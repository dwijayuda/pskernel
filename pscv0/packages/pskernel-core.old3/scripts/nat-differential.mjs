// Independent native admission comparisons for the bounded unary recursive family.
import fs from 'node:fs';import path from 'node:path';import {spawnSync} from 'node:child_process';import {fileURLToPath} from 'node:url';
import {root,json,sha256,checkedTool} from './source.mjs';import './verify-build.mjs';
import {definition} from '../test/unit-values.mjs';
import {N,Z,S,U,B,C,app,pi,lam,nat,numeral,member,identityRec,sortRec,polymorphicFold,joint,bootstrap} from '../test/nat-values.mjs';
const pin=json(path.join(root,'manifests/TOOLCHAIN.json')),provider=checkedTool(process.env.LEAN_PROVIDER,pin.leanProviderSha256,'LEAN_PROVIDER');
function call(args,input){const p=spawnSync(provider,args,{input,encoding:'utf8',timeout:120000,maxBuffer:8*1024*1024});
 if(p.error||p.signal||p.status!==0)throw p.error||Error('REFERENCE_PROCESS_FAILED');const r=JSON.parse(p.stdout);
 if(r.protocol!=='pskernel-lean/1'||r.provider!=='lean4-cpp'||r.leanVersion!==pin.leanVersion||r.leanCommit!==pin.leanCommit||r.profile!=='lean4.34-core')throw Error('REFERENCE_IDENTITY');return r;}
const identity=call(['--version']),cases=[],add=(label,entries,expected,bootstrap=false)=>cases.push({label,entries,expected,bootstrap});
const proofType=pi('P',U(Z),pi('p',B(0),B(1)));
add('unary recursive family',[nat()],true);
for(const [label,override]of [
 ['family collision',{zeroName:N('OwnedNat')}],['constructor collision',{succName:member('OwnedNat','zero')}],['recursor collision',{succName:member('OwnedNat','rec')}],
 ['unknown result',{zeroType:C('Unknown')}],['wrong zero result',{zeroType:U(Z)}],
 ['wrong successor result',{succType:pi('n',C('OwnedNat'),U(Z))}],
 ['negative recursive field',{succType:pi('f',pi('n',C('OwnedNat'),C('OwnedNat')),C('OwnedNat'))}],
 ['unbound successor type',{succType:pi('n',C('OwnedNat'),B(2))}],
 ['extra family universe',{zeroType:C('OwnedNat',[Z])}],
])add(label,[nat('OwnedNat',override)],false);
add('duplicate family',[nat(),nat()],false);
add('unknown family sort',[nat('OwnedNat',{familyType:C('Unknown')})],false);
add('foreign constructor result',[nat('Foreign'),nat('OwnedNat',{zeroType:C('Foreign')})],false);
add('missing recursor universe',[nat(),definition('Bad',[],U(S(Z)),C(member('OwnedNat','rec')))],false);
for(let i=0;i<24;i++){
 const name='NatFamily'+i,decl=nat(name);
 add('constructor-'+i,[decl,definition('Value',[],C(name),numeral(i%8,name))],true);
 add('identity-recursion-'+i,[decl,definition('Value',[],C(name),identityRec(i%8,name))],true);
 add('iota-dependent-type-'+i,[decl,definition('Value',[],sortRec(i%8,name),proofType)],true);
 const wrong=sortRec(i%8,name);wrong[1][1][2]=U(S(Z));
 add('wrong-minor-'+i,[decl,definition('Bad',[],U(S(Z)),wrong)],false);
 add('wrong-constructor-argument-'+i,[decl,definition('Bad',[],C(name),app(C(member(name,'succ')),U(Z)))],false);
}
for(let i=0;i<16;i++){
 add('builtin-constructor-'+i,[definition('Value',[],C('Nat'),numeral(i%8,'Nat'))],true,true);
 add('builtin-identity-'+i,[definition('Value',[],C('Nat'),identityRec(i%8,'Nat'))],true,true);
 add('builtin-dependent-iota-'+i,[definition('Value',[],sortRec(i%8,'Nat'),proofType)],true,true);
 add('builtin-wrong-value-'+i,[definition('Bad',[],C('Nat'),U(Z))],false,true);
}
add('builtin-Nat-cannot-be-redeclared',[nat('Nat')],false,true);
for(const builtin of [false,true]){
 const family=builtin?'Nat':'OwnedNat',fold=polymorphicFold(5,family);
 add('polymorphic-fold-'+family,[...(builtin?[]:[nat()]),definition('Fold',['u'],fold.type,fold.value)],true,builtin);
}
const name=x=>x[0]==='anonymous'?{k:'a'}:{k:x[0]==='str'?'s':'n',p:name(x[1]),v:x[2]};
const level=x=>x[0]==='zero'?{k:'z'}:x[0]==='succ'?{k:'s',o:level(x[1])}:x[0]==='param'?{k:'p',n:name(x[1])}:{k:x[0],l:level(x[1]),r:level(x[2])};
function expr(x){switch(x[0]){case'b':return{k:'b',i:Number(x[1])};case'sort':return{k:'sort',l:level(x[1])};case'const':return{k:'const',n:name(x[1]),ls:x[2].map(level)};
 case'app':return{k:'app',f:expr(x[1]),a:expr(x[2])};case'lam':case'pi':return{k:x[0]==='lam'?'lam':'forall',n:name(x[1]),bi:'default',t:expr(x[2]),b:expr(x[3])};default:throw Error('UNSUPPORTED_TEST_EXPRESSION');}}
const declaration=d=>d.kind==='nat'?{kind:'inductive',declaration:{lp:[],np:0,ts:[{n:name(d.name),t:expr(d.familyType),cs:[{n:name(d.zeroName),t:expr(d.zeroType)},{n:name(d.succName),t:expr(d.succType)}]}]}}
 :{kind:'constant',declaration:{k:'definition',n:name(d.name),lp:d.parameters.map(name),t:expr(d.type),v:expr(d.value),s:'safe',h:{k:'regular',h:'1'}}};
const records=[];
for(const c of cases){const ours=(c.bootstrap?bootstrap:joint)(c.entries,1000000);if(!['admitted','rejected'].includes(ours.status))throw Error('NONDECISIVE_OWNED_RESULT:'+c.label);
 const request=JSON.stringify({format:'proofscript-checked-admissions',version:2,admissions:c.entries.map(declaration)}),native=call(['--check'],request);
 if(native.accepted!==true&&(native.accepted!==false||native.errorKind!=='kernel-rejection'))throw Error('NONDECISIVE_REFERENCE_RESULT:'+c.label+':'+JSON.stringify(native));
 const record={...c,ours:ours.status,ourError:ours.error??null,steps:ours.steps,native,requestSha256:sha256(request)};
 if(native.accepted!==c.expected||(ours.status==='admitted')!==native.accepted)throw Error('NAT_MISMATCH:'+JSON.stringify(record));
 records.push(record);if(records.length%20===0)console.log('NAT_DIFFERENTIAL_PROGRESS: '+records.length+'/'+cases.length);}
const recordsPath='dist/evidence/nat-differential-records.json',recordsText=JSON.stringify(records,null,2)+'\n';fs.mkdirSync(path.join(root,'dist/evidence'),{recursive:true});fs.writeFileSync(path.join(root,recordsPath),recordsText);
const report={schemaVersion:1,scope:'Monomorphic zero/successor strictly positive unary recursive family in Type, derived dependent recursor and owned checked Nat initialization; not general inductive completeness',
 sourceManifestSha256:sha256(fs.readFileSync(path.join(root,'manifests/SOURCE.json'))),harnessSha256:sha256(fs.readFileSync(fileURLToPath(import.meta.url))),provider:identity,providerSha256:pin.leanProviderSha256,
 cases:records.length,matched:records.length,accepted:records.filter(x=>x.native.accepted).length,rejected:records.filter(x=>!x.native.accepted).length,
 deliberatelyUnsupported:['Prop or higher-sort families','term parameters and indices','additional/nonrecursive/higher-order fields','mutual and nested recursion'],recordsPath,recordsSha256:sha256(recordsText)};
fs.writeFileSync(path.join(root,'manifests/NAT_DIFFERENTIAL.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2));
