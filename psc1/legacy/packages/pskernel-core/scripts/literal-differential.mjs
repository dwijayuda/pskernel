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
const literal=n=>['nat',String(n)],proofType=pi('P',U(Z),pi('p',B(0),B(1)));
const define=(label,type,value,expected)=>add(label,[definition('LiteralProbe',[],type,value)],expected,true);
for(const n of [0n,1n,2n,42n,255n,256n,9007199254740991n,9007199254740993n,1n<<256n,1n<<2048n]){
 define('literal-'+n,C('Nat'),literal(n),true);
 define('wrong-literal-type-'+n,U(Z),literal(n),false);
}
for(let n=0;n<20;n++){
 const fold=identityRec(n,'Nat');fold[2]=literal(n);
 define('literal-recursor-'+n,C('Nat'),fold,true);
 const dependent=sortRec(n,'Nat');dependent[2]=literal(n);
 define('literal-dependent-iota-'+n,dependent,proofType,true);
 define('literal-dependent-wrong-'+n,dependent,U(Z),false);
 const family=pi('n',C('Nat'),U(S(Z)));
 const type=pi('F',family,pi('x',app(B(0),literal(n)),app(B(1),numeral(n,'Nat'))));
 const value=lam('F',family,lam('x',app(B(0),literal(n)),B(0)));
 define('literal-constructor-conversion-'+n,type,value,true);
 const wrong=lam('F',family,lam('x',app(B(0),literal(n+1)),B(0)));
 define('literal-conversion-wrong-'+n,type,wrong,false);
}
define('literal-is-not-a-function',C('Nat'),app(literal(0),literal(0)),false);
define('literal-is-not-a-type',literal(0),literal(0),false);

const name=x=>x[0]==='anonymous'?{k:'a'}:{k:x[0]==='str'?'s':'n',p:name(x[1]),v:x[2]};
const level=x=>x[0]==='zero'?{k:'z'}:x[0]==='succ'?{k:'s',o:level(x[1])}:x[0]==='param'?{k:'p',n:name(x[1])}:{k:x[0],l:level(x[1]),r:level(x[2])};
function expr(x){switch(x[0]){case'b':return{k:'b',i:Number(x[1])};case'sort':return{k:'sort',l:level(x[1])};case'const':return{k:'const',n:name(x[1]),ls:x[2].map(level)};
 case'nat':return{k:'nat',v:x[1]};case'app':return{k:'app',f:expr(x[1]),a:expr(x[2])};case'lam':case'pi':return{k:x[0]==='lam'?'lam':'forall',n:name(x[1]),bi:'default',t:expr(x[2]),b:expr(x[3])};default:throw Error('UNSUPPORTED_TEST_EXPRESSION');}}
const declaration=d=>d.kind==='nat'?{kind:'inductive',declaration:{lp:[],np:0,ts:[{n:name(d.name),t:expr(d.familyType),cs:[{n:name(d.zeroName),t:expr(d.zeroType)},{n:name(d.succName),t:expr(d.succType)}]}]}}
 :{kind:'constant',declaration:{k:'definition',n:name(d.name),lp:d.parameters.map(name),t:expr(d.type),v:expr(d.value),s:'safe',h:{k:'regular',h:'1'}}};
const records=[];
for(const c of cases){const ours=(c.bootstrap?bootstrap:joint)(c.entries,1000000);if(!['admitted','rejected'].includes(ours.status))throw Error('NONDECISIVE_OWNED_RESULT:'+c.label);
 const request=JSON.stringify({format:'proofscript-checked-admissions',version:2,admissions:c.entries.map(declaration)}),native=call(['--check'],request);
 if(native.accepted!==true&&(native.accepted!==false||native.errorKind!=='kernel-rejection'))throw Error('NONDECISIVE_REFERENCE_RESULT:'+c.label+':'+JSON.stringify(native));
 const record={...c,ours:ours.status,ourError:ours.error??null,steps:ours.steps,native,requestSha256:sha256(request)};
 if(native.accepted!==c.expected||(ours.status==='admitted')!==native.accepted)throw Error('LITERAL_MISMATCH:'+JSON.stringify(record));
 records.push(record);if(records.length%20===0)console.log('LITERAL_DIFFERENTIAL_PROGRESS: '+records.length+'/'+cases.length);}
const recordsPath='dist/evidence/literal-differential-records.json',recordsText=JSON.stringify(records,null,2)+'\n';fs.mkdirSync(path.join(root,'dist/evidence'),{recursive:true});fs.writeFileSync(path.join(root,recordsPath),recordsText);
const report={schemaVersion:1,scope:'Natural literals after owned Nat initialization; exact typing, constructor conversion and dependent recursor iota; not arithmetic primitive completeness; String comparisons belong to TEXT_DIFFERENTIAL',
 sourceManifestSha256:sha256(fs.readFileSync(path.join(root,'manifests/SOURCE.json'))),harnessSha256:sha256(fs.readFileSync(fileURLToPath(import.meta.url))),provider:identity,providerSha256:pin.leanProviderSha256,
 cases:records.length,matched:records.length,accepted:records.filter(x=>x.native.accepted).length,rejected:records.filter(x=>!x.native.accepted).length,
 deliberatelyUnsupported:['Nat arithmetic primitives','unbounded evaluation'],recordsPath,recordsSha256:sha256(recordsText)};
fs.writeFileSync(path.join(root,'manifests/LITERAL_DIFFERENTIAL.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2));
