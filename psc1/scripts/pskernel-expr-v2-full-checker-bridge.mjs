import { pathToFileURL } from "node:url";
import { performance } from "node:perf_hooks";
import path from "node:path";
import fs from "node:fs";

const input = process.argv[2];
if (!input) throw Error("PSC1_V2_JS_BRIDGE_REQUIRES_GENERATED_MODULE");
if (typeof global.gc !== "function")
  throw Error("PSC1_V2_JS_BRIDGE_REQUIRES_EXPOSE_GC");
const lib = await import(pathToFileURL(path.resolve(input)).href);
const requireExport = name => {
  if (!(name in lib)) throw Error("PSC1_V2_JS_BRIDGE_MISSING_EXPORT " + name);
  return lib[name];
};
const must = (condition,label) => {
  if (!condition) throw Error("PSC1_V2_JS_BRIDGE_FAILED " + label);
  console.log("PSC1_V2_JS_BRIDGE_PASS " + label);
};
const accepted = (result,label) => {
  if (result && typeof result==="object" && "value" in result)
    return result.value;
  throw Error("PSC1_V2_JS_BRIDGE_UNEXPECTED_REJECTION " + label +
    " " + String(result?.error));
};
const failed = value => value && typeof value==="object" && "error" in value;

must(requireExport("psKernelExprV2CheckerBridgeRoot")===true,"combined-root");
const levels=requireExport("PsKernelLevel");
const names=requireExport("PsKernelName");
const expr=requireExport("PsKernelExpr");
const safety=requireExport("PsKernelDefinitionSafety");
const list=requireExport("List");
const nil=typeof list.nil==="function"?list.nil():list.nil;
const sort0=expr.sort(levels.zero);
const sort1=expr.sort(levels.succ(levels.zero));
const eq=requireExport("psKernelExprEq");
const env=requireExport("psKernelEnvironmentEmpty");
const maxNat=requireExport("psKernelLeanNatMaxSizeDefault");
const session=requireExport("psKernelMkCheckerSession")(
  env,nil,safety.safe,4096n,maxNat);
const check=requireExport("psKernelSessionCheck");
const whnf=requireExport("psKernelSessionWhnf");
const defeq=requireExport("psKernelSessionIsDefEq");
const importPaged=requireExport("psKernelExprV2PagedImportChecked");
const headPaged=requireExport("psKernelExprV2PagedHeadMachineChecked");
const mkPagedSort=requireExport("psKernelExprV2PagedMkSort");
const eqPaged=requireExport("psKernelExprV2PagedEqChecked");
const findPaged=requireExport("psKernelExprV2PagedFind");
const chooseName=index=>names.str(names.anonymous,"bridge-"+index);
const makeZeta=(depth,nameIndex)=>{
  let term=sort0;
  const binderName=chooseName(nameIndex);
  for(let i=0;i<depth;i++){
    term=expr.letE(binderName,sort1,term,expr.bvar(0n),false);
  }
  return term;
};
function trustedWhnf(term){
  const checked=accepted(whnf(4096n,session,term),"trusted-whnf");
  if(!eq(checked.fst,sort0))throw Error("PSC1_V2_JS_BRIDGE_TRUSTED_WHNF_MISMATCH");
}
function trustedCheck(term){
  const checked=accepted(check(4096n,session,term),"trusted-check");
  if(!eq(checked.fst,sort1))throw Error("PSC1_V2_JS_BRIDGE_TRUSTED_TYPE_MISMATCH");
}
function trustedDefEq(term){
  const checked=accepted(defeq(4096n,session,term,sort0),"trusted-defeq");
  if(checked.fst!==true)throw Error("PSC1_V2_JS_BRIDGE_TRUSTED_DEFEQ_MISMATCH");
}
function v2Head(term,depth,includeImport=true,alreadyImported=null){
  const initial=includeImport?
    accepted(importPaged(term),"v2-import"):alreadyImported;
  const result=accepted(headPaged(BigInt(depth+1),
    initial.fst,initial.snd),"v2-restricted-head");
  const withSort=accepted(mkPagedSort(result.fst,levels.zero),"v2-new-sort");
  const isSort=accepted(eqPaged(withSort.fst,result.snd,withSort.snd),
    "v2-output-structural-equality");
  if(isSort!==true)throw Error("PSC1_V2_JS_BRIDGE_V2_NOT_EQ_SORT");
}
for(const depth of [1,8,24,48]){
  const term=makeZeta(depth,depth);
  trustedCheck(term);
  trustedWhnf(term);
  trustedDefEq(term);
  v2Head(term,depth);
  must(failed(headPaged(BigInt(depth),
    accepted(importPaged(term),"v2-import-for-fuel").fst,
    accepted(importPaged(term),"v2-import-for-fuel-2").snd)),
    "restricted-step-fuel-"+depth);
  console.log("PSC1_V2_JS_BRIDGE_VERDICT depth="+depth+" all_correct=true");
}
const malformed=expr.app(sort0,sort0);
must(failed(check(4096n,session,malformed)),
  "production-checker-rejects-illtyped-application");
const neutralImport=accepted(importPaged(malformed),"neutral-v2-import");
const neutralHead=accepted(
  headPaged(1n,neutralImport.fst,neutralImport.snd),"neutral-v2-step");
must(neutralHead.snd===neutralImport.snd,
  "restricted-v2-neutral-is-not-typechecking");

const observations=[];
function time(label,depth,calls,fn){
  let success=0;
  const start=performance.now();
  for(let i=0;i<calls;i++){
    fn(i);
    success++;
  }
  const ms=performance.now()-start;
  if(success!==calls)throw Error("PSC1_V2_JS_BRIDGE_MISSING_CHECK");
  if(typeof global.gc==="function")global.gc();
  observations.push({
    label,depth,calls,ms:Number(ms.toFixed(3)),all_correct:true,
    heap_after_gc:process.memoryUsage().heapUsed
  });
}
for(const [depth,calls] of [[8,4],[24,3],[48,2]]){
  const terms=Array.from({length:5},(_,i)=>makeZeta(depth,i+11));
  const imported=terms.map(t=>accepted(importPaged(t),"preimported"));
  const original=i=>terms[i%terms.length];
  const prebuilt=i=>imported[i%imported.length];
  // Same semantically equivalent fixtures selected by the runtime loop index.
  const full=i=>trustedWhnf(original(i));
  const converted=i=>v2Head(original(i),depth);
  const preimported=i=>v2Head(null,depth,false,prebuilt(i));
  time("trusted-whnf",depth,calls,full);
  time("v2-import-head-equality",depth,calls,converted);
  time("v2-import-head-equality",depth,calls,converted);
  time("trusted-whnf",depth,calls,full);
  time("v2-head-on-preimported",depth,calls,preimported);
  time("trusted-check-type",depth,calls,i=>trustedCheck(original(i)));
  time("trusted-defeq",depth,calls,i=>trustedDefEq(original(i)));
}
console.log("PSC1_V2_JS_CHECKER_BRIDGE_TIMINGS "+JSON.stringify(observations));
console.log("PSC1_V2_JS_CHECKER_BRIDGE_SUMMARY "+JSON.stringify({
  node:process.version,
  source_bytes:fs.statSync(input).size,
  peak_rss_kib:process.resourceUsage().maxRSS,
  post_gc_heap_bytes:process.memoryUsage().heapUsed,
  operation_samples:observations.length,
  all_correct:true
}));
console.log("PSC1_V2_JS_FULL_CHECKER_BRIDGE: PASS");
