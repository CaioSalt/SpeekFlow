echo '--- path do wordmark original dentro do bundle? ---'
grep -c 'M478.909 70.6364' /app/dist_injected/assets/index-BrlXRz2h.js 2>/dev/null
grep -c 'M478.909 70.6364' /app/dist/assets/*.js 2>/dev/null | grep -v ':0' | head
echo '--- o wordmark original em /app/dist soletra o que? (ver dimensoes) ---'
head -c 120 /app/dist/assets/web/wordmark.svg
echo
echo '--- quantidade de paths ---'
grep -o '<path' /app/dist/assets/web/wordmark.svg | wc -l
