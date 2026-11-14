#!/bin/bash
# Roda DENTRO do container proot. Testa os binarios ARM64.
cd /root/speekflow || exit 1
export PATH="/root/speekflow/bin/usr-local-bin:$PATH"
export LD_LIBRARY_PATH="/root/speekflow/bin/lib:$LD_LIBRARY_PATH"
echo "=== conteudo de bin/ ==="
ls bin/
echo ""
echo "=== teste dos binarios ==="
for b in api events autumn january gifbox pushd crond voice-ingress silo mc livekit; do
  printf '%-16s ' "$b"
  out=$(./bin/$b --version 2>&1 | head -2 | tr '\n' ' ')
  echo "${out:0:90}"
done
echo ""
echo "=== ffmpeg/ffprobe ==="
./bin/usr-local-bin/ffmpeg -version 2>&1 | head -1
./bin/usr-local-bin/ffprobe -version 2>&1 | head -1
echo "=== ldd api ==="
ldd ./bin/api 2>&1 | head -8
