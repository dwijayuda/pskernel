// Linux-only hostile, universe and resource probes for the R4B public byte API.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {createRegularCoreIngress,regularIngressLimits} from '../host/ingress.mjs';
assert.equal(process.platform,'linux');assert.match(process.env.GITHUB_SHA||'',/^[a-f0-9]{40}$/);
const dir='dist/pskernel-min/regular-ingress';
const G=await import(pathToFileURL(path.resolve(dir,'vectors.js')).href),check=createRegularCoreIngress(G);
const cases=JSON.parse(fs.readFileSync('scripts/minkernel-regular-ingress-cases.json'));
const clone=()=>JSON.parse(cases[1].source),observations=[],universe=[];
const stable=v=>Array.isArray(v)?v.map(stable):v&&typeof v==='object'
 ?Object.fromEntries(Object.keys(v).sort().map(k=>[k,stable(v[k])])):v;
const nw=text=>text.split('.').reduce((p,v)=>({k:'s',p,v}),{k:'a'});
const cn=(name,levels=[])=>({k:'const',ls:levels.map(n=>n?{k:'s',o:{k:'z'}}:{k:'z'}),n:nw(name)});
const ap=(f,a)=>({a,f,k:'app'}),aps=(f,...args)=>args.reduce(ap,f);
const binder=(k,t,b)=>({b,bi:'default',k,n:nw('x'),t}),arrow=(a,b)=>binder('forall',a,b),lam=(a,b)=>binder('lam',a,b);
const nat=cn('Nat'),falseType=cn('_psc1OrderFalse'),bool=cn('Bool');
const official=source=>{
 const r=spawnSync('.lake/build/bin/psc1_independent_checker',['--check'],
  {input:source,encoding:'utf8',timeout:180000,maxBuffer:4*1024*1024});
 assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+r.stderr);
 return JSON.parse(r.stdout).accepted;
};
function probe(id,packet,expected,compare=false){
 const source=typeof packet==='string'?packet:JSON.stringify(stable(packet));
 const bytes=new Uint8Array(Buffer.from(source)),start=performance.now(),result=check(bytes);
 const row={id,accepted:result.accepted,expected,code:result.code,bytes:bytes.length,elapsedMs:performance.now()-start};
 if(compare){row.official=official(source);assert.ok(!row.accepted||row.official,id+' accepted ill-typed source');}
 observations.push(row);fs.writeFileSync(path.join(dir,'resource-probes.json'),JSON.stringify(observations,null,2)+'\n');
 assert.equal(result.accepted,expected,id+' '+result.code);assert.equal(result.delegated,false,id);
 return row;
}
function typedProbe(id,type,value,expected){
 const p=clone();p.admissions[0].declaration.t=type;p.admissions[0].declaration.v=value;
 universe.push(probe(id,p,expected,true));
}
const falseArrow=arrow(falseType,falseType),identity=lam(falseType,{i:0,k:'b'});
typedProbe('list-proposition',ap(cn('List'),falseType),ap(cn('List.nil'),falseType),false);
typedProbe('option-proposition',ap(cn('Option'),falseType),ap(cn('Option.none'),falseType),false);
typedProbe('list-proposition-arrow',ap(cn('List'),falseArrow),ap(cn('List.nil'),falseArrow),false);
typedProbe('option-type-arrow',ap(cn('Option'),arrow(falseType,nat)),ap(cn('Option.none'),arrow(falseType,nat)),true);
const left=cn('Bool.true'),right=cn('Bool.true'),prop=aps(cn('Eq',[1]),bool,left,right),decision=aps(cn('Bool.decEq'),left,right);
typedProbe('ite-proposition-level-one',falseArrow,aps(cn('ite',[1]),falseArrow,prop,decision,identity,identity),false);
typedProbe('ite-proposition-level-zero',falseArrow,aps(cn('ite',[0]),falseArrow,prop,decision,identity,identity),false);
const enumGroup=name=>({declaration:{lp:[],np:0,ts:[{cs:[{n:nw(name+'.mk'),t:cn(name)}],n:nw(name),t:{k:'sort',l:{k:'s',o:{k:'z'}}}}]},kind:'inductive'});
for(const [level,result,value,expected,id]of [
 [1,falseArrow,identity,false,'recursor-proposition-level-one'],
 [0,falseArrow,identity,false,'recursor-proposition-level-zero'],
 [1,arrow(falseType,nat),lam(falseType,{k:'nat',v:'0'}),true,'recursor-type-arrow']]){
 const p=clone();p.admissions.unshift(enumGroup('Probe'));
 p.admissions[1].declaration.t=result;
 p.admissions[1].declaration.v=aps(cn('Probe.rec',[level]),lam(cn('Probe'),result),value,cn('Probe.mk'));
 universe.push(probe(id,p,expected,true));
}
let p=clone();p.admissions[0].declaration.v.v='65536';probe('maximum-natural',p,true,true);
p=clone();p.admissions[0].declaration.v.v='65537';probe('excess-natural',p,false);
p=clone();p.admissions[0].declaration.h.h='65536';probe('maximum-height',p,true,true);
p=clone();p.admissions[0].declaration.h.h='65537';probe('excess-height',p,false);
for(const [count,expected]of [[512,true],[513,false]]){
 p=clone();const d=p.admissions[0];
 p.admissions=Array.from({length:count},(_,index)=>{const row=JSON.parse(JSON.stringify(d));row.declaration.n=nw('n'+index);return row;});
 probe('definitions-'+count,p,expected,expected);
}
for(const [count,expected]of [[255,true],[256,false]]){
 p=clone();let type=nat,value={k:'nat',v:'0'};
 for(let i=0;i<count;i++){type=arrow(nat,type);value=lam(nat,value);}
 p.admissions[0].declaration.t=type;p.admissions[0].declaration.v=value;
 probe('expression-depth-'+(count+1),p,expected,expected);
}
for(const [components,expected]of [[15,true],[16,false]]){
 p=clone();let name={k:'a'};for(let i=0;i<components;i++)name={k:'s',p:name,v:'a'};
 p.admissions[0].declaration.n=name;probe('name-components-'+components,p,expected,expected);
}
for(const [index,expected]of [[4095,true],[4096,false]]){
 p=clone();p.admissions[0].declaration.n={k:'n',p:{k:'a'},v:String(index)};
 probe('numeric-name-'+index,p,expected,expected);
}
for(const [count,expected]of [[511,true],[512,true],[513,false]]){
 p=clone();const group=enumGroup('Boundary');
 group.declaration.ts[0].cs=Array.from({length:count},(_,i)=>({n:nw('Boundary.c'+i),t:cn('Boundary')}));
 p.admissions=[group];
 probe('constructors-'+count,p,expected,expected);
}
for(const [count,expected]of [[512,true],[513,false]]){
 p=clone();p.admissions=Array.from({length:count},(_,i)=>{const g=enumGroup('E'+i);g.declaration.ts[0].cs=[];return g;});
 probe('empty-groups-'+count,p,expected,expected);
}
p=clone();p.admissions=Array.from({length:512},(_,i)=>{const g=enumGroup('F'+i);g.declaration.ts[0].cs=[];return g;});
p.admissions[0].declaration.ts[0].cs=[{n:nw('F0.mk'),t:arrow(nat,cn('F0'))}];
const exhausted=probe('registry-type-fuel-exhaustion',p,false,true);assert.equal(exhausted.official,true);
probe('exact-byte-ceiling',' '.repeat(regularIngressLimits.bytes),false);
probe('over-byte-ceiling',' '.repeat(regularIngressLimits.bytes+1),false);
fs.writeFileSync(path.join(dir,'source-universe-probes.json'),JSON.stringify(universe,null,2)+'\n');
const receipt={schema:'psc1-min-regular-ingress-resources/1',commit:process.env.GITHUB_SHA,
 observations,universeProbes:universe.length,resourceUsage:process.resourceUsage(),
 oldSpaceMiB:256,boundary:'Observed Linux cases; old-space cap is not total RSS or a complexity theorem.'};
fs.writeFileSync(path.join(dir,'resource-receipt.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_MIN_REGULAR_INGRESS_RESOURCES_PASS '+JSON.stringify({cases:observations.length,universe:universe.length,resourceUsage:receipt.resourceUsage}));
