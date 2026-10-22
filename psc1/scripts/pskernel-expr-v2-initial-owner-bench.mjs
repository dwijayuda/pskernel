import {pathToFileURL} from "node:url";
import path from "node:path";
import os from "node:os";
import fs from "node:fs";
import crypto from "node:crypto";
import {spawnSync} from "node:child_process";
import {performance} from "node:perf_hooks";

/*
Complete public-batch comparison for the initial-session owner bridge.
The workflow must authenticate both artifacts and their full runtime dependency
closures before calling this driver. This script records the exact module bytes
again. Both sides execute their own genuine psKernelV1RunDag; it never bypasses
the initial importer or substitutes a synthetic pre-change implementation.

Each independent process creates an actual checked first batch of 32 or 128
declarations, then a fresh second input graph. Timed calls include the complete
public preflight, arena validation/decoding, initial metadata import where
present, checking/admission, and reply construction. Module load, first checked
batch construction and second graph construction are reported separately.
Every measured result is validated after stopping its timer against a genuine
V1 public operation and the stated positive or negative expectation.

All kernel policies remain the artifact's published defaults, including 4096
fuel. Host workers use a 60-second wall deadline and V8 old-space 2048MiB;
this benchmark does not claim an RSS limit. It is a small paired regression
measurement, not whole-kernel speedup, Arena qualification or a soundness proof.
*/
const digest=bytes=>crypto.createHash("sha256").update(bytes).digest("hex");
const json=value=>JSON.stringify(value,(_,x)=>typeof x==="bigint"?x.toString():x);
const insist=(condition,label)=>{if(condition!==true)throw Error("INITIAL_OWNER_BENCH "+label);};
const unit=x=>typeof x==="function"?x():x;
const same=(a,b)=>{
 if(a===b)return true;
 if(a===null||b===null||typeof a!=="object"||typeof b!=="object")return false;
 const keys=Reflect.ownKeys(a),other=Reflect.ownKeys(b);
 return keys.length===other.length&&keys.every(key=>Object.hasOwn(b,key)&&same(a[key],b[key]));
};
const ok=(value,label)=>{
 if(value&&typeof value==="object"&&Object.hasOwn(value,"value"))return value.value;
 throw Error("INITIAL_OWNER_BENCH "+label+": "+json(value));
};
const isError=value=>Boolean(value&&typeof value==="object"&&Object.hasOwn(value,"error"));
const memory=()=>({rssBytes:process.memoryUsage().rss,heapUsedBytes:process.memoryUsage().heapUsed,
 externalBytes:process.memoryUsage().external,processPeakRssKiB:process.resourceUsage().maxRSS});
const collect=()=>{global.gc();global.gc();return memory();};

async function worker(spec){
 insist(process.env.PATH==="","detached PATH must be empty");
 insist(process.version.startsWith("v22."),"Node22 required");
 insist(typeof global.gc==="function","explicit GC required for retained-memory receipts");
 insist([32,128].includes(spec.owners),"owner-count control");
 insist(["trivial-sort","owned-constant","unknown-constant","ill-typed-definition"].includes(spec.query),
  "query control");
 const bytes=fs.readFileSync(spec.kernel);
 const loadStart=performance.now(),loadCpu=process.cpuUsage();
 const k=await import(pathToFileURL(spec.kernel).href);
 const moduleLoad={wallMs:performance.now()-loadStart,cpu:process.cpuUsage(loadCpu)};
 const get=name=>{insist(name in k,"missing export "+name);return k[name];};
 const List=get("List"),nil=unit(List.nil),N=get("PsKernelName"),E=get("PsKernelExpr");
 const L=get("PsKernelLevel"),C=get("PsKernelDagCommand"),D=get("PsKernelDagDeclarationRequest");
 const Request=get("PsKernelDeclarationRequest"),Reply=get("PsKernelDagReply"),ErrorTag=get("PsKernelError");
 const safe=unit(get("PsKernelDefinitionSafety").safe);
 const hint=unit(get("PsKernelReducibilityHints").abbrevHint);
 const list=values=>values.reduceRight((tail,head)=>List.cons(head,tail),nil);
 const array=values=>{const out=[];while(values&&Object.hasOwn(values,"head")){
  out.push(values.head);values=values.tail;}return out;};
 const nm=text=>N.str(unit(N.anonymous),text),zero=unit(L.zero),one=L.succ(zero);
 const sort0=E.sort(zero),sort1=E.sort(one),cn=name=>E.const(name,nil);
 const exact=(left,right)=>get("psKernelExprEqual")(left)(right);
 const rawError=(result,text)=>isError(result)&&same(result.error,ErrorTag.rejectedInvalid(text));
 const initial=ok(get("psKernelKernelSessionEmpty")(
  get("psKernelResourcePolicyDefault"),get("psKernelProviderDefault")),"empty session");
 insist(initial.resources.fuel===4096n,"published fuel unchanged");
 const emptySource=()=>({arena:get("psKernelExprV2PagedEmpty"),
  built:get("psKernelExprV2DecodedEmpty"),declarations:nil});
 let source=emptySource();
 const add=term=>{const imported=ok(get("psKernelDagGeneratedImport")(term,source),"input construction");
  source=imported.fst;return imported.snd;};
 const buildStart=performance.now(),buildCpu=process.cpuUsage(),setupBefore=collect();
 const commands=[],names=[];
 const typeId=add(sort1),bodyId=add(sort0);
 for(let i=0;i<spec.owners;i++){
  const name=N.num(nm("InitialOwnerBench"),BigInt(i));names.push(name);
  const base={name,levelParams:nil,type:typeId};
  commands.push(C.admit(i%2===0?D.axiomDecl(base,false):
   D.definitionDecl({base,value:bodyId,hints:hint,safety:safe})));
 }
 const first=ok(get("psKernelV1RunDag")(initial,nil,safe,source.arena,list(commands)),"checked first batch");
 const session=first.session;
 insist(array(first.replies).length===spec.owners,"complete first admission batch");
 insist(get("psKernelEnvironmentSize")(session.environment)===BigInt(spec.owners),"checked owner count");
 insist(session.resources.fuel===4096n,"first batch preserved fuel");
 const firstBatch={wallMs:performance.now()-buildStart,cpu:process.cpuUsage(buildCpu),
  inputNodes:source.arena.size,declaredOwners:spec.owners,definitions:spec.owners/2,
  memoryBefore:setupBefore,memoryAfter:collect()};
 const graphStart=performance.now(),graphCpu=process.cpuUsage();
 source=emptySource();
 const unknownName=nm("InitialOwnerBenchMissing"),badName=nm("InitialOwnerBenchInvalid");
 let expression,command,referenceRequest=null;
 if(spec.query==="trivial-sort"){
  expression=sort0;command=C.check(add(expression));
 }else if(spec.query==="owned-constant"){
  expression=cn(names[names.length-1]);command=C.check(add(expression));
 }else if(spec.query==="unknown-constant"){
  expression=cn(unknownName);command=C.check(add(expression));
 }else{
  const root=add(sort0);
  command=C.admit(D.definitionDecl({
   base:{name:badName,levelParams:nil,type:root},value:root,hints:hint,safety:safe}));
  referenceRequest=Request.definitionDecl({
   base:{name:badName,levelParams:nil,type:sort0},value:sort0,hints:hint,safety:safe});
 }
 const graph=source.arena,commandList=list([command]);
 const inputConstruction={wallMs:performance.now()-graphStart,cpu:process.cpuUsage(graphCpu),
  inputNodes:graph.size,memoryAfter:collect()};
 // A complete original V1 public operation is an independent outcome control.
 // It is outside all measured DAG calls and publishes no owner into them.
 const reference=referenceRequest===null?
  get("psKernelV1CheckExpression")(session,nil,safe,expression):
  get("psKernelV1AdmitDeclaration")(session,referenceRequest);
 const expectedError=spec.query==="unknown-constant"?"unknown constant":
  spec.query==="ill-typed-definition"?"definition type mismatch":null;
 if(expectedError!==null)insist(rawError(reference,expectedError),"reference exact negative outcome");
 else{
  const checked=ok(reference,"reference positive");
  insist(exact(checked.expression,expression)&&exact(checked.type,sort1),"reference exact positive type");
 }
 const validate=result=>{
  if(expectedError!==null)insist(rawError(result,expectedError),"DAG exact negative outcome");
  else{
   const batch=ok(result,"DAG positive"),rows=array(batch.replies),checked=ok(reference,"reference");
   insist(rows.length===1&&same(rows[0],Reply.checked(rows[0].value)),"DAG single checked reply");
   insist(exact(rows[0].value.expression,checked.expression)&&exact(rows[0].value.type,checked.type),
    "DAG exact public checked result");
   insist(get("psKernelEnvironmentSize")(batch.session.environment)===BigInt(spec.owners),
    "query did not publish declarations");
  }
  insist(get("psKernelEnvironmentSize")(session.environment)===BigInt(spec.owners)&&
   !get("psKernelEnvironmentContains")(session.environment,badName),
   "caller session and failed admission remain atomic");
 };
 const execute=()=>get("psKernelV1RunDag")(session,nil,safe,graph,commandList);
 const beforeCalls=collect();
 let validated=0;
 const measure=()=>{
  const start=performance.now(),cpu=process.cpuUsage();
  const result=execute();
  const wallMs=performance.now()-start,cpuUsed=process.cpuUsage(cpu),after=memory();
  validate(result);validated++;
  return {wallMs,cpuUserUs:cpuUsed.user,cpuSystemUs:cpuUsed.system,...after};
 };
 const cold=measure();
 const warmup=[];
 for(let i=0;i<2;i++)warmup.push(measure());
 const warm=[];
 for(let i=0;i<9;i++)warm.push(measure());
 const retained=collect();
 insist(validated===12,"every complete call validated");
 return {label:spec.label,sourceSha:spec.sourceSha,owners:spec.owners,query:spec.query,
  kernelSha256:digest(bytes),node:process.version,moduleLoad,firstBatch,inputConstruction,
  originalV1Control:expectedError===null?"accepted":"rejectedInvalid:"+expectedError,
  cold,warmup,warm,validated,beforeCalls,retained,
  retainedHeapDeltaBytes:retained.heapUsedBytes-beforeCalls.heapUsedBytes,
  processPeakRssKiB:process.resourceUsage().maxRSS,
  kernelFuel:session.resources.fuel,hostWallDeadlineSeconds:60,v8OldSpaceMiB:2048,
  hardRssLimitClaim:false};
}

if(process.argv[2]==="--worker"){
 try{
  const result=await worker(JSON.parse(process.argv[3]));
  process.stdout.write("PSC1_INITIAL_OWNER_BENCH_WORKER "+json(result)+"\n");
 }catch(error){process.stderr.write(String(error?.stack??error)+"\n");process.exitCode=1;}
}else{
 const [candidateArg,baselineArg,outputArg,candidateSha,baselineSha]=process.argv.slice(2);
 insist(Boolean(candidateArg&&baselineArg&&outputArg),"usage: candidate.js baseline.js outputDir candidateSHA baselineSHA");
 insist(/^[0-9a-f]{40}$/.test(candidateSha??"")&&/^[0-9a-f]{40}$/.test(baselineSha??""),
  "exact source SHAs required");
 insist(candidateSha!==baselineSha,"comparison requires distinct actual source revisions");
 const candidate=path.resolve(candidateArg),baseline=path.resolve(baselineArg),output=path.resolve(outputArg);
 insist(fs.statSync(candidate).isFile()&&fs.statSync(baseline).isFile(),"both actual generated artifacts required");
 fs.mkdirSync(output,{recursive:true});
 const temporary=fs.mkdtempSync(path.join(os.tmpdir(),"psc1-initial-owner-bench-"));
 const workers=[],failures=[];
 const expectedDigests={baseline:digest(fs.readFileSync(baseline)),candidate:digest(fs.readFileSync(candidate))};
 try{
  for(const owners of [32,128])for(const query of [
   "trivial-sort","owned-constant","unknown-constant","ill-typed-definition"]){
   for(const [position,label] of ["baseline","candidate","candidate","baseline"].entries()){
    const spec={label,owners,query,sourceSha:label==="baseline"?baselineSha:candidateSha,
     kernel:label==="baseline"?baseline:candidate};
    const result=spawnSync(process.execPath,["--expose-gc","--max-old-space-size=2048",
     path.resolve(process.argv[1]),"--worker",json(spec)],{
      cwd:temporary,env:{PATH:""},encoding:"utf8",timeout:60000,maxBuffer:8*1024*1024});
    const stem=owners+"-"+query+"-"+position+"-"+label;
    fs.writeFileSync(path.join(output,stem+".stdout.log"),result.stdout??"");
    fs.writeFileSync(path.join(output,stem+".stderr.log"),result.stderr??"");
    if(result.error||result.status!==0||result.signal){
     failures.push({owners,query,position,label,status:result.status,signal:result.signal,
      hostError:result.error?.code??null});
     continue;
    }
    const lines=(result.stdout??"").trimEnd().split("\n");
    const records=lines.filter(line=>line.startsWith("PSC1_INITIAL_OWNER_BENCH_WORKER "));
    insist(records.length===1,"exactly one worker receipt");
    const receipt=JSON.parse(records[0].slice("PSC1_INITIAL_OWNER_BENCH_WORKER ".length));
    insist(receipt.label===label&&receipt.owners===owners&&receipt.query===query&&
     receipt.sourceSha===spec.sourceSha&&receipt.kernelSha256===expectedDigests[label]&&
     receipt.validated===12&&receipt.kernelFuel==="4096","authenticated complete worker receipt");
    workers.push({...receipt,position});
   }
  }
 }finally{fs.rmSync(temporary,{recursive:true,force:true});}
 const median=values=>{const sorted=[...values].sort((a,b)=>a-b),n=sorted.length;
  return n%2?sorted[(n-1)/2]:(sorted[n/2-1]+sorted[n/2])/2;};
 const mean=values=>values.reduce((sum,x)=>sum+x,0)/values.length;
 const rows=[];
 for(const owners of [32,128])for(const query of [
  "trivial-sort","owned-constant","unknown-constant","ill-typed-definition"]){
  const summary=label=>{
   const observations=workers.filter(row=>row.owners===owners&&row.query===query&&row.label===label);
   if(observations.length!==2)return null;
   const warm=observations.flatMap(row=>row.warm);
   return {processes:2,validatedCalls:observations.reduce((sum,row)=>sum+row.validated,0),
    coldMedianMs:median(observations.map(row=>row.cold.wallMs)),
    warmMeanMs:mean(warm.map(row=>row.wallMs)),warmMedianMs:median(warm.map(row=>row.wallMs)),
    warmMeanCpuUs:mean(warm.map(row=>row.cpuUserUs+row.cpuSystemUs)),
    maxProcessPeakRssKiB:Math.max(...observations.map(row=>row.processPeakRssKiB)),
    medianRetainedHeapBytes:median(observations.map(row=>row.retained.heapUsedBytes)),
    medianRetainedHeapDeltaBytes:median(observations.map(row=>row.retainedHeapDeltaBytes)),
    firstBatchMeanMs:mean(observations.map(row=>row.firstBatch.wallMs)),
    inputConstructionMeanMs:mean(observations.map(row=>row.inputConstruction.wallMs))};
  };
  const old=summary("baseline"),next=summary("candidate");
  rows.push({owners,query,baseline:old,candidate:next,
   candidateOverBaselineCold:old&&next&&old.coldMedianMs>0?next.coldMedianMs/old.coldMedianMs:null,
   candidateOverBaselineWarm:old&&next&&old.warmMeanMs>0?next.warmMeanMs/old.warmMeanMs:null,
   candidateMinusBaselinePeakRssKiB:old&&next?
    next.maxProcessPeakRssKiB-old.maxProcessPeakRssKiB:null});
 }
 const report={schema:"psc1-initial-owner-complete-batch-v1",candidateSha,baselineSha,expectedDigests,
  driverSha256:digest(fs.readFileSync(path.resolve(process.argv[1]))),
  scope:"Actual original and candidate public RunDag calls; complete import/validation/checking cost included.",
  limits:{kernelFuel:4096,hostPerWorkerSeconds:60,v8OldSpaceMiB:2048,hardRssLimitClaim:false},
  order:"ABBA: baseline,candidate,candidate,baseline for each size/query; each worker is a new detached process.",
  coldDefinition:"First second-batch call in a fresh process after checked-session setup and the independent V1 outcome control; not the first kernel operation.",
  callsPerWorker:{cold:1,warmup:2,warm:9},expectedWorkers:32,completedWorkers:workers.length,
  validatedCalls:workers.reduce((sum,row)=>sum+row.validated,0),failures,rows,workers};
 fs.writeFileSync(path.join(output,"initial-owner-complete-batch.json"),JSON.stringify(report,null,2)+"\n");
 const lines=[
  "# Initial-session owner complete-batch comparison","",
  "Exact candidate: "+candidateSha+". Exact baseline: "+baselineSha+".",
  "All times include the actual public RunDag call. Setup/import of the JavaScript module and the first checked batch are separately recorded.",
  "Candidate/baseline >1 means slower. These are small paired measurements, not a whole-kernel speedup claim.",
  "The 60-second deadline and 2048MiB V8 old-space setting do not establish an RSS cap.","",
  "| Owners | Query | Baseline warm mean ms | Candidate warm mean ms | Candidate/baseline | Baseline peak KiB | Candidate peak KiB |",
  "|---:|---|---:|---:|---:|---:|---:|"
 ];
 for(const row of rows)lines.push("| "+[row.owners,row.query,
  row.baseline?.warmMeanMs.toFixed(6)??"incomplete",row.candidate?.warmMeanMs.toFixed(6)??"incomplete",
  row.candidateOverBaselineWarm?.toFixed(4)??"incomplete",
  row.baseline?.maxProcessPeakRssKiB??"incomplete",row.candidate?.maxProcessPeakRssKiB??"incomplete"].join(" | ")+" |");
 lines.push("","Validated calls: "+report.validatedCalls+"/384; completed workers: "+workers.length+"/32.",
  "Every negative call requires its exact rejection class and message; any host error leaves the comparison failed.");
 fs.writeFileSync(path.join(output,"initial-owner-complete-batch.md"),lines.join("\n")+"\n");
 insist(failures.length===0&&workers.length===32&&report.validatedCalls===384,"all full-call controls must pass");
 console.log("PSC1_V2_INITIAL_OWNER_BENCH: PASS workers=32 calls=384 sizes=32,128 queries=4");
}
