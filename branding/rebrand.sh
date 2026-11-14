#!/bin/sh
# Rebrand: Stoat -> SpeekFlow (roda no inicio do container, apos inject.js)
set -e
cd /app/dist_injected

echo "Substituindo nome 'Stoat' -> 'SpeekFlow'..."
COUNT=0
for f in $(grep -rl 'Stoat' . 2>/dev/null); do
    sed -i 's/Stoat/SpeekFlow/g' "$f"
    COUNT=$((COUNT+1))
done
echo "$COUNT arquivos atualizados."

echo "Trocando wordmark.svg..."
cp /tmp/SpeekFlow-wordmark.svg assets/web/wordmark.svg

echo "Rebrand concluido."
