// Independent actual polymorphic declaration judgments. Test-only; never a
// checking fallback or part of the installed kernel's semantic implementation.
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { root, json, sha256, checkedTool } from './source.mjs';
import './verify-build.mjs';
import { k, list, expression } from '../test/binding-values.mjs';
import { runtimeName } from '../test/fixture-values.mjs';
import { drive } from '../test/checker-values.mjs';
const pin=json(path.join(root,'manifests/TOOLCHAIN.json'));
const provider=checkedTool(process.env.LEAN_PROVIDER,pin.leanProviderSha256,'LEAN_PROVIDER');
function call(args,input){
  const p=spawnSync(provider,args,{input,encoding:'utf8',timeout:120000,maxBuffer:8*1024*1024});
  if(p.error||p.signal||p.status!==0)throw p.error||Error('REFERENCE_PROCESS_FAILED');
  const r=JSON.parse(p.stdout);
  if(r.protocol!=='pskernel-lean/1'||r.provider!=='lean4-cpp'||r.leanVersion!==pin.leanVersion||r.leanCommit!==pin.leanCommit||r.profile!=='lean4.34-core')throw Error('REFERENCE_IDENTITY');
  return r;
}
const providerIdentity=call(['--version']);
const N=s=>['str',['anonymous'],s], Z=['zero'], S=l=>['succ',l], P=s=>['param',N(s)], U=l=>['sort',l], B=i=>['b',String(i)];
const C=(n,ls=[])=>['const',N(n),ls], Pi=(n,t,b)=>['pi',N(n),t,b,'explicit'], Lam=(n,t,b)=>['lam',N(n),t,b,'explicit'];
const idType=l=>Pi('A',U(l),Pi('x',B(0),B(1))), id=l=>Lam('A',U(l),Lam('x',B(0),B(0)));
const def=(name,parameters,type,value)=>({name,parameters,type,value});
const poly=()=>def('Id',['u'],idType(P('u')),id(P('u')));
const alias=()=>def('Universe',['u'],U(S(P('u'))),U(P('u')));
const cases=[];
const add=(label,definitions,expected)=>cases.push({label,definitions,expected});
add('symbolic identity',[poly()],true);
add('symbolic successor use',[poly(),def('Use',['v'],idType(S(P('v'))),C('Id',[S(P('v'))]))],true);
add('delta under binder domain',[alias(),def('Use',[],Pi('A',C('Universe',[S(Z)]),Pi('x',B(0),B(1))),id(S(Z)))],true);
add('wrong instantiated type',[poly(),def('Bad',[],idType(S(Z)),C('Id',[Z]))],false);
add('missing level',[poly(),def('Bad',[],idType(Z),C('Id'))],false);
add('extra level',[poly(),def('Bad',[],idType(Z),C('Id',[Z,Z]))],false);
add('undeclared level in declaration',[def('Bad',[],U(S(P('missing'))),U(P('missing')))],false);
add('undeclared level in use',[poly(),def('Bad',[],idType(Z),C('Id',[P('missing')]))],false);
add('self reference',[def('Self',['u'],idType(P('u')),C('Self',[P('u')]))],false);
add('forward reference',[def('Use',['u'],idType(P('u')),C('Id',[P('u')])),poly()],false);
for(let i=0;i<64;i++){
  let level=i%2?P('v'):Z;
  for(let n=0;n<i%5;n++)level=S(level);
  if(i%3===0)level=['max',level,P('v')];
  if(i%7===0)level=['imax',P('v'),level];
  const parameters=['v'];
  add('generated-positive-'+i,[poly(),def('Use',parameters,idType(level),C('Id',[level]))],true);
  add('generated-corruption-'+i,[def('Bad',parameters,idType(level),Lam('A',U(level),Lam('x',B(0),B(1))))],false);
}
const name=x=>x[0]==='anonymous'?{k:'a'}:{k:x[0]==='str'?'s':'n',p:name(x[1]),v:x[2]};
const level=x=>x[0]==='zero'?{k:'z'}:x[0]==='succ'?{k:'s',o:level(x[1])}:x[0]==='param'?{k:'p',n:name(x[1])}:{k:x[0],l:level(x[1]),r:level(x[2])};
function expr(x){
  switch(x[0]){
    case'b':return{k:'b',i:Number(x[1])};
    case'sort':return{k:'sort',l:level(x[1])};
    case'const':return{k:'const',n:name(x[1]),ls:x[2].map(level)};
    case'app':return{k:'app',f:expr(x[1]),a:expr(x[2])};
    case'lam':case'pi':return{k:x[0]==='lam'?'lam':'forall',n:name(x[1]),bi:'default',t:expr(x[2]),b:expr(x[3])};
    default:throw Error('UNSUPPORTED_TEST_EXPRESSION');
  }
}
const declaration=d=>({kind:'constant',declaration:{k:'definition',n:name(N(d.name)),lp:d.parameters.map(p=>name(N(p))),t:expr(d.type),v:expr(d.value),s:'safe',h:{k:'regular',h:'1'}}});
const owned=d=>k.PsKernelDefinition.polymorphic(runtimeName(k,N(d.name)),list(d.parameters.map(p=>runtimeName(k,N(p)))),expression(d.type),expression(d.value));
const records=[];
for(const c of cases){
  const ours=drive(k.psKernelAdmissionStep,k.psKernelAdmissionStart(list(c.definitions.map(owned))),200000);
  if(!['admitted','rejected'].includes(ours.status))throw Error('NONDECISIVE_OWNED_RESULT:'+c.label);
  const request=JSON.stringify({format:'proofscript-checked-admissions',version:2,admissions:c.definitions.map(declaration)});
  const native=call(['--check'],request);
  if(native.accepted!==true&&(native.accepted!==false||native.errorKind!=='kernel-rejection'))throw Error('NONDECISIVE_REFERENCE_RESULT:'+c.label+':'+JSON.stringify(native));
  const record={...c,ours:ours.status,ourError:ours.error??null,steps:ours.steps,native,requestSha256:sha256(request)};
  if(native.accepted!==c.expected||(ours.status==='admitted')!==native.accepted)throw Error('POLYMORPHIC_MISMATCH:'+JSON.stringify(record));
  records.push(record);
  if(records.length%20===0)console.log('POLYMORPHIC_DIFFERENTIAL_PROGRESS: '+records.length+'/'+cases.length);
}
const recordsPath='dist/evidence/polymorphic-differential-records.json',recordsText=JSON.stringify(records,null,2)+'\n';
fs.mkdirSync(path.join(root,'dist/evidence'),{recursive:true});fs.writeFileSync(path.join(root,recordsPath),recordsText);
const report={schemaVersion:1,scope:'Bounded actual polymorphic transparent-definition judgments; not full kernel compatibility',
  sourceManifestSha256:sha256(fs.readFileSync(path.join(root,'manifests/SOURCE.json'))),
  harnessSha256:sha256(fs.readFileSync(fileURLToPath(import.meta.url))),provider:providerIdentity,providerSha256:pin.leanProviderSha256,
  cases:records.length,matched:records.length,accepted:records.filter(x=>x.native.accepted).length,rejected:records.filter(x=>!x.native.accepted).length,
  recordsPath,recordsSha256:sha256(recordsText)};
fs.writeFileSync(path.join(root,'manifests/POLYMORPHIC_DIFFERENTIAL.json'),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify(report,null,2));
