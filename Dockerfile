FROM python:3.11-slim AS builder

WORKDIR /app

# Install Poetry
ENV POETRY_VERSION=1.8.5 \
    POETRY_HOME="/opt/poetry" \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=true

RUN pip install --no-cache-dir "poetry==${POETRY_VERSION}"

# Copy dependency files
COPY pyproject.toml poetry.lock* ./

# Install dependencies (no dev, no root package)
RUN poetry config virtualenvs.create false \
    && poetry install --no-dev --no-root

# ---
FROM python:3.11-slim AS runtime

WORKDIR /app

# Copy virtualenv and app from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY app ./app
COPY pyproject.toml ./

ENV PYTHONPATH=/app \
    PORT=3000

EXPOSE 3000

# Bind to 0.0.0.0 so container accepts external connections
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT}"]
