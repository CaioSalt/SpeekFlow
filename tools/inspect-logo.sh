echo '--- index.html title ---'
grep -oE '<title>[^<]*</title>' /app/dist_injected/index.html
echo '--- manifest name ---'
grep -oE '"(name|short_name)"[^,]*' /app/dist_injected/manifest.webmanifest
echo '--- svgs/pnns com Stoat no nome ---'
find /app/dist_injected -iname '*logo*' -o -iname '*.svg' | head -20
echo '--- svg com texto Stoat ---'
grep -l 'Stoat' $(find /app/dist_injected -name '*.svg') 2>/dev/null | head
echo '--- logo references em index ---'
grep -oE '(logo|wordmark)[^"]*\.(svg|png|webp)' /app/dist_injected/index.html | head
