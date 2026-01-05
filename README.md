## 安裝方式

### 私人pushprox快速安裝
```bash
curl -fsSL https://raw.githubusercontent.com/3samhuang/initial-scripts/main/install-pushprox-agent.sh | bash
```
### overlay2佔用大的目錄查找容器
```
bash <(curl -fsSL https://raw.githubusercontent.com/3samhuang/initial-scripts/main/find-container-by-layer.sh) /data01/docker_data/overlay2/953d...
```
### 清理comfyui output
```
curl -fsSL https://raw.githubusercontent.com/3samhuang/initial-scripts/main/clean-comfyui-outputs.sh | bash
curl -fsSL https://raw.githubusercontent.com/3samhuang/initial-scripts/main/clean-comfyui-outputs.sh | bash -s -- [options]
curl -fsSL https://raw.githubusercontent.com/3samhuang/initial-scripts/main/clean-comfyui-outputs.sh | bash -s -- --dry-run
```
### 找檔案
```
curl -fsSL https://raw.githubusercontent.com/3samhuang/initial-scripts/main/check_comfyui_models.sh | bash
```
### 建立user
```
curl -sSL https://raw.githubusercontent.com/3samhuang/initial-scripts/main/create_devops_user.sh | bash
```
### 安裝clamav
```
curl -sSL https://raw.githubusercontent.com/3samhuang/initial-scripts/main/install-clamav.sh | sudo bash
```