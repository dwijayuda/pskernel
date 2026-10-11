// PSCV0 v7 generated-source AST -> retained PSC0 compiler source-AST transport.
// This is a CLOSED, versioned *untrusted syntax* boundary, not a kernel API.
// Independent per-bundle symbols and constructors are never shared or spoofed.
import { createHash } from 'node:crypto';

export const AST_ABI_VERSION='psc0-pscv0-source-ast-transport/1';
export const V7_REFERENCE_SHA='843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5';
const list=of=>({kind:'list',of});
const option=of=>({kind:'option',of});
const pair=(fst,snd)=>({kind:'pair',fst,snd});
const BT=pair('PsSyntaxBinderHead','PsSyntaxTerm');
const struct={
  PsSourcePos:{byteOffset:'nat',line:'nat',column:'nat'},
  PsSourceSpan:{start:'PsSourcePos',stop:'PsSourcePos'},
  PsSyntaxName:{segments:list('string'),span:'PsSourceSpan'},
  PsSyntaxBinderHead:{name:'PsSyntaxName',kind:'PsSyntaxBinderKind',span:'PsSourceSpan'},
  PsSyntaxInductiveConstructor:{name:'PsSyntaxName',fields:list(BT),span:'PsSourceSpan'},
  PsSyntaxImport:{moduleName:'PsSyntaxName',span:'PsSourceSpan'},
  PsSyntaxModule:{imports:list('PsSyntaxImport'),declarations:list('PsSyntaxDeclaration')}
};
const variant={
  PsSyntaxBinderKind:{explicit:{},implicit:{},strictImplicit:{},instanceImplicit:{}},
  PsSyntaxPattern:{
    bool:{value:'bool',span:'PsSourceSpan'},wildcard:{span:'PsSourceSpan'},
    constructor:{name:'PsSyntaxName',binders:list('PsSyntaxName'),span:'PsSourceSpan'}
  },
  PsSyntaxTerm:{
    reference:{name:'PsSyntaxName'},
    natural:{text:'string',span:'PsSourceSpan'},
    string:{text:'string',span:'PsSourceSpan'},
    character:{text:'string',span:'PsSourceSpan'},
    bool:{value:'bool',span:'PsSourceSpan'},
    unit:{span:'PsSourceSpan'},
    record:{fields:list(pair('PsSyntaxName','PsSyntaxTerm')),span:'PsSourceSpan'},
    app:{fn:'PsSyntaxTerm',args:list('PsSyntaxTerm'),span:'PsSourceSpan'},
    lambda:{binders:list(BT),body:'PsSyntaxTerm',span:'PsSourceSpan'},
    forallE:{binders:list(BT),body:'PsSyntaxTerm',span:'PsSourceSpan'},
    letE:{name:'PsSyntaxName',type:option('PsSyntaxTerm'),value:'PsSyntaxTerm',
      body:'PsSyntaxTerm',span:'PsSourceSpan'},
    ifE:{condition:'PsSyntaxTerm',thenBranch:'PsSyntaxTerm',elseBranch:'PsSyntaxTerm',span:'PsSourceSpan'},
    matchE:{scrutinee:'PsSyntaxTerm',
      alternatives:list(pair('PsSyntaxPattern',pair('PsSyntaxTerm','PsSourceSpan'))),span:'PsSourceSpan'}
  },
  PsSyntaxDeclaration:{
    definition:{name:'PsSyntaxName',binders:list(BT),
      type:'PsSyntaxTerm',value:'PsSyntaxTerm',span:'PsSourceSpan'},
    partialDefinition:{name:'PsSyntaxName',binders:list(BT),
      type:'PsSyntaxTerm',value:'PsSyntaxTerm',span:'PsSourceSpan'},
    theoremDecl:{name:'PsSyntaxName',binders:list(BT),
      type:'PsSyntaxTerm',value:'PsSyntaxTerm',span:'PsSourceSpan'},
    inductiveDecl:{name:'PsSyntaxName',params:list(BT),resultType:option('PsSyntaxTerm'),
      constructors:list('PsSyntaxInductiveConstructor'),span:'PsSourceSpan'},
    structureDecl:{name:'PsSyntaxName',params:list(BT),fields:list(BT),span:'PsSourceSpan'}
  }
};
const kinds={List:{nil:{},cons:{head:true,tail:true}},
  Option:{none:{},some:{value:true}},...variant};
function refuse(path,reason){throw Error('PSCV0_AST_ABI_INVALID '+path+': '+reason);}
function record(v,path){
  if(v===null||typeof v!=='object'||Array.isArray(v)||
    (Object.getPrototypeOf(v)!==Object.prototype&&Object.getPrototypeOf(v)!==null))
    refuse(path,'expected an ordinary data record');
}
function fieldSet(v,fields,path){
  record(v,path);
  const actual=Object.keys(v).sort(),want=[...fields].sort();
  if(JSON.stringify(actual)!==JSON.stringify(want))
    refuse(path,'field names do not match closed AST schema');
  for(const k of actual){
    const d=Object.getOwnPropertyDescriptor(v,k);
    if(!d||!Object.hasOwn(d,'value'))
      refuse(path+'.'+k,'data field must not be an accessor');
  }
}
function instance(mod,type,name){
  const ctor=mod[type]?.[name];
  if(ctor===undefined)refuse(type+'.'+name,'factory not exported');
  return typeof ctor==='function'?ctor(...Object.keys(kinds[type][name]).map(()=>undefined)):ctor;
}
function tagFor(mod,type){
  const first=Object.keys(kinds[type])[0];
  const x=instance(mod,type,first);
  record(x,type);
  const syms=Object.getOwnPropertySymbols(x).filter(s=>s.description==='ProofScript.'+type+'.tag');
  if(syms.length!==1||x[syms[0]]!==first)
    refuse(type,'cannot extract the bundle-local constructor tag');
  return syms[0];
}
function verifiedTag(v,symbol,kind,path){
  record(v,path);
  const syms=Object.getOwnPropertySymbols(v);
  if(syms.length!==1||syms[0]!==symbol||v[symbol]!==kind)
    refuse(path,'source constructor tag does not belong to this bundle');
  const property=Object.getOwnPropertyDescriptor(v,symbol);
  if(!property||!Object.hasOwn(property,'value'))refuse(path,'getter-backed tag prohibited');
}
function verifiedBrand(v,type,path){
  record(v,path);
  const syms=Object.getOwnPropertySymbols(v);
  if(syms.length!==1||syms[0].description!=='ProofScript.'+type||
    v[syms[0]]!==true||!Object.hasOwn(Object.getOwnPropertyDescriptor(v,syms[0]),'value'))
    refuse(path,'invalid '+type+' source structure brand');
}
function closedAbi(B,C){
  const tags={};
  for(const [type,constructors] of Object.entries(kinds)){
    const wanted=Object.keys(constructors).sort();
    for(const [role,mod] of [['generated',B],['retained',C]]){
      if(JSON.stringify(Object.keys(mod[type]||{}).sort())!==JSON.stringify(wanted))
        refuse(type,role+' implementation no longer matches versioned constructor schema');
    }
    tags[type]={source:tagFor(B,type),recipient:tagFor(C,type)};
    if(tags[type].source===tags[type].recipient)
      refuse(type,'expected independent generated and retained symbols');
  }
  return tags;
}
/**
 * Rebuild the externally parsed source module as recipient-owned ADTs.
 * Constructor tags are verified by identity with the actual generated bundle,
 * NOT guessed from Symbol descriptions. All records have closed field sets.
 * Structure brands are checked and omitted in the wire representation because
 * recipient runtime code reads their fields (never uses brands as a trust token).
 */
export function transferPscv0Ast(B,C,module,sourceText){
  if(typeof sourceText!=='string'||Buffer.byteLength(sourceText,'utf8')>1048576)
    refuse('source','source not provided or source byte budget exceeded');
  if(B.psPscv0ReferenceSha256!==V7_REFERENCE_SHA||
     B.psPscv0LanguageEdition!=='pscv0')
    refuse('reference','source runtime does not match sole PSCV0 v7 authority');
  const tags=closedAbi(B,C);
  const byteLength=Buffer.byteLength(sourceText,'utf8');
  let budget=200000,depth=0,nodes=0;
  const descend=(path)=>{
    if(--budget<0||++depth>512)refuse(path,'AST resource budget exceeded');
    nodes++;
  };
  const decode=(type,v,path)=>{
    descend(path);
    try {
      if(typeof type==='string'){
        if(type==='string'){
          if(typeof v!=='string'||Buffer.byteLength(v,'utf8')>1048576)
            refuse(path,'invalid bounded string');
          return v;
        }
        if(type==='bool'){
          if(typeof v!=='boolean')refuse(path,'not a boolean');
          return v;
        }
        if(type==='nat'){
          if(typeof v!=='bigint'||v<0n)refuse(path,'not a Nat bigint');
          return v;
        }
        if(variant[type]){
          record(v,path);
          const kind=v[tags[type].source],spec=variant[type][kind];
          if(!spec)refuse(path,'unknown '+type+' constructor');
          if(type==='PsSyntaxDeclaration'&&kind==='partialDefinition')
            refuse(path,'partial source definitions disallowed by v7');
          const fields=Object.keys(spec);
          fieldSet(v,fields,path);
          verifiedTag(v,tags[type].source,kind,path);
          const args=fields.map(k=>decode(spec[k],v[k],path+'.'+k));
          const ctor=C[type][kind];
          const out=typeof ctor==='function'?ctor(...args):ctor;
          if(!out||out[tags[type].recipient]!==kind)
            refuse(path,'retained constructor reconstruction failed');
          return out;
        }
        if(!struct[type])refuse(path,'unknown source struct '+type);
        const spec=struct[type];
        fieldSet(v,Object.keys(spec),path);
        verifiedBrand(v,type,path);
        const out=Object.create(null);
        for(const [name,fieldType] of Object.entries(spec))
          out[name]=decode(fieldType,v[name],path+'.'+name);
        if(type==='PsSourcePos'&&(out.byteOffset>BigInt(byteLength)||out.line<1n||out.column<1n))
          refuse(path,'source location not within source bytes');
        if(type==='PsSourceSpan'&&(out.start.byteOffset>out.stop.byteOffset||out.start.line>out.stop.line))
          refuse(path,'invalid source span');
        return out;
      }
      if(type.kind==='pair'){
        fieldSet(v,['fst','snd'],path);
        verifiedBrand(v,'Prod',path);
        return Object.assign(Object.create(null),{
          fst:decode(type.fst,v.fst,path+'.fst'),
          snd:decode(type.snd,v.snd,path+'.snd')
        });
      }
      if(type.kind==='option'){
        record(v,path);
        const kind=v[tags.Option.source];
        if(kind!=='none'&&kind!=='some')refuse(path,'unknown Option constructor');
        fieldSet(v,kind==='none'?[]:['value'],path);
        verifiedTag(v,tags.Option.source,kind,path);
        return kind==='none'?C.Option.none():C.Option.some(decode(type.of,v.value,path+'.value'));
      }
      if(type.kind==='list'){
        const items=[],seen=new Set();
        let cur=v;
        while(true){
          if(seen.has(cur))refuse(path,'cyclic list');
          seen.add(cur);
          record(cur,path);
          const kind=cur[tags.List.source];
          if(kind==='nil'){
            fieldSet(cur,[],path);
            verifiedTag(cur,tags.List.source,'nil',path);
            break;
          }
          if(kind!=='cons')refuse(path,'invalid source list constructor');
          fieldSet(cur,['head','tail'],path);
          verifiedTag(cur,tags.List.source,'cons',path);
          items.push(decode(type.of,cur.head,path+'['+items.length+']'));
          if(items.length>65536)refuse(path,'source list element budget exceeded');
          cur=cur.tail;
        }
        let out=C.List.nil();
        for(let k=items.length-1;k>=0;k--)out=C.List.cons(items[k],out);
        return out;
      }
      refuse(path,'unrecognized descriptor');
    }finally{depth--;}
  };
  const output=decode('PsSyntaxModule',module,'module');
  return {module:output,receipt:Object.freeze({
    schema:AST_ABI_VERSION,
    referenceSha256:V7_REFERENCE_SHA,
    sourceSha256:createHash('sha256').update(sourceText).digest('hex'),
    normalizedNodes:nodes,
    trustedByKernel:false,
    elaborationRequired:true
  })};
}
