# llama-cpp-nvidia-tq

llama.cpp with **TurboQuant** KV cache compression, built for NVIDIA CUDA GPUs.

[![Build Status](http://192.168.50.11:3042/api/repos/mkadrlik/llama-cpp-nvidia-tq/actions/runs?branch=main)](http://192.168.50.11:3042/mkadrlik/llama-cpp-nvidia-tq/actions)

> **\u26a0\ufe0f UNTESTED:** This image has **NOT** been tested on NVIDIA hardware. It was created as a byproduct of the [ROCm implementation](https://github.com/mkadrlik/llama-cpp-rocm-tq). If you find issues, please [create an issue](https://github.com/mkadrlik/llama-cpp-nvidia-tq/issues) and we will address it promptly.

## What is TurboQuant?

TurboQuant compresses the KV cache using Walsh-Hadamard Transform (WHT) rotation + PolarQuant scalar quantization, enabling dramatically larger context windows within the same VRAM budget.

| Type | Bits | Compression | PPL cost |
|------|------|-------------|----------|
| `turbo3` | 3-bit | 5.12x | <1% (recommended) |
| `turbo4` | 4-bit | 3.8x | +0.23% |
| `turbo2` | 2-bit | 7.5x | +3.7% |

**Paper:** [TurboQuant: KV Cache Compression via WHT](https://arxiv.org/abs/2504.19874)

## Quick Start

```bash
# Using pre-built image from local registry
docker run --rm --gpus all \
  -p 8080:8080 \
  -v /path/to/model.gguf:/model.gguf:ro \
  192.168.50.11:5000/mkadrlik/llama-cpp-nvidia-tq:latest \
  --model /model.gguf -ctk turbo3 -ctv turbo3 -ngl 99
```

Or use docker-compose (see [docker-compose.yml](docker-compose.yml)):

```bash
cp .env.example .env
# Edit .env to set MODEL_PATH and other options
docker compose up -d
```

## Building from Source

```bash
docker build -t llama-cpp-nvidia-tq .
```

## Attribution & Acknowledgements

This project builds on the excellent work of several open source contributors:

- **[TheTom/llama-cpp-turboquant](https://github.com/TheTom/llama-cpp-turboquant)** — The canonical TurboQuant fork of llama.cpp. This Docker image uses the `feature/turboquant-kv-cache` branch. All credit for TurboQuant implementation goes to TheTom.
- **[ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp)** — The upstream llama.cpp project by @ggerganov and contributors.
- **[TurboQuant Paper](https://arxiv.org/abs/2504.19874)** — The research paper describing the WHT + PolarQuant KV cache compression technique.
- **NVIDIA CUDA** — NVIDIA's parallel computing platform used in this build.

## Build Process

This Docker image is built using a multi-stage Dockerfile:

1. **Builder stage** (`nvidia/cuda:12.2.0-devel-ubuntu22.04`):
   - Installs build dependencies (cmake, git, build-essential)
   - Clones TheTom's TurboQuant fork from `feature/turboquant-kv-cache` branch
   - Configures CMake with `GGML_CUDA=ON`
   - Builds with CUDA toolkit

2. **Runtime stage** (`nvidia/cuda:12.2.0-runtime-ubuntu22.04`):
   - Copies built binaries (llama-server, llama-quantize)
   - Copies all shared libraries (libggml*, libllama*)
   - Sets default CMD to serve with turbo3 KV cache compression

## Benchmarks

See [benchmarks/README.md](benchmarks/README.md) for benchmark results.

> **Note:** Benchmarks were run on AMD ROCm hardware (3x RX 7900 XTX). Results on NVIDIA CUDA hardware may differ. The relative improvements between cache types should be consistent, but absolute numbers will vary.

## License

MIT (same as upstream llama.cpp).
