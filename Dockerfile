# Dockerfile.optimized - إصدار محسن
# مرحلة البناء
FROM python:3.9-slim as builder
LABEL org.opencontainers.image.title="app" \
      org.opencontainers.image.description="Optimized image" \
      org.opencontainers.image.version="1.0.0"

WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# مرحلة التشغيل النهائية
FROM python:3.9-slim

# تعيين متغيرات البيئة
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# إنشاء مستخدم غير root
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# نسخ المتطلبات من مرحلة البناء
COPY --from=builder /root/.local /root/.local
COPY --chown=appuser:appuser . .

# التأكد من أن المسار يشمل مكتبات المستخدم
ENV PATH=/root/.local/bin:$PATH

# التبديل إلى المستخدم غير root
USER appuser

# تشغيل التطبيق
CMD ["python3", "app.py"]

# Basic healthcheck
HEALTHCHECK --interval=30s --timeout=3s CMD [ "sh", "-c", "echo ok" ]