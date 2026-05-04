# Benchmarks: llama-cpp-nvidia-tq

> **\u26a0\ufe0f DISCLAIMER:** These benchmarks were run on **AMD ROCm hardware** (3x RX 7900 XTX). They have NOT been verified on NVIDIA CUDA hardware. The relative improvements between cache types should be consistent, but absolute numbers will vary depending on your GPU configuration.

## Test Hardware (ROCm)

| Component | Specification |
|-----------|--------------|
| GPU | 3x AMD Radeon RX 7900 XTX |
| VRAM per GPU | 24,560 MiB (24 GB) |
| Total VRAM | 73,680 MiB (72 GB) |
| GPU Architecture | gfx1100 (RDNA3) |
| ROCm Version | 7.2 |

## Test Model

| Property | Value |
|----------|-------|
| Model | Qwen3.6-27B-UD-Q4_K_XL |
| Size | 16.39 GiB (5.24 BPW) |
| Parameters | 26.90 B |

## Speed Benchmark (llama-bench)

Parameters: pp512 (prompt processing), tg256 (text generation), batch=8, ubatch=2048, threads=24

| Cache Type | Prompt (pp512) t/s | Generation (tg256) t/s | vs f16 |
|-----------|-------------------|----------------------|--------|
| f16 | 118.92 +/- 0.77 | 19.41 +/- 0.26 | baseline |
| q8_0 | 118.75 +/- 1.06 | 19.24 +/- 0.04 | -0.1% / -0.9% |
| turbo4 | 118.92 +/- 0.73 | 19.64 +/- 0.07 | +0.0% / +1.2% |
| turbo3 | 118.58 +/- 0.48 | 19.42 +/- 0.10 | -0.3% / +0.1% |
| turbo2 | 118.31 +/- 0.27 | 19.32 +/- 0.10 | -0.5% / -0.5% |

## KV Cache Memory Savings (512 Context)

| Cache Type | Total KV Cache | vs f16 savings |
|-----------|---------------|---------------|
| f16 | 128.00 MiB | baseline |
| q8_0 | 68.00 MiB | -46.9% |
| turbo4 | 51.00 MiB | -60.2% |
| turbo3 | 46.50 MiB | -63.7% |
| turbo2 | 44.09 MiB | -65.6% |

## Quality Benchmark (Perplexity)

Lower is better. Test file: Wikipedia LLM article (650 lines, 14,336 tokens).

| Cache Type | PPL | vs f16 delta |
|-----------|-----|-------------|
| f16 | 1.5972 | baseline |
| q8_0 | 1.6006 | +0.21% |
| turbo4 | 1.6014 | +0.26% |
| turbo3 | 1.6044 | +0.45% |
| turbo2 | 1.6142 | +1.06% |

## Recommendation

For production use, `--cache-type-k q8_0 --cache-type-v turbo3` is recommended for the best balance of VRAM savings and quality preservation.

## Note on CUDA Performance

These benchmarks were run on ROCm. CUDA performance characteristics may differ:
- CUDA may have different memory bandwidth characteristics
- Flash Attention implementation differs between ROCm and CUDA
- Multi-GPU scaling may behave differently

If you have NVIDIA hardware and can contribute benchmark results, please [open an issue](https://github.com/mkadrlik/llama-cpp-nvidia-tq/issues) with your findings.
