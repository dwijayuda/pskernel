// Test-only adapter: ask the pinned external Lean provider to check ground
// computation theorems about the owned implementation. Not a runtime dependency.
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync, spawnSync } from 'node:child_process';
import { root, json, sha256 } from './source.mjs';
import { cases, naturalBits } from '../test/fixture-values.mjs';
import './verify-build.mjs';
const pin=json(path.join(root,'manifests/TOOLCHAIN.json'));
for(const [variable,key] of [['PSC1','psc1Sha256'],['LEAN_PROVIDER','leanProviderSha256']]) {
  if(!process.env[variable] || sha256(fs.readFileSync(process.env[variable]))!==pin[key]) throw Error(`${variable}_PIN_REQUIRED`);
}
const native=process.env.LEAN_PROVIDER;
const identity=JSON.parse(execFileSync(native,['--version'],{encoding:'utf8'}));
if(identity.leanVersion!==pin.leanVersion || identity.leanCommit!==pin.leanCommit || identity.provider!=='lean4-cpp') throw Error('ORACLE_IDENTITY_MISMATCH');
const base=JSON.parse(execFileSync(process.env.PSC1,['admissions',path.join(root,'dist/foundation.lean')],{encoding:'utf8',maxBuffer:16*1024*1024,timeout:60000}));
const name = text => text.split('.').reduce((p,v)=>({k:'s',p,v}),{k:'a'});
const constant=(n,ls=[])=>({k:'const',ls,n:name(n)});
const apply=(f,...args)=>args.reduce((f,a)=>({a,f,k:'app'}),f);
const ctor=(type,tag,...args)=>apply(constant(`${type}.${tag}`),...args);
function nat(text) {
  const bits=naturalBits(text);if(bits==='0') return constant('PsKernelNatural.zero');
  let n=constant('PsKernelPositive.one');
  for(const bit of bits.slice(1)) n=ctor('PsKernelPositive',bit==='0'?'bit0':'bit1',n);
  return ctor('PsKernelNatural','positive',n);
}
function text(value) {
  let out=constant('PsKernelText.empty');
  const bytes=new TextEncoder().encode(value);
  for(let i=bytes.length-1;i>=0;i--) out=ctor('PsKernelText','byte',nat(String(bytes[i])),out);
  return out;
}
function nm(x) {
  if(x[0]==='anonymous') return constant('PsKernelName.anonymous');
  return ctor('PsKernelName',x[0],nm(x[1]),x[0]==='str'?text(x[2]):nat(x[2]));
}
function lv(x) {
  if(x[0]==='zero') return constant('PsKernelLevel.zero');
  if(x[0]==='param') return ctor('PsKernelLevel','param',nm(x[1]));
  if(x[0]==='succ') return ctor('PsKernelLevel','succ',lv(x[1]));
  return ctor('PsKernelLevel',x[0],lv(x[1]),lv(x[2]));
}
// The PSC prelude treats Eq as an opaque assumption and does not provide Eq.refl.
// Admit a fresh ordinary indexed equality family, with no additional axiom.
const bv = i => ({i,k:'b'});
const pi = (n,t,b) => ({b,bi:'default',k:'forall',n:name(n),t});
const resultType=constant('PsKernelCompareResult');
const equality={kind:'inductive',declaration:{lp:[],np:1,ts:[{
  n:name('PsKernelFixture.Equal'),
  t:pi('expected',resultType,pi('actual',resultType,{k:'sort',l:{k:'z'}})),
  cs:[{n:name('PsKernelFixture.Equal.refl'),t:pi('expected',resultType,apply(constant('PsKernelFixture.Equal'),bv(0),bv(0)))}]
}]}};
function theorem(c,i,expected=c.expected) {
  let fuel=constant('PsKernelFuel.stop');for(let j=0;j<c.fuel;j++) fuel=ctor('PsKernelFuel','more',fuel);
  const convert=c.kind==='name'?nm:c.kind==='level'?lv:nat;
  const task=ctor('PsKernelCompareTask',c.kind,convert(c.left),convert(c.right));
  const taskType=constant('PsKernelCompareTask');
  const list=apply(constant('PsKernelList.cons'),taskType,task,apply(constant('PsKernelList.nil'),taskType));
  const expression=apply(constant('psKernelCompareTasks'),fuel,list);
  const value=constant(`PsKernelCompareResult.${expected}`);
  return {kind:'constant',declaration:{k:'theorem',lp:[],n:name(`PsKernelFixture.case${i}`),t:apply(constant('PsKernelFixture.Equal'),value,expression),v:apply(constant('PsKernelFixture.Equal.refl'),value)}};
}
function canonical(x) {
  if(Array.isArray(x)) return '['+x.map(canonical).join(',')+']';
  if(x!==null && typeof x==='object') return '{'+Object.keys(x).sort().map(k=>JSON.stringify(k)+':'+canonical(x[k])).join(',')+'}';
  return JSON.stringify(x);
}
function check(admissions) {
  const request=canonical({...base,admissions:[...base.admissions,equality,...admissions]});
  const run=spawnSync(native,['--check'],{input:request,encoding:'utf8',timeout:120000,maxBuffer:16*1024*1024});
  if(run.error || run.signal) throw run.error || Error(`ORACLE_SIGNAL: ${run.signal}`);
  let result;try {result=JSON.parse(run.stdout);}catch {throw Error(`ORACLE_PROTOCOL: ${run.stderr.slice(0,2000)}`);}
  if(result.leanCommit!==pin.leanCommit || result.provider!=='lean4-cpp') throw Error('ORACLE_RESPONSE_IDENTITY');
  return {requestSha256:sha256(request),status:run.status,result};
}
const valid=check(cases.map((c,i)=>theorem(c,i)));
if(valid.status!==0 || valid.result.accepted!==true) throw Error(`ORACLE_CASES_REJECTED: ${JSON.stringify(valid.result)}`);
const invalid=check([theorem(cases[0],0,'different')]);
if(invalid.result.accepted!==false || invalid.result.errorKind!=='kernel-rejection' || invalid.result.declarationIndex!==base.admissions.length+1) throw Error('FALSE_THEOREM_NOT_REJECTED');
const report={schemaVersion:1,scope:'ground computation cases for foundation; not full kernel equivalence or general correctness',sourceManifestSha256:sha256(fs.readFileSync(path.join(root,'manifests/SOURCE.json'))),provider:identity,providerSha256:pin.leanProviderSha256,fixturesSha256:sha256(fs.readFileSync(path.join(root,'test/cases.json'))),oracleHarnessSha256:sha256(fs.readFileSync(path.join(root,'scripts/oracle.mjs'))),positiveCases:cases.length,positiveRequestSha256:valid.requestSha256,positive:valid.result,negativeControls:1,negativeRequestSha256:invalid.requestSha256,negative:invalid.result};
fs.writeFileSync(path.join(root,'manifests/ORACLE.json'),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify(report,null,2));
