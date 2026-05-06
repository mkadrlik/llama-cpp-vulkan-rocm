# llama-cpp-vulkan-tq

TurboQuant llama.cpp build with Vulkan backend for AMD/Intel GPUs.

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

- `-sm tensor` + TurboQuant = CRASH. Use `-sm layer`
- Always add `-fit off` for split modes
- Vulkan requires `-fa on` (Flash Attention) for quantized V cache
- Build inside container - GLIBC mismatch between Fedora host and Ubuntu container
- Must copy ALL shared libs (libllama*, libggml*, libmtmd*)

## Dependencies

- TurboQuant fork: `TheTom/llama-cpp-turboquant`
- Vulkan SDK (glslc, libvulkan.so)
