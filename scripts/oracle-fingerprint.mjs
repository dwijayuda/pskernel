import {createHash} from 'node:crypto';
import {existsSync,readFileSync} from 'node:fs';
import {join} from 'node:path';
const manifest=JSON.parse(readFileSync(new URL('../ORACLE_SOURCES.json',import.meta.url),'utf8'));
const roots={lean434:process.env.LEAN434_SOURCE_ROOT??'/mnt/data/work/lean4-4.34.0',lean4lean:process.env.LEAN4LEAN_SOURCE_ROOT??'/mnt/data/work/lean4lean-master'};
let checked=0;
for(const f of manifest.files){const p=join(roots[f.source],f.path);if(!existsSync(p))continue;const got=createHash('sha256').update(readFileSync(p)).digest('hex');if(got!==f.sha256)throw new Error(`oracle source drift: ${f.source}/${f.path}`);checked++;}
console.log(`oracle-fingerprint: PASS (${checked}/${manifest.files.length} source files locally verified)`);
