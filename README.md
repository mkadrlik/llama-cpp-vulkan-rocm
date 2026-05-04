# llama-cpp-nvidia-tq

llama.cpp with **TurboQuant** KV cache compression, built for NVIDIA CUDA GPUs.

## What is TurboQuant?

TurboQuant compresses the KV cache using Walsh-Hadamard Transform (WHT) rotation + PolarQuant scalar quantization. Results:

| Type | Bits | Compression | PPL cost |
|------|------|-------------|----------|
| `turbo3` | 3-bit | 5.12x | <1% (recommended) |
| `turbo4` | 4-bit | 3.8x | +0.23% |
| `turbo2` | 2-bit | 7.5x | +3.7% |

Paper: [TurboQuant: KV Cache Compression via WHT](https://arxiv.org/abs/2504.19874)

## Quick Start

```bash
docker build -t llama-cpp-nvidia-tq .

docker run --rm --gpus all \
  -v /path/to/model.gguf:/model.gguf:ro \
  llama-cpp-nvidia-tq /model.gguf -ctk turbo3 -ctv turbo3 -ngl 99
```

## Build Notes

- Source: `TheTom/llama-cpp-turboquant` branch `feature/turboquant-kv-cache`
- CUDA 12.2 on Ubuntu 22.04

## License

MIT (same as upstream llama.cpp).
