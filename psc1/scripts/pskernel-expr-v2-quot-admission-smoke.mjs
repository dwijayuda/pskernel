import {pathToFileURL} from "node:url";
import path from "node:path";

// Positive environments are built by real checked admission. Damaged metadata
// is confined to rejection/ordering controls and never authorizes a proof.
const filename=process.argv[2];
if(!filename)throw Error("PSC1_QUOT_ADMISSION_REQUIRES_KERNEL");
const k=await import(pathToFileURL(path.resolve(filename)).href);
const get=name=>{if(!(name in k))throw Error("PSC1_QUOT_ADMISSION_MISSING_EXPORT "+name);return k[name];};
const unit=x=>typeof x==="function"?x():x;
let assertions=0;
const must=(condition,label)=>{if(condition!==true)throw Error("PSC1_QUOT_ADMISSION_FAIL "+label);assertions++;};
const accepted=(value,label)=>{
 if(value&&typeof value==="object"&&Object.hasOwn(value,"value"))return value.value;
 const error=value&&Object.hasOwn(value,"error")?value.error:null;
 throw Error("PSC1_QUOT_ADMISSION_UNEXPECTED_REJECTION "+label+": "+
  (typeof error==="string"?error:error?.message??"missing accepted payload"));
};
const rejected=value=>Boolean(value&&typeof value==="object"&&Object.hasOwn(value,"error"));
const same=(left,right)=>{
 if(left===right)return true;
 if(left===null||right===null||typeof left!=="object"||typeof right!=="object")return false;
 const keys=Reflect.ownKeys(left),others=Reflect.ownKeys(right);
 return keys.length===others.length&&keys.every(key=>Object.hasOwn(right,key)&&same(left[key],right[key]));
};
const List=get("List"),nil=unit(List.nil),Option=get("Option"),none=unit(Option.none);
const list=items=>items.reduceRight((tail,head)=>List.cons(head,tail),nil);
const array=value=>{const result=[];while(value&&Object.hasOwn(value,"head")){result.push(value.head);value=value.tail;}return result;};
const N=get("PsKernelName"),E=get("PsKernelExpr"),L=get("PsKernelLevel"),B=get("PsKernelBinderInfo");
const CI=get("PsKernelConstantInfo"),D=get("PsKernelDagDeclarationRequest"),R=get("PsKernelDeclarationRequest");
const C=get("PsKernelDagCommand"),Reply=get("PsKernelDagReply"),Errors=get("PsKernelError");
const RK=get("PsKernelExprV2DeclarationRefKind"),Resource=get("PsKernelResourceError");
const name=text=>N.str(unit(N.anonymous),text),one=L.succ(unit(L.zero));
const safe=unit(get("PsKernelDefinitionSafety").safe),hints=unit(get("PsKernelReducibilityHints").abbrevHint);
const nameEq=(a,b)=>get("psKernelNameEq")(a)(b),exact=(a,b)=>get("psKernelExprEqual")(a)(b);
const exprEq=(a,b)=>get("psKernelExprEq")(a)(b);
const bv=n=>E.bvar(n),cn=(n,levels=[])=>E.const(n,list(levels)),sort=l=>E.sort(l);
const app=(fn,arg)=>E.app(fn,arg),apps=(fn,args)=>args.reduce(app,fn);
const pi=(n,type,body,bi=unit(B.default))=>E.forallE(name(n),type,body,bi);
const lam=(n,type,body)=>E.lam(name(n),type,body,unit(B.default));
const lit=n=>E.lit(get("PsKernelLiteral").nat(n));
const natName=get("psKernelNatName"),eqName=get("psKernelEqName"),reflName=N.str(eqName,"refl");
const quotName=get("psKernelQuotName"),mkName=get("psKernelQuotMkName");
const liftName=get("psKernelQuotLiftName"),indName=get("psKernelQuotIndName");
const nat=cn(natName),s1=sort(one),u=name("u");
const relation=app(cn(eqName,[one]),nat),eq7=apps(relation,[lit(7n),lit(7n)]);
const refl7=apps(cn(reflName,[one]),[nat,lit(7n)]),quotient=apps(cn(quotName,[one]),[nat,relation]);
const mk7=apps(cn(mkName,[one]),[nat,relation,lit(7n)]),identity=lam("x",nat,bv(0n));
const respect=lam("a",nat,lam("b",nat,lam("h",apps(relation,[bv(1n),bv(0n)]),bv(0n))));
const liftOf=major=>apps(cn(liftName,[one,one]),[nat,relation,nat,identity,respect,major]);
const ind7=apps(cn(indName,[one]),[nat,relation,lam("q",quotient,eq7),lam("a",nat,refl7),mk7]);
const natDecl={levelParams:nil,name:natName,type:s1,ctors:list([
 {name:get("psKernelNatZeroName"),type:nat},{name:get("psKernelNatSuccName"),type:pi("n",nat,nat)}]),isUnsafe:false,numParams:0n};
const eqDecl={levelParams:list([u]),name:eqName,type:get("psKernelExpectedEqType")(u),
 ctors:list([{name:reflName,type:get("psKernelExpectedEqReflType")(u)}]),isUnsafe:false,numParams:2n};
const empty=accepted(get("psKernelKernelSessionEmpty")(get("psKernelResourcePolicyDefault"),
 get("psKernelProviderDefault")),"empty");
const withNat=accepted(get("psKernelV1AdmitDeclaration")(empty,R.ordinaryInductive(natDecl)),"checked-Nat").session;
const withEq=accepted(get("psKernelV1AdmitDeclaration")(withNat,R.ordinaryInductive(eqDecl)),"checked-Eq").session;
const withQuot=accepted(get("psKernelV1AdmitDeclaration")(withEq,unit(R.quot)),"independent-Quot").session;
let arena=get("psKernelExprV2PagedEmpty");
const copy=term=>{
 const built=accepted(get("psKernelExprV2DecodeChecked")(arena),"copy-input");
 const result=accepted(get("psKernelDagGeneratedImport")(term,{arena,built,declarations:nil}),"fixture-copy");
 arena=result.fst.arena;return result.snd;
};
const request=decl=>D.ordinaryInductive(decl.levelParams,decl.numParams,
 {name:decl.name,type:copy(decl.type),ctors:list(array(decl.ctors).map(c=>({name:c.name,type:copy(c.type)})))},decl.isUnsafe);
const natRequest=request(natDecl),eqRequest=request(eqDecl),prefix=[C.admit(natRequest),C.admit(eqRequest)];
const fixtures=[
 ["mk",mk7,mk7],["lift",liftOf(mk7),lit(7n)],["ind",ind7,refl7],
 ["beta-major",liftOf(app(lam("q",quotient,bv(0n)),mk7)),lit(7n)]
].map(([label,term,expected])=>({label,term,expected,
 type:accepted(get("psKernelV1CheckExpression")(withQuot,nil,safe,term),label+"-type").type,
 root:copy(term),expectedRoot:copy(expected)}));
const natRoot=copy(nat),sortRoot=copy(s1),unknownTerm=cn(name("QuotAdmissionUnknown")),unknownRoot=copy(unknownTerm);
const source=arena,input=accepted(get("psKernelExprV2DecodeChecked")(source),"original-input");
let before={arena:source,built:input,declarations:nil};
before={...before,declarations:get("psKernelDagDeclarationsAfterAdmission")(natRequest,before.declarations)};
before=accepted(get("psKernelDagGeneratedAfterCommandWithPrevious")(
 C.admit(natRequest),empty.environment,withNat.environment,before),"checked-Nat-owners");
before={...before,declarations:get("psKernelDagDeclarationsAfterAdmission")(eqRequest,before.declarations)};
before=accepted(get("psKernelDagGeneratedAfterCommandWithPrevious")(
 C.admit(eqRequest),withNat.environment,withEq.environment,before),"checked-Eq-owners");
const decoded=(a,id)=>accepted(get("psKernelExprV2DecodedRequire")(
 accepted(get("psKernelExprV2DecodeChecked")(a),"decode"),id),"decode-root");
const exactEnvironment=(label,expected,actual)=>{
 must(get("psKernelEnvironmentSize")(expected)===get("psKernelEnvironmentSize")(actual)&&
  expected.quotInitialized===actual.quotInitialized,label+"-size-and-initialized");
 for(const n of [quotName,mkName,liftName,indName]){
  const a=accepted(get("psKernelEnvironmentFind")(expected,n),label+"-reference-info");
  const b=accepted(get("psKernelEnvironmentFind")(actual,n),label+"-actual-info");
  must(same(a,CI.quotInfo(a.value))&&same(b,CI.quotInfo(b.value)),label+"-quot-kind");
  must(nameEq(a.value.base.name,b.value.base.name)&&
   get("psKernelNameListsEq")(a.value.base.levelParams)(b.value.base.levelParams)&&
   get("psKernelExprV2QuotKindEq")(a.value.kind,b.value.kind)&&exact(a.value.base.type,b.value.base.type),
   label+"-exact-live-header");
 }
};
const compareAdmission=(label,reference,actual)=>{
 if(rejected(reference)){must(rejected(actual)&&same(reference.error,actual.error),label+"-exact-typed-error");return;}
 const a=accepted(reference,label+"-V1"),b=accepted(actual,label+"-owned").fst;
 exactEnvironment(label,a.session.environment,b.session.environment);
 must(same(a.declaration.receipt,b.declaration.receipt),label+"-exact-receipt");
};


let headerCases=0;
for(const size of [0n,3n,63n,64n,127n,129n]){
 let initial=get("psKernelExprV2PagedEmpty");
 for(let i=0n;i<size;i++)initial=accepted(get("psKernelExprV2PagedMkSort")(initial,one),"prefix-sort").fst;
 for(const [a,b] of [[name("u"),name("v")],[name("α"),name("β")],
  [N.num(name("level"),17n),unit(N.anonymous)],[name("same"),name("same")]]){
  const built=accepted(get("psKernelDagQuotBuildHeaders")(initial,a,b),"direct-headers");
  must(built.arena.size===size+55n,"header-exact-55-append");
  must(built.quotType===size+14n&&built.mkType===size+19n&&built.liftType===size+38n&&built.indType===size+54n,
   "header-four-exact-roots");
  const canonical=accepted(get("psKernelExprV2PagedValidate")(built.arena),"header-replay");
  const table=accepted(get("psKernelExprV2DecodeChecked")(canonical),"header-decode");
  for(let root=0n;root<size;root++)must(exact(accepted(get("psKernelExprV2DecodedRequire")(table,root),"prefix"),s1),
   "header-preserves-prefix");
  for(const [root,expected] of [[built.quotType,get("psKernelMakeQuotType")(a)],
   [built.mkType,get("psKernelMakeQuotMkType")(a)],[built.liftType,get("psKernelMakeQuotLiftType")(a,b)],
   [built.indType,get("psKernelMakeQuotIndType")(a)]]){
   const value=accepted(get("psKernelExprV2DecodedRequire")(table,root),"header-root");
   must(exact(value,expected),"header-exact-reference-builder");
   must(!get("psKernelExprHasLooseBVar")(value)&&!get("psKernelExprHasFVar")(value),"header-closed-no-fvar");
  }
  headerCases++;
 }
}
must(headerCases===24,"all-header-prefix-universe-cases");
const level=L.param(u),eq=get("psKernelExpectedEqType")(u),refl=get("psKernelExpectedEqReflType")(u);
const rename=x=>E.forallE(name("renamed"),x.type,x.body,unit(B.instImplicit));
const eqShape=(domain,a,b,result)=>pi("x",domain,pi("a",a,pi("b",b,result)));
const eqCases=[eq,rename(eq),
 pi("x",sort(level),pi("y",bv(0n),pi("z",bv(1n),sort(unit(L.zero)),unit(B.implicit)),unit(B.strictImplicit))),
 E.mdata(7n,eq),E.letE(name("t"),s1,s1,eq,false),
 eqShape(s1,bv(0n),bv(1n),sort(unit(L.zero))),eqShape(sort(level),bv(1n),bv(1n),sort(unit(L.zero))),
 eqShape(sort(level),bv(0n),bv(0n),sort(unit(L.zero))),eqShape(sort(level),bv(0n),bv(1n),s1),
 eqShape(sort(L.max(level,unit(L.zero))),bv(0n),bv(1n),sort(unit(L.zero))),bv(0n),sort(unit(L.zero))];
const reflShape=(head,args)=>pi("x",sort(level),pi("a",bv(0n),apps(head,args)),unit(B.implicit));
const reflCases=[refl,rename(refl),reflShape(cn(eqName,[level]),[bv(1n),bv(0n),bv(0n)]),
 E.mdata(9n,refl),E.letE(name("t"),s1,s1,refl,false),reflShape(cn(eqName),[bv(1n),bv(0n),bv(0n)]),
 reflShape(cn(name("NotEq"),[level]),[bv(1n),bv(0n),bv(0n)]),
 reflShape(cn(eqName,[level]),[bv(0n),bv(0n),bv(0n)]),reflShape(cn(eqName,[level]),[bv(1n),bv(1n),bv(0n)]),
 reflShape(cn(eqName,[level]),[bv(1n),bv(0n),bv(1n)]),reflShape(cn(eqName,[level]),[bv(1n),bv(0n)]),
 reflShape(cn(eqName,[level]),[bv(1n),bv(0n),bv(0n),bv(0n)])];
for(const [expected,cases,check] of [[eq,eqCases,get("psKernelDagQuotCheckEqType")],
 [refl,reflCases,get("psKernelDagQuotCheckReflType")]]){
 for(const term of cases){
  const emptyState={arena:get("psKernelExprV2PagedEmpty"),built:get("psKernelExprV2DecodedEmpty"),declarations:nil};
  const copied=accepted(get("psKernelDagGeneratedImport")(term,emptyState),"raw-syntax-copy");
  must(accepted(check(copied.fst.arena,copied.snd,u),"mandatory-syntax-Some")===exprEq(term,expected),"syntax-exact-ExprEq");
 }
 must(same(check(get("psKernelExprV2PagedEmpty"),0n,u),none),"invalid-syntax-root-declines");
}
must(eqCases.length+reflCases.length===24,"all-syntax-cases");


const eqInfo=accepted(get("psKernelEnvironmentFind")(withEq.environment,eqName),"live-Eq");
const reflInfo=accepted(get("psKernelEnvironmentFind")(withEq.environment,reflName),"live-refl");
must(same(eqInfo,CI.inductInfo(eqInfo.value))&&same(reflInfo,CI.ctorInfo(reflInfo.value)),"checked-prerequisite-kinds");
const eqValue=eqInfo.value,reflValue=reflInfo.value;
const eqBase=base=>CI.inductInfo({...eqValue,base:{...eqValue.base,...base}});
const reflBase=base=>CI.ctorInfo({...reflValue,base:{...reflValue.base,...base}});
const malformed=[
 ["missing-Eq",[]],["wrong-Eq-kind",[CI.axiomInfo({base:eqValue.base,isUnsafe:false}),reflInfo]],
 ["Eq-no-universe",[eqBase({levelParams:nil}),reflInfo]],
 ["Eq-extra-universe",[eqBase({levelParams:list([name("u"),name("v")])}),reflInfo]],
 ["Eq-no-ctor",[CI.inductInfo({...eqValue,ctors:nil}),reflInfo]],
 ["Eq-extra-ctor",[CI.inductInfo({...eqValue,ctors:list([reflName,name("extra")])}),reflInfo]],
 ["Eq-wrong-type",[eqBase({type:s1}),reflInfo]],
 ["Eq-type-before-missing-refl",[eqBase({type:s1})]],["missing-refl",[eqInfo]],
 ["refl-no-universe",[eqInfo,reflBase({levelParams:nil})]],
 ["refl-extra-universe",[eqInfo,reflBase({levelParams:list([name("u"),name("v")])})]],
 ["refl-wrong-type",[eqInfo,reflBase({type:s1})]]
];
const rows=[{label:"checked-positive",environment:withEq.environment,state:before}];
for(const [label,infos] of malformed){
 const environment=infos.reduce((env,info)=>get("psKernelEnvironmentAddUnchecked")(env,info),get("psKernelEnvironmentEmpty"));
 must(rejected(get("psKernelAddQuot")(environment)),label+"-reference-rejects");
 let state={arena:get("psKernelExprV2PagedEmpty"),built:get("psKernelExprV2DecodedEmpty"),declarations:nil};
 for(const info of infos){
  if(same(info,CI.inductInfo(info.value))||same(info,CI.ctorInfo(info.value)))
   state=accepted(get("psKernelDagGeneratedInstallNewInfo")(info,nil,state),label+"-negative-owned-type");
 }
 rows.push({label,environment,state});
}
for(const n of [quotName,mkName,liftName,indName]){
 const occupied={base:{name:n,levelParams:nil,type:s1},isUnsafe:false};
 const admitted=accepted(get("psKernelV1AdmitDeclaration")(withEq,R.axiomDecl(occupied)),"checked-reserved-name");
 rows.push({label:"reserved-name",environment:admitted.session.environment,state:before});
}
must(rows.length===17,"seventeen-guard-rows");
let admissions=0;
for(const row of rows){
 const reference=get("psKernelAddQuot")(row.environment);
 const actual=accepted(get("psKernelDagTryAddQuotOwned")(row.environment,row.state),row.label+"-mandatory-raw-Some");
 if(rejected(reference))must(rejected(actual)&&reference.error===actual.error,row.label+"-exact-raw-error-order");
 else{
  must(row.label==="checked-positive","only-checked-positive");
  exactEnvironment(row.label,accepted(reference,row.label+"-reference"),accepted(actual,row.label+"-raw").fst);
 }
 for(const fuel of [0n,1n,2n,8n,4096n])for(const maxRecDepth of [0n,1n,64n]){
  const session={environment:row.environment,resources:{...withEq.resources,fuel,maxRecDepth},provider:withEq.provider};
  compareAdmission(row.label+"-policy",get("psKernelV1AdmitDeclaration")(session,unit(R.quot)),
   get("psKernelDagAdmitDeclarationOwned")(session,row.state,unit(D.quot),unit(R.quot)));
  admissions++;
 }
}
must(admissions===255,"all-admission-resource-rows");
const size=get("psKernelEnvironmentSize")(withEq.environment);
for(const maxDeclarations of [size+3n,size+4n]){
 const session={...withEq,resources:{...withEq.resources,maxDeclarations}};
 compareAdmission("declaration-count-after-bootstrap",get("psKernelV1AdmitDeclaration")(session,unit(R.quot)),
  get("psKernelDagAdmitDeclarationOwned")(session,before,unit(D.quot),unit(R.quot)));
}
const cancelled={...withEq,resources:{...withEq.resources,cancelled:true,fuel:0n}};
compareAdmission("cancel-before-fuel-and-Quot",get("psKernelV1AdmitDeclaration")(cancelled,unit(R.quot)),
 get("psKernelDagAdmitDeclarationOwned")(cancelled,before,unit(D.quot),unit(R.quot)));
const wrongProvider={...cancelled,provider:{...cancelled.provider,target:{...cancelled.provider.target,leanVersion:"wrong"}}};
compareAdmission("provider-before-resource-and-Quot",get("psKernelV1AdmitDeclaration")(wrongProvider,unit(R.quot)),
 get("psKernelDagAdmitDeclarationOwned")(wrongProvider,before,unit(D.quot),unit(R.quot)));
must(!withEq.environment.quotInitialized&&same(get("psKernelEnvironmentFind")(withEq.environment,quotName),none),
 "original-session-not-initialized");

const sameOwner=(label,expected,actual)=>{
 must(expected.arena.size===actual.arena.size&&expected.built.size===actual.built.size&&
  array(expected.declarations).length===array(actual.declarations).length,label+"-sizes");
 const a=array(expected.declarations),b=array(actual.declarations);
 a.forEach((left,i)=>must(nameEq(left.name,b[i].name)&&left.type===b[i].type&&same(left.deltaValue,b[i].deltaValue),
  label+"-owner-IDs"));
 for(let root=0n;root<expected.built.size;root++)
  must(exact(accepted(get("psKernelExprV2DecodedRequire")(expected.built,root),label+"-old"),
   accepted(get("psKernelExprV2DecodedRequire")(actual.built,root),label+"-new")),label+"-exact-prefix");
};
const direct=accepted(accepted(get("psKernelDagTryAddQuotOwned")(
 get("psKernelKernelSessionEnvironment")(withEq),before),"real-direct-Quot-Some"),"real-direct-Quot");
const environment=direct.fst,owned=direct.snd;
exactEnvironment("direct-bootstrap",withQuot.environment,environment);
must(owned.arena.size===before.arena.size+55n&&owned.built.size===before.built.size+55n&&
 array(owned.declarations).length===array(before.declarations).length+4,"actual-55-nodes-four-owners");
for(const [n,offset] of [[quotName,14n],[mkName,19n],[liftName,38n],[indName,54n]]){
 const owner=accepted(get("psKernelExprV2DeclarationRefFind")(owned.declarations)(n),"direct-owner");
 const info=accepted(get("psKernelEnvironmentFind")(environment,n),"direct-live-info");
 must(owner.type===before.arena.size+offset&&same(owner.deltaValue,none)&&
  get("psKernelExprV2DeclarationRefMatches")(owner,info),"exact-private-root-kind");
 must(exact(accepted(get("psKernelExprV2DecodedRequire")(owned.built,owner.type),"owned-type"),
  get("psKernelConstantInfoType")(info)),"owned-type-is-published-type");
}
for(let root=0n;root<input.size;root++)
 must(exact(accepted(get("psKernelExprV2DecodedRequire")(input,root),"input-node"),
  accepted(get("psKernelExprV2DecodedRequire")(owned.built,root),"owned-node")),"original-input-ID-retained");
sameOwner("bridge-reuses-direct-headers",owned,accepted(get("psKernelDagGeneratedAfterCommandWithPrevious")(
 C.admit(unit(D.quot)),withEq.environment,environment,owned),"post-direct-bridge"));
for(const state of [owned,{...owned,declarations:nil}]){
 const result=accepted(accepted(get("psKernelDagTryAddQuotOwned")(environment,state),"initialized-Some"),"initialized");
 exactEnvironment("initialized",environment,result.fst);sameOwner("initialized-no-op",state,result.snd);
}
for(const n of [eqName,reflName]){
 const refs=array(before.declarations);
 const variants=[refs.filter(r=>!nameEq(r.name,n)),
  refs.map(r=>nameEq(r.name,n)?{...r,kind:unit(RK.axiomDecl)}:r),
  refs.map(r=>nameEq(r.name,n)?{...r,type:before.arena.size}:r)];
 for(const entries of variants){
  const damaged={...before,declarations:list(entries)};
  must(same(get("psKernelDagTryAddQuotOwned")(withEq.environment,damaged),none),"missing-kind-dangling-owner-declines");
  compareAdmission("explicit-fallback",get("psKernelV1AdmitDeclaration")(withEq,unit(R.quot)),
   get("psKernelDagAdmitDeclarationOwned")(withEq,damaged,unit(D.quot),unit(R.quot)));
 }
}
must(same(get("psKernelDagTryAddQuotOwned")(withEq.environment,{...before,built:get("psKernelExprV2DecodedEmpty")}),none),
 "incoherent-work-table-declines");
const oldAdmission=accepted(get("psKernelDagAdmitDeclaration")(withEq,before.arena,before.declarations,
 unit(D.quot),unit(R.quot)),"historical-no-carrier");
exactEnvironment("historical-fallback",withQuot.environment,oldAdmission.session.environment);


const state=()=>get("psKernelExprV2CheckStateWithWhnf")(get("psKernelExprV2CheckStateEmpty")(owned.arena),
 get("psKernelExprV2WhnfStateForDeclarations")(owned.arena,owned.declarations));
const base=get("psKernelKernelSessionChecker")(withQuot,nil,safe);
const context=c=>get("psKernelExprV2CheckContextEmpty")(c);
const check=(fuel,c,s,root)=>get("psKernelExprV2TryCheckStateWithFuel")(fuel,c,s,root);
const whnf=(fuel,c,s,root)=>get("psKernelExprV2TryWhnfCheckStateWithFuel")(fuel,c,s,root);
const defeq=(fuel,c,s,left,right)=>get("psKernelExprV2TryDefEqStateWithFuel")(fuel)(c)(s)(left)(right);
const compareExpr=(label,reference,attempt)=>{
 const actual=accepted(attempt,label+"-mandatory-Some");
 if(rejected(reference)){must(rejected(actual)&&reference.error===actual.error,label+"-exact-error");return;}
 const a=accepted(reference,label+"-V1"),b=accepted(actual,label+"-owned");
 must(exact(a.fst,decoded(b.fst.whnf.arena,b.snd)),label+"-exact-expression");
};
const compareBool=(label,reference,attempt)=>{
 const actual=accepted(attempt,label+"-mandatory-Some");
 if(rejected(reference)){must(rejected(actual)&&reference.error===actual.error,label+"-exact-error");return;}
 must(accepted(reference,label+"-V1").fst===accepted(actual,label+"-owned").snd,label+"-exact-bool");
};
let consumerRows=0;
for(const fixture of fixtures){
 for(const fuel of [0n,1n,2n,16n,4096n])for(const [maxRecDepth,recDepth] of [[0n,0n],[1n,15n],[1n,16n]]){
  const raw={...base.context,maxRecDepth,recDepth},scalar={...base,context:raw},c=context(raw);
  compareExpr(fixture.label+"-check",get("psKernelSessionCheck")(fuel,scalar,fixture.term),check(fuel,c,state(),fixture.root));
  compareExpr(fixture.label+"-WHNF",get("psKernelSessionWhnf")(fuel,scalar,fixture.term),whnf(fuel,c,state(),fixture.root));
  compareBool(fixture.label+"-DefEq",get("psKernelSessionIsDefEq")(fuel,scalar,fixture.term,fixture.expected),
   defeq(fuel,c,state(),fixture.root,fixture.expectedRoot));
  consumerRows++;
 }
 const c=context(base.context);
 const checked=accepted(accepted(check(4096n,c,state(),fixture.root),"complete-check-Some"),"complete-check");
 must(exact(decoded(checked.fst.whnf.arena,checked.snd),fixture.type),"complete-owned-inferred-type");
 const reduced=accepted(accepted(whnf(4096n,c,state(),fixture.root),"complete-WHNF-Some"),"complete-WHNF");
 must(exprEq(decoded(reduced.fst.whnf.arena,reduced.snd),fixture.expected),"complete-owned-normal-form");
 must(accepted(accepted(defeq(4096n,c,state(),fixture.root,fixture.expectedRoot),"complete-DefEq-Some"),
  "complete-DefEq").snd===true,"complete-owned-equality");
}
must(consumerRows===60,"sixty-each-raw-consumer-rows");
const sameFailure=(label,reference,actual)=>must(rejected(reference)&&rejected(actual)&&same(reference.error,actual.error),
 label+"-exact-typed-failure");
const prelude=[...prefix,C.admit(unit(D.quot))];
const run=extra=>get("psKernelV1RunDag")(empty,nil,safe,source,list([...prelude,...extra]));
const queries=fixtures.flatMap(f=>[C.check(f.root),C.whnf(f.root),C.isDefEq(f.root,f.expectedRoot)]);
const complete=accepted(run(queries),"complete-bootstrap-and-query-batch");
exactEnvironment("complete-public",withQuot.environment,complete.session.environment);
const answers=array(complete.replies).slice(prelude.length);
fixtures.forEach((fixture,i)=>{
 const [checked,reduced,equal]=answers.slice(3*i,3*i+3);
 must(same(checked,Reply.checked(checked.value))&&same(reduced,Reply.normalized(reduced.value))&&
  same(equal,Reply.equal(equal.value)),"exact-ordered-reply-shapes");
 must(exact(checked.value.expression,fixture.term)&&exact(checked.value.type,fixture.type)&&
  exprEq(reduced.value,fixture.expected)&&equal.value===true,fixture.label+"-complete-public-values");
});
must(queries.length===12&&answers.length===12,"exact-twelve-query-replies");
const execution={session:withEq,declarations:before.declarations};
const commandResult=accepted(get("psKernelDagRunCommandOwnedWithSource")(input,execution,nil,safe,before.arena,
 before.built,C.admit(unit(D.quot))),"raw-owned-command");
sameOwner("production-command-retains-owner",owned,accepted(commandResult.owner,"command-owner"));
const fixture=fixtures[1],goodName=name("QuotAdmissionValid");
const good={base:{name:goodName,levelParams:nil,type:nat},value:fixture.term,hints,safety:safe};
const goodSource=D.definitionDecl({base:{name:goodName,levelParams:nil,type:natRoot},value:fixture.root,hints,safety:safe});
const reference=accepted(get("psKernelV1AdmitDeclaration")(withQuot,R.definitionDecl(good)),"V1-real-definition");
const admitted=accepted(run([C.admit(goodSource)]),"public-real-definition");
must(get("psKernelEnvironmentSize")(admitted.session.environment)===get("psKernelEnvironmentSize")(reference.session.environment)&&
 !same(get("psKernelEnvironmentFind")(admitted.session.environment,goodName),none),"whole-batch-publishes-real-definition");
for(const [n,value,root] of [[name("QuotAdmissionWrongBody"),s1,sortRoot],
 [name("QuotAdmissionUnknownBody"),unknownTerm,unknownRoot]]){
 const info={base:{name:n,levelParams:nil,type:nat},value,hints,safety:safe};
 const request=D.definitionDecl({base:{name:n,levelParams:nil,type:natRoot},value:root,hints,safety:safe});
 sameFailure("invalid-definition",get("psKernelV1AdmitDeclaration")(withQuot,R.definitionDecl(info)),run([C.admit(request)]));
}
sameFailure("late-error",get("psKernelV1CheckExpression")(reference.session,nil,safe,unknownTerm),
 run([C.admit(goodSource),C.check(unknownRoot)]));
must(same(get("psKernelEnvironmentFind")(empty.environment,quotName),none)&&
 same(get("psKernelEnvironmentFind")(empty.environment,goodName),none)&&!empty.environment.quotInitialized,
 "source-session-has-no-partial-publication");
sameFailure("missing-Eq",get("psKernelV1AdmitDeclaration")(empty,unit(R.quot)),
 get("psKernelV1RunDag")(empty,nil,safe,source,list([C.admit(unit(D.quot))])));


const privateRoot=accepted(get("psKernelExprV2DeclarationRefFind")(owned.declarations)(quotName),"private-root").type;
must(privateRoot>=input.size&&privateRoot<owned.built.size,"private-root-outside-original-source");
const privateHeader={name:name("QuotAdmissionPrivate"),levelParams:nil,type:privateRoot};
const publicHeader={name:name("QuotAdmissionPrivateBody"),levelParams:nil,type:natRoot};
const privateDef={base:publicHeader,value:privateRoot,hints,safety:safe};
const family={name:name("QuotAdmissionPrivateFamily"),type:privateRoot,ctors:nil};
const ctor={name:family.name,type:sortRoot,ctors:list([{name:name("QuotAdmissionPrivateCtor"),type:privateRoot}])};
const privateCommands=[C.check(privateRoot),C.whnf(privateRoot),C.isDefEq(privateRoot,natRoot),C.isDefEq(natRoot,privateRoot),
 C.admit(D.axiomDecl(privateHeader,false)),C.admit(D.definitionDecl(privateDef)),
 C.admit(D.theoremDecl(publicHeader,privateRoot)),C.admit(D.opaqueDecl(publicHeader,privateRoot,false)),
 C.admit(D.mutualDefinitions(list([privateDef]))),C.admit(D.ordinaryInductive(nil,0n,family,false)),
 C.admit(D.ordinaryInductive(nil,0n,ctor,false)),
 C.admit(D.mutualInductive({levelParams:nil,numParams:0n,types:list([family]),isUnsafe:false})),
 C.admit(D.nestedInductive({levelParams:nil,numParams:0n,types:list([ctor]),isUnsafe:false}))];
const invalid=value=>rejected(value)&&same(value.error,Errors.rejectedInvalid("PSKERNEL_V2_DECODE_INVALID_REFERENCE"));
const afterExecution={session:withQuot,declarations:owned.declarations};
for(const command of privateCommands){
 must(invalid(get("psKernelDagRunCommandOwnedWithSource")(input,afterExecution,nil,safe,owned.arena,owned.built,command)),
  "owned-command-refuses-private-source-ID");
 must(invalid(get("psKernelDagRunCommandsOwnedWithSource")(list([command]))(input)(afterExecution)(nil)(safe)(owned.arena)(owned.built)),
  "owned-loop-keeps-original-input");
 must(invalid(run([command])),"public-loop-keeps-original-input");
}
must(privateCommands.length===13,"all-thirteen-private-input-forms");
const early=run([C.admit(D.unsupported("QUOT_ADMISSION_ORDER")),C.check(privateRoot)]);
must(rejected(early)&&same(early.error,Errors.declinedUnsupported("QUOT_ADMISSION_ORDER")),"earlier-error-precedence");
must(invalid(run([C.check(privateRoot),C.admit(D.unsupported("QUOT_ADMISSION_ORDER"))])),"private-ID-before-late-error");
const invalidArena={...source,size:source.size+1n};
const cancelledEmpty={...empty,resources:{...empty.resources,cancelled:true,fuel:0n}};
const zero={...empty,resources:{...empty.resources,fuel:0n}};
const incompatible={...cancelledEmpty,provider:{...cancelledEmpty.provider,
 target:{...cancelledEmpty.provider.target,leanVersion:"wrong"}}};
for(const [session,error] of [
 [cancelledEmpty,Errors.resourceExhausted(unit(Resource.cancelled),"resource policy declined operation before entry")],
 [zero,Errors.resourceExhausted(unit(Resource.fuel),"resource policy declined operation before entry")],
 [incompatible,Errors.declinedUnsupported("provider target does not match KernelContract-v1")]]){
 const result=get("psKernelV1RunDag")(session,nil,safe,invalidArena,list([C.admit(unit(D.quot))]));
 must(rejected(result)&&same(result.error,error),"preflight-before-graph-and-Quot");
}
console.log("PSC1_V2_QUOT_ADMISSION_JS_PASS headers=24 syntax=24 guards=17 admissions=255 policy=4 checks=60 whnf=60 defeq=60 private=13 independentPositive=4 independentNegative=4 assertions="+assertions);
