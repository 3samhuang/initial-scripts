!/bin/bash
set -e

echo "=== 更新系統並安裝 make、git ==="
sudo apt update
sudo apt install -y make git wget

echo "=== 安裝 Go ==="
sudo rm -rf /usr/local/go
cd /opt
wget https://go.dev/dl/go1.25.1.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.25.1.linux-amd64.tar.gz

export PATH=$PATH:/usr/local/go/bin

echo "Go version:"
go version

echo "=== 下載並編譯 pushprox ==="
cd /opt
sudo rm -rf pushprox
git clone https://github.com/prometheus-community/pushprox.git
cd pushprox
make build

echo "=== 建立 systemd 服務檔 ==="
SERVICE_FILE="/etc/systemd/system/pushprox-client.service"

sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=PushProx Client
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/pushprox
ExecStart=/opt/pushprox/pushprox-client --proxy-url=http://10.200.1.8:8080/
Restart=always
RestartSec=5
StandardOutput=append:/var/log/pushprox-client.log
StandardError=append:/var/log/pushprox-client-error.log

[Install]
WantedBy=multi-user.target
EOF

echo "=== 重新載入 systemd ==="
sudo systemctl daemon-reload

echo "=== 啟用並啟動 pushprox-client ==="
sudo systemctl enable pushprox-client
sudo systemctl start pushprox-client

echo "=== 完成！目前服務狀態 ==="
sudo systemctl status pushprox-client --no-pager
