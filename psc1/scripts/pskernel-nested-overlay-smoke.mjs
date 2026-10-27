import {pathToFileURL} from 'node:url';
import {resolve} from 'node:path';
const k=await import(pathToFileURL(resolve(process.argv[2])).href);
const get=n=>{if(!(n in k))throw Error('missing export '+n);return k[n];};
const unit=x=>typeof x==='function'?x():x;
const same=(a,b)=>a===b||(a!==null&&b!==null&&typeof a==='object'&&typeof b==='object'&&Reflect.ownKeys(a).length===Reflect.ownKeys(b).length&&Reflect.ownKeys(a).every(p=>Object.hasOwn(b,p)&&same(a[p],b[p])));
const N=get('PsKernelName'),E=get('PsKernelExpr'),V=get('PsKernelLevel'),List=get('List');
const nil=unit(List.nil),list=xs=>xs.reduceRight((tail,head)=>List.cons(head,tail),nil),nm=s=>N.str(unit(N.anonymous),s);
const n=nm('OverlayOrigin'),zero=unit(V.zero),one=V.succ(zero),s1=E.sort(one),bi=unit(get('PsKernelBinderInfo').default);
const empty=()=>({arena:unit(get('psKernelExprV2PagedEmpty')),built:unit(get('psKernelExprV2DecodedEmpty')),declarations:nil});
const force=x=>{if(Object.hasOwn(x,'value'))return x.value;throw Error(x.error??'bad Except');};
const originalImport=(source,state)=>force(get('psKernelDagGeneratedImport')(source,state));
const overlay=(source,original,state)=>force(get('psKernelExprV2NestedOverlay')(source,original,state));
const labels=[];
function require(label,value){if(value!==true||labels.includes(label))throw Error('PSC1_NESTED_OVERLAY_FAIL '+label);labels.push(label);console.log('PSC1_NESTED_OVERLAY_ASSERT '+label);}
function prefixStable(before,after){
 if(before.arena.size>after.arena.size||before.built.size>after.built.size)return false;
 for(let id=0n;id<before.arena.size;id++){
  const a=force(get('psKernelExprV2PagedRequire')(before.arena,id)),b=force(get('psKernelExprV2PagedRequire')(after.arena,id));
  const x=force(get('psKernelExprV2DecodedRequire')(before.built,id)),y=force(get('psKernelExprV2DecodedRequire')(after.built,id));
  if(!same(a,b)||!same(x,y))return false;
 }
 return true;
}
const forms=[['bvar',E.bvar(1000000000000000000n)],['fvar',E.fvar(n)],['mvar',E.mvar(n)],['sort',s1],
 ['const',E.const(n,list([zero,one]))],['app',E.app(s1,E.bvar(0n))],['lam',E.lam(n,s1,E.bvar(0n),bi)],
 ['forall',E.forallE(n,s1,E.bvar(0n),bi)],['let',E.letE(n,s1,E.bvar(0n),E.bvar(0n),false)],
 ['literal',E.lit(get('PsKernelLiteral').str('Aé€😀'))],['metadata',E.mdata(7n,E.bvar(0n))],['projection',E.proj(n,0n,E.bvar(0n))]];
for(const [label,source]of forms){
 const before=originalImport(source,empty()),after=overlay(source,before.snd,before.fst);
 require(label+'-same-root',after.snd===before.snd);
 require(label+'-zero-node-growth',after.fst.arena.size===before.fst.arena.size&&after.fst.built.size===before.fst.built.size);
 const decoded=force(get('psKernelExprV2DecodedRequire')(after.fst.built,after.snd));
 require(label+'-canonical-source-and-prefix',same(decoded,source)&&prefixStable(before.fst,after.fst));
}
const spines=[['app',E.app(s1,E.bvar(0n)),E.app(s1,E.bvar(1n))],
 ['lam',E.lam(n,s1,E.bvar(0n),bi),E.lam(n,s1,E.bvar(1n),bi)],
 ['forall',E.forallE(n,s1,E.bvar(0n),bi),E.forallE(n,s1,E.bvar(1n),bi)],
 ['let',E.letE(n,s1,E.bvar(0n),E.bvar(0n),false),E.letE(n,s1,E.bvar(0n),E.bvar(1n),false)],
 ['metadata',E.mdata(7n,E.bvar(0n)),E.mdata(7n,E.bvar(1n))],['projection',E.proj(n,0n,E.bvar(0n)),E.proj(n,0n,E.bvar(1n))]];
for(const [label,source,target]of spines){
 const before=originalImport(source,empty()),after=overlay(target,before.snd,before.fst);
 require(label+'-only-new-leaf-and-parent',after.fst.arena.size===before.fst.arena.size+2n&&after.fst.built.size===after.fst.arena.size);
 require(label+'-old-ids-and-all-metadata-retained',prefixStable(before.fst,after.fst));
 require(label+'-changed-canonical-exact',same(force(get('psKernelExprV2DecodedRequire')(after.fst.built,after.snd)),target));
}
const payloads=[['binder-name',E.lam(n,s1,E.bvar(0n),bi),E.lam(nm('Renamed'),s1,E.bvar(0n),bi)],
 ['binder-info',E.forallE(n,s1,E.bvar(0n),bi),E.forallE(n,s1,E.bvar(0n),unit(get('PsKernelBinderInfo').implicit))],
 ['let-nondep',E.letE(n,s1,E.bvar(0n),E.bvar(0n),false),E.letE(n,s1,E.bvar(0n),E.bvar(0n),true)]];
for(const [label,source,target]of payloads){
 const before=originalImport(source,empty()),after=overlay(target,before.snd,before.fst);
 require(label+'-all-children-reused',after.fst.arena.size===before.fst.arena.size+1n&&prefixStable(before.fst,after.fst));
 require(label+'-new-payload-exact',same(force(get('psKernelExprV2DecodedRequire')(after.fst.built,after.snd)),target));
}
const sameError=(a,b)=>Object.hasOwn(a,'error')&&Object.hasOwn(b,'error')&&a.error===b.error;
const before=originalImport(E.bvar(0n),empty()),badRoot=before.fst.built.size;
require('missing-original-decoded-error-first',sameError(get('psKernelExprV2NestedOverlay')(E.app(s1,s1),badRoot,before.fst),get('psKernelExprV2DecodedRequire')(before.fst.built,badRoot)));
const stale={...before.fst,built:unit(get('psKernelExprV2DecodedEmpty'))};
require('stale-decoded-continuation-rejected',sameError(get('psKernelExprV2NestedOverlay')(E.bvar(0n),0n,stale),get('psKernelExprV2DecodedRequire')(stale.built,0n)));
const absent={...before.fst,arena:unit(get('psKernelExprV2PagedEmpty'))};
require('missing-original-arena-error-preserved',sameError(get('psKernelExprV2NestedOverlay')(E.bvar(0n),0n,absent),get('psKernelExprV2PagedRequire')(absent.arena,0n)));
const target=E.app(s1,E.bvar(1n)),after=overlay(target,before.snd,before.fst),reference=originalImport(target,before.fst);
require('changed-kind-original-generated-size-and-root',after.snd===reference.snd&&after.fst.arena.size===reference.fst.arena.size);
require('changed-kind-prefix-metadata-retained',prefixStable(before.fst,after.fst));
require('changed-kind-canonical-exact',same(force(get('psKernelExprV2DecodedRequire')(after.fst.built,after.snd)),target));
const header=originalImport(s1,empty()),declaration={name:n,levelParams:nil,type:header.snd,deltaValue:unit(get('Option').none),kind:unit(get('PsKernelExprV2DeclarationRefKind').axiomDecl)};
const owned={...header.fst,declarations:list([declaration])};
const sameOwner=overlay(s1,header.snd,owned),changedOwner=overlay(E.mdata(7n,s1),header.snd,owned);
require('unchanged-owner-retains-declaration-prefix',same(sameOwner.fst.declarations,owned.declarations));
require('changed-owner-retains-declaration-prefix',same(changedOwner.fst.declarations,owned.declarations));
if(labels.length!==68)throw Error('Bad overlay inventory');
console.log('PSC1_NESTED_OVERLAY_JS: PASS '+JSON.stringify({assertions:labels.length,labels,privateOnly:true,publicRouteChanged:false,fullKernel:false,performanceQualified:false}));
