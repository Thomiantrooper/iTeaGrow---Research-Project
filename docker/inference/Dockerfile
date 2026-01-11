# Tea Leaf Disease Detection Platform - Inference Service
# Optimized for ML inference with optional GPU support

ARG BASE_IMAGE=python:3.10-slim
FROM ${BASE_IMAGE} as builder

WORKDIR /build

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements-inference.txt .

RUN pip wheel --no-cache-dir --no-deps --wheel-dir /build/wheels -r requirements-inference.txt


FROM ${BASE_IMAGE} as runtime

LABEL maintainer="Tea Leaf Disease Detection Team"
LABEL version="1.0.0"
LABEL description="Inference Service with YOLOv8n for disease detection"

RUN useradd --create-home --shell /bin/bash appuser

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

COPY --from=builder /build/wheels /wheels
RUN pip install --no-cache-dir /wheels/* && rm -rf /wheels

COPY configs/ ./configs/
COPY src/core/ ./src/core/
COPY src/api/schemas.py ./src/api/
COPY src/services/inference/ ./src/services/inference/
COPY models/ ./models/

RUN mkdir -p /app/storage /app/cache \
    && chown -R appuser:appuser /app

USER appuser

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONPATH=/app
ENV OMP_NUM_THREADS=4
ENV MKL_NUM_THREADS=4

EXPOSE 8001

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8001/health || exit 1

CMD ["uvicorn", "src.services.inference.service:app", "--host", "0.0.0.0", "--port", "8001"]
