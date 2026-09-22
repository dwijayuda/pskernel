import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {Lean4ExportReplay} from '../dist/src/integration/lean4export.js';

const here=path.dirname(fileURLToPath(import.meta.url));
const file=path.resolve(here,'../oracle/fixtures/lean434-std-sat-cnf-roots.ndjson');
if(!fs.existsSync(file)) throw new Error(`missing Std Sat CNF fixture: ${file}`);
const replay=new Lean4ExportReplay();
const stats=replay.replay(fs.readFileSync(file,'utf8'));
const expected={lines:11338,names:1850,levels:29,expressions:9183,declarations:275};
for(const [k,v] of Object.entries(expected)) if(stats[k]!==v) throw new Error(`Std Sat CNF fixture drift: ${k}=${stats[k]} expected ${v}`);
if(replay.env.entries().length!==366) throw new Error(`Std Sat CNF fixture drift: constants=${replay.env.entries().length} expected 366`);
console.log(JSON.stringify({ok:true,file,stats,constants:replay.env.entries().length},null,2));
