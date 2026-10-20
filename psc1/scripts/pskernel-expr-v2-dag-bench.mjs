import { pathToFileURL, fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { performance } from "node:perf_hooks";
import { readFileSync } from "node:fs";
import path from "node:path";

const [filename,mode,variant,shape,depthArg,callsArg,operationArg]=process.argv.slice(2);
if(!filename)throw Error("PSC1_DAG_BENCH_REQUIRES_GENERATED_KERNEL");
const absolute=path.resolve(filename);

if(mode!=="worker"){
  const observations=[];
  for(const [shape,depth,calls,operation] of [
    ["metadata",32,6,"check"],["metadata",96,4,"check"],["metadata",192,2,"check"],
    ["zeta",8,3,"check"],["zeta",24,2,"check"],["zeta",48,1,"check"],
    ["metadata",96,4,"whnf"],["metadata",96,4,"defeq"],["metadata",96,2,"batch-check"],
    ["zeta",8,3,"whnf"],["zeta",24,2,"whnf"],["zeta",48,1,"whnf"]
  ]){
    for(const variant of ["legacy","dag","dag","legacy"]){
      const result=spawnSync(process.execPath,
        ["--expose-gc",fileURLToPath(import.meta.url),absolute,"worker",
          variant,shape,String(depth),String(calls),operation],
        {encoding:"utf8",timeout:180000,maxBuffer:16*1024*1024});
      if(result.status!==0)throw Error("PSC1_DAG_BENCH_WORKER_FAILED "+
        [variant,shape,depth,result.stderr,result.stdout].join(" "));
      const line=result.stdout.split("\n").find(s=>s.startsWith("PSC1_DAG_SAMPLE "));
      if(!line)throw Error("PSC1_DAG_BENCH_SAMPLE_MISSING");
      const sample=JSON.parse(line.slice("PSC1_DAG_SAMPLE ".length));
      if(sample.calls!==calls||sample.checksum!==calls||sample.all_correct!==true)
        throw Error("PSC1_DAG_BENCH_INCOMPLETE");
      observations.push(sample);
      console.log(line);
    }
  }
  console.log("PSC1_DAG_WHOLE_CHECKER_ABBA "+JSON.stringify({
    node:process.version,toolchain:readFileSync("lean-toolchain","utf8").trim(),
    meaning:"complete public checks, checked WHNF and checked DefEq; DAG includes validation and decoding on every batch call",
    scope:"terminal/metadata inference and terminal/metadata/zeta WHNF migration; zeta checking uses legacy fallback; batch-check amortizes one validation across eight fresh-context checks",
    limitations:"finite fixtures; no general speedup or allocation-counter claim",
    observations
  }));
  console.log("PSC1_V2_DAG_BENCH: PASS");
}else{
  if(typeof global.gc!=="function")throw Error("PSC1_DAG_BENCH_REQUIRES_GC");
  const k=await import(pathToFileURL(absolute).href);
  const L=k.PsKernelLevel,N=k.PsKernelName,E=k.PsKernelExpr;
  const nil=typeof k.List.nil==="function"?k.List.nil():k.List.nil;
  const accepted=(r,label)=>{
    if(r&&typeof r==="object"&&"value" in r)return r.value;
    throw Error("PSC1_DAG_BENCH_REJECTED "+label);
  };
  const depth=Number(depthArg),calls=Number(callsArg),operation=operationArg||"check";
  const batchSize=operation==="batch-check"?8:1;
  const sort0=E.sort(L.zero),sort1=E.sort(L.succ(L.zero));
  if(k.psKernelExprEq(sort0)(sort0)!==true||k.psKernelExprEq(sort0)(sort1)!==false)
    throw Error("PSC1_DAG_BENCH_EQUALITY_HARNESS_INVALID");
  const session=accepted(k.psKernelKernelSessionEmpty(
    k.psKernelResourcePolicyDefault,k.psKernelProviderDefault),"session");
  const values=[];
  const setupStart=performance.now();
  for(let fixture=0;fixture<5;fixture++){
    const binder=N.str(N.anonymous,"bench-"+fixture);
    if(variant==="legacy"){
      let term=sort0;
      for(let i=0;i<depth;i++){
        term=shape==="metadata"?E.mdata(BigInt(fixture*1000+i),term):
          E.letE(binder,sort1,term,E.bvar(0n),false);
      }
      values.push(term);
    }else{
      let a=accepted(k.psKernelExprV2PagedMkSort(k.psKernelExprV2PagedEmpty,L.zero),"s0");
      const s0=a.snd;
      a=accepted(k.psKernelExprV2PagedMkSort(a.fst,L.succ(L.zero)),"s1");
      const s1=a.snd;
      a=accepted(k.psKernelExprV2PagedMkBVar(a.fst,0n),"b0");
      const b0=a.snd;
      let root=s0,arena=a.fst;
      for(let i=0;i<depth;i++){
        const next=shape==="metadata"?
          k.psKernelExprV2PagedMkMData(arena,BigInt(fixture*1000+i),root):
          k.psKernelExprV2PagedMkLet(arena,binder,s1,root,b0,false);
        const inserted=accepted(next,"node");
        arena=inserted.fst;root=inserted.snd;
      }
      const command=operation==="whnf"?k.PsKernelDagCommand.whnf(root):
        operation==="defeq"?k.PsKernelDagCommand.isDefEq(root,root):
        k.PsKernelDagCommand.check(root);
      let commands=nil;
      for(let i=0;i<batchSize;i++)commands=k.List.cons(command,commands);
      values.push({arena,root,commands});
    }
  }
  const setupMs=performance.now()-setupStart;
  const validate=value=>{
    if(operation==="whnf"){
      if(k.psKernelExprEq(value)(sort0)!==true)
        throw Error("PSC1_DAG_BENCH_WRONG_WHNF");
    }else if(operation==="defeq"){
      if(value!==true)throw Error("PSC1_DAG_BENCH_WRONG_DEFEQ");
    }else if(k.psKernelExprEq(value.type)(sort1)!==true){
      throw Error("PSC1_DAG_BENCH_WRONG_CHECKED_TYPE");
    }
  };
  const perform=i=>{
    const value=values[i%values.length];
    if(variant==="legacy"){
      for(let n=0;n<batchSize;n++){
        const result=operation==="whnf"?
          k.psKernelV1Whnf(session,nil,k.PsKernelDefinitionSafety.safe,value):
          operation==="defeq"?
            k.psKernelV1IsDefEq(session,nil,k.PsKernelDefinitionSafety.safe,value,value):
            k.psKernelV1CheckExpression(session,nil,k.PsKernelDefinitionSafety.safe,value);
        validate(accepted(result,"legacy-"+operation));
      }
    }else{
      const output=accepted(k.psKernelV1RunDag(
        session,nil,k.PsKernelDefinitionSafety.safe,value.arena,value.commands),"dag-"+operation);
      let replies=output.replies,count=0;
      while(replies&&typeof replies==="object"&&"head" in replies){
        validate(replies.head.value);count++;replies=replies.tail;
      }
      if(count!==batchSize)throw Error("PSC1_DAG_BENCH_REPLY_COUNT");
    }
    return 1;
  };
  const coldStart=performance.now();
  perform(0);
  const coldMs=performance.now()-coldStart;
  for(let i=0;i<values.length;i++)perform(i);
  global.gc();
  const before=process.memoryUsage();
  let checksum=0;
  const start=performance.now();
  for(let i=0;i<calls;i++)checksum+=perform(i);
  const ms=performance.now()-start;
  global.gc();
  const after=process.memoryUsage();
  console.log("PSC1_DAG_SAMPLE "+JSON.stringify({
    variant,shape,depth,calls,operation,batch_size:batchSize,
    checked_public_operations:calls*batchSize,checksum,all_correct:checksum===calls,
    check_ms:Number(ms.toFixed(3)),cold_check_ms:Number(coldMs.toFixed(3)),
    input_construction_ms:Number(setupMs.toFixed(3)),
    peak_rss_kib:process.resourceUsage().maxRSS,
    heap_before_bytes:before.heapUsed,heap_after_gc_bytes:after.heapUsed,
    retained_heap_delta_bytes:after.heapUsed-before.heapUsed,
    input_pool:values.length,semantic_cache:"fresh per checked public operation"
  }));
}
