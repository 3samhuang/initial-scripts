#!/usr/bin/env bash
# clean-comfyui-outputs.sh
#
# 功能：
#   清理 /data01/comfyui_data/ 底下所有名稱包含 "output" 的資料夾內容
#   保留資料夾本身（不刪除資料夾）
#
# 適合遠端 curl 執行（非互動）
# 用法：
#   bash <(curl -fsSL https://raw.githubusercontent.com/<你的帳號>/<repo>/main/clean-comfyui-outputs.sh)
#   bash <(curl -fsSL https://raw.githubusercontent.com/<你的帳號>/<repo>/main/clean-comfyui-outputs.sh) --dry-run
#
# 參數：
#   --dry-run   僅列出將清理的內容，不實際刪除

set -euo pipefail

ROOT_DIR="/data01/comfyui_data"
DRY_RUN=false

# 檢查參數
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

if [ ! -d "$ROOT_DIR" ]; then
  echo "❌ 找不到路徑: $ROOT_DIR"
  exit 1
fi

echo "🔍 掃描目錄：$ROOT_DIR"
echo "   尋找名稱包含 'output' 的資料夾..."
echo

# 找出所有名稱包含 output 的資料夾
mapfile -t OUTPUT_DIRS < <(find "$ROOT_DIR" -type d -iname "output" 2>/dev/null)

if [ ${#OUTPUT_DIRS[@]} -eq 0 ]; then
  echo "✅ 沒有找到任何名稱包含 'output' 的資料夾。"
  exit 0
fi

echo "📂 找到 ${#OUTPUT_DIRS[@]} 個 output 資料夾："
for dir in "${OUTPUT_DIRS[@]}"; do
  echo "  $dir"
done
echo

echo "🧹 開始清理模式：$([[ $DRY_RUN == true ]] && echo 'Dry-run (僅顯示不刪除)' || echo '正式刪除')"
echo

# 執行清理
for dir in "${OUTPUT_DIRS[@]}"; do
  echo "→ 處理目錄: $dir"
  if $DRY_RUN; then
    find "$dir" -mindepth 1 -maxdepth 1 2>/dev/null || true
  else
    find "$dir" -mindepth 1 -delete 2>/dev/null || true
  fi
done

echo
if $DRY_RUN; then
  echo "✅ Dry-run 模式完成（未刪除任何檔案）。"
else
  echo "✅ 清理完成！"
fi
