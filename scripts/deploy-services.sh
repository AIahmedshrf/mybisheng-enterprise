#!/bin/bash
set -e

echo "🚀 Bisheng Enterprise - Deployment Script"
echo "=========================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📦 المرحلة 1: بدء الخدمات الأساسية${NC}"
docker compose -f base/docker-compose.base.yml up -d
echo -e "${GREEN}✅ الخدمات الأساسية بدأت${NC}"

echo ""
echo -e "${BLUE}📊 المرحلة 2: بدء خدمات المراقبة${NC}"
docker compose -f infrastructure/docker-compose.monitoring.yml up -d
echo -e "${GREEN}✅ خدمات المراقبة بدأت${NC}"

echo ""
echo -e "${BLUE}🔍 فحص حالة الخدمات${NC}"
docker ps --filter "name=bisheng" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo -e "${GREEN}✅ تم بدء جميع الخدمات بنجاح!${NC}"
echo ""
echo "🌐 الخدمات المتاحة:"
echo "  • PostgreSQL: localhost:5432"
echo "  • Redis: localhost:6379"
echo "  • Elasticsearch: localhost:9200"
echo "  • Milvus: localhost:19530"
echo "  • MinIO Console: http://localhost:9001"
echo "  • Prometheus: http://localhost:9090"
echo "  • Grafana: http://localhost:3002"
