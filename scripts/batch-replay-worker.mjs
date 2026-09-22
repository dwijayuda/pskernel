import {createInterface} from 'node:readline';
import {Lean4ExportReplay} from '../dist/src/integration/lean4export.js';

const replay=new Lean4ExportReplay();
const rl=createInterface({input:process.stdin,crlfDelay:Infinity});
let maxRssMiB=process.memoryUsage().rss/1048576;
for await(const line of rl){
  if(!line.trim())continue;
  let marker=null;try{marker=JSON.parse(line);}catch{}
  if(marker?.environment||marker?.batch)continue;
  replay.replayLine(line);
  const rss=process.memoryUsage().rss/1048576;
  if(rss>maxRssMiB)maxRssMiB=rss;
}
const stats=replay.finish();
console.log(JSON.stringify({stats,constants:replay.env.entries().length,maxRssMiB:Number(maxRssMiB.toFixed(1))}));
