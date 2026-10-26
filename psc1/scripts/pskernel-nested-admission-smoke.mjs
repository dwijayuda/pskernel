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
function require(label,value){if(value!==true||labels.includes(label))throw Error('PSC1_NESTED_ADMISSION_FAIL '+label);labels.push(label);}
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
function compare(label,session,decl,expectAux){
 const built=build(decl),input=built.owner.built;
 const owner=force(get('psKernelDagGeneratedFromSession')(session,built.owner.arena,input));
 const checked=attempted(get('psKernelExprV2NestedTransformedWithFuel')(256n,session.environment,0n,natLimit,input,owner,built.value));
 const restored=force(get('psKernelExprV2NestedRestore')(session.environment,owner,checked));
 const original=force(get('psKernelAddSimpleNestedInductive')(256n,session.environment,decl,0n,natLimit));
 require(label+'-whole-restored-environment-exact-actual-original',envSame(original,restored.environment));
 require(label+'-exact-original-auxiliary-presence',(array(checked.preprocessed.processed.state.aux).length===0)===!expectAux);
 require(label+'-owner-synchronized',restored.owner.arena.size===restored.owner.built.size);
 require(label+'-every-transformed-id-metadata-and-decoded-value-retained',prefixSame(checked.admitted.owner,restored.owner));
 let types=true,rules=true,kinds=true;
 for(const info of array(restored.environment.constants)){
  const name=get('psKernelConstantInfoName')(info);if(get('psKernelEnvironmentContains')(session.environment,name))continue;
  const found=refFind(restored.owner,name);if(same(found,none))throw Error('restored owner missing');const ref=found.value;
  types=types&&same(decoded(restored.owner,ref.type),get('psKernelConstantInfoType')(info))&&same(ref.levelParams,get('psKernelConstantInfoLevelParams')(info))&&same(ref.deltaValue,none);
  kinds=kinds&&get('psKernelExprV2DeclarationRefKindMatches')(ref.kind,info);
  if(info.value&&Object.hasOwn(info.value,'rules')){
   if(!Object.hasOwn(ref.kind,'rules'))rules=false;
   else{
    const xs=array(info.value.rules),ys=array(ref.kind.rules);
    rules=rules&&xs.length===ys.length&&xs.every((r,i)=>same(r.ctor,ys[i].ctor)&&r.nFields===ys[i].nFields&&same(r.rhs,decoded(restored.owner,ys[i].rhs)));
   }
  }
 }
 require(label+'-all-restored-type-ids-level-params-and-delta-exact',types);
 require(label+'-all-restored-recursor-rules-exact',rules);
 require(label+'-all-restored-reference-kinds-exact',kinds);
 require(label+'-no-provisional-auxiliary-declaration-reference-leaks',live(restored.environment,restored.owner));
 require(label+'-base-environment-unchanged',array(session.environment.constants).every(info=>{
  const found=get('psKernelEnvironmentFind')(restored.environment,get('psKernelConstantInfoName')(info));return !same(found,none)&&same(found.value,info);
 }));
 require(label+'-no-aux-path-preserves-exact-admitted-owner',expectAux||(restored.owner.arena.size===checked.admitted.owner.arena.size&&restored.owner.built.size===checked.admitted.owner.built.size&&array(restored.owner.declarations).length===array(checked.admitted.owner.declarations).length));
 if(expectAux)force(get('psKernelSimpleNestedValidateRestored')(256n,checked.admitted.environment,restored.environment,decl,checked.preprocessed.canonicalParams,checked.preprocessed.processed.state.aux,restored.renames,0n,natLimit));
 require(label+'-actual-original-postvalidation-accepts',true);
 const finalOwner=attempted(get('psKernelExprV2NestedValidateRestoredWithFuel')(256n,0n,natLimit,restored));
 require(label+'-independent-owning-postvalidation-accepts',true);
 require(label+'-validated-owner-synchronized',finalOwner.arena.size===finalOwner.built.size);
 require(label+'-postvalidation-retains-all-restored-ids-and-metadata',prefixSame(restored.owner,finalOwner));
 require(label+'-postvalidation-no-provisional-namespace-leak',live(restored.environment,finalOwner));
 let actualNegative=true,owningNegative=true;
 if(expectAux){
  const name=get('psKernelSimpleRecName')(array(decl.types)[0].name),found=get('psKernelEnvironmentFind')(restored.environment,name);
  if(same(found,none)||!Object.hasOwn(found.value.value,'rules'))throw Error('missing original recursor');
  const recursor=found.value.value,badRecursor={...recursor,rules:list(array(recursor.rules).map(rule=>({...rule,rhs:E.const(nm('DefinitelyMissingNestedRuleConstant'),nil)})))};
  const info=get('PsKernelConstantInfo').recInfo(badRecursor),badEnvironment=get('psKernelEnvironmentReplaceUnchecked')(restored.environment,info);
  const badOwner=force(get('psKernelExprV2NestedRestoreReference')(info,refFind(restored.owner,name),restored.owner));
  actualNegative=Object.hasOwn(get('psKernelSimpleNestedValidateRestored')(256n,checked.admitted.environment,badEnvironment,decl,checked.preprocessed.canonicalParams,checked.preprocessed.processed.state.aux,restored.renames,0n,natLimit),'error');
  const rejected=get('psKernelExprV2NestedValidateRestoredWithFuel')(256n,0n,natLimit,{...restored,environment:badEnvironment,owner:badOwner});
  owningNegative=!same(rejected,none)&&Object.hasOwn(rejected.value,'error');
 }
 require(label+'-actual-original-rejects-corrupted-restored-rule',actualNegative);
 require(label+'-owning-postvalidation-rejects-corrupted-restored-rule',owningNegative);
 const complete=attempted(get('psKernelExprV2NestedAdmitWithFuel')(256n,session.environment,0n,natLimit,input,owner,built.value));
 require(label+'-complete-private-admission-exact-actual-original-environment',envSame(original,complete.environment));
 require(label+'-complete-private-owner-synchronized-and-input-retained',complete.owner.built.size===complete.owner.arena.size&&owner.arena.size<=complete.owner.arena.size);
 require(label+'-complete-private-namespace-has-no-auxiliary-leak',live(complete.environment,complete.owner));
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
if(labels.length!==141)throw Error('incomplete nested transaction controls '+labels.length);
console.log('PSC1_NESTED_ADMISSION_JS: PASS '+JSON.stringify({assertions:labels.length,labels,actualOriginalCompleteEnvironments:7,actualOriginalValidationComparisons:7,corruptedRuleRejections:5,completePrivateTransaction:true,ownerPrefixesIntact:true,privateOnly:true,publicRouteChanged:false,restorationValidated:true,fullKernel:false,performanceQualified:false}));
