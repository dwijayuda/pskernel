import {pathToFileURL} from "node:url";
import path from "node:path";

// Mirrors PsKernelNameWorkerRegression.lean. The raw-position oracle follows
// Lean 4.35 String.Pos.Raw get/next (default 'A' at non-boundaries), using an
// independently constructed UTF-8 boundary map. No Lean process is invoked.
const filename=process.argv[2];
if(!filename)throw Error("PSC1_NAME_WORKER_REQUIRES_GENERATED_KERNEL");
const k=await import(pathToFileURL(path.resolve(filename)).href);
const get=name=>{if(!(name in k))throw Error("PSC1_NAME_WORKER_MISSING_EXPORT "+name);return k[name];};
const unit=x=>typeof x==="function"?x():x;
let assertions=0;
const must=(condition,label)=>{if(condition!==true)throw Error("PSC1_NAME_WORKER_FAIL "+label);assertions++;};
const accepted=(value,label)=>{
 if(value&&typeof value==="object"&&Object.hasOwn(value,"value"))return value.value;
 throw Error("PSC1_NAME_WORKER_REJECTED "+label+": "+
  JSON.stringify(value,(_,v)=>typeof v==="bigint"?String(v):v));
};
const rejected=value=>Boolean(value&&typeof value==="object"&&Object.hasOwn(value,"error"));
const same=(a,b)=>{
 if(a===b)return true;
 if(a===null||b===null||typeof a!=="object"||typeof b!=="object")return false;
 const ak=Reflect.ownKeys(a),bk=Reflect.ownKeys(b);
 return ak.length===bk.length&&ak.every(key=>Object.hasOwn(b,key)&&same(a[key],b[key]));
};
const invalid=(value,label)=>must(rejected(value)&&typeof value.error?.message==="string"&&
 same(value.error,get("PsKernelError").rejectedInvalid(value.error.message)),label);
const rawWorker=get("psKernelStringEqFromWorkerWithFuel");
const rawPublic=get("psKernelStringEqFromWithFuel"),stringEq=get("psKernelStringEq");
const nameWorker=get("psKernelNameEqWorker"),nameEq=get("psKernelNameEq");
const N=get("PsKernelName"),E=get("PsKernelExpr"),L=get("PsKernelLevel");
const List=get("List"),nil=unit(List.nil);
const list=xs=>xs.reduceRight((tail,head)=>List.cons(head,tail),nil);
const array=xs=>{const out=[];while(xs&&typeof xs==="object"&&Object.hasOwn(xs,"head")){out.push(xs.head);xs=xs.tail;}return out;};
const encoder=new TextEncoder(),views=new Map();
const view=text=>{
 let result=views.get(text);if(result)return result;
 const chars=new Map();let offset=0n;
 for(const ch of text){chars.set(offset,ch);offset+=BigInt(encoder.encode(ch).length);}
 result={size:BigInt(encoder.encode(text).length),chars};views.set(text,result);return result;
};
const rawReference=(fuel,left,right,lp,rp)=>{
 const a=view(left),b=view(right);
 while(fuel!==0n){
  fuel--;
  if(lp>=a.size)return rp>=b.size;
  if(rp>=b.size)return false;
  const ac=a.chars.get(lp)??"A",bc=b.chars.get(rp)??"A";
  if(ac!==bc)return false;
  lp+=BigInt(encoder.encode(ac).length);rp+=BigInt(encoder.encode(bc).length);
 }
 return false;
};
const raw=(fuel,left,right,lp,rp)=>rawPublic(fuel)(left)(right)(lp)(rp);
const compareRaw=(label,fuel,left,right,lp,rp)=>{
 const expected=rawReference(fuel,left,right,lp,rp);
 must(rawWorker(fuel,left,right,lp,rp)===expected,label+"-worker");
 must(raw(fuel,left,right,lp,rp)===expected,label+"-public");
};
{
 const words=["","A","B","é","é","🙂","L∃∀N","\u0000x"];
 let rawCount=0,full=0,long=0;
 for(const left of words)for(const right of words){
  must(stringEq(left,right)===(left===right),"full-string-exact");full++;
  for(const lp of [0n,1n,2n,3n,4n,7n,8n,9n])
   for(const rp of [0n,1n,2n,3n,4n,7n,8n,9n])
    for(const fuel of [0n,1n,2n,4n,8n,16n]){
     compareRaw("raw-matrix",fuel,left,right,lp,rp);rawCount++;
    }
 }
 const huge=1000000000000000000000000000023n;
 const controls=[
  ["zero-empty",0n,"","",0n,0n,false],
  ["zero-after-end",0n,"A","B",9n,9n,false],
  ["one-empty",1n,"","",0n,0n,true],
  ["one-char-exhausted",1n,"A","A",0n,0n,false],
  ["two-char-complete",2n,"A","A",0n,0n,true],
  ["current-mismatch",1n,"A","B",0n,0n,false],
  ["left-end-only",1n,"A","A",1n,0n,false],
  ["right-end-only",1n,"A","A",0n,1n,false],
  ["both-arbitrary-end",1n,"A","B",9n,9n,true],
  ["middle-two-byte-default",2n,"é","A",1n,0n,true],
  ["middle-four-byte-default",2n,"🙂","A",3n,0n,true],
  ["middle-three-default-short",3n,"🙂","AAA",1n,0n,false],
  ["middle-three-default-enough",4n,"🙂","AAA",1n,0n,true],
  ["huge-raw-positions",1n,"α","β",huge,huge,true],
  ["distinct-normalizations",1n,"é","é",0n,0n,false],
  ["one-unicode-scalar",2n,"🙂","🙂",0n,0n,true]
 ];
 for(const [label,fuel,left,right,lp,rp,answer] of controls){
  compareRaw(label,fuel,left,right,lp,rp);
  must(raw(fuel,left,right,lp,rp)===answer,label+"-exact");
 }
 for(const count of [1,32,256,1024,4096]){
  const left="A".repeat(count),mismatch="B"+"A".repeat(count-1),n=BigInt(count);
  compareRaw("ascii-equal-insufficient",n,left,left,0n,0n);
  must(raw(n,left,left,0n,0n)===false,"ascii-equal-insufficient-exact");
  compareRaw("ascii-equal-sufficient",n+1n,left,left,0n,0n);
  must(raw(n+1n,left,left,0n,0n)===true,"ascii-equal-sufficient-exact");
  compareRaw("ascii-first-mismatch",n+1n,left,mismatch,0n,0n);
  must(stringEq(left,mismatch)===false,"ascii-first-mismatch-exact");long+=3;
 }
 for(const count of [1,32,256]){
  const text="🙂".repeat(count),n=BigInt(count);
  compareRaw("unicode-insufficient",n,text,text,0n,0n);
  must(raw(n,text,text,0n,0n)===false,"unicode-insufficient-exact");
  compareRaw("unicode-sufficient",n+1n,text,text,0n,0n);
  must(raw(n+1n,text,text,0n,0n)===true,"unicode-sufficient-exact");
  must(stringEq(text,text)===true,"unicode-byte-derived-public-budget");long+=3;
 }
 must(rawCount===24576&&full===64&&controls.length===16&&long===24,"string-matrix-counts");
 console.log("PSC1_NAME_WORKER_STRINGS_PASS raw=24576 full=64 controls=16 long=24");
}

const anonymous=()=>({kind:"anonymous",actual:unit(N.anonymous)});
const str=(parent,value)=>({kind:"str",parent,value,actual:N.str(parent.actual,value)});
const num=(parent,value)=>({kind:"num",parent,value,actual:N.num(parent.actual,value)});
const name=value=>str(anonymous(),value);
const deepName=(seed,depth)=>{
 let result=name(seed);
 for(let i=0;i<depth;i++)result=i%2===0?num(result,BigInt(i)):str(result,"🙂");
 return result;
};
const nameReference=(left,right)=>{
 while(true){
  if(left.kind!==right.kind)return false;
  if(left.kind==="anonymous")return true;
  if(left.value!==right.value)return false;
  left=left.parent;right=right.parent;
 }
};
{
 const names=[anonymous(),name(""),name("A"),name("0"),num(anonymous(),0n),num(anonymous(),1n),
  num(anonymous(),9007199254740993n),num(anonymous(),9007199254806514n),
  str(name("A"),"B"),name("A.B"),name("é"),name("é")];
 for(const depth of [1,8,64,256])names.push(deepName("A",depth),deepName("B",depth));
 let comparisons=0;
 for(const left of names){
  const partial=nameEq(left.actual);must(typeof partial==="function","name-public-curried");
  for(const right of names){
   const expected=nameReference(left,right);
   must(nameWorker(left.actual,right.actual)===expected,"name-worker-exact");
   must(partial(right.actual)===expected,"name-public-partial-exact");comparisons++;
  }
 }
 const deep=deepName("A",1024),equal=deepName("A",1024),other=deepName("B",1024);
 const cases=[[deep,equal,true],[deep,other,false],
  [str(deep,"tail"),str(equal,"Tail"),false],[str(deep,"1"),num(equal,1n),false]];
 for(const [left,right,expected] of cases){
  must(nameReference(left,right)===expected,"deep-name-independent");
  must(nameWorker(left.actual,right.actual)===expected,"deep-name-worker");
  must(nameEq(left.actual)(right.actual)===expected,"deep-name-public");
 }
 must(names.length===20&&comparisons===400&&cases.length===4,"name-matrix-counts");
 console.log("PSC1_NAME_WORKER_NAMES_PASS pairs=400 deep=4 maxDepth=1024");
 const p0=rawPublic(2n);must(typeof p0==="function","raw-partial-fuel");
 const p1=p0("🙂");must(typeof p1==="function","raw-partial-left");
 const p2=p1("🙂");must(typeof p2==="function","raw-partial-right");
 const p3=p2(0n);must(typeof p3==="function","raw-partial-left-position");
 must(p3(0n)===true,"raw-partial-first");
 must(p3(4n)===false,"raw-partial-alternate");
 must(p3(0n)===true,"raw-partial-reuse");
 must(p2(4n)(4n)===true,"raw-partial-second-position");
 const partial=nameEq(deep.actual);must(typeof partial==="function","name-partial");
 must(partial(equal.actual)===true,"name-partial-first");
 must(partial(other.actual)===false,"name-partial-alternate");
 must(partial(equal.actual)===true,"name-partial-reuse");
 console.log("PSC1_NAME_WORKER_ABI_PASS rawPartials=4 namePartials=1 executions=7");
}

const S=get("PsKernelDefinitionSafety"),H=get("PsKernelReducibilityHints");
const Request=get("PsKernelDeclarationRequest"),D=get("PsKernelDagDeclarationRequest");
const C=get("PsKernelDagCommand"),Reply=get("PsKernelDagReply");
const safe=unit(S.safe),hint=unit(H.abbrevHint);
const level=n=>{let value=unit(L.zero);for(let i=0;i<n;i++)value=L.succ(value);return value;};
const prefix=name("NameWorker");
const names=[str(prefix,"é"),str(prefix,"é"),str(prefix,"αβ"),str(prefix,"🙂"),
 str(prefix,"with.dot"),str(str(prefix,"with"),"dot"),
 num(prefix,9007199254740993n),num(prefix,9007199254806514n),
 str(prefix,"Plain"),deepName("NameWorkerDeep",32)];
const empty=accepted(get("psKernelKernelSessionEmpty")(
 get("psKernelResourcePolicyDefault"),get("psKernelProviderDefault")),"empty-session");
let originalSession=empty,arena=unit(get("psKernelExprV2PagedEmpty"));
const build=(kind,...args)=>{
 const result=accepted(get("psKernelExprV2PagedMk"+kind)(arena,...args),"build-"+kind);
 arena=result.fst;return result.snd;
};
const requests=[],fixtures=[];
for(let i=0;i<names.length;i++){
 const name=names[i].actual,type=E.sort(level(i+1)),value=E.sort(level(i)),term=E.const(name,nil);
 const typeId=build("Sort",level(i+1)),valueId=build("Sort",level(i)),root=build("Const",name,nil);
 fixtures.push({name,type,value,term,typeId,valueId,root});
 const old=Request.definitionDecl({base:{name,levelParams:nil,type},value,hints:hint,safety:safe});
 requests.push(D.definitionDecl({base:{name,levelParams:nil,type:typeId},value:valueId,hints:hint,safety:safe}));
 originalSession=accepted(get("psKernelV1AdmitDeclaration")(originalSession,old),"reference-admit").session;
}
const missingName=name("NameWorkerMissing").actual,missingRoot=build("Const",missingName,nil);
const canonical=accepted(get("psKernelExprV2PagedValidate")(arena),"canonical");
const commands=[...requests.map(request=>C.admit(request)),
 ...fixtures.flatMap(fixture=>[C.check(fixture.root),C.whnf(fixture.root)])];
const batch=accepted(get("psKernelV1RunDag")(empty,nil,safe,canonical,list(commands)),"public-batch");
const replies=array(batch.replies);
must(fixtures.length===10&&replies.length===30&&
 get("psKernelEnvironmentSize")(batch.session.environment)===10n&&
 get("psKernelEnvironmentSize")(originalSession.environment)===10n,"real-batch-count");
for(let i=0;i<fixtures.length;i++){
 const fixture=fixtures[i];
 must(same(replies[10+2*i],Reply.checked({expression:fixture.term,type:fixture.type})),"dag-checked-exact-type-and-expression");
 must(same(replies[11+2*i],Reply.normalized(fixture.value)),"dag-normalized-exact-body");
 const checked=accepted(get("psKernelV1CheckExpression")(originalSession,nil,safe,fixture.term),"reference-check");
 const normalized=accepted(get("psKernelV1Whnf")(originalSession,nil,safe,fixture.term),"reference-whnf");
 must(same(checked.type,fixture.type),"reference-checked-exact-type");
 must(same(normalized,fixture.value),"reference-normalized-exact-body");
}
must(get("psKernelEnvironmentNameHash")(names[6].actual)===get("psKernelEnvironmentNameHash")(names[7].actual),
 "numeric-hash-collision-is-real");
const first=fixtures[0],badName=name("NameWorkerIlltyped").actual;
const unknownName=name("NameWorkerUnknownBody").actual;
const negatives=[
 [Request.definitionDecl({base:{name:first.name,levelParams:nil,type:first.type},
   value:first.value,hints:hint,safety:safe}),requests[0]],
 [Request.definitionDecl({base:{name:badName,levelParams:nil,type:E.sort(unit(L.zero))},
   value:E.sort(unit(L.zero)),hints:hint,safety:safe}),
  D.definitionDecl({base:{name:badName,levelParams:nil,type:first.valueId},
   value:first.valueId,hints:hint,safety:safe})],
 [Request.definitionDecl({base:{name:unknownName,levelParams:nil,type:first.type},
   value:E.const(missingName,nil),hints:hint,safety:safe}),
  D.definitionDecl({base:{name:unknownName,levelParams:nil,type:first.typeId},
   value:missingRoot,hints:hint,safety:safe})]
];
for(const [old,dag] of negatives){
 invalid(get("psKernelV1AdmitDeclaration")(originalSession,old),"reference-rejects-invalid-declaration");
 invalid(get("psKernelV1RunDag")(batch.session,nil,safe,canonical,list([C.admit(dag)])),
  "dag-rejects-invalid-declaration");
}
invalid(get("psKernelV1CheckExpression")(empty,nil,safe,first.term),"fresh-reference-cannot-resolve-prior-name");
invalid(get("psKernelV1RunDag")(empty,nil,safe,canonical,list([C.check(first.root)])),
 "fresh-dag-cannot-resolve-prior-name");
must(empty.resources.fuel===4096n&&get("psKernelEnvironmentSize")(empty.environment)===0n&&
 get("psKernelEnvironmentSize")(batch.session.environment)===10n&&
 get("psKernelEnvironmentSize")(originalSession.environment)===10n,"resource-policy-and-environments-preserved");
console.log("PSC1_NAME_WORKER_CHECKING_PASS declarations=10 checked=10 normalized=10 negatives=4 official=native-gate");
console.log("PSC1_NAME_WORKER_PASS assertions="+assertions);
