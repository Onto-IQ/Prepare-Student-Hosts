#!/bin/sh
# Regenerate docker-compose.generated.yml จาก .env แล้ว down + up ใหม่
# ใช้เมื่อแก้ 404 (ทุกเครื่อง) หรือเปลี่ยน BASE_HOST/N8N_COUNT
# รันจากโฟลเดอร์โปรเจกต์: ./scripts/regenerate-and-up.sh
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

if [ ! -f .env ]; then
  echo "ไม่พบ .env — สร้างจาก .env.example แล้วแก้ค่า (โดยเฉพาะ BASE_HOST, N8N_COUNT)" >&2
  exit 1
fi

# โหลด .env (ค่าที่มีช่องว่างหรือ # กลางบรรทัดอาจต้องแก้มือ)
export $(grep -v '^#' .env | grep -v '^[[:space:]]*$' | xargs) 2>/dev/null || true

N8N_COUNT="${N8N_COUNT:-25}"
BASE_HOST="${BASE_HOST:-yourdomain.com}"
echo "Regenerate: N8N_COUNT=$N8N_COUNT BASE_HOST=$BASE_HOST"

if ! N8N_COUNT="$N8N_COUNT" BASE_HOST="$BASE_HOST" python3 scripts/generate-compose.py; then
  echo "Generate ล้มเหลว" >&2
  exit 1
fi

echo "Stopping stack..."
docker compose -f docker-compose.yml -f docker-compose.generated.yml down
echo "Starting stack..."
docker compose -f docker-compose.yml -f docker-compose.generated.yml up -d
echo "Done. ตรวจสอบ: docker compose -f docker-compose.yml -f docker-compose.generated.yml ps"
echo "เข้าได้ที่: http://n8n01.${BASE_HOST}/ (หรือ https:// ถ้ามี cert)"
