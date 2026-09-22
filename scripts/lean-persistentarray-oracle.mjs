import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {Lean4ExportReplay} from '../dist/src/integration/lean4export.js';

const here=path.dirname(fileURLToPath(import.meta.url));
const file=path.resolve(here,'../oracle/fixtures/lean434-lean-persistentarray-roots.ndjson');
if(!fs.existsSync(file)) throw new Error(`missing Lean PersistentArray fixture: ${file}`);
const replay=new Lean4ExportReplay();
const stats=replay.replay(fs.readFileSync(file,'utf8'));
const expected={lines:85105,names:9448,levels:46,expressions:74170,declarations:1440};
for(const [k,v] of Object.entries(expected)) if(stats[k]!==v) throw new Error(`Lean PersistentArray fixture drift: ${k}=${stats[k]} expected ${v}`);
if(replay.env.entries().length!==1633) throw new Error(`Lean PersistentArray fixture drift: constants=${replay.env.entries().length} expected 1633`);
console.log(JSON.stringify({ok:true,file,stats,constants:replay.env.entries().length},null,2));
