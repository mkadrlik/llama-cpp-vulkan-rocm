#!/usr/bin/env python3
"""
Apply #ifdef GGML_CUDA guards around TriAttention (CUDA-only) code.
Patches the AmesianX/TurboQuant fork source to compile without CUDA.
"""
import sys, os

def apply_guards(path, guards):
    """
    guards: list of (start_line, end_line) tuples (1-indexed inclusive)
    Wraps each range with #ifdef GGML_CUDA / #endif
    """
    with open(path) as f:
        lines = f.readlines()
    
    guards = sorted(guards, key=lambda x: x[0], reverse=True)
    
    for start, end in guards:
        s = start - 1  # 0-indexed
        e = end        # end is inclusive, so slice to end
        
        indent = lines[s][:len(lines[s]) - len(lines[s].lstrip())]
        
        new_lines = [indent + '#ifdef GGML_CUDA\n']
        new_lines.extend(lines[s:e])
        new_lines.append(indent + '#endif\n')
        lines[s:e] = new_lines
    
    with open(path, 'w') as f:
        f.writelines(lines)
    print(f"  OK: {os.path.basename(path)} ({len(guards)} guard(s))")

def main():
    src = os.environ.get('SRC', '/opt/llama.cpp/src')
    top = os.path.dirname(src)  # /opt/llama.cpp/
    
    print("Applying CUDA guards...")
    
    # src/llama-kv-cache.cpp: struct llama_tria_stats + extern "C" + tria_score_maybe
    apply_guards(f'{src}/llama-kv-cache.cpp', [(1167, 1222)])
    
    # src/llama-kv-cache.h: tria_score_maybe declaration (line 157)
    apply_guards(f'{src}/llama-kv-cache.h', [(157, 157)])
    
    # src/llama-context.h: void tria_set; and tria_stats members
    apply_guards(f'{src}/llama-context.h', [
        (227, 227),   # void tria_set
        (261, 265),   # tria_stats members
    ])
    
    # src/llama-context.cpp: all tria_ implementations
    apply_guards(f'{src}/llama-context.cpp', [
        (1882, 1892),  # if (tria_stats && tria_budget > 0) block
        (3115, 3123),  # void llama_context::tria_set
        (3125, 3133),  # void llama_tria_attach
        (3141, 3153),  # extern "C" + llama_tria_load + llama_tria_free
    ])
    
    # include/llama.h: struct llama_tria_stats; + API declarations (lines 515-530)
    apply_guards(f'{top}/include/llama.h', [(515, 530)])
    
    # common/common.cpp: full if block for triattention (lines 1587-1598)
    apply_guards(f'{top}/common/common.cpp', [(1587, 1598)])
    
    print("All patches applied.")

if __name__ == '__main__':
    main()
