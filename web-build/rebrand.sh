#!/bin/sh
# Rebrand de textos: Stoat -> SpeekFlow (roda apos inject.js no start)
set -e
cd /app/dist_injected

echo "Substituindo nome 'Stoat' -> 'SpeekFlow'..."
COUNT=0
for f in $(grep -rl 'Stoat' . 2>/dev/null); do
    sed -i 's/Stoat/SpeekFlow/g' "$f"
    COUNT=$((COUNT+1))
done
echo "$COUNT arquivos atualizados."
echo "Rebrand concluido."
