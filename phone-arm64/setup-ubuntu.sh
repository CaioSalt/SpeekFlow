#!/bin/bash
# SpeekFlow - etapa 2 (dentro do Ubuntu proot): instalar servicos
set -e
export DEBIAN_FRONTEND=noninteractive

echo "=== Instalando dependencias APT (sem systemd no proot) ==="
printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

echo "[1/5] APT update..."
apt-get update -y

echo "[2/5] Instalando node, redis, rabbitmq, ffmpeg (demora varios minutos)..."
apt-get install -y procps redis-server rabbitmq-server nodejs npm ffmpeg curl gpg

echo "[3/5] Instalando Caddy (binario oficial arm64)..."
dpkg -i /root/payload/caddy_arm64.deb || apt-get -f install -y

echo "[4/5] Instalando MongoDB 8 (repo oficial arm64)..."
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc -o /tmp/mongo.asc
gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor /tmp/mongo.asc
echo "deb [ arch=arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-8.0.list
apt-get update -y
apt-get install -y mongodb-org

echo "[5/5] Montando estrutura /root/speekflow..."
mkdir -p /root/speekflow /root/data/db /root/data/minio /root/logs
cp -r /root/payload/bin /root/payload/web /root/payload/config /root/speekflow/
cp /root/payload/rebrand-phone.sh /root/payload/start-all.sh /root/payload/stop-all.sh /root/payload/status.sh /root/speekflow/
chmod +x /root/speekflow/bin/* /root/speekflow/bin/usr-local-bin/* /root/speekflow/*.sh
cp /root/payload/config/Revolt.toml /Revolt.toml
cp /root/payload/config/stoat.json /stoat.json

# Apelidos de rede do MinIO (equivalente aos aliases do Docker)
grep -q 'revolt-uploads.minio' /etc/hosts || echo "127.0.0.1 minio revolt-uploads.minio attachments.minio avatars.minio backgrounds.minio icons.minio banners.minio emojis.minio" >> /etc/hosts
# RabbitMQ precisa resolver o proprio hostname
grep -q "$(hostname)" /etc/hosts || echo "127.0.0.1 $(hostname)" >> /etc/hosts

echo ""
echo "=== INSTALACAO CONCLUIDA ==="
echo "Para ligar o servidor:"
echo "  proot-distro login ubuntu -- /root/speekflow/start-all.sh"
