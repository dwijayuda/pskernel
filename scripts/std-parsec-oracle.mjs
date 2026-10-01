import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {Lean4ExportReplay} from '../dist/src/integration/lean4export.js';

const here=path.dirname(fileURLToPath(import.meta.url));
const file=path.resolve(here,'../oracle/fixtures/lean434-std-parsec-roots.ndjson');
if(!fs.existsSync(file)) throw new Error(`missing Std Parsec fixture: ${file}`);
const replay=new Lean4ExportReplay();
const stats=replay.replay(fs.readFileSync(file,'utf8'));
const expected={lines:23239,names:3772,levels:30,expressions:18921,declarations:515};
for(const [k,v] of Object.entries(expected)) if(stats[k]!==v) throw new Error(`Std Parsec fixture drift: ${k}=${stats[k]} expected ${v}`);
if(replay.env.entries().length!==646) throw new Error(`Std Parsec fixture drift: constants=${replay.env.entries().length} expected 646`);
console.log(JSON.stringify({ok:true,file,stats,constants:replay.env.entries().length},null,2));
