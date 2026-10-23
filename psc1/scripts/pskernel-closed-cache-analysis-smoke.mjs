import {pathToFileURL} from "node:url";
import path from "node:path";

// Differential checks use the actual generated constructors and the unchanged
// public cache operations. They do not manufacture JavaScript kernel records.
if(process.argv.length!==3)throw Error("usage: closed-cache-analysis-smoke <generated-kernel>");
const k=await import(pathToFileURL(path.resolve(process.argv[2])).href);
const get=name=>{if(!(name in k))throw Error("PSC1_CLOSED_CACHE_MISSING_EXPORT "+name);return k[name];};
const unit=value=>typeof value==="function"?value():value;
const ensure=(condition,label)=>{if(condition!==true)throw Error("PSC1_CLOSED_CACHE_ANALYSIS_FAIL "+label);};
let assertions=0;
const must=(condition,label)=>{ensure(condition,label);assertions++;};
const same=(left,right)=>{
 if(left===right)return true;
 if(left===null||right===null||typeof left!=="object"||typeof right!=="object")return false;
 const a=Reflect.ownKeys(left),b=Reflect.ownKeys(right);
 return a.length===b.length&&a.every(key=>Object.hasOwn(right,key)&&same(left[key],right[key]));
};
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
const analyze=get("psKernelExprClosedCacheAnalysis"),hasFVar=get("psKernelExprHasFVar"),hash=get("psKernelExprHash");
const eligible=get("psKernelSemanticCacheEligible"),pairEligible=get("psKernelSemanticPairCacheEligible");
const inferEligible=get("psKernelInferCacheEligible");
const mapGet=get("psKernelExprMapGet"),mapInsert=get("psKernelExprMapInsert");
const pairContains=get("psKernelExprPairSetContains"),pairInsert=get("psKernelExprPairSetInsert");
const semanticGet=get("psKernelSemanticExprMapGet"),semanticInsert=get("psKernelSemanticExprMapInsert");
const semanticContains=get("psKernelSemanticExprPairSetContains"),semanticPairInsert=get("psKernelSemanticExprPairSetInsert");
const inferGet=get("psKernelInferCacheMapGet"),inferInsert=get("psKernelInferCacheMapInsert");
// Generic Option.none constructs a fresh object. Compare its actual private
// constructor Symbol and exact fields; distinct allocations are not identical.
const optionSame=(actual,expected)=>same(actual,expected);

for(let i=0;i<expressions.length;i++){
 const expr=expressions[i],result=analyze(expr),isOpen=hasFVar(expr);
 must(result.snd===isOpen,"analysis flag "+i);
 must(result.fst===(isOpen?0n:hash(expr)),"analysis exact closed hash "+i);
}

// Small states sit at the real threshold, so inserting a fresh closed key also
// tests the unchanged small-list promotion path. Colliding bvars stay distinct.
const smallLimit=unit(get("psKernelCacheSmallLimit")),modulus=unit(get("psKernelCacheHashModulus"));
ensure(typeof smallLimit==="bigint"&&smallLimit===8n,"published small-cache limit");
ensure(typeof modulus==="bigint"&&modulus===65521n,"published hash modulus");
const collision1=E.bvar(modulus),collision2=E.bvar(2n*modulus),value=E.sort(L.succ(one));
ensure(hash(bound)===hash(collision1)&&hash(bound)===hash(collision2),"real expression hash collisions");
const mapKeys=[open,bound,constant,constantLevels,nat,str,collision1,collision2];
let smallMap=unit(get("psKernelExprMapEmpty"));
for(const key of mapKeys)smallMap=mapInsert(smallMap,key,value);
const setKeys=[[open,bound],[bound,bound],[constant,constantLevels],[constant,bound],
 [app,lam],[nat,str],[collision1,bound],[collision2,bound]];
let smallSet=unit(get("psKernelExprPairSetEmpty"));
for(const[left,right]of setKeys)smallSet=pairInsert(smallSet,left,right);
ensure(BigInt(mapKeys.length)===smallLimit&&BigInt(setKeys.length)===smallLimit,"small threshold fixtures");
let indexedMap=smallMap,indexedSet=smallSet;
for(let i=0n;i<smallLimit+2n;i++){
 const key=E.bvar(1000n+i);
 indexedMap=mapInsert(indexedMap,key,value);
 indexedSet=pairInsert(indexedSet,key,bound);
}
must(same(smallMap.index,none),"small map representation");
must(same(indexedMap.index,Option.some(indexedMap.index.value)),"indexed map representation");
must(same(smallSet.index,none),"small pair-set representation");
must(same(indexedSet.index,Option.some(indexedSet.index.value)),"indexed pair-set representation");
for(const map of[smallMap,indexedMap])
 ensure(optionSame(mapGet(map,open),Option.some(value)),"raw ineligible map entry exists");
for(const set of[smallSet,indexedSet])
 ensure(pairContains(set,open,bound)===true&&pairContains(set,bound,open)===true,"raw ineligible symmetric pair exists");

let mapQueries=0,inferQueries=0,pairQueries=0;
const states=[{map:smallMap,set:smallSet},{map:indexedMap,set:indexedSet}];
for(let stateIndex=0;stateIndex<states.length;stateIndex++){
 const {map,set}=states[stateIndex];
 for(let i=0;i<expressions.length;i++){
  const expr=expressions[i],label=stateIndex+"/"+i;
  const allowed=eligible(expr);
  must(optionSame(semanticGet(map,expr),allowed?mapGet(map,expr):none),"semantic map get "+label);
  must(optionSame(semanticInsert(map,expr,value),allowed?Option.some(mapInsert(map,expr,value)):none),"semantic map insert "+label);
  mapQueries++;
  for(const inferOnly of[false,true]){
   const canInfer=inferEligible(inferOnly,expr);
   must(optionSame(inferGet(map,inferOnly,expr),canInfer?mapGet(map,expr):none),"inference map get "+label+"/"+inferOnly);
   must(optionSame(inferInsert(map,inferOnly,expr,value),canInfer?Option.some(mapInsert(map,expr,value)):none),"inference map insert "+label+"/"+inferOnly);
   inferQueries++;
  }
  for(let j=0;j<expressions.length;j++){
   const right=expressions[j],canPair=pairEligible(expr,right),pairLabel=label+"/"+j;
   must(semanticContains(set,expr,right)===(canPair?pairContains(set,expr,right):false),"semantic pair contains "+pairLabel);
   const expectedSet=canPair?pairInsert(set,expr,right):null;
   const inserted=semanticPairInsert(set,expr,right);
   must(optionSame(inserted,canPair?Option.some(expectedSet):none)&&
    (!canPair||expectedSet!==set||inserted.value===set),"semantic pair insert and retained identity "+pairLabel);
   pairQueries++;
  }
 }
}
ensure(mapQueries===40&&pairQueries===800&&inferQueries===80&&assertions===1884,"exact coverage totals");
console.log("PSC1_CLOSED_CACHE_ANALYSIS_JS: PASS "+JSON.stringify({
 expressions:20,states:2,mapQueries,pairQueries,inferQueries,assertions,
 smallAndIndexed:true,openEntriesSeeded:true
}));

