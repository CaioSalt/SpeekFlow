#!/bin/bash
# Roda DENTRO do container proot.
cd /root/speekflow || exit 1
echo "=== o Termux tem libssl do Android em \$PREFIX/lib? ==="
ls -la /data/data/com.termux/files/usr/lib/libssl.so* /data/data/com.termux/files/usr/lib/libcrypto.so* /data/data/com.termux/files/usr/lib/libc.so* 2>&1 | head
echo ""
echo "=== 1) com LD_LIBRARY_PATH herdado do Termux ==="
./bin/api --version 2>&1 | head -2
echo ""
echo "=== 2) com LD_LIBRARY_PATH limpo ==="
LD_LIBRARY_PATH= ./bin/api --version 2>&1 | head -2
echo ""
echo "=== 3) com LD_LIBRARY_PATH=/root/speekflow/bin/lib ==="
LD_LIBRARY_PATH=/root/speekflow/bin/lib ./bin/api --version 2>&1 | head -2
echo ""
echo "=== 4) todos os binarios com LD_LIBRARY_PATH limpo ==="
for b in api events autumn january gifbox pushd crond voice-ingress silo mc livekit; do
  printf '  %-14s ' "$b"
  out=$(LD_LIBRARY_PATH= ./bin/$b --version 2>&1 | head -1 | cut -c1-60)
  echo "$out"
done
