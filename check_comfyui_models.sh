#!/bin/bash
# ComfyUI Models Checker
# curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/check_models.sh | bash

SEARCH_DIR="${1:-/data01/comfyui_data/models/}"

MODELS=(
    "flux_lustly-ai_v1.safetensors"
    "Male_Nude_and_Genital_Anatomy_for_Flux_1_Dev.safetensors"
    "clothes_remover_v0.safetensors"
    "flux_nsfw_v3.safetensors"
)

[ ! -d "$SEARCH_DIR" ] && echo "Error: Directory not found: $SEARCH_DIR" && exit 1

echo "Checking models in: $SEARCH_DIR"
echo "=========================================="

found=0
missing=0
missing_list=()

for model in "${MODELS[@]}"; do
    if find "$SEARCH_DIR" -type f -name "$model" 2>/dev/null | grep -q .; then
        echo "Found: $model"
        ((found++))
    else
        echo "Missing: $model"
        missing_list+=("$model")
        ((missing++))
    fi
done

echo "=========================================="
echo "Total: ${#MODELS[@]} | Found: $found | Missing: $missing"

if [ $missing -eq 0 ]; then
    echo "All models found!"
    exit 0
else
    echo "Missing models:"
    printf '  - %s\n' "${missing_list[@]}"
    exit 1
fi