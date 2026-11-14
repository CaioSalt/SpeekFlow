echo '--- css classes com wordmark/logo ---'
grep -rhoE '[a-z-]*wordmark[a-z-]*' /app/dist_injected/assets/*.css 2>/dev/null | sort | uniq -c | head
echo '--- arquivos css ---'
ls /app/dist_injected/assets/*.css 2>/dev/null | head
echo '--- respostas da API raiz ---'
