#!/bin/bash
# SpeekFlow - ligar todos os servicos (dentro do Ubuntu proot)
# - [1-5] servicos base (mongo externo via Atlas, valkey, rabbit, silo, livekit)
# - [6] cloudflared quick tunnel (sem dominio - *.trycloudflare.com aleatorio)
# - [7] redescobrir URL do tunnel + reescrever config + rebuild EXT bundle
# - [8] API e demais servicos
# - [9] Caddy (LAN :8080 + HTTPS :8443)
# - [10] verificacao
#
# IMPORTANTE: execute com a sessao proot PERSISTENTE:
#   proot-distro login ubuntu -- /bin/bash -c "/root/speekflow/start-all.sh; exec sleep infinity"
# (ou /root/start-speekflow.sh da Termux home)
cd /root/speekflow
mkdir -p /root/logs
export PATH=/root/speekflow/bin/usr-local-bin:$PATH
export LD_LIBRARY_PATH=/root/speekflow/bin/lib:$LD_LIBRARY_PATH
set -a; . config/secrets.env; set +a
LOG=/root/logs
port_open() { (echo >/dev/tcp/127.0.0.1/$1) 2>/dev/null; }

echo "[1/10] MongoDB (Atlas, via config/Revolt.toml)..."
if grep -qE 'mongodb(\+srv)?://(127\.0\.0\.1|localhost)' config/Revolt.toml; then
  echo "  ATENCAO: a string mongodb em config/Revolt.toml aponta para localhost."
  echo "  O mongo NAO roda no celular; aponte para o MongoDB Atlas."
  exit 1
fi
echo "  string de conexao encontrada (Atlas)"

echo "[2/10] Valkey (compativel Redis)..."
port_open 6379 || valkey-server --daemonize yes --bind 127.0.0.1 --port 6379 --ignore-warnings ARM64-COW-BUG --logfile $LOG/valkey.log
for i in $(seq 1 30); do port_open 6379 && break; sleep 1; done

echo "[3/10] RabbitMQ (pode levar 30s)..."
port_open 5672 || su -s /bin/bash rabbitmq -c 'RABBITMQ_FEATURE_FLAGS=classic_mirrored_queue_version rabbitmq-server -detached'
for i in $(seq 1 60); do port_open 5672 && break; sleep 1; done
su -s /bin/bash rabbitmq -c 'rabbitmqctl list_users' 2>/dev/null | grep -q rabbituser || su -s /bin/bash rabbitmq -c 'rabbitmqctl add_user rabbituser rabbitpass'
su -s /bin/bash rabbitmq -c 'rabbitmqctl set_permissions -p / rabbituser ".*" ".*" ".*"' 2>/dev/null || true

echo "[4/10] Silo (armazenamento de arquivos)..."
port_open 9000 || MINIO_ROOT_USER=minioautumn MINIO_ROOT_PASSWORD=minioautumn MINIO_DOMAIN=minio nohup ./bin/silo server /root/data/minio > $LOG/silo.log 2>&1 &
for i in $(seq 1 30); do port_open 9000 && break; sleep 1; done
./bin/mc alias set minio http://minio:9000 minioautumn minioautumn >/dev/null 2>&1 || true
./bin/mc mb --ignore-existing minio/revolt-uploads >/dev/null 2>&1 || true

echo "[5/10] LiveKit (voz e video)..."
port_open 7880 || nohup ./bin/livekit --config config/livekit.yml > $LOG/livekit.log 2>&1 &

echo "[6/10] Tunnel trycloudflare: DESATIVADO."
echo "  EXT usa a URL fixa https://speekflow.duckdns.org:8443 (TLS Let's Encrypt no Caddy)."
echo "  Para reverter ao tunnel: iniciar cloudflared manualmente e reescrever os hosts."

echo "[7/10] Hosts EXT fixos em speekflow.duckdns.org:8443 (nada a redescobrir)."
cd /root/speekflow

echo "[8/10] Servicos do SpeekFlow (api, eventos, arquivos)..."
port_open 14702 || nohup ./bin/api > $LOG/api.log 2>&1 &
port_open 14703 || nohup ./bin/events > $LOG/events.log 2>&1 &
port_open 14704 || nohup ./bin/autumn > $LOG/autumn.log 2>&1 &
port_open 14705 || nohup ./bin/january > $LOG/january.log 2>&1 &
port_open 14706 || nohup ./bin/gifbox > $LOG/gifbox.log 2>&1 &
port_open 8500 || nohup ./bin/voice-ingress > $LOG/voice-ingress.log 2>&1 &
pkill -x crond 2>/dev/null; pkill -x pushd 2>/dev/null
nohup ./bin/crond > $LOG/crond.log 2>&1 &
nohup ./bin/pushd > $LOG/pushd.log 2>&1 &
# cron do sistema (necessario para: DuckDNS a cada 5 min, certbot-renew, etc.)
# Sem isto, nada atualiza o DuckDNS - o arquivo /etc/cron.d/duckdns fica orfao (sem ninguem executando).
pgrep -x cron >/dev/null || nohup /usr/sbin/cron > $LOG/cron.log 2>&1 &

echo "[9/10] Caddy (LAN :8080 + HTTPS EXT :8443 com Let's Encrypt)..."
port_open 8080 || (cd /root/speekflow/config && caddy start --config Caddyfile > $LOG/caddy.log 2>&1)

echo "[10/10] Verificando servicos..."
sleep 5
bash /root/speekflow/status.sh
echo ""
echo "EXT (HTTPS fixo, Let's Encrypt): https://speekflow.duckdns.org:8443"
echo "LAN (rede local): http://192.168.0.54:8080"
echo "Desligar tudo: proot-distro login ubuntu -- /root/speekflow/stop-all.sh"
