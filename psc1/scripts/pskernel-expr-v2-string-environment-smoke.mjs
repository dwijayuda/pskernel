import {readFileSync} from "node:fs";
import {pathToFileURL} from "node:url";
import path from "node:path";
import {performance} from "node:perf_hooks";
import {createHash} from "node:crypto";

const [filename,fixturePath]=process.argv.slice(2);
if(!filename||!fixturePath)throw Error("usage: t01f-string-smoke <generated-kernel.js> <authentic-fixture.json>");
const kernelSha256=createHash("sha256").update(readFileSync(filename)).digest("hex");
const k=await import(pathToFileURL(path.resolve(filename)).href);
const fixtureBytes=readFileSync(fixturePath);
const fixture=JSON.parse(fixtureBytes.toString("utf8"));
const fixtureSha256=createHash("sha256").update(fixtureBytes).digest("hex");
const get=name=>{if(!(name in k))throw Error("PSC1_T01F_MISSING_EXPORT "+name);return k[name];};
const unit=value=>typeof value==="function"?value():value;
let assertions=0;
const must=(ok,label)=>{if(ok!==true)throw Error("PSC1_T01F_FAIL "+label);assertions++;};
const accepted=(value,label)=>{
 if(value&&typeof value==="object"&&Object.hasOwn(value,"value"))return value.value;
 const error=value?.error;
 throw Error("PSC1_T01F_REJECTED "+label+": "+(typeof error==="string"?error:error?.message??"invalid Except"));
};
const attempt=(value,label)=>accepted(accepted(value,label+"-direct"),label);
const List=get("List"),nil=unit(List.nil);
const list=values=>values.reduceRight((tail,head)=>List.cons(head,tail),nil);
const array=value=>{
 const out=[];
 while(value&&typeof value==="object"&&Object.hasOwn(value,"head")){
  if(!same(value,List.cons(value.head,value.tail)))throw Error("invalid generated List.cons");
  out.push(value.head);value=value.tail;
 }
 if(!same(value,nil))throw Error("invalid generated List.nil");
 return out;
};
const N=get("PsKernelName"),L=get("PsKernelLevel"),E=get("PsKernelExpr");
const BI=get("PsKernelBinderInfo"),Lit=get("PsKernelLiteral"),S=get("PsKernelDefinitionSafety");
const H=get("PsKernelReducibilityHints"),R=get("PsKernelDeclarationRequest"),C=get("PsKernelDagCommand");
const safe=unit(S.safe),zero=unit(L.zero);
const same=(a,b)=>{
 if(a===b)return true;
 if(a===null||b===null||typeof a!=="object"||typeof b!=="object")return false;
 const ka=Reflect.ownKeys(a),kb=Reflect.ownKeys(b);
 return ka.length===kb.length&&ka.every(key=>Object.hasOwn(b,key)&&same(a[key],b[key]));
};
const rejected=result=>result&&typeof result==="object"&&Object.hasOwn(result,"error")&&
 typeof result.error?.message==="string"&&same(result.error,get("PsKernelError").rejectedInvalid(result.error.message));
const record=(raw,size,label)=>{
 if(!Array.isArray(raw)||raw.length!==size)throw Error("invalid authentic fixture "+label);
 return raw;
};
const natural=value=>{if(typeof value!=="string"||!/^(0|[1-9][0-9]*)$/u.test(value))throw Error("invalid natural");return BigInt(value);};
const text=value=>{if(typeof value!=="string")throw Error("invalid string");return value;};
const bool=value=>{if(typeof value!=="boolean")throw Error("invalid boolean");return value;};
const sequence=value=>{if(!Array.isArray(value))throw Error("invalid list");return value;};
function name(raw){
 sequence(raw);
 switch(raw[0]){
  case "anonymous":record(raw,1,"name");return unit(N.anonymous);
  case "str":record(raw,3,"name");return N.str(name(raw[1]),text(raw[2]));
  case "num":record(raw,3,"name");return N.num(name(raw[1]),natural(raw[2]));
  default:throw Error("invalid name tag");
 }
}
function level(raw){
 sequence(raw);
 switch(raw[0]){
  case "zero":record(raw,1,"level");return zero;
  case "succ":record(raw,2,"level");return L.succ(level(raw[1]));
  case "max":case "imax":record(raw,3,"level");return L[raw[0]](level(raw[1]),level(raw[2]));
  case "param":case "mvar":record(raw,2,"level");return L[raw[0]](name(raw[1]));
  default:throw Error("invalid level tag");
 }
}
function binder(raw){
 if(!["default","implicit","strictImplicit","instImplicit"].includes(raw))throw Error("invalid binder");
 return unit(BI[raw]);
}
function expr(raw){
 sequence(raw);const tag=raw[0];
 switch(tag){
  case "bvar":record(raw,2,"expression");return E.bvar(natural(raw[1]));
  case "fvar":case "mvar":record(raw,2,"expression");return E[tag](name(raw[1]));
  case "sort":record(raw,2,"expression");return E.sort(level(raw[1]));
  case "const":record(raw,3,"expression");return E.const(name(raw[1]),list(sequence(raw[2]).map(level)));
  case "app":record(raw,3,"expression");return E.app(expr(raw[1]),expr(raw[2]));
  case "lam":case "forallE":record(raw,5,"expression");return E[tag](name(raw[1]),expr(raw[2]),expr(raw[3]),binder(raw[4]));
  case "letE":record(raw,6,"expression");return E.letE(name(raw[1]),expr(raw[2]),expr(raw[3]),expr(raw[4]),bool(raw[5]));
  case "nat":record(raw,2,"expression");return E.lit(Lit.nat(natural(raw[1])));
  case "str":record(raw,2,"expression");return E.lit(Lit.str(text(raw[1])));
  case "mdata":record(raw,3,"expression");return E.mdata(natural(raw[1]),expr(raw[2]));
  case "proj":record(raw,4,"expression");return E.proj(name(raw[1]),natural(raw[2]),expr(raw[3]));
  default:throw Error("invalid expression tag");
 }
}
function base(raw){record(raw,3,"base");return {name:name(raw[0]),levelParams:list(sequence(raw[1]).map(name)),type:expr(raw[2])};}
function hints(raw){
 sequence(raw);
 if(raw[0]==="regular"){record(raw,2,"hints");return H.regular(natural(raw[1]));}
 if(!["opaqueHint","abbrevHint"].includes(raw[0]))throw Error("invalid hints");
 record(raw,1,"hints");return unit(H[raw[0]]);
}
function safety(raw){if(!["safe","unsafeDef","partialDef"].includes(raw))throw Error("invalid safety");return unit(S[raw]);}
function definition(raw){record(raw,4,"definition");return {base:base(raw[0]),value:expr(raw[1]),hints:hints(raw[2]),safety:safety(raw[3])};}
function ctor(raw){record(raw,2,"constructor");return {name:name(raw[0]),type:expr(raw[1])};}
function inductive(raw){record(raw,3,"inductive");return {name:name(raw[0]),type:expr(raw[1]),ctors:list(sequence(raw[2]).map(ctor))};}
function group(raw){record(raw,4,"group");return {levelParams:list(sequence(raw[0]).map(name)),numParams:natural(raw[1]),types:list(sequence(raw[2]).map(inductive)),isUnsafe:bool(raw[3])};}
function request(raw){
 sequence(raw);const tag=raw[0];
 switch(tag){
  case "axiomDecl":record(raw,3,"request");return R.axiomDecl({base:base(raw[1]),isUnsafe:bool(raw[2])});
  case "definitionDecl":record(raw,2,"request");return R.definitionDecl(definition(raw[1]));
  case "theoremDecl":record(raw,3,"request");return R.theoremDecl({base:base(raw[1]),value:expr(raw[2])});
  case "opaqueDecl":record(raw,4,"request");return R.opaqueDecl({base:base(raw[1]),value:expr(raw[2]),isUnsafe:bool(raw[3])});
  case "mutualDefinitions":record(raw,2,"request");return R.mutualDefinitions(list(sequence(raw[1]).map(definition)));
  case "quot":record(raw,1,"request");return unit(R.quot);
  case "ordinaryInductive":{
   record(raw,2,"request");const value=record(raw[1],4,"ordinary-group"),type=inductive(value[2]);
   return R.ordinaryInductive({...type,levelParams:list(sequence(value[0]).map(name)),numParams:natural(value[1]),isUnsafe:bool(value[3])});
  }
  case "mutualInductive":case "nestedInductive":record(raw,2,"request");return R[tag](group(raw[1]));
  default:throw Error("unsupported authentic request tag "+tag);
 }
}
must(fixture.format==="psc1-authentic-string435-v1"&&fixture.leanVersion==="4.35.0"&&
 fixture.leanCommit==="eb6cafb7290e8bd5f2937522d8d804f58f02bafc","source-provenance");
must(Array.isArray(fixture.roots)&&Array.isArray(fixture.declarations)&&
 fixture.roots.length===fixture.declarations.length,"complete-request-order");
must(fixture.roots.every(root=>typeof root==="string")&&
 new Set(fixture.roots).size===fixture.roots.length,"unique-request-roots");
for(const root of ["String.ofList","Char.ofNat","UInt8.ofNat"])must(fixture.roots.includes(root),"genuine-root-"+root);
must(same(fixture.samples,["","a","é","€","😀","Aé€😀"]),"complete-utf8-sample-matrix");
const resources=get("psKernelResourcePolicyDefault");
must(resources.fuel===4096n&&resources.maxRecDepth===0n&&resources.maxNatSize===134217728n&&
 resources.maxDeclarations===0n&&resources.cancelled===false,"unchanged-resources");
const empty=accepted(get("psKernelKernelSessionEmpty")(resources,get("psKernelProviderDefault")),"empty");
let session=empty;
const qname=value=>value.split(".").reduce((parent,part)=>N.str(parent,part),unit(N.anonymous));
const cn=(value,levels=[])=>E.const(qname(value),list(levels));
const app=(fn,args)=>args.reduce((left,right)=>E.app(left,right),fn);
const constructionStart=performance.now();
const requests=fixture.declarations.map(request);
const standardAxioms=["propext","Classical.choice","Quot.sound"].map(qname);
for(let index=0;index<fixture.declarations.length;index++){
 if(fixture.declarations[index][0]==="axiomDecl"){
  must(standardAxioms.some(allowed=>same(allowed,requests[index].value.base.name)),
   "no-unchecked-fixture-axiom-"+fixture.roots[index]);
  console.log("PSC1_T01F_JS_SOURCE_AXIOM "+fixture.roots[index]);
 }
}
const constructionMs=performance.now()-constructionStart;
const admitStart=performance.now();
let corruptedDefinitionControls=0;
for(let index=0;index<requests.length;index++){
 console.log("PSC1_T01F_JS_ADMIT_BEGIN "+index+" "+fixture.roots[index]);
 if(fixture.declarations[index][0]==="definitionDecl"&&
    same(requests[index].value.base.name,qname("String.ofList"))){
  const original=requests[index];
  must(Boolean(original&&original.value&&same(original,R.definitionDecl(original.value))),"ofList-genuine-definition-request");
  const beforeSize=get("psKernelEnvironmentSize")(session.environment);
  const corrupted=R.definitionDecl({...original.value,value:E.lit(Lit.nat(0n))});
  must(rejected(get("psKernelV1AdmitDeclaration")(session,corrupted)),"reject-corrupted-ofList-definition");
  must(get("psKernelEnvironmentSize")(session.environment)===beforeSize&&
   !get("psKernelEnvironmentContains")(session.environment,qname("String.ofList")),"corrupted-definition-publishes-nothing");
  corruptedDefinitionControls++;
 }
 session=accepted(get("psKernelV1AdmitDeclaration")(session,requests[index]),"admission-"+fixture.roots[index]).session;
}
const admissionMs=performance.now()-admitStart;
must(corruptedDefinitionControls===1,"exactly-one-authentic-corrupted-definition-control");
const chars=value=>{
 const char=cn("Char");
 return [...value].reduceRight((tail,item)=>app(cn("List.cons",[zero]),
  [char,app(cn("Char.ofNat"),[E.lit(Lit.nat(BigInt(item.codePointAt(0))))]),tail]),app(cn("List.nil",[zero]),[char]));
};
const bytes=value=>{
 const byte=cn("UInt8");
 return [...Buffer.from(value,"utf8")].reduceRight((tail,item)=>app(cn("List.cons",[zero]),
  [byte,app(cn("UInt8.ofNat"),[E.lit(Lit.nat(BigInt(item)))]),tail]),app(cn("List.nil",[zero]),[byte]));
};
const find=n=>accepted(get("psKernelEnvironmentFind")(session.environment,qname(n)),"live-"+n);
const ci=get("PsKernelConstantInfo");
const eqExpr=(a,b)=>get("psKernelExprEq")(a)(b);
const names=raw=>list(sequence(raw).map(name));
// The original official metadata is an expected value only. It never enters
// an admission request, checked environment, declaration index or owner table.
const metadata=sequence(fixture.metadata),metadataNames=[];
for(const raw of metadata){
 sequence(raw);const tag=text(raw[0]);
 const expectedBase=base(tag==="defnInfo"?record(raw[1],4,"metadata-definition")[0]:raw[1]);
 const actual=accepted(get("psKernelEnvironmentFind")(session.environment,expectedBase.name),"metadata-present");
 must(typeof ci[tag]==="function"&&actual&&actual.value&&same(actual,ci[tag](actual.value)),"metadata-kind-"+tag);
 const value=actual.value;
 must(same(value.base.name,expectedBase.name)&&same(value.base.levelParams,expectedBase.levelParams)&&
  eqExpr(value.base.type,expectedBase.type),"metadata-authentic-base-"+tag);
 metadataNames.push(JSON.stringify(tag==="defnInfo"?raw[1][0][0]:raw[1][0]));
 switch(tag){
  case "axiomInfo":
   record(raw,3,"axiom metadata");
   must(value.isUnsafe===bool(raw[2]),"metadata-axiom-safety");break;
  case "defnInfo":{
   record(raw,2,"definition metadata");const expected=definition(raw[1]);
   must(eqExpr(value.value,expected.value)&&same(value.hints,expected.hints)&&
    same(value.safety,expected.safety),"metadata-definition-body-and-policy");break;
  }
  case "thmInfo":
   record(raw,3,"theorem metadata");
   must(eqExpr(value.value,expr(raw[2])),"metadata-theorem-proof");break;
  case "opaqueInfo":
   record(raw,4,"opaque metadata");
   must(eqExpr(value.value,expr(raw[2]))&&value.isUnsafe===bool(raw[3]),"metadata-opaque-body-and-safety");break;
  case "inductInfo":
   record(raw,10,"inductive metadata");
   must(value.numParams===natural(raw[2])&&value.numIndices===natural(raw[3])&&
    same(value.all,names(raw[4]))&&same(value.ctors,names(raw[5]))&&
    value.numNested===natural(raw[6])&&value.isRec===bool(raw[7])&&
    value.isReflexive===bool(raw[8])&&value.isUnsafe===bool(raw[9]),"metadata-inductive-fields");break;
  case "ctorInfo":
   record(raw,7,"constructor metadata");
   must(same(value.induct,name(raw[2]))&&value.cidx===natural(raw[3])&&
    value.numParams===natural(raw[4])&&value.numFields===natural(raw[5])&&
    value.isUnsafe===bool(raw[6]),"metadata-constructor-fields");break;
  case "recInfo":{
   record(raw,10,"recursor metadata");
   must(same(value.all,names(raw[2]))&&value.numParams===natural(raw[3])&&
    value.numIndices===natural(raw[4])&&value.numMotives===natural(raw[5])&&
    value.numMinors===natural(raw[6])&&value.k===bool(raw[8])&&
    value.isUnsafe===bool(raw[9]),"metadata-recursor-fields");
   const actualRules=array(value.rules),expectedRules=sequence(raw[7]);
   must(actualRules.length===expectedRules.length,"metadata-recursor-rule-count");
   expectedRules.forEach((rule,index)=>{
    record(rule,3,"recursor rule");const actualRule=actualRules[index];
    must(same(actualRule.ctor,name(rule[0]))&&actualRule.nFields===natural(rule[1])&&
     eqExpr(actualRule.rhs,expr(rule[2])),"metadata-recursor-rule-body");
   });break;
  }
  case "quotInfo":
   record(raw,3,"quotient metadata");
   must(["typeQ","ctorQ","liftQ","indQ"].includes(raw[2])&&
    same(value.kind,unit(get("PsKernelQuotKind")[raw[2]])),"metadata-quotient-kind");break;
  default:throw Error("invalid metadata tag "+tag);
 }
}
must(new Set(metadataNames).size===metadataNames.length&&
 BigInt(metadata.length)===get("psKernelEnvironmentSize")(session.environment),"complete-authentic-metadata-coverage");
const stringConstructor=find("String.ofByteArray");
must(stringConstructor&&same(stringConstructor,ci.ctorInfo(stringConstructor.value))&&
 stringConstructor.value.numFields===2n,"actual-String-bytearray-proof-constructor");
const exact=(a,b)=>get("psKernelExprEqual")(a)(b);
const requireStringConstructor=(term,label)=>{
 let head=term;
 while(head&&typeof head==="object"&&Object.hasOwn(head,"fn")&&
   same(head,E.app(head.fn,head.arg)))head=head.fn;
 must(exact(head,cn("String.ofByteArray")),label+"-actual-String-constructor");
};
const decode=(arena,root)=>accepted(get("psKernelExprV2DecodedRequire")(
 accepted(get("psKernelExprV2DecodeChecked")(arena),"decode"),root),"root");
const measurements=[];
for(const value of sequence(fixture.samples).map(text)){
 const started=performance.now();
 const literal=E.lit(Lit.str(value)),expanded=app(cn("String.ofList"),[chars(value)]);
 const data=term=>E.proj(qname("Array"),0n,E.proj(qname("ByteArray"),0n,E.proj(qname("String"),0n,term)));
 const proof=term=>E.proj(qname("String"),1n,term);
 const pairs=[["string",literal,expanded],["utf8-literal",data(literal),bytes(value)],
  ["utf8-ofList",data(expanded),bytes(value)],["validity",proof(literal),proof(expanded)]];
 let source={arena:get("psKernelExprV2PagedEmpty"),built:get("psKernelExprV2DecodedEmpty"),declarations:nil};
 const input=term=>{const result=accepted(get("psKernelDagGeneratedImport")(term,source),"input");source=result.fst;return result.snd;};
 const roots=pairs.map(([label,left,right])=>({label,left,right,a:input(left),b:input(right)}));
 const arena=source.arena,built=accepted(get("psKernelExprV2DecodeChecked")(arena),"decode-input");
 const owners=accepted(get("psKernelDagGeneratedFromSession")(session,arena,built),"derive-owners");
 const ownerMs=performance.now()-started;
 const context=get("psKernelKernelSessionChecker")(session,nil,safe).context;
 for(const {label,left,right,a,b} of roots){
  must(accepted(get("psKernelV1IsDefEq")(session,nil,safe,left,right),label+"-v1-defeq"),label+"-v1-equal");
  must(attempt(get("psKernelExprV2TryDefEqWithDeclarationsFuel")(4096n,context,owners.arena,owners.declarations,a,b),label+"-defeq"),label+"-equal");
  for(const [side,term,root,other] of [["left",left,a,b],["right",right,b,a]]){
   const caseLabel=label+"-"+side;
   const legacy=accepted(get("psKernelV1CheckExpression")(session,nil,safe,term),caseLabel+"-v1-check");
   const legacyNormalized=accepted(get("psKernelV1Whnf")(session,nil,safe,term),caseLabel+"-v1-whnf");
   if(label==="string"&&side==="right")requireStringConstructor(legacyNormalized,caseLabel+"-v1");
   must(exact(legacy.expression,term),caseLabel+"-v1-input-preserved");
   const checked=attempt(get("psKernelExprV2TryCheckWithDeclarationsFuel")(
    4096n,context,owners.arena,owners.declarations,root),caseLabel+"-check");
   const actualType=decode(checked.fst,checked.snd);
   must(accepted(get("psKernelV1IsDefEq")(session,nil,safe,actualType,legacy.type),caseLabel+"-type"),caseLabel+"-type-equal");
   const normalized=attempt(get("psKernelExprV2TryWhnfOwnedWithDeclarationsFuel")(
    4096n,context,owners.arena,owners.declarations,root),caseLabel+"-whnf");
   const actualWhnf=decode(normalized.fst,normalized.snd);
   if(label==="string"&&side==="right")requireStringConstructor(actualWhnf,caseLabel+"-direct");
   must(eqExpr(actualWhnf,legacyNormalized),caseLabel+"-whnf-output-matches-v1");
   must(accepted(get("psKernelV1IsDefEq")(session,nil,safe,term,actualWhnf),caseLabel+"-whnf-parity"),caseLabel+"-whnf-equal");
   const commands=list([C.check(root),C.whnf(root),C.isDefEq(root,other)]);
   const first=accepted(get("psKernelV1RunDag")(session,nil,safe,arena,commands),caseLabel+"-first-public");
   const second=accepted(get("psKernelV1RunDag")(first.session,nil,safe,arena,commands),caseLabel+"-reused-public");
   for(const result of [first,second]){
    const replies=array(result.replies),Reply=get("PsKernelDagReply");
    must(replies.length===3&&replies[0]&&replies[1]&&
     same(replies[0],Reply.checked(replies[0].value))&&
     same(replies[1],Reply.normalized(replies[1].value))&&
     same(replies[2],Reply.equal(true)),caseLabel+"-public-reply-kinds");
    const checkedReply=replies[0].value,whnfReply=replies[1].value;
    if(label==="string"&&side==="right")requireStringConstructor(whnfReply,caseLabel+"-public");
    must(exact(checkedReply.expression,term),caseLabel+"-public-check-input-preserved");
    must(accepted(get("psKernelV1IsDefEq")(session,nil,safe,checkedReply.type,legacy.type),
     caseLabel+"-public-check-type"),caseLabel+"-public-check-type-equal");
    must(eqExpr(whnfReply,legacyNormalized),caseLabel+"-public-whnf-output-matches-v1");
    must(accepted(get("psKernelV1IsDefEq")(session,nil,safe,term,whnfReply),
     caseLabel+"-public-whnf-parity"),caseLabel+"-public-whnf-equal");
    must(result.session.environment===session.environment&&result.session.resources===session.resources&&
     result.session.provider===session.provider,caseLabel+"-query-session-unmodified");
   }
  }
 }
 const badCases=[
  ["projection-index",E.proj(qname("String"),2n,literal)],
  ["ofList-argument",app(cn("String.ofList"),[E.lit(Lit.nat(0n))])],
  ["constructor-proof",app(cn("String.ofByteArray"),[E.proj(qname("String"),0n,literal),E.lit(Lit.nat(0n))])],
  ["ofList-universe",app(cn("String.ofList",[zero]),[chars(value)])]
 ];
 for(const [badLabel,bad] of badCases){
  must(rejected(get("psKernelV1CheckExpression")(session,nil,safe,bad)),badLabel+"-invalid-rejection");
  const malformed={arena:get("psKernelExprV2PagedEmpty"),built:get("psKernelExprV2DecodedEmpty"),declarations:nil};
  const imported=accepted(get("psKernelDagGeneratedImport")(bad,malformed),"bad-input");
  for(const command of [C.check(imported.snd),C.whnf(imported.snd),C.isDefEq(imported.snd,imported.snd)]){
   must(rejected(get("psKernelV1RunDag")(session,nil,safe,imported.fst.arena,list([command]))),badLabel+"-public-invalid-rejection");
  }
 }
 const different=E.lit(Lit.str(value+"x"));
 must(!accepted(get("psKernelV1IsDefEq")(session,nil,safe,literal,different),"distinct-v1"),"distinct-strings-v1");
 let unequalSource={arena:get("psKernelExprV2PagedEmpty"),built:get("psKernelExprV2DecodedEmpty"),declarations:nil};
 const unequalLeft=accepted(get("psKernelDagGeneratedImport")(literal,unequalSource),"distinct-left");
 const unequalRight=accepted(get("psKernelDagGeneratedImport")(different,unequalLeft.fst),"distinct-right");
 const unequal=accepted(get("psKernelV1RunDag")(session,nil,safe,unequalRight.fst.arena,
  list([C.isDefEq(unequalLeft.snd,unequalRight.snd)])),"distinct-public");
 must(same(array(unequal.replies),[get("PsKernelDagReply").equal(false)]),"distinct-strings-public");
 must(unequal.session.environment===session.environment,"distinct-query-environment-unmodified");
 measurements.push({sample:value,utf8Bytes:Buffer.byteLength(value),owners:array(owners.declarations).length,
  ownerAndConstructionMs:ownerMs,totalMs:performance.now()-started,
  arenaNodes:arena.size.toString(),ownedArenaNodes:owners.arena.size.toString(),memory:process.memoryUsage()});
 console.log("PSC1_T01F_JS_CASE_PASS "+JSON.stringify(value));
}
must(get("psKernelEnvironmentSize")(empty.environment)===0n,"empty-session-immutable");
console.log("PSC1_T01F_FULL_STRING_JS: PASS "+JSON.stringify({kernelSha256,fixtureSha256,requests:requests.length,metadata:metadata.length,
 declarations:get("psKernelEnvironmentSize")(session.environment).toString(),samples:fixture.samples.length,
 assertions,constructionMs,admissionMs,measurements}));

