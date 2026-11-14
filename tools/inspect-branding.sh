echo '--- arquivos com Stoat ---'
grep -rl 'Stoat' /app/dist_injected 2>/dev/null | head -30
echo '--- total ---'
grep -rl 'Stoat' /app/dist_injected 2>/dev/null | wc -l
echo '--- ocorrencias (contexto) ---'
grep -rhoE '.{12}Stoat.{12}' /app/dist_injected 2>/dev/null | sort | uniq -c | sort -rn | head -40
echo '--- structure ---'
ls /app/dist_injected | head -40
