import { pathToFileURL } from "node:url";
import path from "node:path";

const filename=process.argv[2];
if(!filename)throw Error("PSC1_INFER_ONLY_REQUIRES_GENERATED_KERNEL");
const k=await import(pathToFileURL(path.resolve(filename)).href);
const get=name=>{
  if(!(name in k))throw Error("PSC1_INFER_ONLY_MISSING_EXPORT "+name);
  return k[name];
};
let assertions=0;
const must=(value,label)=>{
  if(value!==true)throw Error("PSC1_INFER_ONLY_FAILED "+label);
  assertions++;
};
const accepted=(result,label)=>{
  if(result&&typeof result==="object"&&"value" in result)return result.value;
  throw Error("PSC1_INFER_ONLY_UNEXPECTED_REJECTION "+label);
};
const rejected=result=>Boolean(result&&typeof result==="object"&&"error" in result);
const same=(left,right)=>{
  if(left===right)return true;
  if(left===null||right===null||typeof left!=="object"||typeof right!=="object")return false;
  const keys=Reflect.ownKeys(left),others=Reflect.ownKeys(right);
  return keys.length===others.length&&keys.every(key=>Object.hasOwn(right,key)&&same(left[key],right[key]));
};
const List=get("List"),nil=typeof List.nil==="function"?List.nil():List.nil;
const list=xs=>xs.reduceRight((tail,head)=>List.cons(head,tail),nil);
const N=get("PsKernelName"),E=get("PsKernelExpr"),L=get("PsKernelLevel");
const B=get("PsKernelBinderInfo"),S=get("PsKernelDefinitionSafety"),Lit=get("PsKernelLiteral");
const D=get("PsKernelDagDeclarationRequest"),Request=get("PsKernelDeclarationRequest");
const name=text=>N.str(N.anonymous,text);
const exact=(left,right)=>get("psKernelExprEqual")(left)(right);
let arena=get("psKernelExprV2PagedEmpty");
const build=(kind,term,...args)=>{
  const result=accepted(get("psKernelExprV2PagedMk"+kind)(arena,...args),"build-"+kind);
  arena=result.fst;
  return {id:result.snd,term};
};
const sort=level=>build("Sort",E.sort(level),level);
const bv=index=>build("BVar",E.bvar(index),index);
const mv=n=>build("MVar",E.mvar(n),n);
const fv=n=>build("FVar",E.fvar(n),n);
const cn=n=>build("Const",E.const(n,nil),n,nil);
const app=(f,a)=>build("App",E.app(f.term,a.term),f.id,a.id);
const lam=(n,t,b,info=B.default)=>build("Lam",E.lam(n,t.term,b.term,info),n,t.id,b.id,info);
const forall=(n,t,b)=>build("Forall",E.forallE(n,t.term,b.term,B.default),n,t.id,b.id,B.default);
const letE=(n,t,v,b,nondep=false)=>build("Let",E.letE(n,t.term,v.term,b.term,nondep),n,t.id,v.id,b.id,nondep);
const md=(tag,b)=>build("MData",E.mdata(tag,b.term),tag,b.id);
const lit=value=>build("Lit",E.lit(value),value);
const s0=sort(L.zero),s1=sort(L.succ(L.zero)),b0=bv(0n),b1=bv(1n);
const A=name("A"),x=name("x");
const idType=forall(A,s1,forall(x,b0,b1));
const metadataType=forall(A,s1,md(9n,md(8n,forall(x,b0,b1))));
const letType=forall(A,s1,letE(name("T"),s1,b0,forall(x,b0,b1)));
let session=accepted(get("psKernelKernelSessionEmpty")(
  get("psKernelResourcePolicyDefault"),get("psKernelProviderDefault")),"session");
let declarations=nil;
for(const [n,type,isUnsafe] of [
  [name("inferId"),idType,false],[name("inferHidden"),metadataType,false],
  [name("inferLetType"),letType,false],[name("inferUnsafe"),s1,true]
]){
  const base=get("PsKernelConstantBase").mk(n,nil,type.term);
  session=accepted(get("psKernelV1AdmitDeclaration")(session,
    Request.axiomDecl(get("PsKernelAxiomInfo").mk(base,isUnsafe))),"fixture-axiom").session;
  declarations=get("psKernelDagDeclarationsAfterAdmission")(
    D.axiomDecl(get("PsKernelDagConstantBase").mk(n,nil,type.id),isUnsafe),declarations);
}
const partialName=name("inferPartial"),hints=get("PsKernelReducibilityHints").abbrevHint;
session=accepted(get("psKernelV1AdmitDeclaration")(session,
  Request.definitionDecl(get("PsKernelDefinitionInfo").mk(
    get("PsKernelConstantBase").mk(partialName,nil,s1.term),s0.term,hints,S.partialDef))),
  "fixture-partial").session;
declarations=get("psKernelDagDeclarationsAfterAdmission")(
  D.definitionDecl(get("PsKernelDagDefinition").mk(
    get("PsKernelDagConstantBase").mk(partialName,nil,s1.id),s0.id,hints,S.partialDef)),declarations);
const id=cn(name("inferId")),missing=mv(name("notCheckedArgument"));
const unchecked=app(app(id,s0),missing);
const fixtures=[
  ["sort",s0],["metadata",md(5n,md(6n,s0))],["lambda",lam(x,s1,b0)],
  ["unchecked-lambda-domain",lam(x,missing,s0,B.implicit)],["forall",idType],
  ["one-argument",app(id,s0)],["two-arguments",unchecked],
  ["lazy-metadata-domain",app(app(cn(name("inferHidden")),s0),missing)],
  ["lazy-let-domain",app(app(cn(name("inferLetType")),s0),missing)],
  ["unused-let-value",letE(x,s1,missing,s0)],["unused-let-type",letE(x,missing,s0,s0,true)],
  ["dependent-let-body",letE(x,s1,s0,b0)],["nested-shadow",lam(x,s1,letE(x,s1,b0,b0))],
  ["unsafe-constant",cn(name("inferUnsafe"))],["partial-constant",cn(partialName)],
  ["bad-head",app(s0,missing)],["loose",b0],["unknown-local",fv(name("absent"))],
  ["metavariable",missing],["nat-literal",lit(Lit.nat(17n))],["string-literal",lit(Lit.str("type"))]
];
const base=get("psKernelKernelSessionChecker")(session,nil,S.safe);
const initial=owning=>get("psKernelExprV2CheckStateWithWhnf")(
  get("psKernelExprV2CheckStateEmpty")(owning),
  get("psKernelExprV2WhnfStateForDeclarations")(owning,declarations));
const ctx=scalar=>get("psKernelExprV2CheckContextEmpty")(scalar);
const infer=get("psKernelExprV2TryInferStateWithFuel");
const originalInfer=get("psKernelCheckerInfer"),originalCheck=get("psKernelCheckerCheck");
const emptyOriginal=get("psKernelCheckerStateEmpty");
const compare=(original,attempted,label)=>{
  const actual=accepted(attempted,label+"-direct");
  if(rejected(original)){
    must(rejected(actual)&&actual.error===original.error,label+"-exact-error");
  }else{
    const expected=accepted(original,label+"-original"),result=accepted(actual,label+"-dag");
    const decoded=accepted(get("psKernelExprV2DecodeChecked")(result.fst.whnf.arena),label+"-decode");
    const type=accepted(get("psKernelExprV2DecodedRequire")(decoded,result.snd),label+"-type");
    must(exact(expected.fst,type)===true,label+"-exact-type");
    must(expected.snd.nextFresh===result.fst.nextFresh,label+"-fresh");
  }
};
let comparisons=0;
for(const [label,node] of fixtures){
  for(const fuel of [0n,1n,2n,3n,4n,6n,12n,64n]){
    for(const maxRecDepth of [0n,1n])for(const recDepth of [0n,15n,16n]){
      const scalar={...base.context,maxRecDepth,recDepth};
      compare(originalInfer(fuel,scalar,emptyOriginal,node.term),
        infer(fuel,ctx(scalar),initial(arena),node.id),label+"-"+fuel+"-"+maxRecDepth+"-"+recDepth);
      comparisons++;
    }
  }
}
const inferred=accepted(accepted(infer(64n,ctx(base.context),initial(arena),unchecked.id),
  "warm-direct"),"warm-inferred");
must(!same(inferred.fst.inferOnly,nil),"infer-only-app-cache-populated");
must(same(inferred.fst.checkedInfer,nil),"infer-only-cannot-populate-checked-cache");
compare(originalCheck(64n,base.context,emptyOriginal,unchecked.term),
  get("psKernelExprV2TryCheckStateWithFuel")(64n,ctx(base.context),inferred.fst,unchecked.id),
  "infer-only-cache-cannot-authorize-check");
const warmScalar={...base.context,maxRecDepth:1n,recDepth:0n};
const warmOriginal=accepted(originalInfer(64n,warmScalar,emptyOriginal,unchecked.term),"warm-original");
const warmDirect=accepted(accepted(infer(64n,ctx(warmScalar),initial(arena),unchecked.id),
  "warm-fixed-policy-some"),"warm-fixed-policy-result");
for(const fuel of [0n,1n,64n])for(const recDepth of [0n,15n,16n]){
  const scalar={...warmScalar,recDepth};
  compare(originalInfer(fuel,scalar,warmOriginal.snd,unchecked.term),
    infer(fuel,ctx(scalar),warmDirect.fst,unchecked.id),"warm-entry-"+fuel+"-"+recDepth);
}
const huge=lit(Lit.nat(1n<<128n)),limited={...base.context,maxNatSize:1n};
compare(originalInfer(64n,limited,emptyOriginal,huge.term),
  infer(64n,ctx(limited),initial(arena),huge.id),"retains-nat-limit");
must(comparisons===1008,"complete-fixture-matrix");
console.log("PSC1_V2_DAG_JS_INFER_ONLY: PASS comparisons="+comparisons+" assertions="+assertions);
