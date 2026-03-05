#!/bin/sh
# สร้างโฟลเดอร์ data/n8n-* และตั้งสิทธิ์ให้ UID 1000 (user node ใน n8n container)
# ใช้เฉพาะเมื่อแก้ compose ให้ใช้ bind mount (./data/n8n-X) แทน named volume
# โปรเจกต์ default ใช้ named volumes จึงไม่ต้องรันสคริปต์นี้บนเครื่องใหม่
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="$REPO_ROOT/data"
N8N_UID="${N8N_DATA_UID:-1000}"
N8N_GID="${N8N_DATA_GID:-1000}"

# อ่าน N8N_COUNT จาก env (ตรงกับ generate-compose.py)
N8N_COUNT="${N8N_COUNT:-25}"

echo "Preparing n8n data directories (N8N_COUNT=$N8N_COUNT, uid:gid=$N8N_UID:$N8N_GID)..."

for i in $(seq 1 "$N8N_COUNT"); do
  d="$DATA_DIR/n8n-$i"
  mkdir -p "$d"
  if [ "$(id -u)" = 0 ] || [ -w "$d" ]; then
    chown -R "$N8N_UID:$N8N_GID" "$d" 2>/dev/null || true
  fi
done

echo "Done. If you need to fix ownership (e.g. EACCES in n8n logs), run as root:"
echo "  sudo chown -R $N8N_UID:$N8N_GID $DATA_DIR/n8n-*"
