#!/usr/bin/env node
import {createReadStream} from 'node:fs';
import {createInterface} from 'node:readline';
import {resolve} from 'node:path';
import {Lean4ExportReplay} from 'lean-ts-kernel/lean4export';

function usage(code=0){
  const out=code===0?console.log:console.error;
  out(`usage:
  pskernel replay <lean4export.ndjson>
  pskernel check <lean4export.ndjson>
  pskernel --help`);
  process.exit(code);
}

async function replayFile(file){
  const path=resolve(file);
  const replay=new Lean4ExportReplay();
  const rl=createInterface({
    input:createReadStream(path,{encoding:'utf8'}),
    crlfDelay:Infinity
  });
  for await(const line of rl) replay.replayLine(line);
  const stats=replay.finish();
  return {ok:true,file:path,stats,constants:replay.env.size};
}

const [cmd,file,...rest]=process.argv.slice(2);
if(cmd===undefined||cmd==='--help'||cmd==='-h')usage(0);
if(rest.length!==0||!file||!(cmd==='replay'||cmd==='check'))usage(2);

try{
  const result=await replayFile(file);
  console.log(JSON.stringify(result,null,2));
}catch(error){
  console.error(JSON.stringify({
    ok:false,
    file:file?resolve(file):undefined,
    error:error instanceof Error?(error.stack??error.message):String(error)
  },null,2));
  process.exit(1);
}
