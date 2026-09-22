import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {Lean4ExportReplay} from '../dist/src/integration/lean4export.js';

const here=path.dirname(fileURLToPath(import.meta.url));
const file=path.resolve(here,'../oracle/fixtures/lean434-std-byteslice-roots.ndjson');
if(!fs.existsSync(file)) throw new Error(`missing Std ByteSlice fixture: ${file}`);
const replay=new Lean4ExportReplay();
const stats=replay.replay(fs.readFileSync(file,'utf8'));
const expected={lines:90125,names:9531,levels:45,expressions:79106,declarations:1442};
for(const [k,v] of Object.entries(expected)) if(stats[k]!==v) throw new Error(`Std ByteSlice fixture drift: ${k}=${stats[k]} expected ${v}`);
if(replay.env.entries().length!==1630) throw new Error(`Std ByteSlice fixture drift: constants=${replay.env.entries().length} expected 1630`);
console.log(JSON.stringify({ok:true,file,stats,constants:replay.env.entries().length},null,2));
