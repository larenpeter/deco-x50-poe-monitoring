FROM python:3.12-slim AS builder
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*
WORKDIR /app
RUN URL=$(printf 'https://%s/%s/%s.git' 'github.com' 'SimonJPegg' 'deco-rate') && \
    git clone "$URL" . && \
    git checkout 819ca53a4b91a18f3b609346711797d2f4c2f5a9

# Fix firmware status endpoint and Number.NaN JSON response for Deco X50-PoE
RUN sed -i 's/"firmware", params={"form": "upgrade"}/"cloud", params={"form": "firmware_status"}/g' src/deco_rate/client.py && \
    sed -i 's/json.loads(decrypted.decode())/json.loads(decrypted.decode().replace("Number.NaN", "null"))/g' src/deco_rate/client.py && \
    sed -i 's/firmware_status.get("upgrade_available", False)/firmware_status.get("upgrade_available") or firmware_status.get("status", "idle") != "idle"/g' src/deco_rate/metrics.py

RUN uv sync --frozen --no-dev --no-editable

FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"
CMD ["deco-rate"]
