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
    ["zeta",8,3,"whnf"],["zeta",24,2,"whnf"],["zeta",48,1,"whnf"],
    ...["fn-shared","fn-alpha","fn-unique","fn-collision"].flatMap(shape=>
      [[8,2],[32,1],[128,1]].map(([depth,calls])=>[shape,depth,calls,"whnf"]))
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
      if(sample.calls!==calls||sample.checksum!==calls||sample.all_correct!==true||sample.fuel!==4096)
        throw Error("PSC1_DAG_BENCH_INCOMPLETE");
      observations.push(sample);
      console.log(line);
    }
  }
  console.log("PSC1_DAG_WHOLE_CHECKER_ABBA "+JSON.stringify({
    node:process.version,toolchain:readFileSync("lean-toolchain","utf8").trim(),
    meaning:"complete public checks, checked WHNF and checked DefEq; DAG includes validation and decoding on every batch call",
    scope:"terminal/metadata inference and checked terminal/metadata/beta/zeta/function-position WHNF migration; composite checking uses legacy fallback; batch-check amortizes one validation across eight fresh-context checks",
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
  if(session.resources.fuel!==4096n)throw Error("PSC1_DAG_BENCH_RESOURCE_POLICY_CHANGED");
  const values=[];
  const setupStart=performance.now();
  for(let fixture=0;fixture<5;fixture++){
    const binder=N.str(N.anonymous,"bench-"+fixture);
    const cacheShape=shape.startsWith("fn-");
    const marker=i=>BigInt(fixture*4096)+
      (shape==="fn-unique"?BigInt(i):shape==="fn-collision"?65521n*BigInt(i):0n);
    const headName=i=>N.str(N.anonymous,"cache-"+fixture+"-"+i);
    const binderInfo=i=>shape==="fn-alpha"&&i%2===1?
      k.PsKernelBinderInfo.implicit:k.PsKernelBinderInfo.default;
    if(variant==="legacy"){
      let term=sort0;
      if(cacheShape){
        const type=E.forallE(N.anonymous,sort1,sort1,k.PsKernelBinderInfo.default);
        const head=i=>E.letE(headName(i),type,
          E.mdata(marker(i),E.lam(headName(i),sort1,E.bvar(0n),binderInfo(i))),
          E.bvar(0n),false);
        const shared=shape==="fn-shared"?head(0):null;
        for(let i=0;i<depth;i++)term=E.app(shape==="fn-shared"?shared:head(i),term);
      }else{
        for(let i=0;i<depth;i++){
          term=shape==="metadata"?E.mdata(BigInt(fixture*1000+i),term):
            E.letE(binder,sort1,term,E.bvar(0n),false);
        }
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
      if(cacheShape){
        const add=(kind,...args)=>{
          const inserted=accepted(k["psKernelExprV2PagedMk"+kind](arena,...args),"cache-"+kind);
          arena=inserted.fst;return inserted.snd;
        };
        const type=add("Forall",N.anonymous,s1,s1,k.PsKernelBinderInfo.default);
        const head=i=>{
          const identity=add("Lam",headName(i),s1,b0,binderInfo(i));
          const marked=add("MData",marker(i),identity);
          return add("Let",headName(i),type,marked,b0,false);
        };
        const shared=shape==="fn-shared"?head(0):null;
        for(let i=0;i<depth;i++)root=add("App",shape==="fn-shared"?shared:head(i),root);
      }else{
        for(let i=0;i<depth;i++){
          const next=shape==="metadata"?
            k.psKernelExprV2PagedMkMData(arena,BigInt(fixture*1000+i),root):
            k.psKernelExprV2PagedMkLet(arena,binder,s1,root,b0,false);
          const inserted=accepted(next,"node");
          arena=inserted.fst;root=inserted.snd;
        }
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
  const measuredPeakRss=process.resourceUsage().maxRSS;
  let cacheDiagnostic=null;
  if(variant==="dag"&&shape.startsWith("fn-")){
    const input=values[0];
    const checker=k.psKernelKernelSessionChecker(session,nil,k.PsKernelDefinitionSafety.safe);
    const attempt=k.psKernelExprV2TryWhnfStateWithFuel(session.resources.fuel)
      (checker.context)(k.psKernelExprV2WhnfStateEmpty(input.arena))(input.root);
    if(!attempt||typeof attempt!=="object"||!("value" in attempt))
      throw Error("PSC1_DAG_BENCH_CACHE_PATH_FELL_BACK");
    const reduced=accepted(attempt.value,"cache-diagnostic");
    const state=reduced.fst;
    const built=accepted(k.psKernelExprV2DecodeChecked(state.arena),"cache-diagnostic-arena");
    const output=accepted(k.psKernelExprV2DecodedRequire(built,reduced.snd),"cache-diagnostic-root");
    if(k.psKernelExprEqual(output)(sort0)!==true)
      throw Error("PSC1_DAG_BENCH_CACHE_DIAGNOSTIC_VALUE");
    let entries=state.coreCache,publications=0,shadowed=0,maxBucket=0;
    const buckets=new Map(),sourceIDs=new Set();
    while(entries&&typeof entries==="object"&&"head" in entries){
      const entry=entries.head,key=entry.hash.toString();
      publications++;sourceIDs.add(entry.source.toString());
      const bucket=buckets.get(key)||[];
      let equivalent=false;
      for(const previous of bucket){
        if(accepted(k.psKernelExprV2PagedEqOnCanonical(
            state.arena,previous.source,entry.source),"cache-diagnostic-equality")===true){
          equivalent=true;break;
        }
      }
      if(equivalent)shadowed++;
      bucket.push(entry);buckets.set(key,bucket);
      maxBucket=Math.max(maxBucket,bucket.length);
      entries=entries.tail;
    }
    let publicEntries=state.publicCache,publicCount=0;
    while(publicEntries&&typeof publicEntries==="object"&&"head" in publicEntries){
      publicCount++;publicEntries=publicEntries.tail;
    }
    cacheDiagnostic={
      scope:"one untimed raw DAG operation after public timing and memory snapshot",
      direct_success:true,core_publications:publications,core_cache_high_water_entries:publications,
      public_cache_entries:publicCount,total_cache_entries:publications+publicCount,
      distinct_source_ids:sourceIDs.size,equivalent_shadowed_entries:shadowed,
      hash_buckets:buckets.size,max_hash_bucket_length:maxBucket,
      arena_nodes_before:input.arena.size.toString(),
      arena_nodes_after:state.arena.size.toString(),
      arena_nodes_appended:(state.arena.size-input.arena.size).toString(),
      hit_miss_probe_counters_measured:false
    };
  }

  console.log("PSC1_DAG_SAMPLE "+JSON.stringify({
    variant,shape,depth,calls,operation,batch_size:batchSize,
    checked_public_operations:calls*batchSize,checksum,all_correct:checksum===calls,
    check_ms:Number(ms.toFixed(3)),cold_check_ms:Number(coldMs.toFixed(3)),
    input_construction_ms:Number(setupMs.toFixed(3)),
    peak_rss_kib:measuredPeakRss,cache_diagnostic:cacheDiagnostic,fuel:4096,
    heap_before_bytes:before.heapUsed,heap_after_gc_bytes:after.heapUsed,
    retained_heap_delta_bytes:after.heapUsed-before.heapUsed,
    input_pool:values.length,semantic_cache:"fresh per checked public operation"
  }));
}
