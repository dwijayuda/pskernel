#!/usr/bin/env node
import {resolve} from 'node:path';
import {discoverLean,exportLeanToFile} from '../src/index.js';
const args=process.argv.slice(2);
if(args[0]==='version'){console.log(JSON.stringify(discoverLean(),null,2));process.exit(0);}
if(args[0]==='run'){const moduleName=args[1],script=args[2],output=args[3],exportArgs=args.slice(4);if(moduleName===undefined||script===undefined||output===undefined){console.error('usage: proofscript-lean4export run <Lean.Module> <Exporter.lean> <out.ndjson> [exporter args...]');process.exit(2);}const result=await exportLeanToFile({moduleName,script:resolve(script),args:exportArgs},output);console.log(JSON.stringify({ok:true,file:result.file,toolchain:result.toolchain},null,2));process.exit(0);}
console.error('usage: proofscript-lean4export version | run <Lean.Module> <Exporter.lean> <out.ndjson> [exporter args...]');process.exit(2);
