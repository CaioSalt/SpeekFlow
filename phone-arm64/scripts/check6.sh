#!/bin/bash
# Roda DENTRO do container proot. Diagnostico definitivo das libs.
cd /root/speekflow || exit 1
echo "=== bin/lib/libssl.so.3: NEEDED + interpreter ==="
readelf -d bin/lib/libssl.so.3 2>&1 | grep -E 'NEEDED|SONAME'
readelf -l bin/lib/libssl.so.3 2>&1 | grep -i interpreter
echo ""
echo "=== bin/lib/libcrypto.so.3: NEEDED ==="
readelf -d bin/lib/libcrypto.so.3 2>&1 | grep -E 'NEEDED|SONAME'
echo ""
echo "=== o bin/lib/libssl funciona com bash? ==="
LD_LIBRARY_PATH=/root/speakflow/bin/lib /bin/bash -c 'echo bash-ok' 2>&1 | head -2
echo ""
echo "=== api carrega? (sem LD_LIBRARY_PATH, 3x) ==="
for i in 1 2 3; do
  out=$(./bin/api --version 2>&1)
  if echo "$out" | grep -q "Starting revolt-delta"; then echo "  run$i: BINARIO CARREGOU OK"; else echo "  run$i: NAO CARREGOU -> $(echo "$out" | head -1)"; fi
done
echo ""
echo "=== outros binarios carregam? ==="
for b in events autumn january gifbox pushd crond voice-ingress; do
  out=$(./bin/$b --version 2>&1 | head -1)
  printf '  %-14s %s\n' "$b" "$(echo $out | cut -c1-80)"
done
echo ""
echo "=== links simbolicos do container ==="
ls -la /usr/lib/aarch64-linux-gnu/libssl.so.3 /usr/lib/aarch64-linux-gnu/libcrypto.so.3 /usr/lib/aarch64-linux-gnu/libgcc_s.so.1 2>&1
