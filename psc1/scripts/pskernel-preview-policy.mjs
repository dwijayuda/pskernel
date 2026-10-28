import {parseExactJSON} from './pskernel-arena-replay.mjs';

export const TARGET = Object.freeze({version:'4.35.0',githash:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc'});
export class PolicyFailure extends Error {
  constructor(outcome,stage,message,assumptions=[]){super(message);Object.assign(this,{outcome,stage,assumptions});}
}
const malformed=message=>{throw new PolicyFailure('rejectedInvalid','transport',message);};
const object=x=>{if(!x||typeof x!=='object'||Array.isArray(x))malformed('expected object');return x;};
const natural=x=>{if(typeof x!=='bigint'||x<0n)malformed('expected exact nonnegative integer');return x;};
const array=x=>{if(!Array.isArray(x))malformed('expected array');return x;};
const string=x=>{if(typeof x!=='string')malformed('expected string');return x;};
const encode=x=>JSON.stringify(x);
const reference=(table,id)=>{natural(id);if(!table.has(id))malformed('missing or forward table reference');return table.get(id);};
const bind=(table,id,value)=>{natural(id);if(table.has(id))malformed('duplicate table ID');table.set(id,value);};
const nameText=n=>n[0]==='anonymous'?'':n[0]==='str'?[nameText(n[1]),n[2]].filter(Boolean).join('.'):null;

// This scan grants no checking authority. The unchanged adapter still validates
// the entire stream and public V1RunDag still admits every declaration.
export function scanAssumptions(text,pins,onProgress=()=>{}){
  if(pins?.format!=='pskernel-preview-axioms-v1'||pins.leanVersion!==TARGET.version||pins.leanCommit!==TARGET.githash||
    encode(Object.keys(pins.schemas??{}).sort())!==encode(['Classical.choice','Quot.sound','propext'])||!pins.primitives)
    throw Error('invalid pinned assumption policy');
  const names=new Map([[0n,['anonymous']]]),levels=new Map([[0n,['zero']]]),expressions=new Map();
  const assumptions=[],axiomNames=new Set(),primitiveRecords=new Map();let records=0,sawMeta=false;
  function schemaFor(raw){
    const params=array(raw.levelParams).map(x=>reference(names,x));
    if(new Set(params.map(encode)).size!==params.length)malformed('duplicate universe parameter');
    let expanded=0;const active=new Set();
    function level(n,depth){
      if(depth>256)throw new PolicyFailure('resourceExhausted','assumption-policy','universe depth limit',assumptions);
      if(n[0]==='paramName'){
        const index=params.findIndex(p=>encode(p)===encode(n[1]));if(index<0)malformed('undeclared universe parameter');
        return ['param',String(index)];
      }
      return [n[0],...n.slice(1).map(x=>level(x,depth+1))];
    }
    function expr(id,depth=0){
      if(depth>256||++expanded>10000)throw new PolicyFailure('resourceExhausted','assumption-policy','schema structural limit',assumptions);
      if(active.has(id))malformed('cyclic schema type');active.add(id);
      const {kind,raw}=reference(expressions,id);let result;
      if(kind==='bvar')result=['bvar',natural(raw).toString()];
      else if(kind==='sort')result=['sort',level(reference(levels,raw),0)];
      else if(kind==='const'){object(raw);result=['const',reference(names,raw.name),array(raw.us).map(x=>level(reference(levels,x),0))];}
      else if(kind==='app'){object(raw);result=['app',expr(raw.fn,depth+1),expr(raw.arg,depth+1)];}
      else if(kind==='forallE'){object(raw);result=['forallE',expr(raw.type,depth+1),expr(raw.body,depth+1),string(raw.binderInfo)];}
      else throw new PolicyFailure('declinedUnsupported','assumption-policy','nonstandard schema type constructor',assumptions);
      active.delete(id);return result;
    }
    return {universeParameters:String(params.length),type:expr(raw.type)};
  }
  function primitive(kind,raw){
    object(raw);const n=reference(names,raw.name),label=nameText(n);
    if(!label||!Object.hasOwn(pins.primitives,label))return;
    if(primitiveRecords.has(label))malformed('duplicate standard primitive');
    primitiveRecords.set(label,{kind,raw,name:n});
  }
  const lines=text.split(/\r?\n/u);if(lines.at(-1)==='')lines.pop();
  for(const line of lines){
    if(!line.trim())malformed('blank record');
    const r=object(parseExactJSON(line)),keys=Object.keys(r);records++;
    if(records%1024===0)onProgress({stage:'assumption-scan',records,coreInvoked:false});
    if(keys.length===1&&keys[0]==='meta'){
      if(sawMeta||records!==1)malformed('metadata must occur once at beginning');
      object(r.meta);object(r.meta.format);object(r.meta.lean);
      if(r.meta.format.version!=='3.1.0'||r.meta.lean.version!==TARGET.version||r.meta.lean.githash!==TARGET.githash)
        throw new PolicyFailure('declinedUnsupported','target','unsupported export target',assumptions);
      sawMeta=true;continue;
    }
    if(!sawMeta)malformed('missing initial metadata');
    if(Object.hasOwn(r,'in')){
      if(keys.length!==2)malformed('invalid name record');
      if(Object.hasOwn(r,'str')){object(r.str);bind(names,r.in,['str',reference(names,r.str.pre),string(r.str.str)]);}
      else if(Object.hasOwn(r,'num')){object(r.num);bind(names,r.in,['num',reference(names,r.num.pre),natural(r.num.i).toString()]);}
      else malformed('invalid name constructor');
    }else if(Object.hasOwn(r,'il')){
      if(keys.length!==2)malformed('invalid level record');
      const kind=keys.find(k=>k!=='il'),raw=r[kind];let node;
      if(kind==='succ')node=['succ',reference(levels,raw)];
      else if(kind==='param')node=['paramName',reference(names,raw)];
      else if(kind==='max'||kind==='imax'){if(array(raw).length!==2)malformed('level arity');node=[kind,...raw.map(x=>reference(levels,x))];}
      else malformed('invalid level constructor');
      bind(levels,r.il,node);
    }else if(Object.hasOwn(r,'ie')){
      if(keys.length!==2)malformed('invalid expression record');
      const kind=keys.find(k=>k!=='ie');bind(expressions,r.ie,{kind,raw:r[kind]});
    }else{
      if(keys.length!==1)malformed('invalid declaration record');
      const kind=keys[0],raw=object(r[kind]);
      const unsafe=kind==='def'?raw.safety==='unsafe'||raw.safety==='partial':raw.isUnsafe===true||
        (kind==='inductive'&&['types','ctors','recs'].some(k=>array(raw[k]).some(x=>object(x).isUnsafe===true)));
      if(unsafe)throw new PolicyFailure('declinedUnsupported','assumption-policy','unsafe or partial declaration outside strict file profile',assumptions);
      if(kind==='inductive'){
        for(const t of array(raw.types))primitive('inductiveType',t);
        for(const c of array(raw.ctors))primitive('constructor',c);
      }else if(kind==='quot')primitive('quotient',raw);
      else if(Object.hasOwn(raw,'name'))primitive(kind,raw);
      if(kind!=='axiom')continue;
      const name=reference(names,raw.name),label=nameText(name),params=array(raw.levelParams).map(x=>reference(names,x));
      if(raw.isUnsafe!==false)malformed('invalid axiom safety');
      if(axiomNames.has(encode(name)))malformed('duplicate axiom declaration');axiomNames.add(encode(name));
      const inventory={name:label??encode(name),universeParameters:params.length,standardSchema:false};assumptions.push(inventory);
      if(!label||!Object.hasOwn(pins.schemas,label))throw new PolicyFailure('declinedUnsupported','assumption-policy','axiom outside pinned standard schemas',assumptions);
      const pinnedName=label.split('.').reduce((p,s)=>['str',p,s],['anonymous']);
      if(encode(name)!==encode(pinnedName))throw new PolicyFailure('declinedUnsupported','assumption-policy','axiom name segments differ from pinned schema',assumptions);
      const actual=schemaFor(raw);
      if(actual.universeParameters!==pins.schemas[label].universeParameters||encode(actual.type)!==encode(pins.schemas[label].type))
        throw new PolicyFailure('declinedUnsupported','assumption-policy','standard axiom name has altered schema',assumptions);
      inventory.standardSchema=true;
    }
  }
  if(!sawMeta)malformed('missing metadata');
  if(assumptions.length){
    const required=new Set();
    for(const a of assumptions){
      if(a.name==='propext')for(const n of ['Eq','Eq.refl','Iff','Iff.intro'])required.add(n);
      if(a.name==='Classical.choice')for(const n of ['Nonempty','Nonempty.intro'])required.add(n);
      if(a.name==='Quot.sound')for(const n of ['Eq','Eq.refl','Quot','Quot.mk'])required.add(n);
    }
    for(const label of required){
      const p=pins.primitives[label],r=primitiveRecords.get(label);
      if(!p||!r||r.kind!==p.kind||encode(r.name)!==encode(label.split('.').reduce((a,b)=>['str',a,b],['anonymous'])))
        throw new PolicyFailure('declinedUnsupported','assumption-policy','missing or shadowed standard axiom dependency: '+label,assumptions);
      const actual=schemaFor(r.raw);
      if(actual.universeParameters!==p.universeParameters||encode(actual.type)!==encode(p.type))
        throw new PolicyFailure('declinedUnsupported','assumption-policy','altered standard dependency type: '+label,assumptions);
      for(const [key,value]of Object.entries(p)){
        if(['kind','type','universeParameters','fixtureType','fixtureLevelParams'].includes(key))continue;
        const observed=key==='all'||key==='ctors'?array(r.raw[key]).map(x=>reference(names,x)):
          key==='induct'?reference(names,r.raw[key]):typeof value==='string'?natural(r.raw[key]).toString():r.raw[key];
        if(encode(observed)!==encode(value))throw new PolicyFailure('declinedUnsupported','assumption-policy','altered standard dependency metadata: '+label+'.'+key,assumptions);
      }
    }
  }
  return {policy:'pinned-standard-axioms-v1',validated:true,assumptions,records};
}
