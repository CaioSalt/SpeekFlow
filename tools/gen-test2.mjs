// Gera HTML com os dois wordmarks embutidos (sem fetch)
import fs from 'node:fs';
const orig = fs.readFileSync('E:/Concord/tools/original-wordmark.svg', 'utf8');
const novo = fs.readFileSync('E:/Concord/branding/SpeekFlow-wordmark.svg', 'utf8');
const origFilled = orig.replace(/fill="none"/, 'fill="#ffffff"');
const html = `<!DOCTYPE html>
<html style="background:#111;margin:0">
<body style="margin:0;background:#111;display:flex;flex-direction:column;gap:40px;padding:40px;align-items:center">
  <div>${origFilled}</div>
  <div>${novo}</div>
</body>
</html>`;
fs.writeFileSync('E:/Concord/tools/wordmark-test2.html', html);
console.log('gerado:', origFilled.slice(0, 120));
