# llama-cpp-vulkan-rocm

llama.cpp build with Vulkan backend for AMD/Intel GPUs (Vulkan + ROCm hybrid).

## Purpose

The **speed** backend in the lemonade-tq ecosystem. Faster token generation than ROCm for standard workloads. TriAttention (CUDA-only) is patched out via `#ifdef GGML_CUDA` guards.

## Build

```bash
# Inside Ubuntu container with Vulkan SDK
cmake -B build -DGGML_VULKAN=ON
cmake --build build --target llama-server -j$(nproc)
```

## Key Files

- `Dockerfile` - Multi-stage build, copies all shared libs
- `.gitea/workflows/ci.yml` - Self-contained CI workflow

## CI/CD

- Runner: `rocm/linux` (Gitea Actions)
- Pushes to: `ghcr.io/mkadrlik/llama-cpp-vulkan-tq:latest`
- Trigger: push to main

## Pitfalls

- Vulkan requires `-fa on` (Flash Attention) for quantized models
- `-sm tensor` + TurboQuant = CRASH. Use `-sm layer`
- Always add `-fit off` for split modes
- Build inside container — GLIBC mismatch between Fedora host and Ubuntu container
- Must copy ALL shared libs (libllama*, libggml*)

## Dependencies

- Vulkan SDK (glslc, libvulkan.so)
