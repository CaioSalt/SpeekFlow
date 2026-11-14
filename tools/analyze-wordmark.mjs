// Analisa os paths do wordmark original: min/max X
import fs from 'node:fs';
const svg = fs.readFileSync('E:/Concord/tools/original-wordmark.svg', 'utf8');
const ds = [...svg.matchAll(/d="([^"]+)"/g)].map(m => m[1]);
console.log('total paths:', ds.length);
let minX = Infinity, maxX = -Infinity;
for (const d of ds) {
  const nums = [...d.matchAll(/-?\d+\.?\d*/g)].map(Number);
  for (let i = 0; i + 1 < nums.length; i += 2) {
    // aproximação: pares x,y em comandos absolutos
    const x = nums[i], y = nums[i+1];
    if (x < minX) minX = x;
    if (x > maxX) maxX = x;
  }
}
console.log('minX aprox:', minX.toFixed(1));
console.log('maxX aprox:', maxX.toFixed(1));
console.log('viewBox width: 500');
