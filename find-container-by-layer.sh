#!/usr/bin/env bash
# find-container-by-layer.sh
# 用法:
#   ./find-container-by-layer.sh /data01/docker_data/overlay2/<layer-id>
# 會輸出對應的 mount-id, container-id 和 docker container name (若 docker 可用)

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 /path/to/docker_data/overlay2/<layer-id>"
  exit 1
fi

LAYER_PATH="$1"

if [ ! -d "$LAYER_PATH" ]; then
  echo "❌ 找不到目錄: $LAYER_PATH"
  exit 2
fi

# 推斷 DOCKER_ROOT（取 overlay2 之前的路徑）
DOCKER_ROOT=$(echo "$LAYER_PATH" | sed -E 's#/overlay2/.*##')
MOUNT_DIR="$DOCKER_ROOT/image/overlay2/layerdb/mounts"
CONTAINER_DIR="$DOCKER_ROOT/containers"

LAYER_ID=$(basename "$LAYER_PATH")

echo "🔍 查找 Layer ID: $LAYER_ID"
echo "📂 推斷 Docker Root: $DOCKER_ROOT"
echo

# 找所有檔案路徑包含該 layer id 的檔案（可能在多個 mount 目錄中）
mapfile -t matches < <(grep -rl --binary-files=without-match "$LAYER_ID" "$MOUNT_DIR" 2>/dev/null || true)

if [ ${#matches[@]} -eq 0 ]; then
  echo "⚠️ 在 $MOUNT_DIR 沒有找到任何提到該 layer id 的檔案。這可能是 image layer（非 container mount）或 metadata 已被移除。"
  exit 0
fi

echo "🔗 在 layerdb/mounts 找到以下匹配（可能有多個）："
for p in "${matches[@]}"; do
  echo "  $p"
done
echo

# 取出對應的 mount-id（即 matches 的上層目錄名）
declare -A mount_ids=()
for p in "${matches[@]}"; do
  dir=$(dirname "$p")
  mid=$(basename "$dir")
  mount_ids["$mid"]=1
done

echo "🔎 推論到的 Mount ID(s):"
for mid in "${!mount_ids[@]}"; do
  echo "  $mid"
done
echo

# 對每個 mount id，嘗試在 containers 內尋找
found_any=0
for mid in "${!mount_ids[@]}"; do
  echo "➡ 檢查 mount-id: $mid"
  # 找出 containers 目錄下包含該 mount id 的檔案（會回傳路徑）
  mapfile -t c_matches < <(grep -RIl --binary-files=without-match "$mid" "$CONTAINER_DIR" 2>/dev/null || true)

  if [ ${#c_matches[@]} -eq 0 ]; then
    echo "   ��️ 未在 $CONTAINER_DIR 中找到包含該 mount-id 的檔案（container 可能已刪除或 metadata 不一致）"
    echo
    continue
  fi

  # 解析 container id（路徑為 .../containers/<container_id>/...）
  declare -A container_ids=()
  for cp in "${c_matches[@]}"; do
    # 使用 sed 解析 container id
    if [[ "$cp" =~ /containers/([0-9a-fA-F]+) ]]; then
      cid="${BASH_REMATCH[1]}"
      container_ids["$cid"]=1
    fi
  done

  if [ ${#container_ids[@]} -eq 0 ]; then
    echo "   ⚠️ 找到匹配檔案，但無法解析 container id 的路徑格式。匹配清單："
    for cp in "${c_matches[@]}"; do echo "     $cp"; done
    echo
    continue
  fi

  found_any=1
  echo "   找到 Container ID(s):"
  for cid in "${!container_ids[@]}"; do
    echo "     $cid"

    # 若系統有 docker client，可用 docker inspect 解析名稱（需要權限）
    if command -v docker >/dev/null 2>&1; then
      name=$(docker inspect --format='{{.Name}}' "$cid" 2>/dev/null || echo "(docker inspect 無結果或無權限)")
      echo "       -> docker name: $name"
    else
      echo "       -> docker command not found, 無法透過 docker inspect 取得 container name"
    fi
  done
  echo
done

if [ $found_any -eq 0 ]; then
  echo "⚠️ 沒有找到任何 container 對應該 layer 的 mount-id。"
  exit 3
fi

exit 0