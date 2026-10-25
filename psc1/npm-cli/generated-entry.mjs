#!/usr/bin/env node
// Compiler execution engine, output backend and independent checker are separate.
import fs from 'node:fs';import path from 'node:path';import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const packageMeta=JSON.parse(fs.readFileSync(path.join(root,'package.json'),'utf8'));
try{
 const command=process.argv[2];
 if(command==='generated'){const {generatedMain}=await import('./generated.mjs');await generatedMain(process.argv.slice(3),root);}
 else if(command==='kernel'){const {kernelMain}=await import('./kernel.mjs');await kernelMain(process.argv.slice(3),root);}
 else if(packageMeta.proofscript?.defaultKernel==='wasm'){
  const args=process.argv.slice(2),selected=[],dist=JSON.parse(fs.readFileSync(path.join(root,'KERNEL_DISTRIBUTION.json'),'utf8'));let provider=dist.defaultProvider;
  if(provider!=='wasm')throw Error('PSC1_DEFAULT_KERNEL_POLICY');
  for(let i=0;i<args.length;i++){if(args[i]==='--kernel'){const value=args[++i];if(!['wasm','native','both'].includes(value))throw Error('PSC1_KERNEL_PROVIDER');provider=value;}else selected.push(args[i]);}
  process.env.PSC1_KERNEL_PROVIDER=provider;
  if(selected[0]==='check'){
   const {kernelMain}=await import('./kernel.mjs');await kernelMain(['check-source',...selected.slice(1),'--provider',provider],root);
  }else{process.argv=[...process.argv.slice(0,2),...selected];await import('./psc.js');}
 }else{await import('./psc.js');}
}catch(error){console.error(String(error?.message||error));process.exitCode=1;}
