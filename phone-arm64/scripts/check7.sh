#!/bin/bash
cd /root/speekflow || exit 1
echo "=== ls bin/api ==="
ls -la bin/api
echo ""
echo "=== LD_DEBUG=libs ==="
LD_DEBUG=libs LD_DEBUG_OUTPUT=/tmp/lddbg ./bin/api --version 2>&1 | head -5
echo "--- arquivos de debug gerados ---"
ls /tmp/lddbg.* 2>/dev/null | head -3
for f in /tmp/lddbg.*; do
  [ -f "$f" ] && { echo "== $f =="; grep -E "find library|needed by|calling init|error" "$f" | head -25; break; }
done
echo ""
echo "=== /lib ==="
ls -la /lib | head -20
echo ""
echo "=== /usr/lib/aarch64-linux-gnu (primeiros) ==="
ls /usr/lib/aarch64-linux-gnu/ 2>&1 | head -20
echo ""
echo "=== existe libc.so (linker script)? ==="
ls -la /usr/lib/aarch64-linux-gnu/libc.so 2>&1
ls -la /usr/lib/aarch64-linux-gnu/libgcc_s.so.1 2>&1
