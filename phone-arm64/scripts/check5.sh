#!/bin/bash
# Roda DENTRO do container proot. Determina a config de libs correta.
cd /root/speekflow || exit 1
run() {
  local desc="$1"; shift
  echo "--- $desc ---"
  for i in 1 2 3; do
    if out=$(env "$@" ./bin/api --version 2>&1); then
      echo "  run$i: OK ($(echo "$out" | grep -m1 -o 'revolt-delta[^ ]*'))"
    else
      echo "  run$i: FALHOU -> $(echo "$out" | head -1 | cut -c1-100)"
    fi
  done
}
run "sem LD_LIBRARY_PATH" -u LD_LIBRARY_PATH
run "com bin/lib" LD_LIBRARY_PATH=/root/speekflow/bin/lib
echo ""
echo "=== ldd (ldd do container) ==="
/usr/bin/ldd ./bin/api 2>&1 | head -12
echo ""
echo "=== arquivos libssl no container ==="
ls -la /usr/lib/aarch64-linux-gnu/libssl.so.3 /usr/lib/aarch64-linux-gnu/libcrypto.so.3
echo "=== simbolos versionados nos binarios ==="
readelf -V ./bin/api 2>/dev/null | grep -A3 "Version needs" | head -12
