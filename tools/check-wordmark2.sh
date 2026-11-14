echo '--- refs a wordmark em todo dist ---'
grep -rl 'wordmark' /app/dist_injected 2>/dev/null | head
echo '--- contexto ---'
grep -rhoE '.{30}wordmark.{30}' /app/dist_injected 2>/dev/null | head -8
