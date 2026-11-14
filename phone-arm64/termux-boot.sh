#!/data/data/com.termux/files/usr/bin/bash
# SpeekFlow - hook de boot (Termux:Boot)
# Rodado automaticamente quando o celular liga, se o Termux:Boot estiver instalado.
# Tambem pode ser chamado manualmente a qualquer momento.
export HOME=/data/data/com.termux/files/home
export PREFIX=/data/data/com.termux/files/usr
export PATH=$PREFIX/bin:/system/bin

# 1) Espera a rede subir (Wi-Fi/dados) por ate 5 min antes de iniciar.
#    Sem isso, o cloudflared sobe antes da internet e o rebuild do bundle EXT
#    pode ficar com a URL antiga.
echo "[boot] Aguardando rede..."
for i in $(seq 1 60); do
  if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
    echo "[boot] Rede OK (tentativa $i)"
    break
  fi
  sleep 5
done

# 2) Sobe a stack inteira (idempotente - start-speekflow ja detecta sessao ativa)
$HOME/start-speekflow.sh
