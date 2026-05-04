###############################################################################
# llama-cpp-vulkan-tq
# Vulkan build of llama.cpp with TurboQuant KV cache compression.
#
# Source: TheTom/llama-cpp-turboquant (feature/turboquant-kv-cache)
###############################################################################

FROM ubuntu:22.04 AS builder

# Build dependencies + Vulkan SDK
RUN apt-get update && apt-get install -y \
    cmake \
    git \
    build-essential \
    vulkan-sdk \
    && rm -rf /var/lib/apt/lists/*

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
    libvulkan1 \
    && rm -rf /var/lib/apt/lists/*

# Copy built binaries + shared libs
COPY --from=builder /opt/llama.cpp/build/bin/llama-server /usr/local/bin/
COPY --from=builder /opt/llama.cpp/build/bin/llama-quantize /usr/local/bin/
COPY --from=builder /opt/llama.cpp/build/bin/libggml*.so* /usr/local/lib/
COPY --from=builder /opt/llama.cpp/build/bin/libllama.so* /usr/local/lib/

ENV LD_LIBRARY_PATH=/usr/local/lib

# Default: serve with TurboQuant 3-bit KV cache (recommended)
ENTRYPOINT ["llama-server"]
CMD ["--host", "0.0.0.0", "--port", "8080", "-ctk", "turbo3", "-ctv", "turbo3"]
