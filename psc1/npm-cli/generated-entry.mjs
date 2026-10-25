#!/usr/bin/env node
// Explicit command transport; compiler semantics and independent admission remain separate.
import path from 'node:path';import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
if(['generated','kernel'].includes(process.argv[2])){
 try{const command=process.argv[2],module=await import(command==='generated'?'./generated.mjs':'./kernel.mjs');
  await (command==='generated'?module.generatedMain:module.kernelMain)(process.argv.slice(3),root);
 }catch(error){console.error(String(error?.message||error));process.exitCode=1;}
}else{await import('./psc.js');}
