#!/bin/bash
bash /root/speekflow/stop-all.sh
sleep 2
# garantir que morreu tudo
pkill -9 -x mongod redis-server silo livekit caddy api events autumn january gifbox crond pushd voice-ingress 2>/dev/null
pkill -9 -f beam.smp 2>/dev/null; pkill -9 -f sirv 2>/dev/null
sleep 3
rm -rf /root/data/db/* 2>/dev/null
bash /root/speekflow/start-all.sh
echo ""
echo "=== curl ==="
curl -s -o /dev/null -w "Web: HTTP %{http_code}\n" http://localhost:8080/
curl -s -o /dev/null -w "API: HTTP %{http_code}\n" http://localhost:8080/api/
echo "=== erros nos logs ==="
for f in /root/logs/*.log; do
  if grep -qiE 'panic|FATAL|FailedConnection|Error' "$f" 2>/dev/null; then echo "== $f"; grep -iE 'panic|FATAL|FailedConnection|Error' "$f" | head -3; fi
done
echo "=== fim ==="
