import {pathToFileURL} from "node:url";
import path from "node:path";

const filename=process.argv[2];
if(!filename)throw Error("PSC1_V2_INITIAL_OWNER_REQUIRES_GENERATED_KERNEL");
const k=await import(pathToFileURL(path.resolve(filename)).href);
const get=name=>{if(!(name in k))throw Error("PSC1_V2_INITIAL_OWNER_MISSING_EXPORT "+name);return k[name];};
const unit=x=>typeof x==="function"?x():x;
const same=(a,b)=>{
 if(a===b)return true;
 if(a===null||b===null||typeof a!=="object"||typeof b!=="object")return false;
 const keys=Reflect.ownKeys(a),other=Reflect.ownKeys(b);
 return keys.length===other.length&&keys.every(key=>Object.hasOwn(b,key)&&same(a[key],b[key]));
};
let assertions=0;
const must=(condition,label)=>{
 if(condition!==true)throw Error("PSC1_V2_INITIAL_OWNER_FAIL "+label);
 assertions++;
};
const accepted=(value,label)=>{
 if(value&&typeof value==="object"&&Object.hasOwn(value,"value"))return value.value;
 const error=value&&typeof value==="object"&&Object.hasOwn(value,"error")?value.error:null;
 const text=typeof error==="string"?error:error?.message??"missing accepted value";
 throw Error("PSC1_V2_INITIAL_OWNER_REJECTED "+label+": "+text);
};
const attempt=(value,label)=>accepted(accepted(value,label+"-direct"),label);
const isError=value=>Boolean(value&&typeof value==="object"&&Object.hasOwn(value,"error"));
const List=get("List"),nil=unit(List.nil),Opt=get("Option"),none=unit(Opt.none);
const list=xs=>xs.reduceRight((tail,head)=>List.cons(head,tail),nil);
const array=xs=>{const out=[];while(xs&&Object.hasOwn(xs,"head")){out.push(xs.head);xs=xs.tail;}return out;};
const N=get("PsKernelName"),E=get("PsKernelExpr"),L=get("PsKernelLevel");
const B=get("PsKernelBinderInfo"),Lit=get("PsKernelLiteral"),CI=get("PsKernelConstantInfo");
const Request=get("PsKernelDeclarationRequest"),D=get("PsKernelDagDeclarationRequest"),C=get("PsKernelDagCommand");
const ErrorTag=get("PsKernelError"),Kind=get("PsKernelExprV2DeclarationRefKind");
const safe=unit(get("PsKernelDefinitionSafety").safe),hint=unit(get("PsKernelReducibilityHints").abbrevHint);
const nm=text=>N.str(unit(N.anonymous),text),zero=unit(L.zero),one=L.succ(zero);
const cn=(name,levels=[])=>E.const(name,list(levels));
const pi=(name,type,body)=>E.forallE(nm(name),type,body,unit(B.default));
const app=(fn,args)=>args.reduce((left,right)=>E.app(left,right),fn);
const nat=cn(get("psKernelNatName")),s1=E.sort(one),seven=E.lit(Lit.nat(7n));
const nEq=(a,b)=>get("psKernelNameEq")(a)(b);
const exact=(a,b)=>get("psKernelExprEqual")(a)(b);
const publicError=(value,kind,text)=>isError(value)&&value.error&&
 typeof value.error.message==="string"&&same(value.error,ErrorTag[kind](value.error.message))&&
 (text===undefined||value.error.message===text);
const rejected=value=>publicError(value,"rejectedInvalid");
const isRec=info=>Boolean(info&&Object.hasOwn(info,"value")&&same(info,CI.recInfo(info.value)));
const contains=(environment,name)=>get("psKernelEnvironmentContains")(environment,name);
const infoName=info=>get("psKernelConstantInfoName")(info);
const findRef=(rows,name)=>get("psKernelExprV2DeclarationRefFind")(rows)(name);
const decode=(arena,root)=>accepted(get("psKernelExprV2DecodedRequire")(
 accepted(get("psKernelExprV2DecodeChecked")(arena),"decode"),root),"root");

// This stable preexisting importer constructs test input; RunDag still validates it.
let source={arena:get("psKernelExprV2PagedEmpty"),built:get("psKernelExprV2DecodedEmpty"),declarations:nil};
const inputExpr=term=>{
 const result=accepted(get("psKernelDagGeneratedImport")(term,source),"input-construction");
 source=result.fst;return result.snd;
};
inputExpr(E.lit(Lit.nat(53n)));
const empty=accepted(get("psKernelKernelSessionEmpty")(
 get("psKernelResourcePolicyDefault"),get("psKernelProviderDefault")),"empty");
let session=empty;
const commands=[],transitions=[];
const publish=(kind,request,sourceRequest)=>{
 const previous=session.environment;
 session=accepted(get("psKernelV1AdmitDeclaration")(session,sourceRequest),"checked-"+kind).session;
 commands.push(C.admit(request));
 transitions.push({kind,request,previous,current:session.environment});
};
const importGroup=group=>({
 levelParams:group.levelParams,numParams:group.numParams,isUnsafe:group.isUnsafe,
 types:list(array(group.types).map(type=>({
  name:type.name,type:inputExpr(type.type),
  ctors:list(array(type.ctors).map(ctor=>({name:ctor.name,type:inputExpr(ctor.type)})))
 })))
});
const group=(nested,value)=>{
 const dag=importGroup(value);
 publish(nested?"nested":"mutual",nested?D.nestedInductive(dag):D.mutualInductive(dag),
  nested?Request.nestedInductive(value):Request.mutualInductive(value));
};
const ordinary=decl=>{
 const dg=importGroup({levelParams:decl.levelParams,numParams:decl.numParams,isUnsafe:decl.isUnsafe,
  types:list([{name:decl.name,type:decl.type,ctors:decl.ctors}])});
 publish("ordinary",D.ordinaryInductive(decl.levelParams,decl.numParams,array(dg.types)[0],decl.isUnsafe),
  Request.ordinaryInductive(decl));
};
const axiom=name=>{
 const root=inputExpr(s1),base={name,levelParams:nil,type:s1};
 publish("axiom",D.axiomDecl({name,levelParams:nil,type:root},false),
  Request.axiomDecl({base,isUnsafe:false}));
};
const ctor=(name,type)=>({name,type});
const family=(name,type,ctors)=>({name,type,ctors:list(ctors)});
ordinary({levelParams:nil,name:get("psKernelNatName"),type:s1,
 ctors:list([ctor(get("psKernelNatZeroName"),nat),ctor(get("psKernelNatSuccName"),pi("n",nat,nat))]),
 isUnsafe:false,numParams:0n});
const root=N.num(nm("InitialOwner"),7n),a=N.str(root,"Left"),b=N.str(root,"Right");
const abase=N.str(a,"base"),bbase=N.str(b,"base"),amk=N.str(a,"mk"),bmk=N.str(b,"mk");
const u=nm("u"),v=nm("v"),uv=[L.param(u),L.param(v)];
const universeType=E.sort(L.succ(L.max(L.param(u),L.param(v)))),aType=cn(a,uv),bType=cn(b,uv);
const mutualGroup={levelParams:list([u,v]),numParams:0n,isUnsafe:false,types:list([
 family(a,universeType,[ctor(abase,aType),ctor(amk,pi("other",bType,aType))]),
 family(b,universeType,[ctor(bbase,bType),ctor(bmk,pi("other",aType,bType))])
])};
group(false,mutualGroup);
const mutualTransition=transitions.at(-1);
const listName=N.str(root,"List"),nilName=N.str(listName,"nil"),consName=N.str(listName,"cons");
const sortU=E.sort(L.succ(L.param(u))),listAt=element=>app(cn(listName,[L.param(u)]),[element]);
ordinary({levelParams:list([u]),name:listName,type:pi("A",sortU,sortU),numParams:1n,isUnsafe:false,
 ctors:list([
  ctor(nilName,pi("A",sortU,listAt(E.bvar(0n)))),
  ctor(consName,pi("A",sortU,pi("head",E.bvar(0n),
   pi("tail",listAt(E.bvar(1n)),listAt(E.bvar(2n))))))
 ])});
const treeName=N.str(root,"Tree"),leafName=N.str(treeName,"leaf"),branchName=N.str(treeName,"branch");
const tree=cn(treeName),listTree=app(cn(listName,[zero]),[tree]);
const treeGroup={levelParams:nil,numParams:0n,isUnsafe:false,types:list([
 family(treeName,s1,[ctor(leafName,tree),ctor(branchName,pi("children",listTree,tree))])
])};
const beforeTree=session;
group(true,treeGroup);
const treeSession=session;
const fastName=N.str(root,"Fast"),fastCtor=N.str(fastName,"mk");
group(true,{levelParams:nil,numParams:0n,isUnsafe:false,
 types:list([family(fastName,s1,[ctor(fastCtor,cn(fastName))])])});
const fastTransition=transitions.at(-1);
const axiomName=N.str(root,"Token"),aliasName=N.str(root,"value");
const theoremName=N.str(root,"identity"),sealedName=N.str(root,"sealed");
const proposition=pi("P",E.sort(zero),pi("proof",E.bvar(0n),E.bvar(1n)));
const proof=E.lam(nm("P"),E.sort(zero),
 E.lam(nm("proof"),E.bvar(0n),E.bvar(0n),unit(B.default)),unit(B.default));
axiom(axiomName);
const simple=(kind,name,type,value)=>{
 const typeId=inputExpr(type),valueId=inputExpr(value),base={name,levelParams:nil,type};
 if(kind==="definition")publish(kind,D.definitionDecl({
  base:{name,levelParams:nil,type:typeId},value:valueId,hints:hint,safety:safe}),
  Request.definitionDecl({base,value,hints:hint,safety:safe}));
 else if(kind==="theorem")publish(kind,D.theoremDecl(
  {name,levelParams:nil,type:typeId},valueId),Request.theoremDecl({base,value}));
 else publish(kind,D.opaqueDecl({name,levelParams:nil,type:typeId},valueId,false),
  Request.opaqueDecl({base,value,isUnsafe:false}));
};
simple("definition",aliasName,nat,seven);
simple("theorem",theoremName,proposition,proof);
simple("opaque",sealedName,nat,seven);
const preparedSession=session,firstArena=source.arena;
const first=accepted(get("psKernelV1RunDag")(empty,nil,safe,firstArena,list(commands)),"first-public-batch");
must(array(first.replies).length===9,"first-batch-replies");
must(get("psKernelEnvironmentSize")(first.session.environment)===28n,"first-batch-real-environment");
for(const info of array(preparedSession.environment.constants)){
 const actual=accepted(get("psKernelEnvironmentFind")(
  first.session.environment,infoName(info)),"first-public-metadata");
 must(exact(get("psKernelConstantInfoType")(info),get("psKernelConstantInfoType")(actual)),
  "public-first-batch-agrees-with-independent-admission");
}
session=first.session;
const environment=get("psKernelKernelSessionEnvironment")(session);
const newPrefix=(previous,current)=>{
 const out=[];let pending=current.constants;
 while(pending&&Object.hasOwn(pending,"head")){
  const info=pending.head;
  if(contains(previous,infoName(info)))break;
  out.push(info);pending=pending.tail;
 }
 return out;
};
const treePrefix=newPrefix(beforeTree.environment,treeSession.environment);
const treeRecursors=treePrefix.filter(isRec).map(info=>info.value);
const treeInfo=accepted(get("psKernelEnvironmentFind")(session.environment,treeName),"tree-info");
must(treeRecursors.length===2&&same(treeInfo,CI.inductInfo(treeInfo.value))&&
 treeInfo.value.numNested===1n,"genuine-nested-restoration");
const aux=treeRecursors.find(rec=>array(rec.rules).some(rule=>nEq(rule.ctor,nilName)));
must(Boolean(aux),"actual-final-auxiliary-recursor");
const recInfo=name=>{
 const value=accepted(get("psKernelEnvironmentFind")(session.environment,name),"final-recursor");
 must(isRec(value),"final-recursor-kind");return value.value;
};
const aRec=recInfo(get("psKernelSimpleRecName")(a)),bRec=recInfo(get("psKernelSimpleRecName")(b));
const treeRec=recInfo(get("psKernelSimpleRecName")(treeName));
const fastRec=recInfo(get("psKernelSimpleRecName")(fastName));
const isPi=type=>Boolean(type&&Object.hasOwn(type,"body")&&Object.hasOwn(type,"type")&&
 same(type,E.forallE(type.name,type.type,type.body,type.binderInfo)));
const constantFunction=(type,value)=>isPi(type)?
 E.lam(type.name,type.type,constantFunction(type.body,value),type.binderInfo):value;
const recApplication=(info,originalParams,major)=>{
 must(info.numParams===0n&&info.numIndices===0n,"fixture-zero-params-indices");
 const levels=array(info.base.levelParams).map(name=>originalParams.some(x=>nEq(x,name))?zero:one);
 let type=get("psKernelExprInstantiateLevelParams")(info.base.type)(info.base.levelParams)(list(levels));
 let term=cn(info.base.name,levels);
 for(let i=0n;i<info.numMotives+info.numMinors;i++){
  must(isPi(type),"actual-recursor-Pi-spine");
  const value=constantFunction(type.type,i<info.numMotives?nat:seven);
  term=E.app(term,value);type=get("psKernelExprInstantiate")(type.body,list([value]));
 }
 return E.app(term,major);
};

const leaf=cn(leafName),listNil=app(cn(nilName,[zero]),[tree]);
const listCons=app(cn(consName,[zero]),[tree,leaf,listNil]);
const natRec=recInfo(get("psKernelSimpleRecName")(get("psKernelNatName")));
const reduced=[
 ["ordinary-Nat",recApplication(natRec,[],app(cn(get("psKernelNatSuccName")),[E.lit(Lit.nat(0n))]))],
 ["mutual-left",recApplication(aRec,[u,v],app(cn(amk,[zero,zero]),[cn(bbase,[zero,zero])]))],
 ["mutual-right",recApplication(bRec,[u,v],app(cn(bmk,[zero,zero]),[cn(abase,[zero,zero])]))],
 ["nested-leaf",recApplication(treeRec,[],leaf)],
 ["nested-branch",recApplication(treeRec,[],app(cn(branchName),[listCons]))],
 ["nested-aux",recApplication(aux,[],listCons)],
 ["nested-no-aux",recApplication(fastRec,[],cn(fastCtor))]
];
const queries=[
 ...reduced.map(([label,term])=>({label,term,normalized:seven,equalTo:seven})),
 {label:"axiom",term:cn(axiomName),normalized:cn(axiomName),equalTo:cn(axiomName)},
 {label:"definition",term:cn(aliasName),normalized:seven,equalTo:seven},
 {label:"theorem",term:cn(theoremName),normalized:cn(theoremName),equalTo:proof},
 {label:"opaque",term:cn(sealedName),normalized:cn(sealedName),equalTo:cn(sealedName)},
 {label:"proof",term:proof,normalized:proof,equalTo:cn(theoremName)}
];
// New source arena and empty owner list: no first-batch IDs or caches are reused.
source={arena:get("psKernelExprV2PagedEmpty"),built:get("psKernelExprV2DecodedEmpty"),declarations:nil};
inputExpr(E.lit(Lit.nat(12345n)));
for(const query of queries){query.root=inputExpr(query.term);query.target=inputExpr(query.equalTo);}
const input=source.arena,built=accepted(get("psKernelExprV2DecodeChecked")(input),"second-input-decode");
accepted(get("psKernelExprV2PagedValidate")(input),"second-input-validate");
const generated=accepted(get("psKernelDagInitialInstall")(
 environment,{arena:input,built,declarations:nil}),"initial-session-owners");
const requireBuilt=(table,id,label)=>accepted(get("psKernelExprV2DecodedRequire")(table,id),label);
const scalar=get("psKernelKernelSessionChecker")(session,nil,safe).context;
const ownerByName=name=>accepted(findRef(generated.declarations,name),"live-owner");
must(exact(E.lit(Lit.nat(12345n)),requireBuilt(built,0n,"fresh-padding")),"fresh-second-graph-padding");
must(array(generated.declarations).length===28,"new-owner-complete-count");
must(generated.arena.size===generated.built.size,"appended-tables-correspond");
let recursors=0,rules=0,deltas=0;
for(const info of array(environment.constants)){
 const name=infoName(info),live=accepted(get("psKernelEnvironmentFind")(environment,name),"live-lookup");
 const owner=ownerByName(name);
 must(get("psKernelExprV2DeclarationRefMatches")(owner,live),"only-live-index-metadata");
 must(owner.type>=input.size,"private-type-ID");
 must(exact(get("psKernelConstantInfoType")(live),requireBuilt(generated.built,owner.type,"live-type")),
  "exact-live-type");
 if(same(live,CI.defnInfo(live.value))){
  deltas++;
  const body=accepted(owner.deltaValue,"transparent-body");
  must(body>=input.size,"private-transparent-body-ID");
  must(exact(live.value.value,requireBuilt(generated.built,body,"live-body")),"exact-live-transparent-body");
 }else must(same(owner.deltaValue,none),"only-definitions-publish-delta");
 if(isRec(live)){
  recursors++;
  for(const rule of array(live.value.rules)){
   rules++;
   const rhs=accepted(get("psKernelExprV2RecursorRuleOwner")(
    generated.declarations,live.value,rule),"live-rule-owner");
   must(rhs>=input.size,"private-rule-ID");
   must(exact(rule.rhs,requireBuilt(generated.built,rhs,"live-rule")),"exact-live-rule");
  }
 }
}
must(recursors===7&&rules===13&&deltas===1,"owner-family-counts");
for(let id=0n;id<input.size;id++)must(exact(
 requireBuilt(built,id,"input-original"),requireBuilt(generated.built,id,"input-after")),
 "original-input-prefix");
const aliasQuery=queries.find(query=>query.label==="definition");
must(same(get("psKernelExprV2TryCheckWithDeclarationsFuel")(
 4096n,scalar,input,nil,aliasQuery.root),none),"preexisting-without-owner-explicitly-declines");
const initial=get("psKernelExprV2CheckStateWithWhnf")(
 get("psKernelExprV2CheckStateEmpty")(generated.arena),
 get("psKernelExprV2WhnfStateForDeclarations")(generated.arena,generated.declarations));
must(initial.nextFresh===0n&&["checkedInfer","inferOnly","success","failure","unfold"].every(
 key=>array(initial[key]).length===0)&&array(initial.whnf.coreCache).length===0&&
 array(initial.whnf.publicCache).length===0,"fresh-complete-operation-state");
const primed=attempt(get("psKernelExprV2TryCheckStateWithFuel")(
 4096n,get("psKernelExprV2CheckContextEmpty")(scalar),initial,
 queries.find(query=>query.label==="proof").root),"fresh-proof-state");
must(primed.fst.nextFresh>0n,"real-operation-used-fresh-names");
must(initial.nextFresh===0n&&array(initial.checkedInfer).length===0,"original-state-not-mutated");
const compareExpr=(label,reference,observed)=>{
 const actual=accepted(observed,label+"-mandatory-owned-result");
 if(isError(reference)||isError(actual)){
  must(isError(reference)&&isError(actual)&&reference.error===actual.error,label+"-exact-error");
 }else{
  const left=accepted(reference,label+"-reference"),right=accepted(actual,label+"-actual");
  must(exact(left.fst,decode(right.fst,right.snd)),label+"-exact-expression");
 }
};
const compareBool=(label,reference,observed)=>{
 const actual=accepted(observed,label+"-mandatory-owned-result");
 if(isError(reference)||isError(actual)){
  must(isError(reference)&&isError(actual)&&reference.error===actual.error,label+"-exact-error");
 }else must(accepted(reference,label+"-reference").fst===accepted(actual,label+"-actual"),
  label+"-exact-boolean");
};
let matrix=0;
for(const query of queries)for(const fuel of [0n,1n,2n,4n,16n,64n,4096n])
 for(const [maxRecDepth,recDepth] of [[0n,0n],[1n,15n],[1n,16n]]){
  const context={...scalar,maxRecDepth,recDepth};
  const reference={context,state:unit(get("psKernelCheckerStateEmpty"))};
  const label=query.label+"-fuel"+fuel+"-limit"+maxRecDepth+"-depth"+recDepth;
  compareExpr(label+"-check",get("psKernelSessionCheck")(fuel,reference,query.term),
   get("psKernelExprV2TryCheckWithDeclarationsFuel")(
    fuel,context,generated.arena,generated.declarations,query.root));
  compareExpr(label+"-whnf",get("psKernelSessionWhnf")(fuel,reference,query.term),
   get("psKernelExprV2TryWhnfOwnedWithDeclarationsFuel")(
    fuel,context,generated.arena,generated.declarations,query.root));
  compareBool(label+"-defeq",get("psKernelSessionIsDefEq")(fuel,reference,query.term,query.equalTo),
   get("psKernelExprV2TryDefEqWithDeclarationsFuel")(
    fuel,context,generated.arena,generated.declarations,query.root,query.target));
  matrix++;
 }
must(matrix===252,"raw-matrix-complete");
console.log("PSC1_V2_INITIAL_OWNER_METADATA_JS: PASS owners=28 recursors=7 rules=13 delta=1");
console.log("PSC1_V2_INITIAL_OWNER_MATRIX_JS: PASS check=252 whnf=252 defeq=252");

const Reply=get("PsKernelDagReply");
const secondCommands=queries.flatMap(query=>[
 C.check(query.root),C.whnf(query.root),C.isDefEq(query.root,query.target)]);
const second=accepted(get("psKernelV1RunDag")(
 session,nil,safe,input,list(secondCommands)),"second-public-batch");
const replies=array(second.replies);
must(replies.length===36,"second-batch-all-replies");
must(get("psKernelEnvironmentSize")(second.session.environment)===28n,"second-batch-environment-size");
for(let i=0;i<queries.length;i++){
 const query=queries[i];
 const checked=accepted(get("psKernelV1CheckExpression")(session,nil,safe,query.term),"reference-check");
 const normalized=accepted(get("psKernelV1Whnf")(session,nil,safe,query.term),"reference-whnf");
 const equal=accepted(get("psKernelV1IsDefEq")(session,nil,safe,query.term,query.equalTo),"reference-defeq");
 must(exact(normalized,query.normalized),query.label+"-specified-normalization");
 must(equal===true,query.label+"-specified-equality");
 const checkReply=replies[i*3],whnfReply=replies[i*3+1],equalReply=replies[i*3+2];
 must(same(checkReply,Reply.checked(checkReply.value)),query.label+"-checked-reply");
 must(exact(checkReply.value.expression,checked.expression)&&exact(checkReply.value.type,checked.type),
  query.label+"-public-exact-check");
 must(same(whnfReply,Reply.normalized(whnfReply.value))&&exact(whnfReply.value,normalized),
  query.label+"-public-exact-whnf");
 must(same(equalReply,Reply.equal(equalReply.value))&&equalReply.value===equal,
  query.label+"-public-exact-defeq");
}
const wrongName=nm("InitialOwnerWrongType");
must(publicError(get("psKernelV1AdmitDeclaration")(session,Request.definitionDecl({
 base:{name:wrongName,levelParams:nil,type:s1},value:seven,hints:hint,safety:safe
})),"rejectedInvalid","definition type mismatch"),"V1-real-invalid-definition");
console.log("PSC1_V2_INITIAL_OWNER_PUBLIC_JS: PASS replies=36 secondArena=fresh");

// All private metadata IDs remain outside every public request's original table.
source={arena:input,built,declarations:nil};
const natId=inputExpr(nat),s1Id=inputExpr(s1),sevenId=inputExpr(seven),aliasId=inputExpr(cn(aliasName));
const missingName=nm("InitialOwnerMissing"),missingId=inputExpr(cn(missingName));
const freshName=nm("InitialOwnerSecondDefinition"),freshId=inputExpr(cn(freshName));
const extendedInput=source.arena,extendedBuilt=accepted(
 get("psKernelExprV2DecodeChecked")(extendedInput),"extended-input");
const extendedOwned=accepted(get("psKernelDagInitialInstall")(
 environment,{arena:extendedInput,built:extendedBuilt,declarations:nil}),"extended-owner");
const aliasOwner=accepted(findRef(extendedOwned.declarations,aliasName),"extended-alias-owner");
const bodyId=accepted(aliasOwner.deltaValue,"extended-alias-body");
const firstNatRule=array(natRec.rules)[0];
const ruleId=accepted(get("psKernelExprV2RecursorRuleOwner")(
 extendedOwned.declarations,natRec,firstNatRule),"extended-Nat-rule");
const privateIds=[extendedInput.size,aliasOwner.type,bodyId,ruleId];
const privateName=nm("InitialOwnerPrivateAttempt"),privateFamily=nm("InitialOwnerPrivateFamily");
const privateCtorName=N.str(privateFamily,"mk");
const run=(cmds,start=session,graph=extendedInput)=>
 get("psKernelV1RunDag")(start,nil,safe,graph,list(cmds));
const invalidReference=value=>publicError(value,"rejectedInvalid","PSKERNEL_V2_DECODE_INVALID_REFERENCE");
const defRequest=(name,type,value,safety=safe)=>D.definitionDecl({
 base:{name,levelParams:nil,type},value,hints:hint,safety});
let positions=0;
for(const privateId of privateIds){
 must(privateId>=extendedInput.size,"metadata-IDs-outside-source");
 const privateBase={name:privateName,levelParams:nil,type:privateId};
 const validBase={name:privateName,levelParams:nil,type:natId};
 const privateType={name:privateFamily,type:privateId,ctors:nil};
 const privateCtor={name:privateFamily,type:s1Id,ctors:list([{name:privateCtorName,type:privateId}])};
 const dg=value=>({levelParams:nil,numParams:0n,types:list([value]),isUnsafe:false});
 const invalidCommands=[
  C.check(privateId),C.whnf(privateId),C.isDefEq(privateId,sevenId),C.isDefEq(sevenId,privateId),
  C.admit(D.axiomDecl(privateBase,false)),
  C.admit(D.definitionDecl({base:privateBase,value:sevenId,hints:hint,safety:safe})),
  C.admit(D.definitionDecl({base:validBase,value:privateId,hints:hint,safety:safe})),
  C.admit(D.theoremDecl(privateBase,sevenId)),C.admit(D.theoremDecl(validBase,privateId)),
  C.admit(D.opaqueDecl(privateBase,sevenId,false)),C.admit(D.opaqueDecl(validBase,privateId,false)),
  C.admit(D.mutualDefinitions(list([{
   base:privateBase,value:sevenId,hints:hint,safety:unit(get("PsKernelDefinitionSafety").unsafeDef)}]))),
  C.admit(D.mutualDefinitions(list([{
   base:validBase,value:privateId,hints:hint,safety:unit(get("PsKernelDefinitionSafety").unsafeDef)}]))),
  C.admit(D.ordinaryInductive(nil,0n,privateType,false)),
  C.admit(D.ordinaryInductive(nil,0n,privateCtor,false)),
  C.admit(D.mutualInductive(dg(privateType))),C.admit(D.mutualInductive(dg(privateCtor))),
  C.admit(D.nestedInductive(dg(privateType))),C.admit(D.nestedInductive(dg(privateCtor)))
 ];
 must(invalidCommands.length===19,"private-position-count");
 for(const command of invalidCommands){
  must(invalidReference(run([command])),"private-ID-never-becomes-an-external-input");positions++;
 }
}
must(positions===76,"private-matrix-complete");
const privateId=extendedInput.size;
const invalid=defRequest(nm("InitialOwnerBadDefinition"),s1Id,sevenId);
must(publicError(run([C.check(missingId),C.check(privateId)]),"rejectedInvalid","unknown constant"),
 "earlier-unknown-constant-before-later-private-ID");
must(publicError(run([C.admit(invalid),C.check(privateId)]),"rejectedInvalid","definition type mismatch"),
 "earlier-semantic-failure-before-later-private-ID");
const good=defRequest(freshName,natId,aliasId);
const admitted=accepted(run([C.admit(good),C.check(freshId)]),"real-second-batch-admission");
must(contains(admitted.session.environment,freshName)&&
 get("psKernelEnvironmentSize")(admitted.session.environment)===29n&&array(admitted.replies).length===2,
 "second-batch-admitted-real-reference");
must(invalidReference(run([C.admit(good),C.check(privateId)])),"late-private-failure-is-atomic");
must(publicError(run([C.admit(good),C.admit(invalid)]),"rejectedInvalid","definition type mismatch"),
 "late-semantic-failure-is-atomic");
must(!contains(session.environment,freshName)&&get("psKernelEnvironmentSize")(session.environment)===28n,
 "input-session-did-not-publish-partial-work");
must(publicError(get("psKernelV1CheckExpression")(session,nil,safe,cn(freshName)),
 "rejectedInvalid","unknown constant"),"later-call-cannot-see-private-publication");
const invalidArena={...get("psKernelExprV2PagedEmpty"),size:1n};
must(isError(get("psKernelExprV2PagedValidate")(invalidArena)),"actual-invalid-graph");
const ResourceError=get("PsKernelResourceError");
const resourceError=(value,kind,text)=>isError(value)&&same(
 value.error,ErrorTag.resourceExhausted(unit(ResourceError[kind]),text));
const cancelled={...session,resources:{...session.resources,cancelled:true}};
must(resourceError(run([C.check(0n)],cancelled,invalidArena),"cancelled",
 "resource policy declined operation before entry"),"cancellation-precedes-validation-and-import");
const zeroSession={...session,resources:{...session.resources,fuel:0n}};
must(resourceError(run([C.check(0n)],zeroSession,invalidArena),"fuel",
 "resource policy declined operation before entry"),"fuel-zero-precedes-validation-and-import");
const badProvider={...session.provider,target:{...session.provider.target,leanVersion:"mismatch"}};
const incompatible={...cancelled,provider:badProvider};
must(publicError(run([C.check(0n)],incompatible,invalidArena),"declinedUnsupported",
 "provider target does not match KernelContract-v1"),"provider-guard-precedes-resource-and-import");
const limited={...session,resources:{...session.resources,maxDeclarations:28n}};
must(resourceError(run([C.admit(good)],limited),"declarationLimit","declaration limit exceeded"),
 "declaration-limit-preserved");
const emptyBatch=accepted(run([]),"empty-second-batch");
must(array(emptyBatch.replies).length===0&&get("psKernelEnvironmentSize")(emptyBatch.session.environment)===28n,
 "empty-batch-retains-session");
const broken=get("psKernelExprV2DecodedPush")(extendedBuilt,s1);
const failedImport=get("psKernelDagInitialInstall")(
 environment,{arena:extendedInput,built:broken,declarations:nil});
must(isError(failedImport)&&failedImport.error==="PSKERNEL_V2_GENERATED_OWNER_MISMATCH",
 "internal-import-error-does-not-return-partial-owner");
console.log("PSC1_V2_INITIAL_OWNER_NAMESPACE_JS: PASS positions=76 precedence=2 atomic=3 guards=4");

const liveAlias=accepted(get("psKernelEnvironmentFind")(environment,aliasName),"checked-alias");
must(same(liveAlias,CI.defnInfo(liveAlias.value)),"checked-alias-kind");
const definition=liveAlias.value;
const stale=CI.defnInfo({...definition,base:{...definition.base,type:s1},value:E.sort(zero)});
const wrongKind=CI.axiomInfo({base:{...definition.base,type:s1},isUnsafe:false});
const phantomName=nm("InitialOwnerPhantomHistory");
const phantom=CI.axiomInfo({base:{name:phantomName,levelParams:nil,type:s1},isUnsafe:false});
const variants=[
 ["stale-type-and-body",{...environment,constants:list([stale])},1],
 ["missing-index",{...environment,constants:list([liveAlias]),index:get("psKernelEnvironmentEmpty").index},0],
 ["duplicate-history",{...environment,constants:list([stale,liveAlias,wrongKind])},3],
 ["index-only",{...environment,constants:nil},0],
 ["historical-wrong-kind",{...environment,constants:list([wrongKind])},1],
 ["phantom-history",{...environment,constants:list([phantom])},0]
];
source={arena:get("psKernelExprV2PagedEmpty"),built:get("psKernelExprV2DecodedEmpty"),declarations:nil};
const lookupRoot=inputExpr(cn(aliasName)),phantomRoot=inputExpr(cn(phantomName));
const lookupSource=source.arena,lookupBuilt=accepted(
 get("psKernelExprV2DecodeChecked")(lookupSource),"lookup-source");
const comparePublic=(label,reference,observed)=>{
 if(isError(reference)||isError(observed)){
  must(publicError(reference,"rejectedInvalid")&&publicError(observed,"rejectedInvalid")&&
   reference.error.message===observed.error.message,label+"-same-exact-rejection");
 }else{
  const expected=accepted(reference,label+"-reference"),result=accepted(observed,label+"-observed");
  const rows=array(result.replies);
  must(rows.length===1&&same(rows[0],Reply.checked(rows[0].value)),label+"-single-checked-reply");
  must(exact(rows[0].value.expression,expected.expression)&&exact(rows[0].value.type,expected.type),
   label+"-same-exact-checked-type");
 }
};
for(const [label,forged,expectedOwners] of variants){
 // Deliberately low-level trusted sessions; these are not newly admitted records.
 const trusted={...session,environment:forged};
 const installed=accepted(get("psKernelDagInitialInstall")(
  get("psKernelKernelSessionEnvironment")(trusted),
  {arena:lookupSource,built:lookupBuilt,declarations:nil}),label+"-install");
 must(array(installed.declarations).length===expectedOwners,label+"-owner-count");
 for(const owner of array(installed.declarations)){
  must(get("psKernelExprV2DeclarationRefMatches")(owner,liveAlias),label+"-live-kind");
  must(exact(definition.base.type,requireBuilt(installed.built,owner.type,"lookup-type")),
   label+"-live-type-not-history");
  const value=accepted(owner.deltaValue,label+"-live-body-owner");
  must(exact(definition.value,requireBuilt(installed.built,value,"lookup-body")),
   label+"-live-body-not-history");
 }
 comparePublic(label,get("psKernelV1CheckExpression")(trusted,nil,safe,cn(aliasName)),
  get("psKernelV1RunDag")(trusted,nil,safe,lookupSource,list([C.check(lookupRoot)])));
 comparePublic(label+"-phantom",get("psKernelV1CheckExpression")(trusted,nil,safe,cn(phantomName)),
  get("psKernelV1RunDag")(trusted,nil,safe,lookupSource,list([C.check(phantomRoot)])));
 const context=get("psKernelKernelSessionChecker")(trusted,nil,safe).context;
 const raw=get("psKernelExprV2TryCheckWithDeclarationsFuel")(
  4096n,context,installed.arena,installed.declarations,lookupRoot);
 if(expectedOwners>0){
  const checked=attempt(raw,label+"-raw-owned");
  must(exact(definition.base.type,decode(checked.fst,checked.snd)),label+"-raw-exact-live-type");
 }else if(same(get("psKernelEnvironmentFind")(forged,aliasName),none)){
  const refusal=accepted(raw,label+"-mandatory-missing-index-error");
  must(isError(refusal)&&refusal.error==="unknown constant",label+"-missing-index-never-authorizes");
 }else must(same(raw,none),label+"-index-only-explicit-fallback");
 must(same(findRef(installed.declarations,phantomName),none),label+"-phantom-never-installed");
}
console.log("PSC1_V2_INITIAL_OWNER_LIVE_INDEX_JS: PASS variants=6 public=12");
console.log("PSC1_V2_INITIAL_OWNER_JS: PASS checkedBatches=2 queries=12 assertions="+assertions);
