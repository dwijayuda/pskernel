#!/usr/bin/env node
// A pinned host script. Generated wire bytes cannot select a provider or its files.
import path from 'node:path';import {fileURLToPath} from 'node:url';import {createIndependentKernelToolchain} from '../host-tools/kernel-toolchain.mjs';
try{
 let provider='wasm';const args=process.argv.slice(2);for(let i=0;i<args.length;i++){if(args[i]==='--check')continue;if(args[i]==='--provider'&&['native','wasm','both'].includes(args[i+1]))provider=args[++i];else throw Error('PSC1_KERNEL_CHECKER_ARGUMENTS');}
 const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..'),chunks=[];let bytes=0;
 for await(const chunk of process.stdin){bytes+=chunk.length;if(bytes>128*1024*1024)throw Error('PSC1_WASM_CHECKER_INPUT_LIMIT');chunks.push(chunk);}
 const source=new TextDecoder('utf-8',{fatal:true}).decode(Buffer.concat(chunks)),checker=await createIndependentKernelToolchain({root,provider}),result=await checker.checkCanonicalAdmissions(source),selected=provider==='native'?'native':'wasm';
 console.log(JSON.stringify({...result.results[selected],accepted:result.accepted,...(!result.agreement?{errorKind:'provider-disagreement'}:{})}));
}catch(error){console.error(String(error?.message||error));process.exitCode=1;}
