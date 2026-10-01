import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {Lean4ExportReplay} from '../dist/src/integration/lean4export.js';

const here=path.dirname(fileURLToPath(import.meta.url));
const file=path.resolve(here,'../oracle/fixtures/lean434-lean-rbmap-roots.ndjson');
if(!fs.existsSync(file)) throw new Error(`missing Lean RBMap fixture: ${file}`);
const replay=new Lean4ExportReplay();
const stats=replay.replay(fs.readFileSync(file,'utf8'));
const expected={lines:41107,names:5039,levels:38,expressions:35396,declarations:633};
for(const [k,v] of Object.entries(expected)) if(stats[k]!==v) throw new Error(`Lean RBMap fixture drift: ${k}=${stats[k]} expected ${v}`);
if(replay.env.entries().length!==743) throw new Error(`Lean RBMap fixture drift: constants=${replay.env.entries().length} expected 743`);
console.log(JSON.stringify({ok:true,file,stats,constants:replay.env.entries().length},null,2));
