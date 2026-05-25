# llama-cpp-vulkan-rocm

llama.cpp build with Vulkan backend for AMD/Intel GPUs (Vulkan + ROCm hybrid).

## Purpose

The **speed** backend in the lemonade-tq ecosystem. Faster token generation than ROCm for standard workloads. TriAttention (CUDA-only) is patched out via `#ifdef GGML_CUDA` guards.

Vulkan does **NOT** support TurboQuant. Use the ROCm backend (`llama-cpp-rocm-tq`) for TurboQuant KV cache compression and long-context inference.

## Quick Start (Clone → Validate)

### Prerequisites

- Docker 24.x+ with BuildKit
- Vulkan-capable GPU with working ICD loader
- AMD GPU users: ROCm runtime installed on host (for `/dev/dri` and `/dev/kfd`)

### Clone

```bash
# From Gitea (primary, includes CI workflows)
git clone http://nas.kadrlik.home:3042/mkadrlik/llama-cpp-vulkan-rocm.git
cd llama-cpp-vulkan-rocm

# From GitHub (mirror, no CI workflows)
git clone https://github.com/mkadrlik/llama-cpp-vulkan-rocm.git
cd llama-cpp-vulkan-rocm
```

### Configure

```bash
cp .env.example .env
# Edit .env — at minimum set MODEL_PATH to a real .gguf file
# Example: MODEL_PATH=/home/you/models/Gemma-4-E2B-it-Q8_0.gguf
```

### Build

```bash
docker build -t llama-cpp-vulkan-rocm .
```

Builds inside an Ubuntu container with Vulkan SDK. Compiles llama-server with `GGML_VULKAN=ON`. Build takes 15-25 minutes.

### Run

```bash
docker compose up -d
```

### Validate

```bash
# 1. Container is running
docker ps --filter name=llama-cpp-vulkan-rocm --format "{{.Status}}"
# Expected: "Up X minutes"

# 2. Server responds
curl -s http://localhost:8080/health | python3 -m json.tool
# Expected: {"status": "ok"}

# 3. Vulkan backend is active
docker logs llama-cpp-vulkan-rocm 2>&1 | grep -i "vulkan"
# Expected: lines showing Vulkan device detection

# 4. Chat completion works
curl -s http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"default","messages":[{"role":"user","content":"Say hello"}],"max_tokens":20}' | python3 -m json.tool
# Expected: JSON response with choices[0].message.content

# 5. Stop
docker compose down
```

### Pull Pre-built Image (skip build)

```bash
docker pull ghcr.io/mkadrlik/llama-cpp-vulkan-rocm:latest
# Or from Gitea Container Registry
docker pull nas.kadrlik.home:3042/mkadrlik/llama-cpp-vulkan-tq:latest
```

## Build Details

Multi-stage Docker build. Builder stage uses Ubuntu + Vulkan SDK, runtime stage copies all shared libs (libllama*, libggml* must all be included or llama-server crashes at startup with missing symbol errors).

### Key Build Flags

| Flag | Purpose |
|------|---------|
| `GGML_VULKAN=ON` | Vulkan backend for GPU compute |
| TriAttention patched | `#ifdef GGML_CUDA` guards exclude CUDA-only code |

## Performance Benchmarks

Tested with `Qwen3.6-35B-A3B-GGUF` on 3x RX 7900 XTX:

| Metric | Value | Notes |
|--------|-------|-------|
| Prompt tok/s | 83-90 | No TurboQuant |
| Token gen | 35-48 | Flash Attention on |
| Max context | 226K tokens | Standard KV cache |

## Key Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Multi-stage build, copies all shared libs |
| `docker-compose.yml` | Production deployment config |
| `.env.example` | Environment variable template |
| `.gitea/workflows/ci.yml` | Self-contained CI workflow |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `IMAGE_REGISTRY` | `ghcr.io` | Docker image registry |
| `IMAGE_NAME` | `mkadrlik/llama-cpp-vulkan-rocm` | Image name |
| `IMAGE_TAG` | `latest` | Image tag |
| `MODEL_PATH` | (required) | Path to .gguf model on host |
| `MODEL_MOUNT` | `/model.gguf` | Mount point inside container |
| `SERVER_HOST` | `0.0.0.0` | Server bind address |
| `SERVER_PORT` | `8080` | Host port mapping |
| `GPU_LAYERS` | `99` | GPU layers to offload |
| `THREADS` | (auto) | CPU thread count |
| `CONTEXT_SIZE` | (model default) | Context window size |
| `EXTRA_ARGS` | (empty) | Additional llama-server arguments |

## CI/CD

- Runner: `rocm/linux` (Gitea Actions)
- Pushes to: `ghcr.io/mkadrlik/llama-cpp-vulkan-tq:latest` and `nas.kadrlik.home:3042/mkadrlik/llama-cpp-vulkan-tq:latest`
- Trigger: push to main
- Mirrors to GitHub (excludes `.gitea/` and `.upstream-hash`)

## Dependencies

- Vulkan SDK (glslc, libvulkan.so)
- AMD ROCm runtime on host (for `/dev/dri` access)

## Known Pitfalls

1. **Flash Attention required**: Always use `-fa on` for quantized models on Vulkan. Without it, output is garbled.
2. **Tensor split + TurboQuant = crash**: `-sm tensor` combined with TurboQuant cache types causes crashes. Use `-sm layer` only.
3. **Always add `-fit off`**: Required for split modes to avoid `GGML_ASSERT(n_inputs < GGML_SCHED_MAX_SPLIT_INPUTS)`.
4. **GLIBC mismatch**: Build inside the container. Fedora host has newer glibc than the Ubuntu container — statically linked builds break.
5. **Must copy ALL shared libs**: Missing `libllama*` or `libggml*` causes immediate crash at startup.
6. **No TurboQuant**: Vulkan backend does not support TurboQuant KV cache compression. Use ROCm for long-context inference.