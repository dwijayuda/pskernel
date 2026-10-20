import { pathToFileURL } from "node:url";
import { performance } from "node:perf_hooks";
import fs from "node:fs";
import path from "node:path";

const filename=process.argv[2];
if (!filename) throw Error("PSKERNEL_HOTPATH_JS_FILE_REQUIRED");
if (typeof global.gc !== "function") throw Error("PSKERNEL_HOTPATH_JS_REQUIRES_EXPOSE_GC");
const kernel=await import(pathToFileURL(path.resolve(filename)).href);
const required=["PsKernelExpr","psKernelExprHash","psKernelExprHasFVar",
  "psKernelExprHasLooseBVar","psKernelExprEq"];
for (const name of required) {
  if (!(name in kernel)) throw Error("PSKERNEL_HOTPATH_MISSING_EXPORT "+name);
}
const Expr=kernel.PsKernelExpr;
const make=depth=>{
  let expr=Expr.bvar(0n);
  for(let i=0;i<depth;i++) expr=Expr.app(expr,Expr.bvar(1n));
  return expr;
};
const samples=[];
const bench=(operation,depth,calls,fn)=>{
  let checksum=0n;
  const begin=performance.now();
  for(let i=0;i<calls;i++){
    const value=fn();
    const v=typeof value==="bigint"?value:(value===true?1n:0n);
    checksum+=v;
  }
  const ms=performance.now()-begin;
  const item={operation,depth,calls,ms:Number(ms.toFixed(3)),
    checksum:String(checksum),rss_bytes:process.memoryUsage().rss};
  samples.push(item);
  console.log("PSC1_HOTPATH_JS "+JSON.stringify(item));
};
for(const depth of [32,128,256]) {
  const expr=make(depth), clone=make(depth);
  const loose=kernel.psKernelExprHasLooseBVar(expr);
  const fvar=kernel.psKernelExprHasFVar(expr);
  const same=kernel.psKernelExprEq(expr,clone);
  console.log("PSC1_HOTPATH_JS_GUARD "+JSON.stringify({depth,loose,fvar,same,
    looseType:typeof loose,fvarType:typeof fvar,sameType:typeof same}));
  if(loose!==true || fvar!==false || same!==true)
    throw Error("PSKERNEL_HOTPATH_SEMANTIC_GUARD "+depth);
  global.gc();
  const calls=120;
  bench("psc_hash",depth,calls,()=>kernel.psKernelExprHash(expr));
  bench("psc_has_fvar",depth,calls,()=>kernel.psKernelExprHasFVar(expr));
  bench("psc_has_bvar",depth,calls,()=>kernel.psKernelExprHasLooseBVar(expr));
  bench("psc_equal",depth,calls,()=>kernel.psKernelExprEq(expr,clone));
}
global.gc();
const summary={source:path.basename(filename),node:process.version,bytes:fs.statSync(filename).size,
  post_gc_heap_bytes:process.memoryUsage().heapUsed,peak_rss_kib:process.resourceUsage().maxRSS,
  operations:samples.length,all_correct:true};
if(samples.length!==12)throw Error("PSKERNEL_HOTPATH_INCOMPLETE");
console.log("PSC1_HOTPATH_JS_SUMMARY "+JSON.stringify(summary));
