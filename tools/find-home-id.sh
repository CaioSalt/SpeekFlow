echo '--- id da traducao no pt ---'
grep -hoE '"[A-Za-z0-9_-]{4,8}":\["Criar um grupo ou servidor"\]' /app/dist_injected/assets/messages-*.js 2>/dev/null | head -3
grep -hoE '.{0,10}Criar um grupo ou servidor' /app/dist_injected/assets/messages-*.js 2>/dev/null | head -3
echo '--- ids visiveis ---'
grep -hoE '[A-Za-z0-9_-]{5,7}":\["Criar um grupo' /app/dist_injected/assets/messages-*.js 2>/dev/null | head
