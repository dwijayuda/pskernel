import {pathToFileURL} from "node:url";
import path from "node:path";

// Every environment entry below comes from real checked admission. The test
// never imports an exported recursor body or supplies fabricated metadata.
const filename=process.argv[2];
if(!filename)throw Error("PSC1_GENERATED_OWNER_REQUIRES_KERNEL");
const k=await import(pathToFileURL(path.resolve(filename)).href);
const get=name=>{if(!(name in k))throw Error("PSC1_GENERATED_OWNER_MISSING_EXPORT "+name);return k[name];};
const unit=x=>typeof x==="function"?x():x;
let assertions=0;
const must=(condition,label)=>{if(condition!==true)throw Error("PSC1_GENERATED_OWNER_FAIL "+label);assertions++;};
const accepted=(x,label)=>{
 if(x&&typeof x==="object"&&Object.hasOwn(x,"value"))return x.value;
 const error=x&&typeof x==="object"&&Object.hasOwn(x,"error")?x.error:null;
 const detail=typeof error==="string"?error:
  error&&typeof error.message==="string"?error.message:"missing accepted value";
 throw Error("PSC1_GENERATED_OWNER_UNEXPECTED_REJECTION "+label+": "+detail);
};
const rejected=x=>Boolean(x&&typeof x==="object"&&Object.hasOwn(x,"error"));
const same=(left,right)=>{
 if(left===right)return true;
 if(left===null||right===null||typeof left!=="object"||typeof right!=="object")return false;
 const keys=Reflect.ownKeys(left),others=Reflect.ownKeys(right);
 return keys.length===others.length&&keys.every(key=>Object.hasOwn(right,key)&&same(left[key],right[key]));
};
const List=get("List"),nil=unit(List.nil),Option=get("Option"),none=unit(Option.none);
const list=xs=>xs.reduceRight((tail,head)=>List.cons(head,tail),nil);
const array=xs=>{const out=[];while(xs&&Object.hasOwn(xs,"head")){out.push(xs.head);xs=xs.tail;}return out;};
const N=get("PsKernelName"),E=get("PsKernelExpr"),L=get("PsKernelLevel"),B=get("PsKernelBinderInfo");
const Literal=get("PsKernelLiteral"),S=get("PsKernelDefinitionSafety"),CI=get("PsKernelConstantInfo");
const Request=get("PsKernelDeclarationRequest"),D=get("PsKernelDagDeclarationRequest");
const C=get("PsKernelDagCommand"),Reply=get("PsKernelDagReply"),ErrorTag=get("PsKernelError");
const name=text=>N.str(unit(N.anonymous),text),one=L.succ(unit(L.zero));
const safe=unit(S.safe),hints=unit(get("PsKernelReducibilityHints").abbrevHint);
let arena=get("psKernelExprV2PagedEmpty");
const build=(kind,term,...args)=>{
 const result=accepted(get("psKernelExprV2PagedMk"+kind)(arena,...args),"build-"+kind);
 arena=result.fst;return {term,id:result.snd};
};
const cn=(n,levels=[])=>build("Const",E.const(n,list(levels)),n,list(levels));
const sort=level=>build("Sort",E.sort(level),level);
const bv=index=>build("BVar",E.bvar(index),index);
const app=(f,a)=>build("App",E.app(f.term,a.term),f.id,a.id);
const apps=(f,args)=>args.reduce((x,y)=>app(x,y),f);
const lam=(n,t,b)=>build("Lam",E.lam(name(n),t.term,b.term,unit(B.default)),name(n),t.id,b.id,unit(B.default));
const all=(n,t,b)=>build("Forall",E.forallE(name(n),t.term,b.term,unit(B.default)),name(n),t.id,b.id,unit(B.default));
const lit=n=>build("Lit",E.lit(Literal.nat(n)),Literal.nat(n));
const natName=get("psKernelNatName"),nat=cn(natName),s1=sort(one);
const zero=cn(get("psKernelNatZeroName")),succ=n=>app(cn(get("psKernelNatSuccName")),n);
const leftName=name("OwnerLeft"),rightName=name("OwnerRight"),listName=name("OwnerList");
const treeName=name("OwnerTree"),plainName=name("OwnerPlain"),ctor=(n,s)=>N.str(n,s);
const family=(n,a,index)=>apps(cn(n),[a,index]),listOf=a=>app(cn(listName),a);
const tree=cn(treeName),trees=listOf(tree),plain=cn(plainName);
const empty=accepted(get("psKernelKernelSessionEmpty")(
 get("psKernelResourcePolicyDefault"),get("psKernelProviderDefault")),"empty");
let session=empty,originals=nil;
const commands=[],stages=[],requests=[];
const ordinary=(label,n,type,ctors,numParams)=>{
 const scalar={levelParams:nil,name:n,type:type.term,
  ctors:list(ctors.map(([name,type])=>({name,type:type.term}))),isUnsafe:false,numParams};
 const request=D.ordinaryInductive(nil,numParams,
  {name:n,type:type.id,ctors:list(ctors.map(([name,type])=>({name,type:type.id})))},false);
 session=accepted(get("psKernelV1AdmitDeclaration")(session,Request.ordinaryInductive(scalar)),label).session;
 originals=get("psKernelDagDeclarationsAfterAdmission")(request,originals);
 commands.push(C.admit(request));requests.push(request);stages.push(session);
};
const scalarGroup=spec=>({levelParams:nil,numParams:spec.numParams,isUnsafe:false,
 types:list(spec.types.map(t=>({name:t.name,type:t.type.term,
  ctors:list(t.ctors.map(([name,type])=>({name,type:type.term})))})))});
const dagGroup=spec=>({levelParams:nil,numParams:spec.numParams,isUnsafe:false,
 types:list(spec.types.map(t=>({name:t.name,type:t.type.id,
  ctors:list(t.ctors.map(([name,type])=>({name,type:type.id})))})))});
const admitGroup=(label,spec,nested)=>{
 const scalar=scalarGroup(spec),dag=dagGroup(spec);
 const kind=nested?"nestedInductive":"mutualInductive",request=D[kind](dag);
 session=accepted(get("psKernelV1AdmitDeclaration")(session,Request[kind](scalar)),label).session;
 originals=get("psKernelDagDeclarationsAfterAdmission")(request,originals);
 commands.push(C.admit(request));requests.push(request);stages.push(session);
 return {scalar,dag};
};
ordinary("Nat",natName,s1,[[get("psKernelNatZeroName"),nat],
 [get("psKernelNatSuccName"),all("n",nat,nat)]],0n);
ordinary("OwnerList",listName,all("A",s1,s1),[
 [ctor(listName,"nil"),all("A",s1,listOf(bv(0n)))],
 [ctor(listName,"cons"),all("A",s1,all("head",bv(0n),all("tail",listOf(bv(1n)),listOf(bv(2n)))))]
],1n);
const foundationSession=session,foundationCommands=[...commands];
const mutualType=(n,other)=>({name:n,type:all("A",s1,all("n",nat,s1)),ctors:[
 [ctor(n,"base"),all("A",s1,all("value",bv(0n),family(n,bv(1n),zero)))],
 [ctor(n,"step"),all("A",s1,all("n",nat,all("other",family(other,bv(1n),bv(0n)),
  family(n,bv(2n),succ(bv(1n))))))]
]});
const mutualGroup=admitGroup("mutual-parameter-index",
 {numParams:1n,types:[mutualType(leftName,rightName),mutualType(rightName,leftName)]},false);
const treeGroup=admitGroup("nested-auxiliary",{numParams:0n,types:[{name:treeName,type:s1,ctors:[
 [ctor(treeName,"leaf"),all("value",nat,tree)],[ctor(treeName,"branch"),all("children",trees,tree)]
]}]},true);
const plainGroup=admitGroup("nested-no-auxiliary",{numParams:0n,types:[{name:plainName,type:s1,ctors:[
 [ctor(plainName,"zero"),plain],[ctor(plainName,"step"),all("previous",plain,plain)]
]}]},true);
const recName=n=>get("psKernelSimpleRecName")(n);
const mainRec=recName(treeName),auxRec=get("psKernelNameAppendIndexAfter")(mainRec,1n);
const mutualMotive=n=>lam("n",nat,lam("major",family(n,nat,bv(0n)),nat));
const mutualBaseMinor=()=>lam("value",nat,bv(0n));
const mutualStepMinor=other=>lam("n",nat,lam("other",family(other,nat,bv(0n)),lam("ih",nat,bv(0n))));
const mutualRec=(n,index,major)=>apps(cn(recName(n),[one]),[
 nat,mutualMotive(leftName),mutualMotive(rightName),
 mutualBaseMinor(),mutualStepMinor(rightName),mutualBaseMinor(),mutualStepMinor(leftName),index,major]);
const mutualBase=(n,value)=>apps(cn(ctor(n,"base")),[nat,lit(value)]);
const mutualStep=(n,index,major)=>apps(cn(ctor(n,"step")),[nat,index,major]);
const treeLeaf=value=>app(cn(ctor(treeName,"leaf")),lit(value));
const treeNil=app(cn(ctor(listName,"nil")),tree);
const treeCons=(head,tail)=>apps(cn(ctor(listName,"cons")),[tree,head,tail]);
const treeRec=(n,major)=>apps(cn(n,[one]),[
 lam("tree",tree,nat),lam("trees",trees,nat),lam("value",nat,bv(0n)),
 lam("children",trees,lam("ih",nat,bv(0n))),lit(0n),
 lam("head",tree,lam("tail",trees,lam("headIH",nat,lam("tailIH",nat,bv(1n))))),major]);
const plainRec=major=>apps(cn(recName(plainName),[one]),[
 lam("major",plain,nat),lit(5n),lam("previous",plain,lam("ih",nat,bv(0n))),major]);
const left7=mutualBase(leftName,7n),right9=mutualBase(rightName,9n);
const leftStep9=mutualStep(leftName,zero,right9),rightStep7=mutualStep(rightName,zero,left7);
const children=treeCons(treeLeaf(7n),treeNil);
const fixtures=[
 ["mutual-left-base",mutualRec(leftName,zero,left7),lit(7n)],
 ["mutual-right-base",mutualRec(rightName,zero,right9),lit(9n)],
 ["mutual-left-cross",mutualRec(leftName,succ(zero),leftStep9),lit(9n)],
 ["mutual-right-cross",mutualRec(rightName,succ(zero),rightStep7),lit(7n)],
 ["mutual-left-two",mutualRec(leftName,succ(succ(zero)),mutualStep(leftName,succ(zero),rightStep7)),lit(7n)],
 ["mutual-right-two",mutualRec(rightName,succ(succ(zero)),mutualStep(rightName,succ(zero),leftStep9)),lit(9n)],
 ["nested-leaf",treeRec(mainRec,treeLeaf(7n)),lit(7n)],
 ["nested-branch",treeRec(mainRec,app(cn(ctor(treeName,"branch")),children)),lit(7n)],
 ["nested-aux-nil",treeRec(auxRec,treeNil),lit(0n)],
 ["nested-aux-cons",treeRec(auxRec,children),lit(7n)],
 ["nested-no-aux-zero",plainRec(cn(ctor(plainName,"zero"))),lit(5n)],
 ["nested-no-aux-step",plainRec(app(cn(ctor(plainName,"step")),cn(ctor(plainName,"zero")))),lit(5n)]
];
const missing=cn(name("OwnerMissingDependency"));
const badMutualSpec={numParams:1n,types:[{
 name:leftName,type:all("A",s1,all("n",nat,s1)),ctors:[
  [ctor(leftName,"base"),all("A",s1,all("value",bv(0n),family(rightName,bv(1n),zero)))]]
},mutualType(rightName,leftName)]};
const badTreeSpec={numParams:0n,types:[{name:treeName,type:s1,ctors:[
 [ctor(treeName,"leaf"),all("value",nat,trees)],[ctor(treeName,"branch"),all("children",trees,tree)]
]}]};
const badMutual={scalar:scalarGroup(badMutualSpec),dag:dagGroup(badMutualSpec)};
const badTree={scalar:scalarGroup(badTreeSpec),dag:dagGroup(badTreeSpec)};
const input=arena,built=accepted(get("psKernelExprV2DecodeChecked")(input),"source-decode");
let generated={arena:input,built,declarations:nil};
for(let i=0;i<commands.length;i++){
 generated={...generated,declarations:get("psKernelDagDeclarationsAfterAdmission")(requests[i],generated.declarations)};
 generated=accepted(get("psKernelDagGeneratedAfterCommand")(
  commands[i],stages[i].environment,generated),"install-real-admitted-owner");
}
const exprEq=(a,b)=>get("psKernelExprEq")(a)(b);
const exact=(a,b)=>get("psKernelExprEqual")(a)(b);
const decoded=(owned,id)=>accepted(get("psKernelExprV2DecodedRequire")(
 accepted(get("psKernelExprV2DecodeChecked")(owned),"decode"),id),"decoded-root");
const state=()=>get("psKernelExprV2CheckStateWithWhnf")(
 get("psKernelExprV2CheckStateEmpty")(generated.arena),
 get("psKernelExprV2WhnfStateForDeclarations")(generated.arena,generated.declarations));
const find=n=>accepted(get("psKernelEnvironmentFind")(session.environment,n),"checked-live-info");
const recursor=n=>{
 const info=find(n);must(same(info,CI.recInfo(info.value)),"live-recursor-kind");return info.value;
};
const inductive=n=>{
 const info=find(n);must(same(info,CI.inductInfo(info.value)),"live-inductive-kind");return info.value;
};
accepted(get("psKernelExprV2PagedValidate")(generated.arena),"validate-generated-arena");
must(generated.arena.size===generated.built.size&&generated.arena.size>input.size,"owner-size-and-private-extension");
must(array(generated.declarations).length===25,"all-25-live-owners");
for(let index=0n;index<input.size;index++){
 must(exact(accepted(get("psKernelExprV2DecodedRequire")(built,index),"original"),
  accepted(get("psKernelExprV2DecodedRequire")(generated.built,index),"retained")),"original-source-ID-unchanged");
}
let recursors=0,rules=0;
for(const owner of array(generated.declarations)){
 const info=find(owner.name);
 must(get("psKernelExprV2DeclarationRefMatches")(owner,info)&&same(owner.deltaValue,none),
  "owner-matches-final-admitted-kind");
 must(exact(get("psKernelConstantInfoType")(info),decoded(generated.arena,owner.type)),
  "owner-type-is-exact-final-admitted-type");
 if(same(info,CI.recInfo(info.value))){
  recursors++;must(owner.type>=input.size,"generated-recursor-type-is-private");
  for(const rule of array(info.value.rules)){
   const rhs=accepted(get("psKernelExprV2RecursorRuleOwner")(generated.declarations,info.value,rule),"rule-owner");
   must(exact(rule.rhs,decoded(generated.arena,rhs)),"rule-is-exact-final-admitted-RHS");rules++;
  }
 }
}
must(recursors===7&&rules===14,"all-seven-recursors-and-fourteen-rules");
for(const original of array(originals)){
 const installed=accepted(get("psKernelExprV2DeclarationRefFind")(generated.declarations)(original.name),"original-owner");
 must(installed.type===original.type&&original.type<input.size,
  "ordinary-mutual-original-header-constructor-IDs-retained");
}
const leftInfo=inductive(leftName),rightInfo=inductive(rightName);
must(leftInfo.isRec&&rightInfo.isRec&&leftInfo.numParams===1n&&rightInfo.numParams===1n&&
 leftInfo.numIndices===1n&&rightInfo.numIndices===1n&&array(leftInfo.all).length===2&&
 array(rightInfo.all).length===2,"mutual-is-cross-recursive-parameterized-and-indexed");
must(inductive(treeName).numNested===1n&&inductive(plainName).numNested===0n,"genuine-nested-and-no-aux-routes");
for(const n of [treeName,ctor(treeName,"leaf"),ctor(treeName,"branch"),
 plainName,ctor(plainName,"zero"),ctor(plainName,"step")]){
 const owner=accepted(get("psKernelExprV2DeclarationRefFind")(generated.declarations)(n),"restored-owner");
 must(owner.type>=input.size,"nested-header-and-constructor-owned-from-restored-metadata");
}
for(const n of [leftName,rightName]){
 const info=recursor(recName(n));
 must(info.numParams===1n&&info.numIndices===1n&&info.numMotives===2n&&info.numMinors===4n&&
  array(info.base.levelParams).length===1&&info.k===false,"both-mutual-recursor-metadata");
}
for(const n of [mainRec,auxRec]){
 const info=recursor(n);
 must(info.numParams===0n&&info.numIndices===0n&&info.numMotives===2n&&info.numMinors===4n&&
  array(info.base.levelParams).length===1&&info.k===false,"main-and-renamed-auxiliary-recursor-metadata");
}
const environment=session.environment;
const before={arena:input,built,declarations:originals};
const planMutual=g=>get("psKernelDagGeneratedPlanMutual")(g,environment);
const planNested=(g,env=environment)=>get("psKernelDagGeneratedPlanNested")(g,env);
must(array(accepted(planMutual(mutualGroup.dag),"mutual-plan")).length===2&&
 array(accepted(planNested(treeGroup.dag),"nested-plan")).length===5&&
 array(accepted(planNested(plainGroup.dag),"no-aux-plan")).length===4,"complete-plans-before-import");
const members=array(mutualGroup.dag.types);
const missingMember={...mutualGroup.dag,types:list([members[0],{...members[1],name:name("OwnerMissingMember")}])};
const wrongParameters={...mutualGroup.dag,numParams:2n};
const wrongLevels={...treeGroup.dag,levelParams:list([name("ownerUnexpectedLevel")])};
const unchanged=(label,command,env=environment)=>{
 const after=accepted(get("psKernelDagGeneratedAfterCommand")(command,env,before),label);
 must(same(after,before),label+"-no-private-import-or-owner-publication");
};
for(const [label,group] of [["missing-later-mutual-member",missingMember],["mismatched-parameter-count",wrongParameters]]){
 must(same(planMutual(group),none),label+"-plan-refusal");
 unchanged(label,C.admit(D.mutualInductive(group)));
}
must(same(planNested(wrongLevels),none),"nested-mismatched-levels-refusal");
unchanged("nested-mismatched-levels",C.admit(D.nestedInductive(wrongLevels)));
must(same(planNested(treeGroup.dag,foundationSession.environment),none),"no-owner-from-unadmitted-environment");
unchanged("no-owner-from-unadmitted-environment",C.admit(D.nestedInductive(treeGroup.dag)),foundationSession.environment);

const base=get("psKernelKernelSessionChecker")(session,nil,safe);
const checkContext=c=>get("psKernelExprV2CheckContextEmpty")(c);
const check=(fuel,c,s,root)=>get("psKernelExprV2TryCheckStateWithFuel")(fuel,c,s,root);
const whnf=(fuel,c,s,root)=>get("psKernelExprV2TryWhnfCheckStateWithFuel")(fuel,c,s,root);
const defeq=(fuel,c,s,left,right)=>get("psKernelExprV2TryDefEqStateWithFuel")(fuel)(c)(s)(left)(right);
const unowned=get("psKernelExprV2CheckStateWithWhnf")(get("psKernelExprV2CheckStateEmpty")(input),
 get("psKernelExprV2WhnfStateForDeclarations")(input,originals));
for(const [label,term] of fixtures){
 must(same(check(4096n,checkContext(base.context),unowned,term.id),none),label+"-new-owner-is-required");
}
const compareExpr=(label,original,actual)=>{
 const owned=accepted(actual,label+"-mandatory-Some");
 if(rejected(original)){must(rejected(owned)&&original.error===owned.error,label+"-exact-error");return;}
 const left=accepted(original,label+"-V1"),right=accepted(owned,label+"-V2");
 must(exact(left.fst,decoded(right.fst.whnf.arena,right.snd)),label+"-exact-expression");
};
const compareBool=(label,original,actual)=>{
 const owned=accepted(actual,label+"-mandatory-Some");
 if(rejected(original)){must(rejected(owned)&&original.error===owned.error,label+"-exact-error");return;}
 const left=accepted(original,label+"-V1"),right=accepted(owned,label+"-V2");
 must(left.fst===right.snd,label+"-exact-boolean");
};
let checks=0,reductions=0,equalities=0;
for(const [label,term,expected] of fixtures){
 for(const fuel of [0n,1n,2n,4n,16n,64n])for(const [maxRecDepth,recDepth] of [[0n,0n],[1n,15n],[1n,16n]]){
  const context={...base.context,maxRecDepth,recDepth},scalar={...base,context},ownedContext=checkContext(context);
  compareExpr(label+"-check",get("psKernelSessionCheck")(fuel,scalar,term.term),
   check(fuel,ownedContext,state(),term.id));checks++;
  compareExpr(label+"-WHNF",get("psKernelSessionWhnf")(fuel,scalar,term.term),
   whnf(fuel,ownedContext,state(),term.id));reductions++;
  compareBool(label+"-DefEq",get("psKernelSessionIsDefEq")(fuel,scalar,term.term,expected.term),
   defeq(fuel,ownedContext,state(),term.id,expected.id));equalities++;
 }
 const c=checkContext(base.context);
 const checked=accepted(accepted(check(4096n,c,state(),term.id),label+"-complete-owned-check-Some"),label+"-complete-owned-check");
 must(exprEq(decoded(checked.fst.whnf.arena,checked.snd),nat.term),label+"-owned-check-is-Nat");
 const reduced=accepted(accepted(whnf(4096n,c,state(),term.id),label+"-complete-owned-WHNF-Some"),label+"-complete-owned-WHNF");
 must(exprEq(decoded(reduced.fst.whnf.arena,reduced.snd),expected.term),label+"-owned-WHNF-value");
 const equal=accepted(accepted(defeq(4096n,c,state(),term.id,expected.id),label+"-complete-owned-DefEq-Some"),
  label+"-complete-owned-DefEq");
 must(equal.snd===true,label+"-owned-DefEq-success");
}
must(checks===216&&reductions===216&&equalities===216,"complete-resource-matrices");
const run=(extra,prefix=commands)=>get("psKernelV1RunDag")(empty,nil,safe,input,list([...prefix,...extra]));
const query=fixtures.flatMap(([,term,expected])=>[C.check(term.id),C.whnf(term.id),C.isDefEq(term.id,expected.id)]);
const result=accepted(run(query),"complete-owner-batch");
const replies=array(result.replies).slice(commands.length);
must(replies.length===36&&query.length===36,"exact-public-36-reply-protocol");
fixtures.forEach(([label,term,expected],i)=>{
 const checked=replies[i*3],reduced=replies[i*3+1],equal=replies[i*3+2];
 must(same(checked,Reply.checked(checked.value))&&exprEq(checked.value.type,nat.term)&&
  exact(checked.value.expression,term.term),label+"-public-check");
 must(same(reduced,Reply.normalized(reduced.value))&&exprEq(reduced.value,expected.term),label+"-public-WHNF");
 must(same(equal,Reply.equal(true)),label+"-public-DefEq");
});
const first=fixtures[0][1],firstExpected=fixtures[0][2];
const definition={base:{name:name("OwnerBatchDefinition"),levelParams:nil,type:nat.id},
 value:first.id,hints,safety:safe};
const admitted=accepted(run([C.admit(D.definitionDecl(definition)),C.check(first.id),
 C.isDefEq(first.id,firstExpected.id)]),"real-checked-definition");
const final=array(admitted.replies);
must(final.length===commands.length+3&&same(final.at(-1),Reply.equal(true))&&
 same(final.at(-2),Reply.checked(final.at(-2).value))&&
 same(final.at(-3),Reply.admitted(final.at(-3).receipt)),"real-definition-checked-and-compared");
const invalid=x=>rejected(x)&&x.error&&typeof x.error.message==="string"&&
 same(x.error,ErrorTag.rejectedInvalid(x.error.message));
const sameRejection=(label,original,actual)=>{
 must(invalid(original)&&invalid(actual),label+"-classified-invalid");
 must(same(original.error,actual.error),label+"-exact-rejection");
};
sameRejection("invalid-mutual",
 get("psKernelV1AdmitDeclaration")(foundationSession,Request.mutualInductive(badMutual.scalar)),
 run([C.admit(D.mutualInductive(badMutual.dag))],foundationCommands));
sameRejection("invalid-nested",
 get("psKernelV1AdmitDeclaration")(foundationSession,Request.nestedInductive(badTree.scalar)),
 run([C.admit(D.nestedInductive(badTree.dag))],foundationCommands));
sameRejection("duplicate-mutual",get("psKernelV1AdmitDeclaration")(session,Request.mutualInductive(mutualGroup.scalar)),
 run([C.admit(D.mutualInductive(mutualGroup.dag))]));
for(const [label,type,value] of [["OwnerWrongType",s1,first],["OwnerMissingValue",nat,missing]]){
 const scalar={base:{name:name(label),levelParams:nil,type:type.term},value:value.term,hints,safety:safe};
 const dag={base:{name:name(label),levelParams:nil,type:type.id},value:value.id,hints,safety:safe};
 sameRejection(label,get("psKernelV1AdmitDeclaration")(session,Request.definitionDecl(scalar)),
  run([C.admit(D.definitionDecl(dag))]));
}
let independentDefinitions=0;
for(const [label,term] of fixtures){
 accepted(get("psKernelV1AdmitDeclaration")(session,Request.definitionDecl({
  base:{name:name("official-"+label),levelParams:nil,type:nat.term},value:term.term,hints,safety:safe
 })),label+"-independent-real-definition");independentDefinitions++;
}
must(independentDefinitions===12,"twelve-independent-real-definitions");
const privateId=input.size;
const privateHeader={name:name("OwnerPrivateHeader"),levelParams:nil,type:privateId};
const publicHeader={name:name("OwnerPrivateBody"),levelParams:nil,type:nat.id};
const privateDefinition={base:publicHeader,value:privateId,hints,safety:safe};
const badHeader={name:name("OwnerPrivateFamily"),type:privateId,ctors:nil};
const badCtor={name:name("OwnerPrivateFamily"),type:s1.id,ctors:list([{name:name("OwnerPrivateCtor"),type:privateId}])};
const privateCommands=[
 C.check(privateId),C.whnf(privateId),C.isDefEq(privateId,nat.id),C.isDefEq(nat.id,privateId),
 C.admit(D.axiomDecl(privateHeader,false)),C.admit(D.definitionDecl(privateDefinition)),
 C.admit(D.theoremDecl(publicHeader,privateId)),C.admit(D.opaqueDecl(publicHeader,privateId,false)),
 C.admit(D.mutualDefinitions(list([privateDefinition]))),
 C.admit(D.ordinaryInductive(nil,0n,badHeader,false)),C.admit(D.ordinaryInductive(nil,0n,badCtor,false)),
 C.admit(D.mutualInductive({levelParams:nil,numParams:0n,types:list([badHeader]),isUnsafe:false})),
 C.admit(D.nestedInductive({levelParams:nil,numParams:0n,types:list([badCtor]),isUnsafe:false}))
];
const invalidReference=x=>invalid(x)&&x.error.message==="PSKERNEL_V2_DECODE_INVALID_REFERENCE";
for(const command of privateCommands){
 must(invalidReference(run([command])),"public-appended-ID-remains-invalid");
 must(invalidReference(get("psKernelDagRunCommandWithSource")(built,
  {session,declarations:generated.declarations},nil,safe,generated.arena,generated.built,command)),
  "original-source-namespace-before-extended-owner");
}
must(privateCommands.length===13,"all-thirteen-private-input-forms");
const early=run([C.admit(D.unsupported("OWNER_ORDER_SENTINEL")),C.check(privateId)]);
must(rejected(early)&&same(early.error,ErrorTag.declinedUnsupported("OWNER_ORDER_SENTINEL")),
 "earlier-unsupported-error-precedes-private-ID");
must(invalidReference(run([C.check(privateId),C.admit(D.unsupported("OWNER_ORDER_SENTINEL"))])),
 "private-ID-error-precedes-later-unsupported");
must(same(get("psKernelEnvironmentFind")(empty.environment,leftName),none)&&
 same(get("psKernelEnvironmentFind")(foundationSession.environment,treeName),none),
 "failed-batch-publishes-no-session-or-declarations");
accepted(run([]),"fresh-success-after-failed-batch");
must(fixtures.length===12,"all-twelve-real-recursor-cases");
console.log("PSC1_V2_GENERATED_OWNER_JS_PASS owners=25 recursors=7 rules=14 cases=12 checks=216 whnf=216 defeq=216 private=13 independentDefinitions=12 assertions="+assertions);
