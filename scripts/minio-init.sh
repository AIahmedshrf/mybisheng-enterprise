#!/bin/bash
mc alias set local http://minio:9000 ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD}
mc mb local/bisheng-production
mc anonymous set public local/bisheng-production