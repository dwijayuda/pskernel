#!/usr/bin/env node
import {createReadStream} from 'node:fs';
import {createInterface} from 'node:readline';
import {Lean4ExportReplay} from 'lean-ts-kernel/lean4export';

const file=process.argv[2];
if(!file){console.error('usage: case-worker <case.ndjson>');process.exit(2);}

try{
  const replay=new Lean4ExportReplay();
  const rl=createInterface({input:createReadStream(file,{encoding:'utf8'}),crlfDelay:Infinity});
  for await(const line of rl)replay.replayLine(line);
  const stats=replay.finish();
  console.log(JSON.stringify({ok:true,file,stats,constants:replay.env.size}));
  process.exit(0);
}catch(error){
  console.error(error instanceof Error?(error.stack??error.message):String(error));
  process.exit(1);
}
