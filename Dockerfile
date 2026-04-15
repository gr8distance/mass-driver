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
    && rm -rf /var/lib/apt/lists/*

# Copy project files
COPY . .

# Install dependencies and build binary via area51
# If area51 is not available in the image, fall back to Quicklisp + ASDF
RUN if command -v area51 > /dev/null 2>&1; then \
      area51 install && area51 build; \
    else \
      sbcl --non-interactive \
           --eval '(load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))' \
           --eval '(push (truename ".") asdf:*central-registry*)' \
           --eval '(ql:quickload "mass-driver")' \
           --eval '(sb-ext:save-lisp-and-die "mass-driver" :toplevel #'"'"'mass-driver:main :executable t)'; \
    fi

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

COPY --from=builder /app/mass-driver /home/app/mass-driver
COPY --from=builder /app/static /home/app/static

ENV PORT=3000
EXPOSE 3000

CMD ["./mass-driver"]
