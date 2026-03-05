# 🚀 Deployment Guide — สำหรับเซิร์ฟเวอร์ใหม่

เอกสารนี้สำหรับติดตั้งระบบ n8n หลาย instance บนเซิร์ฟเวอร์ใหม่

---

## ขั้นตอนที่ 1: เตรียม VPS

### ระบบที่รองรับ
- Ubuntu 22.04 LTS หรือ 24.04 LTS
- RAM: 2GB+ (แนะนำ 4GB สำหรับ 25+ instances)
- Disk: 20GB+

### ติดตั้ง Docker

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Test
sudo docker --version
sudo docker compose version
```

---

## ขั้นตอนที่ 2: โคลนโปรเจกต์

```bash
sudo mkdir -p /opt
sudo git clone https://github.com/Onto-IQ/Prepare-Student-Hosts.git /opt/Prepare-Student-Hosts
sudo chown -R $USER:$USER /opt/Prepare-Student-Hosts
cd /opt/Prepare-Student-Hosts
```

---

## ขั้นตอนที่ 3: ติดตั้ง Cloudflare Tunnel (แนะนำ)

### 3.1 ติดตั้ง cloudflared

```bash
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

### 3.2 สร้าง Tunnel

```bash
# Login (จะเปิด browser)
cloudflared tunnel login

# สร้าง tunnel
cloudflared tunnel create n8n-class

# จด Tunnel ID ที่ขึ้นมา (เช่น: a1b2c3d4-...)
```

### 3.3 ตั้งค่า Tunnel

```bash
# แก้ <TUNNEL_ID> ให้เป็นค่าที่ได้จากข้อ 3.2
TUNNEL_ID=<TUNNEL_ID>

sudo tee /etc/cloudflared/config.yml << EOF
tunnel: ${TUNNEL_ID}
credentials-file: /etc/cloudflared/${TUNNEL_ID}.json

ingress:
  - hostname: '*.datafabric.academy'
    service: http://localhost:80
  - service: http_status:404
EOF

# ย้าย credentials
sudo cp ~/.cloudflared/${TUNNEL_ID}.json /etc/cloudflared/
sudo chown root:root /etc/cloudflared/${TUNNEL_ID}.json
sudo chmod 600 /etc/cloudflared/${TUNNEL_ID}.json

# สร้าง wildcard DNS
cloudflared tunnel route dns ${TUNNEL_ID} '*.datafabric.academy'

# ติดตั้งเป็น service
sudo cloudflared service install
sudo systemctl enable --now cloudflared
```

---

## ขั้นตอนที่ 4: ตั้งค่าและรัน n8n

```bash
cd /opt/Prepare-Student-Hosts

# สร้าง .env
cp .env.example .env
nano .env  # แก้ BASE_HOST, POSTGRES_PASSWORD, N8N_COUNT

# รันคำสั่งเดียว
./scripts/setup-class.sh
```

---

## ขั้นตอนที่ 5: ทดสอบ

```bash
# ตรวจสอบ containers
sudo docker ps

# ทดสอบเข้าใช้งาน
curl -I https://n8n01.datafabric.academy
```

---

## สำหรับทุกครั้งสอนใหม่

```bash
cd /opt/Prepare-Student-Hosts
./scripts/setup-class.sh
```

หรือถ้าต้องการแก้ไขจำนวนนักเรียน:

```bash
nano .env  # แก้ N8N_COUNT
./scripts/regenerate-and-up.sh
```

---

## การ Backup

```bash
# ก่อนจบคลาส — backup ทุกครั้ง
./scripts/backup-n8n-volumes.sh backup
```

---

## แก้ปัญหา

### Error 1033 (Cloudflare Tunnel)

```bash
sudo systemctl restart cloudflared
```

### 404 Page Not Found

```bash
# ตรวจสอบว่า BASE_HOST ตรงกับ URL ที่เข้า
nano .env
./scripts/regenerate-and-up.sh
```

### Container ไม่ขึ้น

```bash
# ดู logs
sudo docker logs n8n-1
sudo docker logs n8n-traefik
```

---

## ข้อมูลเพิ่มเติม

- ดู README.md สำหรับข้อมูลละเอียด
- ดู scripts/ สำหรับสคริปต์ที่ใช้งานได้
