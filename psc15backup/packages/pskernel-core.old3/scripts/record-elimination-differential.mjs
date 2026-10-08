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
const P=(family,index,major)=>['proj',Array.isArray(family)?family:N(family),String(index),major];
const witness=(term,n)=>definition('Witness',[],pi('F',pi('n',C('Nat'),U(S(Z))),pi('h',app(B(0),literal(n)),app(B(1),term))),lam('F',pi('n',C('Nat'),U(S(Z))),lam('h',app(B(0),literal(n)),B(0))));
for(const count of [1,2,3,4,6,8]){
 const family=record('R',Array(count).fill(C('Nat'))),args=Array.from({length:count},(_,i)=>literal(i+1)),major=value('R',args);
 for(let i=0;i<count;i++){const proj=P('R',i,major),minor=Array(count).fill(C('Nat')).reduceRight((b,t,j)=>lam('f'+j,t,b),B(count-i-1)),rec=app(C(member('R','rec'),[S(Z)]),lam('r',C('R'),C('Nat')),minor,major);
  for(const [op,term]of [['proj',proj],['iota',rec]]){add(op+'-computed-'+count+'-'+i,[family,witness(term,i+1)],true);add(op+'-wrong-result-'+count+'-'+i,[family,witness(term,i+2)],false);}
 }
 add('out-of-bounds-'+count,[family,definition('Bad',[],C('Nat'),P('R',count,major))],false);
 add('neutral-bound-'+count,[family,definition('Bad',[],pi('r',C('R'),C('Nat')),lam('r',C('R'),P('R',count,B(0))))],false);
 add('missing-field-'+count,[family,definition('Bad',[],C('Nat'),P('R',0,value('R',args.slice(1))))],false);
 const bad=args.slice();bad[count-1]=U(Z);add('discarded-invalid-field-'+count,[family,definition('Bad',[],C('Nat'),P('R',0,value('R',bad)))],false);
}
const family=record('R',[C('Nat'),C('Nat')]),major=value('R',[literal(7),literal(11)]);
add('wrong-family',[family,record('Other',[C('Nat'),C('Nat')]),definition('Bad',[],C('Nat'),P('Other',0,major))],false);
add('wrong-major',[family,definition('Bad',[],C('Nat'),P('R',0,literal(0)))],false);
add('unknown-family',[family,definition('Bad',[],C('Nat'),P('Missing',0,major))],false);
add('nested',[record('Inner'),record('Outer',[C('Inner')]),witness(P('Inner',0,P('Outer',0,value('Outer',[value('Inner',[literal(7)])]))),7)],true);
add('alias',[family,definition('Alias',[],C('R'),major),witness(P('R',1,C('Alias')),11)],true);
const fn=pi('n',C('Nat'),C('Nat'));add('function-field',[record('R',[fn]),witness(app(P('R',0,value('R',[lam('n',C('Nat'),B(0))])),literal(13)),13)],true);
const captured=lam('x',C('Nat'),lam('y',C('Nat'),P('R',0,value('R',[B(1)]))));add('binder-capture',[record('R'),witness(app(captured,literal(7),literal(11)),7)],true);
const letTerm=['let',N('r'),C('R'),major,P('R',1,B(0))];add('let-projection',[family,witness(letTerm,11)],true);

const name=x=>x[0]==='anonymous'?{k:'a'}:{k:x[0]==='str'?'s':'n',p:name(x[1]),v:x[2]};
const level=x=>x[0]==='zero'?{k:'z'}:x[0]==='succ'?{k:'s',o:level(x[1])}:x[0]==='param'?{k:'p',n:name(x[1])}:{k:x[0],l:level(x[1]),r:level(x[2])};
function expr(x){switch(x[0]){case'b':return{k:'b',i:Number(x[1])};case'sort':return{k:'sort',l:level(x[1])};case'const':return{k:'const',n:name(x[1]),ls:x[2].map(level)};
 case'nat':return{k:'nat',v:x[1]};case'proj':return{k:'proj',n:name(x[1]),i:Number(x[2]),e:expr(x[3])};case'let':return{k:'let',n:name(x[1]),t:expr(x[2]),v:expr(x[3]),b:expr(x[4])};case'app':return{k:'app',f:expr(x[1]),a:expr(x[2])};case'lam':case'pi':return{k:x[0]==='lam'?'lam':'forall',n:name(x[1]),bi:'default',t:expr(x[2]),b:expr(x[3])};default:throw Error('UNSUPPORTED_TEST_EXPRESSION');}}
const declaration=d=>d.kind==='record'?{kind:'inductive',declaration:{lp:d.parameters.map(name),np:0,ts:[{n:name(d.name),t:expr(U(d.level)),cs:[{n:name(d.ctorName),t:expr(d.ctorType)}]}]}}
 :{kind:'constant',declaration:{k:'definition',n:name(d.name),lp:d.parameters.map(name),t:expr(d.type),v:expr(d.value),s:'safe',h:{k:'regular',h:'1'}}};
const records=[];
for(const c of cases){const ours=bootstrap(c.entries,1000000);if(!['admitted','rejected'].includes(ours.status))throw Error('NONDECISIVE_OWNED_RESULT:'+c.label);
 const request=JSON.stringify({format:'proofscript-checked-admissions',version:2,admissions:c.entries.map(declaration)}),native=call(['--check'],request);
 if(native.accepted!==true&&(native.accepted!==false||native.errorKind!=='kernel-rejection'))throw Error('NONDECISIVE_REFERENCE_RESULT:'+c.label+':'+JSON.stringify(native));
 const result={...c,ours:ours.status,ourError:ours.error??null,steps:ours.steps,native,requestSha256:sha256(request)};
 if(native.accepted!==c.expected||(ours.status==='admitted')!==native.accepted)throw Error('RECORD_ELIMINATION_MISMATCH:'+JSON.stringify(result));
 records.push(result);if(records.length%20===0)console.log('RECORD_ELIMINATION_DIFFERENTIAL_PROGRESS: '+records.length+'/'+cases.length);
}
const recordsPath='dist/evidence/record-elimination-differential-records.json',recordsText=JSON.stringify(records,null,2)+'\n';fs.mkdirSync(path.join(root,'dist/evidence'),{recursive:true});fs.writeFileSync(path.join(root,recordsPath),recordsText);
const report={schemaVersion:1,scope:'Closed-record projection typing, bounds, substitution and iota with dependent computed-result witnesses; not general inductive completeness',
 sourceManifestSha256:sha256(fs.readFileSync(path.join(root,'manifests/SOURCE.json'))),harnessSha256:sha256(fs.readFileSync(fileURLToPath(import.meta.url))),provider:identity,providerSha256:pin.leanProviderSha256,
 cases:records.length,matched:records.length,accepted:records.filter(x=>x.native.accepted).length,rejected:records.filter(x=>!x.native.accepted).length,
 deliberatelyUnsupported:['dependent constructor fields','parameters and indices','recursive records','Prop or higher-universe families'],recordsPath,recordsSha256:sha256(recordsText)};
fs.writeFileSync(path.join(root,'manifests/RECORD_ELIMINATION_DIFFERENTIAL.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2));
