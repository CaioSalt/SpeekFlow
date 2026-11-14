#!/bin/bash
# SpeekFlow - atualizar DuckDNS com o IP atual do celular
# Uso: duckdns-update.sh                # atualiza apenas se mudou (cache)
#      duckdns-update.sh --force        # forca mesmo sem mudanca
#
# Token: preencha em config/duckdns.env (crie a partir de duckdns.env.example)
#   DOMAIN='speekflow'          # subdomínio speekflow.duckdns.org
#   TOKEN='<seu token>'         # obtido em https://www.duckdns.org/account.jsp
#
set -euo pipefail

if [ -f /root/speekflow/config/duckdns.env ]; then
  # shellcheck disable=SC1091
  . /root/speekflow/config/duckdns.env
fi

: "${DOMAIN:=speekflow}"
: "${TOKEN:?Preencha config/duckdns.env com DOMAIN e TOKEN}"

RUN_DIR=/root/speekflow/run
LOG_DIR=/root/speekflow/log
CACHE_FILE=$RUN_DIR/ddns.cache
LOG_FILE=$LOG_DIR/ddns.log
mkdir -p "$RUN_DIR" "$LOG_DIR"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

FORCE=0
case "${1:-}" in
  --force) FORCE=1 ;;
  "") ;;
  *) echo "uso: $0 [--force]" >&2; exit 1 ;;
esac

log "caso atual ipify.org..."
NEW4=$(curl -4 -s -m 15 https://api.ipify.org || true)
NEW6=$(curl -6 -s -m 15 https://api6.ipify.org || true)
NEW="$NEW4"
if [ -z "$NEW" ]; then NEW="$NEW6"; fi
log "ipv4=$NEW4 ipv6=$NEW6 escolha=$NEW"

OLD_CACHE=$(cat "$CACHE_FILE" 2>/dev/null || true)
if [ "$FORCE" = 0 ] && [ "$NEW" = "$OLD_CACHE" ] && [ -n "$NEW" ]; then
  log "IP sem mudanca ($NEW) - nada a fazer."
  exit 0
fi

log "atualizando duckdns -> $NEW..."
RESP=$(curl -s -m 20 "https://www.duckdns.org/update?domains=${DOMAIN}&token=${TOKEN}&ip=${NEW}")
log "resposta: $RESP"

if [[ "$RESP" == OK* ]]; then
  echo "$NEW" > "$CACHE_FILE"
  log "cache atualizado para $NEW"
else
  log "ERRO na atualizacao do DuckDNS"
  exit 1
fi
