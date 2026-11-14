// Gera secrets.env e livekit.yml para uma instalacao LOCAL do Stoat (http://localhost)
// Equivalente ao generate_config.sh do repositorio, usando Node em vez de openssl.
import crypto from 'node:crypto';
import fs from 'node:fs';

const b64 = (buf) => buf.toString('base64').replace(/\+/g, '/').replace(/\//g, '/').replace(/=+$/, '');

// --- VAPID (push notifications) ---
const { privateKey } = crypto.generateKeyPairSync('ec', { namedCurve: 'P-256' });
const sec1Pem = privateKey.export({ type: 'sec1', format: 'pem' }).toString();
const sec1Der = privateKey.export({ type: 'sec1', format: 'der' });
const vapidPrivate = Buffer.from(sec1Pem).toString('base64').replace(/=+$/, '');
const point = sec1Der.subarray(sec1Der.length - 65); // ponto publico nao comprimido (65 bytes)
const vapidPublic = Buffer.from(
  point.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
).toString('base64').replace(/\+/g, '_').replace(/\//g, '_').replace(/=+$/, '');
// replicando o pipeline openssl: tail -c 65 | base64 | tr '/+' '_-' | tr -d '\n' | tr -d '='
const vapidPublicOpensslStyle = point
  .toString('base64')
  .replace(/\+/g, '_')
  .replace(/\//g, '_')
  .replace(/=+$/, '');

// --- Files encryption key ---
const filesKey = crypto.randomBytes(32).toString('base64');

// --- LiveKit ---
const lkSecret = crypto.randomBytes(24).toString('hex');
const lkKey = crypto.randomBytes(6).toString('hex');

fs.writeFileSync(
  'secrets.env',
  [
    `REVOLT__PUSHD__VAPID__PRIVATE_KEY='${vapidPrivate}'`,
    `REVOLT__PUSHD__VAPID__PUBLIC_KEY='${vapidPublicOpensslStyle}'`,
    '',
    `REVOLT__FILES__ENCRYPTION_KEY='${filesKey}'`,
    '',
    `REVOLT__API__LIVEKIT__NODES__WORLDWIDE__SECRET='${lkSecret}'`,
    `REVOLT__API__LIVEKIT__NODES__WORLDWIDE__KEY='${lkKey}'`,
    '',
  ].join('\n')
);

fs.writeFileSync(
  'livekit.yml',
  [
    'rtc:',
    '  use_external_ip: true',
    '  port_range_start: 50000',
    '  port_range_end: 50100',
    '  tcp_port: 7881',
    '',
    'redis:',
    '  address: redis:6379',
    '',
    'turn:',
    '  enabled: false',
    '',
    'keys:',
    `  ${lkKey}: ${lkSecret}`,
    '',
    'webhook:',
    `  api_key: ${lkKey}`,
    '  urls:',
    '  - "http://voice-ingress:8500/worldwide"',
    '',
  ].join('\n')
);

console.log('secrets.env e livekit.yml gerados com sucesso.');
console.log('IMPORTANTE: guarde o secrets.env - perde-lo = perder acesso aos arquivos do servidor.');
