# SpeekFlow no celular — como tudo volta se a internet cair ou o celular desligar

> Cenários cobertos por este documento:
> 1. **Internet caiu** e voltou (celular ligado o tempo todo)
> 2. **O S21 FE desligou/reiniciou**

> URL pública via **Cloudflare Tunnel** (trycloudflare) — muda a cada boot do celular;
> o `status-speekflow` e a tela do `start-speekflow` mostram a URL atual.
> LAN: **http://192.168.0.54:8080**

## Por que não tem URL fixa (nov/2026 — testado na prática)

A Claro **bloqueia todo TCP de entrada** (80, 443, 8443, 18443, …) e o tráfego IPv6 também não passa no caminho usado pelo Claro BR. O único caminho externo confiável é a **saída HTTPS** para os servidores Cloudflare (o túnel trycloudflare, porta 443 de saída). O UDP 50000–50100 de entrada funciona (voz/vídeo); TCP 7881 também é usado para mídia.

**Para ter URL fixa de verdade:** comprar um domínio (~R$ 20–40/ano), adicionar no Cloudflare (zona) e criar um *named tunnel* com hostname fixo. Aí `speekflow.seudominio.com` funciona sempre.

## 1) Internet caiu e voltou

**Não precisa fazer nada.** Tudo se recupera sozinho:

- O proot e os serviços (API, LiveKit, Caddy…) continuam rodando durante a queda.
- O `cloudflared` reconecta automaticamente e mantém a mesma URL do túnel (a URL só muda quando a sessão do túnel termina — ex.: reboot).
- O driver do MongoDB Atlas reconecta sozinho.
- Chamadas de voz/vídeo caem no meio, mas o app volta a funcionar quando a rede volta.
- Se o **IP público mudar** enquanto a internet ficou fora:
  - o cron (`*/5 * * * * /root/speekflow/duckdns-update.sh`) detecta e atualiza o DuckDNS (A e AAAA);
  - o LiveKit usa **`node_ip` estático** (`livekit.yml`) com o IPv4 público — STUN foi descartado em nov/2026: a validação de IP falha 100% ("context canceled") e o candidato IPv4 nunca entrava na lista ICE, deixando as chamadas mudas.
  - Se o IP público mudar de novo, o `node_ip` precisa ser atualizado no `livekit.yml` (registrar um domínio + DDNS 🡢 o pedaço mais velho do mundo: `sed -i "s/node_ip: .*/node_ip: $NOVO_IP/"` + reinício do LiveKit).

## 2) O S21 FE desligou/reiniciou

### O que foi configurado (nov/2026) — liga sozinho:

- **Termux:Boot** (v0.8.1, build do GitHub, mesma assinatura do Termux do celular) instalado e aberto uma vez — Registra `BOOT_COMPLETED`.
  - Obs.: a build do F-Droid **não** funciona (assinatura incompatível: `INSTALL_FAILED_SHARED_USER_INCOMPATIBLE`).
- `~/.termux/boot/00-speekflow` — aguarda a rede subir (ping 1.1.1.1, até 5 min) e chama `~/start-speekflow.sh`.
- `start-all.sh` também inicia o **cron do sistema** (`/usr/sbin/cron`) — necessário para DuckDNS e certbot-renew. (Antes disso, o `/etc/cron.d/duckdns` existia mas nada o executava.)
- Android configurado via adb para não suspender nada:
  - `dumpsys deviceidle whitelist +com.termux +com.termux.boot` (fora do Doze),
  - `settings put global stay_on_while_plugged_in 7` (tela ligada enquanto carrega).

### O que acontece na prática quando o celular liga:

1. Android termina o boot → Termux:Boot dispara `00-speekflow`.
2. O script espera a rede (Wi-Fi/dados) responder `ping 1.1.1.1`.
3. Chama `start-speekflow.sh` → proot persistente sobe tudo: Valkey, RabbitMQ, Silo, LiveKit, túnel trycloudflare (apontando para :8443) e o rebuild do bundle EXT com a **nova URL do túnel** (passos `[6/10]` e `[7/10]`).
4. `cron` sobe e agenda DuckDNS/certbot (a renovação do Let's Encrypt tem deploy-hook que reinicia o Caddy).
5. URL pública nova — consulte com `status-speekflow`.

### Se por algum motivo NÃO subir sozinho:

```bash
# no Termux do celular:
start-speekflow        # sobe tudo
status-speekflow       # verifica portas + mostra a URL do túnel
```

### Para deixar ainda mais à prova de falhas (opcional):

- **Configurações → Bateria → Limites de uso em segundo plano → Apps que não suspendem** → adicione `Termux` e `Termux:Boot`.
- Mantenha o celular **na tomada** (o app `Stay awake` via developer options já está ativo).
- Reserve o IP da LAN no roteador (ou deixe-o fixo) — a URL `http://192.168.0.54:8080` está "chumbada" na configuração.

## Notas e decisões

- O túnel apenas **transporta TCP (HTTPS/WSS)** — voz/vídeo ao vivo vão por **UDP 50000–50100 + TCP 7881** direto no IP público (UDP funciona nesse provedor; por isso a chamada funciona mesmo com todas as portas TCP de entrada bloqueadas).
- O registro **AAAA** do `speekflow.duckdns.org` aponta para o IPv6 do celular (melhor esforço; atualizado a cada 5 min pelo cron) — mantido para o dia em que o filtro de IPv6 da Claro permitir.
- O certificado Let's Encrypt de `speekflow.duckdns.org` existe em `/etc/letsencrypt` e seria usado num cenário direto (sem provedor bloqueando); hoje o acesso externo é sempre pelo túnel (cert do próprio Cloudflare, válido).
