#!/bin/bash

# بررسی اینکه فایل اصلی وجود دارد یا خیر
if [ ! -f "install_hysteria.sh" ]; then
  echo "فایل نصب (install_hysteria.sh) پیدا نشد! لطفاً بررسی کنید."
  exit 1
fi

# اعمال مجوز اجرا به فایل نصب
chmod +x install_hysteria.sh

# اجرای فایل نصب
./install_hysteria.sh
