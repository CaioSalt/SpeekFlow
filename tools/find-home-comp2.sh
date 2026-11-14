grep -l 'GUw7IE' /app/dist_injected/assets/*.js 2>/dev/null | head
echo '---'
for f in $(grep -l 'GUw7IE' /app/dist_injected/assets/*.js 2>/dev/null | grep -v messages | head -2); do
  echo "FILE: $f"
  grep -hoE '.{400}GUw7IE.{60}' "$f" | head -2
done
