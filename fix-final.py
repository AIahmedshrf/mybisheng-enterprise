#!/usr/bin/env python3
import re

with open('docker-compose.yml', 'r') as f:
    content = f.read()
    lines = content.split('\n')

# المرحلة 1: إيجاد بداية ونهاية كل قسم
services_start = None
services_end = None
root_services = []  # الخدمات الموجودة في المستوى الجذري

for i, line in enumerate(lines):
    if line.strip().startswith('services:') and not line.startswith(' '):
        services_start = i
    
    # البحث عن الخدمات في المستوى الجذري (بعد services)
    if services_start and i > services_start + 10:
        # تحقق من الخدمات المعروفة في المستوى الجذري
        if re.match(r'^(milvus|elasticsearch|backend|frontend|nginx|etcd|prometheus|grafana|alertmanager):', line):
            root_services.append(i)
            print(f"🔍 وجدت خدمة في المستوى الجذري: {line.strip()} في السطر {i+1}")

# المرحلة 2: بناء الملف المصحح
fixed_lines = []
skip_until = None

for i, line in enumerate(lines):
    # تخطي الأسطر 40-42 (networks داخل services)
    if 40 <= i <= 42 and 'networks:' in line or (i == 41 and 'default:' in line) or (i == 42 and 'name:' in line):
        continue
    
    # إذا كانت هذه بداية خدمة في المستوى الجذري
    if i in root_services:
        # إضافة مسافتين للخدمة ومحتوياتها
        fixed_lines.append('  ' + line)
    # إذا كنا داخل خدمة من المستوى الجذري
    elif root_services and i > min(root_services):
        # تحقق إذا كانت هذه بداية خدمة جديدة في المستوى الجذري
        is_new_root_service = any(i == rs for rs in root_services)
        # تحقق إذا وصلنا لنهاية الملف أو بداية قسم جديد
        is_end = line.strip() == '' and (i == len(lines) - 1 or (i < len(lines) - 1 and not lines[i+1].startswith(' ')))
        
        if is_new_root_service:
            fixed_lines.append('  ' + line)
        elif line.startswith(' ') or line.strip() == '':
            # محتويات الخدمة - إضافة مسافتين
            fixed_lines.append('  ' + line)
        elif not line.strip():
            # سطر فارغ
            fixed_lines.append(line)
        else:
            # انتهت الخدمات
            fixed_lines.append(line)
    else:
        fixed_lines.append(line)

# المرحلة 3: كتابة الملف
with open('docker-compose.yml', 'w') as f:
    f.write('\n'.join(fixed_lines))

print("\n✅ تم إصلاح الملف بنجاح")
print(f"📊 عدد الخدمات المنقولة: {len(root_services)}")
