#!/bin/bash
# ============================================================
# Instalacao do SpeekFlow/Concord dentro do container proot (Ubuntu 26.04)
# Roda DENTRO do container:  proot-distro login ubuntu -- /bin/bash <este script>
# ============================================================
set -e
export DEBIAN_FRONTEND=noninteractive
# CRUCIAL: limpa o LD_LIBRARY_PATH herdado do Termux (libs bionic do Android
# quebram os binarios glibc). Ver README-phone.md.
export LD_LIBRARY_PATH=""
export PATH="/root/speekflow/bin/usr-local-bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
MONGO_VER=8.0.12

step() { echo ""; echo "############ $* ############"; }

step "0) bloqueando auto-start de servicos (sem systemd no proot)"
printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

step "1) apt-get update"
apt-get update -y -o Acquire::Retries=3

step "2) dependencias basicas"
apt-get install -y -o Acquire::Retries=3 --no-install-recommends \
  curl ca-certificates gnupg procps file xz-utils libdav1d7 tzdata

step "3) valkey (redis 9 - igual ao compose.yml)"
apt-get install -y -o Acquire::Retries=3 valkey

step "4) rabbitmq-server (api/pushd/voice-ingress)"
apt-get install -y -o Acquire::Retries=3 rabbitmq-server

step "5) nodejs (frontend web)"
apt-get install -y -o Acquire::Retries=3 nodejs

step "6) caddy (reverse proxy / entrada)"
apt-get install -y -o Acquire::Retries=3 caddy

step "7) mongodb $MONGO_VER via tarball oficial"
if [ ! -x /opt/mongodb/bin/mongod ]; then
  curl -fSL --retry 3 -o /tmp/mongo.tgz \
    "https://fastdl.mongodb.org/linux/mongodb-linux-aarch64-ubuntu2404-${MONGO_VER}.tgz"
  tar -xzf /tmp/mongo.tgz -C /opt
  ln -sfn "/opt/mongodb-linux-aarch64-ubuntu2404-${MONGO_VER}" /opt/mongodb
  rm -f /tmp/mongo.tgz
fi
ln -sfn /opt/mongodb/bin/mongod /usr/local/bin/mongod
/opt/mongodb/bin/mongod --version | head -2

step "8) arquivos de configuracao"
cp /root/speekflow/config/Revolt.toml /Revolt.toml
cp /root/speekflow/config/stoat.json /stoat.json
chmod 644 /Revolt.toml /stoat.json

step "9) /etc/hosts (aliases do MinIO/Silo + hostname)"
grep -q 'revolt-uploads.minio' /etc/hosts || echo "127.0.0.1 minio revolt-uploads.minio attachments.minio avatars.minio backgrounds.minio icons.minio banners.minio emojis.minio" >> /etc/hosts
grep -q "$(hostname)" /etc/hosts || echo "127.0.0.1 $(hostname)" >> /etc/hosts
cat /etc/hosts

step "10) versoes instaladas"
valkey-server --version 2>&1 | head -1
rabbitmqctl version 2>&1 | tail -1
node --version
caddy version 2>&1 | head -1
mongod --version | head -1
echo ""
echo "### INSTALACAO CONCLUIDA ###"
