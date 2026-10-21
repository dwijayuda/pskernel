import {pathToFileURL} from "node:url";
import path from "node:path";

const filename=process.argv[2];
if(!filename)throw Error("PSC1_INVALID_RECURSOR_OCCURRENCE_REQUIRES_GENERATED_KERNEL");
const k=await import(pathToFileURL(path.resolve(filename)).href);
const get=name=>{if(!(name in k))throw Error("PSC1_INVALID_RECURSOR_OCCURRENCE_MISSING_EXPORT "+name);return k[name];};
const unit=x=>typeof x==="function"?x():x;
let assertions=0;
const must=(condition,label)=>{if(condition!==true)throw Error("PSC1_INVALID_RECURSOR_OCCURRENCE_JS_FAIL "+label);assertions++;};
const accepted=(x,label)=>{
 if(x&&typeof x==="object"&&Object.hasOwn(x,"value"))return x.value;
 const error=x&&typeof x==="object"&&Object.hasOwn(x,"error")?x.error:null;
 throw Error("PSC1_INVALID_RECURSOR_OCCURRENCE_JS_REJECTED "+label+": "+
   (typeof error==="string"?error:error?.message??"no value"));
};
const same=(a,b)=>{
 if(a===b)return true;
 if(a===null||b===null||typeof a!=="object"||typeof b!=="object")return false;
 const keys=Reflect.ownKeys(a),other=Reflect.ownKeys(b);
 return keys.length===other.length&&keys.every(key=>Object.hasOwn(b,key)&&same(a[key],b[key]));
};
const List=get("List"),nil=unit(List.nil),Option=get("Option"),none=unit(Option.none);
const list=xs=>xs.reduceRight((tail,head)=>List.cons(head,tail),nil);
const N=get("PsKernelName"),E=get("PsKernelExpr"),L=get("PsKernelLevel"),B=get("PsKernelBinderInfo");
const Request=get("PsKernelDeclarationRequest"),ErrorType=get("PsKernelError");
const name=s=>N.str(unit(N.anonymous),s),child=(n,s)=>N.str(n,s);
const z=unit(L.zero),one=L.succ(z),two=L.succ(one),type=E.sort(one),bi=unit(B.default);
const cn=(n,levels=[])=>E.const(n,list(levels));
const all=(n,t,b)=>E.forallE(name(n),t,b,bi),lam=(n,t,b)=>E.lam(name(n),t,b,bi);
const bv=i=>E.bvar(i),app=(f,a)=>E.app(f,a),apps=(f,args)=>args.reduce(app,f);
const boolean=name("OccurrenceBool"),ff=child(boolean,"ff"),tt=child(boolean,"tt"),boolType=cn(boolean);
const gate=name("OccurrenceGate"),gateCtor=child(gate,"mk"),gateAt=index=>apps(cn(gate),[index]);
const simple=(n,t,ctors,params=0n)=>({
 levelParams:nil,name:n,type:t,ctors:list(ctors.map(([name,type])=>({name,type}))),isUnsafe:false,numParams:params});
const boolDecl=simple(boolean,type,[[ff,boolType],[tt,boolType]]);
const gateDecl=simple(gate,all("b",boolType,E.sort(z)),[[gateCtor,gateAt(cn(ff))]]);
const recName=get("psKernelSimpleRecName")(gate);
const eliminated=(minor,index,major)=>apps(cn(recName,[two]),[
 lam("b",boolType,lam("h",gateAt(bv(0n)),type)),minor,index,major]);
const ownerDecl=(n,index,recursive,erased)=>{
 const owner=cn(n),minor=recursive?owner:boolType;
 const field=erased?
  app(lam("T",type,eliminated(minor,index,bv(1n))),owner):
  eliminated(minor,index,bv(0n));
 return simple(n,type,[[child(n,"mk"),all("h",gateAt(index),all("child",field,owner))]]);
};
const empty=accepted(get("psKernelKernelSessionEmpty")(
 get("psKernelResourcePolicyDefault"),get("psKernelProviderDefault")),"empty");
const admit=(session,decl)=>get("psKernelV1AdmitDeclaration")(session,Request.ordinaryInductive(decl));
const first=accepted(admit(empty,boolDecl),"Bool");
const ready=accepted(admit(first.session,gateDecl),"Gate").session;
const rec=accepted(get("psKernelEnvironmentFind")(ready.environment,recName),"checked recursor");
must(rec && same(rec,get("PsKernelConstantInfo").recInfo(rec.value)) &&
 rec.value.k===true,"actual-checked-K-recursor");
const bad=ownerDecl(name("OccurrenceBad"),cn(tt),true,false);
const good=ownerDecl(name("OccurrenceGood"),cn(ff),true,false);
const nonrecursive=ownerDecl(name("OccurrenceNonrecursive"),cn(tt),false,false);
const erased=ownerDecl(name("OccurrenceErased"),cn(tt),false,true);
const unsafeBad={...bad,isUnsafe:true};
const message="simple inductive field has an invalid recursor-headed recursive occurrence";
const rejected=admit(ready,bad);
must(rejected&&Object.hasOwn(rejected,"error")&&
 same(rejected.error,ErrorType.rejectedInvalid(message)),"public-invalid-exact-diagnostic");
accepted(admit(ready,good),"reducible-recursive-minor");
accepted(admit(ready,nonrecursive),"nonrecursive-stuck-minor");
const isUnsupported=result=>result&&Object.hasOwn(result,"error")&&
 typeof result.error?.message==="string"&&same(result.error,ErrorType.declinedUnsupported(result.error.message));
must(isUnsupported(admit(ready,erased)),"original-only-erased-occurrence-keeps-unsupported");
must(isUnsupported(admit(ready,unsafeBad)),"unsafe-recursive-occurrence-keeps-unsupported");
const zeroFuel={...ready,resources:{...ready.resources,fuel:0n}},limited=admit(zeroFuel,bad);
must(limited&&Object.hasOwn(limited,"error")&&typeof limited.error?.message==="string"&&
 same(limited.error,ErrorType.resourceExhausted(limited.error.resource,limited.error.message)),
 "zero-fuel-precedes-semantic-guard");
for(const n of [bad.name,child(bad.name,"mk"),get("psKernelSimpleRecName")(bad.name)]){
 must(same(get("psKernelEnvironmentFind")(ready.environment,n),none),
  "failed-admission-publishes-no-type-ctor-or-recursor");
}
const boxName=name("OccurrenceBox");
const box=simple(boxName,all("A",type,type),[[child(boxName,"mk"),
 all("A",type,all("value",bv(0n),apps(cn(boxName),[bv(1n)])))]],1n);
const boxed=accepted(admit(ready,box),"Box").session;
const nestedName=name("OccurrenceNested"),nestedType=cn(nestedName);
const nested=simple(nestedName,type,[[child(nestedName,"mk"),
 all("child",apps(cn(boxName),[nestedType]),nestedType)]]);
must(isUnsupported(admit(boxed,nested)),"genuine-nested-ordinary-keeps-unsupported");
const group={levelParams:nil,numParams:0n,types:list([{
 name:nested.name,type:nested.type,ctors:nested.ctors}]),isUnsafe:false};
accepted(get("psKernelV1AdmitDeclaration")(boxed,Request.nestedInductive(group)),
 "genuine-nested-explicit-route");
console.log("PSC1_INVALID_RECURSOR_OCCURRENCE_JS: PASS "+assertions+
 " invalid/reducible/nonrecursive/erased/unsafe/nested/resource/publication controls");

