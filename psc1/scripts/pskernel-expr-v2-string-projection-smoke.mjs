import {pathToFileURL} from "node:url";
import path from "node:path";

// Raw String reduction is separate from checked ordinary-structure controls.
// No String/ByteArray metadata or declaration closure is fabricated here.
const filename=process.argv[2];
if(!filename)throw Error("PSC1_STRING_PROJECTION_REQUIRES_GENERATED_KERNEL");
const k=await import(pathToFileURL(path.resolve(filename)).href);
const get=name=>{if(!(name in k))throw Error("PSC1_STRING_PROJECTION_MISSING_EXPORT "+name);return k[name];};
const unit=x=>typeof x==="function"?x():x;
let assertions=0;
const must=(condition,label)=>{if(condition!==true)throw Error("PSC1_STRING_PROJECTION_FAIL "+label);assertions++;};
const accepted=(x,label)=>{
 if(x&&typeof x==="object"&&Object.hasOwn(x,"value"))return x.value;
 const error=x&&typeof x==="object"&&Object.hasOwn(x,"error")?x.error:null;
 throw Error("PSC1_STRING_PROJECTION_UNEXPECTED_REJECTION "+label+": "+
  (typeof error==="string"?error:error?.message??"missing accepted value"));
};
const rejected=x=>Boolean(x&&typeof x==="object"&&Object.hasOwn(x,"error"));
const same=(left,right)=>{
 if(left===right)return true;
 if(left===null||right===null||typeof left!=="object"||typeof right!=="object")return false;
 const keys=Reflect.ownKeys(left),others=Reflect.ownKeys(right);
 return keys.length===others.length&&keys.every(key=>Object.hasOwn(right,key)&&same(left[key],right[key]));
};
const List=get("List"),nil=unit(List.nil),Option=get("Option"),none=unit(Option.none),Ex=get("Except");
const list=xs=>xs.reduceRight((tail,head)=>List.cons(head,tail),nil);
const array=xs=>{const out=[];while(xs&&Object.hasOwn(xs,"head")){out.push(xs.head);xs=xs.tail;}return out;};
const N=get("PsKernelName"),E=get("PsKernelExpr"),L=get("PsKernelLevel"),B=get("PsKernelBinderInfo");
const Literal=get("PsKernelLiteral"),S=get("PsKernelDefinitionSafety"),safe=unit(S.safe);
const Request=get("PsKernelDeclarationRequest"),D=get("PsKernelDagDeclarationRequest"),C=get("PsKernelDagCommand");
const name=value=>N.str(unit(N.anonymous),value),one=L.succ(unit(L.zero));
let arena=get("psKernelExprV2PagedEmpty");
const build=(kind,term,...args)=>{
 const result=accepted(get("psKernelExprV2PagedMk"+kind)(arena,...args),"build-"+kind);
 arena=result.fst;return {term,id:result.snd};
};
const cn=n=>build("Const",E.const(n,nil),n,nil);
const sort=l=>build("Sort",E.sort(l),l);
const bv=n=>build("BVar",E.bvar(n),n);
const app=(f,a)=>build("App",E.app(f.term,a.term),f.id,a.id);
const lam=(n,t,b)=>build("Lam",E.lam(name(n),t.term,b.term,unit(B.default)),name(n),t.id,b.id,unit(B.default));
const forall=(n,t,b)=>build("Forall",E.forallE(name(n),t.term,b.term,unit(B.default)),name(n),t.id,b.id,unit(B.default));
const natLit=n=>build("Lit",E.lit(Literal.nat(n)),Literal.nat(n));
const strLit=value=>build("Lit",E.lit(Literal.str(value)),Literal.str(value));
const proj=(n,index,major)=>build("Proj",E.proj(n,index,major.term),n,index,major.id);
const letE=(n,t,v,b)=>build("Let",E.letE(name(n),t.term,v.term,b.term,false),name(n),t.id,v.id,b.id,false);
const exact=(a,b)=>get("psKernelExprEqual")(a)(b);
const decoded=(owned,root)=>accepted(get("psKernelExprV2DecodedRequire")(
 accepted(get("psKernelExprV2DecodeChecked")(owned),"decode"),root),"decoded-root");
const empty=accepted(get("psKernelKernelSessionEmpty")(
 get("psKernelResourcePolicyDefault"),get("psKernelProviderDefault")),"empty");
let session=empty,declarations=nil;
const commands=[];
const inductive=(n,type,ctors)=>{
 session=accepted(get("psKernelV1AdmitDeclaration")(session,Request.ordinaryInductive({
  levelParams:nil,name:n,type:type.term,ctors:list(ctors.map(([name,type])=>({name,type:type.term}))),
  isUnsafe:false,numParams:0n})),"checked-inductive").session;
 const request=D.ordinaryInductive(nil,0n,
  {name:n,type:type.id,ctors:list(ctors.map(([name,type])=>({name,type:type.id})))},false);
 declarations=get("psKernelDagDeclarationsAfterAdmission")(request,declarations);
 commands.push(C.admit(request));
};
const natName=get("psKernelNatName"),stringName=get("psKernelStringName");
const nat=cn(natName),s1=sort(one);
inductive(natName,s1,[[get("psKernelNatZeroName"),nat],
 [get("psKernelNatSuccName"),forall("n",nat,nat)]]);
const boxName=name("StringProjectionBox"),boxCtor=N.str(boxName,"mk"),box=cn(boxName);
inductive(boxName,s1,[[boxCtor,forall("left",nat,forall("right",nat,box))]]);
const preparedArena=arena,scalar=get("psKernelKernelSessionChecker")(session,nil,safe).context;
const context=c=>get("psKernelExprV2CheckContextEmpty")(c);
const initial=owned=>get("psKernelExprV2CheckStateFromWhnf")(
 get("psKernelExprV2WhnfStateForDeclarations")(owned,declarations));
const local=c=>n=>get("psKernelExprV2CheckLocalValue")(c,n);
const oldEq=get("psKernelIsDefEqWithFuel"),dagEq=get("psKernelExprV2TryDefEqStateWithFuel");
const oldEmpty=get("psKernelCheckerStateEmpty");
const ok=(state,root)=>Option.some(Ex.ok({fst:state,snd:root}));
const error=message=>Option.some(Ex.error(message));
const compare=(reference,actual,label)=>{
 const attempted=accepted(actual,label+"-some");
 if(rejected(reference)){must(rejected(attempted)&&attempted.error===reference.error,label+"-exact-error");return;}
 const a=accepted(reference,label+"-reference"),b=accepted(attempted,label+"-result");
 must(a.snd.nextFresh===b.fst.nextFresh,label+"-fresh-counter");
 must(exact(a.fst,decoded(b.fst.whnf.arena,b.snd)),label+"-expression");
};
const values=["","a","é","e\u0301","🙂","a\u0000β"];
const oldNoRec=_c=>state=>_term=>_cr=>_cp=>Ex.ok({fst:none,snd:state});
const newNoRec=_c=>state=>_root=>_cr=>_cp=>ok(state,none);
let publics=0,cores=0,fixed=0;
for(const value of values){
 arena=preparedArena;
 const term=proj(stringName,0n,strLit(value)),input=arena;
 for(const fuel of [0n,1n,2n,3n,8n,32n,64n])
  for(const [maxRecDepth,recDepth] of [[0n,0n],[1n,15n],[1n,16n]]){
   const oldContext={...scalar,maxRecDepth,recDepth},c=context(oldContext);
   compare(get("psKernelWhnfWithRecursorFuel")(fuel,oldEq(fuel),oldContext,oldEmpty,term.term),
    get("psKernelExprV2TryWhnfCheckStateWithFuel")(fuel,c,initial(input),term.id),"String-public");
   publics++;
   for(const cheapRec of [false,true])for(const cheapProj of [false,true]){
    compare(get("psKernelWhnfCoreWithRecursorFuel")(
     fuel,oldEq(fuel),oldContext,oldEmpty,term.term,cheapRec,cheapProj),
     get("psKernelExprV2TryWhnfCoreOwnedWithLocalValuesFuel")(
      fuel,dagEq(fuel),local,c,initial(input),term.id,cheapRec,cheapProj),"String-core");
    cores++;
   }
  }
 for(const structuralFuel of [0n,1n,2n,4n,16n])for(const callbackFuel of [0n,1n,2n,8n]){
  const oldPublic=c=>s=>r=>get("psKernelWhnfWithRecursorFuel")(callbackFuel,oldEq(callbackFuel),c,s,r);
  const newPublic=c=>s=>r=>get("psKernelExprV2TryWhnfCheckStateWithFuel")(callbackFuel,c,s,r);
  for(const cheapRec of [false,true])for(const cheapProj of [false,true]){
   compare(get("psKernelWhnfCoreWithFuel")(structuralFuel)(oldPublic)(oldNoRec)(
    scalar)(oldEmpty)(term.term)(cheapRec)(cheapProj),
    get("psKernelExprV2TryWhnfCoreOwnedModeWithReducerFuel")(structuralFuel)(
     cheapRec)(cheapProj)(local)(newPublic)(newNoRec)(context(scalar))(initial(input))(term.id),
    "String-fixed-public-owner");
   fixed++;
  }
 }
}
must(publics===126&&cores===504&&fixed===480,"String-resource-matrix-counts");
console.log("PSC1_V2_DAG_STRING_PROJECTION_MATRIX_JS: PASS public=126 core=504 fixed=480");

const modulus=BigInt(get("psKernelCacheHashModulus"));
const tagRows=(rows,tag)=>{const xs=array(rows);return xs.length===1&&BigInt(xs[0].hash)===modulus+tag;};
const arenaTag=(state,tag)=>{
 const rows=array(state.checkedInfer);
 if(rows.length!==1)return false;
 const found=get("psKernelExprV2PagedRequire")(state.whnf.arena,rows[0].result);
 return !rejected(found)&&same(accepted(found,"String-marker").node,
  get("PsKernelExprV2Node").lit(Literal.nat(14000n+tag)));
};
const tagged=(state,tag)=>state.nextFresh===tag&&tagRows(state.checkedInfer,tag)&&
 tagRows(state.success,tag)&&tagRows(state.inferOnly,tag)&&tagRows(state.unfold,tag)&&
 tagRows(state.failure,tag)&&arenaTag(state,tag);
const stamp=(key,state,tag)=>{
 const made=accepted(get("psKernelExprV2PagedMkLit")(state.whnf.arena,Literal.nat(14000n+tag)),"String-stamp");
 const cache={source:key,result:made.snd,hash:modulus+tag},pair={left:key,right:key,hash:modulus+tag};
 return {whnf:{arena:made.fst,coreCache:List.cons(cache,state.whnf.coreCache),
  publicCache:List.cons(cache,state.whnf.publicCache),declarations:state.whnf.declarations},
  nextFresh:tag,checkedInfer:list([cache]),success:list([pair]),inferOnly:list([cache]),
  unfold:list([cache]),failure:list([pair])};
};
const markStep=(failAt,decline,state,key,result,tag)=>{
 if(!tagged(state,tag))return error("STRING_PROJECTION_STALE_STATE");
 if(failAt===tag+1n-20n)return decline?none:error("STRING_PROJECTION_INJECTED");
 return ok(stamp(key,state,tag+1n),result);
};
let probes=0,propagated=0;
for(const value of values){
 arena=preparedArena;
 const left=natLit(7n),right=natLit(11n),constructed=app(app(cn(boxCtor),left),right),literal=strLit(value);
 const built=accepted(get("psKernelExprV2StringLitToConstructorOnCanonical")(arena,value),"String-expansion");
 arena=built.fst;
 const expectedExpansion=built.snd;
 must(exact(get("psKernelStringLitToConstructor")(value),decoded(arena,expectedExpansion)),
  "String-exact-constructor");
 for(const index of [0n,1n,2n,BigInt(get("psKernelLeanUInt32Max"))+1n]){
  // These mock callbacks test raw ordering, not admission of this ill-typed source.
  const term=proj(boxName,index,literal),input=arena,seeded=stamp(literal.id,initial(input),20n);
  must(!tagged({...seeded,whnf:{...seeded.whnf,arena:input}},20n),"String-arena-loss-marker");
  const selected=index===0n?left.id:right.id,hasField=index<2n;
  for(const cheapProj of [false,true]){
   const run=(failAt,decline)=>{
    const recurse=_c=>state=>root=>{
     if(state.nextFresh===20n&&cheapProj&&root===literal.id)
      return markStep(failAt,decline,state,literal.id,literal.id,20n);
     if(state.nextFresh===22n&&hasField&&root===selected)
      return markStep(failAt,decline,state,selected,selected,22n);
     return error("STRING_PROJECTION_RECURSE_ORDER");
    };
    const publicWhnf=_c=>state=>root=>{
     if(state.nextFresh===20n&&!cheapProj&&root===literal.id)
      return markStep(failAt,decline,state,literal.id,literal.id,20n);
     if(state.nextFresh===21n){
      const equal=get("psKernelExprV2PagedEqOnCanonical")(state.whnf.arena,root,expectedExpansion);
      if(rejected(equal))return error(equal.error);
      return accepted(equal,"String-constructor-equality")?
       markStep(failAt,decline,state,root,constructed.id,21n):error("STRING_PROJECTION_CONSTRUCTOR_INPUT");
     }
     return error("STRING_PROJECTION_PUBLIC_ORDER");
    };
    return get("psKernelExprV2TryWhnfProjectionOwnedWith")(
     recurse,publicWhnf,context(scalar),seeded,term.id,boxName,index,literal.id,cheapProj);
   };
   const result=accepted(accepted(run(0n,false),"String-state-some"),"String-state-ok");
   const finalTag=hasField?23n:22n,finalRoot=hasField?selected:term.id;
   must(tagged(result.fst,finalTag),"String-all-fields-and-arena");
   must(result.snd===finalRoot,"String-selected-or-original-root");
   must(array(result.fst.whnf.coreCache).some(row=>BigInt(row.hash)===modulus+finalTag),
    "String-core-marker-retained");
   must(array(result.fst.whnf.publicCache).some(row=>BigInt(row.hash)===modulus+finalTag),
    "String-public-marker-retained");
   const sourceEntry=accepted(get("psKernelExprV2PagedRequire")(result.fst.whnf.arena,term.id),"String-original");
   const cached=accepted(get("psKernelExprV2WhnfCacheFind")(result.fst.whnf,term.id,sourceEntry),"String-cache");
   must(cheapProj?same(cached,none):same(cached,Option.some(finalRoot)),"String-original-root-publication");
   accepted(get("psKernelExprV2PagedValidate")(result.fst.whnf.arena),"String-final-arena");
   probes++;
   for(const failAt of hasField?[1n,2n,3n]:[1n,2n])for(const decline of [false,true]){
    const failure=run(failAt,decline);
    if(same(failure,none))must(decline,"String-ordered-None");
    else{const result=accepted(failure,"String-failure-some");
     must(!decline&&rejected(result)&&result.error==="STRING_PROJECTION_INJECTED","String-ordered-error");}
    propagated++;
   }
  }
 }
}
must(probes===48&&propagated===240,"String-state-counts");
console.log("PSC1_V2_DAG_STRING_PROJECTION_STATE_JS: PASS cases=48 propagated=240");

const invalid=result=>rejected(result)&&typeof result.error?.message==="string"&&
 same(result.error,get("PsKernelError").rejectedInvalid(result.error.message));
arena=preparedArena;
const ctorValue=app(app(cn(boxCtor),natLit(7n)),natLit(11n));
const beta=app(lam("box",box,bv(0n)),ctorValue),zeta=letE("box",box,ctorValue,bv(0n));
const fixtures=[
 [proj(boxName,0n,ctorValue),natLit(7n)],[proj(boxName,1n,ctorValue),natLit(11n)],
 [proj(boxName,0n,beta),natLit(7n)],[proj(boxName,1n,beta),natLit(11n)],
 [proj(boxName,0n,zeta),natLit(7n)],[proj(boxName,1n,zeta),natLit(11n)]
];
const negatives=[proj(boxName,2n,ctorValue),proj(stringName,0n,ctorValue),proj(boxName,0n,cn(boxCtor))];
const checkedInput=arena,Reply=get("PsKernelDagReply");
const run=(input,command)=>get("psKernelV1RunDag")(empty,nil,safe,input,list([...commands,command]));
let valid=0,invalids=0;
for(const [term,expected] of fixtures){
 const reference=accepted(get("psKernelV1Whnf")(session,nil,safe,term.term),"checked-reference");
 const result=accepted(run(checkedInput,C.whnf(term.id)),"checked-batch"),reply=array(result.replies).at(-1);
 must(same(reply,Reply.normalized(reply.value))&&exact(reply.value,expected.term),"checked-protocol");
 must(exact(reference,expected.term),"checked-V1");
 const actual=accepted(accepted(get("psKernelExprV2TryWhnfCheckStateWithFuel")(
  4096n,context(scalar),initial(checkedInput),term.id),"checked-direct-some"),"checked-direct-ok");
 must(exact(decoded(actual.fst.whnf.arena,actual.snd),expected.term),"checked-direct-V2");
 valid++;
}
for(const term of negatives){
 const reference=get("psKernelV1Whnf")(session,nil,safe,term.term),actual=run(checkedInput,C.whnf(term.id));
 must(invalid(reference)&&invalid(actual)&&same(reference.error,actual.error),"checked-invalid-exact");
 invalids++;
}
must(valid===6&&invalids===3,"checked-projection-counts");
console.log("PSC1_V2_DAG_STRING_PROJECTION_CHECKED_JS: PASS valid=6 invalid=3");

let missingEnvironment=0;
for(const value of values)for(const index of [0n,1n,2n]){
 arena=preparedArena;
 const term=proj(stringName,index,strLit(value));
 const reference=get("psKernelV1CheckExpression")(session,nil,safe,term.term);
 const actual=run(arena,C.check(term.id));
 must(invalid(reference)&&invalid(actual)&&same(reference.error,actual.error),
  "String-missing-environment-explicit-checked-rejection");
 missingEnvironment++;
}
must(missingEnvironment===18,"String-scope-count");
console.log("PSC1_V2_DAG_STRING_PROJECTION_SCOPE_JS: PASS missingEnvironment=18");
