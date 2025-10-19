# ========================================
# Bisheng Enterprise - Makefile
# ========================================
# الاستخدام: make [command]
# مثال: make dev

.PHONY: help review setup init dev prod stop clean restart logs backup restore update health ps stats

# الألوان
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
CYAN := \033[0;36m
MAGENTA := \033[0;35m
NC := \033[0m

# متغيرات
DOCKER_COMPOSE := docker-compose
PROJECT_NAME := bisheng-enterprise

# ========================================
# الأوامر الرئيسية
# ========================================

help: ## 📚 عرض المساعدة
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║         Bisheng Enterprise - الأوامر المتاحة            ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)🚀 التشغيل:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)💡 أمثلة:$(NC)"
	@echo "  $(GREEN)make setup$(NC)     - إعداد المشروع لأول مرة"
	@echo "  $(GREEN)make dev$(NC)       - تشغيل بيئة التطوير"
	@echo "  $(GREEN)make logs$(NC)      - عرض السجلات"
	@echo "  $(GREEN)make health$(NC)    - فحص صحة الخدمات"
	@echo ""

review: ## 🔍 مراجعة شاملة للمشروع
	@echo "$(BLUE)🔍 بدء المراجعة الشاملة...$(NC)"
	@if [ -f scripts/review-project.sh ]; then \
		bash scripts/review-project.sh; \
	else \
		echo "$(RED)❌ السكربت غير موجود: scripts/review-project.sh$(NC)"; \
	fi

setup: ## ⚙️ إعداد المشروع لأول مرة
	@echo "$(BLUE)⚙️  إعداد المشروع...$(NC)"
	@echo "$(YELLOW)📁 إنشاء المجلدات المطلوبة...$(NC)"
	@mkdir -p data/{postgresql,redis,milvus,elasticsearch,minio,backups}
	@mkdir -p logs/{backend,frontend,nginx,worker}
	@mkdir -p ssl
	@echo "$(YELLOW)🔐 إنشاء مجلدات SSL...$(NC)"
	@mkdir -p ssl/certs ssl/private
	@echo "$(YELLOW)✅ تعيين الأذونات للسكربتات...$(NC)"
	@chmod +x scripts/*.sh 2>/dev/null || true
	@echo "$(YELLOW)📄 نسخ ملف البيئة...$(NC)"
	@if [ ! -f .env ]; then cp .env.development .env; fi
	@echo "$(GREEN)✅ تم الإعداد بنجاح!$(NC)"
	@echo ""
	@echo "$(CYAN)�� الخطوات التالية:$(NC)"
	@echo "  1. راجع ملف .env وعدّل الإعدادات"
	@echo "  2. نفذ: $(GREEN)make dev$(NC) لتشغيل بيئة التطوير"
	@echo ""

init: setup ## 🎬 اختصار لـ setup

# ========================================
# التشغيل
# ========================================

dev: ## 🚀 تشغيل بيئة التطوير
	@echo "$(BLUE)🚀 تشغيل بيئة التطوير...$(NC)"
	@if [ ! -f .env ]; then \
		echo "$(YELLOW)⚠️  لم يتم العثور على .env، سيتم نسخه من .env.development$(NC)"; \
		cp .env.development .env; \
	fi
	@echo "$(YELLOW)🔄 سحب أحدث الصور...$(NC)"
	@$(DOCKER_COMPOSE) -f docker-compose.yml -f docker-compose.dev.yml pull || true
	@echo "$(YELLOW)🏗️  بناء الخدمات...$(NC)"
	@$(DOCKER_COMPOSE) -f docker-compose.yml -f docker-compose.dev.yml build
	@echo "$(YELLOW)▶️  تشغيل الخدمات...$(NC)"
	@$(DOCKER_COMPOSE) -f docker-compose.yml -f docker-compose.dev.yml up -d
	@echo ""
	@echo "$(GREEN)✅ بيئة التطوير تعمل الآن!$(NC)"
	@echo ""
	@echo "$(CYAN)📍 الروابط:$(NC)"
	@echo "  Frontend:       $(YELLOW)http://localhost:3000$(NC)"
	@echo "  Backend API:    $(YELLOW)http://localhost:3001$(NC)"
	@echo "  MinIO Console:  $(YELLOW)http://localhost:9001$(NC)"
	@echo "  Grafana:        $(YELLOW)http://localhost:3002$(NC)"
	@echo "  Prometheus:     $(YELLOW)http://localhost:9090$(NC)"
	@echo ""
	@echo "$(CYAN)📊 الأوامر المفيدة:$(NC)"
	@echo "  $(GREEN)make logs$(NC)      - عرض السجلات"
	@echo "  $(GREEN)make ps$(NC)        - عرض حالة الخدمات"
	@echo "  $(GREEN)make health$(NC)    - فحص الصحة"
	@echo ""

prod: ## 🏭 تشغيل بيئة الإنتاج
	@echo "$(BLUE)🏭 تشغيل بيئة الإنتاج...$(NC)"
	@if [ ! -f .env ]; then \
		echo "$(RED)❌ لم يتم العثور على .env$(NC)"; \
		echo "$(YELLOW)💡 نسخ من .env.production...$(NC)"; \
		cp .env.production .env; \
		echo "$(RED)⚠️  يجب تعديل كلمات المرور في .env قبل المتابعة!$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)🔄 سحب أحدث الصور...$(NC)"
	@$(DOCKER_COMPOSE) -f docker-compose.yml pull
	@echo "$(YELLOW)▶️  تشغيل الخدمات...$(NC)"
	@$(DOCKER_COMPOSE) -f docker-compose.yml up -d
	@echo ""
	@echo "$(GREEN)✅ بيئة الإنتاج تعمل الآن!$(NC)"
	@echo ""

up: dev ## ▶️ اختصار لـ dev

start: dev ## ▶️ اختصار لـ dev

# ========================================
# الإيقاف والتنظيف
# ========================================

stop: ## ⏸️ إيقاف جميع الخدمات
	@echo "$(YELLOW)⏸️  إيقاف الخدمات...$(NC)"
	@$(DOCKER_COMPOSE) -f docker-compose.yml -f docker-compose.dev.yml down || $(DOCKER_COMPOSE) down
	@echo "$(GREEN)✅ تم الإيقاف$(NC)"

down: stop ## ⏸️ اختصار لـ stop

restart: ## 🔄 إعادة تشغيل الخدمات
	@echo "$(BLUE)🔄 إعادة التشغيل...$(NC)"
	@$(MAKE) stop
	@sleep 3
	@$(MAKE) dev

clean: ## 🧹 تنظيف (حذف الحاويات والشبكات)
	@echo "$(RED)⚠️  تنظيف الحاويات والشبكات...$(NC)"
	@read -p "هل أنت متأكد؟ (yes/no): " confirm && [ "$$confirm" = "yes" ] || exit 1
	@$(DOCKER_COMPOSE) down -v --remove-orphans
	@echo "$(GREEN)✅ تم التنظيف$(NC)"

clean-data: ## 🗑️ حذف جميع البيانات (خطير!)
	@echo "$(RED)⚠️  هذا سيحذف جميع البيانات بشكل دائم!$(NC)"
	@read -p "اكتب 'DELETE' للتأكيد: " confirm && [ "$$confirm" = "DELETE" ] || exit 1
	@$(MAKE) clean
	@rm -rf data/postgresql/* data/redis/* data/milvus/* data/elasticsearch/* data/minio/*
	@rm -rf logs/*/*.log
	@echo "$(GREEN)✅ تم حذف جميع البيانات$(NC)"

clean-logs: ## 📝 حذف السجلات
	@echo "$(YELLOW)📝 حذف السجلات...$(NC)"
	@rm -rf logs/*/*.log
	@echo "$(GREEN)✅ تم حذف السجلات$(NC)"

# ========================================
# السجلات والمراقبة
# ========================================

logs: ## 📋 عرض جميع السجلات
	@$(DOCKER_COMPOSE) logs -f --tail=100

logs-backend: ## 📋 سجلات Backend
	@$(DOCKER_COMPOSE) logs -f --tail=100 backend

logs-frontend: ## 📋 سجلات Frontend
	@$(DOCKER_COMPOSE) logs -f --tail=100 frontend

logs-db: ## 📋 سجلات PostgreSQL
	@$(DOCKER_COMPOSE) logs -f --tail=100 postgres

logs-redis: ## 📋 سجلات Redis
	@$(DOCKER_COMPOSE) logs -f --tail=100 redis

logs-nginx: ## 📋 سجلات Nginx
	@$(DOCKER_COMPOSE) logs -f --tail=100 nginx

logs-milvus: ## 📋 سجلات Milvus
	@$(DOCKER_COMPOSE) logs -f --tail=100 milvus

ps: ## 📊 عرض حالة الخدمات
	@echo "$(BLUE)📊 حالة الخدمات:$(NC)"
	@$(DOCKER_COMPOSE) ps

stats: ## 💻 عرض إحصائيات الموارد
	@echo "$(BLUE)💻 إحصائيات الموارد:$(NC)"
	@docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

health: ## 🏥 فحص صحة الخدمات
	@echo "$(BLUE)🏥 فحص صحة الخدمات...$(NC)"
	@if [ -f scripts/health-check.sh ]; then \
		bash scripts/health-check.sh; \
	else \
		echo "$(YELLOW)⚠️  السكربت غير موجود، سيتم استخدام docker ps$(NC)"; \
		$(DOCKER_COMPOSE) ps; \
	fi

# ========================================
# Shell Access
# ========================================

shell-backend: ## 🐚 الدخول إلى Backend shell
	@$(DOCKER_COMPOSE) exec backend bash

shell-frontend: ## 🐚 الدخول إلى Frontend shell
	@$(DOCKER_COMPOSE) exec frontend sh

shell-db: ## 🐚 الدخول إلى PostgreSQL shell
	@$(DOCKER_COMPOSE) exec postgres psql -U bisheng -d bisheng_dev

shell-redis: ## 🐚 الدخول إلى Redis CLI
	@$(DOCKER_COMPOSE) exec redis redis-cli -a dev_redis_pass_123

shell-minio: ## 🐚 الدخول إلى MinIO shell
	@$(DOCKER_COMPOSE) exec minio sh

# ========================================
# النسخ الاحتياطي والاستعادة
# ========================================

backup: ## 💾 نسخ احتياطي
	@echo "$(BLUE)💾 بدء النسخ الاحتياطي...$(NC)"
	@if [ -f scripts/backup.sh ]; then \
		bash scripts/backup.sh; \
	else \
		echo "$(RED)❌ السكربت غير موجود: scripts/backup.sh$(NC)"; \
	fi

restore: ## 📥 استعادة من نسخة احتياطية
	@echo "$(BLUE)📥 استعادة من نسخة احتياطية...$(NC)"
	@if [ -f scripts/restore.sh ]; then \
		bash scripts/restore.sh; \
	else \
		echo "$(RED)❌ السكربت غير موجود: scripts/restore.sh$(NC)"; \
	fi

# ========================================
# التحديث والبناء
# ========================================

update: ## 🔄 تحديث المشروع
	@echo "$(BLUE)🔄 تحديث المشروع...$(NC)"
	@if [ -f scripts/update.sh ]; then \
		bash scripts/update.sh; \
	else \
		echo "$(YELLOW)⚠️  السكربت غير موجود، سيتم pull الصور$(NC)"; \
		$(DOCKER_COMPOSE) pull; \
		$(MAKE) restart; \
	fi

pull: ## ⬇️ سحب أحدث الصور
	@echo "$(BLUE)⬇️  سحب أحدث الصور...$(NC)"
	@$(DOCKER_COMPOSE) pull
	@echo "$(GREEN)✅ تم السحب بنجاح$(NC)"

build: ## 🔨 بناء الصور المخصصة
	@echo "$(BLUE)🔨 بناء الصور...$(NC)"
	@$(DOCKER_COMPOSE) build
	@echo "$(GREEN)✅ تم البناء بنجاح$(NC)"

rebuild: ## 🔨 إعادة البناء (بدون cache)
	@echo "$(BLUE)🔨 إعادة البناء بدون cache...$(NC)"
	@$(DOCKER_COMPOSE) build --no-cache
	@echo "$(GREEN)✅ تم البناء بنجاح$(NC)"

# ========================================
# أدوات إضافية
# ========================================

prune: ## 🗑️ تنظيف Docker (حذف الموارد غير المستخدمة)
	@echo "$(YELLOW)🗑️  تنظيف Docker...$(NC)"
	@docker system prune -af --volumes
	@echo "$(GREEN)✅ تم التنظيف$(NC)"

disk-usage: ## 💽 عرض استخدام المساحة
	@echo "$(BLUE)💽 استخدام المساحة:$(NC)"
	@df -h | grep -E '(Filesystem|/dev/loop|/tmp|overlay)'
	@echo ""
	@echo "$(BLUE)Docker:$(NC)"
	@docker system df

network: ## 🌐 عرض الشبكات
	@echo "$(BLUE)🌐 شبكات Docker:$(NC)"
	@docker network ls | grep bisheng

volumes: ## 💾 عرض الـ volumes
	@echo "$(BLUE)💾 Docker Volumes:$(NC)"
	@docker volume ls | grep bisheng

inspect-backend: ## 🔍 فحص Backend container
	@$(DOCKER_COMPOSE) exec backend env

inspect-db: ## 🔍 فحص PostgreSQL
	@$(DOCKER_COMPOSE) exec postgres psql -U bisheng -d bisheng_dev -c "\l"
	@$(DOCKER_COMPOSE) exec postgres psql -U bisheng -d bisheng_dev -c "\dt"

test-redis: ## 🧪 اختبار Redis
	@echo "$(BLUE)🧪 اختبار Redis...$(NC)"
	@$(DOCKER_COMPOSE) exec redis redis-cli -a dev_redis_pass_123 ping

test-minio: ## 🧪 اختبار MinIO
	@echo "$(BLUE)🧪 اختبار MinIO...$(NC)"
	@curl -s http://localhost:9000/minio/health/live || echo "MinIO غير متاح"

# ========================================
# Git
# ========================================

git-status: ## 📊 حالة Git
	@git status

git-push: ## ⬆️ رفع التغييرات إلى GitHub
	@echo "$(BLUE)⬆️  رفع إلى GitHub...$(NC)"
	@git add .
	@git status
	@read -p "رسالة الـ commit: " msg && git commit -m "$$msg"
	@git push
	@echo "$(GREEN)✅ تم الرفع بنجاح$(NC)"

# ========================================
# معلومات
# ========================================

info: ## ℹ️ معلومات المشروع
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║            Bisheng Enterprise - معلومات المشروع          ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)📁 المشروع:$(NC) $(PROJECT_NAME)"
	@echo "$(CYAN)📂 المسار:$(NC) $(shell pwd)"
	@echo "$(CYAN)🌿 الفرع:$(NC) $(shell git branch --show-current 2>/dev/null || echo 'N/A')"
	@echo "$(CYAN)📊 البيئة:$(NC) $(shell grep ENVIRONMENT .env 2>/dev/null | cut -d= -f2 || echo 'غير محدد')"
	@echo ""
	@echo "$(CYAN)🐳 Docker:$(NC)"
	@docker version --format '  الإصدار: {{.Server.Version}}'
	@docker-compose version --short 2>/dev/null | awk '{print "  Compose: " $$0}' || echo "  Compose: غير متاح"
	@echo ""
	@echo "$(CYAN)💻 الموارد:$(NC)"
	@echo "  CPU: $(shell nproc) cores"
	@echo "  RAM: $(shell free -h | awk '/^Mem:/ {print $$2}')"
	@echo "  Disk: $(shell df -h / | awk 'NR==2 {print $$4 " متاح من " $$2}')"
	@echo ""

version: ## 📌 إصدارات الأدوات
	@echo "$(BLUE)📌 إصدارات الأدوات:$(NC)"
	@docker --version
	@docker-compose --version
	@git --version
	@make --version | head -1

# ========================================
# الافتراضي
# ========================================

.DEFAULT_GOAL := help

# نهاية Makefile
