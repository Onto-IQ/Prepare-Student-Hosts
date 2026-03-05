# ⚠️ Terminal Exposure Report — REDACTED VERSION

> **INTERNAL USE ONLY** — This file contains sanitized information. The original with full details is kept locally only.

---

## 🔴 ข้อมูลที่ Exposed ใน Terminal History

จากการ debug ก่อนหน้า มี **API Keys/Tokens** ปรากฏใน terminal output:

### ประเภทข้อมูลที่ exposed:
- **Cloudflare Global API Keys** — 3 keys
- **Cloudflare API Token** — 1 token  
- **Cloudflare Tunnel ID** — 1 ID
- **Zone ID** — 1 ID

> **หมายเหตุ:** รายละเอียดเต็มอยู่ใน `TERMINAL-EXPOSURE-REPORT-ORIGINAL.md` (local only, ไม่ commit)

---

## 🛡️ การดำเนินการที่ต้องทำทันที

### 1. หมุน (Rotate) API Keys/Tokens

```bash
# ไปที่ Cloudflare Dashboard
https://dash.cloudflare.com/profile/api-tokens

# ลบ Keys/Tokens เก่าที่ exposed แล้วสร้างใหม่
# อัปเดตใน .env บน server
nano /opt/Prepare-Student-Hosts/.env
```

### 2. ล้าง Terminal History

```bash
history -c
history -w
# หรือลบบรรทัดที่มี sensitive data
```

### 3. ตรวจสอบ Log Files

```bash
sudo grep -r "API_KEY_PATTERN" /var/log/ 2>/dev/null
```

---

## 🔒 Best Practices สำหรับอนาคต

1. **อย่าใส่ Secrets ใน Command Line** — ใช้ `.env` หรือ file
2. **ใช้ Environment Variables** — `source .env` แทน `export KEY=value`
3. **หมุน Keys ทุก 3-6 เดือน**
4. **ใช้ GitLeaks ตรวจสอบ** ก่อน commit

---

## 📋 Checklist หลังแก้ไข

- [ ] หมุน API Keys/Tokens ที่ exposed
- [ ] ล้าง terminal history
- [ ] ตรวจสอบ log files
- [ ] ทดสอบระบบยังทำงาน

---

**หมายเหตุ:** รายงานฉบับเต็ม (มีรายละเอียด secrets) เก็บไว้ที่ `/root/TERMINAL-EXPOSURE-REPORT-ORIGINAL.md` บน server เท่านั้น ไม่ commit ขึ้น GitHub
