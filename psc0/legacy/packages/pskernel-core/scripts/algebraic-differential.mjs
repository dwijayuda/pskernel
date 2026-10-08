// Independent reference evidence only; native judgments never enter owned execution.
import fs from 'node:fs';import path from 'node:path';import {spawnSync} from 'node:child_process';import {fileURLToPath} from 'node:url';
import {root,json,sha256,checkedTool} from './source.mjs';import './verify-build.mjs';
import {family,bootstrap,value,eliminate,resultWitness,wireBatch,N,Z,S,U,B,C,app,pi,lam,member,literal,T,d} from '../test/algebraic-values.mjs';
const pin=json(path.join(root,'manifests/TOOLCHAIN.json')),provider=checkedTool(process.env.LEAN_PROVIDER,pin.leanProviderSha256,'LEAN_PROVIDER');
function call(args,input){const p=spawnSync(provider,args,{input,encoding:'utf8',timeout:120000,maxBuffer:16*1024*1024});if(p.error||p.signal||p.status!==0)throw p.error||Error('REFERENCE_PROCESS_FAILED');const r=JSON.parse(p.stdout);if(r.protocol!=='pskernel-lean/1'||r.provider!=='lean4-cpp'||r.leanVersion!==pin.leanVersion||r.leanCommit!==pin.leanCommit||r.profile!=='lean4.34-core')throw Error('REFERENCE_IDENTITY');return r;}
const identity=call(['--version']),cases=[],add=(label,entries,expected)=>cases.push({label,entries,expected}),wit=(term,n)=>{const w=resultWitness(term,n);return d('Witness',w.type,w.value);};
for(const n of [1,2,3]){const ps=Array.from({length:n},()=>C('Nat')),fields=[[],[B(0)],[...Array.from({length:n},(_,i)=>B(n-1-i))]],e=family('Choice',n,fields),ty=app(C('Choice'),...ps),minors=[literal(0),lam('x',C('Nat'),B(0)),fields[2].reduceRight((b,_,i)=>lam('x'+i,C('Nat'),b),B(0))];
 add('family-'+n,[e],true);for(let i=0;i<3;i++){const args=fields[i].map((_,j)=>literal(j+2)),v=value(e,i,ps,args),expected=i===0?0:args.length+1,term=eliminate(e,ps,lam('c',ty,C('Nat')),minors,v);
  add('ctor-'+n+'-'+i,[e,d('Use',ty,v)],true);add('computed-'+n+'-'+i,[e,wit(term,expected)],true);add('wrong-result-'+n+'-'+i,[e,wit(term,expected+1)],false);
  add('bad-minor-'+n+'-'+i,[e,d('Bad',C('Nat'),eliminate(e,ps,lam('c',ty,C('Nat')),minors.map((m,j)=>j===(i+1)%3?U(Z):m),v))],false);
  if(args.length)add('bad-field-'+n+'-'+i,[e,d('Bad',C('Nat'),eliminate(e,ps,lam('c',ty,C('Nat')),minors,value(e,i,ps,[U(Z),...args.slice(1)])))],false);
 }
 for(const name of [e.name,e.constructors[0].name,member('Choice','rec')])add('collision-'+n+'-'+JSON.stringify(name),[{...d('Prior',C('Nat'),literal(0)),name},e],false);
 const dup=structuredClone(e);dup.constructors[1].name=dup.constructors[0].name;add('duplicate-ctor-'+n,[dup],false);
 const result=structuredClone(e);result.constructors[0].type=C('Nat');add('wrong-ctor-result-'+n,[result],false);
 add('duplicate-family-'+n,[e,e],false);
}
const l=family('Seq',1,[[],[B(0),app(C('Seq'),B(0))]]),lt=app(C('Seq'),C('Nat')),nil=value(l,0,[C('Nat')]),cons=(n,t)=>value(l,1,[C('Nat')],[literal(n),t]);
const step=lam('h',C('Nat'),lam('t',lt,lam('ih',C('Nat'),app(C(member('Nat','succ')),B(0)))));
for(const [major,n]of [[nil,0],[cons(2,nil),1],[cons(2,cons(3,nil)),2],[cons(3,cons(2,cons(1,nil))),3]]){const term=eliminate(l,[C('Nat')],lam('s',lt,C('Nat')),[literal(0),step],major);add('list-length-'+n,[l,wit(term,n)],true);add('list-wrong-length-'+n,[l,wit(term,n+1)],false);}
const tr=family('Tree',0,[[],[C('Tree'),C('Tree')]]),leaf=value(tr,0),node=(a,b)=>value(tr,1,[],[a,b]),minor=[['a',C('Tree')],['b',C('Tree')],['iha',C('Nat')],['ihb',C('Nat')]].reduceRight((body,[n,t])=>lam(n,t,body),app(C(member('Nat','succ')),B(0))),treeTerm=eliminate(tr,[],lam('t',C('Tree'),C('Nat')),[literal(0),minor],node(leaf,node(leaf,leaf)));
add('recursive-hypothesis-order',[tr,wit(treeTerm,2)],true);add('wrong-recursive-order',[tr,wit(treeTerm,1)],false);
for(const [label,e]of [['negative-parameter',family('Neg',1,[[pi('a',B(0),C('Nat'))]])],['negative-self',family('Neg',1,[[pi('a',app(C('Neg'),B(0)),C('Nat'))]])],['free-field',family('Neg',1,[[B(1)]])],['unknown-field',family('Neg',1,[[C('Missing')]])]]){if(label==='negative-parameter')continue;add(label,[e],false);}
const o=family('O',1,[[],[B(0)]]),ot=app(C('O'),C('Nat')),ov=value(o,1,[C('Nat')],[literal(2)]),om=lam('o',ot,C('Nat')),os=[literal(0),lam('x',C('Nat'),B(0))];
add('partial-rec',[o,d('Partial',pi('o',ot,C('Nat')),app(C(member('O','rec'),[S(Z)]),C('Nat'),om,...os))],true);
const capture=lam('outer',C('Nat'),eliminate(o,[C('Nat')],om,[B(0),lam('x',C('Nat'),B(1))],ov));add('capture-avoidance',[o,wit(app(capture,literal(3)),3)],true);
const proof=eliminate(o,[C('Nat')],lam('o',ot,B(2)),[B(0),lam('x',C('Nat'),B(1))],ov,Z);add('Prop-elimination',[o,d('Proof',pi('P',U(Z),pi('h',B(0),B(1))),lam('P',U(Z),lam('h',B(0),proof)))],true);
for(const levels of [[],[Z,Z]])add('recursor-universe-arity-'+levels.length,[o,d('Bad',C('Nat'),app(C(member('O','rec'),levels),C('Nat'),om,...os,ov))],false);
for(const type of [C('Nat'),app(C('O'),C('Nat')),pi('a',T,app(C('O'),C('Nat')))])add('malformed-constructor-'+JSON.stringify(type),[{...o,constructors:[{...o.constructors[0],type}]}],false);
const records=[];for(const c of cases){const ours=bootstrap(c.entries,4000000);if(!['admitted','rejected'].includes(ours.status))throw Error('NONDECISIVE_OWNED_RESULT:'+c.label);
 const request=wireBatch(c.entries),native=call(['--check'],request);if(native.accepted!==true&&(native.accepted!==false||native.errorKind!=='kernel-rejection'))throw Error('NONDECISIVE_REFERENCE_RESULT:'+c.label+':'+JSON.stringify(native));
 const r={...c,ours:ours.status,ourError:ours.error??null,steps:ours.steps,native,request,requestSha256:sha256(request)};
 if(c.label==='free-field') {
  if(r.requestSha256!=='ce7311b7515beb593a574c4f55d90ebe11519b30cf3f516ddce36356a69553e2'||ours.status!=='rejected'||ours.error!=='invalidScope'||native.accepted!==true)throw Error('REFERENCE_SCOPE_DISCREPANCY_CHANGED:'+JSON.stringify(r));
  r.classification='reference-boundary-discrepancy';
 } else {
  if(native.accepted!==c.expected||(ours.status==='admitted')!==native.accepted)throw Error('ALGEBRAIC_MISMATCH:'+JSON.stringify(r));
  r.classification='matched';
 }
 records.push(r);if(records.length%10===0)console.log('ALGEBRAIC_DIFFERENTIAL_PROGRESS: '+records.length+'/'+cases.length);
}
const recordsPath='dist/evidence/algebraic-differential-records.json',bytes=JSON.stringify(records,null,2)+'\n';fs.mkdirSync(path.join(root,'dist/evidence'),{recursive:true});fs.writeFileSync(path.join(root,recordsPath),bytes);
const report={schemaVersion:1,scope:'Uniform Type0 algebraic families with type parameters and direct recursion; dependent eliminator types and recursive computation; not nested, indexed, mutual or universe-polymorphic completeness',sourceManifestSha256:sha256(fs.readFileSync(path.join(root,'manifests/SOURCE.json'))),harnessSha256:sha256(fs.readFileSync(fileURLToPath(import.meta.url))),fixtureSha256:sha256(fs.readFileSync(path.join(root,'test/algebraic-values.mjs'))),provider:identity,providerSha256:pin.leanProviderSha256,cases:records.length,comparableCases:records.filter(r=>r.classification==='matched').length,matched:records.filter(r=>r.classification==='matched').length,accepted:records.filter(r=>r.classification==='matched'&&r.native.accepted).length,rejected:records.filter(r=>r.classification==='matched'&&!r.native.accepted).length,referenceBoundaryDiscrepancies:records.filter(r=>r.classification!=='matched').map(r=>({label:r.label,requestSha256:r.requestSha256,ours:r.ours,ourError:r.ourError,native:r.native,note:'The exact constructor has loose bound variables; native raw addDeclCore also accepted it. This is not counted as matching evidence. Owned rejection is retained.'})),deliberatelyUnsupported:['dependent fields','term-valued and universe parameters','indices','nested recursion','mutual families','negative or function-valued parameter uses','Prop and higher-universe families','empty family'],recordsPath,recordsSha256:sha256(bytes)};
fs.writeFileSync(path.join(root,'manifests/ALGEBRAIC_DIFFERENTIAL.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2));
