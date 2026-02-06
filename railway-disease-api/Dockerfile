# Lightweight Tea Leaf Disease Detection API for Railway
FROM python:3.10-slim

WORKDIR /app

# Install minimal system dependencies for OpenCV
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Copy and install requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application and model
COPY app.py .
COPY best.pt .

ENV PYTHONUNBUFFERED=1
ENV MODEL_PATH=/app/best.pt

EXPOSE 8000

CMD uvicorn app:app --host 0.0.0.0 --port ${PORT:-8000}
