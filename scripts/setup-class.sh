#!/bin/bash
# Setup n8n class environment — ใช้สำหรับทุกครั้งสอน
# ตั้งค่า .env, regenerate compose, และ start stack

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}   n8n Class Setup${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}ไม่พบไฟล์ .env — สร้างใหม่${NC}"
    
    if [ -f .env.example ]; then
        cp .env.example .env
    else
        # Create minimal .env
        cat > .env << 'EOF'
# --- PostgreSQL ---
POSTGRES_USER=n8n
POSTGRES_PASSWORD=change-me-strong-password
POSTGRES_DB=n8n

# --- n8n ---
GENERIC_TIMEZONE=Asia/Bangkok

# --- Class Configuration ---
BASE_HOST=datafabric.academy
N8N_COUNT=25
USE_LETSENCRYPT=false

# --- Traefik ---
TRAEFIK_ACME_EMAIL=admin@datafabric.academy
EOF
    fi
    
    echo -e "${GREEN}✓ สร้าง .env แล้ว${NC}"
    echo ""
fi

# Interactive configuration
echo -e "${YELLOW}ตั้งค่าครั้งนี้:${NC}"
echo ""

# Get current values from .env (if exist)
set -a
source .env 2>/dev/null || true
set +a

# Ask for N8N_COUNT
current_count="${N8N_COUNT:-25}"
read -p "จำนวนนักเรียน [default: $current_count]: " input_count
N8N_COUNT="${input_count:-$current_count}"

# Ask for BASE_HOST
current_host="${BASE_HOST:-datafabric.academy}"
read -p "โดเมนที่ใช้ [default: $current_host]: " input_host
BASE_HOST="${input_host:-$current_host}"

# Update .env
sed -i "s/^N8N_COUNT=.*/N8N_COUNT=$N8N_COUNT/" .env
sed -i "s/^BASE_HOST=.*/BASE_HOST=$BASE_HOST/" .env

echo ""
echo -e "${GREEN}✓ ตั้งค่า:${NC}"
echo "  จำนวนนักเรียน: $N8N_COUNT"
echo "  โดเมน: $BASE_HOST"
echo ""

# Regenerate docker-compose
echo -e "${YELLOW}กำลังสร้าง docker-compose.generated.yml...${NC}"
if ! N8N_COUNT="$N8N_COUNT" BASE_HOST="$BASE_HOST" python3 scripts/generate-compose.py; then
    echo -e "${RED}✗ สร้างไฟล์ล้มเหลว${NC}"
    exit 1
fi
echo -e "${GREEN}✓ สร้างไฟล์สำเร็จ${NC}"
echo ""

# Start stack
echo -e "${YELLOW}กำลังรัน Docker stack...${NC}"
docker compose -f docker-compose.yml -f docker-compose.generated.yml down 2>/dev/null || true
docker compose -f docker-compose.yml -f docker-compose.generated.yml up -d

echo ""
echo -e "${GREEN}✓ Stack กำลังรัน${NC}"
echo ""

# Wait for health check
echo -e "${YELLOW}รอให้ services พร้อม...${NC}"
sleep 5

# Check status
if docker compose -f docker-compose.yml -f docker-compose.generated.yml ps | grep -q "n8n-1"; then
    echo -e "${GREEN}✓ n8n containers ขึ้นครบ${NC}"
else
    echo -e "${YELLOW}⚠ รออีกสักครู่...${NC}"
    sleep 5
fi

echo ""
echo -e "${BLUE}=====================================${NC}"
echo -e "${GREEN}   พร้อมสอนแล้ว!${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""
echo "นักเรียนเข้าได้ที่:"
for i in 1 2 3; do
    printf "  https://n8n%02d.%s\n" "$i" "$BASE_HOST"
done
echo "  ..."
printf "  https://n8n%02d.%s\n" "$N8N_COUNT" "$BASE_HOST"
echo ""
echo "ตรวจสอบสถานะ: docker compose -f docker-compose.yml -f docker-compose.generated.yml ps"
echo "ดู logs: docker logs n8n-1"
echo ""

# Save class info
cat > last-class-info.txt << EOF
Class started: $(date)
N8N_COUNT: $N8N_COUNT
BASE_HOST: $BASE_HOST
URLs:
$(for i in $(seq 1 $N8N_COUNT); do printf "https://n8n%02d.%s\n" "$i" "$BASE_HOST"; done)
EOF

echo -e "${GREEN}บันทึกข้อมูลที่: last-class-info.txt${NC}"
