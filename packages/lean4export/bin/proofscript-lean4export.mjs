#!/usr/bin/env node
import {resolve} from 'node:path';
import {discoverLean,exportLeanToFile} from '../src/index.mjs';

const args=process.argv.slice(2);
if(args[0]==='version'){
  const info=discoverLean();
  console.log(JSON.stringify(info,null,2));
  process.exit(0);
}
if(args[0]==='run'){
  const [,_run,moduleName,script,output,...exportArgs]=args;
  if(!moduleName||!script||!output){
    console.error('usage: proofscript-lean4export run <Lean.Module> <Exporter.lean> <out.ndjson> [exporter args...]');
    process.exit(2);
  }
  const result=await exportLeanToFile({
    moduleName,
    script:resolve(script),
    args:exportArgs
  },output);
  console.log(JSON.stringify({ok:true,file:result.file,toolchain:result.toolchain},null,2));
  process.exit(0);
}
console.error('usage: proofscript-lean4export version | run <Lean.Module> <Exporter.lean> <out.ndjson> [exporter args...]');
process.exit(2);
