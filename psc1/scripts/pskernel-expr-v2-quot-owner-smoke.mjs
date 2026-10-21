import {pathToFileURL} from "node:url";
import path from "node:path";

// Positive metadata comes only from real checked admission. Deliberately
// damaged records below are confined to plan-refusal and owner-repair tests.
const filename=process.argv[2];
if(!filename)throw Error("PSC1_QUOT_OWNER_REQUIRES_KERNEL");
const k=await import(pathToFileURL(path.resolve(filename)).href);
const get=name=>{if(!(name in k))throw Error("PSC1_QUOT_OWNER_MISSING_EXPORT "+name);return k[name];};
const unit=x=>typeof x==="function"?x():x;
let assertions=0;
const must=(condition,label)=>{if(condition!==true)throw Error("PSC1_QUOT_OWNER_FAIL "+label);assertions++;};
const accepted=(x,label)=>{
 if(x&&typeof x==="object"&&Object.hasOwn(x,"value"))return x.value;
 const error=x&&typeof x==="object"&&Object.hasOwn(x,"error")?x.error:null;
 const detail=typeof error==="string"?error:
  error&&typeof error.message==="string"?error.message:"missing accepted value";
 throw Error("PSC1_QUOT_OWNER_UNEXPECTED_REJECTION "+label+": "+detail);
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
const Kind=get("PsKernelQuotKind"),RefKind=get("PsKernelExprV2DeclarationRefKind");
const name=text=>N.str(unit(N.anonymous),text),one=L.succ(unit(L.zero));
const safe=unit(S.safe),hints=unit(get("PsKernelReducibilityHints").abbrevHint);
const nameEq=(a,b)=>get("psKernelNameEq")(a)(b);
const exprEq=(a,b)=>get("psKernelExprEq")(a)(b);
const exact=(a,b)=>get("psKernelExprEqual")(a)(b);
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
const md=(tag,x)=>build("MData",E.mdata(tag,x.term),tag,x.id);
const letE=(n,t,v,b)=>build("Let",E.letE(name(n),t.term,v.term,b.term,false),name(n),t.id,v.id,b.id,false);
const decoded=(owned,id)=>accepted(get("psKernelExprV2DecodedRequire")(
 accepted(get("psKernelExprV2DecodeChecked")(owned),"decode"),id),"decoded-root");
// Fixture construction only: these expressions are still checked by the
// actual declaration/command entry points. No owner is installed by this copy.
const appendExpr=term=>{
 const built=accepted(get("psKernelExprV2DecodeChecked")(arena),"fixture-input-decode");
 const result=accepted(get("psKernelDagGeneratedImport")(term,{arena,built,declarations:nil}),"fixture-copy");
 arena=result.fst.arena;
 must(exact(decoded(arena,result.snd),term),"fixture-copy-is-exact");
 return {term,id:result.snd};
};
const natName=get("psKernelNatName"),eqName=get("psKernelEqName"),reflName=N.str(eqName,"refl");
const quotName=get("psKernelQuotName"),mkName=get("psKernelQuotMkName");
const liftName=get("psKernelQuotLiftName"),indName=get("psKernelQuotIndName");
const nat=cn(natName),s1=sort(one),u=name("u");
const eqType=appendExpr(get("psKernelExpectedEqType")(u));
const eqReflType=appendExpr(get("psKernelExpectedEqReflType")(u));
const empty=accepted(get("psKernelKernelSessionEmpty")(
 get("psKernelResourcePolicyDefault"),get("psKernelProviderDefault")),"empty");
let session=empty;
const commands=[],requests=[],stages=[];
const ordinary=(label,n,levels,type,ctors,numParams)=>{
 const scalar={levelParams:list(levels),name:n,type:type.term,
  ctors:list(ctors.map(([name,type])=>({name,type:type.term}))),isUnsafe:false,numParams};
 const request=D.ordinaryInductive(list(levels),numParams,
  {name:n,type:type.id,ctors:list(ctors.map(([name,type])=>({name,type:type.id})))},false);
 session=accepted(get("psKernelV1AdmitDeclaration")(session,Request.ordinaryInductive(scalar)),label).session;
 commands.push(C.admit(request));requests.push(request);stages.push(session);
};
ordinary("checked-Nat",natName,[],s1,[[get("psKernelNatZeroName"),nat],
 [get("psKernelNatSuccName"),all("n",nat,nat)]],0n);
const withNat=session;
ordinary("checked-Eq",eqName,[u],eqType,[[reflName,eqReflType]],2n);
const withEq=session;
session=accepted(get("psKernelV1AdmitDeclaration")(session,unit(Request.quot)),"checked-Quot").session;
commands.push(C.admit(unit(D.quot)));requests.push(unit(D.quot));stages.push(session);
const relation=app(cn(eqName,[one]),nat);
const equality=(left,right)=>apps(relation,[left,right]);
const quotient=apps(cn(quotName,[one]),[nat,relation]);
const refl=(type,value)=>apps(cn(reflName,[one]),[type,value]);
const major=value=>apps(cn(mkName,[one]),[nat,relation,value]);
const identity=lam("x",nat,bv(0n));
const respectIdentity=lam("a",nat,lam("b",nat,
 lam("h",apps(relation,[bv(1n),bv(0n)]),bv(0n))));
const respectConstant=(type,value)=>lam("a",nat,lam("b",nat,
 lam("h",apps(relation,[bv(1n),bv(0n)]),refl(type,value))));
const lift=(type,fn,respect,value)=>apps(cn(liftName,[one,one]),[nat,relation,type,fn,respect,value]);
const liftIdentity=value=>lift(nat,identity,respectIdentity,value);
const induction=(motive,minor,value)=>apps(cn(indName,[one]),[nat,relation,motive,minor,value]);
const seven=lit(7n),major7=major(seven),result7=refl(nat,seven);
const motive=lam("q",quotient,equality(seven,seven)),minor=lam("a",nat,result7);
const nestedMajor=lift(quotient,lam("a",nat,major7),respectConstant(quotient,major7),major7);
const fnType=all("x",nat,nat),liftFn=lift(fnType,lam("a",nat,identity),respectConstant(fnType,identity),major7);
const motiveFn=lam("q",quotient,all("x",nat,equality(seven,seven)));
const minorFn=lam("a",nat,lam("x",nat,result7));
const partialLift=apps(cn(liftName,[one,one]),[nat,relation,nat,identity]);
const partialInd=apps(cn(indName,[one]),[nat,relation,motive]);
const fixtures=[
 ["lift",liftIdentity(major7),seven],
 ["ind",induction(motive,minor,major7),result7],
 ["major-beta",liftIdentity(app(lam("q",quotient,bv(0n)),major7)),seven],
 ["major-zeta",liftIdentity(letE("q",quotient,major7,bv(0n))),seven],
 ["major-metadata",liftIdentity(md(31n,major7)),seven],
 ["major-nested-quot",liftIdentity(nestedMajor),seven],
 ["ind-trailing",app(induction(motiveFn,minorFn,major7),lit(9n)),result7],
 ["lift-trailing",app(liftFn,lit(9n)),lit(9n)],
 ["unsaturated-lift",partialLift,partialLift],
 ["unsaturated-ind",partialInd,partialInd]
].map(([label,term,expected])=>{
 const checked=accepted(get("psKernelV1CheckExpression")(session,nil,safe,term.term),label+"-V1-check");
 return {label,term,expected,type:appendExpr(checked.type)};
});
const invalidTerms=[
 liftIdentity(apps(cn(mkName,[one]),[nat,relation])),
 liftIdentity(apps(cn(mkName,[one]),[nat,relation,seven,lit(8n)])),
 liftIdentity(seven),lift(nat,s1,respectIdentity,major7),
 apps(cn(liftName),[nat,relation,nat,identity,respectIdentity,major7])
];
const missing=cn(name("QuotOwnerMissingDependency"));
const input=arena,built=accepted(get("psKernelExprV2DecodeChecked")(input),"complete-source-decode");
const installedOwner=limit=>{
 let generated={arena:input,built,declarations:nil};
 for(let i=0;i<limit;i++){
  generated={...generated,declarations:get("psKernelDagDeclarationsAfterAdmission")(requests[i],generated.declarations)};
  generated=accepted(get("psKernelDagGeneratedAfterCommand")(
   commands[i],stages[i].environment,generated),"install-real-admitted-Quot-owner");
 }
 return generated;
};
const before=installedOwner(2),generated=installedOwner(3);
const state=(owned=generated)=>get("psKernelExprV2CheckStateWithWhnf")(
 get("psKernelExprV2CheckStateEmpty")(owned.arena),
 get("psKernelExprV2WhnfStateForDeclarations")(owned.arena,owned.declarations));
const base=get("psKernelKernelSessionChecker")(session,nil,safe);
const checkContext=c=>get("psKernelExprV2CheckContextEmpty")(c);
const check=(fuel,c,s,root)=>get("psKernelExprV2TryCheckStateWithFuel")(fuel,c,s,root);
const whnf=(fuel,c,s,root)=>get("psKernelExprV2TryWhnfCheckStateWithFuel")(fuel,c,s,root);
const defeq=(fuel,c,s,left,right)=>get("psKernelExprV2TryDefEqStateWithFuel")(fuel)(c)(s)(left)(right);

const quotientInfos=()=>{
 const infos=[];
 for(const [n,kind] of [[quotName,unit(Kind.typeQ)],[mkName,unit(Kind.ctorQ)],
  [liftName,unit(Kind.liftQ)],[indName,unit(Kind.indQ)]]){
  const info=accepted(get("psKernelEnvironmentFind")(session.environment,n),"live-Quot-info");
  must(same(info,CI.quotInfo(info.value)),"live-quotient-kind");
  must(nameEq(info.value.base.name,n)&&get("psKernelExprV2QuotKindEq")(info.value.kind,kind),
   "live-quot-name-and-kind");
  infos.push(info.value);
 }
 return infos;
};
const exactOwners=owned=>{
 for(const value of quotientInfos()){
  const owner=accepted(get("psKernelExprV2DeclarationRefFind")(owned.declarations)(value.base.name),"Quot-owner");
  must(get("psKernelExprV2DeclarationRefMatches")(owner,CI.quotInfo(value))&&same(owner.deltaValue,none),
   "owned-kind-levels-and-no-delta");
  must(exact(accepted(get("psKernelExprV2DecodedRequire")(owned.built,owner.type),"owned-type"),value.base.type),
   "exact-admitted-Quot-type");
  must(exact(decoded(owned.arena,owner.type),value.base.type),"exact-arena-and-decoded-Quot-type");
  must(get("psKernelDagGeneratedQuotOwnerMatches")(value,owned),"idempotence-guard-uses-exact-live-info");
 }
};
const unchanged=(label,before,after)=>must(same(before,after),label+"-no-append-or-owner-change");
must(array(generated.declarations).length===array(before.declarations).length+4&&
 generated.arena.size>before.arena.size&&generated.built.size===generated.arena.size,"all-four-owners-published");
accepted(get("psKernelExprV2PagedValidate")(generated.arena),"validate-Quot-owner-arena");
exactOwners(generated);
for(let root=0n;root<input.size;root++){
 must(exact(accepted(get("psKernelExprV2DecodedRequire")(built,root),"source-node"),
  accepted(get("psKernelExprV2DecodedRequire")(generated.built,root),"retained-node")),"immutable-source-prefix");
}
for(const value of quotientInfos()){
 const owner=accepted(get("psKernelExprV2DeclarationRefFind")(generated.declarations)(value.base.name),"private-owner");
 must(owner.type>=before.arena.size,"all-Quot-types-are-private-appended-IDs");
}
const repeated=accepted(get("psKernelV1AdmitDeclaration")(session,unit(Request.quot)),"idempotent-checked-Quot");
unchanged("repeated-Quot",generated,accepted(get("psKernelDagGeneratedAfterCommand")(
 C.admit(unit(D.quot)),repeated.session.environment,generated),"idempotent-Quot-owner"));
for(const fixture of fixtures){
 must(same(check(4096n,checkContext(base.context),state(before),fixture.term.id),none),
  fixture.label+"-owner-was-previously-missing");
}
const owners=array(generated.declarations),selected=accepted(
 get("psKernelExprV2DeclarationRefFind")(generated.declarations)(quotName),"repair-target");
const isQuot=owner=>nameEq(owner.name,quotName);
const repairs=[
 ["missing",owners.filter(owner=>!isQuot(owner))],
 ["wrong-kind",owners.map(owner=>isQuot(owner)?{...owner,kind:unit(RefKind.axiomDecl)}:owner)],
 ["wrong-type",owners.map(owner=>isQuot(owner)?{...owner,type:nat.id}:owner)],
 ["delta-body",owners.map(owner=>isQuot(owner)?{...owner,deltaValue:Option.some(nat.id)}:owner)],
 ["dangling-type",owners.map(owner=>isQuot(owner)?{...owner,type:generated.built.size}:owner)]
];
for(const [label,damagedOwners] of repairs){
 const damaged={...generated,declarations:list(damagedOwners)};
 const repaired=accepted(get("psKernelDagGeneratedAfterCommand")(
  C.admit(unit(D.quot)),session.environment,damaged),label+"-repair");
 must(repaired.arena.size>damaged.arena.size&&array(repaired.declarations).length===damagedOwners.length+4,
  label+"-cannot-elide-import");
 exactOwners(repaired);
 unchanged(label+"-repaired-idempotence",repaired,accepted(get("psKernelDagGeneratedAfterCommand")(
  C.admit(unit(D.quot)),session.environment,repaired),label+"-retained"));
}
must(selected.type<generated.built.size&&repairs.length===5,"repair-controls-retain-original-owner");
const environment=session.environment;
const plan=accepted(get("psKernelDagGeneratedPlanQuot")(environment),"complete-Quot-plan");
must(array(plan).length===4,"plan-has-all-four-before-import");
const environments=[
 ["uninitialized",{...environment,quotInitialized:false}],
 ["initialized-without-metadata",get("psKernelEnvironmentMarkQuotInitialized")(get("psKernelEnvironmentEmpty"))]
];
for(const value of quotientInfos()){
 const constants=array(environment.constants).filter(info=>
  !nameEq(get("psKernelConstantInfoName")(info),value.base.name));
 const missingEnvironment=constants.reduce((env,info)=>get("psKernelEnvironmentAddUnchecked")(env,info),
  get("psKernelEnvironmentEmpty"));
 environments.push(["missing-one",get("psKernelEnvironmentMarkQuotInitialized")(missingEnvironment)]);
 const wrongKind=get("psKernelExprV2QuotKindEq")(value.kind,unit(Kind.typeQ))?unit(Kind.ctorQ):unit(Kind.typeQ);
 environments.push(["wrong-kind",get("psKernelEnvironmentReplaceUnchecked")(
  environment,CI.quotInfo({...value,kind:wrongKind}))]);
}
for(const [label,env] of environments){
 must(same(get("psKernelDagGeneratedPlanQuot")(env),none),label+"-complete-plan-refuses");
 unchanged(label+"-atomic-no-publication",before,accepted(get("psKernelDagGeneratedAfterCommand")(
  C.admit(unit(D.quot)),env,before),label+"-uninstalled"));
}
must(environments.length===10,"ten-plan-refusal-controls");

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
let checks=0,reductions=0,equalities=0,invalidChecks=0;
for(const {label,term,expected,type} of fixtures){
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
 const checked=accepted(accepted(check(4096n,c,state(),term.id),label+"-complete-check-Some"),label+"-complete-check");
 must(exact(decoded(checked.fst.whnf.arena,checked.snd),type.term),label+"-owned-inferred-type");
 const reduced=accepted(accepted(whnf(4096n,c,state(),term.id),label+"-complete-WHNF-Some"),label+"-complete-WHNF");
 must(exprEq(decoded(reduced.fst.whnf.arena,reduced.snd),expected.term),label+"-owned-WHNF-value");
 const equal=accepted(accepted(defeq(4096n,c,state(),term.id,expected.id),label+"-complete-DefEq-Some"),label+"-complete-DefEq");
 must(equal.snd===true,label+"-owned-DefEq-success");
}
for(const term of invalidTerms){
 for(const fuel of [0n,1n,2n,4n,16n,64n])for(const [maxRecDepth,recDepth] of [[0n,0n],[1n,15n],[1n,16n]]){
  const context={...base.context,maxRecDepth,recDepth};
  compareExpr("invalid-checked-Quot",get("psKernelSessionCheck")(fuel,{...base,context},term.term),
   check(fuel,checkContext(context),state(),term.id));invalidChecks++;
 }
 must(rejected(accepted(check(4096n,checkContext(base.context),state(),term.id),"invalid-check-Some")),
  "invalid-never-becomes-success");
}
must(checks===180&&reductions===180&&equalities===180&&invalidChecks===90,"complete-resource-matrices");

const run=(extra,prefix=commands)=>get("psKernelV1RunDag")(empty,nil,safe,input,list([...prefix,...extra]));
const invalid=x=>rejected(x)&&x.error&&typeof x.error.message==="string"&&
 same(x.error,ErrorTag.rejectedInvalid(x.error.message));
const sameRejection=(label,original,actual)=>{
 must(invalid(original)&&invalid(actual),label+"-classified-invalid");
 must(same(original.error,actual.error),label+"-exact-rejection");
};
const definition=(label,type,value)=>({base:{name:name(label),levelParams:nil,type},value,hints,safety:safe});
const directAdmission=(label,source,value,valid)=>{
 const resources=session.resources;
 const environment=get("psKernelKernelSessionEnvironment")(session);
 const original=get("psKernelAddDefinition")(resources.fuel,environment,value,
  resources.maxRecDepth,resources.maxNatSize);
 const owned=accepted(get("psKernelDagTryAdmitSimpleWithFuel")(
  resources.fuel,environment,resources.maxRecDepth,resources.maxNatSize,
  generated.arena,generated.declarations,source,Request.definitionDecl(value)),label+"-mandatory-direct-admission");
 if(rejected(original)){
  must(!valid&&rejected(owned)&&original.error===owned.error,label+"-exact-admission-error");
  return;
 }
 const left=accepted(original,label+"-original-admission"),right=accepted(owned,label+"-owned-admission");
 must(valid&&get("psKernelEnvironmentSize")(left)===get("psKernelEnvironmentSize")(right),label+"-real-admission");
 const info=accepted(get("psKernelEnvironmentFind")(right,value.base.name),label+"-admitted-info");
 must(same(info,CI.defnInfo(info.value))&&exact(info.value.base.type,value.base.type)&&
  exact(info.value.value,value.value)&&
  get("psKernelNameListsEq")(info.value.base.levelParams)(value.base.levelParams),
  label+"-actual-checked-definition");
};
const admittedCommands=[];
let admissions=0,independentPositive=0,independentNegative=0;
for(const fixture of fixtures){
 const label="QuotOwnerValid-"+fixture.label;
 const source=D.definitionDecl(definition(label,fixture.type.id,fixture.term.id));
 const value=definition(label,fixture.type.term,fixture.term.term);
 directAdmission(label,source,value,true);
 accepted(get("psKernelV1AdmitDeclaration")(session,Request.definitionDecl(value)),label+"-independent-real-definition");
 admittedCommands.push(C.admit(source));admissions++;independentPositive++;
}
const complete=accepted(run(admittedCommands),"all-ten-real-Quot-definitions");
must(array(complete.replies).length===13,"complete-batch-has-all-admission-replies");
for(const fixture of fixtures){
 const info=accepted(get("psKernelEnvironmentFind")(complete.session.environment,name("QuotOwnerValid-"+fixture.label)),
  "completed-definition");
 must(same(info,CI.defnInfo(info.value)),"completed-batch-publishes-real-definition");
}
const negatives=invalidTerms.map((value,index)=>["QuotOwnerInvalid"+index,nat,value]);
negatives.push(["QuotOwnerWrongType",s1,fixtures[0].term],["QuotOwnerMissingValue",nat,missing]);
for(const [label,type,value] of negatives){
 const info=definition(label,type.term,value.term),source=D.definitionDecl(definition(label,type.id,value.id));
 directAdmission(label,source,info,false);
 sameRejection(label,get("psKernelV1AdmitDeclaration")(session,Request.definitionDecl(info)),
  run([C.admit(source)]));
 must(same(get("psKernelEnvironmentFind")(session.environment,name(label)),none),label+"-no-publication");
 admissions++;independentNegative++;
}
must(admissions===17&&independentPositive===10&&independentNegative===7,"seventeen-actual-direct-admissions");
must(same(get("psKernelDagTryAdmitSimpleWithFuel")(
 session.resources.fuel,withEq.environment,session.resources.maxRecDepth,session.resources.maxNatSize,
 generated.arena,generated.declarations,unit(D.quot),unit(Request.quot)),none),
 "Quot-admission-itself-remains-validated-V1");

const queries=fixtures.flatMap(({term,expected})=>[C.check(term.id),C.whnf(term.id),C.isDefEq(term.id,expected.id)]);
const result=accepted(run(queries),"complete-Quot-owner-batch");
const replies=array(result.replies).slice(commands.length);
must(replies.length===30&&queries.length===30,"exact-public-thirty-reply-protocol");
fixtures.forEach(({label,term,expected,type},i)=>{
 const checked=replies[i*3],reduced=replies[i*3+1],equal=replies[i*3+2];
 must(same(checked,Reply.checked(checked.value))&&exact(checked.value.type,type.term)&&
  exact(checked.value.expression,term.term),label+"-public-check");
 must(same(reduced,Reply.normalized(reduced.value))&&exprEq(reduced.value,expected.term),label+"-public-WHNF");
 must(same(equal,Reply.equal(true)),label+"-public-DefEq");
});
for(const term of invalidTerms){
 sameRejection("invalid-Quot-public-WHNF",get("psKernelV1Whnf")(session,nil,safe,term.term),
  run([C.whnf(term.id)]));
}
const publicRepeated=accepted(run([C.admit(unit(D.quot)),C.admit(unit(D.quot))]),"public-repeated-Quot");
must(get("psKernelEnvironmentSize")(publicRepeated.session.environment)===get("psKernelEnvironmentSize")(session.environment),
 "public-repeat-preserves-environment-size");

const quotientOwner=accepted(get("psKernelExprV2DeclarationRefFind")(generated.declarations)(quotName),"private-Quot-owner");
const privateId=quotientOwner.type;
must(input.size<=privateId&&privateId<generated.built.size,"private-target-is-real-new-Quot-type");
const privateHeader={name:name("QuotPrivateHeader"),levelParams:nil,type:privateId};
const publicHeader={name:name("QuotPrivateBody"),levelParams:nil,type:nat.id};
const privateDefinition={base:publicHeader,value:privateId,hints,safety:safe};
const badHeader={name:name("QuotPrivateFamily"),type:privateId,ctors:nil};
const badCtor={name:name("QuotPrivateFamily"),type:s1.id,ctors:list([{name:name("QuotPrivateCtor"),type:privateId}])};
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
 must(invalidReference(run([command])),"public-private-Quot-ID-remains-invalid");
 must(invalidReference(get("psKernelDagRunCommandWithSource")(built,
  {session,declarations:generated.declarations},nil,safe,generated.arena,generated.built,command)),
  "worker-retains-original-input-namespace");
}
must(privateCommands.length===13,"all-thirteen-private-Quot-input-forms");
const early=run([C.admit(D.unsupported("QUOT_OWNER_ORDER")),C.check(privateId)]);
must(rejected(early)&&same(early.error,ErrorTag.declinedUnsupported("QUOT_OWNER_ORDER")),
 "earlier-error-precedes-private-ID");
must(invalidReference(run([C.check(privateId),C.admit(D.unsupported("QUOT_OWNER_ORDER"))])),
 "private-ID-precedes-later-error");
must(same(get("psKernelEnvironmentFind")(empty.environment,quotName),none)&&
 !empty.environment.quotInitialized&&!withEq.environment.quotInitialized,"failed-batch-has-no-published-session");
accepted(run([]),"fresh-batch-after-failure");

sameRejection("Quot-without-Eq",get("psKernelV1AdmitDeclaration")(empty,unit(Request.quot)),
 get("psKernelV1RunDag")(empty,nil,safe,input,list([C.admit(unit(D.quot))])));
const wrongEq={levelParams:nil,name:eqName,type:s1.term,
 ctors:list([{name:N.str(eqName,"bad"),type:E.const(eqName,nil)}]),isUnsafe:false,numParams:0n};
const wrong=accepted(get("psKernelV1AdmitDeclaration")(empty,Request.ordinaryInductive(wrongEq)),"checked-non-equality-Eq");
arena=get("psKernelExprV2PagedEmpty");
const wrongSort=sort(one),wrongEqType=cn(eqName);
const wrongRequest=D.ordinaryInductive(nil,0n,
 {name:eqName,type:wrongSort.id,ctors:list([{name:N.str(eqName,"bad"),type:wrongEqType.id}])},false);
const wrongInput=arena;
arena=input;
sameRejection("Quot-requires-correct-Eq-shape",get("psKernelV1AdmitDeclaration")(wrong.session,unit(Request.quot)),
 get("psKernelV1RunDag")(empty,nil,safe,wrongInput,list([C.admit(wrongRequest),C.admit(unit(D.quot))])));
const occupied={base:{name:quotName,levelParams:nil,type:s1.term},isUnsafe:false};
const reserved=accepted(get("psKernelV1AdmitDeclaration")(withEq,Request.axiomDecl(occupied)),"checked-reserved-Quot-name");
const reservedRequest=D.axiomDecl({name:quotName,levelParams:nil,type:s1.id},false);
sameRejection("Quot-requires-free-reserved-names",get("psKernelV1AdmitDeclaration")(reserved.session,unit(Request.quot)),
 run([C.admit(reservedRequest),C.admit(unit(D.quot))],commands.slice(0,2)));
must(!wrong.session.environment.quotInitialized&&!reserved.session.environment.quotInitialized&&
 same(get("psKernelEnvironmentFind")(withEq.environment,quotName),none),"failed-Quot-never-marks-original-environment");
must(fixtures.length===10&&invalidTerms.length===5,"ten-valid-and-five-invalid-Quot-cases");
console.log("PSC1_V2_QUOT_OWNER_JS_PASS owners=4 cases=10 checks=180 whnf=180 defeq=180 invalidChecks=90 admissions=17 plans=10 repairs=5 private=13 independentPositive=10 independentNegative=7 assertions="+assertions);
