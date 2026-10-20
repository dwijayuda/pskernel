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
function timed(label,build){
  const before=performance.now();
  const result=build();
  const elapsed=performance.now()-before;
  timings.push({label,ms:Number(elapsed.toFixed(3)),n:result});
}
for(const n of [256,1024,4096]){
  for(let round=0;round<2;round++){
    timed("array-"+n+"-"+round,()=>{
      let x=empty;
      for(let i=0;i<n;i++)x=push(x,firstEntry).fst;
      return x.nodes.length;
    });
    timed("chunked32-"+n+"-"+round,()=>{
      let x=chunkedEmptyWithLimit(32n);
      for(let i=0;i<n;i++)x=chunkedPush(x,firstEntry).fst;
      return Number(x.size);
    });
    if(n===256){
      timed("indexed-"+n+"-"+round,()=>{
        let x=emptyIndex;
        for(let i=0;i<n;i++){
          x=accepted(indexedPush(x,firstEntry),"bench-index-push").fst;
        }
        return Number(x.size);
      });
    }
  }
}
demand(timings.every(x=>x.n===Number(x.label.split("-")[1])),"matched-build-work");
console.log("PSC1_EXPR_V2_JS_TIMINGS "+JSON.stringify(timings));
console.log("PSC1_EXPR_V2_JS_SUMMARY "+JSON.stringify({
  node:process.version,source_bytes:fs.statSync(filename).size,
  rss_bytes:process.memoryUsage().rss,
  post_gc_heap_bytes:(typeof global.gc==="function"?(global.gc(),process.memoryUsage().heapUsed):null),
  all_correct:true
}));
console.log("PSC1_EXPR_V2_JS_SMOKE: PASS");
