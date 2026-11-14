#!/bin/sh
# Rebrand de textos: Stoat -> SpeekFlow (roda dentro de /root/speekflow, apos inject.js)
set -e
cd /root/speekflow/web/dist_injected
COUNT=0
for f in $(grep -rl 'Stoat' . 2>/dev/null); do
    sed -i 's/Stoat/SpeekFlow/g' "$f"
    COUNT=$((COUNT+1))
done
echo "Rebrand concluido: $COUNT arquivos."
