# 🔐 Security Guide — ข้อมูล Sensitive และการจัดการ

เอกสารนี้อธิบายว่าข้อมูลใดบ้างที่เป็น **Sensitive Information** และต้องเก็บไว้ใน `.env` เท่านั้น

---

## ⚠️ Sensitive Information ที่ต้องอยู่ใน `.env` เท่านั้น

| ข้อมูล | รายละเอียด | ตัวอย่างรูปแบบ |
|--------|-----------|--------------|
| **POSTGRES_PASSWORD** | รหัสผ่านฐานข้อมูล PostgreSQL | `xxxxxxxx...` (32+ chars) |
| **CF_API_TOKEN** | Cloudflare API Token | `xxxxxxxx...` |
| **CF_API_KEY** | Cloudflare Global API Key | `xxxxxxxx...` |
| **Tunnel Credentials** | ไฟล์ `.json` ที่ได้จาก `cloudflared tunnel create` | `xxxx-xxxx.json` |

---

## ❌ ห้าม Commit ข้อมูลเหล่านี้

### 1. รหัสผ่านและ Key

```bash
# ❌ ห้าม hardcode:
POSTGRES_PASSWORD="mysecretpassword"
CF_API_KEY="xxxxxxxx"

# ✅ ให้ใช้ environment variable:
source .env
```

### 2. Tunnel Credentials

```bash
# ❌ ห้าม commit:
/etc/cloudflared/xxxx-xxxx.json

# ✅ ย้ายไปที่ปลอดภัย:
sudo cp ~/.cloudflared/*.json /etc/cloudflared/
sudo chmod 600 /etc/cloudflared/*.json
```

---

## ✅ ข้อมูลที่ Commit ได้ (ไม่ Sensitive)

| ข้อมูล | ตัวอย่าง |
|--------|----------|
| BASE_HOST | `datafabric.academy` |
| N8N_COUNT | `25` |
| GENERIC_TIMEZONE | `Asia/Bangkok` |
| USE_LETSENCRYPT | `false` |
| TRAEFIK_ACME_EMAIL | `admin@datafabric.academy` |
| POSTGRES_USER | `n8n` |

---

## 🔒 แนวทางปฏิบัติ

### 1. ตั้งค่า `.env` ครั้งแรก

```bash
cp .env.example .env
nano .env
# ใส่รหัสผ่านที่แข็งแรง (openssl rand -base64 32)
```

### 2. อย่า commit `.env`

```bash
# .gitignore มีแล้ว:
.env
.env.local
*.json
```

### 3. สร้างรหัสผ่านแข็งแรง

```bash
openssl rand -base64 32
```

### 4. จำกัดการเข้าถึง

```bash
chmod 600 .env
chmod 600 /etc/cloudflared/*.json
```

---

## 🚨 ถ้าพลาด Commit Sensitive Data

```bash
# 1. ลบออกจาก Git History
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch .env' \
  --prune-empty --tag-name-filter cat -- --all

# 2. เปลี่ยน Secret ทันที
# 3. สร้างใหม่และอัปเดต
```

---

## 🛡️ การจัดเก็บบน Production Server

```bash
# สร้าง .env บน server เอง
cp .env.example .env
nano .env

# จำกัดสิทธิ์
chmod 600 .env
chown root:root .env

# เก็บ backup แยก
cp .env /root/.n8n-env-backup
chmod 600 /root/.n8n-env-backup
```

---

## 📋 Checklist ก่อน Commit

- [ ] `.env` อยู่ใน `.gitignore`
- [ ] ไม่มีรหัสผ่านในโค้ด
- [ ] ไม่มี API Key ในโค้ด
- [ ] ตรวจสอบด้วย `git diff --cached`

---

**หลักการสำคัญ:** Secret อยู่ใน `.env` ที่เดียว ไม่แพร่กระจาย ไม่ commit!
