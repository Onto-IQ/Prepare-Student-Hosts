# 📦 Project Summary — n8n Class Environment

สรุปโครงสร้างและเอกสารทั้งหมด

---

## 🎯 โครงสร้างโปรเจกต์

```
Prepare-Student-Hosts/
│
├── 📄 เอกสารหลัก
│   ├── README.md              → เอกสารหลัก (การใช้งานทั่วไป)
│   ├── QUICKSTART.md          → สรุปคำสั่งเร็ว ⚡
│   ├── DEPLOYMENT.md          → คู่มือติดตั้งบนเซิร์ฟเวอร์ใหม่
│   ├── SECURITY.md            → ความปลอดภัยและ Sensitive Data
│   ├── ENV-REFERENCE.md      → รายการตัวแปรใน .env
│   └── SUMMARY.md            → ไฟล์นี้
│
├── ⚙️ ไฟล์ตั้งค่า
│   ├── .env.example           → ตัวอย่าง .env (ไม่มี secrets)
│   ├── .env                   → ไฟล์จริง (ไม่ commit — มี secrets)
│   ├── .gitignore             → รายการไฟล์ที่ไม่ commit
│   ├── docker-compose.yml     → Base services (postgres, traefik)
│   └── docker-compose.generated.yml → Auto-generated n8n services
│
├── 🛠️ Scripts หลักที่ใช้
│   ├── setup-class.sh         → 🔥 สคริปต์หลักสำหรับทุกครั้งสอน
│   ├── regenerate-and-up.sh   → Regenerate และ restart
│   ├── backup-n8n-volumes.sh → Backup/restore n8n data
│   └── fix-postgres-password.sh → แก้รหัสผ่าน PostgreSQL
│
└── 💾 Data (ไม่ commit)
    ├── data/postgres/         → PostgreSQL data
    └── data/letsencrypt/      → SSL certificates
```

---

## 📚 เอกสารแต่ละไฟล์

| ไฟล์ | ใช้เมื่อไหร่ | มีอะไรบ้าง |
|------|-------------|-----------|
| `README.md` | อ่านครั้งแรก | ภาพรวม, การใช้งาน, troubleshooting |
| `QUICKSTART.md` | สอนครั้งต่อไป | คำสั่งเดียวที่ใช้บ่อย |
| `DEPLOYMENT.md` | ติดตั้งเซิร์ฟเวอร์ใหม่ | ขั้นตอนติดตั้งแบบ step-by-step |
| `SECURITY.md` | ตรวจสอบความปลอดภัย | อะไรเป็น sensitive, วิธีจัดการ |
| `ENV-REFERENCE.md` | แก้ไข .env | รายการตัวแปร, ตัวอย่างค่า |

---

## 🔐 Sensitive Information

### เก็บใน `.env` เท่านั้น (ห้าม commit)

- `POSTGRES_PASSWORD` — รหัสผ่านฐานข้อมูล
- `CF_API_TOKEN` / `CF_API_KEY` — Cloudflare API
- `/etc/cloudflared/*.json` — Tunnel credentials

---

## 🚀 คำสั่งที่ใช้งาน

### สำหรับทุกครั้งสอน

```bash
cd /opt/Prepare-Student-Hosts && ./scripts/setup-class.sh
```

### สำหรับติดตั้งครั้งแรก

```bash
# 1. ติดตั้ง Docker (ดู DEPLOYMENT.md)
# 2. ตั้งค่า Cloudflare Tunnel (ดู DEPLOYMENT.md)
# 3. รัน
./scripts/setup-class.sh
```

---

## 🌐 URL ที่ใช้งานได้

ถ้า `BASE_HOST=datafabric.academy`:

- https://n8n01.datafabric.academy
- https://n8n02.datafabric.academy
- ... (ถึง n8n25)

---

## 🎓 สรุปสำหรับครู/อาจารย์

```bash
# ทุกครั้งที่สอนใหม่ — ใช้คำสั่งนี้คำสั่งเดียว:
./scripts/setup-class.sh
```

**พร้อมสอนแล้ว!** 🎉

---

**Version:** 2.0 (Updated 2026-03-05)
