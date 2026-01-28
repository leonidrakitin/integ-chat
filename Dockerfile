FROM python:3.11-slim AS builder

WORKDIR /app

# Install Poetry (match poetry.lock generator version)
ENV POETRY_VERSION=2.1.4 \
    POETRY_HOME="/opt/poetry" \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=true

RUN pip install --no-cache-dir "poetry==${POETRY_VERSION}"

# Copy dependency files
COPY pyproject.toml poetry.lock* ./

# Install dependencies (main group only, no root package)
RUN poetry config virtualenvs.create false \
    && poetry install --only main --no-root

# ---
FROM python:3.11-slim AS runtime

WORKDIR /app

# Copy virtualenv and app from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY app ./app
COPY pyproject.toml ./

ENV PYTHONPATH=/app \
    PORT=4000

EXPOSE 4000

# Bind to 0.0.0.0 so container accepts external connections
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT}"]
