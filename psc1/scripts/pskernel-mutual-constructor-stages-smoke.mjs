import {readFileSync} from 'node:fs';
import {pathToFileURL} from 'node:url';
import {resolve} from 'node:path';
import {createHash} from 'node:crypto';

const filename=process.argv[2];
if(process.argv.length!==3)throw Error('usage: mutual-header-smoke kernel.mjs');
const bytes=readFileSync(filename),k=await import(pathToFileURL(resolve(filename)).href);
const get=name=>{if(!(name in k))throw Error('missing export '+name);return k[name];};
const unit=value=>typeof value==='function'?value():value;
const same=(a,b)=>a===b||(a!==null&&b!==null&&typeof a==='object'&&typeof b==='object'&&
 Reflect.ownKeys(a).length===Reflect.ownKeys(b).length&&
 Reflect.ownKeys(a).every(key=>Object.hasOwn(b,key)&&same(a[key],b[key])));
const List=get('List'),nil=unit(List.nil),list=xs=>xs.reduceRight((tail,head)=>List.cons(head,tail),nil);
const array=xs=>{const out=[];while(Object.hasOwn(xs,'head')){out.push(xs.head);xs=xs.tail;}
 if(!same(xs,nil))throw Error('invalid List');return out;};
const none=unit(get('Option').none),ok=get('Except').ok,prod=(fst,snd)=>({fst,snd});
const force=value=>{if(Object.hasOwn(value,'error'))throw Error(value.error);
 if(!Object.hasOwn(value,'value'))throw Error('invalid Except');return value.value;};
const direct=value=>{if(same(value,none))throw Error('direct header declined');return force(value.value);};
const capture=fn=>{try{return {value:fn()};}catch(error){return {error:error.message};}};
const N=get('PsKernelName'),L=get('PsKernelLevel'),E=get('PsKernelExpr');
const nm=s=>N.str(unit(N.anonymous),s),zero=unit(L.zero),one=L.succ(zero);
const s1=E.sort(one),s2=E.sort(L.succ(one)),bi=unit(get('PsKernelBinderInfo').default);
const all=(s,domain,body)=>E.forallE(nm(s),domain,body,bi);
const a=nm('T06MutualA'),b=nm('T06MutualB'),c=nm('T06MutualC'),u=nm('u'),v=nm('v');
const type=(name,type,ctors=[])=>({name,type,ctors:list(ctors)});
const group=(ta,tb,numParams=0n,levelParams=[])=>({levelParams:list(levelParams),numParams,
 types:list([type(a,ta),type(b,tb)]),isUnsafe:false});
const environment=get('psKernelEnvironmentEmpty'),depth=0n,maxNat=get('psKernelLeanNatMaxSizeDefault');
const safety=value=>unit(value.isUnsafe?get('PsKernelDefinitionSafety').unsafeDef:get('PsKernelDefinitionSafety').safe);

// Literal V1 transaction prefix: group guards, first header, then fresh closed
// checking for each remaining type before resuming the shared first parameters.
function frozen(fuel,value){
 const types=array(value.types),names=types.map(t=>t.name);
 if(get('psKernelNameHasDuplicates')(value.levelParams))throw Error('duplicate universe parameter');
 if(types.length<2)throw Error('mutual inductive admission requires at least two datatypes');
 const allNames=list([...names,...names.map(get('psKernelSimpleRecName')),...types.flatMap(t=>array(t.ctors).map(x=>x.name))]);
 if(!get('psKernelSimpleNameListUnique')(allNames))throw Error('duplicate inductive, constructor, or recursor name');
 force(get('psKernelCheckFreshInductiveNames')(allNames)(environment));
 force(get('psKernelSimpleCheckUniformOccurrences')(list(names),value.levelParams,value.numParams,
  list(types.flatMap(t=>array(t.ctors).map(x=>x.type)))));
 const closed=type=>{
  force(get('psKernelCheckNoMVarNoFVar')(type));force(get('psKernelCheckLevelParams')(type,value.levelParams));
  const initial=get('psKernelMkCheckerSession')(environment,value.levelParams,safety(value),depth,maxNat);
  const checked=force(get('psKernelSessionCheck')(fuel,initial,type));
  return force(get('psKernelSessionEnsureSort')(fuel,checked.snd,checked.fst)).snd;
 };
 const first=types[0],sorted=closed(first.type);
 const parameters=force(get('psKernelOpenSimpleHeaderParams')(fuel,sorted,first.type,value.numParams));
 const firstIndices=force(get('psKernelOpenSimpleHeaderIndices')(fuel,parameters.session,parameters.result));
 if(!Object.hasOwn(firstIndices.result,'level')||!same(firstIndices.result,E.sort(firstIndices.result.level)))
  throw Error('simple inductive result must be a sort');
 const resultLevel=firstIndices.result.level,headers=[{declaration:first,indices:firstIndices}];
 for(const declaration of types.slice(1)){
  closed(declaration.type);
  const aligned=force(get('psKernelOpenSimpleConstructorParams')(fuel,parameters.session,parameters.binders,declaration.type));
  const indices=force(get('psKernelOpenSimpleHeaderIndices')(fuel,aligned.session,aligned.result));
  if(!Object.hasOwn(indices.result,'level')||!same(indices.result,E.sort(indices.result.level)))
   throw Error('mutual inductive result must be a sort');
  if(!get('psKernelLevelEquivalent')(indices.result.level,resultLevel))
   throw Error('mutually inductive types must live in the same universe');
  headers.push({declaration,indices});
 }
 return {parameters,types:headers,resultLevel};
}
function build(value){
 let source={arena:get('psKernelExprV2PagedEmpty'),built:get('psKernelExprV2DecodedEmpty'),declarations:nil};
 const input=term=>{const next=force(get('psKernelDagGeneratedImport')(term,source));source=next.fst;return next.snd;};
 const types=array(value.types).map(t=>({name:t.name,type:input(t.type),
  ctors:list(array(t.ctors).map(c=>({name:c.name,type:input(c.type)})))}));
 return {arena:source.arena,value:{...value,types:list(types)}};
}
const decode=(arena,root)=>force(get('psKernelExprV2DecodedRequire')(
 force(get('psKernelExprV2DecodeChecked')(arena)),root));
const eq=(left,right)=>get('psKernelExprEqual')(left)(right);
function sameOpen(old,actual){
 const left=array(old.binders),right=array(actual.binders);
 return left.length===right.length&&old.session.state.nextFresh===actual.state.nextFresh&&
  eq(old.result,decode(actual.state.whnf.arena,actual.result))&&left.every((x,i)=>{
   const y=right[i];return same(x.internalName,y.internalName)&&same(x.userName,y.userName)&&
    same(x.binderInfo,y.binderInfo)&&eq(x.type,decode(actual.state.whnf.arena,y.type));
  });
}
const labels=[];
function require(label,condition){if(condition!==true)throw Error('PSC1_MUTUAL_HEADER_FAIL '+label);labels.push(label);}
function compare(label,fuel,value){
 const built=build(value),old=capture(()=>frozen(fuel,value));
 const actual=capture(()=>direct(get('psKernelExprV2MutualAnalyzeHeaderWithFuel')(
  fuel,environment,depth,maxNat,built.arena,nil,built.value)));
 if(Object.hasOwn(old,'error'))require(label+'-exact-error',old.error===actual.error);
 else{
  if(Object.hasOwn(actual,'error'))throw Error(label+': '+actual.error);
  const left=old.value,right=actual.value,types=array(right.types);
  require(label+'-complete-private-owner-parity',sameOpen(left.parameters,right.parameters)&&
   same(left.resultLevel,right.resultLevel)&&left.types.length===types.length&&
   left.types.every((t,i)=>same(t.declaration.name,types[i].declaration.name)&&
    sameOpen(t.indices,types[i].indices)&&eq(t.indices.result,decode(right.arena,types[i].indices.result))));
 }
}
const positives=[
 ['two-enums',group(s1,s1)],
 ['shared-parameter',group(all('A',s1,s1),all('B',s1,s1),1n)],
 ['dependent-parameter',group(all('A',s1,all('a',E.bvar(0n),s1)),all('B',s1,all('b',E.bvar(0n),s1)),2n)],
 ['different-indices',group(all('A',s1,all('x',E.bvar(0n),s1)),all('B',s1,all('y',s1,s1)),1n)],
 ['universe-parameters',group(all('A',E.sort(L.param(u)),E.sort(L.param(v))),all('B',E.sort(L.param(u)),E.sort(L.param(v))),1n,[u,v])],
 ['later-index-freshness-isolation',{levelParams:nil,numParams:0n,types:list([type(a,all('X',s1,s1)),type(b,all('Y',s1,all('y',E.bvar(0n),s1))),type(c,all('Z',s1,s1))]),isUnsafe:false}],
 ['beta-first',group(E.app(E.lam(nm('T'),s2,E.bvar(0n),bi),s1),s1)],
 ['let-later',group(s1,E.letE(nm('T'),s2,s1,E.bvar(0n),false))],
 ['metadata-index',group(E.mdata(3n,s1),E.mdata(4n,s1))],
 ['unsafe-context',{...group(s1,s1),isUnsafe:true}],
 ['cross-family-uniform-occurrence',{levelParams:nil,numParams:1n,types:list([
  type(a,all('A',s1,s1),[{name:nm('mkA'),type:all('A',s1,E.app(E.const(b,nil),E.bvar(0n)))}]),
  type(b,all('B',s1,s1))]),isUnsafe:false}]
];
const raw=(types,params=0n,levels=[])=>({levelParams:list(levels),numParams:params,types:list(types),isUnsafe:false});
const negatives=[
 ['duplicate-level-before-count',raw([],0n,[u,u])],
 ['minimum-count-before-mvar',raw([type(a,E.mvar(a))])],
 ['type-name-duplicate-before-mvar',raw([type(a,E.mvar(a)),type(a,s1)])],
 ['recursor-name-collision',raw([type(a,s1),type(get('psKernelSimpleRecName')(a),s1)])],
 ['constructor-name-collision',raw([type(a,s1,[{name:b,type:E.mvar(a)}]),type(b,s1)])],
 ['uniform-before-first-static',raw([type(a,E.mvar(a),[{name:nm('bad'),type:E.const(b,nil)}]),type(b,s1)],1n)],
 ['first-mvar',group(E.mvar(a),s1)],['later-mvar',group(s1,E.mvar(b))],
 ['later-fvar-before-level',group(s1,E.app(E.fvar(a),E.sort(L.param(u))))],
 ['later-undeclared-level',group(s1,E.sort(L.param(u)))],
 ['later-illtyped',group(s1,E.app(s1,s1))],['later-result-universe-mismatch',group(s1,s2)],
 ['later-parameter-type-mismatch',group(all('A',s1,s1),all('B',s2,s1),1n)],
 ['later-too-few-parameters',group(all('A',s1,s1),s1,1n)],
 ['later-not-sort-result',group(s1,all('A',s1,E.bvar(0n)))],
 ['first-not-sort-result',group(all('A',s1,E.bvar(0n)),s1)]
];
for(const [label,value]of positives)compare(label,256n,value);
for(const [label,value]of negatives)compare(label,256n,value);
for(const fuel of[0n,1n,2n,4n,16n])compare('fuel-'+fuel,fuel,group(all('A',s1,s1),all('B',s1,s1),1n));
const built=build(group(s1,s1)),root=array(built.value.types)[0].type;
const context=get('psKernelExprV2MutualClosedContext')(environment,built.value,0n,0n);
const shared={...get('psKernelExprV2CheckStateEmpty')(built.arena),nextFresh:17n};
const parameters={context,state:shared,binders:nil,result:root};
const check=_fuel=>_context=>state=>_root=>get('Option').some(ok(prod({...state,nextFresh:999n},root)));
const whnf=_fuel=>_context=>state=>root=>get('Option').some(ok(prod(state,root)));
const defeq=_fuel=>_context=>_state=>_left=>_right=>none;
const indices=direct(get('psKernelExprV2MutualRemainingPhasesWith')(check,whnf,defeq,16n,context,
 get('psKernelExprV2MutualClosedState')(built.arena,nil),parameters,root,one));
require('injected-closed-freshness-discarded',indices.state.nextFresh===17n&&same(indices.context.locals,nil));
if(labels.length!==33||new Set(labels).size!==33)throw Error('matrix incomplete');
console.log('PSC1_MUTUAL_HEADER_JS: PASS '+JSON.stringify({assertions:33,positive:11,negative:16,budgets:5,
 injected:1,labels,completeV1PrefixComparison:true,owningIDs:true,privateHeaderOnly:true,fullAdmission:false,
 fullKernel:false,performanceQualified:false,kernel:{bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex')}}));

// Cross-family recognition uses actual checked shared headers with 0/1/2 indices.
const familyValue={levelParams:nil,numParams:1n,isUnsafe:false,types:list([
 type(a,all('P',s1,s1)),type(b,all('P',s1,all('i',s1,s1))),
 type(c,all('P',s1,all('i',s1,all('j',s1,s1))))])};
const familyBuilt=build(familyValue),familyOld=frozen(256n,familyValue);
const familyActual=direct(get('psKernelExprV2MutualAnalyzeHeaderWithFuel')(
 256n,environment,depth,maxNat,familyBuilt.arena,nil,familyBuilt.value));
const familyLabels=[];
const familyRequire=(label,condition)=>{if(condition!==true)throw Error('PSC1_MUTUAL_RESULT_FAIL '+label);familyLabels.push(label);};
familyRequire('checked-shared-header-parameter-names',same(
 array(familyOld.parameters.binders).map(p=>p.internalName),
 array(familyActual.parameters.binders).map(p=>p.internalName)));
let familySource={arena:familyActual.arena,built:force(get('psKernelExprV2DecodeChecked')(familyActual.arena)),declarations:nil};
const familyInput=term=>{const next=force(get('psKernelDagGeneratedImport')(term,familySource));familySource=next.fst;return next.snd;};
const ca=E.const(a,nil),cb=E.const(b,nil),cc=E.const(c,nil),co=E.const(nm('Other'),nil),free=E.fvar(nm('free'));
const Lit=get('PsKernelLiteral');
const familyTerms=[ca,cb,cc,co,s1,free,E.app(co,ca),E.lam(nm('x'),ca,free,bi),
 E.forallE(nm('x'),free,cb,unit(get('PsKernelBinderInfo').implicit)),
 E.letE(nm('x'),free,ca,cb,false),E.mdata(5n,ca),E.proj(a,0n,s1),E.proj(nm('Other'),0n,cb),
 E.bvar(0n),E.mvar(a),E.lit(Lit.nat(3n)),E.lit(Lit.str('Aé€😀')),
 E.app(E.lam(nm('x'),co,E.mdata(3n,cc),bi),cb)];
const targetSets=[[],[a],[b,c],[a,b,c],[a,a]];
familyTerms.forEach((term,i)=>{
 const root=familyInput(term);
 targetSets.forEach((names,j)=>familyRequire('all-family-occurrence-'+i+'-'+j,
  force(get('psKernelExprV2MutualContainsConstOnCanonical')(familySource.arena,list(names),root))===
   get('psKernelSimpleMutualContainsConst')(list(names),term)));
});
familyRequire('zero-structural-budget-precedes-lookup',same(
 get('psKernelExprV2MutualContainsConstWithFuel')(0n)(familySource.arena)(list([a,b,c]))(familySource.arena.size+1n),
 get('Except').error('PSKERNEL_V2_MUTUAL_CONTAINS_CONST_FUEL')));
familyRequire('missing-occurrence-root-is-error',Object.hasOwn(
 get('psKernelExprV2MutualContainsConstOnCanonical')(familySource.arena,list([a,b,c]),familySource.arena.size),'error'));
const parameter=E.fvar(array(familyOld.parameters.binders)[0].internalName),wrong=E.fvar(nm('wrong'));
const apps=(head,args)=>args.reduce((fn,arg)=>E.app(fn,arg),head);
const applicationTerms=[apps(ca,[parameter]),apps(cb,[parameter,s1]),apps(cc,[parameter,s1,s2]),
 apps(cb,[parameter,wrong]),apps(co,[parameter]),ca,apps(cb,[parameter]),apps(ca,[parameter,s1]),
 apps(E.const(a,list([zero])),[parameter]),apps(ca,[wrong]),apps(ca,[E.mdata(0n,parameter)]),
 apps(E.mdata(0n,ca),[parameter]),apps(cb,[parameter,ca]),apps(cb,[parameter,E.proj(a,0n,s1)]),
 apps(cb,[parameter,E.app(co,cc)]),apps(cb,[parameter,E.letE(nm('x'),s1,cb,s1,false)]),
 apps(wrong,[parameter]),apps(cc,[parameter,s1]),apps(cc,[parameter,s1,s2,s1]),
 apps(cb,[parameter,E.mdata(0n,E.proj(nm('Other'),0n,cc))])];
const oldShapes=list(familyOld.types.map(t=>({decl:t.declaration,indices:t.indices.binders})));
applicationTerms.forEach((term,i)=>{
 const root=familyInput(term);
 const old=get('psKernelSimpleMutualAppInfo')(list([a,b,c]),oldShapes,nil,familyOld.parameters.binders,term);
 const actual=force(get('psKernelExprV2MutualAppInfoOnCanonical')(familySource.arena,list([a,b,c]),
  familyActual.types,nil,familyActual.parameters.binders,root));
 let equal=same(old,none)&&same(actual,none);
 if(!same(old,none)&&!same(actual,none)){
  const left=old.value,right=actual.value,li=array(left.indices),ri=array(right.indices);
  const spine=force(get('psKernelExprV2TransformAppSpineOnCanonical')(familySource.arena,root));
  equal=left.target===right.target&&li.length===ri.length&&
   li.every((expr,j)=>eq(expr,decode(familySource.arena,ri[j])))&&same(ri,array(spine.snd).slice(1));
 }
 familyRequire('cross-family-application-'+i,equal);
});
familyRequire('missing-application-root-is-error',Object.hasOwn(get('psKernelExprV2MutualAppInfoOnCanonical')(
 familySource.arena,list([a,b,c]),familyActual.types,nil,familyActual.parameters.binders,familySource.arena.size),'error'));
if(familyLabels.length!==114||new Set(familyLabels).size!==114)throw Error('family matrix incomplete');
console.log('PSC1_MUTUAL_RESULT_JS: PASS '+JSON.stringify({assertions:114,occurrence:90,application:20,
 boundary:3,headers:1,labels:familyLabels,completeV1StructuralComparison:true,originalIndexIDs:true,
 allFamilyNames:true,privateStageOnly:true,fullAdmission:false,fullKernel:false,performanceQualified:false,
 kernel:{bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex')}}));

// Exact expanded-tree budget: fresh private memo, no expanded reference on stress DAGs.
const sizeLabels=[];
const sizeRequire=(label,condition)=>{if(condition!==true)throw Error('PSC1_EXPANDED_SIZE_FAIL '+label);sizeLabels.push(label);};
const sizeAtom=E.const(nm('atom'),nil),sizeSort=E.sort(zero);
const sizeTerms=[E.bvar(0n),E.fvar(nm('x')),E.mvar(nm('m')),sizeSort,sizeAtom,
 E.app(sizeAtom,sizeAtom),E.lam(nm('x'),sizeSort,E.bvar(0n),bi),
 E.forallE(nm('x'),sizeSort,E.bvar(0n),unit(get('PsKernelBinderInfo').implicit)),
 E.letE(nm('x'),sizeSort,sizeSort,E.bvar(0n),false),E.lit(Lit.nat(123n)),E.lit(Lit.str('Aé€😀')),
 E.mdata(13n,sizeAtom),E.proj(nm('Struct'),1n,sizeAtom),
 E.app(E.mdata(1n,sizeAtom),E.app(sizeAtom,sizeAtom)),
 E.letE(nm('x'),E.app(sizeAtom,sizeAtom),E.mdata(2n,sizeAtom),E.app(E.bvar(0n),sizeAtom),true),
 E.forallE(nm('x'),sizeAtom,E.lam(nm('y'),sizeAtom,E.app(E.bvar(0n),E.bvar(1n)),unit(get('PsKernelBinderInfo').strictImplicit)),bi),
 E.const(nm('levels'),list([L.param(nm('u')),L.max(zero,one)])),
 E.sort(L.max(L.param(nm('u')),L.succ(L.param(nm('v')))))];
sizeTerms.forEach((term,i)=>{
 const initial={arena:get('psKernelExprV2PagedEmpty'),built:get('psKernelExprV2DecodedEmpty'),declarations:nil};
 const built=force(get('psKernelDagGeneratedImport')(term,initial));
 const actual=force(get('psKernelExprV2ExpandedSizeOnCanonical')(built.fst.arena,built.snd));
 sizeRequire('all-shapes-exact-count-'+i,actual===get('psKernelExprNodeCount')(term));
});
for(const depth of[0,1,5,20,100]){
 const leaf=force(get('psKernelExprV2PagedMkSort')(get('psKernelExprV2PagedEmpty'),zero));
 let arena=leaf.fst,root=leaf.snd;
 for(let i=0;i<depth;i++){
  const next=force(get('psKernelExprV2PagedMkApp')(arena,root,root));arena=next.fst;root=next.snd;
 }
 const entry=force(get('psKernelExprV2PagedRequire')(arena,root));
 const result=force(get('psKernelExprV2ExpandedSizeWithFuel')(entry.depth+1n)(arena)(root)(nil));
 const actual=force(get('psKernelExprV2ExpandedSizeOnCanonical')(arena,root));
 const expected=2n**BigInt(depth+1)-1n;
 sizeRequire('shared-diamond-'+depth,actual===expected&&result.snd===expected&&
  array(result.fst).length===depth+1&&arena.size===BigInt(depth+1));
}
const fakeSizeMemo=list([{source:0n,count:777n}]),sizeEmpty=get('psKernelExprV2PagedEmpty');
sizeRequire('zero-budget-precedes-even-a-memo-hit',same(
 get('psKernelExprV2ExpandedSizeWithFuel')(0n)(sizeEmpty)(0n)(fakeSizeMemo),
 get('Except').error('PSKERNEL_V2_EXPANDED_SIZE_FUEL')));
const fakePrivate=force(get('psKernelExprV2ExpandedSizeWithFuel')(1n)(sizeEmpty)(0n)(fakeSizeMemo));
sizeRequire('public-canonical-entry-never-accepts-private-memo',fakePrivate.snd===777n&&
 array(fakePrivate.fst).length===1&&Object.hasOwn(get('psKernelExprV2ExpandedSizeOnCanonical')(sizeEmpty,0n),'error'));
sizeRequire('missing-root-is-hard-error',Object.hasOwn(get('psKernelExprV2ExpandedSizeOnCanonical')(sizeEmpty,10n),'error'));
if(sizeLabels.length!==26||new Set(sizeLabels).size!==26)throw Error('size matrix incomplete');
console.log('PSC1_EXPANDED_SIZE_JS: PASS '+JSON.stringify({assertions:26,shapes:18,sharing:5,boundaries:3,
 labels:sizeLabels,exactV1Count:true,originalStructuralBudget:true,privateMemo:true,expandedStressReferenceBuilt:false,
 fullAdmission:false,fullKernel:false,performanceQualified:false,
 kernel:{bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex')}}));

// The actual retained original worker remains the semantic comparison. Every
// private result must be direct; a decline never counts as admission success.
const stageNames=list([a,b,c]);
const provisionalDecl={levelParams:nil,numParams:1n,
 types:list(familyOld.types.map(t=>t.declaration)),isUnsafe:false};
const provisionalInfos=get('psKernelMakeSimpleMutualBaseInfos')(stageNames,provisionalDecl,oldShapes);
const stageWork=get('psKernelAddMutualInductiveInfos')(provisionalInfos)(environment);
const stageOld=get('psKernelSessionWithEnvironment')(familyOld.parameters.session,stageWork);
const stageContext={...familyActual.parameters.context,
 scalar:get('psKernelCheckerContextWithEnvironment')(familyActual.parameters.context.scalar,stageWork)};
const stageReferences=list(array(familyActual.types).map(t=>({name:t.declaration.name,
 levelParams:nil,type:t.declaration.type,deltaValue:none,
 kind:unit(get('PsKernelExprV2DeclarationRefKind').inductiveDecl)})));
const stageBase=familyActual.parameters.state;
const stageState=get('psKernelExprV2CheckStateWithWhnf')(stageBase,
 {...stageBase.whnf,arena:familyActual.arena,declarations:stageReferences});
const stageInput=term=>{
 const result=force(get('psKernelDagGeneratedImport')(term,{arena:stageState.whnf.arena,
  built:force(get('psKernelExprV2DecodeChecked')(stageState.whnf.arena)),declarations:nil}));
 return {root:result.snd,state:get('psKernelExprV2CheckStateWithArena')(stageState,result.fst.arena)};
};
const sameStageBinder=(arena,x,y)=>same(x.internalName,y.internalName)&&same(x.userName,y.userName)&&
 same(x.binderInfo,y.binderInfo)&&eq(x.type,decode(arena,y.type));
const sameStageLocals=(old,context,state)=>old.state.nextFresh===state.nextFresh&&
 array(old.context.localContext.decls).length===array(context.locals).length&&
 array(old.context.localContext.decls).every((x,i)=>{
  const y=array(context.locals)[i];return same(get('psKernelLocalDeclName')(x),y.name)&&
   same(get('psKernelLocalDeclUserName')(x),y.userName)&&eq(get('psKernelLocalDeclType')(x),decode(state.whnf.arena,y.type));
 });
const sameStageRecursive=(arena,x,y)=>sameStageBinder(arena,x.field,y.field)&&x.target===y.target&&
 array(x.args).length===array(y.arguments).length&&array(x.indices).length===array(y.indices).length&&
 array(x.args).every((v,i)=>sameStageBinder(arena,v,array(y.arguments)[i]))&&
 array(x.indices).every((v,i)=>eq(v,decode(arena,array(y.indices)[i])));
const stageCompare=(old,actual,fields=false)=>{
 if(Object.hasOwn(old,'error'))return old.error===actual.error;
 if(Object.hasOwn(actual,'error'))return false;
 const x=old.value,y=actual.value,arena=y.state.whnf.arena;
 if(!sameStageLocals(x.session,y.context,y.state))return false;
 if(fields)return eq(x.result,decode(arena,y.result))&&array(x.fields).length===array(y.fields).length&&
  array(x.recursiveFields).length===array(y.recursiveFields).length&&
  array(x.fields).every((v,i)=>sameStageBinder(arena,v,array(y.fields)[i]))&&
  array(x.recursiveFields).every((v,i)=>sameStageRecursive(arena,v,array(y.recursiveFields)[i]));
 if(same(x.recursiveInfo,none)||same(y.recursiveInfo,none))return same(x.recursiveInfo,none)&&same(y.recursiveInfo,none);
 return sameStageRecursive(arena,x.recursiveInfo.value,y.recursiveInfo.value);
};
const recursiveLabels=[];
const recursiveRequire=(label,condition)=>{if(condition!==true)throw Error('PSC1_MUTUAL_RECURSIVE_FAIL '+label);recursiveLabels.push(label);};
recursiveRequire('checked-shared-header-parameter-names',same(
 array(familyOld.parameters.binders).map(p=>p.internalName),array(familyActual.parameters.binders).map(p=>p.internalName)));
const ra=apps(ca,[parameter]),rb=apps(cb,[parameter,s1]),rc=apps(cc,[parameter,s1,s2]);
const rnested=E.app(ra,s1);
const recursiveTerms=[ra,rb,rc,s1,parameter,E.mdata(5n,ra),E.mdata(3n,rb),
 E.app(E.lam(nm('z'),s1,ra,bi),s1),E.letE(nm('z'),s1,s1,rb,false),
 all('x',s1,ra),all('x',s1,all('y',s1,rb)),all('x',E.mdata(7n,s1),rc),
 all('x',ra,s1),all('x',E.mdata(9n,rb),ra),all('x',E.proj(c,0n,s1),ra),
 rnested,E.mdata(2n,rnested),apps(cb,[parameter,ra]),apps(E.const(a,list([zero])),[parameter]),
 E.forallE(nm('x'),s1,apps(cb,[parameter,E.bvar(0n)]),unit(get('PsKernelBinderInfo').implicit))];
const stagePoison=_fuel=>_context=>_state=>_root=>get('Option').some(get('Except').error('UNEXPECTED_WHNF'));
function recursiveWorker(structural,fuel,whnf,context,state,field,root){
 return get('psKernelExprV2MutualAnalyzeRecursiveArgumentWorker')(structural,fuel)(whnf)(context)(state)
  (stageNames)(familyActual.types)(nil)(familyActual.parameters.binders)(field)(root)(nil);
}
recursiveTerms.forEach((term,i)=>{
 const owned=stageInput(term),root=owned.root;
 const oldOpened=get('psKernelSessionWithLocal')(stageOld,nm('field'),term,bi);
 const oldField={internalName:oldOpened.fst,userName:nm('field'),type:term,binderInfo:bi};
 const opened=force(get('psKernelExprV2CheckOpenBinder')(stageContext,owned.state,nm('field'),root,root,bi));
 const field={internalName:opened.fresh,userName:nm('field'),type:root,binderInfo:bi};
 for(const fuel of[0n,1n,8n,256n]){
  const old=capture(()=>force(get('psKernelAnalyzeSimpleMutualRecursiveArgument')(
   fuel,oldOpened.snd,stageNames,oldShapes,nil,familyOld.parameters.binders,oldField,term)));
  const actual=capture(()=>direct(get('psKernelExprV2MutualAnalyzeRecursiveArgumentWithFuel')(
   fuel,opened.context,opened.parent,stageNames,familyActual.types,nil,familyActual.parameters.binders,field,root)));
  recursiveRequire('frozen-original-recursive-'+i+'-fuel-'+fuel,stageCompare(old,actual));
 }
 const attempted=recursiveWorker(1n,0n,stagePoison,opened.context,opened.parent,field,root);
 if(i<3)recursiveRequire('structural-selection-precedes-poison-whnf-'+i,
  !same(attempted,none)&&Object.hasOwn(attempted.value,'value'));
 if(i===3){
  recursiveRequire('structural-zero-precedes-even-valid-domain',same(
   recursiveWorker(0n,256n,stagePoison,opened.context,opened.parent,field,root),
   get('Option').some(get('Except').error('mutual recursive-argument budget exhausted'))));
  recursiveRequire('whnf-decline-propagates',same(
   recursiveWorker(1n,8n,_fuel=>_context=>_state=>_root=>none,opened.context,opened.parent,field,root),none));
  recursiveRequire('whnf-error-propagates',same(attempted,get('Option').some(get('Except').error('UNEXPECTED_WHNF'))));
  const missing=get('psKernelExprV2MutualAnalyzeRecursiveArgumentWith')(stagePoison,8n,opened.context,opened.parent,
   stageNames,familyActual.types,nil,familyActual.parameters.binders,field,opened.parent.whnf.arena.size);
  recursiveRequire('missing-count-root-hard-error-before-whnf',!same(missing,none)&&
   Object.hasOwn(missing.value,'error')&&missing.value.error!=='UNEXPECTED_WHNF');
 }
});
if(recursiveLabels.length!==88||new Set(recursiveLabels).size!==88)throw Error('recursive matrix incomplete');
console.log('PSC1_MUTUAL_RECURSIVE_JS: PASS '+JSON.stringify({assertions:88,frozen:80,direct:3,boundaries:4,header:1,
 labels:recursiveLabels,originalStructuralBudget:true,fixedCheckerFuel:true,originalBeforeWhnf:true,
 directPrivateOnly:true,fullAdmission:false,fullKernel:false,performanceQualified:false,
 kernel:{bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex')}}));

const fieldLabels=[];
const fieldRequire=(label,condition)=>{if(condition!==true)throw Error('PSC1_MUTUAL_FIELDS_FAIL '+label);fieldLabels.push(label);};
fieldRequire('checked-shared-header-parameter-names',same(
 array(familyOld.parameters.binders).map(p=>p.internalName),array(familyActual.parameters.binders).map(p=>p.internalName)));
const fa=ra,fb=apps(cb,[parameter,parameter]),fc=apps(cc,[parameter,parameter,parameter]);
const functionArg=all('x',parameter,fa);
const fieldTerms=[fa,fb,fc,all('f',fa,fa),all('f',fb,fa),all('f',fc,fb),all('f',functionArg,fc),
 all('f',all('x',parameter,all('y',parameter,fb)),fa),all('f',E.mdata(3n,functionArg),fa),
 all('f',all('x',fa,s1),fa),all('f',E.app(fa,s1),fa),all('f',apps(cb,[parameter,fa]),fa),
 all('f',s1,fa),all('f',s2,fa),all('f',fa,all('g',fb,fc)),all('f',functionArg,all('g',fc,fa)),
 E.mdata(4n,all('f',fa,fa)),E.letE(nm('z'),s1,s1,all('f',fa,fa),false),
 E.forallE(nm('f'),fa,E.app(cb,E.bvar(0n)),unit(get('PsKernelBinderInfo').implicit)),all('f',E.bvar(0n),fa)];
fieldTerms.forEach((term,i)=>{
 const owned=stageInput(term);
 for(const fuel of[0n,1n,8n,256n]){
  const old=capture(()=>force(get('psKernelOpenSimpleMutualConstructorFields')(
   fuel,stageOld,stageNames,oldShapes,nil,familyOld.parameters.binders,familyActual.resultLevel,term)));
  const actual=capture(()=>direct(get('psKernelExprV2MutualOpenConstructorFieldsWithFuel')(
   fuel,stageContext,owned.state,stageNames,familyActual.types,nil,familyActual.parameters.binders,
   familyActual.resultLevel,owned.root)));
  fieldRequire('frozen-original-fields-'+i+'-fuel-'+fuel,stageCompare(old,actual,true));
 }
});
const poisonCheck=_fuel=>_context=>_state=>_root=>get('Option').some(get('Except').error('UNEXPECTED_CHECK'));
const poisonAnalyze=_fuel=>_context=>_state=>_targets=>_types=>_levels=>_params=>_field=>_root=>
 get('Option').some(get('Except').error('UNEXPECTED_ANALYZE'));
const unused={internalName:nm('unused'),userName:nm('unused'),type:0n,binderInfo:bi};
function fieldsWorker(fuel,rev){return get('psKernelExprV2MutualOpenConstructorFieldsWorker')(fuel)
 (poisonCheck)(poisonCheck)(poisonAnalyze)(stageContext)(stageState)(stageNames)(familyActual.types)(nil)
 (familyActual.parameters.binders)(familyActual.resultLevel)(stageState.whnf.arena.size)(rev)(nil);}
fieldRequire('zero-precedes-lookup-and-all-callbacks',same(fieldsWorker(0n,list([unused])),
 get('Option').some(get('Except').error('mutual constructor field budget exhausted'))));
const fieldMissing=fieldsWorker(1n,nil);
fieldRequire('missing-root-precedes-all-callbacks',!same(fieldMissing,none)&&Object.hasOwn(fieldMissing.value,'error')&&
 fieldMissing.value.error!=='UNEXPECTED_CHECK'&&fieldMissing.value.error!=='UNEXPECTED_ANALYZE');
if(fieldLabels.length!==83||new Set(fieldLabels).size!==83)throw Error('field matrix incomplete');
console.log('PSC1_MUTUAL_FIELDS_JS: PASS '+JSON.stringify({assertions:83,frozen:80,boundaries:2,header:1,
 labels:fieldLabels,originalFieldOrder:true,mandatoryEnsureSort:true,scopeRestore:true,directPrivateOnly:true,
 fullAdmission:false,fullKernel:false,performanceQualified:false,
 kernel:{bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex')}}));

// Complete closed constructor types: every owner is compared against the
// retained original constructor loop before any public publication exists.
const constructorLabels=[];
const constructorRequire=(label,condition)=>{if(condition!==true)throw Error('PSC1_MUTUAL_CONSTRUCTOR_FAIL '+label);constructorLabels.push(label);};
constructorRequire('checked-shared-header-parameter-names',same(
 array(familyOld.parameters.binders).map(p=>p.internalName),array(familyActual.parameters.binders).map(p=>p.internalName)));
const ap=n=>apps(ca,[E.bvar(n)]),bp=n=>apps(cb,[E.bvar(n),E.bvar(n)]),cp=n=>apps(cc,[E.bvar(n),E.bvar(n),E.bvar(n)]);
const closeCtor=body=>all('P',s1,body);
const constructorTerms=[closeCtor(ap(0n)),closeCtor(bp(0n)),closeCtor(cp(0n)),
 closeCtor(all('f',ap(0n),ap(1n))),closeCtor(all('f',bp(0n),ap(1n))),closeCtor(all('f',cp(0n),bp(1n))),
 closeCtor(all('f',all('x',E.bvar(0n),ap(1n)),cp(1n))),
 closeCtor(all('f',all('x',E.bvar(0n),all('y',E.bvar(1n),bp(2n))),ap(1n))),
 closeCtor(all('f',E.mdata(3n,all('x',E.bvar(0n),ap(1n))),ap(1n))),
 closeCtor(all('f',all('x',ap(0n),E.bvar(1n)),ap(1n))),closeCtor(all('f',E.app(ap(0n),s1),ap(1n))),
 closeCtor(all('f',s1,ap(1n))),closeCtor(all('f',s2,ap(1n))),
 closeCtor(all('f',ap(0n),all('g',bp(1n),cp(2n)))),E.mdata(4n,closeCtor(ap(0n))),
 E.letE(nm('z'),s1,s1,closeCtor(ap(0n)),false),
 E.app(E.lam(nm('T'),s2,E.bvar(0n),bi),closeCtor(ap(0n))),E.mvar(nm('hole')),E.fvar(nm('unbound')),
 all('P',s1,E.const(a,list([L.param(nm('undeclared'))])))];
const applyStage=(fn,args)=>args.reduce((f,arg)=>f(arg),fn);
function compareConstructor(old,actual){
 if(Object.hasOwn(old,'error'))return old.error===actual.error;
 if(Object.hasOwn(actual,'error'))return false;
 const shapes=array(old.value.shapes);if(shapes.length!==1)throw Error('expected one original shape');
 const x=shapes[0],y=actual.value.shape,arena=actual.value.state.whnf.arena;
 return x.owner===y.owner&&same(x.ctor.name,y.ctor.name)&&eq(x.ctor.type,decode(arena,y.ctor.type))&&
  array(x.fields).length===array(y.fields).length&&array(x.recursiveFields).length===array(y.recursiveFields).length&&
  array(x.resultIndices).length===array(y.resultIndices).length&&
  array(x.fields).every((v,i)=>sameStageBinder(arena,v,array(y.fields)[i]))&&
  array(x.recursiveFields).every((v,i)=>sameStageRecursive(arena,v,array(y.recursiveFields)[i]))&&
  array(x.resultIndices).every((v,i)=>eq(v,decode(arena,array(y.resultIndices)[i])));
}
constructorTerms.forEach((term,i)=>{
 const owned=stageInput(term),ctor={name:nm('ctor'+i),type:term},dag={name:ctor.name,type:owned.root};
 array(oldShapes).forEach((shape,j)=>{
  const owner=BigInt(j);
  for(const fuel of[0n,8n,256n]){
   const old=capture(()=>force(applyStage(get('psKernelAddSimpleMutualConstructorsForTypeWorker')(list([ctor])),
    [fuel,unit(get('PsKernelDefinitionSafety').safe),familyActual.resultLevel,nil,familyOld.parameters.binders,
     stageNames,oldShapes,shape,owner,familyOld.parameters.session,stageWork,0n])));
   const actual=capture(()=>direct(get('psKernelExprV2MutualAnalyzeConstructorWithFuel')(fuel,stageContext,
    owned.state,stageNames,familyActual.types,owner,nil,familyActual.parameters.binders,familyActual.resultLevel,dag)));
   constructorRequire('frozen-original-constructor-'+i+'-owner-'+owner+'-fuel-'+fuel,compareConstructor(old,actual));
   if(i<3&&fuel===256n&&j===i)constructorRequire('checked-correct-owner-'+owner,Object.hasOwn(actual,'value'));
   if(i<3&&fuel===256n&&j===(i+1)%3)constructorRequire('checked-wrong-owner-'+i,
    actual.error==='mutual constructor returns the wrong datatype');
  }
 });
});
const constructorNever=_fuel=>_context=>_state=>_left=>_right=>none;
const missingConstructor={name:nm('missing'),type:stageState.whnf.arena.size};
const missingCtor=get('psKernelExprV2MutualAnalyzeConstructorWith')(poisonCheck,poisonCheck,constructorNever,256n,
 stageContext,stageState,stageNames,familyActual.types,0n,nil,familyActual.parameters.binders,
 familyActual.resultLevel,missingConstructor);
constructorRequire('missing-static-root-precedes-closed-check',!same(missingCtor,none)&&
 Object.hasOwn(missingCtor.value,'error')&&missingCtor.value.error!=='UNEXPECTED_CHECK');
const invalidCtorResult=stageInput(s1);
constructorRequire('invalid-result-before-owner-comparison',same(get('psKernelExprV2MutualValidateConstructorResult')(
 invalidCtorResult.state.whnf.arena,stageNames,familyActual.types,999n,nil,familyActual.parameters.binders,
 invalidCtorResult.root),get('Except').error('mutual constructor has invalid return type')));
if(constructorLabels.length!==189||new Set(constructorLabels).size!==189)throw Error('constructor matrix incomplete');
console.log('PSC1_MUTUAL_CONSTRUCTOR_JS: PASS '+JSON.stringify({assertions:189,frozen:180,correct:3,wrong:3,boundaries:2,header:1,
 labels:constructorLabels,completeClosedConstructor:true,freshClosedScope:true,originalOwnerErrors:true,directPrivateOnly:true,
 fullAdmission:false,fullKernel:false,performanceQualified:false,
 kernel:{bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex')}}));
