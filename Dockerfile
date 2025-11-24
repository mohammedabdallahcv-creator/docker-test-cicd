# Dockerfile.basic - إصدار غير محسن
FROM ubuntu:20.04
LABEL org.opencontainers.image.title="app" \
      org.opencontainers.image.description="Optimized image" \
      org.opencontainers.image.version="1.0.0"

# تثبيت جميع الحزم المطلوبة
RUN apt-get update && apt-get install -y --no-install-recommends -y \
    python3 \
    python3-pip \
    git \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# نسخ الكود المصدري
COPY . /app
WORKDIR /app

# تثبيت المتطلبات
RUN pip3 install -r requirements.txt

# تشغيل التطبيق
CMD ["python3", "app.py"]

# Add non-root user for better security
RUN addgroup -S app && adduser -S app -G app
USER app

# Basic healthcheck
HEALTHCHECK --interval=30s --timeout=3s CMD [ "sh", "-c", "echo ok" ]