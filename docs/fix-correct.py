#!/usr/bin/env python3

with open('docker-compose.yml', 'r') as f:
    lines = f.readlines()

# حذف الأسطر 41-43 (0-indexed: 40-42)
del lines[40:43]

# الآن نحتاج لإيجاد الخدمات الأربع وإزاحتها
fixed_lines = []
inside_service = None
service_start = None

for i, line in enumerate(lines):
    line_num = i + 1
    
    # تحديد بداية الخدمات الأربع (بعد حذف 3 أسطر)
    if line.startswith('milvus:') and line_num > 200:
        inside_service = 'milvus'
        service_start = i
        fixed_lines.append('  ' + line)
    elif line.startswith('backend:') and line_num > 300:
        inside_service = 'backend'
        service_start = i
        fixed_lines.append('  ' + line)
    elif line.startswith('frontend:') and line_num > 400:
        inside_service = 'frontend'
        service_start = i
        fixed_lines.append('  ' + line)
    elif line.startswith('nginx:') and line_num > 450:
        inside_service = 'nginx'
        service_start = i
        fixed_lines.append('  ' + line)
    elif inside_service and (line.startswith('  ') or line.strip() == ''):
        # محتويات الخدمة - إضافة مسافتين
        fixed_lines.append('  ' + line)
    elif inside_service and not line.startswith(' '):
        # انتهت الخدمة
        inside_service = None
        fixed_lines.append(line)
    else:
        fixed_lines.append(line)

with open('docker-compose.yml', 'w') as f:
    f.writelines(fixed_lines)

print("✅ تم الإصلاح بنجاح")
