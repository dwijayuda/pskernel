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
const portableHeadMachine=load("psKernelExprV2PortableHeadMachineChecked");
const portableStructuralEq=load("psKernelExprV2PortableEqChecked");
const portableEqBatch=load("psKernelExprV2PortableEqBatchChecked");
const portableImport=load("psKernelExprV2PortableImportChecked");
const portableImportInto=load("psKernelExprV2PortableImportIntoChecked");
const pagedEmptyWithLimit=load("psKernelExprV2PagedEmptyWithLimit");
const pagedPush=load("psKernelExprV2PagedPush");
const pagedFind=load("psKernelExprV2PagedFind");
const pagedValidate=load("psKernelExprV2PagedValidate");
const pagedLift=load("psKernelExprV2PagedLiftChecked");
const pagedInst=load("psKernelExprV2PagedInstantiate1Checked");
const pagedHead=load("psKernelExprV2PagedHeadMachineChecked");
const pagedMkLam=load("psKernelExprV2PagedMkLam");
const pagedMkLet=load("psKernelExprV2PagedMkLet");
const pagedMkMData=load("psKernelExprV2PagedMkMData");
const pagedMkSort=load("psKernelExprV2PagedMkSort");
const pagedMkBVar=load("psKernelExprV2PagedMkBVar");
const pagedMkApp=load("psKernelExprV2PagedMkApp");
const legacyExpr=load("PsKernelExpr");
const boolListEq=load("psKernelExprV2PortableBoolListEq");
const boolList=load("List");
const boolListNil=typeof boolList.nil==="function"?boolList.nil():boolList.nil;
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
const machineDone=accepted(portableHeadMachine(4n,compositeLet.fst,compositeLet.snd),
  "head-machine-composition");
demand(machineDone.snd===headSequenceDone.snd &&
  machineDone.fst.size===headSequenceDone.fst.size,
  "head-machine-same-result");
const machineExhausted=portableHeadMachine(3n,compositeLet.fst,compositeLet.snd);
demand(machineExhausted&&"error" in machineExhausted,
  "head-machine-remaining-fuel-rejected");
const machineBad=portableHeadMachine(4n,forgedChunk,0n);
demand(machineBad&&"error" in machineBad,"head-machine-forged-rejected");









// Same-arena equality uses verified IDs and hash only as acceleration.
// Equal hashes still need the structural comparison (bvar 0 vs 65521).
const firstBVar=accepted(chunkedMkBVar(chunkedEmptyWithLimit(64n),0n),
  "pair-eq-bvar-zero");
const duplicateBVar=accepted(chunkedMkBVar(firstBVar.fst,0n),
  "pair-eq-bvar-duplicate");
const collidingBVar=accepted(chunkedMkBVar(duplicateBVar.fst,65521n),
  "pair-eq-bvar-hash-collision");
const collidingFirst=acceptedOption(
  chunkedFind(collidingBVar.fst,firstBVar.snd),"pair-eq-first-entry");
const collidingLast=acceptedOption(
  chunkedFind(collidingBVar.fst,collidingBVar.snd),"pair-eq-last-entry");
demand(collidingFirst.hash===collidingLast.hash,"pair-eq-actual-hash-collision");
demand(accepted(portableStructuralEq(
  collidingBVar.fst,firstBVar.snd,duplicateBVar.snd),"pair-eq-duplicate"),
  "pair-eq-distinct-identical-nodes");
demand(accepted(portableStructuralEq(
  collidingBVar.fst,firstBVar.snd,collidingBVar.snd),"pair-eq-collision")===false,
  "pair-eq-hash-collision-not-equality");
demand(portableStructuralEq(forgedChunk,0n,0n)?.error!==undefined,
  "pair-eq-forged-metadata-rejected");
let eqGraph=firstBVar.fst;
let eqLeft=firstBVar.snd, eqRight=firstBVar.snd;
for(let i=0;i<20;i++){
  const one=accepted(chunkedMkApp(eqGraph,eqLeft,eqLeft),"pair-eq-shared-left");
  const two=accepted(chunkedMkApp(one.fst,eqRight,eqRight),"pair-eq-shared-right");
  eqGraph=two.fst; eqLeft=one.snd; eqRight=two.snd;
}
demand(eqGraph.size===41n,"pair-eq-compact-DAG");
demand(eqLeft!==eqRight &&
  accepted(portableStructuralEq(eqGraph,eqLeft,eqRight),"pair-eq-shared-graph"),
  "pair-eq-sharing-memo-success");
const pairEqInvalid=portableStructuralEq(eqGraph,999999n,eqRight);
demand(pairEqInvalid&&"error" in pairEqInvalid,"pair-eq-invalid-id-rejected");


// An equality batch validates exactly one arena. It never carries a positive
// result into a different arena, nor treats hash collisions as equality.
const pairQueries=boolList.cons({fst:eqLeft,snd:eqRight},
  boolList.cons({fst:eqRight,snd:eqLeft},
    boolList.cons({fst:eqLeft,snd:firstBVar.snd},boolListNil)));
const expectedPairAnswers=boolList.cons(true,
  boolList.cons(true,boolList.cons(false,boolListNil)));
const paired=accepted(portableEqBatch(eqGraph,pairQueries),"pair-batch-checked");
demand(boolListEq(paired)(expectedPairAnswers)===true,
  "pair-batch-ordered-answers");
const badBatch=portableEqBatch(eqGraph,
  boolList.cons({fst:eqLeft,snd:99999n},boolListNil));
demand(badBatch&&"error" in badBatch,"pair-batch-invalid-node-rejected");
const batchForged=portableEqBatch(forgedChunk,
  boolList.cons({fst:0n,snd:0n},boolListNil));
demand(batchForged&&"error" in batchForged,
  "pair-batch-forged-metadata-rejected");
let repeatedPairs=boolListNil,repeatedExpected=boolListNil;
for(let i=0;i<12;i++){
  repeatedPairs=boolList.cons({fst:eqLeft,snd:eqRight},repeatedPairs);
  repeatedExpected=boolList.cons(true,repeatedExpected);
}
const pairBatchMetrics=[];
function compareBatch(kind) {
  const start=performance.now();
  if(kind==="repeated-single"){
    for(let i=0;i<12;i++){
      if(accepted(portableStructuralEq(eqGraph,eqLeft,eqRight),
          "pair-batch-repeated-single")!==true)
        throw Error("PSC1_V2_PAIR_BATCH_SINGLE_MISMATCH");
    }
  }else{
    const values=accepted(portableEqBatch(eqGraph,repeatedPairs),
      "pair-batch-amortized");
    if(!boolListEq(values)(repeatedExpected))
      throw Error("PSC1_V2_PAIR_BATCH_BATCHED_MISMATCH");
  }
  pairBatchMetrics.push({kind,queries:12,arena_nodes:Number(eqGraph.size),
    ms:Number((performance.now()-start).toFixed(3))});
}
compareBatch("repeated-single");
compareBatch("batch");
compareBatch("batch");
compareBatch("repeated-single");
console.log("PSC1_EXPR_V2_PAIR_BATCH_TIMINGS "+JSON.stringify(pairBatchMetrics));


// Real legacy-expression input adapter, checked by the same portable
// smart-constructor replay used for V2 metadata/collision safety.
const oldSort=legacyExpr.sort(level.zero);
const oldIdentityLam=legacyExpr.lam(nameConstructors.anonymous,
  oldSort,legacyExpr.bvar(0n),binderConstructors.default);
const oldBeta=legacyExpr.app(oldIdentityLam,oldSort);
const imported=accepted(portableImport(oldBeta),"portable-import-old-beta");
const importedCopy=accepted(
  portableImportInto(imported.fst,oldBeta),"portable-import-copy");
demand(imported.snd!==importedCopy.snd &&
  accepted(portableStructuralEq(importedCopy.fst,imported.snd,importedCopy.snd),
    "portable-import-identity-parity"),
  "portable-import-structural-copy-equality");
const importedStep=accepted(
  portableHeadMachine(2n,imported.fst,imported.snd),
  "portable-import-beta-reduction");
const sortWithRoot=accepted(chunkedMkSort(importedStep.fst,level.zero),
  "portable-import-beta-expected-sort");
demand(accepted(portableStructuralEq(
  sortWithRoot.fst,importedStep.snd,sortWithRoot.snd),
  "portable-import-beta-result-equality"),
  "portable-import-beta-parity");
const importedForged=portableImportInto(forgedChunk,oldSort);
demand(importedForged&&"error" in importedForged,
  "portable-import-rejects-forged-input");

// Order-balanced comparison; both implementations see equivalent prebuilt DAGs.
// Every result and returned arena size is checked before accepting a timing.
const headMachineMetrics=[];
for(const depth of [8,24,48]){
  let a=accepted(chunkedMkSort(chunkedEmptyWithLimit(64n),level.zero),
    "head-machine-sort");
  const sortId=a.snd;
  for(let i=0;i<depth;i++){
    a=accepted(chunkedMkLet(a.fst,nameConstructors.anonymous,
      sortId,sortId,a.snd,false),"head-machine-let");
  }
  const evaluate=(kind)=>{
    const start=performance.now();
    const ret=accepted(
      (kind==="fast"?portableHeadMachine:portableHeadSequence)(
        BigInt(depth+1),a.fst,a.snd),
      "head-machine-"+kind+"-"+depth);
    const elapsed=performance.now()-start;
    if(ret.snd!==sortId || ret.fst.size!==a.fst.size)
      throw Error("PSC1_V2_HEAD_MACHINE_PARITY "+kind+" "+depth);
    headMachineMetrics.push({kind,depth,ms:Number(elapsed.toFixed(3)),
      input_nodes:Number(a.fst.size),output_nodes:Number(ret.fst.size)});
  };
  // ABBA to expose order/warmup bias; timings remain microbenchmarks.
  evaluate("slow"); evaluate("fast"); evaluate("fast"); evaluate("slow");
}
console.log("PSC1_EXPR_V2_HEAD_MACHINE_TIMINGS "+JSON.stringify(headMachineMetrics));



// Paged arena is an independently validated experimental alternative.
// Old and middle node IDs must remain directly accessible after page rollover.
let paged= pagedEmptyWithLimit(64n);
for(let i=0;i<128;i++){
  const add=pagedPush(paged,firstEntry);
  demand(add.snd===BigInt(i),"paged-id-"+i);
  paged=add.fst;
}
demand(paged.size===128n,"paged-size-128");
const checkedPaged=accepted(pagedValidate(paged),"paged-replay-validated");
for(const i of [0,1,31,63,64,65,96,127]){
  const entry=acceptedOption(pagedFind(checkedPaged,BigInt(i)),
    "paged-readback-"+i);
  demand(entry.hash===firstEntry.hash &&
    entry.looseRange===firstEntry.looseRange,"paged-lookup-"+i);
}
const invalidPage=pagedFind(paged,128n);
demand(!invalidPage||!("value" in invalidPage),"paged-out-of-bounds");

const firstPaged=accepted(pagedMkBVar(pagedEmptyWithLimit(64n),0n),
  "paged-smart-bvar");
const pairPaged=accepted(pagedMkApp(firstPaged.fst,firstPaged.snd,firstPaged.snd),
  "paged-smart-shared-app");
const pagedApp=acceptedOption(pagedFind(pairPaged.fst,pairPaged.snd),
  "paged-app-lookup");
demand(pagedApp.depth===2n,"paged-smart-app-depth");
demand(accepted(pagedValidate(pairPaged.fst),"paged-smart-validation").size===2n,
  "paged-smart-count");
const forgedPaged=pagedPush(pagedEmptyWithLimit(64n),
  {...firstEntry,hasFVar:true}).fst;
const forgedPagedResult=pagedValidate(forgedPaged);
demand(forgedPagedResult&&"error" in forgedPagedResult,
  "paged-forged-metadata-rejected");
const badPagedLayout={...paged,size:paged.size+1n};
const badPagedResult=pagedValidate(badPagedLayout);
demand(badPagedResult&&"error" in badPagedResult,
  "paged-malformed-layout-rejected");




// Semantic-pilot parity: construct equivalent direct beta/zeta/mdata terms
// using independent paged builders and the qualified chunked reference.
const piLeaf=accepted(pagedMkBVar(pagedEmptyWithLimit(64n),0n),
  "paged-inst-leaf");
const piSort=accepted(pagedMkSort(piLeaf.fst,level.zero),"paged-inst-sort");
const piLam=accepted(pagedMkLam(piSort.fst,nameConstructors.anonymous,
  piSort.snd,piLeaf.snd,binderConstructors.default),"paged-inst-lambda");
const piBeta=accepted(pagedMkApp(piLam.fst,piLam.snd,piSort.snd),
  "paged-inst-beta");
const piInst=accepted(pagedInst(piBeta.fst,piLeaf.snd,piSort.snd),
  "paged-inst-substitution");
demand(piInst.snd===piSort.snd,"paged-inst-identity-beta");
const piMetadata=accepted(pagedMkMData(piBeta.fst,7n,piBeta.snd),
  "paged-head-metadata");
const piOuter=accepted(pagedMkLet(piMetadata.fst,nameConstructors.anonymous,
  piSort.snd,piSort.snd,piMetadata.snd,false),"paged-head-outer-let");
const piResult=accepted(pagedHead(4n,piOuter.fst,piOuter.snd),
  "paged-head-beta-zeta-mdata");
demand(piResult.snd===piSort.snd &&
  piResult.fst.size===piOuter.fst.size,
  "paged-head-checked-result");
const piFuel=pagedHead(3n,piOuter.fst,piOuter.snd);
demand(piFuel&&"error" in piFuel,"paged-head-fuel-rejected");
const piBadInst=pagedInst(forgedPaged,0n,0n);
const piBadHead=pagedHead(4n,forgedPaged,0n);
demand(piBadInst&&"error" in piBadInst &&
  piBadHead&&"error" in piBadHead,"paged-semantic-forged-rejected");
const piInvalid=pagedInst(piOuter.fst,9999n,piSort.snd);
demand(piInvalid&&"error" in piInvalid,"paged-inst-invalid-root-rejected");

const pagedHeadTimings=[];
for(const depth of [8,24,48]){
  function make(kind){
    const isPaged=kind==="paged";
    let start=accepted(isPaged?
      pagedMkSort(pagedEmptyWithLimit(64n),level.zero):
      chunkedMkSort(chunkedEmptyWithLimit(64n),level.zero),
      "paged-head-sort");
    const sortId=start.snd;
    for(let i=0;i<depth;i++){
      start=accepted(isPaged?
        pagedMkLet(start.fst,nameConstructors.anonymous,
          sortId,sortId,start.snd,false):
        chunkedMkLet(start.fst,nameConstructors.anonymous,
          sortId,sortId,start.snd,false),"paged-head-nested-let");
    }
    return {arena:start.fst,root:start.snd,sort:sortId};
  }
  const chunk=make("chunked"),page=make("paged");
  for(const kind of ["chunked","paged","paged","chunked"]){
    const input=kind==="paged"?page:chunk;
    const begin=performance.now();
    const result=accepted(
      (kind==="paged"?pagedHead:portableHeadMachine)(
        BigInt(depth+1),input.arena,input.root),"paged-head-benchmark");
    const ms=performance.now()-begin;
    if(result.snd!==input.sort||result.fst.size!==input.arena.size)
      throw Error("PSC1_V2_PAGED_HEAD_BENCH_PARITY "+depth+" "+kind);
    pagedHeadTimings.push({kind,depth,ms:Number(ms.toFixed(3)),
      input_nodes:Number(input.arena.size),output_nodes:Number(result.fst.size)});
  }
}
console.log("PSC1_EXPR_V2_PAGED_HEAD_TIMINGS "+JSON.stringify(pagedHeadTimings));

const timings=[];
const readArray=(a,id)=>accepted(lookup(a,id),"measured-array-read");
const readChunked=(a,id)=>acceptedOption(chunkedFind(a,id),"measured-chunked-read");
const readPaged=(a,id)=>acceptedOption(pagedFind(a,id),"measured-paged-read");
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
      timed("paged"+limit+"-"+n+"-"+round,n,()=>{
        let x=pagedEmptyWithLimit(BigInt(limit));
        for(let i=0;i<n;i++)x=pagedPush(x,firstEntry).fst;
        return x;
      },readPaged);
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
demand(timings.length===44 &&
  timings.every(x=>x.checksum===String(firstEntry.hash*3n) &&
    x.n===Number(x.label.split("-")[1])),"matched-storage-build-and-readback");
console.log("PSC1_EXPR_V2_JS_TIMINGS "+JSON.stringify(timings));

// V2 DAG algorithms repeatedly reference previously built nodes, not only
// append new nodes. Compare cold/old-page lookups after equal construction.
let lookupChunked=chunkedEmptyWithLimit(64n);
let lookupPaged=pagedEmptyWithLimit(64n);
for(let i=0;i<4096;i++){
  lookupChunked=chunkedPush(lookupChunked,firstEntry).fst;
  lookupPaged=pagedPush(lookupPaged,firstEntry).fst;
}
const lookupIds=[0n,63n,1024n,2048n,4095n];
const lookupResults=[];
function measureLookups(kind){
  const find=kind==="paged"?pagedFind:chunkedFind;
  const arena=kind==="paged"?lookupPaged:lookupChunked;
  let checksum=0n;
  const start=performance.now();
  for(let r=0;r<24;r++){
    for(const id of lookupIds){
      const entry=acceptedOption(find(arena,id),"measured-"+kind+"-"+id);
      checksum+=entry.hash+entry.looseRange;
    }
  }
  const elapsed=performance.now()-start;
  const expected=120n*(firstEntry.hash+firstEntry.looseRange);
  if(checksum!==expected)throw Error("PSC1_V2_LOOKUP_CHECKSUM "+kind);
  lookupResults.push({kind,queries:120,arena_nodes:4096,
    ms:Number(elapsed.toFixed(3)),checksum:String(checksum)});
}
measureLookups("chunked");
measureLookups("paged");
measureLookups("paged");
measureLookups("chunked");
console.log("PSC1_EXPR_V2_LOOKUP_TIMINGS "+JSON.stringify(lookupResults));

// Realistic DAG construction: every application references a newly
// built head and the oldest BVar leaf. Both arenas must compute the
// SAME checked metadata while preserving old and recent node access.
// Construction is measured separately from replay validation.
const spineMeasures=[];
function buildSharedSpine(kind,depth){
  const isPaged=kind==="paged";
  const start=accepted(
    isPaged?pagedMkBVar(pagedEmptyWithLimit(64n),0n):
      chunkedMkBVar(chunkedEmptyWithLimit(64n),0n),
    "spine-leaf-"+kind);
  let arena=start.fst, root=start.snd;
  const leaf=root;
  const startTime=performance.now();
  for(let i=0;i<depth;i++){
    const next=accepted(
      isPaged?pagedMkApp(arena,root,leaf):
        chunkedMkApp(arena,root,leaf),
      "spine-append-"+kind);
    arena=next.fst;
    root=next.snd;
  }
  const buildMs=performance.now()-startTime;
  const find=isPaged?pagedFind:chunkedFind;
  const value=acceptedOption(find(arena,root),"spine-root-"+kind);
  const leafValue=acceptedOption(find(arena,leaf),"spine-leaf-"+kind);
  if(value.depth!==BigInt(depth+1)||value.looseRange!==1n||
     value.hasFVar!==false || leafValue.looseRange!==1n ||
     arena.size!==BigInt(depth+1))
    throw Error("PSC1_V2_SPINE_METADATA_PARITY "+kind+" "+depth);
  const checksum=value.hash+leafValue.hash+value.looseRange+value.depth;
  return {arena,root,checksum,buildMs};
}
for(const depth of [1024,4096,8192]){
  let expectedChecksum=null;
  for(const kind of ["chunked","paged","paged","chunked"]){
    const result=buildSharedSpine(kind,depth);
    if(expectedChecksum===null)expectedChecksum=result.checksum;
    if(expectedChecksum!==result.checksum)
      throw Error("PSC1_V2_SPINE_HASH_MISMATCH "+kind+" "+depth);
    spineMeasures.push({kind,depth,
      build_ms:Number(result.buildMs.toFixed(3)),
      node_count:Number(result.arena.size),
      checksum:String(result.checksum)});
  }
}
console.log("PSC1_EXPR_V2_SPINE_TIMINGS "+JSON.stringify(spineMeasures));

// Pilot port of M3 binder lifting from the linked-chunk arena to pages.
// Compare identical shared App DAGs and checked output metadata.
const pagedLiftMeasurements=[];
for(const depth of [128,512,1024]){
  const chunkGraph=buildSharedSpine("chunked",depth);
  const pageGraph=buildSharedSpine("paged",depth);
  let expectedHash=null;
  for(const kind of ["chunked","paged","paged","chunked"]){
    const isPaged=kind==="paged";
    const graph=isPaged?pageGraph:chunkGraph;
    const start=performance.now();
    const reduced=accepted(
      (isPaged?pagedLift:portableLift)(graph.arena,graph.root,0n,2n),
      "paged-lift-"+kind+"-"+depth);
    const elapsed=performance.now()-start;
    const value=acceptedOption(
      (isPaged?pagedFind:chunkedFind)(reduced.fst,reduced.snd),
      "paged-lift-root-"+kind);
    if(value.depth!==BigInt(depth+1)||value.looseRange!==3n||
       value.hasFVar!==false||reduced.fst.size>graph.arena.size+BigInt(depth+1))
      throw Error("PSC1_V2_PAGED_LIFT_INVALID_RESULT "+kind+" "+depth);
    const signature=String(value.hash)+"-"+String(value.depth)+"-"+String(value.looseRange);
    if(expectedHash===null)expectedHash=signature;
    if(signature!==expectedHash)
      throw Error("PSC1_V2_PAGED_LIFT_METADATA_DIFFERENCE "+kind+" "+depth);
    pagedLiftMeasurements.push({
      kind,depth,ms:Number(elapsed.toFixed(3)),
      input_nodes:Number(graph.arena.size),output_nodes:Number(reduced.fst.size),
      checksum:signature
    });
  }
}
const pagedLiftForged=pagedLift(forgedPaged,0n,0n,1n);
demand(pagedLiftForged&&"error" in pagedLiftForged,"paged-lift-forged-rejected");
console.log("PSC1_EXPR_V2_PAGED_LIFT_TIMINGS "+JSON.stringify(pagedLiftMeasurements));



console.log("PSC1_EXPR_V2_JS_SUMMARY "+JSON.stringify({
  node:process.version,source_bytes:fs.statSync(filename).size,
  rss_bytes:process.memoryUsage().rss,
  post_gc_heap_bytes:(typeof global.gc==="function"?(global.gc(),process.memoryUsage().heapUsed):null),
  all_correct:true
}));
console.log("PSC1_EXPR_V2_JS_SMOKE: PASS");
