
# dependency builder

FROM python:3.10-alpine AS builder

WORKDIR /build

# Install build dependencies for mysql-connector C extension
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    default-libmysqlclient-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*


COPY requirements.txt .

RUN pip install --upgrade pip --quiet \
 && pip install --prefix=/install --no-cache-dir -r requirements.txt \
 && pip install --prefix=/install --no-cache-dir gunicorn==21.2.0



FROM python:3.10-alpine AS runtime

# Labels
LABEL maintainer="sole-store"
LABEL description="Sole Store Flask e-commerce app"

# Runtime-only system libraries (no gcc, no build tools)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libmariadb3 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Non-root user for security
RUN groupadd --gid 1001 appgroup \
 && useradd  --uid 1001 --gid appgroup --no-create-home appuser

WORKDIR /app

# Copy pre-built packages from builder stage
COPY --from=builder /install /usr/local

# Copy application source (each COPY is a separate layer for cache efficiency)
COPY app.py        ./
COPY routes/       ./routes/
COPY utils/        ./utils/
COPY templates/    ./templates/
COPY schema.sql    ./

# Ownership — everything belongs to the non-root user
RUN chown -R appuser:appgroup /app

USER appuser

# Flask env — overridden at runtime via docker-compose or -e flags
ENV FLASK_ENV=production \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=5000

EXPOSE 5000

# Health check — Docker marks container unhealthy if Flask stops responding
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:5000/ || exit 1

# Gunicorn: 4 sync workers, access log to stdout, 120s timeout
# Adjust --workers to (2 * CPU cores + 1) for production
CMD ["gunicorn", \
     "--bind", "0.0.0.0:5000", \
     "--workers", "4", \
     "--timeout", "120", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "--log-level", "info", \
     "app:create_app()"]
