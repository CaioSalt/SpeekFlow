# SpeekFlow no celular — como tudo volta se a internet cair ou o celular desligar

> Cenários cobertos por este documento:
> 1. **Internet caiu** e voltou (celular ligado o tempo todo)
> 2. **O S21 FE desligou/reiniciou**

## 1) Internet caiu e voltou

**Não precisa fazer nada.** Tudo se recupera sozinho:

- O proot e os serviços (API, LiveKit, Caddy…) continuam rodando durante a queda.
- O `cloudflared` reconecta automaticamente e mantém a mesma URL do tunnel.
- O driver do MongoDB Atlas reconecta sozinho.
- Chamadas de voz/vídeo caem no meio, mas o app volta a funcionar quando a rede volta.
- Se o **IP público mudar** enquanto a internet ficou fora:
  - o cron (`*/5 * * * * /root/speekflow/duckdns-update.sh`) detecta e atualiza o DuckDNS;
  - o LiveKit **não precisa de sincronização manual**: usa `use_external_ip: true` (STUN) e descobre o IP público sozinho a cada start.
  - ~~node_ip fixo no `livekit.yml`~~ **não use**: no Android/proot, o LiveKit 1.13.4 morre com `route ip+net: netlinkrib: invalid argument` antes de subir (confirmado após reboot em nov/2026).

## 2) O S21 FE desligou/reiniciou

### O que foi configurado (nov/2026) — liga sozinho:

- **Termux:Boot** (v0.8.1, build do GitHub, mesma assinatura do Termux do celular) instalado e aberto uma vez — Registra `BOOT_COMPLETED`.
  - Obs.: a build do F-Droid **não** funciona (assinatura incompatível: `INSTALL_FAILED_SHARED_USER_INCOMPATIBLE`).
- `~/.termux/boot/00-speekflow` — aguarda a rede subir (ping 1.1.1.1, até 5 min) e chama `~/start-speekflow.sh`.
- `start-all.sh` agora também inicia o **cron do sistema** (`/usr/sbin/cron`) — necessário para DuckDNS e certbot-renew. (Antes disso, o `/etc/cron.d/duckdns` existia mas nada o executava.)
- Android configurado via adb para não suspender nada:
  - `dumpsys deviceidle whitelist +com.termux +com.termux.boot` (fora do Doze),
  - `settings put global stay_on_while_plugged_in 7` (tela ligada enquanto carrega).

### O que acontece na prática quando o celular liga:

1. Android termina o boot → Termux:Boot dispara `00-speekflow`.
2. O script espera a rede (Wi-Fi/dados) responder `ping 1.1.1.1`.
3. Chama `start-speekflow.sh` → proot persistente sobe tudo: Valkey, RabbitMQ, Silo, LiveKit, túnel e o rebuild do bundle EXT com a **nova URL do tunnel**.
4. `cron` sobe e agenda DuckDNS/certbot.
5. URL pública nova (muda a cada boot) — consulte com `status-speekflow` ou abra o arquivo `~/speekflow-run.log`.

### Se por algum motivo NÃO subir sozinho:

```bash
# no Termux do celular:
start-speekflow        # sobe tudo
status-speekflow       # verifica portas + mostra a URL do tunnel
```

### Para deixar ainda mais à prova de falhas (opcional):

- **Configurações → Bateria → Limites de uso em segundo plano → Apps que não suspendem** → adicione `Termux` e `Termux:Boot`.
- Mantenha o celular **na tomada** (o app `Stay awake` via developer options já está ativo).
- Reserve o IP da LAN no roteador (ou deixe-o fixo) — a URL `http://192.168.0.54:8080` está "chumbada" na configuração.

### Por que a URL pública muda toda vez que liga

O túnel gratuito `trycloudflare.com` é temporário — cada sessão do `cloudflared` gera uma URL nova. A única forma de URL fixa é registrar um domínio próprio. Enquanto isso não acontece, o bundle EXT e o `Revolt.toml` são regrados automaticamente a cada boot pelo passo `[7/10]` do `start-all.sh`.
