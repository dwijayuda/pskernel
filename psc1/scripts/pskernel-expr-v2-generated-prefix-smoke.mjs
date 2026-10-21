import {pathToFileURL} from "node:url";
import path from "node:path";

const filename=process.argv[2];
if(!filename)throw Error("PSC1_V2_PREFIX_REQUIRES_GENERATED_KERNEL");
const k=await import(pathToFileURL(path.resolve(filename)).href);
const get=name=>{if(!(name in k))throw Error("PSC1_V2_PREFIX_MISSING_EXPORT "+name);return k[name];};
const unit=x=>typeof x==="function"?x():x;
const same=(a,b)=>{
 if(a===b)return true;
 if(a===null||b===null||typeof a!=="object"||typeof b!=="object")return false;
 const keys=Reflect.ownKeys(a),other=Reflect.ownKeys(b);
 return keys.length===other.length&&keys.every(key=>Object.hasOwn(b,key)&&same(a[key],b[key]));
};
let assertions=0;
const must=(condition,label)=>{
 if(condition!==true)throw Error("PSC1_V2_PREFIX_FAIL "+label);
 assertions++;
};
const accepted=(value,label)=>{
 if(value&&typeof value==="object"&&Object.hasOwn(value,"value"))return value.value;
 const error=value&&typeof value==="object"&&Object.hasOwn(value,"error")?value.error:null;
 const text=typeof error==="string"?error:error?.message??"missing accepted value";
 throw Error("PSC1_V2_PREFIX_REJECTED "+label+": "+text);
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
for(let i=0n;i<32n;i++)axiom(N.num(nm("PrefixOld"),i));
const oldSession=session;
const root=N.num(nm("PrefixOwner"),7n),a=N.str(root,"Left"),b=N.str(root,"Right");
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
const treeSession=session,treeCommands=[...commands];
const fastName=N.str(root,"Fast"),fastCtor=N.str(fastName,"mk");
group(true,{levelParams:nil,numParams:0n,isUnsafe:false,
 types:list([family(fastName,s1,[ctor(fastCtor,cn(fastName))])])});
const fastTransition=transitions.at(-1);
axiom(N.str(root,"after"));
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
const cases=[
 ["mutual-left",recApplication(aRec,[u,v],app(cn(amk,[zero,zero]),[cn(bbase,[zero,zero])]))],
 ["mutual-right",recApplication(bRec,[u,v],app(cn(bmk,[zero,zero]),[cn(abase,[zero,zero])]))],
 ["nested-leaf",recApplication(treeRec,[],leaf)],
 ["nested-branch",recApplication(treeRec,[],app(cn(branchName),[listCons]))],
 ["nested-aux",recApplication(aux,[],listCons)],
 ["nested-no-aux",recApplication(fastRec,[],cn(fastCtor))]
].map(([label,term])=>({label,term,root:inputExpr(term)}));
const fastCtorId=inputExpr(cn(fastCtor)),sevenId=inputExpr(seven),input=source.arena;
const built=accepted(get("psKernelExprV2DecodeChecked")(input),"input-decode");
accepted(get("psKernelExprV2PagedValidate")(input),"input-validate");
let generated={arena:input,built,declarations:nil},newCount=0,recCount=0;
for(const transition of transitions){
 const refs=get("psKernelDagDeclarationsAfterAdmission")(transition.request,nil);
 generated={...generated,declarations:get("psKernelDagDeclarationsAfterAdmission")(
  transition.request,generated.declarations)};
 const before=generated;
 generated=accepted(get("psKernelDagGeneratedAfterCommandWithPrevious")(
  C.admit(transition.request),transition.previous,transition.current,generated),"install-final-prefix");
 if(transition.kind==="axiom"){
  must(generated.arena.size===before.arena.size&&
   array(generated.declarations).length===array(before.declarations).length,"noninductive-identity");
  continue;
 }
 const delta=newPrefix(transition.previous,transition.current);
 newCount+=delta.length;
 for(const info of delta){
  const name=infoName(info),owner=accepted(findRef(generated.declarations,name),"final-owner");
  must(get("psKernelExprV2DeclarationRefMatches")(owner,info)&&same(owner.deltaValue,none)&&
   exact(get("psKernelConstantInfoType")(info),decode(generated.arena,owner.type)),"final-type-kind-no-delta");
  const original=findRef(refs,name);
  if(!same(original,none)){
   const old=accepted(original,"input-owner");
   must(old.type>0n&&old.type===owner.type&&owner.type<input.size,"exact-original-input-ID");
   must(array(generated.declarations).filter(row=>nEq(row.name,name)).length===1,"no-duplicate-input-owner");
  }else must(owner.type>=input.size,"generated-restored-ID-private");
  if(isRec(info)){
   recCount++;
   for(const rule of array(info.value.rules)){
    const rhs=accepted(get("psKernelExprV2RecursorRuleOwner")(generated.declarations,info.value,rule),"rule-owner");
    must(exact(rule.rhs,decode(generated.arena,rhs)),"final-rule-exact");
   }
  }
 }
 must(generated.arena.size===generated.built.size,"complete-arena-built-state");
 const oldHead=transition.previous.constants&&Object.hasOwn(transition.previous.constants,"head")?
  transition.previous.constants.head:null;
 if(oldHead){
  const poison=CI.axiomInfo({base:{name:nm("PREFIX_POISON"),levelParams:nil,type:s1},isUnsafe:false});
  const boundary=accepted(get("psKernelDagGeneratedInstallNewPrefix")(
   list([...delta,oldHead,poison]),transition.previous,refs,before),"boundary-before-poison-tail");
  must(boundary.arena.size===generated.arena.size&&
   array(boundary.declarations).length===array(generated.declarations).length,"old-entry-stops-tail");
 }
}
// Nat4 + mutual8 + List4 + nested Tree5 + Fast3 =24 final declarations.
must(newCount===24&&recCount===7,"bounded-new-prefix-counts");
for(const owner of array(generated.declarations))must(contains(session.environment,owner.name),"no-flattening-only-owner");
for(let i=0n;i<input.size;i++)must(exact(
 accepted(get("psKernelExprV2DecodedRequire")(built,i),"input-original"),
 accepted(get("psKernelExprV2DecodedRequire")(generated.built,i),"input-after")),"input-IDs-stable");
const scalar=get("psKernelKernelSessionChecker")(session,nil,safe).context;
for(const {label,term,root} of cases){
 const checked=attempt(get("psKernelExprV2TryCheckWithDeclarationsFuel")(
  4096n,scalar,generated.arena,generated.declarations,root),label+"-check");
 const actualType=decode(checked.fst,checked.snd);
 must(exact(nat,accepted(get("psKernelV1Whnf")(session,nil,safe,actualType),label+"-type-WHNF")),label+"-type");
 const normalized=attempt(get("psKernelExprV2TryWhnfOwnedWithDeclarationsFuel")(
  4096n,scalar,generated.arena,generated.declarations,root),label+"-WHNF");
 must(exact(seven,decode(normalized.fst,normalized.snd)),label+"-iota");
 must(attempt(get("psKernelExprV2TryDefEqWithDeclarationsFuel")(
  4096n,scalar,generated.arena,generated.declarations,root,sevenId),label+"-defeq"),label+"-equal");
 must(exact(seven,accepted(get("psKernelV1Whnf")(session,nil,safe,term),label+"-V1")),label+"-V1-result");
 const positive={base:{name:nm(label+"-checked"),levelParams:nil,type:nat},value:term,hints:hint,safety:safe};
 accepted(get("psKernelV1AdmitDeclaration")(session,Request.definitionDecl(positive)),label+"-definition");
 must(rejected(get("psKernelV1AdmitDeclaration")(session,Request.definitionDecl({
  ...positive,base:{...positive.base,type:s1}}))),label+"-invalid-definition");
}
const run=(start,cmds)=>get("psKernelV1RunDag")(start,nil,safe,input,list(cmds));
const result=accepted(run(empty,[...commands,...cases.flatMap(({root})=>[
 C.check(root),C.whnf(root),C.isDefEq(root,sevenId)])]),"whole-batch");
must(array(result.replies).length===commands.length+18,"whole-batch-complete");
const firstBatch=accepted(run(empty,treeCommands),"first-batch");
const secondBatch=accepted(run(firstBatch.session,[C.admit(fastTransition.request),C.check(fastCtorId)]),"second-batch");
must(array(secondBatch.replies).length===2,"two-public-batches");
const secondAdmitted=accepted(get("psKernelDagRunCommand")(
 {session:firstBatch.session,declarations:nil},nil,safe,input,built,C.admit(fastTransition.request)),"second-admitted");
const secondOwner=accepted(get("psKernelDagGeneratedAfterCommandWithPrevious")(
 C.admit(fastTransition.request),firstBatch.session.environment,secondAdmitted.snd.session.environment,
 {arena:input,built,declarations:secondAdmitted.snd.declarations}),"second-owner");
must(same(findRef(secondOwner.declarations,get("psKernelNatName")),none),"no-invented-old-session-refs");
const secondScalar=get("psKernelKernelSessionChecker")(secondAdmitted.snd.session,nil,safe).context;
const secondChecked=attempt(get("psKernelExprV2TryCheckWithDeclarationsFuel")(
 4096n,secondScalar,secondOwner.arena,secondOwner.declarations,fastCtorId),"second-direct-new-constructor");
must(exact(cn(fastName),decode(secondChecked.fst,secondChecked.snd)),"second-direct-type");
for(const command of [C.check(input.size),C.whnf(input.size),C.isDefEq(input.size,sevenId)]){
 must(publicError(run(empty,[...commands,command]),"rejectedInvalid","PSKERNEL_V2_DECODE_INVALID_REFERENCE"),
  "private-generated-ID-refused");
}
must(rejected(run(empty,[...commands,C.admit(mutualTransition.request)])),"late-invalid-command-atomic");
must(!contains(empty.environment,a)&&!contains(oldSession.environment,a),"original-session-unchanged");
const broken=get("psKernelExprV2DecodedPush")(built,s1);
const brokenResult=get("psKernelDagRunCommandsWithSource")(list(commands))(built)(
 {session:empty,declarations:nil})(nil)(safe)(input)(broken);
must(publicError(brokenResult,"internalError","PSKERNEL_V2_GENERATED_OWNER_MISMATCH"),"internal-import-no-publication");
const poison=CI.axiomInfo({base:{name:nm("PREFIX_LATE_POISON"),levelParams:nil,type:s1},isUnsafe:false});
const late=get("psKernelDagGeneratedInstallNewPrefix")(
 list([CI.recInfo(aRec),poison]),oldSession.environment,nil,{arena:input,built,declarations:nil});
must(isError(late)&&late.error==="PSKERNEL_V2_GENERATED_PREFIX_KIND","late-kind-error-after-first-import");
const missing=list(array(generated.declarations).filter(owner=>!nEq(owner.name,aRec.base.name)));
const aOwner=accepted(findRef(generated.declarations,aRec.base.name),"a-owner");
const mismatched=List.cons({...aOwner,kind:unit(Kind.axiomDecl)},missing);
for(const rule of array(aRec.rules)){
 must(same(get("psKernelExprV2RecursorRuleOwner")(missing,aRec,rule),none),"missing-rule-owner");
 must(same(get("psKernelExprV2RecursorRuleOwner")(mismatched,aRec,rule),none),"mismatched-rule-owner");
}
for(const owners of [missing,mismatched])must(same(
 get("psKernelExprV2TryWhnfOwnedWithDeclarationsFuel")(4096n,scalar,generated.arena,owners,cases[0].root),
 none),"missing-or-mismatched-owner-direct-decline");
const negative=accepted(get("psKernelExprV2PagedMkConst")(generated.arena,aRec.base.name,nil),"negative-root");
const wrong=accepted(get("psKernelExprV2TryCheckWithDeclarationsFuel")(
 4096n,scalar,negative.fst,missing,negative.snd),"wrong-universe-direct");
must(isError(wrong)&&wrong.error==="incorrect number of universe levels","wrong-universe-before-owner");
must(rejected(get("psKernelV1CheckExpression")(session,nil,safe,cn(aRec.base.name))),"wrong-universe-public");
console.log("PSC1_V2_GENERATED_PREFIX_JS: PASS new=24 recursors=7 direct=6 privateIDs=3");
console.log("PSC1_V2_GENERATED_PREFIX_CONTROLS_JS: PASS positive=6 negative=7 assertions="+assertions);
