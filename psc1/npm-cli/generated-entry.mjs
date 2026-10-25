#!/usr/bin/env node
// Explicit package transport selection; compilation semantics remain generated/native.
import path from 'node:path';import {fileURLToPath} from 'node:url';
if(process.argv[2]==='generated'){
 try{const {generatedMain}=await import('./generated.mjs');
  await generatedMain(process.argv.slice(3),path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..'));
 }catch(error){console.error(String(error?.message||error));process.exitCode=1;}
}else{await import('./psc.js');}
