grep -o 'wordmark[^"]*' /app/dist_injected/assets/*.js 2>/dev/null | sort | uniq -c | head
echo '---MONO---'
grep -o 'monochrome[^"]*' /app/dist_injected/assets/*.js 2>/dev/null | sort | uniq -c | head
echo '---HEAD-MONO---'
head -c 300 /app/dist_injected/assets/web/monochrome.svg
