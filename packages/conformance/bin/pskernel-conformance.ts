#!/usr/bin/env node
import {resolve} from 'node:path';
import {runArenaSuite} from '../src/index.js';
const args=process.argv.slice(2);
if(args[0]!=='arena'||args[1]===undefined){console.error('usage: pskernel-conformance arena <arena-tests-dir> [--include-perf]');process.exit(2);}
const root=resolve(args[1]),includePerf=args.includes('--include-perf');
const result=await runArenaSuite(root,{includePerf,onResult:row=>{if(!row.ok)console.error(`[conformance] ${row.expected}->${row.outcome} ${row.rel}\n${row.detail}`);}});
console.log(JSON.stringify({ok:result.ok,total:result.total,accept:result.accept,reject:result.reject,timeouts:result.timeouts,errors:result.errors,includePerf:result.includePerf,mismatches:result.mismatches},null,2));
if(!result.ok)process.exit(1);
