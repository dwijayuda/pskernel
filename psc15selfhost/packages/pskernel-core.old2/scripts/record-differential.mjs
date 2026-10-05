// Native comparisons for closed monomorphic record admission and constructor /
// dependent eliminator typing. This is finite evidence, not a soundness proof.
import fs from 'node:fs';import path from 'node:path';import {spawnSync} from 'node:child_process';import {fileURLToPath} from 'node:url';
import {root,json,sha256,checkedTool} from './source.mjs';import './verify-build.mjs';
import {definition} from '../test/unit-values.mjs';
import {N,Z,S,U,B,C,app,pi,lam,record,member,literal,value,firstFieldRec,bootstrap} from '../test/record-values.mjs';
const pin=json(path.join(root,'manifests/TOOLCHAIN.json')),provider=checkedTool(process.env.LEAN_PROVIDER,pin.leanProviderSha256,'LEAN_PROVIDER');
function call(args,input){const p=spawnSync(provider,args,{input,encoding:'utf8',timeout:120000,maxBuffer:8*1024*1024});
 if(p.error||p.signal||p.status!==0)throw p.error||Error('REFERENCE_PROCESS_FAILED');const r=JSON.parse(p.stdout);
 if(r.protocol!=='pskernel-lean/1'||r.provider!=='lean4-cpp'||r.leanVersion!==pin.leanVersion||r.leanCommit!==pin.leanCommit||r.profile!=='lean4.34-core')throw Error('REFERENCE_IDENTITY');return r;}
const identity=call(['--version']),cases=[],add=(label,entries,expected)=>cases.push({label,entries,expected});
for(let count=1;count<=12;count++){
 const family=record('R',Array(count).fill(C('Nat'))),args=Array.from({length:count},(_,i)=>literal(i+1));
 add('record-fields-'+count,[family],true);
 add('constructor-'+count,[family,definition('Use',[],C('R'),value('R',args))],true);
 add('recursor-type-'+count,[family,definition('Use',[],C('Nat'),firstFieldRec('R',count))],true);
 add('missing-field-'+count,[family,definition('Bad',[],C('R'),value('R',args.slice(1)))],false);
 add('extra-field-'+count,[family,definition('Bad',[],C('R'),value('R',[...args,literal(0)]))],false);
 const wrong=args.slice();wrong[count-1]=U(Z);
 add('wrong-field-'+count,[family,definition('Bad',[],C('R'),value('R',wrong))],false);
 const bad=firstFieldRec('R',count);bad[2]=literal(0);
 add('wrong-major-'+count,[family,definition('Bad',[],C('Nat'),bad)],false);
}
for(const count of [1,2,3,8]){
 const inner=record('Inner',Array(count).fill(C('Nat'))),outer=record('Outer',[C('Inner'),C('Nat')]);
 const iv=value('Inner',Array(count).fill(literal(0)));
 add('nested-'+count,[inner,outer,definition('Use',[],C('Outer'),value('Outer',[iv,literal(42)]))],true);
 add('nested-wrong-'+count,[inner,outer,definition('Bad',[],C('Outer'),value('Outer',[literal(0),iv]))],false);
}
add('closed-function',[record('R',[pi('n',C('Nat'),C('Nat'))]),definition('Use',[],C('R'),value('R',[lam('n',C('Nat'),B(0))]))],true);
add('field-type-alias',[definition('Alias',[],U(S(Z)),C('Nat')),record('R',[C('Alias')]),definition('Use',[],C('R'),value('R',[literal(7)]))],true);
for(const [label,entry]of [
 ['field-term',record('R',[literal(0)])],['free-bound-field',record('R',[B(0)])],
 ['negative-recursion',record('R',[pi('bad',C('R'),C('Nat'))])],
 ['wrong-constructor-result',record('R',[C('Nat')],{ctorType:pi('x',C('Nat'),C('Nat'))})],
 ['result-universe',record('R',[C('Nat')],{ctorType:pi('x',C('Nat'),C('R',[Z]))})],
 ['constructor-family-name',record('R',[C('Nat')],{ctorName:N('R')})],
 ['constructor-recursor-name',record('R',[C('Nat')],{ctorName:member('R','rec')})]
])add(label,[entry],false);
add('duplicate-family',[record('R'),record('R')],false);

const name=x=>x[0]==='anonymous'?{k:'a'}:{k:x[0]==='str'?'s':'n',p:name(x[1]),v:x[2]};
const level=x=>x[0]==='zero'?{k:'z'}:x[0]==='succ'?{k:'s',o:level(x[1])}:x[0]==='param'?{k:'p',n:name(x[1])}:{k:x[0],l:level(x[1]),r:level(x[2])};
function expr(x){switch(x[0]){case'b':return{k:'b',i:Number(x[1])};case'sort':return{k:'sort',l:level(x[1])};case'const':return{k:'const',n:name(x[1]),ls:x[2].map(level)};
 case'nat':return{k:'nat',v:x[1]};case'app':return{k:'app',f:expr(x[1]),a:expr(x[2])};case'lam':case'pi':return{k:x[0]==='lam'?'lam':'forall',n:name(x[1]),bi:'default',t:expr(x[2]),b:expr(x[3])};default:throw Error('UNSUPPORTED_TEST_EXPRESSION');}}
const declaration=d=>d.kind==='record'?{kind:'inductive',declaration:{lp:d.parameters.map(name),np:0,ts:[{n:name(d.name),t:expr(U(d.level)),cs:[{n:name(d.ctorName),t:expr(d.ctorType)}]}]}}
 :{kind:'constant',declaration:{k:'definition',n:name(d.name),lp:d.parameters.map(name),t:expr(d.type),v:expr(d.value),s:'safe',h:{k:'regular',h:'1'}}};
const records=[];
for(const c of cases){const ours=bootstrap(c.entries,1000000);if(!['admitted','rejected'].includes(ours.status))throw Error('NONDECISIVE_OWNED_RESULT:'+c.label);
 const request=JSON.stringify({format:'proofscript-checked-admissions',version:2,admissions:c.entries.map(declaration)}),native=call(['--check'],request);
 if(native.accepted!==true&&(native.accepted!==false||native.errorKind!=='kernel-rejection'))throw Error('NONDECISIVE_REFERENCE_RESULT:'+c.label+':'+JSON.stringify(native));
 const result={...c,ours:ours.status,ourError:ours.error??null,steps:ours.steps,native,requestSha256:sha256(request)};
 if(native.accepted!==c.expected||(ours.status==='admitted')!==native.accepted)throw Error('RECORD_MISMATCH:'+JSON.stringify(result));
 records.push(result);if(records.length%20===0)console.log('RECORD_DIFFERENTIAL_PROGRESS: '+records.length+'/'+cases.length);
}
const recordsPath='dist/evidence/record-differential-records.json',recordsText=JSON.stringify(records,null,2)+'\n';fs.mkdirSync(path.join(root,'dist/evidence'),{recursive:true});fs.writeFileSync(path.join(root,recordsPath),recordsText);
const report={schemaVersion:1,scope:'Closed monomorphic Type-valued record fields, constructor applications and derived dependent eliminator typing; admission-only suite; projection and iota have separate evidence; not general inductive completeness',
 sourceManifestSha256:sha256(fs.readFileSync(path.join(root,'manifests/SOURCE.json'))),harnessSha256:sha256(fs.readFileSync(fileURLToPath(import.meta.url))),provider:identity,providerSha256:pin.leanProviderSha256,
 cases:records.length,matched:records.length,accepted:records.filter(x=>x.native.accepted).length,rejected:records.filter(x=>!x.native.accepted).length,
 deliberatelyUnsupported:['dependent constructor fields','parameters and indices','recursive records','Prop or higher-universe families'],recordsPath,recordsSha256:sha256(recordsText)};
fs.writeFileSync(path.join(root,'manifests/RECORD_DIFFERENTIAL.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2));
