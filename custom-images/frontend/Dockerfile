# ============================================
# Bisheng Frontend Enterprise - Custom Image
# ============================================
ARG BASE_IMAGE=dataelement/bisheng-frontend:v2.2.0-beta2
FROM ${BASE_IMAGE}

LABEL maintainer="Bisheng Enterprise Team"
LABEL version="2.0-enterprise"
LABEL description="Enhanced Bisheng Frontend with Security & Performance"

# ============================================
# Environment Variables
# ============================================
ENV NODE_ENV=production \
    NODE_OPTIONS="--max-old-space-size=2048"

# ============================================
# System Dependencies
# ============================================
USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    bash \
    && rm -rf /var/lib/apt/lists/* && apt-get clean

# ============================================
# Security Headers & Configuration
# ============================================
COPY custom-images/frontend/security-headers.conf /etc/nginx/conf.d/security-headers.conf

# ============================================
# Health Check Script
# ============================================
COPY custom-images/frontend/healthcheck.sh /usr/local/bin/healthcheck-frontend.sh
RUN chmod +x /usr/local/bin/healthcheck-frontend.sh

# ============================================
# Custom Entrypoint
# ============================================
COPY custom-images/frontend/entrypoint-frontend.sh /usr/local/bin/entrypoint-frontend.sh
RUN chmod +x /usr/local/bin/entrypoint-frontend.sh

# ============================================
# User & Permissions
# ============================================
RUN adduser -D -u 1000 bisheng && \
    chown -R bisheng:bisheng /app

USER bisheng

# ============================================
# Expose Port
# ============================================
EXPOSE 3001

# ============================================
# Health Check
# ============================================
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD /usr/local/bin/healthcheck-frontend.sh

# ============================================
# Entrypoint
# ============================================
ENTRYPOINT ["/usr/local/bin/entrypoint-frontend.sh"]
CMD ["start"]