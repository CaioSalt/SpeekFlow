echo '--- uso de GUw7IE no bundle principal ---'
grep -hoE '.{300}GUw7IE.{100}' /app/dist_injected/assets/index-*.js 2>/dev/null | head -2
