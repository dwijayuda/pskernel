import {pathToFileURL} from "node:url";
import path from "node:path";

// Complete private admission; public routing has a separate gate.
// Compare actual frozen V1 admission and all generated recursor metadata.
if(process.argv.length!==3)throw Error("PSC1_ORDINARY_ADMISSION_PRIVATE_REQUIRES_GENERATED_KERNEL");
const kernelPath=path.resolve(process.argv[2]),k=await import(pathToFileURL(kernelPath).href);
const get=n=>{if(!(n in k))throw Error("PSC1_ORDINARY_ADMISSION_PRIVATE_MISSING_EXPORT "+n);return k[n];};
const unit=x=>typeof x==="function"?x():x;
const List=get("List"),Option=get("Option"),Except=get("Except");
const nil=unit(List.nil),none=unit(Option.none),ok=Except.ok,err=Except.error;
const list=xs=>xs.reduceRight((tail,head)=>List.cons(head,tail),nil);
const array=xs=>{const a=[];while(xs&&Object.hasOwn(xs,"head")){a.push(xs.head);xs=xs.tail;}return a;};
const same=(a,b)=>{
  if(a===b)return true;
  if(a===null||b===null||typeof a!=="object"||typeof b!=="object")return false;
  const keys=Reflect.ownKeys(a),other=Reflect.ownKeys(b);
  return keys.length===other.length&&keys.every(key=>Object.hasOwn(b,key)&&same(a[key],b[key]));
};
function capture(value,seen=new Map()){
  if(value===null||typeof value!=="object")return value;
  if(seen.has(value))return seen.get(value);
  const copy=Array.isArray(value)?[]:Object.create(Object.getPrototypeOf(value));
  seen.set(value,copy);
  for(const key of Reflect.ownKeys(value)){
    const descriptor=Object.getOwnPropertyDescriptor(value,key);
    if(Object.hasOwn(descriptor,"value"))descriptor.value=capture(descriptor.value,seen);
    Object.defineProperty(copy,key,descriptor);
  }
  return copy;
}
const accepted=(value,label)=>{
  if(value&&Object.hasOwn(value,"value"))return value.value;
  throw Error("PSC1_ORDINARY_ADMISSION_PRIVATE_REJECTED "+label+": "+String(value?.error));
};
const attempted=(value,label)=>accepted(accepted(value,label+"/some"),label+"/ok");
const rejected=value=>Boolean(value&&Object.hasOwn(value,"error"));
let assertions=0,section="harness";const counts={};
const must=(condition,label)=>{
  if(condition!==true)throw Error("PSC1_ORDINARY_ADMISSION_PRIVATE_FAIL "+section+"/"+label);
  assertions++;counts[section]=(counts[section]??0)+1;
};
must(!same(ok(false),ok(true))&&!same(ok("same"),err("same"))&&!same(none,Option.some(none)),
  "negative-control");
const N=get("PsKernelName"),E=get("PsKernelExpr"),L=get("PsKernelLevel"),B=get("PsKernelBinderInfo");
const CI=get("PsKernelConstantInfo"),Safety=get("PsKernelDefinitionSafety");
const nm=text=>N.str(unit(N.anonymous),text),zero=unit(L.zero),one=L.succ(zero);
const bi=unit(B.default),implicit=unit(B.implicit),safe=unit(Safety.safe),unsafe=unit(Safety.unsafeDef);
const s0=E.sort(zero),s1=E.sort(one),s2=E.sort(L.succ(one));
const cn=(name,levels=[])=>E.const(name,list(levels));
const all=(name,domain,body,info=bi)=>E.forallE(nm(name),domain,body,info);
const apps=(fn,args)=>args.reduce((head,arg)=>E.app(head,arg),fn);
const target=nm("AdmissionT"),ctorNames=[nm("AdmissionT.c0"),nm("AdmissionT.c1")];
const priorName=nm("AdmissionPrior"),unsafeName=nm("AdmissionUnsafe"),u=nm("AdmissionU");
const t=cn(target),ti=index=>E.app(t,index),bv=E.bvar,sortU=E.sort(L.param(u));
const empty=unit(get("psKernelEnvironmentEmpty")),maxNat=unit(get("psKernelLeanNatMaxSizeDefault"));
const prior=accepted(get("psKernelAddAxiom")(4096n,empty,
  {base:{name:priorName,levelParams:nil,type:s1},isUnsafe:false},0n,maxNat),"prior-safe-axiom");
const environment=accepted(get("psKernelAddAxiom")(4096n,prior,
  {base:{name:unsafeName,levelParams:nil,type:s1},isUnsafe:true},0n,maxNat),"prior-unsafe-axiom");
const exprExact=(a,b)=>get("psKernelExprEqual")(a)(b)===true;
const seqEqual=(a,b,equal)=>{const left=array(a),right=array(b);
  return left.length===right.length&&left.every((x,i)=>equal(x,right[i]));};
const baseEqual=(a,b)=>same(a.name,b.name)&&same(a.levelParams,b.levelParams)&&exprExact(a.type,b.type);
const tagged=(info,ctor)=>Boolean(info&&Object.hasOwn(info,"value")&&same(info,ctor(info.value)));
function constantEqual(left,right){
  if(tagged(left,CI.axiomInfo)&&tagged(right,CI.axiomInfo)){
    const a=left.value,b=right.value;return baseEqual(a.base,b.base)&&a.isUnsafe===b.isUnsafe;
  }
  if(tagged(left,CI.inductInfo)&&tagged(right,CI.inductInfo)){
    const a=left.value,b=right.value;
    return baseEqual(a.base,b.base)&&a.numParams===b.numParams&&a.numIndices===b.numIndices&&
      same(a.all,b.all)&&same(a.ctors,b.ctors)&&a.numNested===b.numNested&&a.isRec===b.isRec&&
      a.isReflexive===b.isReflexive&&a.isUnsafe===b.isUnsafe;
  }
  if(tagged(left,CI.ctorInfo)&&tagged(right,CI.ctorInfo)){
    const a=left.value,b=right.value;
    return baseEqual(a.base,b.base)&&same(a.induct,b.induct)&&a.cidx===b.cidx&&
      a.numParams===b.numParams&&a.numFields===b.numFields&&a.isUnsafe===b.isUnsafe;
  }
  if(tagged(left,CI.recInfo)&&tagged(right,CI.recInfo)){
    const a=left.value,b=right.value;
    return baseEqual(a.base,b.base)&&same(a.all,b.all)&&a.numParams===b.numParams&&
      a.numIndices===b.numIndices&&a.numMotives===b.numMotives&&a.numMinors===b.numMinors&&
      a.k===b.k&&a.isUnsafe===b.isUnsafe&&seqEqual(a.rules,b.rules,(x,y)=>
        same(x.ctor,y.ctor)&&x.nFields===y.nFields&&exprExact(x.rhs,y.rhs));
  }
  return false;
}
const findInfo=(env,name)=>get("psKernelEnvironmentFind")(env,name);
const findRef=(refs,name)=>get("psKernelExprV2DeclarationRefFind")(refs)(name);
function environmentEqual(a,b){
  if(a.quotInitialized!==b.quotInitialized||!same(a.runtime,b.runtime)||
      !seqEqual(a.constants,b.constants,constantEqual))return false;
  return array(a.constants).every(info=>{
    const name=get("psKernelConstantInfoName")(info),left=findInfo(a,name),right=findInfo(b,name);
    return left&&right&&Object.hasOwn(left,"value")&&Object.hasOwn(right,"value")&&
      constantEqual(info,left.value)&&constantEqual(info,right.value);
  });
}
const decodeWith=built=>root=>accepted(get("psKernelExprV2DecodedRequire")(built,root),"owned-root");
const graphDecode=arena=>decodeWith(accepted(get("psKernelExprV2DecodeChecked")(arena),"canonical-arena"));
function arenaPrefix(after,before){
  if(after.size<before.size||after.pageLimit!==before.pageLimit)return false;
  for(let root=0n;root<before.size;root++)
    if(!same(get("psKernelExprV2PagedFind")(after,root),get("psKernelExprV2PagedFind")(before,root)))return false;
  return true;
}
const cacheEqual=(a,b)=>seqEqual(a,b,(x,y)=>x.source===y.source&&x.result===y.result&&x.hash===y.hash);
const pairsEqual=(a,b)=>seqEqual(a,b,(x,y)=>x.left===y.left&&x.right===y.right&&x.hash===y.hash);
const semanticEqual=(a,b)=>a.nextFresh===b.nextFresh&&
  cacheEqual(a.whnf.coreCache,b.whnf.coreCache)&&cacheEqual(a.whnf.publicCache,b.whnf.publicCache)&&
  cacheEqual(a.checkedInfer,b.checkedInfer)&&cacheEqual(a.inferOnly,b.inferOnly)&&
  cacheEqual(a.unfold,b.unfold)&&pairsEqual(a.success,b.success)&&pairsEqual(a.failure,b.failure);
const stateEqual=(a,b)=>semanticEqual(a,b)&&same(a.whnf.declarations,b.whnf.declarations)&&
  a.whnf.arena.size===b.whnf.arena.size&&arenaPrefix(a.whnf.arena,b.whnf.arena);
const contextEqual=(a,b)=>same(a.locals,b.locals)&&same(a.scalar.localContext,b.scalar.localContext)&&
  same(a.scalar.levelParams,b.scalar.levelParams)&&same(a.scalar.safety,b.scalar.safety)&&
  a.scalar.eagerReduce===b.scalar.eagerReduce&&same(a.scalar.nativeEvaluator,b.scalar.nativeEvaluator)&&
  a.scalar.maxRecDepth===b.scalar.maxRecDepth&&a.scalar.maxNatSize===b.scalar.maxNatSize&&
  a.scalar.recDepth===b.scalar.recDepth&&environmentEqual(a.scalar.environment,b.scalar.environment);

const good=(fields,indices=0n,recursive=false,reflexive=false,kFlag=false,propOnly=false)=>
  ({fields:fields.map(BigInt),indices,recursive,reflexive,kFlag,propOnly});
const rows=[
  {label:"type-empty",header:s1,ctors:[],required:good([])},
  {label:"enum-two",header:s1,ctors:[t,t],required:good([0,0])},
  {label:"direct-recursive",header:s1,ctors:[t,all("previous",t,t)],required:good([0,1],0n,true)},
  {label:"reflexive",header:s1,ctors:[all("branch",all("p",s0,t),t)],required:good([1],0n,true,true)},
  {label:"parameterized",header:all("A",s1,s1,implicit),n:1n,
    ctors:[all("A",s1,all("value",bv(0n),ti(bv(1n))),implicit)],required:good([1])},
  {label:"dependent-index",header:all("A",s1,all("a",bv(0n),s1),implicit),n:1n,
    ctors:[all("A",s1,all("a",bv(0n),apps(t,[bv(1n),bv(0n)])),implicit)],required:good([1],1n)},
  {label:"universe",header:all("A",sortU,sortU,implicit),n:1n,levels:[u],
    ctors:[all("A",sortU,all("value",bv(0n),apps(cn(target,[L.param(u)]),[bv(1n)])),implicit)],
    required:good([1],0n,false,false,false,true)},
  {label:"prop-empty",header:s0,ctors:[],required:good([])},
  {label:"prop-unit",header:s0,ctors:[t],required:good([0],0n,false,false,true)},
  {label:"prop-proof-field",header:all("P",s0,s0,implicit),n:1n,
    ctors:[all("P",s0,all("proof",bv(0n),ti(bv(1n))),implicit)],required:good([1])},
  {label:"prop-data-field",header:s0,ctors:[all("A",s1,t)],required:good([1],0n,false,false,false,true)},
  {label:"prop-two",header:s0,ctors:[t,t],required:good([0,0],0n,false,false,false,true)},
  {label:"unsafe-reference",header:s1,ctors:[all("x",cn(unsafeName),t)],isUnsafe:true,required:good([1])},
  {label:"safe-prior-reference",header:s1,ctors:[all("x",cn(priorName),t)],required:good([1])},
  {label:"duplicate-level-before-mvar",header:E.mvar(nm("AdmissionM")),levels:[u,u],ctors:[],
    error:"duplicate universe parameter"},
  {label:"late-wrong-result",header:s1,ctors:[t,s0],
    error:"simple inductive constructor must return the declared datatype with matching parameters and index arity"},
  {label:"negative-function",header:s1,ctors:[all("f",all("x",t,t),t)],
    error:"recursive function argument contains a negative recursive occurrence"},
  {label:"safe-unsafe-reference",header:s1,ctors:[all("x",cn(unsafeName),t)],
    error:"safe declaration uses unsafe constant"}
];
const recName=get("psKernelSimpleRecName")(target);
function prepare(row){
  let owner={arena:unit(get("psKernelExprV2PagedEmpty")),
    built:unit(get("psKernelExprV2DecodedEmpty")),declarations:nil};
  const add=expr=>{
    const imported=accepted(get("psKernelDagGeneratedImport")(expr,owner),"input-import");
    owner=imported.fst;return imported.snd;
  };
  add(s2);
  const headerId=add(row.header),dagCtors=row.ctors.map((type,i)=>({name:ctorNames[i],type:add(type)}));
  const input=owner.built,sourceArena=owner.arena;
  owner=accepted(get("psKernelDagGeneratedDemandRange")(environment,0n,owner),"prior-owner-demand");
  const levelParams=list(row.levels??[]),numParams=row.n??0n,isUnsafe=row.isUnsafe??false;
  const oldCtors=row.ctors.map((type,i)=>({name:ctorNames[i],type}));
  const declaration={levelParams,name:target,type:row.header,ctors:list(oldCtors),isUnsafe,numParams};
  const value={name:target,type:headerId,ctors:list(dagCtors)};
  return {row,owner,input,sourceArena,headerId,dagCtors,declaration,value,levelParams,numParams,isUnsafe};
}
const oldAdmission=(fuel,f)=>get("psKernelAddSimpleInductive")(fuel,environment,f.declaration,0n,maxNat);
const actualAdmission=(fuel,f)=>get("psKernelExprV2OrdinaryAdmitWithFuel")(
  fuel,environment,0n,maxNat,f.input,f.owner,f.levelParams,f.numParams,f.value,f.isUnsafe);
function ownerMetadataMatches(owner,env,parent){
  const refs=array(owner.declarations),decode=graphDecode(owner.arena);
  const newInfos=array(env.constants).filter(info=>
    !Object.hasOwn(findInfo(environment,get("psKernelConstantInfoName")(info)),"value"));
  if(refs.length!==array(parent.declarations).length+newInfos.length)return false;
  if(!newInfos.every(info=>refs.filter(ref=>
      same(ref.name,get("psKernelConstantInfoName")(info))).length===1))return false;
  for(const ref of refs){
    if(refs.filter(other=>same(other.name,ref.name)).length!==1)return false;
    const found=findInfo(env,ref.name);
    if(!found||!Object.hasOwn(found,"value"))return false;
    const info=found.value;
    if(get("psKernelExprV2DeclarationRefMatches")(ref,info)!==true||
        !same(ref.deltaValue,none)||!exprExact(decode(ref.type),get("psKernelConstantInfoType")(info)))return false;
    if(tagged(info,CI.recInfo)){
      const rules=array(info.value.rules);
      if(!ref.kind||!Object.hasOwn(ref.kind,"rules")||array(ref.kind.rules).length!==rules.length)return false;
      if(!seqEqual(ref.kind.rules,info.value.rules,(a,b)=>same(a.ctor,b.ctor)&&
          a.nFields===b.nFields&&exprExact(decode(a.rhs),b.rhs)))return false;
      for(const rule of rules){
        const root=get("psKernelExprV2RecursorRuleOwner")(owner.declarations,info.value,rule);
        if(!root||!Object.hasOwn(root,"value")||!exprExact(decode(root.value),rule.rhs))return false;
      }
    }
  }
  return array(parent.declarations).every(old=>{
    const found=findRef(owner.declarations,old.name);
    return found&&Object.hasOwn(found,"value")&&same(found.value,old);
  });
}
function ownerAgrees(result,f){
  const owner=result.owner;
  if(!arenaPrefix(owner.arena,f.owner.arena)||!arenaPrefix(owner.arena,f.sourceArena)||
      owner.built.size!==owner.arena.size||
      !ownerMetadataMatches(owner,result.environment,f.owner))return false;
  const canonical=accepted(get("psKernelExprV2DecodeChecked")(owner.arena),"final-owner-canonical");
  for(let root=0n;root<owner.arena.size;root++){
    const actual=get("psKernelExprV2DecodedRequire")(owner.built,root);
    const expected=get("psKernelExprV2DecodedRequire")(canonical,root);
    if(rejected(actual)||rejected(expected)||!exprExact(accepted(actual,"final-built"),
        accepted(expected,"final-canonical")))return false;
  }
  if(!rejected(get("psKernelExprV2DecodedRequire")(owner.built,owner.arena.size)))return false;
  for(const original of [{name:target,type:f.headerId},...f.dagCtors]){
    const ref=accepted(findRef(owner.declarations,original.name),"original-owner");
    if(ref.type!==original.type||ref.type>=f.sourceArena.size||
        !exprExact(decodeWith(f.input)(ref.type),decodeWith(owner.built)(ref.type)))return false;
  }
  const rec=accepted(findRef(owner.declarations,recName),"recursor-owner");
  if(rec.type<f.sourceArena.size||array(rec.kind.rules).some(rule=>rule.rhs<f.sourceArena.size))return false;
  for(const ref of array(f.owner.declarations)){
    const now=accepted(findRef(owner.declarations,ref.name),"retained-prior-owner");
    if(now.type!==ref.type||!same(now,ref))return false;
  }
  return true;
}
function resultEqual(old,actual,f){
  if(!actual||!Object.hasOwn(actual,"value"))return false;
  if(rejected(old))return same(actual,Option.some(old));
  if(rejected(actual.value))return false;
  const left=accepted(old,"old-admission"),right=accepted(actual.value,"private-admission");
  return environmentEqual(left,right.environment)&&ownerAgrees(right,f);
}
function requiredOutcome(actual,f){
  if(f.row.error)return same(actual,Option.some(err(f.row.error)));
  if(!actual||!Object.hasOwn(actual,"value")||rejected(actual.value))return false;
  const result=accepted(actual.value,"required-result"),required=f.row.required,env=result.environment;
  const targetInfo=accepted(findInfo(env,target),"required-target");
  const recInfo=accepted(findInfo(env,recName),"required-rec");
  if(!tagged(targetInfo,CI.inductInfo)||!tagged(recInfo,CI.recInfo))return false;
  const induct=targetInfo.value,rec=recInfo.value;
  return induct.numParams===f.numParams&&induct.numIndices===required.indices&&
    induct.isRec===required.recursive&&induct.isReflexive===required.reflexive&&
    induct.isUnsafe===f.isUnsafe&&rec.isUnsafe===f.isUnsafe&&rec.k===required.kFlag&&
    rec.numParams===f.numParams&&rec.numIndices===required.indices&&rec.numMotives===1n&&
    rec.numMinors===BigInt(f.dagCtors.length)&&array(rec.rules).length===f.dagCtors.length&&
    array(rec.base.levelParams).length===array(f.levelParams).length+(required.propOnly?0:1)&&
    f.dagCtors.every((ctor,i)=>{
      const value=accepted(findInfo(env,ctor.name),"required-ctor");
      return tagged(value,CI.ctorInfo)&&value.value.cidx===BigInt(i)&&
        value.value.numFields===required.fields[i]&&value.value.numParams===f.numParams&&
        same(value.value.induct,target)&&value.value.isUnsafe===f.isUnsafe;
    })&&ownerAgrees(result,f);
}
const fuels=[0n,1n,2n,3n,8n,4096n],fixtures=rows.map(prepare);
section="matrix";
for(const f of fixtures){
  for(const fuel of fuels){
    const before=capture({environment,owner:f.owner,input:f.input});
    const old=oldAdmission(fuel,f),actual=actualAdmission(fuel,f);
    must(resultEqual(old,actual,f)&&same(environment,before.environment)&&
      same(f.owner,before.owner)&&same(f.input,before.input),f.row.label+"/fuel="+fuel);
  }
  const before=capture({environment,owner:f.owner,input:f.input});
  const old=oldAdmission(4096n,f),actual=actualAdmission(4096n,f);
  must(resultEqual(old,actual,f)&&requiredOutcome(actual,f)&&same(environment,before.environment)&&
    same(f.owner,before.owner)&&same(f.input,before.input),f.row.label+"/required-outcome");
}

// Callback probes remain private and return errors/declines on synthetic
// owner paths. Synthetic caches never reach another real checker invocation.
section="protocol";
const probe=fixtures[1],oldComplete=accepted(oldAdmission(4096n,probe),"protocol-old-complete");
const recInfo=accepted(findInfo(oldComplete,recName),"protocol-old-rec").value;
const legacyRules=array(recInfo.rules);
if(legacyRules.length!==2)throw Error("PSC1_ORDINARY_ADMISSION_PRIVATE_PROTOCOL_RULE_COUNT");
let beforeRecursor=environment;
const prefix=array(oldComplete.constants).filter(info=>
  !tagged(info,CI.recInfo)&&!Object.hasOwn(findInfo(environment,get("psKernelConstantInfoName")(info)),"value"));
for(const info of prefix.reverse())beforeRecursor=get("psKernelEnvironmentAddUnchecked")(beforeRecursor,info);
const expectedContext=env=>get("psKernelExprV2CheckContextEmpty")(
  get("psKernelMkCheckerSession")(env,recInfo.base.levelParams,safe,0n,maxNat).context);
const typeContext=expectedContext(beforeRecursor),ruleContext=expectedContext(oldComplete);
const realCheck=fuel=>context=>state=>root=>
  get("psKernelExprV2TryCheckStateWithFuel")(fuel,context,state,root);
const realWhnf=fuel=>context=>state=>root=>
  get("psKernelExprV2TryWhnfCheckStateWithFuel")(fuel,context,state,root);
const realDefEq=fuel=>context=>state=>left=>right=>
  get("psKernelExprV2TryDefEqStateWithFuel")(fuel)(context)(state)(left)(right);
const hasRecursor=context=>{
  const info=findInfo(context.scalar.environment,recName);
  return info&&Object.hasOwn(info,"value")&&tagged(info.value,CI.recInfo);
};
const originalRefs=state=>[{name:target,type:probe.headerId},...probe.dagCtors,
  ...array(probe.owner.declarations)].every(original=>{
    const found=findRef(state.whnf.declarations,original.name);
    return found&&Object.hasOwn(found,"value")&&found.value.type===original.type;
  });
const freshOwner=(context,state,wantContext,wantEnvironment)=>
  contextEqual(context,wantContext)&&
  semanticEqual(state,get("psKernelExprV2CheckStateEmpty")(state.whnf.arena))&&
  originalRefs(state)&&ownerMetadataMatches(
    {arena:state.whnf.arena,declarations:state.whnf.declarations},wantEnvironment,probe.owner);
const cache=hash=>list([{source:1n,result:2n,hash}]);
const pair=hash=>list([{left:1n,right:2n,hash}]);
const stamped=state=>({...state,nextFresh:37n,
  whnf:{...state.whnf,coreCache:cache(101n),publicCache:cache(102n),declarations:nil},
  checkedInfer:cache(103n),success:pair(104n),inferOnly:cache(105n),
  unfold:cache(106n),failure:pair(107n)});
function callbacks(mode){
  const trace=[];let checkedForSort=null,stampedOwner=null,ruleComparisons=0;
  const check=fuel=>context=>state=>root=>{
    const expr=graphDecode(state.whnf.arena)(root),inRules=hasRecursor(context);
    if(!inRules&&exprExact(expr,recInfo.base.type)){
      if(fuel!==4096n)throw Error("PSC1_ORDINARY_ADMISSION_PRIVATE_RECTYPE_FUEL");
      trace.push("rec-type-check");
      if(mode===0)return Option.some(err("REC_TYPE_ERROR"));
      if(mode===1)return none;
      if(mode===3)return Option.some(err(freshOwner(context,state,typeContext,beforeRecursor)?
        "REC_TYPE_FRESH_OK":"REC_TYPE_FRESH_BAD"));
      const actual=mode===2?Option.some(ok({fst:state,snd:probe.dagCtors[0].type})):
        realCheck(fuel)(context)(state)(root);
      if(actual&&Object.hasOwn(actual,"value")&&!rejected(actual.value)){
        const checked=accepted(actual.value,"rec-type-checked");
        checkedForSort={context,state:checked.fst,root:checked.snd};
      }
      return actual;
    }
    if(inRules&&exprExact(expr,legacyRules[0].rhs)){
      if(fuel!==4096n)throw Error("PSC1_ORDINARY_ADMISSION_PRIVATE_RULE_FUEL");
      trace.push("first-rule-check");
      if(mode===4)return Option.some(err("FIRST_RULE_ERROR"));
      if(mode===5)return none;
      if(mode===11)return Option.some(err(freshOwner(context,state,ruleContext,oldComplete)?
        "FIRST_RULE_FRESH_OK":"FIRST_RULE_FRESH_BAD"));
    }
    if(inRules&&exprExact(expr,legacyRules[1].rhs)){
      if(fuel!==4096n)throw Error("PSC1_ORDINARY_ADMISSION_PRIVATE_RULE_FUEL");
      trace.push("second-rule-check");
      if(mode===6||mode===7){
        if(!stampedOwner||!stateEqual(state,stampedOwner)||!contextEqual(context,ruleContext))
          throw Error("PSC1_ORDINARY_ADMISSION_PRIVATE_SECOND_RULE_OWNER");
        return mode===6?Option.some(err("SECOND_RULE_ERROR")):none;
      }
    }
    return realCheck(fuel)(context)(state)(root);
  };
  const whnf=fuel=>context=>state=>root=>{
    if(checkedForSort){
      if(fuel!==4096n||!contextEqual(context,checkedForSort.context)||
          !stateEqual(state,checkedForSort.state)||root!==checkedForSort.root)
        throw Error("PSC1_ORDINARY_ADMISSION_PRIVATE_SORT_OWNER");
      trace.push("rec-type-sort");checkedForSort=null;
    }
    return realWhnf(fuel)(context)(state)(root);
  };
  const defeq=fuel=>context=>state=>left=>right=>{
    if(hasRecursor(context)){
      if(fuel!==4096n)throw Error("PSC1_ORDINARY_ADMISSION_PRIVATE_DEFEQ_FUEL");
      ruleComparisons++;trace.push("rule-defeq-"+ruleComparisons);
      if(mode===8)return Option.some(err("RULE_DEFEQ_ERROR"));
      if(mode===9)return none;
      if(mode===10)return Option.some(ok({fst:state,snd:false}));
      const actual=realDefEq(fuel)(context)(state)(left)(right);
      if((mode===6||mode===7)&&ruleComparisons===1){
        const compared=attempted(actual,"first-rule-real-defeq");
        if(compared.snd!==true)throw Error("PSC1_ORDINARY_ADMISSION_PRIVATE_FIRST_RULE_NOT_EQUAL");
        stampedOwner=stamped(compared.fst);
        return Option.some(ok({fst:stampedOwner,snd:true}));
      }
      return actual;
    }
    return realDefEq(fuel)(context)(state)(left)(right);
  };
  return {check,whnf,defeq,trace};
}
const invoke=(f,callbacks,value=f.value)=>get("psKernelExprV2OrdinaryAdmitWith")(
  callbacks.check,callbacks.whnf,callbacks.defeq,4096n,environment,0n,maxNat,
  f.input,f.owner,f.levelParams,f.numParams,value,f.isUnsafe);
const beforeCall=f=>capture({environment,owner:f.owner,input:f.input});
const unchanged=(f,before)=>same(environment,before.environment)&&
  same(f.owner,before.owner)&&same(f.input,before.input);
const traces=[
  ["rec-type-check"],
  ["rec-type-check"],
  ["rec-type-check","rec-type-sort"],
  ["rec-type-check"],
  ["rec-type-check","rec-type-sort","first-rule-check"],
  ["rec-type-check","rec-type-sort","first-rule-check"],
  ["rec-type-check","rec-type-sort","first-rule-check","rule-defeq-1","second-rule-check"],
  ["rec-type-check","rec-type-sort","first-rule-check","rule-defeq-1","second-rule-check"],
  ["rec-type-check","rec-type-sort","first-rule-check","rule-defeq-1"],
  ["rec-type-check","rec-type-sort","first-rule-check","rule-defeq-1"],
  ["rec-type-check","rec-type-sort","first-rule-check","rule-defeq-1"],
  ["rec-type-check","rec-type-sort","first-rule-check"]
];
const protocols=[
  ["rec-type-error","REC_TYPE_ERROR"],
  ["rec-type-decline",null],
  ["rec-type-nonsort","expected sort"],
  ["rec-type-fresh-context","REC_TYPE_FRESH_OK"],
  ["first-rule-error","FIRST_RULE_ERROR"],
  ["first-rule-decline",null],
  ["second-rule-error","SECOND_RULE_ERROR"],
  ["second-rule-decline",null],
  ["rule-defeq-error","RULE_DEFEQ_ERROR"],
  ["rule-defeq-decline",null],
  ["rule-defeq-false","generated simple recursor rule is not type preserving"],
  ["first-rule-fresh-context","FIRST_RULE_FRESH_OK"]
];
for(let mode=0;mode<protocols.length;mode++){
  const [label,message]=protocols[mode],before=beforeCall(probe),cb=callbacks(mode);
  const actual=invoke(probe,cb),expected=message===null?none:Option.some(err(message));
  must(same(actual,expected)&&same(cb.trace,traces[mode])&&unchanged(probe,before),label);
}
{
  const before=beforeCall(probe),cb={check:realCheck,whnf:realWhnf,defeq:realDefEq};
  const injected=invoke(probe,cb),wrapped=actualAdmission(4096n,probe);
  must(same(injected,wrapped)&&resultEqual(ok(oldComplete),injected,probe)&&
    unchanged(probe,before),"real-callbacks-match-wrapper");
}
const privateImported=accepted(get("psKernelDagGeneratedImport")(s1,probe.owner),"private-namespace-import");
const privateRoot=privateImported.snd,privateProbe={...probe,owner:privateImported.fst};
if(rejected(get("psKernelExprV2PagedRequire")(privateProbe.owner.arena,privateRoot))||
    !rejected(get("psKernelExprV2DecodedRequire")(probe.input,privateRoot)))
  throw Error("PSC1_ORDINARY_ADMISSION_PRIVATE_NAMESPACE_FIXTURE");
const forbiddenCheck=_fuel=>_context=>_state=>_root=>{throw Error("PSC1_ORDINARY_ADMISSION_PRIVATE_UNEXPECTED_CHECK");};
const forbiddenDefEq=_fuel=>_context=>_state=>_left=>_right=>{throw Error("PSC1_ORDINARY_ADMISSION_PRIVATE_UNEXPECTED_DEFEQ");};
const forbidden={check:forbiddenCheck,whnf:forbiddenCheck,defeq:forbiddenDefEq};
{
  const before=beforeCall(privateProbe),value={...probe.value,type:privateRoot};
  must(same(invoke(privateProbe,forbidden,value),Option.some(err("PSKERNEL_V2_DECODE_INVALID_REFERENCE")))&&
    unchanged(privateProbe,before),"private-header-id-not-input");
}
{
  const before=beforeCall(privateProbe),ctors=probe.dagCtors.map((ctor,i)=>i===0?{...ctor,type:privateRoot}:ctor);
  must(same(invoke(privateProbe,forbidden,{...probe.value,ctors:list(ctors)}),
    Option.some(err("PSKERNEL_V2_DECODE_INVALID_REFERENCE")))&&
    unchanged(privateProbe,before),"private-ctor-id-not-input");
}
{
  const before=beforeCall(probe),cb=callbacks(6),failed=invoke(probe,cb);
  const retried=actualAdmission(4096n,probe);
  must(same(failed,Option.some(err("SECOND_RULE_ERROR")))&&same(cb.trace,traces[6])&&
    resultEqual(ok(oldComplete),retried,probe)&&requiredOutcome(retried,probe)&&
    unchanged(probe,before),"retry-after-late-failure");
}
const positive=rows.filter(row=>!row.error).length,negative=rows.length-positive;
if(!same(counts,{harness:1,matrix:126,protocol:16})||assertions!==143||
    rows.length!==18||fuels.length!==6||positive!==14||negative!==4)
  throw Error("PSC1_ORDINARY_ADMISSION_PRIVATE_INVENTORY");
console.log(JSON.stringify({schema:"psc1-ordinary-admission-private-v1",kernel:kernelPath,assertions,
  sectionAssertions:counts,rows:18,fuelValues:6,positive,negative,
  privateAdmission:true,fullAdmission:false,publicRoutingChanged:false}));
console.log("PSC1_ORDINARY_ADMISSION_PRIVATE_JS: PASS assertions=143 privateAdmission=true fullAdmission=false");
