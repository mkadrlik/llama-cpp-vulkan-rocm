#!/usr/bin/env python3
"""
Apply #ifdef GGML_CUDA guards around TriAttention (CUDA-only) code.
Patches the AmesianX/TurboQuant fork source to compile without CUDA.
"""
import sys, os, re

def apply_guards(path, guards):
    """
    guards: list of (start_line, end_line) tuples (1-indexed inclusive)
    Wraps each range with #ifdef GGML_CUDA / #endif
    """
    with open(path) as f:
        lines = f.readlines()
    
    # Sort guards in reverse order so line numbers stay valid
    guards = sorted(guards, key=lambda x: x[0], reverse=True)
    
    for start, end in guards:
        s = start - 1  # 0-indexed
        e = end        # end is inclusive, so slice to end
        
        indent = lines[s][:len(lines[s]) - len(lines[s].lstrip())]
        
        # Replace the range with guarded version
        new_lines = [indent + '#ifdef GGML_CUDA\n']
        new_lines.extend(lines[s:e])
        new_lines.append(indent + '#endif\n')
        lines[s:e] = new_lines
    
    with open(path, 'w') as f:
        f.writelines(lines)
    print(f"  Patched: {os.path.basename(path)} ({len(guards)} guard(s))")

def main():
    src = '/opt/llama.cpp/src'
    
    apply_guards(
        f'{src}/llama-kv-cache.cpp',
        [(1167, 1222)]  # struct llama_tria_stats through tria_score_maybe end
    )
    
    apply_guards(
        f'{src}/llama-context.h',
        [(227, 227), (261, 265)]  # void tria_set; and tria_stats members
    )
    
    apply_guards(
        f'{src}/llama-context.cpp',
        [
            (1882, 1892),  # if (tria_stats && tria_budget > 0) block
            (3115, 3123),  # void llama_context::tria_set
            (3125, 3133),  # void llama_tria_attach
            (3141, 3153),  # extern "C" + llama_tria_load + llama_tria_free
        ]
    )
    
    print("All patches applied.")

if __name__ == '__main__':
    main()
