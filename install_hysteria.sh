#!/bin/bash

# رنگ‌ها برای نمایش
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}شروع نصب Hysteria2...${NC}"

# به‌روزرسانی و نصب ابزارهای اولیه
sudo apt update -y && sudo apt upgrade -y
sudo apt install curl wget -y

# دانلود فایل باینری Hysteria2
echo -e "${GREEN}دانلود فایل Hysteria2...${NC}"
HYSTERIA_VERSION=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | grep "tag_name" | cut -d '"' -f 4)
wget -O hysteria.tar.gz "https://github.com/apernet/hysteria/releases/download/${HYSTERIA_VERSION}/hysteria-linux-amd64.tar.gz"

# استخراج فایل‌ها
echo -e "${GREEN}استخراج فایل‌ها...${NC}"
tar -xvzf hysteria.tar.gz
sudo mv hysteria /usr/local/bin/hysteria
sudo chmod +x /usr/local/bin/hysteria

# ایجاد فایل تنظیمات
echo -e "${GREEN}ایجاد فایل تنظیمات...${NC}"
sudo mkdir -p /etc/hysteria
cat <<EOF | sudo tee /etc/hysteria/config.json
{
  "listen": ":443",
  "protocol": "udp",
  "cert": "/etc/hysteria/cert.pem",
  "key": "/etc/hysteria/key.pem",
  "auth": {
    "mode": "password",
    "config": {
      "password": ["YOUR_PASSWORD"]
    }
  }
}
EOF

# ساخت گواهینامه SSL (خودامضا)
echo -e "${GREEN}ایجاد گواهینامه SSL...${NC}"
openssl req -newkey rsa:2048 -nodes -keyout /etc/hysteria/key.pem -x509 -days 365 -out /etc/hysteria/cert.pem -subj "/CN=localhost"

# ایجاد سرویس برای Hysteria2
echo -e "${GREEN}ایجاد سرویس برای Hysteria2...${NC}"
cat <<EOF | sudo tee /etc/systemd/system/hysteria.service
[Unit]
Description=Hysteria2 Service
After=network.target

[Service]
ExecStart=/usr/local/bin/hysteria -c /etc/hysteria/config.json
Restart=always
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOF

# فعال‌سازی و راه‌اندازی سرویس
echo -e "${GREEN}فعال‌سازی و راه‌اندازی سرویس...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable hysteria
sudo systemctl start hysteria

echo -e "${GREEN}Hysteria2 با موفقیت نصب و راه‌اندازی شد!${NC}"
