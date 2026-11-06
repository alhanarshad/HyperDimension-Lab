/** Local development server. Made by Alhan. No external packages needed. */
import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { resolve, extname, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
const root = resolve(fileURLToPath(new URL('.', import.meta.url)));
const port = Number(process.env.PORT) || 4173;
const type = { '.html':'text/html', '.js':'text/javascript', '.css':'text/css', '.svg':'image/svg+xml', '.json':'application/json', '.txt':'text/plain' };
const server = createServer(async (req, res) => {
  let pathname;
  try { pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname); }
  catch { res.writeHead(400); res.end('Invalid address'); return; }
  const target = resolve(root, '.' + pathname);
  if (target !== root && !target.startsWith(root + sep)) { res.writeHead(403); res.end('Forbidden'); return; }
  try {
    const pathnameFile = (await stat(target)).isDirectory() ? resolve(target, 'index.html') : target;
    const data = await readFile(pathnameFile);
    res.writeHead(200, { 'Content-Type': (type[extname(pathnameFile)] || 'application/octet-stream') + '; charset=utf-8', 'X-Content-Type-Options': 'nosniff' });
    res.end(data);
  } catch { res.writeHead(404); res.end('Not found'); }
});
server.listen(port, () => console.log(`HyperDimension Lab running at http://localhost:${port}`));
