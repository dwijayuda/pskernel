import {pathToFileURL} from "node:url";
import path from "node:path";

// Matches PsKernelExprV2WhnfCacheRegression.lean. Raw malformed cache rows and
// impossible marker hashes are internal diagnostics, never admission evidence.
const filename=process.argv[2];
if(!filename)throw Error("PSC1_INDEXED_CACHE_REQUIRES_GENERATED_KERNEL");
const k=await import(pathToFileURL(path.resolve(filename)).href);
const get=name=>{if(!(name in k))throw Error("PSC1_INDEXED_CACHE_MISSING_EXPORT "+name);return k[name];};
const unit=x=>typeof x==="function"?x():x;
let assertions=0;
const must=(condition,label)=>{if(condition!==true)throw Error("PSC1_INDEXED_CACHE_FAIL "+label);assertions++;};
const accepted=(value,label)=>{
 if(value&&typeof value==="object"&&Object.hasOwn(value,"value"))return value.value;
 throw Error("PSC1_INDEXED_CACHE_REJECTED "+label+": "+
  JSON.stringify(value,(_,v)=>typeof v==="bigint"?String(v):v));
};
const rejected=value=>Boolean(value&&typeof value==="object"&&Object.hasOwn(value,"error"));
const same=(a,b)=>{
 if(a===b)return true;
 if(a===null||b===null||typeof a!=="object"||typeof b!=="object")return false;
 const ak=Reflect.ownKeys(a),bk=Reflect.ownKeys(b);
 return ak.length===bk.length&&ak.every(key=>Object.hasOwn(b,key)&&same(a[key],b[key]));
};
const List=get("List"),nil=unit(List.nil),Option=get("Option"),none=unit(Option.none),Ex=get("Except");
const list=xs=>xs.reduceRight((tail,head)=>List.cons(head,tail),nil);
const array=xs=>{const out=[];while(xs&&typeof xs==="object"&&Object.hasOwn(xs,"head")){out.push(xs.head);xs=xs.tail;}return out;};
const attempt=(value,label)=>accepted(accepted(value,label+"-some"),label+"-ok");
const ok=(state,value)=>Option.some(Ex.ok({fst:state,snd:value}));
const errorIs=(label,message,value)=>{
 const result=accepted(value,label+"-some");
 must(rejected(result)&&result.error===message,label);
};
const invalid=(value,label)=>must(rejected(value)&&typeof value.error?.message==="string"&&
 same(value.error,get("PsKernelError").rejectedInvalid(value.error.message)),label);
const N=get("PsKernelName"),E=get("PsKernelExpr"),L=get("PsKernelLevel"),Literal=get("PsKernelLiteral");
const S=get("PsKernelDefinitionSafety"),H=get("PsKernelReducibilityHints");
const D=get("PsKernelDagDeclarationRequest"),Request=get("PsKernelDeclarationRequest"),C=get("PsKernelDagCommand");
const name=text=>N.str(unit(N.anonymous),text);
const level=n=>{let value=unit(L.zero);for(let i=0;i<n;i++)value=L.succ(value);return value;};
const fromList=get("psKernelExprV2WhnfCacheFromList"),insert=get("psKernelExprV2WhnfCacheInsert");
const lookup=get("psKernelExprV2WhnfCacheLookup"),entries=get("psKernelExprV2WhnfCacheEntries");
const cacheEmpty=unit(get("psKernelExprV2WhnfCacheEmpty"));
const indexed=cache=>!same(cache.index,none)&&same(cache.small,nil);
const caches=state=>[state.whnf.coreCache,state.whnf.publicCache,state.checkedInfer,state.inferOnly,state.unfold];
const exact=(a,b)=>get("psKernelExprEqual")(a)(b);
const decode=(state,root)=>accepted(get("psKernelExprV2DecodedRequire")(
 accepted(get("psKernelExprV2DecodeChecked")(state.whnf.arena),"decode"),root),"decoded-root");
const compareResult=(label,original,actual)=>{
 const observed=accepted(actual,label+"-some");
 if(rejected(original)){must(rejected(observed)&&original.error===observed.error,label+"-exact-error");return;}
 const a=accepted(original,label+"-reference"),b=accepted(observed,label+"-actual");
 must(exact(a.fst,decode(b.fst,b.snd)),label+"-expression");
 must(a.snd.nextFresh===b.fst.nextFresh,label+"-fresh-counter");
};
let arena=unit(get("psKernelExprV2PagedEmpty"));
const build=(kind,term,...args)=>{
 const result=accepted(get("psKernelExprV2PagedMk"+kind)(arena,...args),"build-"+kind);
 arena=result.fst;return {id:result.snd,term};
};
const sort=n=>build("Sort",E.sort(level(n)),level(n));
const bv=i=>build("BVar",E.bvar(i),i);
const cn=n=>build("Const",E.const(n,nil),n,nil);
const letE=(n,t,v,b)=>build("Let",E.letE(n,t.term,v.term,b.term,false),n,t.id,v.id,b.id,false);
const emptySession=()=>accepted(get("psKernelKernelSessionEmpty")(
 get("psKernelResourcePolicyDefault"),get("psKernelProviderDefault")),"empty-session");

{
 const s0=sort(0),s1=sort(1),s2=sort(2),b0=bv(0n);
 const left=letE(name("x"),s1,s0,b0).id,equal=letE(name("y"),s1,s0,b0).id;
 const right=letE(name("x"),s2,s1,b0).id,missing=arena.size+5n;
 must(left!==equal&&accepted(get("psKernelExprV2PagedEqOnCanonical")(arena,left,equal),"alpha"),"distinct-alpha-equal-source-ids");
 let comparisons=0;
 for(const size of [0,1,7,8,9,16,64,128])for(const pattern of [0,1,2,3]){
  const rows=[];let incremental=cacheEmpty;
  for(let i=0;i<size;i++){
   const j=BigInt(i),hash=pattern===0?1000n+j:pattern===1?23n:
    pattern===2?23n+65536n*j:i%3===0?23n:1000n+j;
   const source=[left,right,equal,missing,left][i%5];
   const entry={source,result:i%2===0?left:right,hash};
   rows.unshift(entry);incremental=insert(incremental,entry);
  }
  const oldRows=list(rows),built=fromList(oldRows);
  must((!same(built.index,none))===(size>8),"promotion-boundary-from-list");
  must((!same(incremental.index,none))===(size>8),"promotion-boundary-incremental");
  must(size<=8||(indexed(built)&&indexed(incremental)),"promotion-drops-flat-mirror");
  must(array(entries(built)).length===size&&array(entries(incremental)).length===size,"publication-count-preserved");
  for(const source of [left,right,equal,missing])
   for(const hash of [23n,24n,1000n,1001n,1000n+BigInt(size),65559n,
    23n+65536n*BigInt(size),1000000000000000000000000000023n]){
    const original=get("psKernelExprV2WhnfCacheFindWorker")(oldRows,arena,source,hash);
    must(same(original,get("psKernelExprV2WhnfCacheFindIn")(oldRows)(arena)(source)(hash)),"original-curried-scanner");
    must(same(original,lookup(built,arena,source,hash)),"from-list-exact-result");
    must(same(original,lookup(incremental,arena,source,hash)),"incremental-exact-result");
    comparisons++;
   }
 }
 const filler=Array.from({length:8},(_,i)=>({source:missing,result:right,hash:100000n+BigInt(i)}));
 const row=(source,result,hash)=>({source,result,hash});
 const cases=[
  ["latest-duplicate-wins",[row(left,right,23n),row(left,left,23n)],left,Ex.ok(Option.some(right))],
  ["first-error-before-later-hit",[row(missing,right,23n),row(left,left,23n)],left,Ex.error("PSKERNEL_V2_PAIR_CHECK_INVALID_LEFT")],
  ["first-hit-before-older-error",[row(left,left,23n),row(missing,right,23n)],left,Ex.ok(Option.some(left))],
  ["equal-hash-needs-exact-equality",[row(right,right,23n)],left,Ex.ok(none)],
  ["full-hash-alias-skips-invalid-node",[row(missing,right,65559n),row(left,left,23n)],left,Ex.ok(Option.some(left))],
  ["invalid-query-still-errors",[row(left,right,23n)],missing,Ex.error("PSKERNEL_V2_PAIR_CHECK_INVALID_RIGHT")],
  ["mismatched-hash-does-not-require-node",[row(missing,right,24n)],missing,Ex.ok(none)]
 ];
 for(const [label,head,query,expected] of cases){
  const rows=list([...head,...filler]),cache=fromList(rows);
  must(indexed(cache),label+"-actually-indexed");
  must(same(expected,lookup(cache,arena,query,23n)),label);
  must(same(expected,get("psKernelExprV2WhnfCacheFindWorker")(rows,arena,query,23n)),label+"-old-scanner");
 }
 const old=fromList(list([row(left,left,23n),...filler])),next=insert(old,row(left,right,23n));
 must(same(Ex.ok(Option.some(left)),lookup(old,arena,left,23n)),"old-snapshot-unmodified");
 must(same(Ex.ok(Option.some(right)),lookup(next,arena,left,23n)),"new-snapshot-newest-result");
 must(comparisons===1024,"raw-matrix-count");
 console.log("PSC1_V2_INDEXED_CACHE_RAW_PASS comparisons=1024 adversarial=7 snapshots=2");
}

arena=unit(get("psKernelExprV2PagedEmpty"));
const empty=emptySession(),fixtures=[],requests=[];
let originalSession=empty;
for(let i=0;i<9;i++){
 const n=name("IndexedCacheAlias"+i),type=sort(i+1),value=sort(i),term=cn(n);
 const letTerm=letE(name("x"),type,value,bv(0n));
 fixtures.push({root:term.id,letRoot:letTerm.id,type:type.id,value:value.id,term:term.term,letTerm:letTerm.term});
 requests.push(D.definitionDecl({base:{name:n,levelParams:nil,type:type.id},
  value:value.id,hints:unit(H.abbrevHint),safety:unit(S.safe)}));
 originalSession=accepted(get("psKernelV1AdmitDeclaration")(originalSession,
  Request.definitionDecl({base:{name:n,levelParams:nil,type:type.term},
   value:value.term,hints:unit(H.abbrevHint),safety:unit(S.safe)})),"reference-admit").session;
}
const canonical=accepted(get("psKernelExprV2PagedValidate")(arena),"canonical");
const built=accepted(get("psKernelExprV2DecodeChecked")(canonical),"canonical-decode");
const batch=accepted(get("psKernelV1RunDag")(empty,nil,unit(S.safe),canonical,
 list(requests.map(request=>C.admit(request)))),"public-batch");
must(array(batch.replies).length===9&&get("psKernelEnvironmentSize")(batch.session.environment)===9n&&
 get("psKernelEnvironmentSize")(originalSession.environment)===9n,"public-batch-nine-real-admissions");
let execution={session:empty,declarations:nil};
for(const request of requests)
 execution=accepted(get("psKernelDagRunCommand")(execution,nil,unit(S.safe),canonical,built,C.admit(request)),"command-admit").snd;
const first=fixtures[0],badName=name("IndexedCacheBad");
const badRequest=D.definitionDecl({base:{name:badName,levelParams:nil,type:first.value},
 value:first.value,hints:unit(H.abbrevHint),safety:unit(S.safe)});
invalid(get("psKernelV1RunDag")(empty,nil,unit(S.safe),canonical,list([C.admit(badRequest)])),"public-batch-invalid-refused");
invalid(get("psKernelV1AdmitDeclaration")(empty,
 Request.definitionDecl({base:{name:badName,levelParams:nil,type:E.sort(level(0))},
  value:E.sort(level(0)),hints:unit(H.abbrevHint),safety:unit(S.safe)})),"reference-invalid-refused");
invalid(get("psKernelV1RunDag")(empty,nil,unit(S.safe),canonical,list([C.check(first.root)])),
 "fresh-public-operation-cannot-import-owner");
const scalar=get("psKernelKernelSessionChecker")(execution.session,nil,unit(S.safe)).context;
const context=get("psKernelExprV2CheckContextEmpty")(scalar);
let state=get("psKernelExprV2CheckStateWithWhnf")(get("psKernelExprV2CheckStateEmpty")(canonical),
 get("psKernelExprV2WhnfStateForDeclarations")(canonical,execution.declarations));
let original=unit(get("psKernelCheckerStateEmpty")),parent=state;
const check=get("psKernelExprV2TryCheckStateWithFuel"),infer=get("psKernelExprV2TryInferStateWithFuel");
const oldCheck=get("psKernelCheckerCheck"),oldInfer=get("psKernelCheckerInfer");
const defeq=fuel=>get("psKernelExprV2TryDefEqStateWithFuel")(fuel);
const oldDefeq=fuel=>get("psKernelIsDefEqWithFuel")(fuel);
const core=(fuel,c,s,r,cheap=false)=>get("psKernelExprV2CheckWhnfCoreOwnedWithFuel")(fuel,defeq(fuel),c,s,r,cheap);
const publicWhnf=(fuel,c,s,r)=>get("psKernelExprV2CheckWhnfOwnedWithFuel")(fuel,defeq(fuel),c,s,r);
const oldCore=(fuel,c,s,r)=>get("psKernelWhnfCoreWithRecursorFuel")(fuel,oldDefeq(fuel),c,s,r,false,false);
const oldPublic=(fuel,c,s,r)=>get("psKernelWhnfWithRecursorFuel")(fuel,oldDefeq(fuel),c,s,r);
for(let i=0;i<fixtures.length;i++){
 const fixture=fixtures[i];if(i===8)parent=state;
 const checkedOld=accepted(oldCheck(64n,scalar,original,fixture.term),"warm-checked-old");
 const checked=attempt(check(64n,context,state,fixture.root),"warm-checked");
 compareResult("warm-checked",Ex.ok(checkedOld),ok(checked.fst,checked.snd));
 const inferredOld=accepted(oldInfer(64n,scalar,checkedOld.snd,fixture.term),"warm-infer-old");
 const inferred=attempt(infer(64n,context,checked.fst,fixture.root),"warm-infer-only");
 compareResult("warm-infer-only",Ex.ok(inferredOld),ok(inferred.fst,inferred.snd));
 const coreOld=accepted(oldCore(64n,scalar,inferredOld.snd,fixture.letTerm),"warm-core-old");
 const reducedCore=attempt(core(64n,context,inferred.fst,fixture.letRoot),"warm-core");
 compareResult("warm-core",Ex.ok(coreOld),ok(reducedCore.fst,reducedCore.snd));
 const publicOld=accepted(oldPublic(64n,scalar,coreOld.snd,fixture.letTerm),"warm-public-old");
 const reduced=attempt(publicWhnf(64n,context,reducedCore.fst,fixture.letRoot),"warm-public");
 compareResult("warm-public",Ex.ok(publicOld),ok(reduced.fst,reduced.snd));
 const unfolded=attempt(get("psKernelExprV2DefEqUnfold")(context,reduced.fst,fixture.root),"warm-unfold");
 const value=accepted(unfolded.snd,"warm-unfold-value");
 must(accepted(get("psKernelExprV2PagedEqOnCanonical")(unfolded.fst.whnf.arena,value,fixture.value),"unfold-equality"),"real-unfold-body");
 state=unfolded.fst;original=publicOld.snd;
}
must(caches(state).every(indexed),"all-five-real-caches-promoted");
must(caches(parent).every(cache=>same(cache.index,none)&&array(cache.small).length===8),"all-five-eight-entry-parents-still-small");
must(caches(state).every(cache=>array(entries(cache)).length===9),"all-five-nine-entry-publications");
must(get("psKernelResourcePolicyDefault").fuel===4096n,"published-fuel-unchanged");
console.log("PSC1_V2_INDEXED_CACHE_REAL_PASS publicPositive=9 publicNegative=1 referencePositive=9 referenceNegative=1 caches=5 entries=9 official=native-gate");
const warm=state,chosen=fixtures.at(-1);

{
 let comparisons=0;
 for(const fuel of [0n,1n,64n])for(const depth of [0n,15n,16n]){
  const limited={...scalar,maxRecDepth:1n,recDepth:depth};
  const ctx=get("psKernelExprV2CheckContextEmpty")(limited);
  compareResult("indexed-checked-guards",oldCheck(fuel,limited,original,chosen.term),check(fuel,ctx,warm,chosen.root));
  compareResult("indexed-infer-only-guards",oldInfer(fuel,limited,original,chosen.term),infer(fuel,ctx,warm,chosen.root));
  compareResult("indexed-core-guards",oldCore(fuel,limited,original,chosen.letTerm),core(fuel,ctx,warm,chosen.letRoot));
  compareResult("indexed-public-guards",oldPublic(fuel,limited,original,chosen.letTerm),publicWhnf(fuel,ctx,warm,chosen.letRoot));
  comparisons+=4;
 }
 const owning=warm.whnf.arena,missing=owning.size+999n;
 const missingResult=get("psKernelExprV2PagedRequire")(owning,missing);
 must(rejected(missingResult)&&typeof missingResult.error==="string","missing-source-control");
 const missingError=missingResult.error;
 const aliasEntry=accepted(get("psKernelExprV2PagedRequire")(owning,chosen.root),"alias-entry");
 const letEntry=accepted(get("psKernelExprV2PagedRequire")(owning,chosen.letRoot),"let-entry");
 const poison=(cache,hash)=>insert(cache,{source:missing,result:chosen.value,hash});
 const poisoned={...warm,whnf:{...warm.whnf,
  coreCache:poison(warm.whnf.coreCache,letEntry.hash),publicCache:poison(warm.whnf.publicCache,letEntry.hash)},
  checkedInfer:poison(warm.checkedInfer,aliasEntry.hash),inferOnly:poison(warm.inferOnly,aliasEntry.hash),
  unfold:poison(warm.unfold,aliasEntry.hash)};
 must(caches(poisoned).every(indexed),"all-poison-controls-use-index");
 const exhausted={...context,scalar:{...scalar,maxRecDepth:1n,recDepth:get("psKernelRecDepthFactor")}};
 const fixedDefEq=defeq(64n),fixedWhnf=c=>s=>r=>publicWhnf(64n,c,s,r);
 const inferenceCore=(fuel,c,s,r,mode)=>
  get("psKernelExprV2TryInferCoreOwnedWithFuel")(fuel)(fixedWhnf)(fixedDefEq)(c)(s)(r)(mode);
 const depthError="deep recursion detected, use maxRecDepth to increase the limit";
 const pairError="PSKERNEL_V2_PAIR_CHECK_INVALID_LEFT";
 for(const mode of [false,true]){
  errorIs("indexed-inference-zero-before-source","kernel inference budget exhausted",
   inferenceCore(0n,exhausted,poisoned,missing,mode));
  errorIs("indexed-inference-cache-error-before-depth",pairError,
   inferenceCore(64n,exhausted,poisoned,chosen.root,mode));
  errorIs("indexed-inference-source-error-before-cache-and-depth",missingError,
   inferenceCore(64n,exhausted,poisoned,missing,mode));
 }
 errorIs("indexed-core-zero-before-source","kernel reduction budget exhausted",core(0n,exhausted,poisoned,missing));
 errorIs("indexed-core-depth-before-cache",depthError,core(64n,exhausted,poisoned,chosen.letRoot));
 errorIs("indexed-core-depth-before-source",depthError,core(64n,exhausted,poisoned,missing));
 errorIs("indexed-core-reports-cache-error",pairError,core(64n,context,poisoned,chosen.letRoot));
 errorIs("indexed-core-reports-source-error",missingError,core(64n,context,poisoned,missing));
 errorIs("indexed-public-zero-before-source","kernel reduction budget exhausted",publicWhnf(0n,exhausted,poisoned,missing));
 errorIs("indexed-public-existing-cache-order",pairError,publicWhnf(64n,exhausted,poisoned,chosen.letRoot));
 errorIs("indexed-public-source-before-cache",missingError,publicWhnf(64n,exhausted,poisoned,missing));
 errorIs("indexed-unfold-reports-cache-error",pairError,get("psKernelExprV2DefEqUnfold")(context,poisoned,chosen.root));
 errorIs("indexed-unfold-source-before-cache",missingError,get("psKernelExprV2DefEqUnfold")(context,poisoned,missing));
 const cheap=attempt(core(1n,context,warm,chosen.letRoot,true),"indexed-cheap-cache-hit");
 must(array(entries(cheap.fst.whnf.coreCache)).length===9&&array(entries(cheap.fst.whnf.publicCache)).length===9,
  "indexed-cheap-hit-does-not-publish");
 const childArena=accepted(get("psKernelExprV2PagedMkLit")(owning,Literal.nat(987654n)),"scope-arena").fst;
 const child=get("psKernelExprV2CheckStateFreshName")(
  get("psKernelExprV2CheckStateWithArena")(warm,childArena),name("indexed")).snd;
 const restored=get("psKernelExprV2CheckStateExitLocalScope")(parent,child);
 must(caches(restored).every(cache=>same(cache.index,none)&&array(cache.small).length===8),
  "indexed-scope-restores-eight-entry-parents");
 must(restored.whnf.arena.size===childArena.size&&restored.nextFresh===child.nextFresh,
  "indexed-scope-retains-child-arena-and-fresh");
 for(const [before,after,root] of [
  [warm.whnf.coreCache,restored.whnf.coreCache,chosen.letRoot],
  [warm.whnf.publicCache,restored.whnf.publicCache,chosen.letRoot],
  [warm.checkedInfer,restored.checkedInfer,chosen.root],
  [warm.inferOnly,restored.inferOnly,chosen.root],
  [warm.unfold,restored.unfold,chosen.root]]){
  const entry=accepted(get("psKernelExprV2PagedRequire")(childArena,root),"scoped-source");
  must(!same(accepted(lookup(before,childArena,root,entry.hash),"scoped-before"),none),
   "indexed-child-publication-exists");
  must(same(Ex.ok(none),lookup(after,childArena,root,entry.hash)),
   "indexed-child-publication-does-not-escape-scope");
 }
 const fresh=get("psKernelExprV2CheckStateEmpty")(childArena);
 must(caches(fresh).every(cache=>same(cache.index,none)&&same(cache.small,nil)),"fresh-owner-all-five-empty");
 must(comparisons===36,"resource-matrix-count");
 console.log("PSC1_V2_INDEXED_CACHE_RESOURCE_PASS reference=36 precedence=16 scope=5");
}

{
 const modulus=BigInt(get("psKernelCacheHashModulus"));
 const markerHash=(tag,index)=>modulus+1000n+16n*tag+index;
 const markerCache=(owning,cache,key,tag)=>{
  const rows=array(entries(cache));
  if(!indexed(cache)||rows.length!==9||!rows.every(row=>row.source===key))return false;
  return Array.from({length:9},(_,i)=>BigInt(i)).every(i=>{
   const found=lookup(cache,owning,key,markerHash(tag,i));
   if(rejected(found)||same(found.value,none)||typeof found.value?.value!=="bigint")return false;
   const entry=get("psKernelExprV2PagedRequire")(owning,found.value.value);
   return !rejected(entry)&&same(entry.value.node,get("PsKernelExprV2Node").lit(Literal.nat(9000n+tag)));
  });
 };
 const pairMarker=(pairs,key,tag)=>{
  const rows=array(pairs);
  return rows.length===1&&rows[0].left===key&&rows[0].right===key&&rows[0].hash===markerHash(tag,0n);
 };
 const marked=(owner,key,tag,fresh)=>owner.nextFresh===fresh&&
  caches(owner).every(cache=>markerCache(owner.whnf.arena,cache,key,tag))&&
  pairMarker(owner.success,key,tag)&&pairMarker(owner.failure,key,tag)&&
  !same(get("psKernelExprV2DeclarationRefFind")(owner.whnf.declarations)(name("IndexedCacheAlias8")),none);
 const stamp=(owner,key,tag)=>{
  const built=accepted(get("psKernelExprV2PagedMkLit")(owner.whnf.arena,Literal.nat(9000n+tag)),"marker-build");
  const cache=fromList(list(Array.from({length:9},(_,i)=>({
   source:key,result:built.snd,hash:markerHash(tag,BigInt(i))}))));
  const pairs=list([{left:key,right:key,hash:markerHash(tag,0n)}]);
  return {whnf:{arena:built.fst,coreCache:cache,publicCache:cache,declarations:owner.whnf.declarations},
   nextFresh:tag,checkedInfer:cache,success:pairs,inferOnly:cache,unfold:cache,failure:pairs};
 };
 const markedCallback=(key,input,output,tag,failAt,decline)=>_ctx=>owner=>root=>{
  if(root!==input||!marked(owner,key,tag,tag))return Option.some(Ex.error("INDEXED_CALLBACK_STALE_STATE"));
  if(failAt===tag+1n)return decline?none:Option.some(Ex.error("INDEXED_CALLBACK_INJECTED"));
  return ok(stamp(owner,key,tag+1n),output);
 };
 const key=chosen.root,builtProp=accepted(get("psKernelExprV2PagedMkSort")(warm.whnf.arena,unit(L.zero)),"marker-prop");
 const prop=builtProp.snd,initial=stamp(get("psKernelExprV2CheckStateWithArena")(warm,builtProp.fst),key,20n);
 must(marked(initial,key,20n,20n),"all-five-callback-inputs-indexed");
 let callbacks=0;
 for(const helper of [get("psKernelExprV2DefEqIsPropOwnedWith"),get("psKernelExprV2CheckProjectionIsPropOwnedWith")])
  for(const [failAt,decline] of [[0n,false],[21n,false],[21n,true],[22n,false],[22n,true]]){
   const result=helper(markedCallback(key,key,prop,20n,failAt,decline),
    markedCallback(key,prop,prop,21n,failAt,decline),context,initial,key);
   if(failAt===0n){
    const reduced=attempt(result,"indexed-callback-chain");
    must(marked(reduced.fst,key,22n,22n)&&reduced.snd===true,"all-five-callback-outputs-indexed");
   }else if(decline)must(same(result,none),"indexed-callback-decline-propagates");
   else errorIs("indexed-callback-error-propagates","INDEXED_CALLBACK_INJECTED",result);
   callbacks++;
  }
 const child=stamp(initial,key,21n),restored=get("psKernelExprV2CheckStateExitLocalScope")(initial,child);
 must(marked(restored,key,20n,21n),"indexed-parent-restored-from-indexed-child");
 must(marked(initial,key,20n,20n),"indexed-parent-snapshot-unchanged");
 must(marked(child,key,21n,21n),"indexed-child-snapshot-unchanged");
 const lifted=attempt(get("psKernelExprV2LiftWhnfAttempt")(initial,ok(child.whnf,prop)),"indexed-compatibility-lift");
 must(markerCache(lifted.fst.whnf.arena,lifted.fst.whnf.coreCache,key,21n)&&
  markerCache(lifted.fst.whnf.arena,lifted.fst.whnf.publicCache,key,21n),"indexed-lift-uses-returned-whnf");
 must([lifted.fst.checkedInfer,lifted.fst.inferOnly,lifted.fst.unfold].every(
  cache=>markerCache(lifted.fst.whnf.arena,cache,key,20n))&&lifted.fst.nextFresh===20n&&
  pairMarker(lifted.fst.success,key,20n)&&pairMarker(lifted.fst.failure,key,20n),
  "indexed-lift-preserves-three-other-cache-owners");
 must(callbacks===10,"callback-matrix-count");
 console.log("PSC1_V2_INDEXED_CACHE_CALLBACK_PASS cases=10 caches=5 entries=9");
}
console.log("PSC1_V2_INDEXED_CACHE_PASS assertions="+assertions);
