# Prepare-Student-Hosts

สแต็กสำหรับเตรียม **n8n หลาย instance** ให้นักเรียน/ผู้เรียนแต่ละคนเข้าใช้ได้คนละ URL (หนึ่ง instance ต่อคน) ใช้ **PostgreSQL**, **Traefik** และ Docker Compose

เหมาะกับห้องเรียนหรือ workshop ที่ต้องแจก n8n ให้ผู้เรียนหลายคนโดยไม่ต้องแชร์บัญชี

**สารบัญ:** [การติดตั้งและรัน](#การติดตั้งและรัน) · [โครงสร้างโฟลเดอร์](#โครงสร้างโฟลเดอร์) · [Deploy บน VPS](#deploy-บน-vps-ตัวอย่าง-hostinger) · [nip.io](#กรณีไม่มีโดเมนใช้แค่-vps--hostname-hostinger) · [แก้ปัญหา](#404-page-not-found-ทุกเครื่องทุก-instance) · [Backup](#backup--restore)

## สถาปัตยกรรม

| ส่วน | คำอธิบาย |
|------|----------|
| **Postgres** | ฐานข้อมูลกลาง — แต่ละ n8n instance ใช้ database แยก (`n8n_1`, `n8n_2`, …) |
| **Traefik** | Reverse proxy + TLS (Let's Encrypt) — route ตาม host เช่น `n8n01.yourdomain.com` |
| **n8n (N ตัว)** | จำนวน instance กำหนดจาก `N8N_COUNT` สร้างผ่าน `scripts/generate-compose.py` |

## ความต้องการของระบบ

- Docker และ Docker Compose (v2)
- Python 3 (สำหรับสคริปต์ generate compose)
- **โดเมนหรือ nip.io** — มีโดเมนให้ตั้ง DNS ชี้มาที่เซิร์ฟเวอร์ (A/wildcard); ไม่มีโดเมนใช้ [nip.io](https://nip.io) กับ IP ของ VPS ได้

## การติดตั้งและรัน

### 1. Clone / เข้าโฟลเดอร์โปรเจกต์

```bash
git clone https://github.com/Onto-IQ/Prepare-Student-Hosts.git
cd Prepare-Student-Hosts
```

### 2. ตั้งค่า Environment

คัดลอกไฟล์ตัวอย่างแล้วแก้ค่าให้ตรงกับเซิร์ฟเวอร์และโดเมน:

```bash
cp .env.example .env
# แก้ไข .env — โดยเฉพาะ POSTGRES_PASSWORD, BASE_HOST, TRAEFIK_ACME_EMAIL
```

ตัวแปรสำคัญสำหรับโหมด multi-instance:

| ตัวแปร | ความหมาย |
|--------|----------|
| `BASE_HOST` | โดเมนหรือ host สำหรับ subdomain (เช่น `yourdomain.com` หรือ `76.13.219.184.nip.io`) — URL จะเป็น `n8n01.BASE_HOST`, `n8n02.BASE_HOST`, … |
| `N8N_COUNT` | จำนวน n8n instances (default 25 ใช้ตอน generate) |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` | ใช้กับ Postgres และ n8n ทุก instance |
| `TRAEFIK_ACME_EMAIL` | อีเมลสำหรับ Let's Encrypt (เมื่อใช้ HTTPS) |

### 3. สร้างไฟล์ Docker Compose สำหรับ n8n (generated)

สร้าง `docker-compose.generated.yml` จากค่าใน `.env`:

```bash
export $(grep -v '^#' .env | xargs)
N8N_COUNT=${N8N_COUNT:-25} BASE_HOST=${BASE_HOST:-yourdomain.com} python3 scripts/generate-compose.py
```

หรือระบุค่าตรง: `N8N_COUNT=25 BASE_HOST=yourdomain.com python3 scripts/generate-compose.py`

ไฟล์ที่ได้: `docker-compose.generated.yml` (ห้ามแก้ด้วยมือ — แก้ `.env` แล้ว regenerate ใหม่)

### 4. สร้างฐานข้อมูลใน Postgres (ครั้งแรกเท่านั้น)

สคริปต์ใน `scripts/postgres-init/` จะรันอัตโนมัติเมื่อ volume Postgres ถูกสร้างครั้งแรก และสร้าง DB `n8n_1` … `n8n_25`  

ถ้าใช้ `N8N_COUNT` มากกว่า 25 ต้องแก้ `scripts/postgres-init/01-create-databases.sh` ให้สร้าง DB ถึงจำนวนที่ต้องการ (หรือใช้ค่าในสคริปต์ให้ตรงกับ `N8N_COUNT` สูงสุดที่ใช้)

### 5. รันสแต็ก

```bash
docker compose -f docker-compose.yml -f docker-compose.generated.yml up -d
```

ข้อมูล n8n เก็บใน **Docker named volumes** (`n8n_1_data`, `n8n_2_data`, …) — ไม่ต้อง chown โฟลเดอร์บน host จึงรันบนเครื่องใหม่ได้ทันทีหลัง generate + up

**ถ้าใช้ nip.io (เช่น `http://n8n01.76.13.219.184.nip.io/`) หรือแก้ 404:** ใส่ `BASE_HOST=76.13.219.184.nip.io` ใน `.env` (ใช้ IP จริงของ VPS) แล้วรันคำสั่งเดียว `./scripts/regenerate-and-up.sh` เพื่อ regenerate และ restart stack

### Down / หยุดทั้ง stack

หยุดและลบ containers ทั้งหมด (postgres, traefik, n8n ทุกตัว):

```bash
docker compose -f docker-compose.yml -f docker-compose.generated.yml down
```

- ข้อมูล Postgres ยังอยู่ที่ `./data/postgres`
- ข้อมูล n8n ยังอยู่ที่ Docker named volumes (`docker volume ls | grep n8n`) — ถ้าต้องการลบ volume ด้วยให้ใช้ `down -v`

## โครงสร้างโฟลเดอร์

```
Prepare-Student-Hosts/
├── .env                    # ค่าจริง (ไม่ commit)
├── .env.example            # ตัวอย่างตัวแปร
├── docker-compose.yml      # Base: postgres + traefik
├── docker-compose.generated.yml   # สร้างจากสคริปต์ (ไม่ commit ก็ได้ — generate บนเซิร์ฟเวอร์)
├── scripts/
│   ├── generate-compose.py       # สร้าง docker-compose.generated.yml
│   ├── regenerate-and-up.sh      # regenerate แล้ว down/up (แก้ 404)
│   ├── fix-postgres-password.sh   # แก้รหัส Postgres เมื่อ 502
│   ├── backup-n8n-volumes.sh      # backup/restore named volumes ของ n8n
│   └── postgres-init/
│       └── 01-create-databases.sh  # สร้าง DB n8n_1..n8n_25 ตอน init
├── HostList.md             # ตัวอย่างรายการ URL แจกนักเรียน (อัปเดตหลัง generate)
└── data/                   # ข้อมูลรันจริง (ไม่ commit)
    ├── postgres/
    └── letsencrypt/
# ข้อมูล n8n อยู่ใน Docker named volumes (n8n_1_data, n8n_2_data, …) — ดูด้วย docker volume ls
```

## การตั้งชื่อ

| รูปแบบ | ตัวอย่าง |
|--------|----------|
| Subdomain | `n8n01`, `n8n02`, … `n8n25` |
| URL เต็ม | `https://n8n01.yourdomain.com` |
| Service (container) | `n8n-1`, `n8n-2`, … |
| Database | `n8n_1`, `n8n_2`, … |

## Deploy บน VPS (ตัวอย่าง Hostinger)

ขั้นตอนด้านล่างใช้ได้กับ VPS ที่รัน Ubuntu (เช่น Hostinger VPS, DigitalOcean, Linode ฯลฯ)

### 1. สร้าง VPS และ SSH

- สร้าง VPS แบบ Ubuntu 22.04 LTS ขึ้นไป (แนะนำ RAM อย่างน้อย 2GB สำหรับรันหลาย n8n)
- บันทึก **IP ของเซิร์ฟเวอร์** และรหัสผ่าน/SSH key
- SSH เข้าเซิร์ฟเวอร์:

```bash
ssh root@YOUR_SERVER_IP
# หรือ ssh ubuntu@YOUR_SERVER_IP ถ้าใช้ user ubuntu
```

### 2. ติดตั้ง Docker และ Docker Compose

บน Ubuntu:

```bash
apt update && apt install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

ตรวจสอบ:

```bash
docker --version && docker compose version
```

### 3. ตั้งค่า DNS

ที่ผู้ให้บริการโดเมน (หรือ Hostinger Domain/DNS):

- **แบบ wildcard (แนะนำ)**  
  เพิ่ม A record: `*.yourdomain.com` → IP ของ VPS  
  จะได้ `n8n01.yourdomain.com`, `n8n02.yourdomain.com`, … ใช้ได้ทุก subdomain

- **แบบระบุทีละ subdomain**  
  เพิ่ม A record: `n8n01.yourdomain.com`, `n8n02.yourdomain.com`, … → IP ของ VPS (ตามจำนวน `N8N_COUNT`)

รอให้ DNS propagate (มักไม่เกิน 5–15 นาที) ตรวจสอบด้วย:

```bash
dig n8n01.yourdomain.com +short
# ควรได้ IP ของ VPS
```

### 4. นำโปรเจกต์ขึ้นเซิร์ฟเวอร์

**วิธีที่ 1 — อัปโหลดด้วย SCP (จากเครื่องตัวเอง):**

```bash
# บนเครื่องตัวเอง (ไม่ใช่บน VPS)
scp -r /path/to/Prepare-Student-Hosts root@YOUR_SERVER_IP:/opt/
```

**วิธีที่ 2 — Clone จาก Git:**

```bash
# บน VPS
apt install -y git
git clone https://github.com/Onto-IQ/Prepare-Student-Hosts.git /opt/Prepare-Student-Hosts
cd /opt/Prepare-Student-Hosts
```

### 5. ตั้งค่า Environment บน VPS

```bash
cd /opt/Prepare-Student-Hosts
cp .env.example .env
nano .env   # หรือ vi / vim
```

แก้ค่าให้ตรงกับเซิร์ฟเวอร์และโดเมน เช่น:

```env
POSTGRES_PASSWORD=รหัสผ่านที่แข็งแรง
BASE_HOST=yourdomain.com
N8N_COUNT=25
TRAEFIK_ACME_EMAIL=admin@yourdomain.com
```

ไม่มีโดเมน: ใช้ `BASE_HOST=76.13.219.184.nip.io` (แทนด้วย IP จริงของ VPS) บันทึกแล้วออกจาก editor

### 6. Generate Compose และรันสแต็ก

```bash
cd /opt/Prepare-Student-Hosts
./scripts/regenerate-and-up.sh
```

หรือทำมือ: โหลด `.env` → รัน `generate-compose.py` → `docker compose up -d` (ใช้สองไฟล์ compose ตามขั้นตอนที่ 5)

ตรวจสอบว่าคอนเทนเนอร์รันครบ:

```bash
docker compose -f docker-compose.yml -f docker-compose.generated.yml ps
```

### 7. เปิดพอร์ต Firewall (ถ้าเปิด ufw อยู่)

```bash
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 22/tcp   # SSH
ufw enable
ufw status
```

### 8. ตรวจสอบการทำงาน

- เปิดเบราว์เซอร์ไปที่ `https://n8n01.yourdomain.com` (หรือ subdomain อื่นที่สร้าง)
- ครั้งแรก Let's Encrypt อาจใช้เวลา 1–2 นาที ในการออกใบรับรอง
- ถ้าเจอ certificate error ให้รอสักครู่แล้วรีเฟรช หรือตรวจสอบว่า DNS ชี้มาที่ IP ถูกต้องและพอร์ต 80/443 เปิด

### สรุปคำสั่งรวด (หลังติดตั้ง Docker และตั้ง DNS / nip.io แล้ว)

```bash
cd /opt/Prepare-Student-Hosts
cp .env.example .env && nano .env   # ตั้ง BASE_HOST (โดเมนหรือ IP.nip.io) และ POSTGRES_PASSWORD
./scripts/regenerate-and-up.sh
```

## Domain และการเข้าถึงสำหรับนักเรียน (Hostinger)

การตั้งค่าโดเมนแบบนี้ใช้ได้กับ Hostinger และ VPS อื่นที่จัดการ DNS ได้ (รวมถึงโดเมนที่อยู่กับ Hostinger หรือชี้ nameserver มาที่ Hostinger)

### Domain ต่อ n8n แต่ละตัว

แต่ละ n8n service ใช้ **subdomain คนละตัว** ตามหมายเลข instance:

| หมายเลข instance | Subdomain   | URL ที่นักเรียนเข้า (ตัวอย่าง BASE_HOST=yourdomain.com) |
|------------------|------------|--------------------------------------------------------|
| 1                | `n8n01`    | `https://n8n01.yourdomain.com`                         |
| 2                | `n8n02`    | `https://n8n02.yourdomain.com`                         |
| …                | …          | …                                                      |
| 20               | `n8n20`    | `https://n8n20.yourdomain.com`                         |
| …                | …          | …                                                      |
| 25               | `n8n25`    | `https://n8n25.yourdomain.com`                         |

ครู/ผู้ดูแลแจก URL ตามหมายเลขที่กำหนดให้แต่ละคน (เช่น นักเรียนคนที่ 1 → n8n01, คนที่ 2 → n8n02)

### ตั้งค่า DNS บน Hostinger ให้ทุก subdomain ใช้ได้

**วิธีที่ 1 — Wildcard (แนะนำ)**  
ทำให้ทุก subdomain (`n8n01`, `n8n02`, … `n8n99`) ชี้มาที่ VPS เดียวกันด้วย record เดียว:

1. เข้า **hPanel** → **Websites** → เลือกโดเมน → **Advanced** → **DNS Zone Editor**
2. เพิ่ม **A record** หนึ่งรายการ:
   - **Name / Host:** `*` (เครื่องหมายดอกจัน = wildcard)
   - **Points to / Target:** IP ของ VPS (เช่น IP ของ Hostinger VPS)
   - **TTL:** ค่าเริ่มต้น (เช่น 14400) ก็ได้
3. บันทึก

ผลลัพธ์: `n8n01.yourdomain.com`, `n8n02.yourdomain.com`, … จะ resolve ไปที่ IP ของ VPS ทั้งหมด ไม่ต้องเพิ่มทีละ subdomain

**วิธีที่ 2 — เพิ่ม A record ทีละ subdomain**  
ถ้าไม่ใช้ wildcard ให้เพิ่ม A record แยกแต่ละตัว เช่น:

- Name: `n8n01` → Points to: IP ของ VPS  
- Name: `n8n02` → Points to: IP ของ VPS  
- … ทำไปจนครบตาม `N8N_COUNT`

### ตรวจสอบว่าใช้งานได้สำหรับ Hostinger

| หัวข้อ | รายละเอียด |
|--------|-------------|
| **โดเมนที่ Hostinger** | ใช้ DNS Zone Editor ของ Hostinger ได้เลย โดเมนต้องใช้ nameserver ของ Hostinger (หรือให้ผู้ให้บริการโดเมนชี้ NS มาที่ Hostinger) |
| **โดเมนที่อื่น** | ถ้าโดเมนอยู่ที่อื่น ให้เพิ่ม A record (หรือ wildcard `*`) ที่ผู้ให้บริการนั้นชี้ไปที่ **IP ของ VPS** (ไม่ใช่ IP ของ shared hosting) |
| **VPS คือ Hostinger VPS** | ใช้ IP public ของ VPS ตัวนั้นเป็นค่า "Points to" ใน A record |
| **HTTPS** | Traefik รับพอร์ต 80/443 และออกใบรับรอง Let's Encrypt ให้แต่ละ host (n8n01, n8n02, …) อัตโนมัติ นักเรียนเข้าได้ผ่าน HTTPS โดยไม่ต้องตั้งค่าเพิ่ม |

### การเข้าถึงของนักเรียน

- นักเรียนเปิดเบราว์เซอร์ไปที่ URL ที่ได้รับ (เช่น `https://n8n05.yourdomain.com`)
- ครั้งแรกอาจรอ 1–2 นาที สำหรับการออกใบรับรอง SSL
- แต่ละ URL เป็น n8n instance แยกกัน (แยก workflow, credentials ต่อคน)

### กรณีไม่มีโดเมน (ใช้แค่ VPS / hostname Hostinger)

**ใช้ชื่อ host ของ Hostinger แบบ subdomain ไม่ได้**  
ชื่อแบบ `srv1437279.hstgr.cloud` เป็น hostname เริ่มต้นของ VPS — DNS ของ `hstgr.cloud` อยู่ที่ Hostinger เราเพิ่ม subdomain อย่าง `n8n01.srv1437279.hstgr.cloud`, `n8n02.srv1437279.hstgr.cloud` เองไม่ได้ ดังนั้นถ้าต้องการหลาย instance ต่อนักเรียนหลายคน จะใช้ hostname นี้แบบ subdomain ไม่ได้

**ทางเลือกเมื่อไม่มีโดเมน: ใช้ nip.io กับ IP ของ VPS**

[nip.io](https://nip.io) เป็นบริการ DNS ฟรี ที่ให้ทุก subdomain ของ `<IP>.nip.io` ชี้ไปที่ IP นั้น โดยไม่ต้องซื้อโดเมน

1. หา **IP สาธารณะของ VPS** (จาก hPanel หรือรัน `curl -s ifconfig.me` บน VPS)
2. ตั้งค่าใน `.env`:
   ```env
   BASE_HOST=76.13.219.184.nip.io
   ```
   (แทน `76.13.219.184` ด้วย IP จริงของ VPS)
3. Generate และรัน compose ตามปกติ

**ตัวอย่าง URL ที่นักเรียนเข้า (ใช้ HTTP เมื่อไม่มีใบรับรอง):**  
`http://n8n01.76.13.219.184.nip.io/`, `http://n8n02.76.13.219.184.nip.io/`, … (ใช้ IP จริงของเซิร์ฟเวอร์)  
ถ้าใช้ HTTPS: `https://n8n01.76.13.219.184.nip.io` — Let's Encrypt ออกใบรับรองให้โดเมน nip.io ได้

**ทางเลือกอื่น:** ถ้ารัน **n8n แค่ 1 instance** จะใช้ `srv1437279.hstgr.cloud` เป็น host เดียวได้ (ต้องปรับ compose ให้มีแค่ service n8n หนึ่งตัวและใช้ host นี้ใน Traefik) — แต่ถ้าต้องการหลายคนต่อหลาย instance แนะนำใช้ nip.io กับ IP ตามด้านบน

### 404 Page Not Found (ทุกเครื่อง/ทุก instance)

- **สาเหตุที่เป็นไปได้:** Traefik ไม่ได้ใช้ network เดียวกับ n8n หรือเราเตอร์ไม่ได้ผูก service ชัดเจน
- **แก้ (รันคำสั่งเดียว):** ตั้ง `BASE_HOST` ใน `.env` ให้ตรงกับ URL ที่ใช้ (เช่น `76.13.219.184.nip.io`) แล้วรัน:
  ```bash
  ./scripts/regenerate-and-up.sh
  ```
  หรือทำมือ: regenerate แล้ว `docker compose … down` แล้ว `up -d`
- **ต้องเข้า URL ตรงกับที่ใช้ตอน generate:** ใช้ `http://n8n01.${BASE_HOST}` (หรือ `https://` ถ้ามี cert) — ถ้าเข้าด้วย IP หรือ host คนละแบบ จะไม่ match เราเตอร์และได้ 404  
- **ถ้าเดิมเข้าแบบ `http://n8n01.76.13.219.184.nip.io/`:** ใส่ `BASE_HOST=76.13.219.184.nip.io` ใน `.env` แล้วรัน `./scripts/regenerate-and-up.sh`

**เมื่อใช้ nip.io หรือไม่มีใบรับรอง:** ใช้ **http://** (port 80) แทน https — สคริปต์จะใส่ `N8N_SECURE_COOKIE=false` ให้อัตโนมัติ ถ้ามีโดเมนจริงและต้องการ HTTPS ให้ตั้ง `USE_LETSENCRYPT=true` แล้ว regenerate และเปิด redirect 80→443 ใน `docker-compose.yml`

### Traefik กับ Docker 29 (404 page not found)

ถ้าเข้า URL แล้วได้ **404 page not found** และใน log ของ Traefik เห็น `client version 1.24 is too old. Minimum supported API version is 1.44` แปลว่า Docker บนเครื่องเป็น 29.x แต่ Traefik เก่า (เช่น v3.4) ยังใช้ Docker API เก่า จึงไม่เห็น container ของ n8n เลย

**แก้:** ใช้ Traefik v3.6 ขึ้นไป (ใน `docker-compose.yml` ตั้ง `image: traefik:v3.6`) แล้วรัน `docker compose … up -d traefik` ใหม่

### Bad Gateway (502) — รหัสผ่าน Postgres ไม่ตรง

ถ้า n8n ขึ้น **502 Bad Gateway** และใน log เห็น `password authentication failed for user "n8n"` แปลว่ารหัสใน `.env` (POSTGRES_PASSWORD) ไม่ตรงกับรหัสที่ Postgres ใช้อยู่ (ตั้งตอน init volume ครั้งแรก)

**แก้:** รันสคริปต์ให้รหัสใน Postgres ตรงกับ `.env` แล้ว restart n8n:

```bash
sh scripts/fix-postgres-password.sh
docker compose -f docker-compose.yml -f docker-compose.generated.yml restart $(docker compose -f docker-compose.yml -f docker-compose.generated.yml ps -q --services | grep -E '^n8n-[0-9]+$')
```

### สิทธิ์โฟลเดอร์ (เฉพาะกรณีใช้ bind mount เอง)

โปรเจกต์นี้ใช้ **named volumes** สำหรับ n8n จึงไม่ต้อง chown บนเครื่องใหม่ ถ้าแก้ compose ให้ใช้ `./data/n8n-X` แทน volume ต้องรัน `sudo chown -R 1000:1000 ./data/n8n-*` ก่อน up

### ย้ายข้อมูลจาก bind mount (รุ่นเก่า) ไป named volumes

ถ้าเคยรันด้วย `./data/n8n-X` มาก่อน และอัปเดตมาใช้ named volumes แล้วต้องการย้ายข้อมูลเดิมเข้า volume (หยุด stack ก่อน):

```bash
# ดูชื่อ volume จริง (มักมี project prefix): docker volume ls | grep n8n
# ตัวอย่างย้าย data/n8n-1 เข้า volume (แทน VOLUME_NAME ด้วยชื่อจาก docker volume ls)
docker run --rm -v VOLUME_NAME:/data -v "$(pwd)/data/n8n-1:/src:ro" alpine sh -c "cp -a /src/. /data/"
# ทำซ้ำสำหรับ n8n-2, n8n-3, ... ตามจำนวนที่ใช้
```

---

## Backup / Restore

- **Postgres**: backup โฟลเดอร์ `data/postgres` ตามนโยบาย
- **n8n (named volumes)**: ใช้สคริปต์ `scripts/backup-n8n-volumes.sh` เพื่อ backup/restore ข้อมูล n8n แต่ละ instance

```bash
# Backup ทุก n8n volume ไปที่ ./backups/
./scripts/backup-n8n-volumes.sh backup

# Restore จาก ./backups/ (หยุด stack ก่อน)
./scripts/backup-n8n-volumes.sh restore
```

---

## หมายเหตุ

- **Secrets**: อย่า commit `.env` ใช้ค่าจาก environment หรือ secret manager บน production
- **Backup**: แนะนำให้ backup `data/postgres` และรัน `scripts/backup-n8n-volumes.sh backup` ตามนโยบาย
- **License**: ใช้ตามที่กำหนดใน repo
