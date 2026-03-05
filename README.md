# Prepare-Student-Hosts

สแต็กสำหรับเตรียม **n8n หลาย instance** ให้นักเรียน/ผู้เรียนแต่ละคนเข้าใช้ได้คนละ URL (หนึ่ง instance ต่อคน) ใช้ **PostgreSQL**, **Traefik** และ Docker Compose

เหมาะกับห้องเรียนหรือ workshop ที่ต้องแจก n8n ให้ผู้เรียนหลายคนโดยไม่ต้องแชร์บัญชี

**สารบัญ:** [เริ่มต้นใช้งาน](#เริ่มต้นใช้งาน-สำหรับทุกครั้งสอน) · [การติดตั้ง](#การติดตั้งครั้งแรก) · [Cloudflare Tunnel](#cloudflare-tunnel-แนะนำ) · [แก้ปัญหา](#แก้ปัญหา) · [Backup](#backup--restore)

---

## 🚀 เริ่มต้นใช้งาน (สำหรับทุกครั้งสอน)

ใช้คำสั่งเดียวสำหรับการ deploy ใหม่ทั้งหมด:

```bash
# 1. Clone หรือเข้าไปในโฟลเดอร์โปรเจกต์
cd /opt/Prepare-Student-Hosts

# 2. รันสคริปต์เริ่มต้น (ถ้ายังไม่มี .env จะถามให้สร้าง)
./scripts/setup-class.sh
```

สคริปต์นี้จะ:
- ตรวจสอบและสร้าง `.env` ถ้ายังไม่มี
- ถามจำนวนนักเรียน (N8N_COUNT)
- ถามโดเมนที่ใช้ (BASE_HOST)
- Regenerate docker-compose
- Start stack
- แสดง URLs ทั้งหมดที่นักเรียนต้องใช้

---

## 📋 การติดตั้งครั้งแรก

### ความต้องการของระบบ

- Docker และ Docker Compose (v2)
- Python 3
- โดเมนบน Cloudflare หรือใช้ nip.io

### ขั้นตอนติดตั้ง

#### 1. Clone โปรเจกต์

```bash
git clone https://github.com/Onto-IQ/Prepare-Student-Hosts.git /opt/Prepare-Student-Hosts
cd /opt/Prepare-Student-Hosts
```

#### 2. ตั้งค่า Environment

```bash
cp .env.example .env
nano .env  # แก้ค่าตามต้องการ
```

ตัวแปรสำคัญ:

| ตัวแปร | ค่าตัวอย่าง | คำอธิบาย |
|--------|------------|----------|
| `BASE_HOST` | `datafabric.academy` | โดเมนหลัก — นักเรียนจะเข้าที่ `n8n01.BASE_HOST` |
| `N8N_COUNT` | `25` | จำนวนนักเรียน/instance |
| `POSTGRES_PASSWORD` | (สร้างเอง) | รหัสผ่านฐานข้อมูล |
| `TRAEFIK_ACME_EMAIL` | `admin@domain.com` | อีเมลสำหรับ Let's Encrypt |

#### 3. รันครั้งแรก

```bash
./scripts/setup-class.sh
```

---

## ☁️ Cloudflare Tunnel (แนะนำ)

ใช้ Cloudflare Tunnel แทนการเปิดพอร์ต 80/443 — ได้ HTTPS อัตโนมัติและไม่ต้องกังวลเรื่อง Firewall

### ขั้นตอนติดตั้ง

#### 1. ติดตั้ง cloudflared

```bash
# Ubuntu 22.04/24.04
sudo apt update
sudo apt install -y curl lsb-release

sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg \
  | sudo tee /usr/share/keyrings/cloudflare-main.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] \
https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/cloudflared.list > /dev/null

sudo apt update
sudo apt install -y cloudflared
```

#### 2. สร้าง Tunnel

```bash
# Login (จะเปิด browser ให้ authorize)
cloudflared tunnel login

# สร้าง tunnel
cloudflared tunnel create n8n-class

# จด Tunnel ID ที่ได้ (เช่น xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
```

#### 3. ตั้งค่า Tunnel

สร้างไฟล์ `/etc/cloudflared/config.yml`:

```yaml
tunnel: <TUNNEL_ID>
credentials-file: /etc/cloudflared/<TUNNEL_ID>.json

ingress:
  - hostname: '*.datafabric.academy'
    service: http://localhost:80
  - service: http_status:404
```

ย้าย credentials:
```bash
sudo cp ~/.cloudflared/<TUNNEL_ID>.json /etc/cloudflared/
sudo chown root:root /etc/cloudflared/<TUNNEL_ID>.json
sudo chmod 600 /etc/cloudflared/<TUNNEL_ID>.json
```

#### 4. สร้าง DNS Records

```bash
# Wildcard สำหรับทุก n8n instance
cloudflared tunnel route dns <TUNNEL_ID> '*.datafabric.academy'
```

#### 5. รันเป็น Service

```bash
sudo cloudflared service install
sudo systemctl enable --now cloudflared
```

---

## 🔧 สคริปต์ที่มีให้ใช้

| สคริปต์ | ใช้เมื่อไหร่ |
|---------|------------|
| `./scripts/setup-class.sh` | **เริ่มต้นใช้งานทุกครั้ง** — ตั้งค่าและรัน stack |
| `./scripts/regenerate-and-up.sh` | แก้ไข `.env` แล้วต้องการ regenerate |
| `./scripts/backup-n8n-volumes.sh backup` | Backup ข้อมูล n8n |
| `./scripts/backup-n8n-volumes.sh restore` | Restore ข้อมูล n8n |

---

## 🆘 แก้ปัญหา

### Error 1033 — Cloudflare Tunnel error

**สาเหตุ:** DNS ไม่ได้ชี้มาที่ tunnel ปัจจุบัน

**แก้:**
1. ตรวจสอบว่า `*.datafabric.academy` เป็น CNAME ชี้ไป `<TUNNEL_ID>.cfargotunnel.com`
2. ตรวจสอบว่าไม่มี A/AAAA records ซ้ำ
3. รีสตาร์ท tunnel: `sudo systemctl restart cloudflared`

### 404 Page Not Found (ทุกเครื่อง)

**สาเหตุ:** BASE_HOST ใน `.env` ไม่ตรงกับ URL ที่เข้า

**แก้:**
```bash
# แก้ .env ให้ตรงกับ URL
nano .env  # แก้ BASE_HOST

# รีเจนและรีสตาร์ท
./scripts/regenerate-and-up.sh
```

### Bad Gateway (502)

**สาเหตุ:** Postgres password ไม่ตรง

**แก้:**
```bash
sh scripts/fix-postgres-password.sh
./scripts/regenerate-and-up.sh
```

---

## 💾 Backup / Restore

### Backup

```bash
# Backup ข้อมูล n8n
./scripts/backup-n8n-volumes.sh backup

# Backup Postgres (คัดลอกโฟลเดอร์)
cp -r data/postgres backups/postgres-$(date +%Y%m%d)
```

### Restore

```bash
# Restore n8n
./scripts/backup-n8n-volumes.sh restore

# รีสตาร์ท stack
./scripts/regenerate-and-up.sh
```

---

## 📝 หมายเหตุสำคัญ

- **อย่า commit `.env`** — มีรหัสผ่านและข้อมูลสำคัญ
- **ชื่อ volumes:** ใช้ named volumes (`n8n_1_data`, `n8n_2_data`, ...) ไม่ต้อง chown
- **Wildcard DNS:** Cloudflare รองรับ wildcard (`*.domain.com`) สำหรับทุก subdomain
- **Subdomain 4 ระดับ:** Cloudflare ฟรีไม่รองรับ (เช่น `n8n01.student.datafabric.academy` — นี่คือ 4 ระดับ) ใช้ `n8n01.datafabric.academy` (3 ระดับ) แทน

---

## 📚 โครงสร้างโฟลเดอร์

```
Prepare-Student-Hosts/
├── .env                      # ค่าตัวแปร (ไม่ commit)
├── .env.example              # ตัวอย่าง
├── docker-compose.yml        # Base services (postgres, traefik)
├── docker-compose.generated.yml  # Auto-generated n8n services
├── scripts/
│   ├── setup-class.sh        # 🔥 สคริปต์หลักสำหรับทุกครั้งสอน
│   ├── generate-compose.py   # Generate compose file
│   ├── regenerate-and-up.sh # Regenerate + restart
│   ├── backup-n8n-volumes.sh # Backup/restore volumes
│   └── postgres-init/        # Database init scripts
└── data/
    ├── postgres/             # Postgres data
    └── letsencrypt/          # SSL certificates (ถ้าใช้)
```

---

## 🎯 สรุปคำสั่งสำหรับครู/อาจารย์

```bash
# ทุกครั้งที่สอนใหม่ — ใช้คำสั่งเดียวนี้:
cd /opt/Prepare-Student-Hosts && ./scripts/setup-class.sh

# แก้ไขจำนวนนักเรียนหรือโดเมน:
nano .env
./scripts/regenerate-and-up.sh

# Backup ก่อนจบคลาส:
./scripts/backup-n8n-volumes.sh backup
```

---

**พร้อมใช้งาน!** 🎉
