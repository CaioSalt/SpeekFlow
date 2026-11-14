head -c 500 /app/dist_injected/assets/web/wordmark.svg
echo '---'
grep -oE 'viewBox=.[^"]*.' /app/dist_injected/assets/web/wordmark.svg | head -3
