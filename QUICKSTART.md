# ⚡ Quick Start

สรุปคำสั่งสำหรับใช้งานจริง

---

## สำหรับครั้งแรก (First Time Setup)

```bash
# 1. ติดตั้งบนเซิร์ฟเวอร์ใหม่
cd /opt/Prepare-Student-Hosts

# 2. ตั้งค่า .env
cp .env.example .env
nano .env
# แก้: BASE_HOST, POSTGRES_PASSWORD, N8N_COUNT

# 3. รันคำสั่งเดียว
./scripts/setup-class.sh
```

---

## สำหรับทุกครั้งสอน (Every Class)

```bash
# ใช้คำสั่งเดียวนี้ — ถามจำนวนนักเรียนและโดเมนอัตโนมัติ
cd /opt/Prepare-Student-Hosts && ./scripts/setup-class.sh
```

---

## สำหรับแก้ไขเร่งด่วน

```bash
# แก้ 404 ทุกเครื่อง
./scripts/regenerate-and-up.sh

# Backup
./scripts/backup-n8n-volumes.sh backup

# Restart ทั้งหมด
docker compose -f docker-compose.yml -f docker-compose.generated.yml restart
```

---

## URL ที่นักเรียนใช้

ถ้า `BASE_HOST=datafabric.academy`:

- https://n8n01.datafabric.academy
- https://n8n02.datafabric.academy
- ...
- https://n8n25.datafabric.academy

---

## สถานะปัจจุบัน (Current Status)

| Service | Status |
|---------|--------|
| n8n-01 ถึง n8n-25 | ✅ Running |
| PostgreSQL | ✅ Healthy |
| Traefik | ✅ Running |
| Cloudflare Tunnel | ✅ Connected |

---

**พร้อมสอนแล้ว!** 🎉
