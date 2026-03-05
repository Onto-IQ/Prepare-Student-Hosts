# 📋 Environment Variables Reference

เอกสารนี้สรุปว่าตัวแปรใดบ้างใน `.env`

---

## 🔴 Sensitive (ห้าม Commit — ใส่ใน `.env` เท่านั้น)

| ตัวแปร | คำอธิบาย | ตัวอย่างรูปแบบ |
|--------|----------|--------------|
| `POSTGRES_PASSWORD` | รหัสผ่าน PostgreSQL | `xxxxxxxx...` (32+ chars) |
| `CF_API_TOKEN` | Cloudflare API Token | `xxxxxxxx...` |
| `CF_API_KEY` | Cloudflare Global API Key | `xxxxxxxx...` |
| `CF_EMAIL` | อีเมล Cloudflare account | `admin@domain.com` |

---

## 🟡 Configurable (ใส่ใน `.env`)

| ตัวแปร | คำอธิบาย | ค่าปกติ | แก้บ่อย? |
|--------|----------|---------|----------|
| `BASE_HOST` | โดเมนหลัก | `datafabric.academy` | ✅ ทุกครั้ง |
| `N8N_COUNT` | จำนวนนักเรียน | `25` | ✅ ทุกครั้ง |
| `TRAEFIK_ACME_EMAIL` | อีเมลสำหรับ SSL | `admin@domain.com` | ⚠️ บางครั้ง |
| `GENERIC_TIMEZONE` | Timezone | `Asia/Bangkok` | ❌ แทบไม่ |
| `USE_LETSENCRYPT` | ใช้ HTTPS ตัวเอง? | `false` | ❌ ไม่ |

---

## 🟢 Non-Sensitive (ใส่ใน `.env` หรือ commit ได้)

| ตัวแปร | คำอธิบาย | ค่าปกติ |
|--------|----------|---------|
| `POSTGRES_USER` | ชื่อ user PostgreSQL | `n8n` |
| `POSTGRES_DB` | ชื่อ database | `n8n` |

---

## 📝 ตัวอย่าง `.env` สำหรับใช้งานจริง

```bash
# =============================================================================
# 🔴 SENSITIVE — ห้าม Commit
# =============================================================================

# PostgreSQL Password (สร้างด้วย: openssl rand -base64 32)
POSTGRES_PASSWORD=your-secure-password-here

# Cloudflare Credentials (ถ้าต้องการแก้ DNS ผ่าน API)
# CF_API_TOKEN=your-token-here
# CF_API_KEY=your-global-api-key-here
# CF_EMAIL=your-cloudflare-email

# =============================================================================
# 🟡 CONFIGURABLE — แก้ได้ตามแต่ละครั้งสอน
# =============================================================================

# โดเมนหลัก — นักเรียนเข้าที่ n8n01.BASE_HOST
BASE_HOST=datafabric.academy

# จำนวนนักเรียน/instance
N8N_COUNT=25

# Timezone
GENERIC_TIMEZONE=Asia/Bangkok

# ใช้ Let's Encrypt? (false = ใช้ Cloudflare หรือ HTTP)
USE_LETSENCRYPT=false

# อีเมลสำหรับ SSL (ถ้าใช้ LE)
TRAEFIK_ACME_EMAIL=admin@datafabric.academy

# =============================================================================
# 🟢 NON-SENSITIVE
# =============================================================================

POSTGRES_USER=n8n
POSTGRES_DB=n8n
```

---

## 🔄 การใช้งานตามสถานการณ์

### สอนครั้งแรกบนเซิร์ฟเวอร์ใหม่

```bash
# 1. สร้าง .env ใหม่บน server
cp .env.example .env
nano .env

# 2. ใส่ POSTGRES_PASSWORD (สร้างใหม่)
openssl rand -base64 32

# 3. ใส่ BASE_HOST, N8N_COUNT

# 4. รัน
./scripts/setup-class.sh
```

### สอนครั้งต่อไป (เซิร์ฟเวอร์เดิม)

```bash
# แค่รันคำสั่งเดียว — จะถามจำนวนนักเรียนใหม่
./scripts/setup-class.sh
```

### เปลี่ยนโดเมน

```bash
nano .env  # แก้ BASE_HOST=newdomain.com
./scripts/regenerate-and-up.sh
```

---

## 🎓 สรุปให้จำ

| ถามตัวเองว่า | ถ้าใช่ → เก็บใน | ถ้าไม่ → Commit ได้ |
|------------|---------------|-------------------|
| เป็นรหัสผ่าน? | `.env` | — |
| เป็น Key/Token? | `.env` | — |
| เปลี่ยนทุกครั้งสอน? | `.env` | default |
| ค่าเดิมตลอด? | Commit ได้ | `.env` ก็ได้ |

---

## ⚡ Command Cheat Sheet

```bash
# สร้างรหัสผ่านแข็งแรง
openssl rand -base64 32

# ตรวจสอบว่า .env มีอะไรบ้าง (ไม่แสดงค่า)
grep -E "^[A-Z]" .env | cut -d= -f1

# Backup .env
cp .env .env.backup.$(date +%Y%m%d)

# ลบ .env ออกจาก git history (ถ้าพลาด commit)
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch .env' HEAD
```
