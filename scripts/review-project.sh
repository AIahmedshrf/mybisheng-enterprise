#!/bin/bash

# ========================================
# 🔍 سكربت المراجعة الشاملة لمشروع Bisheng Enterprise
# ========================================
# الغرض: فحص كامل للمشروع والتأكد من جاهزيته
# المؤلف: AI Expert
# التاريخ: 2024
# ========================================

set -e

# ==================== الألوان ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ==================== دوال الطباعة ====================
print_header() {
    echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ $1${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

print_section() {
    echo -e "\n${CYAN}▶ $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}  ✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}  ⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}  ❌ $1${NC}"
}

print_info() {
    echo -e "${CYAN}  ℹ️  $1${NC}"
}

# ==================== متغيرات ====================
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT" || exit 1

# المجلدات المطلوبة
REQUIRED_DIRS=(
    "base"
    "features"
    "infrastructure"
    "configs"
    "configs/nginx"
    "configs/prometheus"
    "configs/grafana"
    "configs/postgresql"
    "configs/redis"
    "configs/elasticsearch"
    "configs/milvus"
    "scripts"
    "custom-images"
    "custom-images/backend"
    "custom-images/frontend"
    "custom-images/backup"
    "data"
    "data/postgresql"
    "data/redis"
    "data/milvus"
    "data/elasticsearch"
    "data/minio"
    "data/backups"
    "logs"
    "logs/backend"
    "logs/frontend"
    "logs/nginx"
    "logs/worker"
    "ssl"
    "docs"
)

# الملفات المطلوبة
REQUIRED_FILES=(
    ".env.example"
    ".env.production"
    ".env.development"
    "Makefile"
    "README.md"
    "docker-compose.yml"
    "docker-compose.dev.yml"
    "base/docker-compose.base.yml"
    "features/docker-compose.ft.yml"
    "features/docker-compose.office.yml"
    "features/docker-compose.ml.yml"
    "infrastructure/docker-compose.monitoring.yml"
    "infrastructure/docker-compose.backup.yml"
    "infrastructure/docker-compose.security.yml"
)

# السكربتات المطلوبة
REQUIRED_SCRIPTS=(
    "scripts/deploy.sh"
    "scripts/backup.sh"
    "scripts/restore.sh"
    "scripts/health-check.sh"
    "scripts/update.sh"
    "scripts/review-project.sh"
)

# ملفات التكوين
REQUIRED_CONFIGS=(
    "configs/nginx/nginx.conf"
    "configs/prometheus/prometheus.yml"
    "configs/postgresql/postgresql.conf"
)

# عدادات
total_issues=0
missing_dirs=0
missing_files=0
missing_scripts=0
missing_configs=0
invalid_compose=0
permission_issues=0

# ==================== البداية ====================
clear
print_header "🔍 المراجعة الشاملة لمشروع Bisheng Enterprise"

echo -e "${WHITE}المسار: ${CYAN}$PROJECT_ROOT${NC}"
echo -e "${WHITE}التاريخ: ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${WHITE}المستخدم: ${CYAN}$(whoami)${NC}\n"

# ==================== 1. فحص المجلدات ====================
print_section "1️⃣  فحص المجلدات الأساسية"

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        # حساب عدد الملفات
        file_count=$(find "$dir" -maxdepth 1 -type f 2>/dev/null | wc -l)
        print_success "المجلد موجود: $dir ${CYAN}($file_count ملف)${NC}"
    else
        print_error "المجلد مفقود: $dir"
        ((missing_dirs++))
        # إنشاء المجلد المفقود
        mkdir -p "$dir" 2>/dev/null && print_warning "  → تم إنشاء المجلد"
    fi
done

if [ $missing_dirs -eq 0 ]; then
    print_success "جميع المجلدات موجودة ✓"
else
    print_warning "تم إنشاء $missing_dirs مجلد مفقود"
fi

# ==================== 2. فحص الملفات الأساسية ====================
print_section "2️⃣  فحص الملفات الأساسية"

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        size=$(du -h "$file" 2>/dev/null | cut -f1)
        lines=$(wc -l < "$file" 2>/dev/null || echo "0")
        
        # فحص إذا كان الملف فارغاً
        if [ "$lines" -eq 0 ] || [ ! -s "$file" ]; then
            print_warning "الملف موجود لكن فارغ: $file"
            ((missing_files++))
        else
            print_success "الملف موجود: $file ${CYAN}($size, $lines سطر)${NC}"
        fi
    else
        print_error "الملف مفقود: $file"
        ((missing_files++))
    fi
done

# ==================== 3. فحص السكربتات ====================
print_section "3️⃣  فحص السكربتات"

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            lines=$(wc -l < "$script" 2>/dev/null || echo "0")
            if [ "$lines" -gt 10 ]; then
                print_success "السكربت جاهز: $script ${CYAN}($lines سطر)${NC}"
            else
                print_warning "السكربت موجود لكن قد يكون غير مكتمل: $script ${CYAN}($lines سطر)${NC}"
                ((missing_scripts++))
            fi
        else
            print_warning "السكربت غير قابل للتنفيذ: $script"
            chmod +x "$script"
            print_success "  → تم تعيين الأذونات"
            ((permission_issues++))
        fi
    else
        print_error "السكربت مفقود: $script"
        ((missing_scripts++))
    fi
done

# ==================== 4. فحص ملفات التكوين ====================
print_section "4️⃣  فحص ملفات التكوين"

for config in "${REQUIRED_CONFIGS[@]}"; do
    if [ -f "$config" ]; then
        size=$(du -h "$config" 2>/dev/null | cut -f1)
        print_success "التكوين موجود: $config ${CYAN}($size)${NC}"
    else
        print_error "التكوين مفقود: $config"
        ((missing_configs++))
    fi
done

# ==================== 5. فحص ملفات Docker Compose ====================
print_section "5️⃣  فحص ملفات Docker Compose"

compose_files=$(find . -maxdepth 3 -name "docker-compose*.yml" -type f 2>/dev/null)
compose_count=0

for file in $compose_files; do
    ((compose_count++))
    
    # فحص إذا كان الملف فارغاً
    if [ ! -s "$file" ]; then
        print_warning "الملف فارغ: $file"
        ((invalid_compose++))
        continue
    fi
    
    # فحص صحة YAML
    if command -v docker-compose >/dev/null 2>&1; then
        if docker-compose -f "$file" config >/dev/null 2>&1; then
            services=$(docker-compose -f "$file" config --services 2>/dev/null | wc -l)
            print_success "ملف صحيح: $file ${CYAN}($services خدمة)${NC}"
        else
            print_error "ملف به أخطاء: $file"
            ((invalid_compose++))
        fi
    else
        size=$(du -h "$file" 2>/dev/null | cut -f1)
        print_info "الملف موجود: $file ${CYAN}($size)${NC}"
    fi
done

print_info "إجمالي ملفات Docker Compose: $compose_count"

# ==================== 6. فحص ملفات البيئة ====================
print_section "6️⃣  فحص ملفات البيئة"

if [ -f ".env" ]; then
    env_from=$(head -n 5 .env | grep "ENVIRONMENT=" | cut -d= -f2)
    print_success "ملف .env موجود ${CYAN}(البيئة: $env_from)${NC}"
else
    print_warning "ملف .env غير موجود"
    print_info "  → يمكن إنشاؤه بـ: cp .env.development .env"
fi

for env_file in .env.example .env.development .env.production; do
    if [ -f "$env_file" ]; then
        vars=$(grep -c "=" "$env_file" 2>/dev/null || echo "0")
        print_success "$env_file ${CYAN}($vars متغير)${NC}"
    else
        print_error "$env_file مفقود"
    fi
done

# ==================== 7. فحص Dockerfiles ====================
print_section "7️⃣  فحص Dockerfiles المخصصة"

dockerfiles=$(find custom-images -name "Dockerfile" -type f 2>/dev/null)
dockerfile_count=0

for dockerfile in $dockerfiles; do
    ((dockerfile_count++))
    lines=$(wc -l < "$dockerfile" 2>/dev/null || echo "0")
    
    if [ "$lines" -gt 5 ]; then
        print_success "Dockerfile: $dockerfile ${CYAN}($lines سطر)${NC}"
    else
        print_warning "Dockerfile قد يكون غير مكتمل: $dockerfile ${CYAN}($lines سطر)${NC}"
    fi
done

print_info "إجمالي Dockerfiles: $dockerfile_count"

# ==================== 8. فحص Docker ====================
print_section "8️⃣  فحص Docker"

if command -v docker >/dev/null 2>&1; then
    docker_version=$(docker --version | awk '{print $3}' | tr -d ',')
    print_success "Docker مثبت ${CYAN}(الإصدار: $docker_version)${NC}"
    
    if docker info >/dev/null 2>&1; then
        print_success "Docker daemon يعمل"
        
        # فحص مساحة Docker
        docker_root=$(docker info --format '{{.DockerRootDir}}' 2>/dev/null || echo "/var/lib/docker")
        print_info "Docker Root: $docker_root"
    else
        print_error "Docker daemon لا يعمل"
    fi
else
    print_error "Docker غير مثبت"
fi

if command -v docker-compose >/dev/null 2>&1; then
    compose_version=$(docker-compose --version | awk '{print $4}' | tr -d ',')
    print_success "Docker Compose مثبت ${CYAN}(الإصدار: $compose_version)${NC}"
else
    print_warning "Docker Compose غير مثبت"
fi

# ==================== 9. فحص Git ====================
print_section "9️⃣  فحص Git"

if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    remote=$(git remote get-url origin 2>/dev/null || echo "لا يوجد")
    
    print_success "مستودع Git نشط ${CYAN}(الفرع: $branch)${NC}"
    
    if echo "$remote" | grep -q "AIahmedshrf/mybisheng-enterprise"; then
        print_success "متصل بالمستودع الصحيح"
        print_info "  → $remote"
    else
        print_warning "Remote غير متطابق: $remote"
    fi
    
    # فحص التغييرات
    if git diff-index --quiet HEAD -- 2>/dev/null; then
        print_success "لا توجد تغييرات غير محفوظة"
    else
        changes=$(git status --short | wc -l)
        print_warning "يوجد $changes تغيير غير محفوظ"
    fi
else
    print_error "ليس مستودع Git"
fi

# ==================== 10. إحصائيات المشروع ====================
print_section "🔟 إحصائيات المشروع"

total_files=$(find . -type f ! -path '*/\.git/*' ! -path '*/data/*' ! -path '*/logs/*' 2>/dev/null | wc -l)
total_dirs=$(find . -type d ! -path '*/\.git/*' ! -path '*/data/*' ! -path '*/logs/*' 2>/dev/null | wc -l)
total_yml=$(find . -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l)
total_sh=$(find . -name "*.sh" 2>/dev/null | wc -l)
total_py=$(find . -name "*.py" 2>/dev/null | wc -l)
total_dockerfile=$(find . -name "Dockerfile*" 2>/dev/null | wc -l)
total_md=$(find . -name "*.md" 2>/dev/null | wc -l)

echo -e "  ${WHITE}📁 إجمالي الملفات:${NC} ${CYAN}$total_files${NC}"
echo -e "  ${WHITE}📂 إجمالي المجلدات:${NC} ${CYAN}$total_dirs${NC}"
echo -e "  ${WHITE}📄 ملفات YAML:${NC} ${CYAN}$total_yml${NC}"
echo -e "  ${WHITE}🔧 ملفات Shell:${NC} ${CYAN}$total_sh${NC}"
echo -e "  ${WHITE}🐍 ملفات Python:${NC} ${CYAN}$total_py${NC}"
echo -e "  ${WHITE}🐳 ملفات Dockerfile:${NC} ${CYAN}$total_dockerfile${NC}"
echo -e "  ${WHITE}📝 ملفات Markdown:${NC} ${CYAN}$total_md${NC}"

# حجم المشروع
project_size=$(du -sh . 2>/dev/null | cut -f1)
echo -e "  ${WHITE}💾 حجم المشروع:${NC} ${CYAN}$project_size${NC}"

# ==================== 11. استخدام الموارد ====================
print_section "1️⃣1️⃣  استخدام الموارد"

# CPU
cpu_cores=$(nproc 2>/dev/null || echo "غير معروف")
echo -e "  ${WHITE}🖥️  CPU Cores:${NC} ${CYAN}$cpu_cores${NC}"

# RAM
if command -v free >/dev/null 2>&1; then
    total_ram=$(free -h | awk '/^Mem:/ {print $2}')
    used_ram=$(free -h | awk '/^Mem:/ {print $3}')
    echo -e "  ${WHITE}💻 RAM:${NC} ${CYAN}$used_ram / $total_ram${NC}"
fi

# Disk
if command -v df >/dev/null 2>&1; then
    disk_usage=$(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')
    echo -e "  ${WHITE}💽 Disk (Root):${NC} ${CYAN}$disk_usage${NC}"
    
    tmp_usage=$(df -h /tmp | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')
    echo -e "  ${WHITE}💽 Disk (/tmp):${NC} ${CYAN}$tmp_usage${NC}"
fi

# ==================== 12. حساب المشاكل ====================
total_issues=$((missing_dirs + missing_files + missing_scripts + missing_configs + invalid_compose + permission_issues))

# ==================== النتيجة النهائية ====================
print_header "📊 النتيجة النهائية"

if [ $total_issues -eq 0 ]; then
    echo -e "${GREEN}"
    echo "  ██████╗ ███████╗ █████╗ ██████╗ ██╗   ██╗"
    echo "  ██╔══██╗██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝"
    echo "  ██████╔╝█████╗  ███████║██║  ██║ ╚████╔╝ "
    echo "  ██╔══██╗██╔══╝  ██╔══██║██║  ██║  ╚██╔╝  "
    echo "  ██║  ██║███████╗██║  ██║██████╔╝   ██║   "
    echo "  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝    ╚═╝   "
    echo -e "${NC}"
    
    print_success "🎉 المشروع جاهز بنسبة 100%!"
    print_success "✅ جميع المكونات موجودة وصحيحة"
    echo ""
    echo -e "${GREEN}يمكنك الآن تشغيل المشروع بـ: ${WHITE}make dev${NC}"
    echo ""
else
    echo -e "${YELLOW}"
    echo "  ⚠️  يحتاج المشروع إلى بعض الإصلاحات"
    echo -e "${NC}"
    
    echo -e "\n${WHITE}المشاكل المكتشفة:${NC}"
    [ $missing_dirs -gt 0 ] && echo -e "  ${RED}❌ مجلدات مفقودة: $missing_dirs${NC}"
    [ $missing_files -gt 0 ] && echo -e "  ${RED}❌ ملفات مفقودة: $missing_files${NC}"
    [ $missing_scripts -gt 0 ] && echo -e "  ${RED}❌ سكربتات مفقودة: $missing_scripts${NC}"
    [ $missing_configs -gt 0 ] && echo -e "  ${RED}❌ تكوينات مفقودة: $missing_configs${NC}"
    [ $invalid_compose -gt 0 ] && echo -e "  ${RED}❌ ملفات compose خاطئة: $invalid_compose${NC}"
    [ $permission_issues -gt 0 ] && echo -e "  ${YELLOW}⚠️  مشاكل أذونات تم إصلاحها: $permission_issues${NC}"
    
    echo -e "\n${WHITE}إجمالي المشاكل: ${RED}$total_issues${NC}"
    
    # نسبة الإنجاز
    total_checks=$((${#REQUIRED_DIRS[@]} + ${#REQUIRED_FILES[@]} + ${#REQUIRED_SCRIPTS[@]} + ${#REQUIRED_CONFIGS[@]}))
    completed=$((total_checks - total_issues))
    percentage=$((completed * 100 / total_checks))
    
    echo -e "\n${WHITE}نسبة الإنجاز: ${CYAN}$percentage%${NC}"
    
    # شريط التقدم
    bar_length=50
    filled=$((percentage * bar_length / 100))
    empty=$((bar_length - filled))
    
    echo -n "  ["
    for ((i=0; i<filled; i++)); do echo -n "█"; done
    for ((i=0; i<empty; i++)); do echo -n "░"; done
    echo "]"
    
    echo ""
    echo -e "${YELLOW}💡 الخطوات التالية:${NC}"
    echo -e "  1. إكمال الملفات الناقصة"
    echo -e "  2. تشغيل: ${GREEN}make review${NC} مرة أخرى"
    echo ""
fi

# ==================== الخاتمة ====================
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}انتهت المراجعة في: ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}\n"

exit 0
