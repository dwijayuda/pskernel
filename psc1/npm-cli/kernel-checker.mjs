#!/usr/bin/env node
// A pinned host script; generated wire data cannot choose this provider or its files.
import path from 'node:path';import {fileURLToPath} from 'node:url';import {createIndependentKernelToolchain} from '../host-tools/kernel-toolchain.mjs';
try{
 const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..'),chunks=[];let bytes=0;
 for await(const chunk of process.stdin){bytes+=chunk.length;if(bytes>128*1024*1024)throw Error('PSC1_WASM_CHECKER_INPUT_LIMIT');chunks.push(chunk);}
 const source=new TextDecoder('utf-8',{fatal:true}).decode(Buffer.concat(chunks)),checker=await createIndependentKernelToolchain({root,provider:'wasm'}),result=await checker.checkCanonicalAdmissions(source);
 console.log(JSON.stringify(result.results.wasm));
}catch(error){console.error(String(error?.message||error));process.exitCode=1;}
