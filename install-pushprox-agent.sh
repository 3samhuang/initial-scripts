#!/bin/bash

# 當任何命令失敗時，立即終止腳本
set -e

echo "=== 更新系統並安裝 make ==="
# 執行前先更新套件列表是個好習慣
cd /opt
sudo apt update
sudo apt install make -y

echo "=== 下載並安裝 Go ==="
# 移除舊的 Go 安裝，確保環境乾淨
sudo rm -rf /usr/local/go
# 下載 Go 語言壓縮檔
wget https://go.dev/dl/go1.25.1.linux-amd64.tar.gz
# 解壓縮到 /usr/local
sudo tar -C /usr/local -xzf go1.25.1.linux-amd64.tar.gz

echo "=== 設定 Go 環境變數 ==="
# 將 Go 的執行路徑加入 PATH
export PATH=$PATH:/usr/local/go/bin
# 顯示版本以確認安裝成功
go version

echo "=== 下載並編譯 pushprox ==="
# 克隆 pushprox 倉庫
git clone https://github.com/prometheus-community/pushprox.git
# 進入專案目錄
cd pushprox/
# 使用 make 進行編譯
make build

# 啟動 pushprox-client，並指定代理伺服器 URL
# 輸出導向 /dev/null，並在背景運行
nohup ./pushprox-client --proxy-url=http://10.200.1.8:8080/ > /dev/null 2>client.log &

ps aux | grep pushprox
