import {pathToFileURL} from 'node:url';
import path from 'node:path';
const filename=process.argv[2];
if(!filename)throw Error('Missing complete generated kernel');
const k=await import(pathToFileURL(path.resolve(filename)).href);
const get=n=>{if(!(n in k))throw Error('Missing export '+n);return k[n];};
const unit=x=>typeof x==='function'?x():x;
const List=get('List'),E=get('PsKernelExpr'),N=get('PsKernelName'),L=get('PsKernelLevel');
const nil=unit(List.nil),list=a=>a.reduceRight((tail,head)=>List.cons(head,tail),nil);
const nm=s=>N.str(unit(N.anonymous),s),info=unit(get('PsKernelBinderInfo').default);
const s1=E.sort(L.succ(unit(L.zero))),all=(n,a,b)=>E.forallE(nm(n),a,b,info);
const name=nm('NestedHygieneProbe'),ctorName=N.str(name,'mk');
const capturedName=N.num(get('psKernelSimpleInternalName')('nestedCtorParam'),0n);
const make=bad=>({levelParams:nil,name,type:all('A',s1,s1),
 ctors:list([{name:ctorName,type:all('A',s1,all('x',bad?E.fvar(capturedName):E.bvar(0n),E.app(E.const(name,nil),E.bvar(1n))))}]),
 isUnsafe:false,numParams:1n});
const nested=bad=>({levelParams:nil,numParams:1n,types:list([{name,type:make(bad).type,ctors:make(bad).ctors}]),isUnsafe:false});
const ok=(x,label)=>{if(x&&Object.hasOwn(x,'value'))return x.value;throw Error(label+' '+String(x?.error?.message??x?.error));};
const session=ok(get('psKernelKernelSessionEmpty')(unit(get('psKernelResourcePolicyDefault')),unit(get('psKernelProviderDefault'))),'empty');
const Err=get('PsKernelError'),Decl=get('PsKernelDeclarationRequest');
const same=(a,b)=>{
 if(a===b)return true;
 if(a===null||b===null||typeof a!=='object'||typeof b!=='object')return false;
 const keys=Reflect.ownKeys(a);return keys.length===Reflect.ownKeys(b).length&&keys.every(n=>Object.hasOwn(b,n)&&same(a[n],b[n]));
};
const error=(x,msg)=>x&&Object.hasOwn(x,'error')&&same(x.error,Err.rejectedInvalid(msg));
const labels=[];
const require=(label,condition)=>{if(condition!==true)throw Error('HYGIENE_FAIL '+label);if(labels.includes(label))throw Error('Duplicate label');labels.push(label);console.log('PSC1_NESTED_PARAM_HYGIENE_ASSERT '+label);};
const admit=get('psKernelV1AdmitDeclaration');
const ordinaryGood=admit(session,Decl.ordinaryInductive(make(false)));
const ordinaryBad=admit(session,Decl.ordinaryInductive(make(true)));
const nestedGood=admit(session,Decl.nestedInductive(nested(false)));
const nestedBad=admit(session,Decl.nestedInductive(nested(true)));
require('actual-Lean-and-original-public-closure-parity',
 Object.hasOwn(ordinaryGood,'value')&&Object.hasOwn(nestedGood,'value')&&
 error(ordinaryBad,'declaration has free variables')&&error(nestedBad,'nested preprocessing: declaration has free variables'));
require('exact-rejection-and-no-publication',error(nestedBad,'nested preprocessing: declaration has free variables')&&get('psKernelEnvironmentSize')(session.environment)===0n);
const f=E.fvar(capturedName);
const wrappers=[['leaf',f],['app-fn',E.app(f,s1)],['app-arg',E.app(s1,f)],
 ['lambda-domain',E.lam(nm('x'),f,s1,info)],['lambda-body',E.lam(nm('x'),s1,f,info)],
 ['forall-domain',all('x',f,s1)],['forall-body',all('x',s1,f)],
 ['let-domain',E.letE(nm('x'),f,s1,s1,false)],['let-value',E.letE(nm('x'),s1,f,s1,false)],
 ['let-body',E.letE(nm('x'),s1,s1,f,false)],['metadata',E.mdata(7n,f)],['projection',E.proj(nm('Q'),0n,f)]];
const capture=get('psKernelSimpleNestedCtorParamCapture');
for(const [label,type]of wrappers)require('capture-'+label,capture(type,1n));
const paramNamespace=get('psKernelSimpleInternalName')('nestedCtorParam');
require('exact-namespace-arbitrary-indices-zero-fastpath',
 !capture(E.fvar(N.num(paramNamespace,1n)),1n)&&capture(E.fvar(N.num(paramNamespace,1n)),2n)&&
 !capture(E.fvar(N.num(paramNamespace,1000000000000000000n)),1n)&&!capture(E.fvar(nm('other')),1n)&&!capture(f,0n));
const shape=get('psKernelSimpleNestedOpenConstructorParams')(f,1n);
require('original-shape-error-precedes-capture-guard',shape&&shape.error==='nested preprocessing constructor parameter mismatch');
const initial={arena:unit(get('psKernelExprV2PagedEmpty')),built:unit(get('psKernelExprV2DecodedEmpty')),declarations:nil};
const importedHeader=ok(get('psKernelDagGeneratedImport')(make(true).type,initial),'header');
const importedCtor=ok(get('psKernelDagGeneratedImport')(make(true).ctors.head.type,importedHeader.fst),'ctor');
const D=get('PsKernelDagDeclarationRequest'),C=get('PsKernelDagCommand');
const request=D.nestedInductive({levelParams:nil,numParams:1n,
 types:list([{name,type:importedHeader.snd,ctors:list([{name:ctorName,type:importedCtor.snd}])}]),isUnsafe:false});
const dag=get('psKernelV1RunDag')(session,nil,unit(get('PsKernelDefinitionSafety').safe),importedCtor.fst.arena,list([C.admit(request)]));
require('public-DAG-original-fallback-rejects-atomically',error(dag,'nested preprocessing: declaration has free variables')&&get('psKernelEnvironmentSize')(session.environment)===0n);
if(labels.length!==17)throw Error('Bad hygiene inventory');
console.log('PSC1_NESTED_PARAM_HYGIENE_JS: PASS '+JSON.stringify({assertions:labels.length,labels,
 actualPinnedLeanOracle:'independently executed and authenticated native archive; same fixture and labels',
 validInputsAccepted:true,publicDagRejects:true,fullKernel:false,performanceQualified:false}));
