# llama-cpp-nvidia-tq

llama.cpp with **TurboQuant** KV cache compression, built for NVIDIA GPUs with CUDA acceleration and multi-GPU tensor parallelism via Split Mode Graph.

## What is TurboQuant?

TurboQuant is a lossy KV cache quantization technique that compresses the key and value caches to 3-bit precision with negligible accuracy loss (<0.1% perplexity degradation). This yields:

- **5.12x KV cache compression** — fits 5x more context in the same VRAM
- **Dramatically reduced memory bandwidth** — faster inference, lower power
- **Near-zero accuracy cost** — imperceptible quality difference on standard benchmarks

Developed by domvox, originally ported to the HIP/ROCm backend, now available for CUDA.

## Features

| Feature | Flag | Description |
|---------|------|-------------|
| TurboQuant K-cache | `-ctk turbo3` | 3-bit compressed key cache |
| TurboQuant V-cache | `-ctv turbo3` | 3-bit compressed value cache |
| Split Mode Graph | `-sm graph` | NCCL-based multi-GPU tensor parallelism |
| CUDA backend | `GGML_CUDA=ON` | NVIDIA GPU acceleration |

## Quick Start

```bash
# Build
docker build -t llama-cpp-nvidia-tq .

# Run with a model (single GPU)
docker run --rm --gpus all \
  -v /path/to/model.gguf:/model.gguf:ro \
  llama-cpp-nvidia-tq \
  /model.gguf --sm graph -ctk turbo3 -ctv turbo3 -ngl 99

# Multi-GPU (2 GPUs, tensor-split)
docker run --rm --gpus all \
  -v /path/to/model.gguf:/model.gguf:ro \
  llama-cpp-nvidia-tq \
  /model.gguf --sm graph -ctk turbo3 -ctv turbo3 --tensor-split 1,1 -ngl 99
```

## Build Configuration

| CMake Flag | Value | Purpose |
|-----------|-------|---------|
| `GGML_CUDA` | `ON` | Enable NVIDIA CUDA backend |

## Hardware Requirements

- **NVIDIA GPU** with CUDA compute capability 7.0+ (Turing, Ampere, Hopper, Blackwell)
- **CUDA Toolkit** 12.2+ (included in build image)
- For multi-GPU: GPUs connected via NVLink or PCIe switch recommended

## Source

Built from `domvox/llama.cpp-turboquant-hip` branch `feature/turboquant-hip-port-clean` with CUDA backend.

## License

Same as upstream llama.cpp (MIT). TurboQuant patches by domvox.
