###############################################################################
# llama-cpp-nvidia-tq
# CUDA build of llama.cpp with TurboQuant KV cache compression and
# Split Mode Graph (multi-GPU tensor parallelism).
#
# Source: domvox/llama.cpp-turboquant-hip (feature/turboquant-hip-port-clean)
###############################################################################

FROM nvidia/cuda:12.2.0-devel-ubuntu22.04 AS builder

# Build dependencies
RUN apt-get update && apt-get install -y \
    cmake \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Clone TurboQuant fork (not vanilla llama.cpp)
RUN git clone --branch feature/turboquant-hip-port-clean --depth 1 \
    https://github.com/domvox/llama.cpp-turboquant-hip.git /opt/llama.cpp
WORKDIR /opt/llama.cpp

# Build with CUDA and TurboQuant support
RUN cmake -B build -DGGML_CUDA=ON
RUN cmake --build build --config Release -j$(nproc)

###############################################################################
# Runtime image
###############################################################################
FROM nvidia/cuda:12.2.0-runtime-ubuntu22.04

# Copy built binaries
COPY --from=builder /opt/llama.cpp/build/bin/llama-server /usr/local/bin/
COPY --from=builder /opt/llama.cpp/build/bin/llama-quantize /usr/local/bin/

# Default: serve with TurboQuant and Split Mode Graph
ENTRYPOINT ["llama-server"]
CMD ["--host", "0.0.0.0", "--port", "8080", "-sm", "graph", "-ctk", "turbo", "-ctv", "turbo"]
