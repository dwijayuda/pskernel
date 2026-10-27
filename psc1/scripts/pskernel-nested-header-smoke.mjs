import {pathToFileURL} from 'node:url';
import {resolve} from 'node:path';
const k=await import(pathToFileURL(resolve(process.argv[2])).href);
const get=n=>{if(!(n in k))throw Error('missing export '+n);return k[n];};
const unit=x=>typeof x==='function'?x():x;
const same=(a,b)=>a===b||(a!==null&&b!==null&&typeof a==='object'&&typeof b==='object'&&Reflect.ownKeys(a).length===Reflect.ownKeys(b).length&&Reflect.ownKeys(a).every(p=>Object.hasOwn(b,p)&&same(a[p],b[p])));
const L=get('List'),nil=unit(L.nil),list=xs=>xs.reduceRight((tail,head)=>L.cons(head,tail),nil);
const array=xs=>{const out=[];while(Object.hasOwn(xs,'head')){out.push(xs.head);xs=xs.tail;}if(!same(xs,nil))throw Error('malformed List');return out;};
const O=get('Option'),none=unit(O.none),X=get('Except');
const N=get('PsKernelName'),E=get('PsKernelExpr'),V=get('PsKernelLevel'),BI=get('PsKernelBinderInfo');
const nm=s=>N.str(unit(N.anonymous),s),zero=unit(V.zero),s1=E.sort(V.succ(zero)),s2=E.sort(V.succ(V.succ(zero))),bi=unit(BI.default);
const all=(domain,body)=>E.forallE(nm('A'),domain,body,bi);
const type=(name,type,ctors=[])=>({name,type,ctors:list(ctors)});
const mk=(types,numParams=0n,levelParams=[],isUnsafe=false)=>({types:list(types),numParams,levelParams:list(levelParams),isUnsafe});
const group=(t,p=0n)=>mk([type(nm('NestedInitial'),t)],p);
const environment=unit(get('psKernelEnvironmentEmpty')),maxNat=unit(get('psKernelLeanNatMaxSizeDefault'));
const force=x=>{if(Object.hasOwn(x,'error'))throw Error(x.error);if(!Object.hasOwn(x,'value'))throw Error('invalid Except');return x.value;};
const capture=fn=>{try{return {value:fn()};}catch(e){return {error:e.message};}};
const labels=[];
function require(label,value){if(value!==true||labels.includes(label))throw Error('PSC1_NESTED_HEADER_FAIL '+label);labels.push(label);}
function originalPrefix(fuel,decl){
 force(get('psKernelSimpleNestedCheckReserved')(decl));
 force(get('psKernelSimpleCheckUniformOccurrences')(get('psKernelSimpleMutualNames')(decl.types),decl.levelParams,decl.numParams,get('psKernelSimpleMutualCtorTypes')(decl.types)));
 const first=array(decl.types)[0];if(!first)throw Error('empty nested inductive declaration');
 const safety=unit(decl.isUnsafe?get('PsKernelDefinitionSafety').unsafeDef:get('PsKernelDefinitionSafety').safe);
 const session=get('psKernelMkCheckerSession')(environment,decl.levelParams,safety,0n,maxNat);
 const checked=force(get('psKernelSessionCheck')(fuel,session,first.type));
 const sorted=force(get('psKernelSessionEnsureSort')(fuel,checked.snd,checked.fst));
 return force(get('psKernelOpenSimpleHeaderParams')(fuel,sorted.snd,first.type,decl.numParams));
}
function build(decl){
 let owner={arena:unit(get('psKernelExprV2PagedEmpty')),built:unit(get('psKernelExprV2DecodedEmpty')),declarations:nil};
 const put=expr=>{const p=force(get('psKernelDagGeneratedImport')(expr,owner));owner=p.fst;return p.snd;};
 const types=array(decl.types).map(t=>({name:t.name,type:put(t.type),ctors:list(array(t.ctors).map(c=>({name:c.name,type:put(c.type)})))}));
 return {owner,value:{...decl,types:list(types)}};
}
const decode=(arena,id)=>force(get('psKernelExprV2DecodedRequire')(force(get('psKernelExprV2DecodeChecked')(arena)),id));
function sameOpen(old,actual){
 const a=array(old.binders),b=array(actual.binders);
 return a.length===b.length&&old.session.state.nextFresh===actual.state.nextFresh&&
  get('psKernelExprEqual')(old.result)(decode(actual.state.whnf.arena,actual.result))&&a.every((x,i)=>same(x.internalName,b[i].internalName)&&same(x.userName,b[i].userName)&&same(x.binderInfo,b[i].binderInfo)&&get('psKernelExprEqual')(x.type)(decode(actual.state.whnf.arena,b[i].type)));
}
function compare(label,fuel,decl){
 const {owner,value}=build(decl),old=capture(()=>originalPrefix(fuel,decl));
 const attempt=get('psKernelExprV2NestedAnalyzeHeaderWithFuel')(fuel,environment,0n,maxNat,owner.built,owner.arena,nil,value);
 if(same(attempt,none))throw Error('private nested header declined '+label);
 const actual=attempt.value;
 if(Object.hasOwn(old,'error')&&Object.hasOwn(actual,'error')){
  require(label+'-prefix-exact-error',old.error===actual.error);
  const retained=get('psKernelAddSimpleNestedInductive')(fuel,environment,decl,0n,maxNat);
  require(label+'-actual-original-error',Object.hasOwn(retained,'error')&&retained.error===actual.error);
 }else if(Object.hasOwn(old,'value')&&Object.hasOwn(actual,'value'))require(label+'-prefix-owner-parity',sameOpen(old.value,actual.value.parameters));
 else throw Error('nested header mismatch '+label);
}
let rejected=false;try{require('forced-failure',false);}catch{rejected=true;}require('harness-rejection-active',rejected);
compare('plain-sort',256n,group(s1));
compare('parameter',256n,group(all(s1,s1),1n));
compare('dependent-parameters',256n,group(all(s1,all(E.bvar(0n),s1)),2n));
compare('index-not-opened',256n,group(all(s1,E.bvar(0n)),1n));
compare('zero-parameters-do-not-open-indices',256n,group(all(s1,E.bvar(0n))));
compare('metadata',256n,group(E.mdata(7n,s1)));
compare('beta',256n,group(E.app(E.lam(nm('T'),s2,E.bvar(0n),bi),s1)));
compare('let',256n,group(E.letE(nm('T'),s2,s1,E.bvar(0n),false)));
compare('unsafe',256n,{...group(s1),isUnsafe:true});
compare('later-header-not-checked',256n,mk([type(nm('First'),s1),type(nm('Second'),E.mvar(nm('bad')))]));
compare('duplicate-names-not-guarded-here',256n,mk([type(nm('Same'),s1),type(nm('Same'),s1)]));
compare('duplicate-levels-not-guarded-here',256n,{...group(s1),levelParams:list([nm('u'),nm('u')])});
compare('empty',256n,mk([]));compare('mvar',256n,group(E.mvar(nm('m'))));compare('fvar',256n,group(E.fvar(nm('f'))));
compare('too-many-parameters',256n,group(s1,1n));compare('zero-fuel',0n,group(s1));
const prefix=unit(get('psKernelSimpleNestedPrefix'));
compare('reserved-type-name',256n,mk([type(N.str(prefix,'User'),s1)]));
compare('reserved-type-expression-before-mvar',256n,group(E.app(E.const(prefix,nil),E.mvar(nm('m')))));
compare('reserved-ctor-name',256n,mk([type(nm('T'),s1,[{name:N.str(prefix,'mk'),type:s1}])]));
compare('reserved-ctor-expression',256n,mk([type(nm('T'),s1,[{name:nm('mk'),type:E.proj(prefix,0n,s1)}])]));
compare('uniform-before-first-mvar',256n,mk([type(nm('T'),E.mvar(nm('m')),[{name:nm('mk'),type:E.const(nm('T'),nil)}])],1n));
const {owner,value}=build(group(s1));
const call=check=>get('psKernelExprV2NestedAnalyzeHeaderWith')(check,_=>_=>_=>_=>none,256n,environment,0n,maxNat,owner.built,owner.arena,nil,value);
require('injected-decline-remains-decline',same(call(_=>_=>_=>_=>none),none));
require('injected-error-no-fallback',same(call(_=>_=>_=>_=>O.some(X.error('injected'))),O.some(X.error('injected'))));
console.log('PSC1_NESTED_HEADER_JS: PASS '+JSON.stringify({assertions:labels.length,labels,actualOriginalNegativeComparisons:10,privateOnly:true,publicRouteChanged:false,fullKernel:false,performanceQualified:false}));
