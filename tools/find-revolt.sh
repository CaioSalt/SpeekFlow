echo '--- Revolt como texto JSX em JS ---'
grep -hoE '>Revolt<|"Revolt"|Revolt<' /app/dist_injected/assets/index-BrlXRz2h.js 2>/dev/null | sort | uniq -c | head
echo '--- contexto username Revolt ---'
grep -hoE '.{60}username:"Revolt".{40}' /app/dist_injected/assets/index-BrlXRz2h.js 2>/dev/null | head -3
echo '--- Revolt em todos os messages (pt) ---'
grep -hoE '.{20}Revolt.{40}' /app/dist_injected/assets/messages-*.js 2>/dev/null | sort | uniq -c | sort -rn | head -20
