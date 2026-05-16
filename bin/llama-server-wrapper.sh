#!/bin/bash
export LD_LIBRARY_PATH=/opt/rocm/lib:/root/.cache/lemonade/bin/llamacpp/vulkan:$LD_LIBRARY_PATH
exec /root/.cache/lemonade/bin/llamacpp/vulkan/llama-server "$@"
