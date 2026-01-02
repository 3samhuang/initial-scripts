#!/bin/bash

# 使用者名稱
USERNAME="devops"

# 偵測系統類型並設定 sudo 群組
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "❌ 無法識別系統"
    exit 1
fi

case $OS in
    ubuntu|debian)
        SUDO_GROUP="sudo"
        ;;
    centos|rhel|rocky|almalinux|amzn)
        SUDO_GROUP="wheel"
        ;;
    fedora)
        SUDO_GROUP="wheel"
        ;;
    *)
        echo "⚠️  未知系統: $OS，預設使用 wheel 群組"
        SUDO_GROUP="wheel"
        ;;
esac

echo "檢測到系統: $PRETTY_NAME"
echo "使用 sudo 群組: $SUDO_GROUP"
echo ""

# 檢查使用者是否已存在
if id "$USERNAME" &>/dev/null; then
    echo "⚠️  使用者 $USERNAME 已存在，跳過建立"
else
    # 建立使用者並建立 home 目錄（不設定密碼）
    useradd -m -s /bin/bash "$USERNAME"
    
    # 鎖定密碼（禁止密碼登入，只能用 SSH key）
    passwd -l "$USERNAME"
    
    echo "✅ 使用者已建立（僅允許 SSH key 登入）"
fi

# 加入 sudo/wheel 群組
usermod -aG "$SUDO_GROUP" "$USERNAME"

# 設定免密 sudo
SUDOERS_FILE="/etc/sudoers.d/$USERNAME"
if [ ! -f "$SUDOERS_FILE" ]; then
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "$SUDOERS_FILE"
    chmod 440 "$SUDOERS_FILE"
    echo "✅ sudo 權限已設定"
else
    echo "⚠️  sudoers 檔案已存在: $SUDOERS_FILE"
fi

# 設定 SSH 目錄和金鑰
SSH_DIR="/home/$USERNAME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

mkdir -p "$SSH_DIR"

# SSH 公鑰
SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCruoViIFaSza/oSdZ+jlNtn4sGcOpltuOEFEy4XmKy+1NbIYkJSRw5Bkdj1JqnDlmy/nf2nKMr0xt4IE9CQWOPxnMrYnhu1ZeGTYc/lZvq+YSAVmbkEoVSN/SWov7F4Qds7H/pXAgRE128coav3YdIkJws4HyVKSGkw/KKFe+WqyEK8Pz87JH4YhrB0VEe/A0FECaVDll0J73iVpymXKrG0I89FRFfzmmP09Igl9YsOR/FH6H+XqK0Oxa9qlfRSib2a1idAWNauIzsgvfBWwUIIhEJJ1zZg2DofIbi1akXN0d+gEhed3Z0acZ1Joo75Q5az/9fUnY78PZXYSDiaLet KF-20240401"

# 檢查金鑰是否已存在
if [ -f "$AUTHORIZED_KEYS" ]; then
    if grep -q "KF-20240401" "$AUTHORIZED_KEYS"; then
        echo "⚠️  SSH 金鑰已存在"
    else
        echo "$SSH_KEY" >> "$AUTHORIZED_KEYS"
        echo "✅ SSH 金鑰已新增"
    fi
else
    echo "$SSH_KEY" > "$AUTHORIZED_KEYS"
    echo "✅ SSH 金鑰已匯入"
fi

# 設定權限
chown -R "$USERNAME:$USERNAME" "$SSH_DIR"
chmod 700 "$SSH_DIR"
chmod 600 "$AUTHORIZED_KEYS"
