# Tea Leaf Disease Detection API - Railway Deployment
# Optimized for production ML inference

FROM python:3.10-slim

LABEL maintainer="iTeaGrow Team"
LABEL version="1.0.0"

WORKDIR /app

# Install system dependencies for OpenCV and ML
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libgomp1 \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy requirements first for caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY configs/ ./configs/
COPY src/ ./src/
COPY backend/ ./backend/

# Copy the trained model (from models/ directory in repo)
COPY models/best.pt ./models/best.pt

# Create storage directories
RUN mkdir -p /app/storage /app/cache

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONPATH=/app
ENV MODEL_PATH=/app/models/best.pt
ENV DEBUG=False
ENV PORT=8000

# Expose port (Railway uses PORT env var)
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:${PORT}/health || exit 1

# Start the application
CMD uvicorn src.main:app --host 0.0.0.0 --port ${PORT:-8000}
