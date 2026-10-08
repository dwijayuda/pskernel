import { artifactKey, verifyArtifact } from './artifact-evidence.mjs';
import { decodeInterfaceIrArtifact, interfaceIrEncodingContract } from './interface-ir-artifact.mjs';

export const canonicalMemoryContract = 'psc-canonical-memory-sync-utf8/1';
export const canonicalCoreValuesContract = 'psc-canonical-core-values-sync-utf8/1';
const fail = code => { throw new TypeError('PSC_CANONICAL_MEMORY_' + code); };
const maximumValueBytes = 268435455;
const preparedInterfaces=new WeakMap();
const align = (size, alignment) => Math.ceil(size / alignment) * alignment;
const unique = values => new Set(values).size === values.length;
const own = (value, key) => {
  if (value === null || typeof value !== 'object') fail('VALUE');
  const descriptor = Object.getOwnPropertyDescriptor(value, key);
  if (!descriptor || !Object.hasOwn(descriptor, 'value')) fail('DATA_PROPERTY');
  return descriptor.value;
};
function keys(value, expected) {
  if (value === null || typeof value !== 'object' || Array.isArray(value) ||
      Reflect.ownKeys(value).length !== expected.length ||
      expected.some(key => !Object.hasOwn(value, key))) fail('SHAPE');
}
function arrayValues(value, count, budget) {
  if (!Array.isArray(value) || (count !== undefined && value.length !== count) ||
      value.length > budget || Reflect.ownKeys(value).length !== value.length + 1) fail('ARRAY');
  const result = [];
  for (let i = 0; i < value.length; i++) result.push(own(value, String(i)));
  return result;
}
function integer(value, minimum, maximum) {
  return typeof value === 'number' && Number.isSafeInteger(value) && value >= minimum && value <= maximum;
}
const scalarInfo = {
  bool:[1, 'i32'], u8:[1, 'i32'], s8:[1, 'i32'], u16:[2, 'i32'], s16:[2, 'i32'],
  u32:[4, 'i32'], s32:[4, 'i32'], u64:[8, 'i64'], s64:[8, 'i64'],
  f32:[4, 'f32'], f64:[8, 'f64'], char:[4, 'i32'],
};
const join = (a, b) => a === b ? a :
  (['i32','f32'].includes(a) && ['i32','f32'].includes(b) ? 'i32' : 'i64');
function checked(node) {
  if (!Number.isSafeInteger(node.size) || node.size > maximumValueBytes) fail('TYPE_SIZE');
  return node;
}
function sequence(tag, children, names) {
  let size=0, alignment=1, flatCount=0, flat=[], depth=0, handles=false, memory=false;
  const offsets=[];
  for (const child of children) {
    size=align(size,child.alignment); offsets.push(size); size+=child.size;
    alignment=Math.max(alignment,child.alignment); flatCount+=child.flatCount;
    flat=[...flat,...child.flat].slice(0,17); depth=Math.max(depth,child.depth);
    handles ||= child.handles; memory ||= child.memory;
    if(size>maximumValueBytes)fail('TYPE_SIZE');
  }
  return checked({tag,children,names,offsets,size:align(size,alignment),alignment,
    flatCount,flat,depth,handles,memory,payloadOffset:0});
}
function variant(tag, names, children) {
  const count=names.length;
  if(!count || count>4294967295 || !unique(names))fail('CASES');
  const discriminant=count<=256?1:count<=65536?2:4;
  let payloadSize=0, payloadAlignment=1, flatCount=0, flat=[], depth=0, handles=false, memory=false;
  for(const child of children) if(child!==null){
    payloadSize=Math.max(payloadSize,child.size); payloadAlignment=Math.max(payloadAlignment,child.alignment);
    flatCount=Math.max(flatCount,child.flatCount); depth=Math.max(depth,child.depth);
    for(let i=0;i<child.flat.length;i++)flat[i]=flat[i]===undefined?child.flat[i]:join(flat[i],child.flat[i]);
    handles ||= child.handles; memory ||= child.memory;
  }
  const alignment=Math.max(discriminant,payloadAlignment), payloadOffset=align(discriminant,payloadAlignment);
  return checked({tag,names,children,discriminant,payloadOffset,alignment,
    size:align(payloadOffset+payloadSize,alignment),flatCount:1+flatCount,flat:['i32',...flat].slice(0,17),
    depth,handles,memory,offsets:[]});
}
function compileDefinitions(iface, pointerBits, typeDepth) {
  const pointerSize=pointerBits/8, pointerType=pointerBits===32?'i32':'i64';
  const definitions=new Map(iface.definitions.map(value=>[value.name,value.body]));
  const cache=new Map(), active=new Set();
  const leaf=(tag,size,flat,extra={})=>({tag,size,alignment:size,flatCount:flat.length,flat,
    depth:1,handles:false,memory:false,offsets:[],payloadOffset:0,...extra});
  function named(name, recursion) {
    if(cache.has(name))return cache.get(name);
    if(recursion>typeDepth || active.has(name) || !definitions.has(name))fail('TYPE_GRAPH');
    active.add(name);
    const body=definitions.get(name); let result;
    switch(body.tag){
      case 'alias': result=type(body.type,recursion+1); break;
      case 'record':
        if(!unique(body.fields.map(field=>field.name)))fail('FIELDS');
        result=sequence('record',body.fields.map(field=>type(field.type,recursion+1)),body.fields.map(field=>field.name)); break;
      case 'variant': result=variant('variant',body.cases.map(value=>value.name),
        body.cases.map(value=>value.payload===null?null:type(value.payload,recursion+1))); break;
      case 'enum': result=variant('enum',body.cases,body.cases.map(()=>null)); result.payloadOffset=0; break;
      case 'resource': result=leaf('resource',0,[],{alignment:1,depth:0,handles:true}); break;
      default: fail('DEFINITION');
    }
    if(result.depth>typeDepth)fail('TYPE_DEPTH');
    active.delete(name); cache.set(name,result); return result;
  }
  function type(value, recursion) {
    if(recursion>typeDepth*2+2)fail('TYPE_DEPTH');
    let result;
    switch(value.tag){
      case 'scalar':
        if(value.scalar==='string')return leaf('string',pointerSize*2,[pointerType,pointerType],
          {alignment:pointerSize,memory:true});
        if(!Object.hasOwn(scalarInfo,value.scalar))fail('SCALAR');
        return leaf(value.scalar,scalarInfo[value.scalar][0],[scalarInfo[value.scalar][1]]);
      case 'named': {
        const target=named(value.name,recursion);
        if(target.tag==='resource')fail('RESOURCE_VALUE');
        result={...target,tag:'named',target,depth:target.depth+1}; break;
      }
      case 'list': {
        const element=type(value.element,recursion+1);
        result=leaf('list',pointerSize*2,[pointerType,pointerType],
          {alignment:pointerSize,element,depth:element.depth+1,memory:true,handles:element.handles}); break;
      }
      case 'tuple': result=sequence('tuple',value.elements.map(item=>type(item,recursion+1))); result.depth++; break;
      case 'option': result=variant('variant',['none','some'],[null,type(value.element,recursion+1)]); result.depth++; break;
      case 'result': result=variant('variant',['ok','error'],[value.ok,value.error].map(item=>item===null?null:type(item,recursion+1))); result.depth++; break;
      case 'own':
        if(definitions.get(value.resource)?.tag!=='resource')fail('RESOURCE');
        return leaf('handle',4,['i32'],{handles:true});
      case 'borrow': fail('BORROWED_VALUE');
      case 'future': case 'stream': fail('ASYNC');
      default: fail('TYPE');
    }
    if(result.depth>typeDepth)fail('TYPE_DEPTH');
    return result;
  }
  for(const name of definitions.keys())named(name,0);
  return {layouts:cache,type:value=>type(value,0)};
}

/** Pure caller-pinned value/type planning. Memory and realloc are attached
 * separately after consumers check binary signatures and execution policy.
 * This is adapter data, not compiler source authority or a lifetime proof.
 */
export function prepareCanonicalValueTypes({interfaceArtifact,expectedInterfaceId,interfaceName,
  pointerBits=32,limits={}}) {
  const typeDepth=limits.typeDepth??64, maxNodes=limits.maxNodes??250000;
  const maxBytes=limits.maxBytes??16*1024*1024, maxStringCodeUnits=limits.maxStringCodeUnits??8*1024*1024;
  if(!integer(typeDepth,1,128) || !integer(maxNodes,1,1000000) ||
      !integer(maxBytes,0,maximumValueBytes) || !integer(maxStringCodeUnits,0,maximumValueBytes) ||
      ![32,64].includes(pointerBits))fail('POLICY');
  if(expectedInterfaceId?.domain!=='interface-ir' || expectedInterfaceId.contract!==interfaceIrEncodingContract ||
      artifactKey(interfaceArtifact?.identity)!==artifactKey(expectedInterfaceId) ||
      !(interfaceArtifact.bytes instanceof Uint8Array) || interfaceArtifact.bytes.length>8*1024*1024)fail('INTERFACE_ID');
  const bytes=Buffer.from(interfaceArtifact.bytes); verifyArtifact(bytes,expectedInterfaceId);
  const world=decodeInterfaceIrArtifact(bytes,{typeDepth:256,maxDepth:512});
  const iface=world.interfaces.find(value=>value.name===interfaceName);
  if(!iface)fail('INTERFACE');
  // The component validation bound always uses memory64 element sizes.
  const maximum=compileDefinitions(iface,64,typeDepth);
  const selected=pointerBits===64?maximum:compileDefinitions(iface,32,typeDepth);
  const layouts=selected.layouts,functionPlans=new Map();
  function functionPlan(name){
    if(functionPlans.has(name))return functionPlans.get(name);
    const fn=iface.functions.find(value=>value.name===name);
    if(!fn||fn.asynchronous||!fn.targets.includes('component-model')||
        !unique(fn.targets)||!unique(fn.parameters.map(field=>field.name)))fail('FUNCTION_PROFILE');
    const types=fn.parameters.map(field=>field.type);
    sequence('tuple',types.map(maximum.type));
    if(fn.result!==null)maximum.type(fn.result);
    const parameters=sequence('tuple',types.map(selected.type));
    const result=fn.result===null?null:selected.type(fn.result);
    if(parameters.handles||result?.handles)fail('HANDLE_TABLE_REQUIRED');
    const value={parameters,result,arity:types.length};functionPlans.set(name,value);return value;
  }
  function describeFunction(name){
    const fn=functionPlan(name),pointer=pointerBits===32?'i32':'i64';
    const indirectParameters=fn.parameters.flatCount>16,indirectResult=fn.result!==null&&fn.result.flatCount>1;
    const parameters=indirectParameters?[pointer]:[...fn.parameters.flat];
    const directResults=fn.result===null?[]:[...fn.result.flat];
    const liftResults=indirectResult?[pointer]:directResults;
    const lowerParameters=indirectResult?[...parameters,pointer]:parameters;
    return Object.freeze({name,arity:fn.arity,hasResult:fn.result!==null,indirectParameters,indirectResult,
      needsMemory:fn.parameters.memory||Boolean(fn.result?.memory)||indirectParameters||indirectResult,
      needsRealloc:fn.parameters.memory||indirectParameters,
      lift:Object.freeze({parameters:Object.freeze(parameters),results:Object.freeze(liftResults)}),
      lower:Object.freeze({parameters:Object.freeze(lowerParameters),results:Object.freeze(indirectResult?[]:directResults)})});
  }
  const prepared=Object.freeze({contract:canonicalCoreValuesContract,interfaceName,pointerBits,
    interfaceId:Object.freeze({...expectedInterfaceId}),exported:world.exports.includes(interfaceName),
    hasWorldImports:world.imports.length!==0,
    requiredCapabilities:Object.freeze([...iface.requiredCapabilities]),
    providedCapabilities:Object.freeze([...iface.providedCapabilities]),describeFunction});
  preparedInterfaces.set(prepared,{layouts,functionPlan,pointerBits,maxNodes,maxBytes,maxStringCodeUnits});
  return prepared;
}

export function bindCanonicalValueMemory(prepared,{memory,realloc}={}){
  const state=preparedInterfaces.get(prepared);if(!state)fail('PREPARED_INTERFACE');
  const {layouts,functionPlan,pointerBits,maxNodes,maxBytes,maxStringCodeUnits}=state;
  if((memory!==undefined&&!(memory instanceof WebAssembly.Memory)) ||
      (realloc!==undefined&&typeof realloc!=='function'))fail('HOST');
  const pointerSize=pointerBits/8, pointerMaximum=pointerBits===32?4294967295:Number.MAX_SAFE_INTEGER;
  let busy=false;
  const buffer=()=>{
    if(memory===undefined)fail('MEMORY_REQUIRED');
    const value=memory.buffer;
    if(!(value instanceof ArrayBuffer))fail('SHARED_MEMORY');
    return value;
  };
  if(memory!==undefined)buffer();
  function range(pointer,size,alignment=1){
    const value=buffer();
    if(!integer(pointer,0,pointerMaximum) || !integer(size,0,maximumValueBytes) ||
        pointer%alignment!==0 || pointer>value.byteLength || size>value.byteLength-pointer)fail('MEMORY_RANGE');
    return value;
  }
  const view=(pointer,size,alignment=1)=>new DataView(range(pointer,size,alignment),pointer,size);
  function pointerRead(at){
    const v=view(at,pointerSize,pointerSize);
    const result=pointerBits===32?v.getUint32(0,true):v.getBigUint64(0,true);
    if(typeof result==='bigint' && result>BigInt(Number.MAX_SAFE_INTEGER))fail('MEMORY_RANGE');
    return Number(result);
  }
  function pointerWrite(at,value){
    if(!integer(value,0,pointerMaximum))fail('POINTER');
    const v=view(at,pointerSize,pointerSize);
    if(pointerBits===32)v.setUint32(0,value,true);else v.setBigUint64(0,BigInt(value),true);
  }
  function allocation(size,alignment){
    if(!realloc)fail('REALLOC_REQUIRED');
    const result=pointerBits===32?realloc(0,0,alignment,size):realloc(0n,0n,BigInt(alignment),BigInt(size));
    let pointer;
    if(pointerBits===32){
      // Wasm JS i32 results are signed; interpret their bits as a pointer.
      if(!integer(result,-2147483648,4294967295))fail('REALLOC_RESULT');
      pointer=result>>>0;
    }else{
      if(typeof result!=='bigint' || result<-(1n<<63n) || result>=(1n<<64n))fail('REALLOC_RESULT');
      const unsigned=BigInt.asUintN(64,result);
      if(unsigned>BigInt(Number.MAX_SAFE_INTEGER))fail('REALLOC_RESULT');
      pointer=Number(unsigned);
    }
    range(pointer,size,alignment); return pointer;
  }
  function nodeBudget(state){ if(++state.nodes>maxNodes)fail('NODE_LIMIT'); }
  function byteBudget(state,size){
    if(!integer(size,0,maximumValueBytes) || size>maxBytes-state.bytes)fail('BYTE_LIMIT');
    state.bytes+=size;
  }
  function scalarValue(tag,value){
    if(tag==='bool'){if(typeof value!=='boolean')fail('BOOL');}
    else if(tag==='char'){
      if(typeof value!=='string' || value.length<1 || value.length>2 || !value.isWellFormed() ||
          String.fromCodePoint(value.codePointAt(0))!==value)fail('CHAR');
    }else if(tag==='f32'||tag==='f64'){
      if(typeof value!=='number' || (tag==='f32' && !Number.isNaN(value) && !Object.is(Math.fround(value),value)))fail('FLOAT');
    }else{
      const signed=tag[0]==='s', bits=Number(tag.slice(1));
      if(bits===64){
        const lo=signed?-(1n<<63n):0n, hi=signed?(1n<<63n)-1n:(1n<<64n)-1n;
        if(typeof value!=='bigint' || value<lo || value>hi)fail('INTEGER');
      }else if(!integer(value,signed?-(2**(bits-1)):0,signed?2**(bits-1)-1:2**bits-1))fail('INTEGER');
    }
    return value;
  }
  function prepare(node,value,state){
    nodeBudget(state);
    switch(node.tag){
      case 'named': return prepare(node.target,value,state);
      case 'string': {
        if(typeof value!=='string' || value.length>maxStringCodeUnits || !value.isWellFormed())fail('STRING');
        const length=Buffer.byteLength(value,'utf8'); byteBudget(state,length);
        return Buffer.from(value,'utf8');
      }
      case 'list': {
        const values=arrayValues(value,undefined,maxNodes-state.nodes);
        byteBudget(state,values.length*node.element.size);
        return values.map(item=>prepare(node.element,item,state));
      }
      case 'tuple': return arrayValues(value,node.children.length,maxNodes-state.nodes).map((item,i)=>prepare(node.children[i],item,state));
      case 'record': keys(value,node.names); return node.names.map((name,i)=>prepare(node.children[i],own(value,name),state));
      case 'variant': {
        const name=own(value,'tag'), index=node.names.indexOf(name);
        if(index<0)fail('VARIANT_TAG');
        const child=node.children[index]; keys(value,child===null?['tag']:['tag','value']);
        return {index,value:child===null?undefined:prepare(child,own(value,'value'),state)};
      }
      case 'enum': {const index=node.names.indexOf(value); if(index<0)fail('ENUM'); return {index};}
      default: return scalarValue(node.tag,value);
    }
  }
  function writeInteger(at,size,value,signed=false){
    const v=view(at,size,size);
    if(size===8){ if(signed)v.setBigInt64(0,value,true);else v.setBigUint64(0,value,true); }
    else v[(signed?'setInt':'setUint')+(size*8)](0,value,true);
  }
  function readInteger(at,size,signed=false){
    const v=view(at,size,size);
    return size===8?v[signed?'getBigInt64':'getBigUint64'](0,true):v[(signed?'getInt':'getUint')+(size*8)](0,true);
  }
  function storeStringRange(value){
    const ptr=allocation(value.length,1);
    new Uint8Array(range(ptr,value.length),ptr,value.length).set(value);
    return [ptr,value.length];
  }
  function storeListRange(node,value){
    const ptr=allocation(value.length*node.element.size,node.element.alignment);
    for(let i=0;i<value.length;i++)store(node.element,value[i],ptr+i*node.element.size);
    return [ptr,value.length];
  }
  function store(node,value,at){
    range(at,node.size,node.alignment);
    switch(node.tag){
      case 'named': store(node.target,value,at); break;
      case 'string': {
        const [ptr,length]=storeStringRange(value);
        pointerWrite(at,ptr);pointerWrite(at+pointerSize,length);break;
      }
      case 'list': {
        const [ptr,length]=storeListRange(node,value);
        pointerWrite(at,ptr);pointerWrite(at+pointerSize,length);break;
      }
      case 'record': case 'tuple':
        for(let i=0;i<node.children.length;i++)store(node.children[i],value[i],at+node.offsets[i]);
        break;
      case 'variant': case 'enum':
        writeInteger(at,node.discriminant,value.index);
        if(node.children[value.index]!==null)store(node.children[value.index],value.value,at+node.payloadOffset);
        break;
      case 'bool': writeInteger(at,1,value?1:0);break;
      case 'char': writeInteger(at,4,value.codePointAt(0));break;
      case 'f32': case 'f64': {
        const v=view(at,node.size,node.alignment);
        if(Number.isNaN(value)){
          if(node.size===4)v.setUint32(0,0x7fc00000,true);else v.setBigUint64(0,0x7ff8000000000000n,true);
        }else v[node.size===4?'setFloat32':'setFloat64'](0,value,true);
        break;
      }
      default: writeInteger(at,node.size,value,node.tag[0]==='s');
    }
  }
  const decoder=new TextDecoder('utf-8',{fatal:true,ignoreBOM:true});
  function loadStringRange(ptr,length,state){
    byteBudget(state,length);const source=new Uint8Array(range(ptr,length),ptr,length);
    let result;try{result=decoder.decode(source);}catch{fail('UTF8');}
    if(result.length>maxStringCodeUnits)fail('STRING_LIMIT');return result;
  }
  function loadListRange(node,ptr,length,state){
    const size=length*node.element.size;
    if(length>maxNodes-state.nodes)fail('NODE_LIMIT');
    byteBudget(state,size);range(ptr,size,node.element.alignment);
    const result=[];for(let i=0;i<length;i++)result.push(load(node.element,ptr+i*node.element.size,state));return result;
  }
  function load(node,at,state){
    nodeBudget(state);range(at,node.size,node.alignment);
    switch(node.tag){
      case 'named': return load(node.target,at,state);
      case 'string': {
        return loadStringRange(pointerRead(at),pointerRead(at+pointerSize),state);
      }
      case 'list': {
        return loadListRange(node,pointerRead(at),pointerRead(at+pointerSize),state);
      }
      case 'tuple': return node.children.map((child,i)=>load(child,at+node.offsets[i],state));
      case 'record': {
        const result=Object.create(null);
        for(let i=0;i<node.children.length;i++)Object.defineProperty(result,node.names[i],{
          value:load(node.children[i],at+node.offsets[i],state),enumerable:true});
        return result;
      }
      case 'variant': case 'enum': {
        const index=readInteger(at,node.discriminant);if(index>=node.names.length)fail('VARIANT_TAG');
        if(node.tag==='enum')return node.names[index];
        const child=node.children[index];
        return child===null?{tag:node.names[index]}:{tag:node.names[index],value:load(child,at+node.payloadOffset,state)};
      }
      case 'bool': return readInteger(at,1)!==0;
      case 'char': {
        const value=readInteger(at,4);
        if(value>0x10ffff || (value>=0xd800 && value<=0xdfff))fail('CHAR');
        return String.fromCodePoint(value);
      }
      case 'f32': case 'f64': {
        const result=view(at,node.size,node.alignment)[node.size===4?'getFloat32':'getFloat64'](0,true);
        return Number.isNaN(result)?NaN:result;
      }
      default:return readInteger(at,node.size,node.tag[0]==='s');
    }
  }
  const reinterpret=new DataView(new ArrayBuffer(8));
  function floatBits(kind,value){
    if(kind==='f32'){
      if(Number.isNaN(value))return 0x7fc00000;
      reinterpret.setFloat32(0,value,true);return reinterpret.getUint32(0,true);
    }
    if(Number.isNaN(value))return 0x7ff8000000000000n;
    reinterpret.setFloat64(0,value,true);return reinterpret.getBigUint64(0,true);
  }
  function bitsFloat(kind,value){
    if(kind==='f32'){
      reinterpret.setUint32(0,value,true);
      const result=reinterpret.getFloat32(0,true);return Number.isNaN(result)?NaN:result;
    }
    reinterpret.setBigUint64(0,value,true);
    const result=reinterpret.getFloat64(0,true);return Number.isNaN(result)?NaN:result;
  }
  // The reference uses unsigned integer bits internally. The WebAssembly JS
  // boundary exposes signed Number/BigInt core values; normalize only there.
  function coreBits(kind,value){
    if(kind==='i32'){
      if(!integer(value,-2147483648,2147483647))fail('CORE_I32');
      return value>>>0;
    }
    if(kind==='i64'){
      if(typeof value!=='bigint' || value<-(1n<<63n) || value>=(1n<<63n))fail('CORE_I64');
      return BigInt.asUintN(64,value);
    }
    return scalarValue(kind,value);
  }
  const coreValue=(kind,value)=>kind==='i32'?value|0:kind==='i64'?BigInt.asIntN(64,value):value;
  const pointerType=pointerBits===32?'i32':'i64';
  const pointerCore=value=>coreValue(pointerType,pointerBits===32?value:BigInt(value));
  function address(value){
    if(typeof value==='bigint'){
      if(value>BigInt(Number.MAX_SAFE_INTEGER))fail('MEMORY_RANGE');
      return Number(value);
    }
    return value;
  }
  function lowerCoercion(value,have,want){
    if(have===want)return value;
    if(have==='f32' && want==='i32')return floatBits(have,value);
    if(have==='i32' && want==='i64')return BigInt(value);
    if(have==='f32' && want==='i64')return BigInt(floatBits(have,value));
    if(have==='f64' && want==='i64')return floatBits(have,value);
    fail('FLAT_JOIN');
  }
  function liftCoercion(value,have,want){
    if(have===want)return value;
    if(have==='i32' && want==='f32')return bitsFloat(want,value);
    if(have==='i64' && want==='i32')return Number(BigInt.asUintN(32,value));
    if(have==='i64' && want==='f32')return bitsFloat(want,Number(BigInt.asUintN(32,value)));
    if(have==='i64' && want==='f64')return bitsFloat(want,value);
    fail('FLAT_JOIN');
  }
  function lowerFlat(node,value){
    switch(node.tag){
      case 'named':return lowerFlat(node.target,value);
      case 'string':return storeStringRange(value).map(item=>pointerBits===32?item:BigInt(item));
      case 'list':return storeListRange(node,value).map(item=>pointerBits===32?item:BigInt(item));
      case 'record':case 'tuple':return node.children.flatMap((child,i)=>lowerFlat(child,value[i]));
      case 'variant':case 'enum':{
        const child=node.children[value.index],payload=child===null?[]:lowerFlat(child,value.value);
        const joined=payload.map((item,i)=>lowerCoercion(item,child.flat[i],node.flat[i+1]));
        for(let i=joined.length+1;i<node.flatCount;i++)joined.push(node.flat[i]==='i64'?0n:0);
        return [value.index,...joined];
      }
      case 'bool':return [value?1:0];
      case 'char':return [value.codePointAt(0)];
      case 'f32':case 'f64':return [Number.isNaN(value)?bitsFloat(node.tag,floatBits(node.tag,value)):value];
      default:return [node.size===8?BigInt.asUintN(64,value):value>>>0];
    }
  }
  function liftFlat(node,read,state){
    nodeBudget(state);
    switch(node.tag){
      case 'named':return liftFlat(node.target,read,state);
      case 'string':return loadStringRange(address(read(pointerType)),address(read(pointerType)),state);
      case 'list':return loadListRange(node,address(read(pointerType)),address(read(pointerType)),state);
      case 'tuple':return node.children.map(child=>liftFlat(child,read,state));
      case 'record':{
        const result=Object.create(null);
        for(let i=0;i<node.children.length;i++)Object.defineProperty(result,node.names[i],{
          value:liftFlat(node.children[i],read,state),enumerable:true});
        return result;
      }
      case 'variant':case 'enum':{
        const index=read('i32');if(index>=node.names.length)fail('VARIANT_TAG');
        const child=node.children[index];let consumed=0;
        const coerce=want=>{
          const have=node.flat[1+consumed++];return liftCoercion(read(have),have,want);
        };
        const value=child===null?undefined:liftFlat(child,coerce,state);
        while(consumed<node.flatCount-1)read(node.flat[1+consumed++]);
        if(node.tag==='enum')return node.names[index];
        return child===null?{tag:node.names[index]}:{tag:node.names[index],value};
      }
      case 'bool':return read('i32')!==0;
      case 'char':{
        const value=read('i32');if(value>0x10ffff || (value>=0xd800 && value<=0xdfff))fail('CHAR');
        return String.fromCodePoint(value);
      }
      case 'f32':case 'f64':{const value=read(node.tag);return Number.isNaN(value)?NaN:value;}
      default:{
        if(node.size===8){const bits=read('i64');return node.tag==='s64'?BigInt.asIntN(64,bits):bits;}
        const width=node.size*8, bits=read('i32')%(2**width);
        return node.tag[0]==='s' && bits>=2**(width-1)?bits-2**width:bits;
      }
    }
  }
  function flatLimit(value){if(value!==1 && value!==16)fail('FLAT_LIMIT');return value;}
  function lowerNode(node,value,maxFlat,outPointer){
    const indirect=node.flatCount>flatLimit(maxFlat),state={nodes:0,bytes:0};
    if(outPointer!==undefined){
      if(!indirect)fail('UNEXPECTED_OUT_POINTER');
      range(outPointer,node.size,node.alignment);
    }
    if(indirect)byteBudget(state,node.size);
    const preparedValue=prepare(node,value,state);
    if(indirect){
      const at=outPointer===undefined?allocation(node.size,node.alignment):outPointer;
      store(node,preparedValue,at);return outPointer===undefined?[pointerCore(at)]:[];
    }
    return lowerFlat(node,preparedValue).map((item,i)=>coreValue(node.flat[i],item));
  }
  function liftNode(node,values,maxFlat){
    const indirect=node.flatCount>flatLimit(maxFlat),state={nodes:0,bytes:0};
    const types=indirect?[pointerType]:node.flat;
    const input=arrayValues(values,types.length,16).map((item,i)=>coreBits(types[i],item));
    if(indirect){byteBudget(state,node.size);return load(node,address(input[0]),state);}
    let index=0;
    const result=liftFlat(node,kind=>{
      if(kind!==types[index])fail('FLAT_TYPE');
      return input[index++];
    },state);
    if(index!==input.length)fail('FLAT_ARITY');
    return result;
  }
  function selected(name){
    const result=layouts.get(name);
    if(!result)fail('TYPE_NAME');
    if(result.handles)fail('HANDLE_TABLE_REQUIRED');
    return result;
  }
  function transaction(operation){
    if(busy)fail('REENTRANT');busy=true;
    try{return operation();}finally{busy=false;}
  }
  return Object.freeze({
    contract:canonicalMemoryContract,
    coreValuesContract:canonicalCoreValuesContract,
    layout(name){const node=selected(name);return Object.freeze({alignment:node.alignment,byteSize:node.size,
      flatCount:node.flatCount,flatPrefix:Object.freeze([...node.flat]),fieldOffsets:Object.freeze([...node.offsets]),
      payloadOffset:node.payloadOffset,needsMemory:node.memory,needsHandleTable:node.handles});},
    lowerValue(name,value,{maxFlat=16,outPointer}={}){return transaction(()=>lowerNode(selected(name),value,maxFlat,outPointer));},
    liftValue(name,values,{maxFlat=16}={}){return transaction(()=>liftNode(selected(name),values,maxFlat));},
    lowerArguments(name,values){return transaction(()=>lowerNode(functionPlan(name).parameters,values,16));},
    liftResult(name,values){return transaction(()=>{
      const fn=functionPlan(name);
      if(fn.result===null){arrayValues(values,0,0);return undefined;}
      return liftNode(fn.result,values,1);
    });},
    load(name,at){return transaction(()=>{const node=selected(name),state={nodes:0,bytes:0};byteBudget(state,node.size);return load(node,at,state);});},
    store(name,value,at){return transaction(()=>{
      const node=selected(name),state={nodes:0,bytes:0};range(at,node.size,node.alignment);byteBudget(state,node.size);
      const prepared=prepare(node,value,state);store(node,prepared,at);
    });},
  });
}

export function createCanonicalMemoryCodec(options){
  return bindCanonicalValueMemory(prepareCanonicalValueTypes(options),options);
}
