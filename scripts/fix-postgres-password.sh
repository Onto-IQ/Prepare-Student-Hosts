#!/bin/sh
# รีเซ็ตรหัสผ่าน user n8n ใน Postgres ให้ตรงกับ POSTGRES_PASSWORD ใน .env
# ใช้เมื่อ n8n ขึ้น "password authentication failed" / Bad Gateway
# รันจากโฟลเดอร์โปรเจกต์: sh scripts/fix-postgres-password.sh

set -e
cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  echo ".env not found. Create from .env.example and set POSTGRES_PASSWORD."
  exit 1
fi

# อ่านรหัสที่ต้องการตั้งจาก .env
NEW_PASS="n8npassword"
if [ -f .env ]; then
  val=$(grep -E '^POSTGRES_PASSWORD=' .env 2>/dev/null | cut -d= -f2- | sed "s/^[\"']//;s/[\"']$//" | head -1)
  [ -n "$val" ] && NEW_PASS="$val"
fi

# ลองรหัสที่อาจใช้ตอน init ครั้งแรก
for TRY in "n8npassword" "change_this_to_a_secure_password" "$NEW_PASS"; do
  if [ -z "$TRY" ]; then continue; fi
  echo "Trying to connect with existing password..."
  if docker exec -e PGPASSWORD="$TRY" n8n-postgres psql -U n8n -d postgres -c "ALTER USER n8n WITH PASSWORD '$NEW_PASS';" 2>/dev/null; then
    echo "Password updated to match .env. Restart n8n: docker compose -f docker-compose.yml -f docker-compose.generated.yml restart \$(docker compose -f docker-compose.yml -f docker-compose.generated.yml ps -q --services | grep -E '^n8n-[0-9]+$')"
    exit 0
  fi
done

echo "Could not connect to Postgres. Ensure container n8n-postgres is running and .env POSTGRES_PASSWORD is set."
echo "If you never changed the password, it may be: n8npassword or the value from .env.example."
exit 1
