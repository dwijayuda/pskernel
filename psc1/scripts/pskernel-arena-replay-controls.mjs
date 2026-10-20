import { pathToFileURL } from 'node:url';
import path from 'node:path';
import { parseExactJSON, replayText } from './pskernel-arena-replay.mjs';

if(process.argv.length!==3)throw Error('usage: node pskernel-arena-replay-controls.mjs generated-kernel.js');
const kernel=await import(pathToFileURL(path.resolve(process.argv[2])).href);
const get=name=>{if(!(name in kernel))throw Error('missing export '+name);return kernel[name];};
let passed=0;
const must=(condition,label)=>{if(condition!==true)throw Error('PSC1_ARENA_CONTROL_FAILED '+label);passed++;console.log('PSC1_ARENA_CONTROL_PASS '+label);};
const accepted=result=>{if(result&&typeof result==='object'&&'value' in result)return result.value;throw Error('unexpected control rejection');};
const observe=source=>{try{return replayText(kernel,source);}catch(error){return {verdict:error.verdict||'driver_error',reason:error.message};}};
const exactJSON=value=>{
  if(typeof value==='bigint')return value.toString();
  if(Array.isArray(value))return '['+value.map(exactJSON).join(',')+']';
  if(value&&typeof value==='object')return '{'+Object.entries(value).map(([key,item])=>JSON.stringify(key)+':'+exactJSON(item)).join(',')+'}';
  return JSON.stringify(value);
};
const meta={meta:{exporter:{name:'pskernel-transport-control',version:'3.1.0'},format:{version:'3.1.0'},
  lean:{version:'4.35.0',githash:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc'}}};
const stream=records=>[meta,...records].map(exactJSON).join('\n')+'\n';
const definition=valid=>stream([
  {in:1n,str:{pre:0n,str:'ArenaTransportDefinition'}},{il:1n,succ:0n},
  {ie:0n,sort:0n},{ie:1n,sort:1n},
  {def:{name:1n,levelParams:[],type:valid?1n:0n,value:0n,hints:'abbrev',safety:'safe',all:[1n]}}
]);
must(parseExactJSON('{"value":9007199254740993}').value===9007199254740993n,'JSON integer precision');
let duplicate=false;try{parseExactJSON('{"x":1,"x":2}');}catch(error){duplicate=error.verdict==='malformed';}
must(duplicate,'duplicate JSON key rejected');
const good=observe(definition(true));
must(good.verdict==='accepted'&&good.metadataValidated===true&&good.fuel==='4096','complete declaration admitted with fixed policy');
must(observe(definition(false)).verdict==='rejected','illtyped definition rejected by complete kernel');
const hugeHint=definition(true).replace('"hints":"abbrev"','"hints":{"regular":4294967296}');
must(observe(hugeHint).verdict==='unsupported','reducibility height outside UInt32 profile is explicit');
must(observe(stream([{ie:0n,fvar:0n}])).verdict==='malformed','unsupported fvar wire constructor rejected');
must(observe(stream([{ie:0n,mvar:0n}])).verdict==='malformed','unsupported mvar wire constructor rejected');
must(observe(definition(true)+'\n').verdict==='malformed','extra blank export record rejected');
must(observe(stream([{ie:0n,app:{fn:0n,arg:0n}}])).verdict==='malformed','cyclic expression table rejected');
must(observe(stream([{ie:0n,app:{fn:1n,arg:1n}},{ie:1n,sort:0n}])).verdict==='malformed','forward expression table reference rejected');
must(observe(stream([{il:0n,succ:0n}])).verdict==='malformed','duplicate universe table rejected');
must(observe(stream([{in:0n,str:{pre:0n,str:'duplicate'}}])).verdict==='malformed','duplicate name table rejected');
const unrepresented=definition(true).replace('"all":[1]','"all":[1,1]');
must(observe(unrepresented).verdict==='unsupported','unrepresented all-list does not silently pass');

const N=get('PsKernelName'),L=get('PsKernelLevel'),E=get('PsKernelExpr'),B=get('PsKernelBinderInfo');
const List=get('List'),nil=typeof List.nil==='function'?List.nil():List.nil;
const array=xs=>{const result=[];while(xs&&typeof xs==='object'&&'head' in xs){result.push(xs.head);xs=xs.tail;}return result;};
const n=N.str(N.anonymous,'ArenaTransportEnum'),c=N.str(n,'mk'),r=N.str(n,'rec');
const s1=E.sort(L.succ(L.zero));
const session=accepted(get('psKernelKernelSessionEmpty')(get('psKernelResourcePolicyDefault'),get('psKernelProviderDefault')));
const request=get('PsKernelDeclarationRequest').ordinaryInductive({levelParams:nil,name:n,type:s1,
  ctors:List.cons({name:c,type:E.const(n,nil)},nil),isUnsafe:false,numParams:0n});
const admitted=accepted(get('psKernelV1AdmitDeclaration')(session,request));
const info=name=>accepted(get('psKernelEnvironmentFind')(admitted.session.environment,name)).value;
const induct=info(n),ctor=info(c),rec=info(r);
const records=[],nameIDs=new Map([[N.anonymous,0n]]),levelIDs=new Map([[L.zero,0n]]),exprIDs=new Map();
let nextName=1n,nextLevel=1n,nextExpr=0n;
function nameID(value){
  if(nameIDs.has(value))return nameIDs.get(value);
  if(!value||typeof value!=='object'||!('parent' in value))return 0n;
  const parent=nameID(value.parent),id=nextName++;
  const item=typeof value.value==='string'?{str:{pre:parent,str:value.value}}:{num:{pre:parent,i:value.value}};
  records.push({in:id,...item});nameIDs.set(value,id);return id;
}
const discriminator=(sample,payload)=>{
  const fields=Object.keys(sample).filter(key=>!payload.includes(key));
  if(fields.length!==1)throw Error('unexpected generated constructor discriminator');return fields[0];
};
const levelTag=discriminator(L.succ(L.zero),['of']);
const levelKinds=new Map([
  ['zero',L.zero],['succ',L.succ(L.zero)],['max',L.max(L.zero,L.zero)],
  ['imax',L.imax(L.zero,L.zero)],['param',L.param(N.anonymous)],['mvar',L.mvar(N.anonymous)]
].map(([kind,sample])=>[sample[levelTag],kind]));
function levelID(value){
  if(levelIDs.has(value))return levelIDs.get(value);
  const kind=levelKinds.get(value[levelTag]);let item;
  if(kind==='zero')return 0n;
  if(kind==='succ')item={succ:levelID(value.of)};
  else if(kind==='max'||kind==='imax')item={[kind]:[levelID(value.left),levelID(value.right)]};
  else if(kind==='param')item={param:nameID(value.name)};
  else throw Error('unsupported level in generated control fixture');
  const id=nextLevel++;records.push({il:id,...item});levelIDs.set(value,id);return id;
}
const leaf=E.bvar(0n),exprTag=discriminator(leaf,['index']);
const exprKinds=new Map([
  ['bvar',leaf],['sort',E.sort(L.zero)],['const',E.const(N.anonymous,nil)],['app',E.app(leaf,leaf)],
  ['lam',E.lam(N.anonymous,leaf,leaf,B.default)],['forallE',E.forallE(N.anonymous,leaf,leaf,B.default)],
  ['letE',E.letE(N.anonymous,leaf,leaf,leaf,false)],['mdata',E.mdata(0n,leaf)],
  ['proj',E.proj(N.anonymous,0n,leaf)]
].map(([kind,sample])=>[sample[exprTag],kind]));
function exprID(value){
  if(exprIDs.has(value))return exprIDs.get(value);
  const kind=exprKinds.get(value[exprTag]);let item;
  if(kind==='bvar')item={bvar:value.index};
  else if(kind==='sort')item={sort:levelID(value.level)};
  else if(kind==='const')item={const:{name:nameID(value.name),us:array(value.levels).map(levelID)}};
  else if(kind==='app')item={app:{fn:exprID(value.fn),arg:exprID(value.arg)}};
  else if(kind==='lam'||kind==='forallE'){
    const binder=['default','implicit','strictImplicit','instImplicit'].find(key=>exactJSON(B[key])===exactJSON(value.binderInfo));
    if(!binder)throw Error('unknown generated binder');
    item={[kind]:{name:nameID(value.name),type:exprID(value.type),body:exprID(value.body),binderInfo:binder}};
  }else if(kind==='letE')item={letE:{name:nameID(value.name),type:exprID(value.type),value:exprID(value.value),body:exprID(value.body),nondep:value.nondep}};
  else if(kind==='mdata')item={mdata:{expr:exprID(value.expr),data:{}}};
  else if(kind==='proj')item={proj:{typeName:nameID(value.typeName),idx:value.index,struct:exprID(value.expr)}};
  else throw Error('unsupported expression in generated control fixture');
  const id=nextExpr++;records.push({ie:id,...item});exprIDs.set(value,id);return id;
}
const base=value=>({name:nameID(value.base.name),levelParams:array(value.base.levelParams).map(nameID),type:exprID(value.base.type)});
const group={types:[{...base(induct),numParams:induct.numParams,numIndices:induct.numIndices,
  all:array(induct.all).map(nameID),ctors:array(induct.ctors).map(nameID),numNested:induct.numNested,
  isRec:induct.isRec,isReflexive:induct.isReflexive,isUnsafe:induct.isUnsafe}],
  ctors:[{...base(ctor),induct:nameID(ctor.induct),cidx:ctor.cidx,numParams:ctor.numParams,numFields:ctor.numFields,isUnsafe:ctor.isUnsafe}],
  recs:[{...base(rec),all:array(rec.all).map(nameID),numParams:rec.numParams,numIndices:rec.numIndices,
    numMotives:rec.numMotives,numMinors:rec.numMinors,k:rec.k,isUnsafe:rec.isUnsafe,
    rules:array(rec.rules).map(rule=>({ctor:nameID(rule.ctor),nfields:rule.nFields,rhs:exprID(rule.rhs)}))}]};
const badRhs=exprID(E.sort(L.zero));
const runGroup=value=>observe(stream([...records,{inductive:value}]));
must(runGroup(group).verdict==='accepted','complete regenerated inductive metadata accepted');
const wrongMinor=structuredClone(group);wrongMinor.recs[0].numMinors+=1n;
must(runGroup(wrongMinor).verdict==='rejected','forged recursor minor count rejected');
const wrongRule=structuredClone(group);wrongRule.recs[0].rules[0].rhs=badRhs;
must(runGroup(wrongRule).verdict==='rejected','forged recursor RHS rejected');
const wrongCtor=structuredClone(group);wrongCtor.ctors[0].numFields+=1n;
must(runGroup(wrongCtor).verdict==='rejected','forged constructor field count rejected');
const wrongInduct=structuredClone(group);wrongInduct.types[0].isRec=!wrongInduct.types[0].isRec;
must(runGroup(wrongInduct).verdict==='rejected','forged inductive recursion flag rejected');
console.log('PSC1_ARENA_REPLAY_CONTROLS: PASS count='+passed);
