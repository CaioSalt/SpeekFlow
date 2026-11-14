#!/bin/sh
# Rebrand de textos: Stoat -> SpeekFlow (roda apos inject.js)
# uso: rebrand-phone.sh [dist_ir]
set -e
DIR=${1:-/root/speekflow/web/dist_injected}
cd "$DIR"
COUNT=0
for f in $(grep -rl 'Stoat' . 2>/dev/null); do
    sed -i 's/Stoat/SpeekFlow/g' "$f"
    COUNT=$((COUNT+1))
done
echo "Rebrand concluido: $COUNT arquivos em $DIR."
