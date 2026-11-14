#!/bin/bash
# SpeekFlow - ligar todos os servicos (dentro do Ubuntu proot)
cd /root/speekflow
mkdir -p /root/logs
export PATH=/root/speekflow/bin/usr-local-bin:$PATH
export LD_LIBRARY_PATH=/root/speekflow/bin/lib:$LD_LIBRARY_PATH
set -a; . config/secrets.env; . config/.env.web; set +a
LOG=/root/logs
port_open() { (echo >/dev/tcp/127.0.0.1/$1) 2>/dev/null; }

echo "[1/9] MongoDB..."
port_open 27017 || mongod --dbpath /root/data/db --bind_ip 127.0.0.1 --wiredTigerCacheSizeGB 0.5 --fork --logpath $LOG/mongod.log || { echo "  FALHA - veja $LOG/mongod.log"; }
for i in $(seq 1 30); do port_open 27017 && break; sleep 1; done

echo "[2/9] Redis..."
port_open 6379 || redis-server --daemonize yes --bind 127.0.0.1 --port 6379 --ignore-warnings ARM64-COW-BUG --logfile $LOG/redis.log
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

echo "[7/9] Frontend web..."
cd /root/speekflow/web
port_open 5000 || {
  node inject.js > $LOG/web.log 2>&1
  sh /root/speekflow/rebrand-phone.sh >> $LOG/web.log 2>&1
  nohup node node_modules/sirv-cli/bin.js dist_injected --port 5000 --cors --single --host >> $LOG/web.log 2>&1 &
}

echo "[8/9] Caddy (porta 8080)..."
port_open 8080 || (cd /root/speekflow/config && caddy start --config Caddyfile > $LOG/caddy.log 2>&1)

echo "[9/9] Verificando servicos..."
sleep 5
bash /root/speekflow/status.sh
echo ""
echo "Se tudo estiver OK, abra no navegador do celular: http://localhost:8080"
echo "Desligar tudo: proot-distro login ubuntu -- /root/speekflow/stop-all.sh"
