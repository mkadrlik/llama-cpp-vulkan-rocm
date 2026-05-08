# llama-cpp-vulkan-tq

llama.cpp built for **Vulkan** GPUs (AMD, NVIDIA, Intel). Optimized for speed.

## What This Is

This is the **speed** backend in the lemonade-tq ecosystem. Vulkan delivers faster token generation than ROCm for standard workloads. It does **not** support TurboQuant KV cache compression — use the ROCm backend for long-context inference.

## Quick Start

```bash
# Using pre-built image from ghcr.io
docker run --rm \
  --device /dev/dri \
  -p 8080:8080 \
  -v /path/to/model.gguf:/model.gguf:ro \
  ghcr.io/mkadrlik/llama-cpp-vulkan-tq:latest \
  --model /model.gguf -ngl 99 -fa on
```

Or use docker-compose (see [docker-compose.yml](docker-compose.yml)):

```bash
cp .env.example .env
# Edit .env to set MODEL_PATH and other options
docker compose up -d
```

## Build Process

This Docker image is built using a multi-stage Dockerfile:

1. **Builder stage** (`ubuntu:22.04` + `vulkan-sdk`):
   - Installs build dependencies (cmake, git, build-essential, vulkan-sdk)
   - Clones llama.cpp from upstream
   - Configures CMake with `GGML_VULKAN=ON`
   - Builds with Vulkan SDK

2. **Runtime stage** (`ubuntu:22.04` + `libvulkan1`):
   - Copies built binaries (llama-server, llama-quantize)
   - Copies all shared libraries (libggml*, libllama*)
   - Sets default CMD to serve with Flash Attention

### Key Build Decisions

- Vulkan SDK for cross-platform GPU support
- Flash Attention enabled (`-fa on`) for quantized models
- No TurboQuant — this is a speed-optimized build, not a long-context build

## Benchmarks

Tested with `Qwen3.6-35B-A3B-GGUF` on 3x RX 7900 XTX:

| Metric | Value | Notes |
|--------|-------|-------|
| Prompt tok/s | 83-90 | Flash Attention on |
| Token gen | 35-48 | Vulkan backend |

## Repository Structure

- `main` — Turn-key repository, ready to use. No sensitive values.
- `home-lab` — Environment-specific configuration (not for general use).

## License

MIT (same as upstream llama.cpp).
