import './verify-build.mjs';
// Test-only reference checker. Does not participate in the installed kernel.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {checkedTool,sourceClosure,verifySource} from './source.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const hash=x=>createHash('sha256').update(x).digest('hex');
const tools=JSON.parse(fs.readFileSync(path.join(root,'manifests/TOOLCHAIN.json'),'utf8'));
const psc=checkedTool(process.env.PSC1,tools.psc1Sha256,'PSC1');
const provider=checkedTool(process.env.LEAN_PROVIDER,tools.leanProviderSha256,'LEAN_PROVIDER');
verifySource(root);
const run=(exe,args,input)=>{const r=spawnSync(exe,args,{cwd:root,input,encoding:'utf8',timeout:180000,maxBuffer:64*1024*1024});if(r.error||r.signal)throw r.error||Error('ORACLE_SIGNAL:'+r.signal);return r;};
const identity=JSON.parse(run(provider,['--version']).stdout);
if(identity.protocol!=='pskernel-lean/1'||identity.provider!=='lean4-cpp'||identity.leanVersion!==tools.leanVersion||identity.leanCommit!==tools.leanCommit)throw Error('ORACLE_IDENTITY');
const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'pskernel-semantic-'));
let base;
try { const src=path.join(tmp,'owned.lean');fs.writeFileSync(src,sourceClosure(root));
const emitted=run(psc,['admissions',src]);if(emitted.status!==0)throw Error(emitted.stderr+emitted.stdout);
base=JSON.parse(emitted.stdout).admissions; } finally { fs.rmSync(tmp,{recursive:true,force:true}); }
const name=s=>s.split('.').reduce((p,v)=>({k:'s',p,v}),{k:'a'});
const C=s=>({k:'const',n:name(s),ls:[]});
const app=(f,...xs)=>xs.reduce((f,a)=>({k:'app',f,a}),f);
const ctor=(t,c,...xs)=>app(C('PsKernel'+t+'.'+c),...xs);
const list=(t,xs)=>xs.reduceRight((r,x)=>ctor('List','cons',t,x,r),ctor('List','nil',t));
const natural=n=>{n=BigInt(n);if(n===0n)return C('PsKernelNatural.zero');const bits=n.toString(2);let p=C('PsKernelPositive.one');for(const b of bits.slice(1))p=ctor('Positive',b==='0'?'bit0':'bit1',p);return ctor('Natural','positive',p);};
const text=s=>[...new TextEncoder().encode(s)].reduceRight((r,b)=>ctor('Text','byte',natural(b),r),C('PsKernelText.empty'));
const ownName=d=>d[0]==='anonymous'?C('PsKernelName.anonymous'):ctor('Name',d[0],ownName(d[1]),d[0]==='str'?text(d[2]):natural(d[2]));
const level=d=>d[0]==='zero'?C('PsKernelLevel.zero'):d[0]==='param'?ctor('Level','param',ownName(Array.isArray(d[1])?d[1]:['str',['anonymous'],d[1]])):d[0]==='succ'?ctor('Level','succ',level(d[1])):ctor('Level',d[0],level(d[1]),level(d[2]));
const expr=d=>{switch(d[0]){
case'b':case'f':return ctor('Expr',d[0]==='b'?'bvar':'fvar',natural(d[1]));
case'sort':return ctor('Expr','sortE',level(d[1]));
case'const':return ctor('Expr','constE',ownName(d[1]),list(C('PsKernelLevel'),d[2].map(level)));
case'app':return ctor('Expr','app',expr(d[1]),expr(d[2]));
case'lam':case'pi':return ctor('Expr',d[0]==='lam'?'lam':'forallE',ownName(d[1]),expr(d[2]),expr(d[3]),C('PsKernelBinder.'+d[4]));
case'let':return ctor('Expr','letE',ownName(d[1]),expr(d[2]),expr(d[3]),expr(d[4]));
case'proj':return ctor('Expr','proj',ownName(d[1]),natural(d[2]),expr(d[3]));
case'nat':case'text':return ctor('Expr','lit',ctor('Literal',d[0]==='nat'?'natural':'text',d[0]==='nat'?natural(d[1]):text(d[1])));
default:throw Error('EXPR_FIXTURE');}};
const mode=d=>d[0]==='closed'?C('PsKernelBindingMode.closed'):ctor('BindingMode',d[0],d[0]==='instantiate'?expr(d[1]):natural(d[1]));
const forall=(n,t,b)=>({k:'forall',n:name(n),bi:'default',t,b});
const b=i=>({k:'b',i});
const defn=(n,t,v)=>({kind:'constant',declaration:{k:'definition',n:name(n),lp:[],t,v,h:{k:'regular',h:'1'},s:'safe'}});
const helper=[];
const fuels=new Map();
const fuel=n=>{if(!fuels.has(n)){let v=C('PsKernelFuel.stop');for(let i=0;i<n;i++)v=ctor('Fuel','more',v);const nme='PsKernelSemanticFuel'+n;helper.push(defn(nme,C('PsKernelFuel'),v));fuels.set(n,C(nme));}return fuels.get(n);};
const equalities=new Map();
function equality(typeName){if(!equalities.has(typeName)){const nme='PsKernelSemanticEqual'+typeName,type=C('PsKernel'+typeName),Eq=C(nme);helper.push({kind:'inductive',declaration:{lp:[],np:1,ts:[{n:name(nme),t:forall('expected',type,forall('actual',type,{k:'sort',l:{k:'z'}})),cs:[{n:name(nme+'.refl'),t:forall('expected',type,app(Eq,b(0),b(0)))}]}]}});equalities.set(typeName,nme);}return equalities.get(typeName);}
let index=0;
function theorem(typeName,expected,actual){const eq=equality(typeName);return{kind:'constant',declaration:{k:'theorem',n:name('PsKernelSemanticCase'+index++),lp:[],t:app(C(eq),expected,actual),v:app(C(eq+'.refl'),expected)}};}
const binding=JSON.parse(fs.readFileSync(path.join(root,'test/binding-cases.json'),'utf8'));
const universes=JSON.parse(fs.readFileSync(path.join(root,'test/universe-cases.json'),'utf8'));
const positive=[];
for(const c of binding){const actual=app(C('psKernelBindingRun'),fuel(c.fuel),app(C('psKernelBindingStart'),mode(c.mode),natural(c.depth),expr(c.input)));const expected=c.status==='done'?ctor('BindingResult','done',expr(c.expected)):C('PsKernelBindingResult.'+c.status);positive.push(theorem('BindingResult',expected,actual));}
for(const c of universes)positive.push(theorem('UniverseResult',ctor('UniverseResult','done',level(c.expected)),app(C('psKernelUniverseRun'),fuel(c.fuel),app(C('psKernelUniverseStart'),level(c.input)))));
const numeric=[[0n,0n],[1n,1n],[9007199254740993n,9007199254740993n],[(1n<<256n)-1n,1n]];
for(const [a,b]of numeric)positive.push(theorem('NumericResult',ctor('NumericResult','sum',natural(a+b)),app(C('psKernelNumericRun'),fuel(1024),ctor('NumericState','add',natural(a),natural(b),C('PsKernelBit.zero'),list(C('PsKernelBit'),[])))));
const u=['param',['str',['anonymous'],'u']],v=['param',['str',['anonymous'],'v']];
for(const [a,b,e]of [[['max',u,v],['max',v,u],'equal'],[u,['succ',u],'different'],[['imax',u,['zero']],['zero'],'equal']])positive.push(theorem('LevelCheckResult',C('PsKernelLevelCheckResult.'+e),app(C('psKernelLevelCheckRun'),fuel(1024),app(C('psKernelLevelCheckStart'),level(a),level(b)))));
const wrong=[];
// Universe instantiation is a prerequisite for polymorphic declaration checking.
// These ground equalities run the owned source in the pinned reference kernel.
const iz=['zero'], inu=['str',['anonymous'],'u'], inv=['str',['anonymous'],'v'];
const ip=n=>['param',n], is=l=>['succ',l];
const instantiate=(names,levels,target,budget=1024)=>app(C('psKernelLevelInstantiateRun'),fuel(budget),
  app(C('psKernelLevelInstantiateStart'),list(C('PsKernelName'),names.map(ownName)),list(C('PsKernelLevel'),levels.map(level)),level(target)));
for(const [names,levels,target,status,expected,budget] of [
  [[inu,inv],[ip(inv),is(iz)],['max',ip(inu),ip(inv)],'done',['max',ip(inv),is(iz)],1024],
  [[inu],[is(iz)],['imax',is(ip(inu)),iz],'done',['imax',is(is(iz)),iz],1024],
  [[inu,inu],[iz,iz],iz,'invalidParameters',null,1024],
  [[inu],[],iz,'invalidParameters',null,1024],
  [[],[],ip(inu),'undeclaredParameter',null,1024],
  [[inu],[iz],ip(inu),'outOfFuel',null,0],
]) positive.push(theorem('LevelInstantiateResult',status==='done'?ctor('LevelInstantiateResult','done',level(expected)):C('PsKernelLevelInstantiateResult.'+status),instantiate(names,levels,target,budget)));
wrong.push({label:'universe-substitution-must-be-simultaneous',decl:theorem('LevelInstantiateResult',ctor('LevelInstantiateResult','done',level(is(iz))),instantiate([inu,inv],[ip(inv),is(iz)],ip(inu)))});
wrong.push({label:'universe-arity-mismatch-cannot-accept',decl:theorem('LevelInstantiateResult',ctor('LevelInstantiateResult','done',level(iz)),instantiate([inu],[],iz))});
const ieName=['str',['anonymous'],'F'];
const instantiateExpr=target=>app(C('psKernelExprInstantiateRun'),fuel(1024),
  app(C('psKernelExprInstantiateStart'),list(C('PsKernelName'),[ownName(inu),ownName(inv)]),
    list(C('PsKernelLevel'),[level(ip(inv)),level(is(iz))]),expr(target)));
const expressionCases=[
  [['sort',ip(inu)],['sort',ip(inv)]],
  [['const',ieName,[ip(inv),ip(inu)]],['const',ieName,[is(iz),ip(inv)]]],
  [['lam',inu,['sort',ip(inu)],['b','0'],'strictImplicit'],['lam',inu,['sort',ip(inv)],['b','0'],'strictImplicit']],
  [['pi',inu,['sort',ip(inv)],['sort',ip(inu)],'instanceImplicit'],['pi',inu,['sort',is(iz)],['sort',ip(inv)],'instanceImplicit']],
  [['let',inu,['sort',ip(inu)],['sort',ip(inv)],['b','0']],['let',inu,['sort',ip(inv)],['sort',is(iz)],['b','0']]],
  [['proj',ieName,'0',['const',ieName,[ip(inu)]]],['proj',ieName,'0',['const',ieName,[ip(inv)]]]],
];
for(const [input,expected]of expressionCases)positive.push(theorem('ExprInstantiateResult',ctor('ExprInstantiateResult','done',expr(expected)),instantiateExpr(input)));
wrong.push({label:'constant-universe-order-must-be-preserved',decl:theorem('ExprInstantiateResult',
  ctor('ExprInstantiateResult','done',expr(['const',ieName,[ip(inv),is(iz)]])),instantiateExpr(['const',ieName,[ip(inv),ip(inu)]]))});
const capture=binding.find(x=>x.label==='substitute-avoids-capture');
wrong.push({label:'capture-avoidance',decl:theorem('BindingResult',ctor('BindingResult','done',expr(['lam',['str',['anonymous'],'x'],['sort',['zero']],['b','0'],'explicit'])),app(C('psKernelBindingRun'),fuel(capture.fuel),app(C('psKernelBindingStart'),mode(capture.mode),natural(0),expr(capture.input))))});
wrong.push({label:'imax-right-zero',decl:theorem('UniverseResult',ctor('UniverseResult','done',level(u)),app(C('psKernelUniverseRun'),fuel(1024),app(C('psKernelUniverseStart'),level(['imax',u,['zero']]))))});
wrong.push({label:'rounded-natural',decl:theorem('NumericResult',ctor('NumericResult','sum',natural(18014398509481984n)),app(C('psKernelNumericRun'),fuel(1024),ctor('NumericState','add',natural(9007199254740993n),natural(9007199254740993n),C('PsKernelBit.zero'),list(C('PsKernelBit'),[]))))});
function sorted(x){if(Array.isArray(x))return x.map(sorted);if(x&&typeof x==='object')return Object.fromEntries(Object.keys(x).sort().map(k=>[k,sorted(x[k])]));return x;}
const request=decls=>JSON.stringify(sorted({format:'proofscript-checked-admissions',version:2,admissions:[...base,...helper,...decls]}));
const check=req=>{const r=run(provider,['--check'],req);let result;try{result=JSON.parse(r.stdout);}catch{throw Error('Oracle protocol failure: '+r.stderr);} if(result.protocol!=='pskernel-lean/1'||result.provider!=='lean4-cpp'||result.leanVersion!==tools.leanVersion||result.leanCommit!==tools.leanCommit||result.profile!=='lean4.34-core')throw Error('ORACLE_RESPONSE_IDENTITY');return result;};
const positiveRequest=request(positive); if (process.env.ORACLE_DEBUG_REQUEST) fs.writeFileSync(process.env.ORACLE_DEBUG_REQUEST,positiveRequest); const pos=check(positiveRequest);if(pos.accepted!==true)throw Error('SEMANTIC_POSITIVE '+JSON.stringify(pos));
const negatives=[];
for(const {label,decl}of wrong){const req=request([decl]),result=check(req);if(result.accepted!==false||result.errorKind!=='kernel-rejection'||result.declarationIndex!==base.length+helper.length)throw Error('NEGATIVE_NOT_REACHED '+label+' '+JSON.stringify(result));negatives.push({label,requestSha256:hash(req),result});}
const record={schemaVersion:1,scope:'Bounded ground computations, not general correctness, full compatibility or independent proof checking',provider:identity,providerSha256:tools.leanProviderSha256,sourceManifestSha256:hash(fs.readFileSync(path.join(root,'manifests/SOURCE.json'))),harnessSha256:hash(fs.readFileSync(fileURLToPath(import.meta.url))),fixtureSha256:{binding:hash(fs.readFileSync(path.join(root,'test/binding-cases.json'))),universes:hash(fs.readFileSync(path.join(root,'test/universe-cases.json')))},positiveCases:positive.length,positiveRequestSha256:hash(positiveRequest),positive:pos,negativeControls:negatives};
fs.writeFileSync(path.join(root,'manifests/SEMANTIC_ORACLE.json'),JSON.stringify(record,null,2)+'\n');console.log(JSON.stringify(record,null,2));
