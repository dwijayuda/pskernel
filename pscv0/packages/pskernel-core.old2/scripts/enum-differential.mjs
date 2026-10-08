// Bounded native comparisons. Reference results never enter the owned implementation.
import fs from 'node:fs';import path from 'node:path';import {spawnSync} from 'node:child_process';import {fileURLToPath} from 'node:url';
import {root,json,sha256,checkedTool} from './source.mjs';import './verify-build.mjs';
import {definition} from '../test/unit-values.mjs';
import {enumeration,bootstrap,eliminate,resultWitness,wireBatch,N,Z,S,U,B,C,app,pi,lam,member,literal} from '../test/enum-values.mjs';
const pin=json(path.join(root,'manifests/TOOLCHAIN.json')),provider=checkedTool(process.env.LEAN_PROVIDER,pin.leanProviderSha256,'LEAN_PROVIDER');
function call(args,input){const p=spawnSync(provider,args,{input,encoding:'utf8',timeout:120000,maxBuffer:16*1024*1024});if(p.error||p.signal||p.status!==0)throw p.error||Error('REFERENCE_PROCESS_FAILED');const r=JSON.parse(p.stdout);if(r.protocol!=='pskernel-lean/1'||r.provider!=='lean4-cpp'||r.leanVersion!==pin.leanVersion||r.leanCommit!==pin.leanCommit||r.profile!=='lean4.34-core')throw Error('REFERENCE_IDENTITY');return r;}
const identity=call(['--version']),cases=[],add=(label,entries,expected)=>cases.push({label,entries,expected}),witness=(term,n)=>{const w=resultWitness(term,n);return definition('Witness',[],w.type,w.value);};
for(const count of [2,3,6,8]){
 const e=enumeration('E',count);add('family-'+count,[e],true);
 for(let i=0;i<count;i++){
  add('constructor-'+count+'-'+i,[e,definition('Use',[],C('E'),C(e.constructors[i].name))],true);
  add('computed-'+count+'-'+i,[e,witness(eliminate(e,i),i+1)],true);
  add('wrong-result-'+count+'-'+i,[e,witness(eliminate(e,i),i+2)],false);
  const minors=e.constructors.map((_,j)=>j===(i+1)%count?U(Z):literal(j+1));add('discarded-bad-minor-'+count+'-'+i,[e,definition('Bad',[],C('Nat'),eliminate(e,i,minors))],false);
 }
 const collision=structuredClone(e);collision.constructors[count-1].name=collision.constructors[0].name;add('duplicate-ctor-'+count,[collision],false);
 const result=structuredClone(e);result.constructors[count-1].type=C('Nat');add('wrong-ctor-result-'+count,[result],false);
 const levels=structuredClone(e);levels.constructors[count-1].type=C('E',[Z]);add('wrong-ctor-level-'+count,[levels],false);
 add('duplicate-family-'+count,[e,e],false);
}
const e=enumeration('E',2),fn=C(member('E','rec'),[S(Z)]),motive=lam('major',C('E'),C('Nat'));
for(const name of [N('E'),member('E','c0'),member('E','rec')])add('existing-name-'+JSON.stringify(name),[{...definition('unused',[],C('Nat'),literal(0)),name},e],false);
add('wrong-major',[e,enumeration('Other',2),definition('Bad',[],C('Nat'),app(fn,motive,literal(1),literal(2),C(member('Other','c0'))))],false);
add('extra-argument',[e,definition('Bad',[],C('Nat'),app(eliminate(e,0),literal(0)))],false);
for(const levels of [[],[Z,Z]])add('recursor-universe-'+levels.length,[e,definition('Bad',[],C('Nat'),app(C(member('E','rec'),levels),motive,literal(1),literal(2),C(e.constructors[0].name)))],false);
add('alias-major',[e,definition('Alias',[],C('E'),C(e.constructors[1].name)),witness(app(fn,motive,literal(1),literal(2),C('Alias')),2)],true);
add('partial-rec',[e,definition('Partial',[],pi('e',C('E'),C('Nat')),app(fn,motive,literal(1),literal(2)))],true);
const captured=lam('n',C('Nat'),lam('m',C('Nat'),eliminate(e,0,[B(1),B(0)])));add('capture-avoidance',[e,witness(app(captured,literal(7),literal(11)),7)],true);
const propTerm=eliminate(e,1,[B(0),B(0)],lam('major',C('E'),B(2)),Z);add('Prop-elimination',[e,definition('Proof',[],pi('P',U(Z),pi('h',B(0),B(1))),lam('P',U(Z),lam('h',B(0),propTerm)))],true);
const functionMotive=lam('e',C('E'),pi('n',C('Nat'),C('Nat'))),functionBranches=[lam('n',C('Nat'),B(0)),lam('n',C('Nat'),literal(0))];
add('function-result',[e,witness(app(eliminate(e,0,functionBranches,functionMotive),literal(7)),7)],true);
const a=N('Name.Child'),b=['str',N('Name'),'Child'];add('full-names',[enumeration(a,2),enumeration(b,2)],true);
const records=[];for(const c of cases){const ours=bootstrap(c.entries,1000000);if(!['admitted','rejected'].includes(ours.status))throw Error('NONDECISIVE_OWNED_RESULT:'+c.label);
 const request=wireBatch(c.entries),native=call(['--check'],request);if(native.accepted!==true&&(native.accepted!==false||native.errorKind!=='kernel-rejection'))throw Error('NONDECISIVE_REFERENCE_RESULT:'+c.label+':'+JSON.stringify(native));
 const r={...c,ours:ours.status,ourError:ours.error??null,steps:ours.steps,native,request,requestSha256:sha256(request)};
 if(native.accepted!==c.expected||(ours.status==='admitted')!==native.accepted)throw Error('ENUM_MISMATCH:'+JSON.stringify(r));records.push(r);if(records.length%10===0)console.log('ENUM_DIFFERENTIAL_PROGRESS: '+records.length+'/'+cases.length);
}
const recordsPath='dist/evidence/enum-differential-records.json',bytes=JSON.stringify(records,null,2)+'\n';fs.mkdirSync(path.join(root,'dist/evidence'),{recursive:true});fs.writeFileSync(path.join(root,recordsPath),bytes);
const report={schemaVersion:1,scope:'Monomorphic Type-valued nullary enumerations, freshness, derived dependent recursor typing and computed iota witnesses; not general sum/recursive completeness',sourceManifestSha256:sha256(fs.readFileSync(path.join(root,'manifests/SOURCE.json'))),harnessSha256:sha256(fs.readFileSync(fileURLToPath(import.meta.url))),fixtureSha256:sha256(fs.readFileSync(path.join(root,'test/enum-values.mjs'))),provider:identity,providerSha256:pin.leanProviderSha256,cases:records.length,matched:records.length,accepted:records.filter(r=>r.native.accepted).length,rejected:records.filter(r=>!r.native.accepted).length,deliberatelyUnsupported:['constructor fields','term and universe parameters','indices','recursive families','Prop and higher-universe families','empty enumeration'],recordsPath,recordsSha256:sha256(bytes)};
fs.writeFileSync(path.join(root,'manifests/ENUM_DIFFERENTIAL.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2));
