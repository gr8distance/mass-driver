## ---------------------------------------------------------------------------
## mass-driver — SBCL multi-stage Docker build
##
## Build:  docker build -t mass-driver .
## Run:    docker run -p 3000:3000 -e DATABASE_URL=... mass-driver
## ---------------------------------------------------------------------------

# --- Build stage ---
FROM fukamachi/sbcl:latest AS builder

WORKDIR /app

# Install system dependencies for Woo (libev) and DB drivers
RUN apt-get update && apt-get install -y --no-install-recommends \
    libev-dev \
    libsqlite3-dev \
    libpq-dev \
    libmariadb-dev \
    git \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install area51
RUN git clone --depth 1 https://github.com/gr8distance/area51.git /tmp/area51 \
    && cd /tmp/area51 \
    && sbcl --non-interactive --load build.lisp \
    && cp bin/area51 /usr/local/bin/area51 \
    && rm -rf /tmp/area51

# Copy project files
COPY . .

# Install dependencies and build binary
RUN area51 install && area51 build

# --- Runtime stage ---
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libev4 \
    libsqlite3-0 \
    libpq5 \
    libmariadb3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash app
USER app
WORKDIR /home/app

COPY --from=builder /app/bin/mass-driver /home/app/mass-driver
COPY --from=builder /app/static /home/app/static

ENV PORT=3000
EXPOSE 3000

CMD ["./mass-driver"]
