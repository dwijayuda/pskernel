import { artifactId, canonicalArtifact, verifyArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';

export const interfaceIrEncodingContract = 'psc-interface-ir-json/1';
export const witArtifactContract = 'psc-wit-world/1';
export const interfaceToWitRelation = 'psc-interface-ir-wit-rendering/1';

const fail = code => { throw new Error('PSC_INTERFACE_IR_ARTIFACT_' + code); };
const arr = (value, count) => {
  if (!Array.isArray(value) || (count !== undefined && value.length !== count)) fail('SCHEMA');
  return value;
};
const str = value => {
  if (typeof value !== 'string' || !value.isWellFormed()) fail('STRING');
  return value;
};
const bool = value => { if (typeof value !== 'boolean') fail('BOOL'); return value; };

const scalars = new Set('bool u8 u16 u32 u64 s8 s16 s32 s64 f32 f64 char string'.split(' '));
function name(value) {
  str(value);
  if (!value.length) fail('NAME');
  let needLetter = true;
  for (const char of value) {
    const code = char.codePointAt(0);
    const letter = code >= 97 && code <= 122;
    const digit = code >= 48 && code <= 57;
    if (letter) { needLetter = false; continue; }
    if (!needLetter && char === '-') { needLetter = true; continue; }
    if (!needLetter && digit) continue;
    fail('NAME');
  }
  if (needLetter) fail('NAME');
  return value;
}
const witName = value => '%' + name(value);

function optionType(value, depth) {
  arr(value);
  if (value[0] === 'none') { arr(value,1); return null; }
  if (value[0] === 'some') { arr(value,2); return foreignType(value[1], depth - 1); }
  fail('OPTION');
}
function foreignType(value, depth) {
  if (depth <= 0) fail('DEPTH');
  arr(value);
  switch (value[0]) {
    case 'scalar': arr(value,2); if (!scalars.has(value[1])) fail('SCALAR'); return { tag:'scalar', scalar:value[1] };
    case 'named': arr(value,2); return { tag:'named', name:name(value[1]) };
    case 'list': arr(value,2); return { tag:'list', element:foreignType(value[1],depth-1) };
    case 'option': arr(value,2); return { tag:'option', element:foreignType(value[1],depth-1) };
    case 'result': arr(value,3); return { tag:'result', ok:optionType(value[1],depth-1), error:optionType(value[2],depth-1) };
    case 'tuple': arr(value,2); if (!value[1].length) fail('TUPLE'); return { tag:'tuple', elements:arr(value[1]).map(item=>foreignType(item,depth-1)) };
    case 'own': arr(value,2); return { tag:'own', resource:name(value[1]) };
    case 'borrow': arr(value,2); return { tag:'borrow', resource:name(value[1]) };
    case 'future': arr(value,2); return { tag:'future', element:optionType(value[1],depth-1) };
    case 'stream': arr(value,2); return { tag:'stream', element:optionType(value[1],depth-1) };
    default: fail('TYPE');
  }
}
function field(value, depth) { arr(value,2); return { name:name(value[0]), type:foreignType(value[1],depth) }; }
function caseValue(value, depth) { arr(value,2); return { name:name(value[0]), payload:optionType(value[1],depth) }; }
function definition(value, depth) {
  arr(value,2); const n=name(value[0]), body=arr(value[1]);
  switch(body[0]){
    case 'alias': arr(body,2); return { name:n, body:{ tag:'alias', type:foreignType(body[1],depth) } };
    case 'record': arr(body,2); if(!body[1].length)fail('RECORD'); return { name:n, body:{ tag:'record', fields:arr(body[1]).map(v=>field(v,depth)) } };
    case 'variant': arr(body,2); if(!body[1].length)fail('VARIANT'); return { name:n, body:{ tag:'variant', cases:arr(body[1]).map(v=>caseValue(v,depth)) } };
    case 'enum': arr(body,2); if(!body[1].length)fail('ENUM'); return { name:n, body:{ tag:'enum', cases:arr(body[1]).map(name) } };
    case 'resource': arr(body,1); return { name:n, body:{ tag:'resource' } };
    default: fail('DEFINITION');
  }
}
function functionValue(value, depth) {
  arr(value,5);
  const result=optionType(value[2],depth);
  return { name:name(value[0]), parameters:arr(value[1]).map(v=>field(v,depth)),
    result, asynchronous:bool(value[3]), targets:arr(value[4]).map(name) };
}
function unique(values) {
  const seen=new Set();
  for(const value of values){ if(seen.has(value))fail('DUPLICATE'); seen.add(value); }
}
function iface(value, depth) {
  arr(value,5); const n=name(value[0]);
  const definitions=arr(value[1]).map(v=>definition(v,depth));
  const functions=arr(value[2]).map(v=>functionValue(v,depth));
  const requiredCapabilities=arr(value[3]).map(name), providedCapabilities=arr(value[4]).map(name);
  unique([...definitions.map(x=>x.name),...functions.map(x=>x.name)]); unique(requiredCapabilities); unique(providedCapabilities);
  return { name:n, definitions, functions, requiredCapabilities, providedCapabilities };
}

export function decodeInterfaceIrArtifact(bytes,{maxBytes=8*1024*1024,maxDepth=128,maxNodes=250000,typeDepth=64}={}){
  const root=decodeComparatorJson(bytes,{maxBytes,maxDepth,maxNodes});
  arr(root,8); if(root[0]!==interfaceIrEncodingContract)fail('CONTRACT');
  const contract=str(root[1]); if(contract!=='psc-foreign-interface/1')fail('FOREIGN_CONTRACT');
  const packageNamespace=name(root[2]), packageName=name(root[3]), worldName=name(root[4]);
  const interfaces=arr(root[5]).map(v=>iface(v,typeDepth));
  const imports=arr(root[6]).map(name), exports=arr(root[7]).map(name);
  unique([worldName,...interfaces.map(x=>x.name)]); unique(imports); unique(exports);
  const known=new Set(interfaces.map(x=>x.name));
  for(const edge of [...imports,...exports]) if(!known.has(edge))fail('MISSING_INTERFACE');
  return Object.freeze({contract,packageNamespace,packageName,name:worldName,interfaces,imports,exports});
}

function witType(type) {
  switch(type.tag){
    case 'scalar': return type.scalar;
    case 'named': return witName(type.name);
    case 'list': return 'list<' + witType(type.element) + '>';
    case 'option': return 'option<' + witType(type.element) + '>';
    case 'result': {
      if(type.ok===null && type.error===null)return 'result';
      if(type.ok===null)return 'result<_, ' + witType(type.error) + '>';
      if(type.error===null)return 'result<' + witType(type.ok) + '>';
      return 'result<' + witType(type.ok) + ', ' + witType(type.error) + '>';
    }
    case 'tuple': return 'tuple<' + type.elements.map(witType).join(', ') + '>';
    case 'own': return witName(type.resource);
    case 'borrow': return 'borrow<' + witName(type.resource) + '>';
    case 'future': return type.element===null ? 'future' : 'future<' + witType(type.element) + '>';
    case 'stream': return type.element===null ? 'stream' : 'stream<' + witType(type.element) + '>';
    default: fail('WIT_TYPE');
  }
}
const witField = value => witName(value.name) + ': ' + witType(value.type);
function witDefinition(value) {
  const n=witName(value.name), body=value.body;
  switch(body.tag){
    case 'alias': return '  type ' + n + ' = ' + witType(body.type) + ';\n';
    case 'resource': return '  resource ' + n + ';\n';
    case 'record': return '  record ' + n + ' { ' + body.fields.map(witField).join(', ') + ' }\n';
    case 'variant': return '  variant ' + n + ' { ' + body.cases.map(item=>witName(item.name)+(item.payload===null?'':'('+witType(item.payload)+')')).join(', ') + ' }\n';
    case 'enum': return '  enum ' + n + ' { ' + body.cases.map(witName).join(', ') + ' }\n';
    default: fail('WIT_DEFINITION');
  }
}
function witFunction(value) {
  const mode=value.asynchronous?'async func(':'func(';
  const result=value.result===null?'':' -> '+witType(value.result);
  return '  '+witName(value.name)+': '+mode+value.parameters.map(witField).join(', ')+')'+result+';\n';
}
export function renderWitFromInterfaceIr(world) {
  let out='package '+witName(world.packageNamespace)+':'+witName(world.packageName)+';\n\n';
  for(const value of world.interfaces){
    out+='interface '+witName(value.name)+' {\n';
    for(const definition of value.definitions)out+=witDefinition(definition);
    for(const fn of value.functions)out+=witFunction(fn);
    out+='}\n\n';
  }
  out+='world '+witName(world.name)+' {\n';
  for(const value of world.imports)out+='  import '+witName(value)+';\n';
  for(const value of world.exports)out+='  export '+witName(value)+';\n';
  out+='}\n';
  return out;
}

export function interfaceAndWitArtifacts(interfaceBytes, witBytes, limits={}) {
  const world=decodeInterfaceIrArtifact(interfaceBytes,limits);
  const rendered=Buffer.from(renderWitFromInterfaceIr(world));
  const supplied=Buffer.from(witBytes);
  if(!rendered.equals(supplied))fail('WIT_RELATION');
  const interfaceIdentity=artifactId(interfaceBytes,'interface-ir',interfaceIrEncodingContract);
  const witIdentity=artifactId(supplied,'wit-world',witArtifactContract);
  const relation=canonicalArtifact({
    schemaVersion:1,
    relation:interfaceToWitRelation,
    interfaceIr:interfaceIdentity,
    wit:witIdentity,
    target:'component-model',
    authority:'adapter-validation-only',
    runtimeBehavior:'not-established',
    canonicalAbi:'not-established',
  },'adapter-validation','psc-interface-wit-validation/1');
  return Object.freeze({world,interface:{bytes:Buffer.from(interfaceBytes),identity:interfaceIdentity},
    wit:{bytes:supplied,identity:witIdentity},relation});
}
