#!/bin/bash
# Roda DENTRO do container proot. Checa opcoes de redis/mongodb/rabbitmq.
echo "=== apt search redis/valkey ==="
apt-cache search --names-only 'redis|valkey' 2>/dev/null | head -20
echo ""
echo "=== apt search mongo ==="
apt-cache search --names-only 'mongo' 2>/dev/null | head -10
echo ""
echo "=== libssl do container ==="
ls /usr/lib/aarch64-linux-gnu/libssl.so.3 /usr/lib/aarch64-linux-gnu/libcrypto.so.3 2>&1
echo ""
echo "=== deps do rabbitmq ==="
apt-cache depends rabbitmq-server 2>/dev/null | head -20
echo ""
echo "=== repositorio oficial do redis (noble) ==="
curl -sI https://packages.redis.io/deb/dists/noble/Release 2>&1 | head -3
echo "=== repositorio oficial do redis (resolute?) ==="
curl -sI https://packages.redis.io/deb/dists/resolute/Release 2>&1 | head -3
echo "=== mongodb fastdl arm64 ==="
for v in 8.0.4 8.0.3 8.0.12; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -I "https://fastdl.mongodb.org/linux/mongodb-linux-aarch64-ubuntu2404-$v.tgz")
  echo "$v => $code"
done
echo "=== mongodb arm64 ubuntu2604? ==="
for v in 8.0.4 8.0.12; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -I "https://fastdl.mongodb.org/linux/mongodb-linux-aarch64-ubuntu2604-$v.tgz")
  echo "ubuntu2604 $v => $code"
done
