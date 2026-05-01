FROM nvidia/cuda:12.2.0-devel-ubuntu22.04 AS builder
RUN apt-get update && apt-get install -y cmake git build-essential && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 https://github.com/ggerganov/llama.cpp.git /opt/llama.cpp
WORKDIR /opt/llama.cpp
RUN cmake -B build -DGGML_CUDA=ON
RUN cmake --build build --config Release -j$(nproc)
FROM nvidia/cuda:12.2.0-runtime-ubuntu22.04
COPY --from=builder /opt/llama.cpp/build/bin/llama-server /usr/local/bin/
COPY --from=builder /opt/llama.cpp/build/bin/llama-quantize /usr/local/bin/
ENTRYPOINT ["llama-server"]
CMD ["--host", "0.0.0.0", "--port", "8080", "-sm", "graph", "-ctk", "turbo", "-ctv", "turbo"]
