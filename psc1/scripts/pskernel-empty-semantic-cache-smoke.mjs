import {pathToFileURL} from "node:url";
import path from "node:path";

// Additional cold empty-map checks; the retained 1884-control harness is separate.
if(process.argv.length!==3)throw Error("usage: empty-semantic-cache-smoke <generated-leaf>");
const k=await import(pathToFileURL(path.resolve(process.argv[2])).href);
const get=name=>{if(!(name in k))throw Error("PSC1_EMPTY_SEMANTIC_CACHE_MISSING_EXPORT "+name);return k[name];};
const unit=value=>typeof value==="function"?value():value;
const ensure=(condition,label)=>{if(condition!==true)throw Error("PSC1_EMPTY_SEMANTIC_CACHE_FAIL "+label);};
const same=(left,right)=>{
 if(left===right)return true;
 if(left===null||right===null||typeof left!=="object"||typeof right!=="object")return false;
 const a=Reflect.ownKeys(left),b=Reflect.ownKeys(right);
 return a.length===b.length&&a.every(key=>Object.hasOwn(right,key)&&same(left[key],right[key]));
};
// Capture all own string and symbol keys without aliasing the generated inputs.
const snapshot=value=>{
 if(value===null||typeof value!=="object")return value;
 const copy=Array.isArray(value)?[]:{};
 for(const key of Reflect.ownKeys(value))copy[key]=snapshot(value[key]);
 return copy;
};
let assertions=0;
const labels=[];
const must=(condition,label)=>{
 ensure(condition,label);
 ensure(!labels.includes(label),"duplicate assertion label");
 labels.push(label);assertions++;
 console.log("PSC1_EMPTY_SEMANTIC_CACHE_ASSERT "+label);
};
let rejected=false;
try{ensure(false,"deliberate rejection");}
catch(error){rejected=error instanceof Error&&error.message==="PSC1_EMPTY_SEMANTIC_CACHE_FAIL deliberate rejection";}
must(rejected,"harness/rejection");
console.log("PSC1_EMPTY_SEMANTIC_CACHE_SECTION harness=1");
const N=get("PsKernelName"),E=get("PsKernelExpr"),L=get("PsKernelLevel");
const B=get("PsKernelBinderInfo"),Literal=get("PsKernelLiteral"),List=get("List"),Option=get("Option");
const nil=unit(List.nil),none=unit(Option.none);
const list=values=>values.reduceRight((tail,head)=>List.cons(head,tail),nil);
const name=text=>N.str(unit(N.anonymous),text);
const binder=unit(B.default),implicit=unit(B.implicit),strict=unit(B.strictImplicit),instance=unit(B.instImplicit);
const zero=unit(L.zero),one=L.succ(zero),unicode=name("Cache.é€😀");
const bound=E.bvar(0n),open=E.fvar(unicode),sort=E.sort(one);
const constant=E.const(name("Closed"),nil);
const constantLevels=E.const(unicode,list([L.max(one,L.param(name("u"))),L.imax(one,L.mvar(name("v")))]));
const app=E.app(constant,bound);
const lam=E.lam(unicode,sort,bound,implicit);
const forall=E.forallE(name("forall"),sort,bound,strict);
const nat=E.lit(Literal.nat(65521n)),str=E.lit(Literal.str("Aé€😀"));
const nestedOpen=E.mdata(97n,E.proj(unicode,0n,E.lam(name("inner"),sort,open,binder)));
const expressions=[
 bound,
 open,
 E.mvar(N.num(unicode,9007199254740993n)),
 sort,
 constant,
 constantLevels,
 app,
 E.app(open,constant),
 E.app(constant,open),
 lam,
 E.lam(name("openType"),nestedOpen,bound,instance),
 forall,
 E.forallE(name("openBody"),sort,nestedOpen,binder),
 E.letE(unicode,sort,nat,bound,false),
 E.letE(unicode,sort,nat,bound,true),
 E.letE(name("nestedOpen"),sort,nestedOpen,E.app(bound,open),false),
 nat,
 str,
 E.mdata(123456789n,E.app(constant,str)),
 E.proj(unicode,2n,E.mdata(11n,lam))
];
ensure(expressions.length===20,"exact twenty-expression matrix");
const semanticGet=get("psKernelSemanticExprMapGet");
const rawGet=get("psKernelExprMapGet");
const eligible=get("psKernelSemanticCacheEligible");
const empty=unit(get("psKernelExprMapEmpty")),initial=snapshot(empty);
ensure(same(empty.small,nil)&&same(empty.index,none),"actual empty small-map representation");
for(let i=0;i<expressions.length;i++){
 const expr=expressions[i],before=snapshot(expr);
 // This is the frozen predecessor equation on the unchanged public map API.
 const expected=eligible(expr)?rawGet(empty,expr):none;
 const actual=semanticGet(empty,expr);
 must(same(actual,none)&&same(actual,expected)&&same(empty,initial)&&same(expr,before),
      "empty/"+String(i).padStart(2,"0"));
}
console.log("PSC1_EMPTY_SEMANTIC_CACHE_SECTION empty=20");
ensure(assertions===21&&labels.length===21,"exact assertion inventory");
console.log("PSC1_EMPTY_SEMANTIC_CACHE_JS: PASS "+JSON.stringify({
 schema:"psc1-empty-semantic-cache-v1",
 assertions,sectionAssertions:{harness:1,empty:20},coldQueries:20,
 actualGeneratedConstructors:true,inputsUnchanged:true,
 helperOnly:true,fullKernel:false,performanceQualified:false
}));
