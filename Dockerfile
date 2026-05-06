###############################################################################
# llama-cpp-vulkan-tq
# Vulkan build of llama.cpp with TurboQuant KV cache compression.
#
# Source: TheTom/llama-cpp-turboquant (feature/turboquant-kv-cache)
###############################################################################

FROM ubuntu:22.04 AS builder

# Build dependencies
RUN apt-get update && apt-get install -y \
    cmake \
    git \
    build-essential \
    wget \
    ca-certificates \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Vulkan SDK from LunarG (1.4.309.0)
RUN wget -qO /tmp/vulkansdk.tar.xz "https://sdk.lunarg.com/sdk/download/1.4.309.0/linux/vulkansdk-linux-x86_64-1.4.309.0.tar.xz" && \
    mkdir -p /opt/vulkan && \
    tar xf /tmp/vulkansdk.tar.xz -C /opt/vulkan && \
    rm /tmp/vulkansdk.tar.xz

ENV VULKAN_SDK=/opt/vulkan/1.4.309.0/x86_64
ENV PATH=/opt/vulkan/1.4.309.0/x86_64/bin:${PATH}

# Clone TurboQuant fork (TheTom — canonical, actively maintained)
RUN git clone --branch feature/turboquant-kv-cache --depth 1 \
    https://github.com/TheTom/llama-cpp-turboquant.git /opt/llama.cpp
WORKDIR /opt/llama.cpp

# Build with Vulkan and TurboQuant support
RUN cmake -B build -DGGML_VULKAN=ON
RUN cmake --build build --config Release -j$(nproc)

###############################################################################
# Runtime image
###############################################################################
FROM ubuntu:22.04

# Vulkan runtime
RUN apt-get update && apt-get install -y \
    libvulkan1 libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copy built binaries + shared libs
COPY --from=builder /opt/llama.cpp/build/bin/llama-server /usr/local/bin/
COPY --from=builder /opt/llama.cpp/build/bin/llama-quantize /usr/local/bin/
COPY --from=builder /opt/llama.cpp/build/bin/libggml*.so* /usr/local/lib/
COPY --from=builder /opt/llama.cpp/build/bin/libllama*.so* /usr/local/lib/
COPY --from=builder /opt/llama.cpp/build/bin/libmtmd*.so* /usr/local/lib/

ENV LD_LIBRARY_PATH=/usr/local/lib

# Default: serve with TurboQuant 3-bit KV cache (recommended)
ENTRYPOINT ["llama-server"]
CMD ["--host", "0.0.0.0", "--port", "8080", "-ctk", "turbo3", "-ctv", "turbo3"]
