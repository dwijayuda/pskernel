import fs from 'node:fs';
import readline from 'node:readline';
import {Lean4ExportReplay} from '../dist/src/integration/lean4export.js';

const file=process.argv[2];
if(!file){console.error('usage: arena-case-worker <test.ndjson>');process.exit(3);}
let version='4.34.0';
try{
  const fd=fs.openSync(file,'r'),buf=Buffer.alloc(65536);const n=fs.readSync(fd,buf,0,buf.length,0);fs.closeSync(fd);
  const first=buf.subarray(0,n).toString('utf8').split(/\r?\n/,1)[0];
  version=JSON.parse(first)?.meta?.lean?.version??version;
}catch(e){console.error(`arena-case-worker: cannot read metadata: ${e}`);process.exit(3);}
const replay=new Lean4ExportReplay(undefined,{expectedLeanVersion:version});
const rl=readline.createInterface({input:fs.createReadStream(file),crlfDelay:Infinity});
try{
  for await(const line of rl)replay.replayLine(line);
  const stats=replay.finish();
  console.log(JSON.stringify({status:'accept',version,constants:replay.env.size,stats}));
  process.exit(0);
}catch(e){
  console.error(JSON.stringify({status:'reject',version,error:e instanceof Error?(e.stack??e.message):String(e)}));
  process.exit(1);
}
