#!/bin/bash
# ClamAV install & schedule for Rocky Linux 8 / 9

set -euo pipefail

OS_ID=$(cat /etc/os-release | grep "^ID=" | cut -d= -f2 | tr -d '"')

if [[ "$OS_ID" != "rocky" ]]; then
  echo "[ERROR] Unsupported OS: $OS_ID"
  exit 1
fi

echo "[INFO] Detected Rocky Linux"

############################
# Install packages
############################
echo "[INFO] Installing ClamAV packages..."
dnf install -y epel-release yum-utils
dnf install -y clamav clamav-update

############################
# Configure freshclam
############################
echo "[INFO] Configuring freshclam..."
sed -i -e 's/^Example/#Example/' /etc/freshclam.conf

echo "[INFO] Updating virus database..."
freshclam || true

systemctl enable --now clamav-freshclam

############################
# Install scan script
############################
echo "[INFO] Installing scan script..."
cat > /usr/local/bin/clamav-scan.sh <<'EOF'
#!/bin/bash
set -euo pipefail

LOG_DIR="/var/log/clamav"
DATE="$(date +%F)"
LOG_FILE="$LOG_DIR/scan-$DATE.log"

EXCLUDE_DIRS=(
  "/proc"
  "/sys"
  "/dev"
  "/run"
  "/var/lib/docker"
  "/var/lib/containerd"
  "/var/lib/kubelet"
)

CANDIDATE_DIRS=(
  "/var/www"
  "/data"
  "/srv"
  "/opt"
  "/tmp"
  "/var/tmp"
  "/home"
  "/root"
  "/var/log/nginx"
)

mkdir -p "$LOG_DIR"

SCAN_DIRS=()
for dir in "${CANDIDATE_DIRS[@]}"; do
  [[ -d "$dir" ]] && SCAN_DIRS+=("$dir")
done

[[ ${#SCAN_DIRS[@]} -eq 0 ]] && exit 0

EXCLUDE_REGEX=$(printf "|^%s" "${EXCLUDE_DIRS[@]}")
EXCLUDE_REGEX="${EXCLUDE_REGEX:1}"

ionice -c3 nice -n 19 \
clamscan -r \
  --infected \
  --log="$LOG_FILE" \
  --max-filesize=30M \
  --max-scansize=200M \
  --exclude-dir="$EXCLUDE_REGEX" \
  "${SCAN_DIRS[@]}"
EOF

chmod +x /usr/local/bin/clamav-scan.sh

############################
# systemd service
############################
echo "[INFO] Creating systemd service..."
cat > /etc/systemd/system/clamav-scan.service <<'EOF'
[Unit]
Description=ClamAV Weekly Scan
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/clamav-scan.sh
Nice=19
IOSchedulingClass=idle
NoNewPrivileges=true
PrivateTmp=true
EOF

############################
# systemd timer
############################
echo "[INFO] Creating systemd timer..."
cat > /etc/systemd/system/clamav-scan.timer <<'EOF'
[Unit]
Description=Run ClamAV scan every Tuesday and Saturday at 10:00

[Timer]
OnCalendar=Tue,Sat *-*-* 10:00:00
Persistent=true
RandomizedDelaySec=900

[Install]
WantedBy=timers.target
EOF

############################
# Enable timer
############################
systemctl daemon-reload
systemctl enable --now clamav-scan.timer

echo "[INFO] Installation complete"
systemctl list-timers --all | grep clamav || true