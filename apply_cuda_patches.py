#!/usr/bin/env python3
"""
Apply #ifdef GGML_CUDA guards around TriAttention (CUDA-only) code.
Patches the AmesianX/TurboQuant fork source to compile without CUDA.

Content-based patching: searches for unique text markers instead of hard-coded
line numbers, so the script self-heals when upstream adds/removes lines.
"""
import sys, os, re


def find_line(lines: list[str], marker: str, start: int = 0) -> int | None:
    """Return 0-indexed line number where *marker* appears, or None."""
    for i in range(start, len(lines)):
        if marker in lines[i]:
            return i
    return None


def find_next_blank_or_sentinel(lines: list[str], after: int, sentinels: list[str] | None = None) -> int:
    """
    Return the index of the first blank line or sentinel line after *after*.
    Returns the line *after* the last line of the block (exclusive end).
    """
    for i in range(after, len(lines)):
        stripped = lines[i].strip()
        if not stripped:
            return i  # blank line = block boundary
        if sentinels:
            for s in sentinels:
                if s in lines[i]:
                    return i
    return len(lines)


def find_block_end(lines: list[str], start: int, sentinels: list[str]) -> int:
    """
    Find end of block starting at *start*. Returns exclusive end index.
    Scans for any of the sentinel strings; returns the line index *of* the
    sentinel (so slicing [start:end] excludes it).
    """
    for i in range(start, len(lines)):
        for s in sentinels:
            if s in lines[i] and i > start:
                return i
    return len(lines)


def apply_guards(path: str, guards: list[tuple]) -> None:
    """
    guards: list of (start_marker, end_sentinels, indent_ref_line_offset) tuples
      - start_marker: substring to find the start of the region
      - end_sentinels: list of strings; first match (after start) = end boundary
      - indent_ref_line_offset: 0 means use the start line itself for indentation;
        use -1 to auto-detect from the first non-blank, non-comment line

    Wraps each region with #ifdef GGML_CUDA / #endif
    """
    with open(path) as f:
        lines = f.readlines()

    # Collect (start_idx, end_idx, indent) for every guard, then apply reverse.
    regions: list[tuple[int, int, str]] = []

    search_from = 0
    for start_marker, end_sentinels, _indent_ref in guards:
        s = find_line(lines, start_marker, search_from)
        if s is None:
            print(f"  FAIL: '{os.path.basename(path)}' — start marker not found: {start_marker!r}")
            sys.exit(1)

        end = find_block_end(lines, s + 1, end_sentinels)

        # Determine indentation from the start line
        raw = lines[s]
        indent = raw[:len(raw) - len(raw.lstrip())]

        regions.append((s, end, indent))
        search_from = end  # next search starts after this region

    # Apply in reverse so earlier indices stay valid
    for s, e, indent in reversed(regions):
        new_lines = [indent + '#ifdef GGML_CUDA\n']
        new_lines.extend(lines[s:e])
        new_lines.append(indent + '#endif\n')
        lines[s:e] = new_lines

    with open(path, 'w') as f:
        f.writelines(lines)

    print(f"  OK: {os.path.basename(path)} ({len(regions)} guard(s))")


# ──────────────────────────────────────────────────────────────────────────────
# Guard definitions — content-based, no line numbers
# ──────────────────────────────────────────────────────────────────────────────

def main():
    src = os.environ.get('SRC', '/opt/llama.cpp/src')
    top = os.path.dirname(src)  # repo root

    print("Applying CUDA guards (content-based)...")

    # ── src/llama-kv-cache.cpp ───────────────────────────────────────────────
    # Region: everything from the CUDA forward-declarations through tria_score_maybe.
    #   Start: "// Forward-declared in ggml-cuda"
    #   End:   next line containing "llama_kv_cache::type_v" (exclusive)
    apply_guards(f'{src}/llama-kv-cache.cpp', [
        (
            "// Forward-declared in ggml-cuda/triattention.cuh",
            ["llama_kv_cache::type_v"],
            0,
        ),
    ])

    # ── src/llama-kv-cache.h ─────────────────────────────────────────────────
    # Region: single declaration line for tria_score_maybe
    apply_guards(f'{src}/llama-kv-cache.h', [
        (
            "bool tria_score_maybe(struct llama_tria_stats",
            ["ggml_type type_k()"],
            0,
        ),
    ])

    # ── src/llama-context.h ──────────────────────────────────────────────────
    # Region 1: void tria_set(...) declaration (single line, before private:)
    # Region 2: tria_stats member block (5 lines)
    apply_guards(f'{src}/llama-context.h', [
        (
            "void tria_set(struct llama_tria_stats",
            ["private:"],
            0,
        ),
        (
            "struct llama_tria_stats * tria_stats",
            ["// decode output", "buffer_view<float> logits"],
            0,
        ),
    ])

    # ── src/llama-context.cpp ────────────────────────────────────────────────
    # Four regions: tria counter block, tria_set method, tria_attach, extern block+load/free
    apply_guards(f'{src}/llama-context.cpp', [
        # (1) if (tria_stats && tria_budget > 0) block
        (
            "if (tria_stats && tria_budget > 0)",
            ["//", "// output"],
            0,
        ),
        # (2) void llama_context::tria_set
        (
            "void llama_context::tria_set(struct llama_tria_stats",
            ["void llama_tria_attach"],
            0,
        ),
        # (3) void llama_tria_attach
        (
            "void llama_tria_attach(",
            ["#include \"ggml-backend.h\"", "// ----"],
            0,
        ),
        # (4) extern \"C\" block + llama_tria_load + llama_tria_free
        (
            '#include "ggml-backend.h"',
            ["uint32_t llama_n_ctx(const llama_context"],
            0,
        ),
    ])

    # ── include/llama.h ──────────────────────────────────────────────────────
    # TriAttention API: struct fwd decl + load/free/attach
    apply_guards(f'{top}/include/llama.h', [
        (
            "// TriAttention (AMX3_1 pre-RoPE polar scoring)",
            ["LLAMA_API int64_t llama_time_us"],
            0,
        ),
    ])

    # ── common/common.cpp ────────────────────────────────────────────────────
    # if (!params.triattention_stats_path.empty() ...) block
    apply_guards(f'{top}/common/common.cpp', [
        (
            "if (!params.triattention_stats_path.empty()",
            ["if (!params.control_vectors.empty()"],
            0,
        ),
    ])

    print("All patches applied.")


if __name__ == '__main__':
    main()
