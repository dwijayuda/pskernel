// Native reference comparisons are test-only; reference answers never enter owned execution.
import fs from 'node:fs';import path from 'node:path';import {spawnSync} from 'node:child_process';import {fileURLToPath} from 'node:url';
import {root,json,sha256,checkedTool} from './source.mjs';import './verify-build.mjs';import {definition} from '../test/unit-values.mjs';import {record,value as recordValue} from '../test/record-values.mjs';import {enumeration} from '../test/enum-values.mjs';
import {sum,bootstrap,value,eliminate,resultWitness,wireBatch,N,Z,S,U,B,C,app,pi,lam,member,literal} from '../test/sum-values.mjs';
const pin=json(path.join(root,'manifests/TOOLCHAIN.json')),provider=checkedTool(process.env.LEAN_PROVIDER,pin.leanProviderSha256,'LEAN_PROVIDER');
function call(args,input){const p=spawnSync(provider,args,{input,encoding:'utf8',timeout:120000,maxBuffer:16*1024*1024});if(p.error||p.signal||p.status!==0)throw p.error||Error('REFERENCE_PROCESS_FAILED');const r=JSON.parse(p.stdout);if(r.protocol!=='pskernel-lean/1'||r.provider!=='lean4-cpp'||r.leanVersion!==pin.leanVersion||r.leanCommit!==pin.leanCommit||r.profile!=='lean4.34-core')throw Error('REFERENCE_IDENTITY');return r;}
const identity=call(['--version']),cases=[],add=(label,entries,expected)=>cases.push({label,entries,expected}),witness=(term,n)=>{const w=resultWitness(term,n);return definition('Witness',[],w.type,w.value);};
for(const widths of [[0,1],[1,0],[1,2,0],[0,3,1,2],[4,0,2]]){
 const fields=widths.map(n=>Array.from({length:n},()=>C('Nat'))),e=sum('Choice',fields),suffix=widths.join('-');add('family-'+suffix,[e],true);
 const minors=fields.map((ts,i)=>ts.reduceRight((b,t,j)=>lam('f'+j,t,b),ts.length?B(0):literal(i+1)));
 for(let i=0;i<widths.length;i++){const args=fields[i].map((_,j)=>literal(j+1)),term=eliminate(e,i,args,minors),expect=widths[i]||i+1;
  add('constructor-'+suffix+'-'+i,[e,definition('Use',[],C(e.name),value(e,i,args))],true);
  add('computed-'+suffix+'-'+i,[e,witness(term,expect)],true);add('wrong-computed-'+suffix+'-'+i,[e,witness(term,expect+1)],false);
  const bad=minors.map((m,j)=>j===(i+1)%minors.length?U(Z):m);add('discarded-minor-'+suffix+'-'+i,[e,definition('Bad',[],C('Nat'),eliminate(e,i,args,bad))],false);
  if(args.length){add('missing-field-'+suffix+'-'+i,[e,definition('Bad',[],C('Nat'),eliminate(e,i,args.slice(1),minors))],false);add('bad-field-'+suffix+'-'+i,[e,definition('Bad',[],C('Nat'),eliminate(e,i,[U(Z),...args.slice(1)],minors))],false);}
 }
 const duplicate=structuredClone(e);duplicate.constructors.at(-1).name=duplicate.constructors[0].name;add('duplicate-ctor-'+suffix,[duplicate],false);
 const result=structuredClone(e);result.constructors.at(-1).type=C('Nat');add('bad-result-'+suffix,[result],false);add('duplicate-family-'+suffix,[e,e],false);
}
const e=sum('Choice',[[C('Nat'),C('Nat')],[]]),minor=lam('a',C('Nat'),lam('b',C('Nat'),B(1))),motive=lam('s',C('Choice'),C('Nat')),fn=C(member('Choice','rec'),[S(Z)]);
add('field-order',[e,witness(eliminate(e,0,[literal(2),literal(3)],[minor,literal(0)]),2)],true);
add('wrong-major',[e,enumeration('Other',2),definition('Bad',[],C('Nat'),app(fn,motive,minor,literal(0),C(member('Other','c0'))))],false);
for(const levels of [[],[Z,Z]])add('wrong-recursor-level-'+levels.length,[e,definition('Bad',[],C('Nat'),app(C(member('Choice','rec'),levels),motive,minor,literal(0),value(e,1)))],false);
for(const name of [N('Choice'),member('Choice','c0'),member('Choice','rec')])add('existing-name-'+JSON.stringify(name),[{...definition('unused',[],C('Nat'),literal(0)),name},e],false);
add('partial-rec',[e,definition('Partial',[],pi('s',C('Choice'),C('Nat')),app(fn,motive,minor,literal(0)))],true);
add('discarded-bad-field',[e,definition('Bad',[],C('Nat'),eliminate(e,0,[literal(2),U(Z)],[minor,literal(0)]))],false);
const small=sum('Small',[[C('Nat')],[]]),smallMinor=lam('n',C('Nat'),B(0)),smallFn=app(C(member('Small','rec'),[S(Z)]),lam('s',C('Small'),C('Nat')),smallMinor,literal(0));
add('alias',[small,definition('Alias',[],C('Small'),value(small,0,[literal(3)])),witness(app(smallFn,C('Alias')),3)],true);
add('let-major',[small,witness(app(smallFn,['let',N('s'),C('Small'),value(small,0,[literal(2)]),B(0)]),2)],true);
const captured=lam('outside',C('Nat'),eliminate(small,0,[literal(3)],[lam('payload',C('Nat'),B(1)),B(0)]));add('capture-avoidance',[small,witness(app(captured,literal(2)),2)],true);
const proof=eliminate(small,0,[literal(2)],[lam('n',C('Nat'),B(1)),B(0)],lam('s',C('Small'),B(2)),Z);add('Prop-elimination',[small,definition('Proof',[],pi('P',U(Z),pi('h',B(0),B(1))),lam('P',U(Z),lam('h',B(0),proof)))],true);
const functionMotive=lam('s',C('Small'),pi('n',C('Nat'),C('Nat'))),functionMinors=[lam('p',C('Nat'),lam('n',C('Nat'),B(1))),lam('n',C('Nat'),B(0))];add('functional-result',[small,witness(app(eliminate(small,0,[literal(2)],functionMinors,functionMotive),literal(3)),2)],true);
const pair=record('Pair',[C('Nat'),C('Nat')]),withPair=sum('WithPair',[[C('Pair')],[]]);add('record-payload',[pair,withPair,witness(eliminate(withPair,0,[recordValue('Pair',[literal(2),literal(3)])],[lam('p',C('Pair'),['proj',N('Pair'),'1',B(0)]),literal(0)]),3)],true);
const withFunction=sum('WithFunction',[[pi('n',C('Nat'),C('Nat'))],[]]);add('function-payload',[withFunction,witness(eliminate(withFunction,0,[lam('n',C('Nat'),B(0))],[lam('f',pi('n',C('Nat'),C('Nat')),app(B(0),literal(2))),literal(0)]),2)],true);
const records=[];for(const c of cases){const ours=bootstrap(c.entries,2000000);if(!['admitted','rejected'].includes(ours.status))throw Error('NONDECISIVE_OWNED_RESULT:'+c.label);
 const request=wireBatch(c.entries),native=call(['--check'],request);if(native.accepted!==true&&(native.accepted!==false||native.errorKind!=='kernel-rejection'))throw Error('NONDECISIVE_REFERENCE_RESULT:'+c.label+':'+JSON.stringify(native));
 const r={...c,ours:ours.status,ourError:ours.error??null,steps:ours.steps,native,request,requestSha256:sha256(request)};
 if(native.accepted!==c.expected||(ours.status==='admitted')!==native.accepted)throw Error('SUM_MISMATCH:'+JSON.stringify(r));records.push(r);if(records.length%10===0)console.log('SUM_DIFFERENTIAL_PROGRESS: '+records.length+'/'+cases.length);
}
const recordsPath='dist/evidence/sum-differential-records.json',bytes=JSON.stringify(records,null,2)+'\n';fs.mkdirSync(path.join(root,'dist/evidence'),{recursive:true});fs.writeFileSync(path.join(root,recordsPath),bytes);
const report={schemaVersion:1,scope:'Closed monomorphic Type-valued payload sums, constructor checks, derived dependent recursor typing and computed iota witnesses; not parameterized/recursive completeness',sourceManifestSha256:sha256(fs.readFileSync(path.join(root,'manifests/SOURCE.json'))),harnessSha256:sha256(fs.readFileSync(fileURLToPath(import.meta.url))),fixtureSha256:sha256(fs.readFileSync(path.join(root,'test/sum-values.mjs'))),provider:identity,providerSha256:pin.leanProviderSha256,cases:records.length,matched:records.length,accepted:records.filter(r=>r.native.accepted).length,rejected:records.filter(r=>!r.native.accepted).length,deliberatelyUnsupported:['dependent fields','term and universe parameters','indices','general recursive families','Prop and higher-universe families','empty family'],recordsPath,recordsSha256:sha256(bytes)};
fs.writeFileSync(path.join(root,'manifests/SUM_DIFFERENTIAL.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2));
