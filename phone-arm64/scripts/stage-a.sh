#!/bin/bash
# Roda DENTRO do container proot. Copia o payload e testa os binarios ARM64.
set -e
SRC=/sdcard/Download/speekflow
DST=/root/speekflow

echo "=== copiando payload ($(du -sh $SRC | cut -f1)) ==="
mkdir -p "$DST"
cp -r "$SRC/bin" "$DST/" 
cp -r "$SRC/config" "$DST/"
mkdir -p "$DST/web"
cp -r "$SRC/web/dist" "$DST/web/"
cp "$SRC/web/package.json" "$SRC/web/package-lock.json" "$SRC/web/inject.js" "$DST/web/"
cp -r "$SRC/web/node_modules" "$DST/web/"
cp "$SRC"/*.sh "$DST/"
cp "$SRC/caddy_arm64.deb" "$DST/" 2>/dev/null || true
chmod +x "$DST"/bin/* "$DST"/bin/usr-local-bin/* "$DST"/*.sh 2>/dev/null || true
echo "copiado: $(du -sh $DST | cut -f1)"

export PATH="$DST/bin/usr-local-bin:$PATH"
export LD_LIBRARY_PATH="$DST/bin/lib:$LD_LIBRARY_PATH"

echo ""
echo "=== teste dos binarios (--version / --help) ==="
for b in api events autumn january gifbox pushd crond voice-ingress silo mc livekit; do
  printf '%-16s ' "$b"
  if out=$(./bin/$b --version 2>&1 | head -2); then
    echo "OK: $(echo "$out" | tr '\n' ' ' | cut -c1-70)"
  else
    echo "FALHOU: $(echo "$out" | head -2 | tr '\n' ' ' | cut -c1-70)"
  fi
done

echo ""
echo "=== teste ffmpeg/ffprobe ==="
./bin/usr-local-bin/ffmpeg -version 2>&1 | head -1
./bin/usr-local-bin/ffprobe -version 2>&1 | head -1
echo "=== ldd api ==="
ldd ./bin/api 2>&1 | head -10
