###############################################################################
# llama-cpp-vulkan-tq
# Vulkan build of llama.cpp — optimized for speed.
#
# NOTE: Vulkan does NOT support TurboQuant. Use the ROCm backend for
# TurboQuant KV cache compression. This backend is for fast inference
# with Flash Attention on AMD/NVIDIA/Intel GPUs.
#
# Source: AmesianX/TurboQuant (master) — includes CVE fixes + general improvements
# Note: TriAttention is ROCm-only and not available in Vulkan build
# Base: rocm/dev-ubuntu-24.04 (same as ROCm build for consistent toolchain)
###############################################################################

# Use -complete variant which includes full dev toolchain (~6.9 GB)
FROM rocm/dev-ubuntu-24.04:7.2.3-complete AS builder

# Build dependencies
RUN apt-get update && apt-get install -y \
    cmake \
    git \
    build-essential \
    wget \
    ca-certificates \
    xz-utils \
    pkg-config \
    libopenblas-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Vulkan SDK from LunarG (1.4.309.0)
RUN wget -qO /tmp/vulkansdk.tar.xz "https://sdk.lunarg.com/sdk/download/1.4.309.0/linux/vulkansdk-linux-x86_64-1.4.309.0.tar.xz" && \
    mkdir -p /opt/vulkan && \
    tar xf /tmp/vulkansdk.tar.xz -C /opt/vulkan && \
    rm /tmp/vulkansdk.tar.xz

ENV VULKAN_SDK=/opt/vulkan/1.4.309.0/x86_64
ENV PATH=/opt/vulkan/1.4.309.0/x86_64/bin:${PATH}

# Clone TurboQuant fork (AmesianX — includes CVE fixes + general improvements)
RUN git clone --branch master --depth 1 \
    https://github.com/AmesianX/TurboQuant.git /opt/llama.cpp
WORKDIR /opt/llama.cpp

# Build with Vulkan + TurboQuant + Release optimizations + BLAS
RUN cmake -B build \
    -DGGML_VULKAN=ON \
    -DGGML_BLAS=ON \
    -DGGML_BLAS_VENDOR=OpenBLAS \
    -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build --config Release -j$(nproc)

###############################################################################
# Runtime image
###############################################################################
FROM rocm/dev-ubuntu-24.04:7.2.3

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libvulkan1 libgomp1 libopenblas0-pthread \
    && rm -rf /var/lib/apt/lists/*

# Copy built binaries + ALL shared libs (llama-server dynamically links to all of them)
COPY --from=builder /opt/llama.cpp/build/bin/llama-server /usr/local/bin/
COPY --from=builder /opt/llama.cpp/build/bin/llama-quantize /usr/local/bin/
COPY --from=builder /opt/llama.cpp/build/bin/llama-bench /usr/local/bin/
COPY --from=builder /opt/llama.cpp/build/bin/llama-perplexity /usr/local/bin/
COPY --from=builder /opt/llama.cpp/build/bin/libggml*.so* /usr/local/lib/
COPY --from=builder /opt/llama.cpp/build/bin/libllama*.so* /usr/local/lib/
COPY --from=builder /opt/llama.cpp/build/bin/libmtmd*.so* /usr/local/lib/

# Copy ROCm runtime libraries (hipblas, rocblas, etc.)
COPY --from=builder /opt/rocm/lib/ /opt/rocm/lib/

ENV LD_LIBRARY_PATH=/usr/local/lib

# Default: serve with Flash Attention enabled (required for Vulkan quantized models)
# No TurboQuant — Vulkan does not support KV cache compression.
ENTRYPOINT ["llama-server"]
CMD ["--host", "0.0.0.0", "--port", "8080", "-fa", "on"]
