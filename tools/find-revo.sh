echo '--- ocorrencias de Revo em js/html ---'
grep -rl 'Revo' /app/dist_injected/index.html /app/dist_injected/assets/*.js 2>/dev/null | head
echo '--- contexto ---'
grep -rhoE '.{25}Revo.{25}' /app/dist_injected/index.html /app/dist_injected/assets/*.js 2>/dev/null | head -10
echo '--- svg home? assets web ---'
ls /app/dist_injected/assets/web/
