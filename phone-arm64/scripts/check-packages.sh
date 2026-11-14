#!/bin/bash
# Roda DENTRO do container proot (Ubuntu 26.04). Verifica conectividade e pacotes disponiveis.
set -x
echo "=== apt-get update ==="
apt-get update -y 2>&1 | tail -5
echo "=== candidatos ==="
for p in redis-server valkey-server rabbitmq-server nodejs npm mongodb-org-server mongodb-server caddy ffmpeg curl gpg ca-certificates; do
  v=$(apt-cache policy "$p" 2>/dev/null | sed -n 's/^  Candidate: //p')
  echo "$p => ${v:-NAO DISPONIVEL}"
done
echo "=== versao node ==="
apt-cache policy nodejs 2>/dev/null | head -4
echo "=== glibc ==="
ldd --version | head -1
echo "=== disco ==="
df -h / | tail -1
echo "=== nproc/mem ==="
nproc
grep MemTotal /proc/meminfo
