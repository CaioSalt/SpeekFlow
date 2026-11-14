#!/bin/bash
cd /root/speekflow || exit 1
echo "=== NEEDED do proprio bin/api (lido de dentro do container) ==="
readelf -d ./bin/api 2>&1 | grep NEEDED
echo ""
echo "=== NEEDED das libs do CONTAINER ==="
for l in /usr/lib/aarch64-linux-gnu/libssl.so.3 /usr/lib/aarch64-linux-gnu/libcrypto.so.3 /usr/lib/aarch64-linux-gnu/libgcc_s.so.1 /usr/lib/aarch64-linux-gnu/libm.so.6; do
  echo "-- $l"
  readelf -d "$l" 2>&1 | grep NEEDED
done
echo ""
echo "=== log LD_DEBUG completo (parte da busca) ==="
rm -f /tmp/lddbg.*
LD_DEBUG=libs LD_DEBUG_OUTPUT=/tmp/lddbg ./bin/api --version >/dev/null 2>&1
f=$(ls /tmp/lddbg.* 2>/dev/null | head -1)
[ -n "$f" ] && sed -n '1,60p' "$f"
