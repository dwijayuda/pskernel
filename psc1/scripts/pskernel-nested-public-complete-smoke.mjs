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
function require(label,value){if(value!==true||labels.includes(label))throw Error('PSC1_NESTED_PUBLIC_COMPLETE_FAIL '+label);labels.push(label);}
function build(decl){
 let owner={arena:unit(get('psKernelExprV2PagedEmpty')),built:unit(get('psKernelExprV2DecodedEmpty')),declarations:nil};
 const put=expr=>{const p=force(get('psKernelDagGeneratedImport')(expr,owner));owner=p.fst;return p.snd;};
 const types=array(decl.types).map(t=>({name:t.name,type:put(t.type),ctors:list(array(t.ctors).map(c=>({name:c.name,type:put(c.type)})))}));
 return {owner,value:{...decl,types:list(types)}};
}
const natLimit=unit(get('psKernelLeanNatMaxSizeDefault'));
const attempted=x=>{if(same(x,none))throw Error('private nested phase declined');return force(x.value);};
const refFind=(owner,name)=>get('psKernelExprV2DeclarationRefFind')(owner.declarations)(name);
const decoded=(owner,root)=>force(get('psKernelExprV2DecodedRequire')(owner.built,root));
const envSame=(x,y)=>x.quotInitialized===y.quotInitialized&&same(x.runtime.nativeEvaluator,none)&&same(y.runtime.nativeEvaluator,none)&&same(x.constants,y.constants)&&array(x.constants).every(info=>{
 const name=get('psKernelConstantInfoName')(info);return same(get('psKernelEnvironmentFind')(x,name),get('psKernelEnvironmentFind')(y,name));
});
function prefixSame(before,after){
 for(let id=0n;id<before.arena.size;id++){
  const a=force(get('psKernelExprV2PagedRequire')(before.arena,id)),b=force(get('psKernelExprV2PagedRequire')(after.arena,id));
  if(!same(a,b)||!same(decoded(before,id),decoded(after,id)))return false;
 }
 return true;
}
const live=(env,owner)=>array(owner.declarations).every(ref=>get('psKernelEnvironmentContains')(env,ref.name));
const C=get('PsKernelDagCommand'),D=get('PsKernelDagDeclarationRequest'),Err=get('PsKernelError'),safe=unit(get('PsKernelDefinitionSafety').safe);
const isInvalid=result=>Object.hasOwn(result,'error')&&typeof result.error?.message==='string'&&same(result.error,Err.rejectedInvalid(result.error.message));
function compare(label,session,decl,_expectAux){
 const built=build(decl),input=built.owner.built;
 const owner=force(get('psKernelDagGeneratedFromSession')(session,built.owner.arena,input));
 const checked=attempted(get('psKernelExprV2NestedAdmitWithFuel')(session.resources.fuel,session.environment,session.resources.maxRecDepth,session.resources.maxNatSize,input,owner,built.value));
 const original=force(get('psKernelAddSimpleNestedInductive')(session.resources.fuel,session.environment,decl,session.resources.maxRecDepth,session.resources.maxNatSize));
 const request=D.nestedInductive(built.value),execution={session,declarations:owner.declarations};
 const direct=force(get('psKernelDagRunOwnedCommandWithSource')(input,execution,nil,safe,owner.arena,owner.built,C.admit(request)));
 require(label+'-actual-public-dispatch-exact-complete-original-environment',envSame(original,direct.execution.session.environment));
 require(label+'-direct-route-retains-exact-fully-checked-owner-without-reimport',direct.owner.arena.size===checked.owner.arena.size&&direct.owner.built.size===checked.owner.built.size&&array(direct.owner.declarations).length===array(checked.owner.declarations).length);
 const batch=force(get('psKernelV1RunDag')(session,nil,safe,built.owner.arena,list([C.admit(request)])));
 require(label+'-full-public-boundary-exact-complete-original-environment',envSame(original,batch.session.environment));
 const failed=get('psKernelV1RunDag')(session,nil,safe,built.owner.arena,list([C.admit(request),C.admit(request)]));
 require(label+'-late-batch-error-publishes-no-partial-session',isInvalid(failed)&&!get('psKernelEnvironmentContains')(session.environment,array(decl.types)[0].name));
 const limited={...session,resources:{...session.resources,maxDeclarations:get('psKernelEnvironmentSize')(original)-1n}},refused=get('psKernelV1RunDag')(limited,nil,safe,built.owner.arena,list([C.admit(request)]));
 require(label+'-unchanged-public-declaration-limit-applies-after-complete-validation',Object.hasOwn(refused,'error')&&same(refused.error,Err.resourceExhausted(unit(get('PsKernelResourceError').declarationLimit),'declaration limit exceeded')));
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
const noAuxA=nm('NestedNoAuxA'),noAuxB=nm('NestedNoAuxB');
compare('no-aux-mutual-dispatch',empty,group([type(noAuxA,s1,[{name:N.str(noAuxA,'mk'),type:E.const(noAuxA,nil)}]),type(noAuxB,s1,[{name:N.str(noAuxB,'mk'),type:E.const(noAuxB,nil)}])]),false);
const u=nm('u'),level=V.param(u),sortU=E.sort(V.succ(level)),boxUName=nm('NestedUniverseBox');
const boxU={levelParams:list([u]),name:boxUName,type:all('A',sortU,sortU),ctors:list([{name:N.str(boxUName,'mk'),type:all('A',sortU,all('value',E.bvar(0n),E.app(E.const(boxUName,list([level])),E.bvar(1n))))}]),isUnsafe:false,numParams:1n};
const boxedU=force(get('psKernelV1AdmitDeclaration')(empty,get('PsKernelDeclarationRequest').ordinaryInductive(boxU))).session;
const nestedUName=nm('NestedUniverseOwner'),selfU=E.const(nestedUName,list([level]));
compare('universe-polymorphic-transformed-family',boxedU,{...group([type(nestedUName,sortU,[{name:N.str(nestedUName,'mk'),type:all('child',E.app(E.const(boxUName,list([level])),selfU),selfU)}])]),levelParams:list([u])},true);
if(labels.length!==36)throw Error('incomplete public nested controls '+labels.length);
console.log('PSC1_NESTED_PUBLIC_COMPLETE_JS: PASS '+JSON.stringify({assertions:labels.length,labels,actualOriginalCompleteEnvironments:7,directOwnerNoReimport:true,publicBoundary:true,atomicFailure:true,resourceLimit:true,fullKernel:false,performanceQualified:false}));
