#!/bin/bash
# Regenerate docker-compose.generated.yml จาก .env แล้ว down + up ใหม่
# ใช้เมื่อแก้ 404 (ทุกเครื่อง) หรือเปลี่ยน BASE_HOST/N8N_COUNT
# รันจากโฟลเดอร์โปรเจกต์: ./scripts/regenerate-and-up.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ ! -f .env ]; then
    echo -e "${RED}ไม่พบ .env${NC} — สร้างจาก .env.example แล้วแก้ค่า (โดยเฉพาะ BASE_HOST, N8N_COUNT)" >&2
    exit 1
fi

# โหลด .env แบบ shell (รองรับ inline comment หลังค่า)
set -a
source .env 2>/dev/null || true
set +a

N8N_COUNT="${N8N_COUNT:-25}"
BASE_HOST="${BASE_HOST:-yourdomain.com}"

echo -e "${YELLOW}Regenerate:${NC} N8N_COUNT=$N8N_COUNT BASE_HOST=$BASE_HOST"

if ! N8N_COUNT="$N8N_COUNT" BASE_HOST="$BASE_HOST" python3 scripts/generate-compose.py; then
    echo -e "${RED}✗ Generate ล้มเหลว${NC}" >&2
    exit 1
fi

echo -e "${GREEN}✓ Generated docker-compose.generated.yml${NC}"

echo "Stopping stack..."
docker compose -f docker-compose.yml -f docker-compose.generated.yml down

echo "Starting stack..."
docker compose -f docker-compose.yml -f docker-compose.generated.yml up -d

# Wait and check
echo ""
echo "รอให้ services ขึ้น..."
sleep 5

# Health check
echo ""
echo "ตรวจสอบสถานะ:"
docker compose -f docker-compose.yml -f docker-compose.generated.yml ps | grep -E "(n8n-|traefik|postgres)" | head -10

# Show URLs
echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}พร้อมใช้งาน!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo "นักเรียนเข้าได้ที่:"
printf "  https://n8n01.%s\n" "$BASE_HOST"
printf "  https://n8n02.%s\n" "$BASE_HOST"
echo "  ..."
printf "  https://n8n%02d.%s\n" "$N8N_COUNT" "$BASE_HOST"
