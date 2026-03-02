# รายชื่อ Host n8n (ตัวอย่างสำหรับแจกนักเรียน)

หลังรัน `scripts/generate-compose.py` แล้ว สร้างไฟล์นี้จาก template โดยแทนที่ `BASE_HOST` ด้วยค่าจริง (เช่น `yourdomain.com` หรือ `IP.nip.io`)

| หมายเลข | Host / Subdomain | URL (ใช้ **http://** เมื่อไม่มี LE cert) |
|--------:|------------------|----------------------------------------|
| 1 | n8n01.BASE_HOST | http://n8n01.BASE_HOST/ |
| 2 | n8n02.BASE_HOST | http://n8n02.BASE_HOST/ |
| … | … | … |
| 25 | n8n25.BASE_HOST | http://n8n25.BASE_HOST/ |

- **ฐาน (BASE_HOST):** ใส่โดเมนหรือ IP.nip.io ตามที่ตั้งใน `.env`
- **จำนวนเครื่อง:** ตาม `N8N_COUNT` (default 25)
- แจก URL ตามหมายเลขให้ผู้เรียน (คนที่ 1 → n8n01, คนที่ 25 → n8n25)
