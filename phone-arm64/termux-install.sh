#!/data/data/com.termux/files/usr/bin/sh
# SpeekFlow - etapa 1 (no Termux): instalar Ubuntu e copiar o pacote
set -e
echo "=========================================="
echo "  SpeekFlow no celular - instalacao"
echo "=========================================="
echo "Se aparecer um pedido de acesso a arquivos, toque em PERMITIR."
termux-setup-storage || true

echo "[1/4] Atualizando o Termux (1-3 min)..."
yes | pkg update -y || true

echo "[2/4] Instalando proot-distro..."
pkg install -y proot-distro

echo "[3/4] Instalando Ubuntu ARM64 (~40 MB)..."
proot-distro install ubuntu 2>/dev/null || echo "Ubuntu ja instalado, pulando."

SRC=/sdcard/Download/speekflow
ROOTFS=$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu-rootfs
echo "[4/4] Copiando pacote SpeekFlow para o Ubuntu (~700 MB, 2-5 min)..."
rm -rf "$ROOTFS/root/payload"
mkdir -p "$ROOTFS/root/payload"
cp -r "$SRC/bin" "$SRC/web" "$SRC/config" "$ROOTFS/root/payload/"
cp "$SRC/rebrand-phone.sh" "$SRC/start-all.sh" "$SRC/stop-all.sh" "$SRC/status.sh" "$SRC/setup-ubuntu.sh" "$SRC/caddy_arm64.deb" "$ROOTFS/root/payload/"

echo ""
echo "Agora instalando os servicos dentro do Ubuntu (5-15 min, muita saida de texto)..."
proot-distro login ubuntu -- /bin/bash /root/payload/setup-ubuntu.sh

echo ""
echo "=========================================="
echo " CONCLUIDO! Para ligar o servidor:"
echo "   proot-distro login ubuntu -- /root/speekflow/start-all.sh"
echo " Depois abra no navegador: http://localhost:8080"
echo "=========================================="
