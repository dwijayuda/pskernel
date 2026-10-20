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
