import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import {fileURLToPath} from 'node:url';
import {Lean4ExportReplay} from '../dist/src/integration/lean4export.js';

const here=path.dirname(fileURLToPath(import.meta.url));
const file=path.resolve(here,'../oracle/fixtures/lean434-lean-rbmap-all.ndjson.gz');
if(!fs.existsSync(file)) throw new Error(`missing full Lean RBMap fixture: ${file}`);

const replay=new Lean4ExportReplay();
const input=fs.createReadStream(file).pipe(zlib.createGunzip());
input.setEncoding('utf8');
let carry='';
for await (const chunk of input){
  carry+=chunk;
  let start=0;
  for(;;){
    const end=carry.indexOf('\n',start);
    if(end<0)break;
    replay.replayLine(carry.slice(start,end));
    start=end+1;
  }
  carry=carry.slice(start);
}
if(carry.length!==0) replay.replayLine(carry);
const stats=replay.finish();
const expected={lines:463440,names:61310,levels:283,expressions:391273,declarations:10573};
for(const [k,v] of Object.entries(expected)) if(stats[k]!==v) throw new Error(`full Lean RBMap fixture drift: ${k}=${stats[k]} expected ${v}`);
if(replay.env.entries().length!==11223) throw new Error(`full Lean RBMap fixture drift: constants=${replay.env.entries().length} expected 11223`);
console.log(JSON.stringify({ok:true,file,stats,constants:replay.env.entries().length},null,2));
