import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';
const root = new URL('..', import.meta.url).pathname;
const lock = JSON.parse(readFileSync(join(root, 'ORACLE_LOCK.json'), 'utf8'));
if (lock.lean !== '4.34.0') throw new Error('Oracle drift: Lean target changed');
if (lock.lean4export?.commit !== '076e8e57707e813375e8f9da8bf989799ace9680') throw new Error('Oracle drift: lean4export pin changed');
if (lock.lean4export?.format !== '3.1.0') throw new Error('Oracle drift: lean4export format changed');
if (lock.lean4export?.toolchain !== 'leanprover/lean4:v4.34.0') throw new Error('Oracle drift: lean4export toolchain changed');
const forbidden = [/lean\s*4\.3[0-3]/i, /equivmanager/i];
function walk(p) { for (const n of readdirSync(p)) { const q=join(p,n); const s=statSync(q); if(s.isDirectory()) walk(q); else if(q.endsWith('.ts')) { const t=readFileSync(q,'utf8'); for(const r of forbidden) if(r.test(t)) throw new Error(`Anti-drift violation ${r} in ${q}`); } } }
walk(join(root,'src'));
console.log('anti-drift: PASS (Lean 4.34.0 pinned)');
