import {pathToFileURL} from 'node:url';
import {resolve} from 'node:path';
const k=await import(pathToFileURL(resolve(process.argv[2])).href);
const get=n=>{if(!(n in k))throw Error('missing export '+n);return k[n];};
const unit=x=>typeof x==='function'?x():x;
const same=(a,b)=>a===b||(a!==null&&b!==null&&typeof a==='object'&&typeof b==='object'&&Reflect.ownKeys(a).length===Reflect.ownKeys(b).length&&Reflect.ownKeys(a).every(p=>Object.hasOwn(b,p)&&same(a[p],b[p])));
const L=get('List'),nil=unit(L.nil),list=xs=>xs.reduceRight((tail,head)=>L.cons(head,tail),nil);
const array=xs=>{const out=[];while(Object.hasOwn(xs,'head')){out.push(xs.head);xs=xs.tail;}if(!same(xs,nil))throw Error('malformed List');return out;};
const O=get('Option'),none=unit(O.none),N=get('PsKernelName'),E=get('PsKernelExpr'),V=get('PsKernelLevel');
const nm=s=>N.str(unit(N.anonymous),s),zero=unit(V.zero),s1=E.sort(V.succ(zero)),bi=unit(get('PsKernelBinderInfo').default);
const all=(n,domain,body)=>E.forallE(nm(n),domain,body,bi);
const type=(name,type,ctors=[])=>({name,type,ctors:list(ctors)});
const group=(types,numParams=0n)=>({levelParams:nil,numParams,types:list(types),isUnsafe:false});
const force=x=>{if(Object.hasOwn(x,'error'))throw Error(x.error?.message??x.error);if(!Object.hasOwn(x,'value'))throw Error('invalid Except');return x.value;};
const labels=[];
function require(label,value){if(value!==true||labels.includes(label))throw Error('PSC1_NESTED_PREPROCESS_FAIL '+label);labels.push(label);}
function originalPrefix(fuel,environment,decl){
 force(get('psKernelSimpleNestedCheckReserved')(decl));
 force(get('psKernelSimpleCheckUniformOccurrences')(get('psKernelSimpleMutualNames')(decl.types),decl.levelParams,decl.numParams,get('psKernelSimpleMutualCtorTypes')(decl.types)));
 const first=array(decl.types)[0];if(!first)throw Error('empty nested inductive declaration');
 const safety=unit(decl.isUnsafe?get('PsKernelDefinitionSafety').unsafeDef:get('PsKernelDefinitionSafety').safe);
 const session=get('psKernelMkCheckerSession')(environment,decl.levelParams,safety,0n,unit(get('psKernelLeanNatMaxSizeDefault')));
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
function compare(label,session,decl,expectAux){
 const built=build(decl),input=built.owner.built;
 const owner=force(get('psKernelDagGeneratedFromSession')(session,built.owner.arena,input));
 const parameters=originalPrefix(256n,session.environment,decl);
 const original=force(get('psKernelSimpleNestedProcessQueue')(256n,session.environment,decl.levelParams,get('psKernelSimpleMutualNames')(decl.types),parameters.binders,decl.numParams,decl.types,nil,{aux:nil,fresh:1n,created:nil}));
 const attempt=get('psKernelExprV2NestedPreprocessWithFuel')(256n,session.environment,0n,unit(get('psKernelLeanNatMaxSizeDefault')),input,owner,built.value);
 if(same(attempt,none))throw Error('private preprocessing declined '+label);
 const actual=force(attempt.value);
 require(label+'-whole-plan-parity',same(original,actual.processed));
 require(label+'-exact-auxiliary-presence',(array(actual.processed.state.aux).length===0)===!expectAux);
 require(label+'-synchronized-append-only-owner',owner.arena.size<=actual.owner.arena.size&&actual.owner.built.size===actual.owner.arena.size);
 for(let id=0n;id<input.size;id++){
  const before=force(get('psKernelExprV2DecodedRequire')(input,id)),after=force(get('psKernelExprV2DecodedRequire')(actual.owner.built,id));
  if(!same(before,after))throw Error('original input prefix changed '+label);
 }
 require(label+'-all-original-input-roots-retained',true);
 const count=get('psKernelEnvironmentSize')(session.environment);
 force(get('psKernelV1AdmitDeclaration')(session,get('PsKernelDeclarationRequest').nestedInductive(decl)));
 require(label+'-actual-original-complete-admission-accepts',get('psKernelEnvironmentSize')(session.environment)===count);
}
let rejected=false;try{require('forced-failure',false);}catch{rejected=true;}require('harness-rejection-active',rejected);
const empty=force(get('psKernelKernelSessionEmpty')(unit(get('psKernelResourcePolicyDefault')),unit(get('psKernelProviderDefault'))));
const enumName=nm('NestedPlanEnum');compare('no-aux-enum',empty,group([type(enumName,s1,[{name:N.str(enumName,'mk'),type:E.const(enumName,nil)}])]),false);
const boxName=nm('NestedPlanBox'),box={levelParams:nil,name:boxName,type:all('A',s1,s1),ctors:list([{name:N.str(boxName,'mk'),type:all('A',s1,all('value',E.bvar(0n),E.app(E.const(boxName,nil),E.bvar(1n))))}]),isUnsafe:false,numParams:1n};
const boxed=force(get('psKernelV1AdmitDeclaration')(empty,get('PsKernelDeclarationRequest').ordinaryInductive(box))).session;
const name=nm('NestedPlanOwner'),self=E.const(name,nil),nested=E.app(E.const(boxName,nil),self);
const single=group([type(name,s1,[{name:N.str(name,'mk'),type:all('child',nested,self)}])]);
compare('genuine-nested-box',boxed,single,true);
compare('repeated-template-reuses-family',boxed,group([type(name,s1,[{name:N.str(name,'left'),type:all('child',nested,self)},{name:N.str(name,'right'),type:all('child',nested,self)}])]),true);
const deep=E.app(E.const(boxName,nil),nested);compare('nested-discovery-queue',boxed,group([type(name,s1,[{name:N.str(name,'mk'),type:all('child',deep,self)}])]),true);
const paramName=nm('NestedPlanParameterized'),applied=E.app(E.const(paramName,nil),E.bvar(0n)),paramNested=E.app(E.const(boxName,nil),applied);
const parameterized=group([type(paramName,all('A',s1,s1),[{name:N.str(paramName,'mk'),type:all('A',s1,all('child',paramNested,E.app(E.const(paramName,nil),E.bvar(1n))))}])],1n);
compare('shared-parameter-rebasing',boxed,parameterized,true);
console.log('PSC1_NESTED_PREPROCESS_JS: PASS '+JSON.stringify({assertions:labels.length,labels,actualOriginalCompleteNestedAcceptedPlanFixtures:5,privateOnly:true,publicRouteChanged:false,fullKernel:false,performanceQualified:false}));
