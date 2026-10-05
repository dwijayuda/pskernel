// Actual independent inductive and definition admission. No reference checker is
// imported by the production kernel or used as an acceptance fallback.
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { root, json, sha256, checkedTool } from './source.mjs';
import './verify-build.mjs';
import { N,Z,S,P,U,C,app,lam,ctorName,recName,unit,definition,joint,eliminate } from '../test/unit-values.mjs';
const pin=json(path.join(root,'manifests/TOOLCHAIN.json'));
const provider=checkedTool(process.env.LEAN_PROVIDER,pin.leanProviderSha256,'LEAN_PROVIDER');
function call(args,input){
 const p=spawnSync(provider,args,{input,encoding:'utf8',timeout:120000,maxBuffer:8*1024*1024});
 if(p.error||p.signal||p.status!==0)throw p.error||Error('REFERENCE_PROCESS_FAILED');
 const r=JSON.parse(p.stdout);
 if(r.protocol!=='pskernel-lean/1'||r.provider!=='lean4-cpp'||r.leanVersion!==pin.leanVersion||r.leanCommit!==pin.leanCommit||r.profile!=='lean4.34-core')throw Error('REFERENCE_IDENTITY');
 return r;
}
const identity=call(['--version']),cases=[];
const add=(label,entries,expected)=>cases.push({label,entries,expected});
const levelAt=n=>n===0?Z:S(levelAt(n-1));
add('polymorphic bootstrap unit',[unit('_pscCheckedNestedUnit',['_pscCheckedMotive'],P('_pscCheckedMotive'),{ctorName:['str',N('_pscCheckedNestedUnit'),'unit']})],true);
add('recursor name collision',[unit('OwnedUnit',[],S(Z),{ctorName:recName('OwnedUnit')})],false);
add('family name collision',[unit('OwnedUnit',[],S(Z),{ctorName:N('OwnedUnit')})],false);
add('family duplicate',[unit(),unit()],false);
add('unknown constructor result',[unit('OwnedUnit',[],S(Z),{ctorType:C('Unknown')})],false);
add('wrong constructor result',[unit('Other'),unit('OwnedUnit',[],S(Z),{ctorType:C('Other')})],false);
add('missing constructor universe',[unit('OwnedUnit',['u'],P('u'),{ctorType:C('OwnedUnit')})],false);
add('extra constructor universe',[unit('OwnedUnit',[],S(Z),{ctorType:C('OwnedUnit',[Z])})],false);
add('undeclared family universe',[unit('OwnedUnit',[],P('missing'))],false);
add('undeclared constructor universe',[unit('OwnedUnit',['u'],P('u'),{ctorType:C('OwnedUnit',[P('missing')])})],false);
add('constructor universe mismatch',[unit('OwnedUnit',['u'],P('u'),{ctorType:C('OwnedUnit',[S(P('u'))])})],false);
add('polymorphic iota',[unit('OwnedUnit',['u'],P('u')),definition('Use',['v'],U(S(Z)),eliminate(P('v'),['v']))],true);
add('fresh motive parameter',[unit('OwnedUnit',[['num',N('OwnedUnit'),'0']],P(['num',N('OwnedUnit'),'0']))],true);
for(let i=0;i<24;i++){
 const name='Family'+i,lev=levelAt(i%4),params=i%2?['u']:[],familyLevel=params.length?P('u'):lev;
 const args=params.length?[lev]:[],decl=unit(name,params,familyLevel);
 add('constructor-use-'+i,[decl,definition('Use',[],C(name,args),C(ctorName(name),args))],true);
 const motive=lam('major',C(name,args),U(S(Z))),head=C(recName(name),[S(S(Z)),...args]);
 add('iota-'+i,[decl,definition('Use',[],U(S(Z)),app(head,motive,U(Z),C(ctorName(name),args)))],true);
 add('wrong-minor-'+i,[decl,definition('Bad',[],U(S(Z)),app(head,motive,U(S(Z)),C(ctorName(name),args)))],false);
 add('wrong-major-'+i,[decl,definition('Bad',[],U(S(Z)),app(head,motive,U(Z),U(Z)))],false);
}
const name=x=>x[0]==='anonymous'?{k:'a'}:{k:x[0]==='str'?'s':'n',p:name(x[1]),v:x[2]};
const level=x=>x[0]==='zero'?{k:'z'}:x[0]==='succ'?{k:'s',o:level(x[1])}:x[0]==='param'?{k:'p',n:name(x[1])}:{k:x[0],l:level(x[1]),r:level(x[2])};
function expr(x){switch(x[0]){
 case'b':return{k:'b',i:Number(x[1])};case'sort':return{k:'sort',l:level(x[1])};
 case'const':return{k:'const',n:name(x[1]),ls:x[2].map(level)};
 case'app':return{k:'app',f:expr(x[1]),a:expr(x[2])};
 case'lam':case'pi':return{k:x[0]==='lam'?'lam':'forall',n:name(x[1]),bi:'default',t:expr(x[2]),b:expr(x[3])};
 default:throw Error('UNSUPPORTED_TEST_EXPRESSION');
}}
const declaration=d=>d.kind==='unit'
 ?{kind:'inductive',declaration:{lp:d.parameters.map(name),np:0,ts:[{n:name(d.name),t:{k:'sort',l:level(d.level)},cs:[{n:name(d.ctorName),t:expr(d.ctorType)}]}]}}
 :{kind:'constant',declaration:{k:'definition',n:name(d.name),lp:d.parameters.map(name),t:expr(d.type),v:expr(d.value),s:'safe',h:{k:'regular',h:'1'}}};
const records=[];
for(const c of cases){
 const ours=joint(c.entries,1000000);
 if(!['admitted','rejected'].includes(ours.status))throw Error('NONDECISIVE_OWNED_RESULT:'+c.label);
 const request=JSON.stringify({format:'proofscript-checked-admissions',version:2,admissions:c.entries.map(declaration)});
 const native=call(['--check'],request);
 if(native.accepted!==true&&(native.accepted!==false||native.errorKind!=='kernel-rejection'))throw Error('NONDECISIVE_REFERENCE_RESULT:'+c.label+':'+JSON.stringify(native));
 const record={...c,ours:ours.status,ourError:ours.error??null,steps:ours.steps,native,requestSha256:sha256(request)};
 if(native.accepted!==c.expected||(ours.status==='admitted')!==native.accepted)throw Error('UNIT_MISMATCH:'+JSON.stringify(record));
 records.push(record);if(records.length%20===0)console.log('UNIT_DIFFERENTIAL_PROGRESS: '+records.length+'/'+cases.length);
}
const recordsPath='dist/evidence/unit-differential-records.json',recordsText=JSON.stringify(records,null,2)+'\n';
fs.mkdirSync(path.join(root,'dist/evidence'),{recursive:true});fs.writeFileSync(path.join(root,recordsPath),recordsText);
const report={schemaVersion:1,scope:'Zero-term-parameter singleton unit inductives and derived recursors; not general inductive completeness',
 sourceManifestSha256:sha256(fs.readFileSync(path.join(root,'manifests/SOURCE.json'))),harnessSha256:sha256(fs.readFileSync(fileURLToPath(import.meta.url))),
 provider:identity,providerSha256:pin.leanProviderSha256,cases:records.length,matched:records.length,
 accepted:records.filter(x=>x.native.accepted).length,rejected:records.filter(x=>!x.native.accepted).length,recordsPath,recordsSha256:sha256(recordsText)};
fs.writeFileSync(path.join(root,'manifests/UNIT_DIFFERENTIAL.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2));
