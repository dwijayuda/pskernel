import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import path from 'node:path';

const TARGET = {version:'4.35.0',githash:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc'};
class ReplayFailure extends Error {
  constructor(verdict,stage,message){super(message);this.verdict=verdict;this.stage=stage;}
}
const fail=(verdict,stage,message)=>{throw new ReplayFailure(verdict,stage,message);};
const malformed=message=>fail('malformed','transport',message);
const unsupported=message=>fail('unsupported','transport',message);
const reject=message=>fail('rejected','metadata',message);
const natural=value=>{
  if(typeof value!=='bigint'||value<0n)malformed('expected exact nonnegative integer');
  return value;
};
const string=value=>{if(typeof value!=='string')malformed('expected string');return value;};
const boolean=value=>{if(typeof value!=='boolean')malformed('expected Boolean');return value;};
const object=value=>{
  if(value===null||typeof value!=='object'||Array.isArray(value))malformed('expected object');
  return value;
};
const sequence=value=>{if(!Array.isArray(value))malformed('expected array');return value;};

// JSON.parse rounds numeric literals before its ordinary reviver runs. This
// reader keeps every integer as BigInt and rejects duplicate object keys.
export function parseExactJSON(text){
  let at=0;
  const space=()=>{while(at<text.length&&/[\x20\x09\x0a\x0d]/u.test(text[at]))at++;};
  function quoted(){
    if(text[at]!=='"')malformed('expected JSON string');
    const begin=at++;
    while(at<text.length){
      const ch=text[at++];
      if(ch==='\\'){at++;continue;}
      if(ch==='"'){
        let result;
        try{result=JSON.parse(text.slice(begin,at));}catch{malformed('invalid JSON string');}
        if(/[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?<![\uD800-\uDBFF])[\uDC00-\uDFFF]/u.test(result))
          malformed('unpaired UTF-16 surrogate');
        return result;
      }
    }
    malformed('unterminated JSON string');
  }
  function value(){
    space();
    if(text[at]==='"')return quoted();
    if(text[at]==='{'){
      at++;space();const result=Object.create(null);
      if(text[at]==='}'){at++;return result;}
      for(;;){
        space();const key=quoted();
        if(Object.hasOwn(result,key))malformed('duplicate JSON object key: '+key);
        space();if(text[at++]!==':')malformed('missing JSON colon');
        result[key]=value();space();const delimiter=text[at++];
        if(delimiter==='}')return result;
        if(delimiter!==',')malformed('invalid JSON object delimiter');
      }
    }
    if(text[at]==='['){
      at++;space();const result=[];
      if(text[at]===']'){at++;return result;}
      for(;;){
        result.push(value());space();const delimiter=text[at++];
        if(delimiter===']')return result;
        if(delimiter!==',')malformed('invalid JSON array delimiter');
      }
    }
    for(const [token,result] of [['true',true],['false',false],['null',null]]){
      if(text.startsWith(token,at)){at+=token.length;return result;}
    }
    const match=/^-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?/u.exec(text.slice(at));
    if(!match)malformed('invalid JSON value at '+at);
    at+=match[0].length;
    return /^-?[0-9]+$/u.test(match[0])?BigInt(match[0]):Number(match[0]);
  }
  const result=value();space();
  if(at!==text.length)malformed('trailing JSON input');
  return result;
}

export function replayText(kernel,text){
  const get=name=>{if(!(name in kernel))throw Error('missing generated export '+name);return kernel[name];};
  const N=get('PsKernelName'),L=get('PsKernelLevel'),B=get('PsKernelBinderInfo');
  const S=get('PsKernelDefinitionSafety'),H=get('PsKernelReducibilityHints');
  const D=get('PsKernelDagDeclarationRequest'),C=get('PsKernelDagCommand');
  const CI=get('PsKernelConstantInfo'),Q=get('PsKernelQuotKind'),O=get('PsKernelOutcome');
  const List=get('List'),nil=typeof List.nil==='function'?List.nil():List.nil;
  const list=items=>items.reduceRight((tail,head)=>List.cons(head,tail),nil);
  const array=items=>{const result=[];while(items&&typeof items==='object'&&'head' in items){result.push(items.head);items=items.tail;}return result;};
  const encode=value=>JSON.stringify(value,(_key,item)=>typeof item==='bigint'?item.toString():item);
  const enumEq=(left,right)=>{
    if(left===undefined||right===undefined)throw Error('missing generated enum value');
    return encode(left)===encode(right);
  };
  const nameEq=(left,right)=>get('psKernelNameEq')(left)(right)===true;
  const exprEq=(left,right)=>get('psKernelExprEq')(left)(right)===true;
  const nameListEq=(left,right)=>{
    const a=array(left),b=array(right);
    return a.length===b.length&&a.every((item,index)=>nameEq(item,b[index]));
  };
  function accepted(result,stage){
    if(result&&typeof result==='object'&&'value' in result)return result.value;
    if(result&&typeof result==='object'&&'error' in result){
      if(typeof result.error==='string')fail('malformed',stage,result.error);
      const outcome=get('psKernelErrorOutcome')(result.error);
      const verdict=enumEq(outcome,O.rejectedInvalid)?'rejected':
        enumEq(outcome,O.declinedUnsupported)?'unsupported':
        enumEq(outcome,O.resourceExhausted)?'resource_exhausted':'internal_error';
      fail(verdict,stage,encode(result.error));
    }
    throw Error('invalid generated Except shape at '+stage);
  }
  const sample0=get('PsKernelExpr').sort(L.zero),sample1=get('PsKernelExpr').sort(L.succ(L.zero));
  if(!exprEq(sample0,sample0)||exprEq(sample0,sample1))throw Error('curried expression comparator sentinel failed');
  const names=new Map([[0n,{value:N.anonymous,key:0}]]),levels=new Map([[0n,L.zero]]),expressions=new Map();
  const semanticNames=new Map();let nextName=1;
  const internName=(kind,parent,item)=>{
    const signature=encode([kind,parent.key,item]);
    if(!semanticNames.has(signature))semanticNames.set(signature,nextName++);
    return {key:semanticNames.get(signature),value:kind==='str'?N.str(parent.value,item):N.num(parent.value,item)};
  };
  const lookup=(table,id,kind)=>{
    id=natural(id);if(!table.has(id))malformed('missing or forward '+kind+' table ID '+id);return table.get(id);
  };
  const name=id=>lookup(names,id,'name').value;
  const nameKey=id=>lookup(names,id,'name').key;
  const nameList=ids=>list(sequence(ids).map(name));
  const level=id=>lookup(levels,id,'level');
  const expr=id=>lookup(expressions,id,'expression');
  const bind=(table,id,item,kind)=>{
    id=natural(id);if(table.has(id))malformed('duplicate '+kind+' table ID '+id);table.set(id,item);
  };
  let arena=get('psKernelExprV2PagedEmpty');
  const nodes=new Map(),groups=[],metadata=[],owners=new Map(),pendingMutual=new Map();
  let records=0,sawMeta=false,quotGroup=null,unsafeOrPartial=false,coreInvoked=false;
  const addNode=(kind,args,children=[],constant=null)=>{
    const result=accepted(get('psKernelExprV2PagedMk'+kind)(arena,...args),'construct-expression');
    arena=result.fst;nodes.set(result.snd,{children,constant});return result.snd;
  };
  const base=raw=>({name:name(raw.name),levelParams:nameList(raw.levelParams),type:expr(raw.type)});
  const owning=(group,key)=>{
    if(owners.has(key)&&owners.get(key)!==group)malformed('duplicate declaration name');
    owners.set(key,group);group.names.add(key);
  };
  const newGroup=()=>{const group={names:new Set(),roots:[],request:null};groups.push(group);return group;};
  const canonicalAll=raw=>{
    const all=sequence(raw.all).map(nameKey),key=nameKey(raw.name);
    if(all.length>1||(all.length===1&&all[0]!==key))unsupported('noncanonical exported all-list metadata is not represented by KernelContract-v1');
  };
  const hints=raw=>{
    if(raw==='opaque')return H.opaqueHint;
    if(raw==='abbrev')return H.abbrevHint;
    const height=natural(object(raw).regular);
    if(height>4294967295n)unsupported('reducibility height exceeds the uint32 export profile');
    return H.regular(height);
  };
  const safety=raw=>{
    if(raw==='safe')return S.safe;
    if(raw==='unsafe'){unsafeOrPartial=true;return S.unsafeDef;}
    if(raw==='partial'){unsafeOrPartial=true;return S.partialDef;}
    malformed('unknown definition safety');
  };
  const declared=new Set();
  const claim=(group,raw)=>{
    const key=nameKey(raw.name);
    if(declared.has(key))malformed('duplicate exported declaration name');
    declared.add(key);owning(group,key);
  };
  const metadataEntry=(group,kind,raw)=>{
    object(raw);base(raw);claim(group,raw);metadata.push({group,kind,raw});
    group.roots.push(expr(raw.type));
  };
  const keyList=ids=>sequence(ids).map(nameKey);
  const sameKeys=(left,right)=>left.length===right.length&&left.every((value,index)=>value===right[index]);
  const plainName=value=>internName('str',names.get(0n),value);
  try {
    for(const line of text.split(/\r?\n/u)){
      if(line.trim()==='')continue;
      const record=object(parseExactJSON(line));
      const keys=Object.keys(record);records++;
      if(keys.length===1&&keys[0]==='meta'){
        if(sawMeta||records!==1)malformed('metadata must occur exactly once at the beginning');
        const meta=object(record.meta),source=object(meta.lean),format=object(meta.format),exporter=object(meta.exporter);
        if(string(format.version)!=='3.1.0')unsupported('unsupported lean4export wire format');
        string(exporter.name);string(exporter.version);
        if(source.version!==TARGET.version||source.githash!==TARGET.githash)
          unsupported('Lean source provenance does not match pinned 4.35.0; an explicit external adapter is required');
        sawMeta=true;continue;
      }
      if(!sawMeta)malformed('missing initial metadata');
      if(Object.hasOwn(record,'in')){
        if(keys.length!==2)malformed('invalid name record keys');
        if(Object.hasOwn(record,'str')){
          const raw=object(record.str),parent=lookup(names,raw.pre,'name');
          bind(names,record.in,internName('str',parent,string(raw.str)),'name');
        }else if(Object.hasOwn(record,'num')){
          const raw=object(record.num),parent=lookup(names,raw.pre,'name');
          bind(names,record.in,internName('num',parent,natural(raw.i)),'name');
        }else malformed('unknown name constructor');
        continue;
      }
      if(Object.hasOwn(record,'il')){
        if(keys.length!==2)malformed('invalid universe record keys');
        let value;
        if(Object.hasOwn(record,'succ'))value=L.succ(level(record.succ));
        else if(Object.hasOwn(record,'param'))value=L.param(name(record.param));
        else if(Object.hasOwn(record,'max')||Object.hasOwn(record,'imax')){
          const kind=Object.hasOwn(record,'max')?'max':'imax',args=sequence(record[kind]);
          if(args.length!==2)malformed('universe binary constructor arity');
          value=L[kind](level(args[0]),level(args[1]));
        }else malformed('unknown universe constructor');
        bind(levels,record.il,value,'level');continue;
      }
      if(Object.hasOwn(record,'ie')){
        if(keys.length!==2)malformed('invalid expression record keys');
        const kind=keys.find(key=>key!=='ie'),raw=record[kind];let id;
        if(kind==='bvar')id=addNode('BVar',[natural(raw)]);
        else if(kind==='fvar'||kind==='mvar')id=addNode(kind==='fvar'?'FVar':'MVar',[name(raw)]);
        else if(kind==='sort')id=addNode('Sort',[level(raw)]);
        else if(kind==='const'){
          object(raw);id=addNode('Const',[name(raw.name),list(sequence(raw.us).map(level))],[],nameKey(raw.name));
        }else if(kind==='app'){
          object(raw);const children=[expr(raw.fn),expr(raw.arg)];id=addNode('App',children,children);
        }else if(kind==='lam'||kind==='forallE'){
          object(raw);const children=[expr(raw.type),expr(raw.body)];
          const binder=string(raw.binderInfo);
          if(!['default','implicit','strictImplicit','instImplicit'].includes(binder))malformed('unknown binder info');
          id=addNode(kind==='lam'?'Lam':'Forall',[name(raw.name),...children,B[binder]],children);
        }else if(kind==='letE'){
          object(raw);const children=[expr(raw.type),expr(raw.value),expr(raw.body)];
          id=addNode('Let',[name(raw.name),...children,boolean(raw.nondep)],children);
        }else if(kind==='proj'){
          object(raw);const body=expr(raw.struct);id=addNode('Proj',[name(raw.typeName),natural(raw.idx),body],[body]);
        }else if(kind==='mdata'){
          object(raw);object(raw.data);const body=expr(raw.expr);
          // Lean 4.35 LeanExport.Parse also reconstructs every mdata payload as {}.
          id=addNode('MData',[0n,body],[body]);
        }else if(kind==='natVal'){
          const digits=string(raw);if(!/^[0-9]+$/u.test(digits))malformed('invalid natural literal text');
          id=addNode('Lit',[get('PsKernelLiteral').nat(BigInt(digits))]);
        }else if(kind==='strVal')id=addNode('Lit',[get('PsKernelLiteral').str(string(raw))]);
        else malformed('unknown expression constructor '+kind);
        bind(expressions,record.ie,id,'expression');continue;
      }
      if(keys.length!==1)malformed('invalid declaration record keys');
      const kind=keys[0],raw=object(record[kind]);
      if(kind==='axiom'){
        const group=newGroup();metadataEntry(group,'axiomInfo',raw);
        const isUnsafe=boolean(raw.isUnsafe);unsafeOrPartial ||= isUnsafe;
        group.request=D.axiomDecl(base(raw),isUnsafe);
      }else if(kind==='def'){
        const info={base:base(raw),value:expr(raw.value),hints:hints(raw.hints),safety:safety(raw.safety)};
        let group;
        if(raw.safety==='safe'){
          canonicalAll(raw);group=newGroup();group.request=D.definitionDecl(info);
        }else{
          let all=keyList(raw.all);if(all.length===0)all=[nameKey(raw.name)];
          if(!all.includes(nameKey(raw.name))||new Set(all).size!==all.length)malformed('invalid mutual definition all-list');
          const signature=encode(all);
          if(!pendingMutual.has(signature)){
            const created=newGroup();created.order=all;created.defs=new Map();created.safety=raw.safety;
            pendingMutual.set(signature,created);
            for(const key of all)owning(created,key);
          }
          group=pendingMutual.get(signature);
          if(group.safety!==raw.safety)reject('mutual definitions have inconsistent safety');
          group.defs.set(nameKey(raw.name),info);
        }
        metadataEntry(group,'defnInfo',raw);group.roots.push(info.value);
      }else if(kind==='thm'||kind==='opaque'){
        canonicalAll(raw);const group=newGroup();metadataEntry(group,kind==='thm'?'thmInfo':'opaqueInfo',raw);
        group.roots.push(expr(raw.value));
        if(kind==='thm')group.request=D.theoremDecl(base(raw),expr(raw.value));
        else{
          const isUnsafe=Object.hasOwn(raw,'isUnsafe')?boolean(raw.isUnsafe):false;unsafeOrPartial ||= isUnsafe;
          group.request=D.opaqueDecl(base(raw),expr(raw.value),isUnsafe);
        }
      }else if(kind==='quot'){
        if(!quotGroup){quotGroup=newGroup();quotGroup.request=D.quot;quotGroup.hasType=false;quotGroup.externalKeys=[plainName('Eq').key];}
        if(!['type','ctor','lift','ind'].includes(raw.kind))malformed('unknown quotient kind');
        metadataEntry(quotGroup,'quotInfo',raw);
        if(raw.kind==='type'&&nameKey(raw.name)===plainName('Quot').key)quotGroup.hasType=true;
        const quot=plainName('Quot');owning(quotGroup,quot.key);
        for(const suffix of ['mk','lift','ind'])owning(quotGroup,internName('str',quot,suffix).key);
      }else if(kind==='inductive'){
        const types=sequence(raw.types).map(object),ctors=sequence(raw.ctors).map(object),recs=sequence(raw.recs).map(object);
        if(types.length===0)reject('empty inductive group');
        const group=newGroup(),all=types.map(type=>nameKey(type.name));
        const lparams=keyList(types[0].levelParams),nparams=natural(types[0].numParams),isUnsafe=boolean(types[0].isUnsafe);
        unsafeOrPartial ||= isUnsafe;
        const ctorsByName=new Map();
        for(const ctor of ctors){
          metadataEntry(group,'ctorInfo',ctor);ctorsByName.set(nameKey(ctor.name),ctor);
          unsafeOrPartial ||= boolean(ctor.isUnsafe);
        }
        for(const rec of recs){
          metadataEntry(group,'recInfo',rec);unsafeOrPartial ||= boolean(rec.isUnsafe);
          for(const rule of sequence(rec.rules)){object(rule);group.roots.push(expr(rule.rhs));}
        }
        const usedCtors=new Set(),values=[];let nested=false;
        for(const type of types){
          metadataEntry(group,'inductInfo',type);
          if(!sameKeys(keyList(type.all),all)||!sameKeys(keyList(type.levelParams),lparams)||
              natural(type.numParams)!==nparams||boolean(type.isUnsafe)!==isUnsafe)
            reject('inconsistent mutual inductive metadata');
          nested ||= natural(type.numNested)>0n;
          const selected=[];
          for(const [index,key] of keyList(type.ctors).entries()){
            const ctor=ctorsByName.get(key);
            if(!ctor||usedCtors.has(key))malformed('missing or repeated inductive constructor');
            if(nameKey(ctor.induct)!==nameKey(type.name)||natural(ctor.cidx)!==BigInt(index))reject('constructor owner or index mismatch');
            usedCtors.add(key);selected.push({name:name(ctor.name),type:expr(ctor.type)});
          }
          values.push({name:name(type.name),type:expr(type.type),ctors:list(selected)});
          owning(group,internName('str',lookup(names,type.name,'name'),'rec').key);
        }
        if(usedCtors.size!==ctors.length)reject('unclaimed exported constructor');
        const specification={levelParams:nameList(types[0].levelParams),numParams:nparams,types:list(values),isUnsafe};
        group.request=nested?D.nestedInductive(specification):values.length===1?
          D.ordinaryInductive(specification.levelParams,nparams,values[0],isUnsafe):D.mutualInductive(specification);
      }else unsupported('unsupported declaration record '+kind);
    }
    if(!sawMeta)malformed('missing metadata');
    if(quotGroup&&!quotGroup.hasType)reject('quotient component exported without Quot type declaration');
    for(const group of pendingMutual.values()){
      if(group.order.some(key=>!group.defs.has(key)))malformed('incomplete exported mutual definition group');
      group.request=D.mutualDefinitions(list(group.order.map(key=>group.defs.get(key))));
    }
    // Declaration order is not trusted. Replay dependencies in topological
    // order, grouping mutual declarations and regenerating their auxiliaries.
    for(const group of groups){
      const dependencies=new Set(),seen=new Set(),work=[...group.roots];
      const dependency=key=>{const owner=owners.get(key);if(owner&&owner!==group)dependencies.add(owner);};
      for(const key of group.externalKeys||[])dependency(key);
      while(work.length){
        const id=work.pop();if(seen.has(id))continue;seen.add(id);
        const node=nodes.get(id);if(!node)throw Error('lost canonical expression node');
        if(node.constant!==null)dependency(node.constant);
        for(const child of node.children)work.push(child);
      }
      group.dependencies=[...dependencies];
    }
    const order=[],colour=new Map();
    for(const start of groups){
      if(colour.get(start)===2)continue;
      const stack=[{group:start,next:0}];colour.set(start,1);
      while(stack.length){
        const frame=stack[stack.length-1];
        if(frame.next===frame.group.dependencies.length){
          colour.set(frame.group,2);order.push(frame.group);stack.pop();continue;
        }
        const next=frame.group.dependencies[frame.next++];
        if(colour.get(next)===1)reject('cyclic declaration dependencies outside a mutual declaration');
        if(colour.get(next)!==2){colour.set(next,1);stack.push({group:next,next:0});}
      }
    }
    const policy=get('psKernelResourcePolicyDefault');
    if(policy.fuel!==4096n||policy.maxRecDepth!==0n||policy.maxNatSize!==134217728n||
       policy.maxDeclarations!==0n||policy.cancelled!==false)
      throw Error('published default resource policy changed');
    const provider=get('psKernelProviderDefault');
    if(provider.target.leanVersion!==TARGET.version||provider.target.leanCommit!==TARGET.githash)
      throw Error('generated kernel target identity mismatch');
    const session=accepted(get('psKernelKernelSessionEmpty')(policy,provider),'session');
    const commands=order.map(group=>C.admit(group.request));
    coreInvoked=true;
    const result=accepted(get('psKernelV1RunDag')(session,nil,S.safe,arena,list(commands)),'kernel-admission');
    if(array(result.replies).length!==commands.length)throw Error('incorrect admission batch reply count');
    // Metadata is inspected only after independent V1 admission succeeds.
    // Exported constructor/recursor bodies never enter the environment.
    const decoded=accepted(get('psKernelExprV2DecodeChecked')(arena),'metadata-decode');
    const expectedExpr=id=>accepted(get('psKernelExprV2DecodedRequire')(decoded,expr(id)),'metadata-expression');
    function infoFor(raw,kind){
      const found=get('psKernelEnvironmentFind')(result.session.environment,name(raw.name));
      if(!found||typeof found!=='object'||!('value' in found))reject('missing regenerated '+kind);
      const info=found.value;
      if(!info||typeof info!=='object'||!('value' in info))throw Error('invalid generated ConstantInfo shape');
      const expected=CI[kind](info.value),keys=Object.keys(info);
      if(keys.length!==Object.keys(expected).length||keys.some(key=>info[key]!==expected[key]))
        reject('regenerated constant has wrong kind: '+kind);
      return info.value;
    }
    for(const {kind,raw} of metadata){
      const info=infoFor(raw,kind);
      const ensure=(condition,field)=>{if(condition!==true)reject('metadata mismatch '+kind+'.'+field+' at name table ID '+raw.name);};
      ensure(nameEq(info.base.name,name(raw.name)),'name');
      ensure(nameListEq(info.base.levelParams,nameList(raw.levelParams)),'levelParams');
      ensure(exprEq(info.base.type,expectedExpr(raw.type)),'type');
      if(kind==='axiomInfo')ensure(info.isUnsafe===boolean(raw.isUnsafe),'isUnsafe');
      if(kind==='defnInfo'){
        ensure(exprEq(info.value,expectedExpr(raw.value)),'value');
        ensure(enumEq(info.hints,hints(raw.hints)),'hints');
        ensure(enumEq(info.safety,safety(raw.safety)),'safety');
      }
      if(kind==='thmInfo'||kind==='opaqueInfo')ensure(exprEq(info.value,expectedExpr(raw.value)),'value');
      if(kind==='opaqueInfo')ensure(info.isUnsafe===(Object.hasOwn(raw,'isUnsafe')?boolean(raw.isUnsafe):false),'isUnsafe');
      if(kind==='inductInfo'){
        for(const field of ['numParams','numIndices','numNested'])ensure(info[field]===natural(raw[field]),field);
        for(const field of ['isRec','isReflexive','isUnsafe'])ensure(info[field]===boolean(raw[field]),field);
        ensure(nameListEq(info.all,nameList(raw.all)),'all');
        ensure(nameListEq(info.ctors,nameList(raw.ctors)),'ctors');
      }
      if(kind==='ctorInfo'){
        ensure(nameEq(info.induct,name(raw.induct)),'induct');
        for(const field of ['cidx','numParams','numFields'])ensure(info[field]===natural(raw[field]),field);
        ensure(info.isUnsafe===boolean(raw.isUnsafe),'isUnsafe');
      }
      if(kind==='recInfo'){
        ensure(nameListEq(info.all,nameList(raw.all)),'all');
        for(const field of ['numParams','numIndices','numMotives','numMinors'])ensure(info[field]===natural(raw[field]),field);
        for(const field of ['k','isUnsafe'])ensure(info[field]===boolean(raw[field]),field);
        const rules=array(info.rules),expected=sequence(raw.rules);
        ensure(rules.length===expected.length,'rules.length');
        for(let index=0;index<rules.length;index++){
          const rule=object(expected[index]);
          ensure(nameEq(rules[index].ctor,name(rule.ctor)),'rules.ctor');
          ensure(rules[index].nFields===natural(rule.nfields),'rules.nfields');
          ensure(exprEq(rules[index].rhs,expectedExpr(rule.rhs)),'rules.rhs');
        }
      }
      if(kind==='quotInfo'){
        const kinds={type:Q.typeQ,ctor:Q.ctorQ,lift:Q.liftQ,ind:Q.indQ};
        ensure(enumEq(info.kind,kinds[raw.kind]),'kind');
      }
    }
    const metadataCounts={};
    for(const {kind} of metadata)metadataCounts[kind]=(metadataCounts[kind]||0)+1;
    return {verdict:'accepted',stage:'complete',coreInvoked,records,metadataCounts,
      metadataCoverage:'all supplied exported metadata; absent records are not independently compared',exportedDeclarations:metadata.length,
      admissionCommands:commands.length,arenaNodes:arena.size.toString(),fuel:'4096',
      containsUnsafeOrPartial:unsafeOrPartial,metadataValidated:true,
      officialReplaySkipsUnsafeOrPartial:unsafeOrPartial};
  }catch(error){
    if(error&&typeof error==='object')error.replayStats={coreInvoked,records,exportedDeclarations:metadata.length,
      admissionCommands:groups.length,arenaNodes:arena.size.toString(),fuel:'4096',
      containsUnsafeOrPartial:unsafeOrPartial,metadataValidated:false};
    throw error;
  }
}

export async function replayFile(kernelPath,inputPath){
  let sourceSha256=null;
  try{
    const bytes=readFileSync(inputPath);sourceSha256=createHash('sha256').update(bytes).digest('hex');
    let source;
    try{source=new TextDecoder('utf-8',{fatal:true}).decode(bytes);}
    catch{malformed('input is not valid UTF-8');}
    const kernel=await import(pathToFileURL(path.resolve(kernelPath)).href);
    return {format:'psc1-arena-replay-v1',sourceSha256,...replayText(kernel,source)};
  }catch(error){
    const verdict=error instanceof ReplayFailure?error.verdict:
      error instanceof RangeError?'resource_exhausted':'driver_error';
    return {format:'psc1-arena-replay-v1',sourceSha256,verdict,
      stage:error.stage||(error instanceof RangeError?'host-stack-or-allocation':'driver'),
      reason:String(error.message||error),fuel:'4096',...(error.replayStats||{})};
  }
}

if(process.argv[1]&&pathToFileURL(path.resolve(process.argv[1])).href===import.meta.url){
  if(process.argv.length!==4)throw Error('usage: node pskernel-arena-replay.mjs generated-kernel.js case.ndjson');
  const result=await replayFile(process.argv[2],process.argv[3]);
  console.log('PSC1_ARENA_REPLAY '+JSON.stringify(result));
  process.exitCode=result.verdict==='driver_error'?2:0;
}
