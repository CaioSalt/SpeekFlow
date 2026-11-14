#!/bin/bash
# SpeekFlow - ligar todos os servicos (dentro do Ubuntu proot)
# MongoDB: NAO roda local (o mongod oficial nao sobe no proot/kernel do Android).
# O banco de dados fica no MongoDB Atlas (preencha a string de conexao no config/Revolt.toml
# antes de ligar - veja Revolt.toml/hosts.database e o guia no README).
cd /root/speekflow
mkdir -p /root/logs
export PATH=/root/speekflow/bin/usr-local-bin:$PATH
export LD_LIBRARY_PATH=/root/speekflow/bin/lib:$LD_LIBRARY_PATH
set -a; . config/secrets.env; set +a
LOG=/root/logs
port_open() { (echo >/dev/tcp/127.0.0.1/$1) 2>/dev/null; }

echo "[1/9] MongoDB (Atlas, via config/Revolt.toml)..."
if grep -qE 'mongodb(\+srv)?://(127\.0\.0\.1|localhost)' config/Revolt.toml; then
  echo "  ATENCAO: a string mongodb em config/Revolt.toml aponta para 127.0.0.1/localhost."
  echo "  O mongod NAO roda neste celular. Aponte para o MongoDB Atlas e rode este script de novo."
  exit 1
fi
echo "  string de conexao encontrada (Atlas)"

echo "[2/9] Valkey (compativel Redis)..."
port_open 6379 || valkey-server --daemonize yes --bind 127.0.0.1 --port 6379 --ignore-warnings ARM64-COW-BUG --logfile $LOG/valkey.log
for i in $(seq 1 30); do port_open 6379 && break; sleep 1; done

echo "[3/9] RabbitMQ (pode levar 30s)..."
port_open 5672 || su -s /bin/bash rabbitmq -c 'RABBITMQ_FEATURE_FLAGS=classic_mirrored_queue_version rabbitmq-server -detached'
for i in $(seq 1 60); do port_open 5672 && break; sleep 1; done
su -s /bin/bash rabbitmq -c 'rabbitmqctl list_users' 2>/dev/null | grep -q rabbituser || su -s /bin/bash rabbitmq -c 'rabbitmqctl add_user rabbituser rabbitpass'
su -s /bin/bash rabbitmq -c 'rabbitmqctl set_permissions -p / rabbituser ".*" ".*" ".*"' 2>/dev/null || true

echo "[4/9] Silo (armazenamento de arquivos)..."
port_open 9000 || MINIO_ROOT_USER=minioautumn MINIO_ROOT_PASSWORD=minioautumn MINIO_DOMAIN=minio nohup ./bin/silo server /root/data/minio > $LOG/silo.log 2>&1 &
for i in $(seq 1 30); do port_open 9000 && break; sleep 1; done
./bin/mc alias set minio http://minio:9000 minioautumn minioautumn >/dev/null 2>&1 || true
./bin/mc mb --ignore-existing minio/revolt-uploads >/dev/null 2>&1 || true

echo "[5/9] LiveKit (voz e video)..."
port_open 7880 || nohup ./bin/livekit --config config/livekit.yml > $LOG/livekit.log 2>&1 &

echo "[6/9] Servicos do SpeekFlow (api, eventos, arquivos)..."
port_open 14702 || nohup ./bin/api > $LOG/api.log 2>&1 &
port_open 14703 || nohup ./bin/events > $LOG/events.log 2>&1 &
port_open 14704 || nohup ./bin/autumn > $LOG/autumn.log 2>&1 &
port_open 14705 || nohup ./bin/january > $LOG/january.log 2>&1 &
port_open 14706 || nohup ./bin/gifbox > $LOG/gifbox.log 2>&1 &
port_open 8500 || nohup ./bin/voice-ingress > $LOG/voice-ingress.log 2>&1 &
# crond e pushd nao tem porta: reinicia sempre
pkill -x crond 2>/dev/null; pkill -x pushd 2>/dev/null
nohup ./bin/crond > $LOG/crond.log 2>&1 &
nohup ./bin/pushd > $LOG/pushd.log 2>&1 &

echo "[7/9] Frontend web (dois builds: LAN e publico)..."
cd /root/speekflow/web
port_open 8080 || port_open 8443 || {
  rm -rf dist_lan dist_ext dist_injected_lan dist_injected_ext
  # LAN (http://192.168.0.54:8080)
  cp -a dist dist_lan
  set -a; . /root/speekflow/config/.env.lan; set +a
  node inject.js dist_lan dist_injected_lan
  sh /root/speekflow/rebrand-phone.sh /root/speekflow/web/dist_injected_lan
  # EXTERNO (https://speekflow.duckdns.org)
  cp -a dist dist_ext
  set -a; . /root/speekflow/config/.env.ext; set +a
  node inject.js dist_ext dist_injected_ext
  sh /root/speekflow/rebrand-phone.sh /root/speekflow/web/dist_injected_ext
}

echo "[8/9] Caddy (LAN :8080 + HTTPS :8443)..."
port_open 8080 || (cd /root/speekflow/config && caddy start --config Caddyfile > $LOG/caddy.log 2>&1)

echo "[9/10] Cloudflare Tunnel (trycloudflare.com - gratuito, URL aleatoria)..."
pgrep -x cloudflared > /dev/null || {
  : > $LOG/cloudflared.log
  nohup /root/speekflow/bin/cloudflared tunnel --url http://127.0.0.1:8080 > $LOG/cloudflared.log 2>&1 &
  for i in $(seq 1 30); do grep -q 'Your quick Tunnel' $LOG/cloudflared.log && break; sleep 1; done
  url=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' $LOG/cloudflared.log | head -1)
  if [ -n "$url" ]; then echo "  Tunnel URL publica: $url"; else echo "  Tunnel iniciado (pode levar alguns segundos para a URL aparecer)"; fi
}

echo "[10/10] Verificando servicos..."
sleep 5
bash /root/speekflow/status.sh
echo ""
echo "LAN (rede local): http://192.168.0.54:8080"
echo "Internet (gratis): URL trycloudflare.com impressa acima (muda a cada reinicio)"
echo "Ext (internet):    https://speekflow.duckdns.org (port forward 443->8443 no roteador)"
echo "Desligar tudo: proot-distro login ubuntu -- /root/speekflow/stop-all.sh"
