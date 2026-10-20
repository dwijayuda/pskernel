import { pathToFileURL } from "node:url";
import { performance } from "node:perf_hooks";
import path from "node:path";
import fs from "node:fs";

const filename=process.argv[2];
if(!filename) throw Error("PSC1_V2_SMOKE_OUTPUT_MISSING");
const lib=await import(pathToFileURL(path.resolve(filename)).href);
const load=name=>{
  if(!(name in lib))throw Error("PSC1_V2_MISSING_EXPORT "+name);
  return lib[name];
};
const demand=(ok,label)=>{
  if(!ok)throw Error("PSC1_V2_JS_FAILED "+label);
  console.log("PSC1_EXPR_V2_JS_PASS "+label);
};
const accepted=(result,label)=>{
  if(result && "value" in result)return result.value;
  throw Error("PSC1_V2_JS_REJECTED "+label+" "+String(result?.error));
};
const empty=load("psKernelExprV2Empty");
const emptyIndex=load("psKernelExprV2IndexedEmpty");
const mkBVar=load("psKernelExprV2MkBVar");
const push=load("psKernelExprV2Push");
const mkApp=load("psKernelExprV2MkApp");
const lookup=load("psKernelExprV2Lookup");
const indexedPush=load("psKernelExprV2IndexedPush");
const indexedFind=load("psKernelExprV2IndexedFind");
const indexedMkBVar=load("psKernelExprV2IndexedMkBVar");
const indexedMkApp=load("psKernelExprV2IndexedMkApp");
const chunkedEmptyWithLimit=load("psKernelExprV2ChunkedEmptyWithLimit");
const chunkedPush=load("psKernelExprV2ChunkedPush");
const chunkedFind=load("psKernelExprV2ChunkedFind");
const chunkedMkBVar=load("psKernelExprV2ChunkedMkBVar");
const chunkedMkApp=load("psKernelExprV2ChunkedMkApp");
const portableValidate=load("psKernelExprV2PortableValidate");
const portableLift=load("psKernelExprV2PortableLiftChecked");
const portableInstantiate=load("psKernelExprV2PortableInstantiate1Checked");
const portableHeadStep=load("psKernelExprV2PortableHeadStepChecked");
const portableHeadSequence=load("psKernelExprV2PortableHeadSequenceChecked");
const chunkedMkLet=load("psKernelExprV2ChunkedMkLet");
const chunkedMkMData=load("psKernelExprV2ChunkedMkMData");
const chunkedMkSort=load("psKernelExprV2ChunkedMkSort");
const chunkedMkLam=load("psKernelExprV2ChunkedMkLam");
const nameConstructors=load("PsKernelName");
const binderConstructors=load("PsKernelBinderInfo");
const level=load("PsKernelLevel");
const mkSort=load("psKernelExprV2MkSort");
let arena=empty;
let indexed=emptyIndex;
const count=128;
let firstId=0n;
for(let i=0;i<count;i++){
  const pushed=mkBVar(arena,BigInt(i));
  arena=pushed.fst;
  const id=pushed.snd;
  if(i===0)firstId=id;
  demand(id===BigInt(i),"arena-id-"+i);
  const entry=accepted(lookup(arena,id),"arena-lookup-"+i);
  const indexedResult=accepted(indexedPush(indexed,entry),"indexed-insert-"+i);
  indexed=indexedResult.fst;
  demand(indexedResult.snd===id,"indexed-id-"+i);
}
demand(arena.nodes.length===count,"array-arena-node-count");
demand(indexed.size===BigInt(count),"indexed-arena-size");
for(const i of [0,1,3,7,15,63,127]){
  const id=BigInt(i);
  const indexedEntry=indexedFind(indexed,id);
  demand(indexedEntry&&"value" in indexedEntry &&
    indexedEntry.value.looseRange===id+1n,"indexed-lookup-"+i);
}
const firstEntry=accepted(lookup(arena,firstId),"first-entry");
demand(firstEntry.looseRange===1n,"first-loose-range");
const sortResult=mkSort(arena,level.zero);
arena=sortResult.fst;
const appResult=accepted(mkApp(arena,firstId,firstId),"shared-app");
const appEntry=accepted(lookup(appResult.fst,appResult.snd),"shared-app-lookup");
demand(appEntry.depth===2n,"shared-app-depth");
demand(appEntry.hasFVar===false,"shared-app-no-fvar");
const freshIndex=accepted(indexedMkBVar(emptyIndex,0n),"indexed-builder-bvar");
const indexedApplication=accepted(indexedMkApp(freshIndex.fst,freshIndex.snd,freshIndex.snd),
  "indexed-builder-shared-app");
const newestIndexed=indexedFind(indexedApplication.fst,indexedApplication.snd);
demand(newestIndexed&&"value" in newestIndexed &&
  newestIndexed.value.depth===2n,"indexed-builder-app-lookup");
let chunked=chunkedEmptyWithLimit(32n);
for(let i=0;i<count;i++){
  const added=chunkedPush(chunked,firstEntry);
  demand(added.snd===BigInt(i),"chunked-id-"+i);
  chunked=added.fst;
}
demand(chunked.size===BigInt(count),"chunked-count");
for(const i of [0,1,31,32,63,64,127]){
  const entry=chunkedFind(chunked,BigInt(i));
  demand(entry&&"value" in entry &&
    entry.value.looseRange===firstEntry.looseRange,"chunked-lookup-"+i);
}
const chunkedBeyond=chunkedFind(chunked,BigInt(count));
demand(!chunkedBeyond || !("value" in chunkedBeyond),"chunked-out-of-range");

const validatedChunked=accepted(portableValidate(chunked),"portable-chunked-validate");
demand(validatedChunked.size===chunked.size,"portable-validation-count");
const forgedChunk=chunkedPush(chunkedEmptyWithLimit(32n),{...firstEntry,hasFVar:true}).fst;
const forgedCheck=portableValidate(forgedChunk);
demand(forgedCheck&&"error" in forgedCheck,"portable-rejects-forged-closedness");

const initialShared=accepted(chunkedMkBVar(chunkedEmptyWithLimit(64n),0n),
  "portable-shared-leaf");
let shared=initialShared.fst, root=initialShared.snd;
for(let i=0;i<12;i++){
  const next=accepted(chunkedMkApp(shared,root,root),"portable-shared-app-"+i);
  shared=next.fst;
  root=next.snd;
}
demand(shared.size===13n,"portable-shared-node-count");
const validatedShared=accepted(portableValidate(shared),"portable-validate-shared-dag");
demand(validatedShared.size===shared.size,"portable-shared-validation-count");
const sharedEntry=acceptedOption(chunkedFind(validatedShared,root),"portable-shared-root");
demand(sharedEntry.depth===13n,"portable-shared-depth");

const lifted=accepted(portableLift(shared,root,0n,2n),"portable-lift-shared");
const liftedRoot=acceptedOption(
  chunkedFind(lifted.fst,lifted.snd),"portable-lift-root");
demand(liftedRoot.depth===sharedEntry.depth,"portable-lift-preserves-depth");
demand(liftedRoot.looseRange===3n,"portable-lift-increases-loose-range");
demand(lifted.fst.size<=shared.size+13n,"portable-lift-sharing-growth");
const liftedApp=liftedRoot.node;
demand(liftedApp.fn===liftedApp.arg,"portable-lift-shared-child-id");
const liftedZero=accepted(portableLift(shared,root,0n,0n),"portable-lift-zero");
demand(liftedZero.snd===root && liftedZero.fst.size===shared.size,
  "portable-lift-zero-allocation");
const liftedAbove=accepted(portableLift(shared,root,3n,1n),"portable-lift-above-range");
demand(liftedAbove.snd===root && liftedAbove.fst.size===shared.size,
  "portable-lift-prunes-unaffected");
const forgedLift=portableLift(forgedChunk,0n,0n,1n);
demand(forgedLift&&"error" in forgedLift,"portable-lift-rejects-forged-metadata");
const missingLift=portableLift(shared,9999n,0n,1n);
demand(missingLift&&"error" in missingLift,"portable-lift-rejects-invalid-root");

const sourceWithSort=accepted(chunkedMkSort(shared,level.zero),"inst-shared-sort");
const instClosed=accepted(
  portableInstantiate(sourceWithSort.fst,root,sourceWithSort.snd),
  "portable-instantiate-shared");
const instRoot=acceptedOption(chunkedFind(instClosed.fst,instClosed.snd),"inst-root");
demand(instRoot.looseRange===0n,"instantiate-closed-substitution");
demand(instRoot.depth===sharedEntry.depth,"instantiate-preserves-depth");
demand(instClosed.fst.size<=sourceWithSort.fst.size+13n,"instantiate-sharing-node-bound");
demand(instRoot.node.fn===instRoot.node.arg,"instantiate-shared-children");

const x1=accepted(chunkedMkBVar(sourceWithSort.fst,1n),"inst-bvar-one");
const x2=accepted(chunkedMkBVar(x1.fst,2n),"inst-bvar-two");
const lam=accepted(chunkedMkLam(x2.fst,nameConstructors.anonymous,
  sourceWithSort.snd,x1.snd,binderConstructors.default),"inst-open-lambda");
const instLam=accepted(portableInstantiate(lam.fst,lam.snd,x2.snd),
  "instantiate-under-binder");
const actualLam=acceptedOption(chunkedFind(instLam.fst,instLam.snd),"inst-lambda");
demand(actualLam.looseRange===3n,"instantiate-binder-depth-capture-avoidance");
const untouched=accepted(chunkedMkLam(lam.fst,nameConstructors.anonymous,
  sourceWithSort.snd,firstId,binderConstructors.default),"inst-closed-lambda");
const instUntouched=accepted(portableInstantiate(untouched.fst,untouched.snd,x2.snd),
  "instantiate-closed-lambda");
demand(instUntouched.snd===untouched.snd &&
  instUntouched.fst.size===untouched.fst.size,"instantiate-preserves-bound-bvar");
const instInvalid=portableInstantiate(sourceWithSort.fst,root,999999n);
demand(instInvalid&&"error" in instInvalid,"instantiate-invalid-replacement-rejected");
const instForged=portableInstantiate(forgedChunk,0n,0n);
demand(instForged&&"error" in instForged,"instantiate-forged-metadata-rejected");


// Head reduction is deliberately one step, not a full WHNF interpreter.
const headLam=accepted(chunkedMkLam(sourceWithSort.fst,nameConstructors.anonymous,
  sourceWithSort.snd,firstId,binderConstructors.default),"head-lambda");
const headBeta=accepted(chunkedMkApp(headLam.fst,headLam.snd,sourceWithSort.snd),
  "head-beta-input");
const betaStep=accepted(portableHeadStep(headBeta.fst,headBeta.snd),"head-beta-step");
demand(betaStep.snd===sourceWithSort.snd,"head-beta-to-argument");
const headLet=accepted(chunkedMkLet(headBeta.fst,nameConstructors.anonymous,
  sourceWithSort.snd,sourceWithSort.snd,firstId,false),"head-let-input");
const letStep=accepted(portableHeadStep(headLet.fst,headLet.snd),"head-zeta-step");
demand(letStep.snd===sourceWithSort.snd,"head-zeta-to-value");
const metadata=accepted(chunkedMkMData(headBeta.fst,17n,headBeta.snd),"head-mdata-input");
const mdataStep=accepted(portableHeadStep(metadata.fst,metadata.snd),"head-mdata-step");
demand(mdataStep.snd===headBeta.snd,"head-mdata-only-unwraps-once");
const neutralHead=accepted(chunkedMkApp(headBeta.fst,sourceWithSort.snd,sourceWithSort.snd),
  "head-neutral-input");
const neutralStep=accepted(portableHeadStep(neutralHead.fst,neutralHead.snd),
  "head-neutral-step");
demand(neutralStep.snd===neutralHead.snd &&
  neutralStep.fst.size===neutralHead.fst.size,"head-neutral-identity");
const invalidHead=portableHeadStep(headBeta.fst,999999n);
demand(invalidHead&&"error" in invalidHead,"head-invalid-root-rejected");
const forgedHead=portableHeadStep(forgedChunk,0n);
demand(forgedHead&&"error" in forgedHead,"head-forged-metadata-rejected");

const compositeLet=accepted(chunkedMkLet(metadata.fst,nameConstructors.anonymous,
  sourceWithSort.snd,sourceWithSort.snd,metadata.snd,false),"head-sequence-input");
const headSequenceDone=accepted(
  portableHeadSequence(4n,compositeLet.fst,compositeLet.snd),
  "head-sequence-composition");
demand(headSequenceDone.snd===sourceWithSort.snd,
  "head-sequence-beta-zeta-mdata-normal-form");
const headSequenceExhausted=portableHeadSequence(3n,compositeLet.fst,compositeLet.snd);
demand(headSequenceExhausted&&"error" in headSequenceExhausted,
  "head-sequence-resource-exhaustion");
const headNeutral=accepted(portableHeadSequence(1n,sourceWithSort.fst,sourceWithSort.snd),
  "head-sequence-neutral");
demand(headNeutral.snd===sourceWithSort.snd,
  "head-sequence-neutral-identity");






const timings=[];
const readArray=(a,id)=>accepted(lookup(a,id),"measured-array-read");
const readChunked=(a,id)=>acceptedOption(chunkedFind(a,id),"measured-chunked-read");
const readIndexed=(a,id)=>acceptedOption(indexedFind(a,id),"measured-indexed-read");
function acceptedOption(option,label){
  if(option&&"value" in option)return option.value;
  throw Error("PSC1_V2_OPTION_MISSING "+label);
}
function timed(label,n,build,read){
  // All benchmark variants insert the *same* already-validated metadata entry,
  // and must read the beginning, middle and end from the completed arena.
  const t0=performance.now();
  const arena=build();
  const checks=[0n,BigInt(Math.floor(n/2)),BigInt(n-1)];
  let checksum=0n;
  for(const id of checks){
    const entry=read(arena,id);
    if(entry.looseRange!==firstEntry.looseRange)
      throw Error("PSC1_V2_BENCH_READBACK_LOOSE "+label+" "+id);
    checksum+=entry.hash;
  }
  const ms=performance.now()-t0;
  if(checksum!==3n*firstEntry.hash)
    throw Error("PSC1_V2_BENCH_READBACK_HASH "+label);
  if(typeof global.gc==="function")global.gc();
  const m=process.memoryUsage();
  // Keep the completed snapshot live past the forced-GC measurement.
  if(read(arena,0n).hash!==firstEntry.hash)
    throw Error("PSC1_V2_BENCH_GC_LOST_SNAPSHOT "+label);
  timings.push({
    label,n,ms:Number(ms.toFixed(3)),checksum:String(checksum),
    post_gc_heap_bytes:m.heapUsed,rss_bytes:m.rss
  });
}
for(const n of [256,1024,4096]){
  for(let round=0;round<2;round++){
    timed("array-"+n+"-"+round,n,()=>{
      let x=empty;
      for(let i=0;i<n;i++)x=push(x,firstEntry).fst;
      return x;
    },readArray);
    for(const limit of [16,32,64]){
      timed("chunked"+limit+"-"+n+"-"+round,n,()=>{
        let x=chunkedEmptyWithLimit(BigInt(limit));
        for(let i=0;i<n;i++)x=chunkedPush(x,firstEntry).fst;
        return x;
      },readChunked);
    }
    if(n===256){
      timed("indexed-"+n+"-"+round,n,()=>{
        let x=emptyIndex;
        for(let i=0;i<n;i++){
          x=accepted(indexedPush(x,firstEntry),"bench-index-push").fst;
        }
        return x;
      },readIndexed);
    }
  }
}
demand(timings.length===26 &&
  timings.every(x=>x.checksum===String(firstEntry.hash*3n) &&
    x.n===Number(x.label.split("-")[1])),"matched-storage-build-and-readback");
console.log("PSC1_EXPR_V2_JS_TIMINGS "+JSON.stringify(timings));
console.log("PSC1_EXPR_V2_JS_SUMMARY "+JSON.stringify({
  node:process.version,source_bytes:fs.statSync(filename).size,
  rss_bytes:process.memoryUsage().rss,
  post_gc_heap_bytes:(typeof global.gc==="function"?(global.gc(),process.memoryUsage().heapUsed):null),
  all_correct:true
}));
console.log("PSC1_EXPR_V2_JS_SMOKE: PASS");
