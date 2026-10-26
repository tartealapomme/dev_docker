FROM python:3.12-slim AS builder
ARG TARGETARCH
WORKDIR /app
COPY requirements.txt .
RUN --mount=type=secret,id=pipconf,target=/etc/pip.conf,required=true \
    --mount=type=cache,id=pip-${TARGETARCH},target=/root/.cache/pip \
    pip install --prefix=/install -r requirements.txt

FROM python:3.12-slim AS test
ARG TARGETARCH
WORKDIR /app
COPY requirements.txt requirements-dev.txt ./
RUN --mount=type=secret,id=pipconf,target=/etc/pip.conf,required=true \
    --mount=type=cache,id=pip-${TARGETARCH},target=/root/.cache/pip \
    pip install -r requirements-dev.txt
COPY worker ./worker
COPY tests ./tests
ENV PYTHONPATH=/app
RUN python -m pytest tests

FROM python:3.12-slim AS runtime
WORKDIR /app
RUN useradd --uid 1000 --create-home --shell /usr/sbin/nologin app
COPY --from=builder /install /usr/local
COPY worker ./worker
USER 1000
CMD ["python", "-m", "worker.main"]
