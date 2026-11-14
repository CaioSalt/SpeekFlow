#!/bin/bash
# SpeekFlow - etapa 2 (dentro do Ubuntu proot): instalar servicos
# IMPORTANTE: o mongod oficial NAO sobe no kernel do Android/proot,
# entao o banco fica no MongoDB Atlas (gratis). Configure a string em
# /root/speekflow/config/Revolt.toml ANTES de ligar (veja Passo 1/9 do start-all.sh).
set -e
export DEBIAN_FRONTEND=noninteractive

echo "=== Instalando dependencias APT (sem systemd no proot) ==="
printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

echo "[1/5] APT update..."
apt-get update -y

echo "[2/5] Instalando valkey, rabbitmq, nodejs, caddy (demora varios minutos)..."
apt-get install -y --no-install-recommends valkey rabbitmq-server nodejs caddy procps curl gnupg ca-certificates

echo "[3/5] Verificando caddy..."
caddy version

echo "[4/5] MongoDB fica EXTERNO (Atlas) - nada a instalar."
echo "      Configure a string de conexao em /root/speekflow/config/Revolt.toml:"
echo "      [database]"
echo "      mongodb = \"mongodb+srv://<usuario>:<senha>@<cluster>.mongodb.net/?retryWrites=true&w=majority\""

echo "[5/5] Montando estrutura /root/speekflow..."
mkdir -p /root/speekflow /root/data/minio /root/logs
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
echo "PASSO FINAL: edite /root/speekflow/config/Revolt.toml com a string do MongoDB Atlas."
echo "Depois ligue o servidor:"
echo "  proot-distro login ubuntu -- /root/speekflow/start-all.sh"
