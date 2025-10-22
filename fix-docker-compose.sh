#!/bin/bash

# نسخة احتياطية
cp docker-compose.yml docker-compose.yml.before-fix

# حذف الأسطر 41-43 (المشكلة الأولى)
sed -i '41,43d' docker-compose.yml

# الآن أرقام الأسطر تغيرت (-3)
# milvus كان في 225 → الآن في 222
# backend كان في 345 → الآن في 342  
# frontend كان في 446 → الآن في 443
# nginx كان في 494 → الآن في 491

# إضافة مسافتين لاسم الخدمة
sed -i '222s/^milvus:/  milvus:/' docker-compose.yml
sed -i '342s/^backend:/  backend:/' docker-compose.yml
sed -i '443s/^frontend:/  frontend:/' docker-compose.yml
sed -i '491s/^nginx:/  nginx:/' docker-compose.yml

# إضافة مسافتين لجميع محتويات milvus (223-341)
sed -i '223,341s/^/  /' docker-compose.yml

# إضافة مسافتين لجميع محتويات backend (343-442)
sed -i '343,442s/^/  /' docker-compose.yml

# إضافة مسافتين لجميع محتويات frontend (444-490)
sed -i '444,490s/^/  /' docker-compose.yml

# إضافة مسافتين لجميع محتويات nginx (492 حتى النهاية)
sed -i '492,$s/^/  /' docker-compose.yml

echo "✅ تم الإصلاح"
