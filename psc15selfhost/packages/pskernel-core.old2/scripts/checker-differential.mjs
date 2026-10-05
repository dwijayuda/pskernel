// Differential tests submit actual term judgments to the independent native
// kernel; this provider is never called by the new checking implementation.
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {root,json,sha256,checkedTool} from './source.mjs';
import './verify-build.mjs';
import {B,U,Pi,Lam,App,Let,identity,identityType,check,admit} from '../test/checker-values.mjs';
import {randomGenerator} from '../test/binding-values.mjs';
const pin=json(path.join(root,'manifests/TOOLCHAIN.json'));
const provider=checkedTool(process.env.LEAN_PROVIDER,pin.leanProviderSha256,'LEAN_PROVIDER');
function call(args,input){
 const p=spawnSync(provider,args,{input,encoding:'utf8',timeout:120000,maxBuffer:8*1024*1024});
 if(p.error||p.signal||p.status!==0)throw p.error||Error('NATIVE_PROCESS_FAILED');
 const r=JSON.parse(p.stdout);
 if(r.protocol!=='pskernel-lean/1'||r.provider!=='lean4-cpp'||r.leanVersion!==pin.leanVersion||r.leanCommit!==pin.leanCommit||r.profile!=='lean4.34-core')throw Error('NATIVE_IDENTITY_MISMATCH');
 return r;
}
const identityPin=call(['--version']);
const name=x=>typeof x==='string'?{k:'s',p:{k:'a'},v:x}:x[0]==='anonymous'?{k:'a'}:{k:x[0]==='str'?'s':'n',p:name(x[1]),v:x[2]};
function lev(x){switch(x[0]){case'zero':return{k:'z'};case'succ':return{k:'s',o:lev(x[1])};case'param':return{k:'p',n:name(x[1])};case'max':case'imax':return{k:x[0],l:lev(x[1]),r:lev(x[2])};default:throw Error('UNKNOWN_LEVEL');}}
function expr(x){switch(x[0]){
 case'b':{const n=BigInt(x[1]);if(n<0n||n>0xffffffffn)throw Error('OUTSIDE_NATIVE_INDEX_RANGE');return{k:'b',i:Number(n)};}
 case'sort':return{k:'sort',l:lev(x[1])};
 case'const':return{k:'const',n:name(x[1]),ls:x[2].map(lev)};
 case'app':return{k:'app',f:expr(x[1]),a:expr(x[2])};
 case'lam':case'pi':return{k:x[0]==='pi'?'forall':'lam',n:name(x[1]),bi:{explicit:'default',implicit:'implicit',strictImplicit:'strictImplicit',instanceImplicit:'instImplicit'}[x[4]],t:expr(x[2]),b:expr(x[3])};
 case'let':return{k:'let',n:name(x[1]),t:expr(x[2]),v:expr(x[3]),b:expr(x[4])};
 default:throw Error('NOT_IN_DIRECT_WIRE_FRAGMENT:'+x[0]);
}}
function canonical(x){if(Array.isArray(x))return x.map(canonical);if(x&&typeof x==='object')return Object.fromEntries(Object.keys(x).sort().map(k=>[k,canonical(x[k])]));return x;}
const declaration=d=>({kind:'constant',declaration:{k:'definition',n:name(d.name),lp:[],t:expr(d.type),v:expr(d.value),h:{k:'regular',h:'1'},s:'safe'}});
const fixed=json(path.join(root,'test/checker-cases.json'));
const excluded=fixed.filter(c=>c.native===null||['internal-free-variable','huge-bound-index-not-rounded'].includes(c.name)).map(c=>({name:c.name,reason:c.exclusionReason??(c.native===null?'explicitly unsupported feature':'not representable in native closed-core wire fragment')}));
const corpus=fixed.filter(c=>!excluded.some(x=>x.name===c.name)).map(c=>({...c,group:'named'}));
const rand=randomGenerator(919);
for(let i=0;i<128;i++){
 const n=rand(5),t=identityType(n),v=identity(n);
 const term=i%2?Let('local',t,v,B(0)):App(Lam('local',t,B(0)),v);
 corpus.push({name:'generated-valid-'+i,group:'generated-positive',type:t,value:term,prior:[],native:true});
 corpus.push({name:'generated-corruption-'+i,group:'generated-negative',type:t,value:Lam('A',U(n),Lam('x',B(0),B(1))),prior:[],native:false});
}
function randomTerm(depth){if(depth===0)return rand(2)?B(rand(4)):U(rand(4));const a=()=>randomTerm(depth-1);switch(rand(6)){case 0:return U(rand(4));case 1:return B(rand(5));case 2:return Pi('x',a(),a());case 3:return Lam('x',a(),a());case 4:return App(a(),a());default:return Let('x',a(),a(),a());}}
for(let i=0;i<256;i++)corpus.push({name:'random-raw-'+i,group:'random-raw',type:U(rand(4)),value:randomTerm(3),prior:[]});
// Recorded completeness gaps, not silently discarded unexpected mismatches.
const piGapType=Pi('P',U(0),Pi('F',Pi('h',B(0),U(1)),Pi('p',B(1),Pi('q',B(2),Pi('x',App(B(2),B(1)),App(B(3),B(1)))))));
const piGapValue=Lam('P',U(0),Lam('F',Pi('h',B(0),U(1)),Lam('p',B(1),Lam('q',B(2),Lam('x',App(B(2),B(1)),B(0))))));
const etaGapType=Pi('A',U(1),Pi('f',Pi('x',B(0),B(1)),Pi('F',Pi('g',Pi('x',B(1),B(2)),U(1)),Pi('h',App(B(0),B(1)),App(B(1),Lam('x',B(3),App(B(3),B(0))))))));
const etaGapValue=Lam('A',U(1),Lam('f',Pi('x',B(0),B(1)),Lam('F',Pi('g',Pi('x',B(1),B(2)),U(1)),Lam('h',App(B(0),B(1)),B(0)))));
const gaps=[{name:'proof-irrelevance',type:piGapType,value:piGapValue},{name:'function-eta',type:etaGapType,value:etaGapValue}];
const records=[];
for(const c of [...corpus,...gaps.map(g=>({...g,group:'known-completeness-gap',prior:[],native:true}))]){
 const ownPrior=admit(c.prior);if(ownPrior.status!=='admitted')throw Error('PRIOR_FAILED:'+c.name);
 const own=check(c.value,c.type,ownPrior.result.environment);if(!['done','rejected'].includes(own.status))throw Error('NONDECISIVE_RESULT:'+c.name);
 const request=JSON.stringify(canonical({format:'proofscript-checked-admissions',version:2,admissions:[...c.prior.map(declaration),declaration({name:'IndependentCheckerProbe',type:c.type,value:c.value})]}));
 const result=call(['--check'],request);
 if(result.accepted!==true&&(result.accepted!==false||result.errorKind!=='kernel-rejection'||result.declarationIndex!==c.prior.length))throw Error('INVALID_NATIVE_RESULT:'+JSON.stringify(result));
 if(c.native!==undefined&&result.accepted!==c.native)throw Error('INCORRECT_FIXTURE_EXPECTATION:'+c.name+':'+JSON.stringify(result));
 const record={name:c.name,group:c.group,type:c.type,value:c.value,prior:c.prior,ours:own.status,ourError:own.error??null,steps:own.steps,nativeAccepted:result.accepted,requestSha256:sha256(request),native:result};
 if(c.group==='known-completeness-gap'){
  if(own.status!=='rejected'||own.error!=='typeMismatch'||result.accepted!==true)throw Error('GAP_EXPECTATION_CHANGED:'+c.name);
 }else if((own.status==='done')!==result.accepted)throw Error('UNEXPECTED_CHECKER_MISMATCH:'+JSON.stringify(record));
 records.push(record);
 if(records.length%50===0)console.log('PSKERNEL_CHECKER_DIFFERENTIAL_PROGRESS: '+records.length);
}
const comparable=records.filter(x=>x.group!=='known-completeness-gap');
const report={schemaVersion:1,scope:'Actual closed monomorphic term judgments; bounded differential evidence, not full compatibility or a soundness proof',sourceManifestSha256:sha256(fs.readFileSync(path.join(root,'manifests/SOURCE.json'))),harnessSha256:sha256(fs.readFileSync(fileURLToPath(import.meta.url))),provider:identityPin,providerSha256:pin.leanProviderSha256,comparableCases:comparable.length,matched:comparable.length,accepted:comparable.filter(x=>x.nativeAccepted).length,rejected:comparable.filter(x=>!x.nativeAccepted).length,knownCompletenessGaps:gaps.map(x=>x.name),excluded,records};
const recordsPath='dist/evidence/checker-differential-records.json';
const recordsText=JSON.stringify(records,null,2)+'\n';
fs.mkdirSync(path.join(root,'dist/evidence'),{recursive:true});
fs.writeFileSync(path.join(root,recordsPath),recordsText);
const summary={...report,records:undefined,recordsPath,recordsSha256:sha256(recordsText)};
fs.writeFileSync(path.join(root,'manifests/CHECKER_DIFFERENTIAL.json'),JSON.stringify(summary,null,2)+'\n');
console.log(JSON.stringify(summary,null,2));
