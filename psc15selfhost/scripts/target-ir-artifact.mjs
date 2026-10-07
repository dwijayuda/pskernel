import { artifactId } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';

export const jsIrEncodingContract = 'psc-js-ir-json/1';
export const wasmIrEncodingContract = 'psc-wasm-ir-json/1';

const fail = code => { throw new Error('PSC_TARGET_IR_' + code); };
const arr = (value, count) => {
  if (!Array.isArray(value) || (count !== undefined && value.length !== count)) fail('SCHEMA');
  return value;
};
const text = value => {
  if (typeof value !== 'string' || !value.isWellFormed()) fail('STRING');
};
const bool = value => { if (typeof value !== 'boolean') fail('BOOL'); };
const oneOf = (value, choices) => { if (!choices.has(value)) fail('MEMBER'); };

const jsMachineTypes = new Set('uint8 uint16 uint32 uint64 int8 int16 int32 int64'.split(' '));
const jsUnary = new Set(['bigintNeg','boolNot']);
const jsSimpleBinary = new Set('bigintAdd bigintSub bigintMul bigintEq bigintNe bigintLe bigintLt boolAnd boolOr boolEq boolNe stringConcat stringEq'.split(' '));
const jsRuntime = new Set('uint8OfNat natSub natDiv natMod intNegSucc intRepr charOfNat charToNat stringLength stringUtf8ByteSize stringNext stringGet stringAtEnd stringExtract arrayEmptyWithCapacity arraySize arrayPush arrayGet arrayGetD arraySet arraySetIfInBounds arrayMap arrayFoldl'.split(' '));

function jsLiteral(value) {
  arr(value);
  switch (value[0]) {
    case 'natural': arr(value,2); natural(value[1]); break;
    case 'integer': arr(value,2); decimal(value[1]); break;
    case 'machineInteger': arr(value,3); oneOf(value[1],jsMachineTypes); decimal(value[2]); break;
    case 'string': arr(value,2); text(value[1]); break;
    case 'bool': arr(value,2); bool(value[1]); break;
    case 'unit': arr(value,1); break;
    default: fail('JS_LITERAL');
  }
}
function jsBinary(value) {
  arr(value);
  if (jsSimpleBinary.has(value[0])) { arr(value,1); return; }
  switch (value[0]) {
    case 'machineInt': arr(value,3); oneOf(value[1],jsMachineTypes); oneOf(value[2],new Set(['add','sub','mul','bitAnd','bitOr','bitXor'])); break;
    case 'machineIntCompare': arr(value,2); oneOf(value[1],new Set(['eq','ne','lt','le','gt','ge'])); break;
    case 'floatBinary': arr(value,3); oneOf(value[1],new Set(['float','float32'])); oneOf(value[2],new Set(['add','sub','mul','div'])); break;
    case 'floatCompare': arr(value,2); oneOf(value[1],new Set(['eq','ne','lt','le','gt','ge'])); break;
    default: fail('JS_BINARY');
  }
}
export function decodeJsIrArtifact(bytes, limits) {
  const root = decodeComparatorJson(bytes, { maxBytes: 128*1024*1024, maxDepth: 512, maxNodes: 3000000, ...limits });
  arr(root,3); if (root[0] !== jsIrEncodingContract) fail('JS_CONTRACT');
  const work = [];
  const push = (kind,value) => work.push([kind,value]);
  const many = (kind,values) => { for (const value of arr(values)) push(kind,value); };
  many('import',root[1]); many('declaration',root[2]);
  while(work.length){
    const [kind,value]=work.pop();
    switch(kind){
      case 'import': arr(value,3); value.forEach(text); break;
      case 'declaration': arr(value,3); text(value[0]); for(const p of arr(value[1])) text(p); push('expr',value[2]); break;
      case 'field': arr(value,2); text(value[0]); push('expr',value[1]); break;
      case 'binding': arr(value,2); text(value[0]); text(value[1]); break;
      case 'alternative': arr(value,3); text(value[0]); many('binding',value[1]); push('expr',value[2]); break;
      case 'expr':
        arr(value);
        switch(value[0]){
          case 'literal': arr(value,2); jsLiteral(value[1]); break;
          case 'var': arr(value,2); text(value[1]); break;
          case 'unary': arr(value,3); oneOf(value[1],jsUnary); push('expr',value[2]); break;
          case 'binary': arr(value,4); jsBinary(value[1]); push('expr',value[2]); push('expr',value[3]); break;
          case 'runtime': arr(value,3); oneOf(value[1],jsRuntime); many('expr',value[2]); break;
          case 'lambda': arr(value,3); for(const p of arr(value[1])) text(p); push('expr',value[2]); break;
          case 'call': arr(value,3); push('expr',value[1]); many('expr',value[2]); break;
          case 'let': arr(value,4); text(value[1]); push('expr',value[2]); push('expr',value[3]); break;
          case 'if': arr(value,4); push('expr',value[1]); push('expr',value[2]); push('expr',value[3]); break;
          case 'record': arr(value,2); many('field',value[1]); break;
          case 'projection': arr(value,3); push('expr',value[1]); text(value[2]); break;
          case 'constructor': arr(value,3); text(value[1]); many('field',value[2]); break;
          case 'match': arr(value,3); push('expr',value[1]); many('alternative',value[2]); break;
          default: fail('JS_EXPR');
        }
        break;
      default: fail('JS_KIND');
    }
  }
  return root;
}

const wasmValueTags=new Set(['i32','i64','f32','f64','funcRef','noValue']);
const wasmNoArgInstructions=new Set('drop unreachable return else end i32Add i32Sub i32Mul i32And i32Or i32Xor i32ShrU i32Extend8S i32Extend16S i32Eq i32Ne i32LtS i32LtU i32LeS i32LeU i32GtS i32GtU i32GeS i32GeU i64Add i64Sub i64Mul i64And i64Or i64Xor i64Eq i64Ne i64LtS i64LtU i64LeS i64LeU i64GtS i64GtU i64GeS i64GeU f32Add f32Sub f32Mul f32Div f32Eq f32Ne f32Lt f32Le f32Gt f32Ge f64Add f64Sub f64Mul f64Div f64Eq f64Ne f64Lt f64Le f64Gt f64Ge arrayLen'.split(' '));
function wasmValueType(value){
  arr(value);
  if(wasmValueTags.has(value[0])) { arr(value,1); return; }
  if(value[0]==='ref'){arr(value,2);text(value[1]);return;}
  fail('WASM_VALUE_TYPE');
}
function wasmStorage(value){
  arr(value);
  if(value[0]==='value'){arr(value,2);wasmValueType(value[1]);return;}
  if(value[0]==='packedI8'||value[0]==='packedI16'){arr(value,1);return;}
  fail('WASM_STORAGE');
}
function optionText(value){arr(value);if(value[0]==='none'){arr(value,1);return;}if(value[0]==='some'){arr(value,2);text(value[1]);return;}fail('OPTION');}
// These are the exact Nat/Int text domains emitted by the portable encoders.
// Do not narrow through Number or accept spellings such as -0, 01 or 1e3.
function decimal(value){
  text(value);
  if(!/^(?:0|-?[1-9][0-9]*)(?![\s\S])/u.test(value))fail('DECIMAL');
}
function natural(value){
  text(value);
  if(!/^(?:0|[1-9][0-9]*)(?![\s\S])/u.test(value))fail('NATURAL');
}
function wasmInstruction(value){
  arr(value); const tag=value[0];
  if(wasmNoArgInstructions.has(tag)){arr(value,1);return;}
  switch(tag){
    case 'localGet':case 'localSet':case 'arrayNewFixed':case 'structGet':case 'structGetS':case 'structGetU':
      // handled below where arity differs
      break;
    case 'call':case 'returnCall':case 'structNew':case 'arrayNew':case 'arrayNewDefault':case 'arrayGet':case 'arrayGetS':case 'arrayGetU':case 'arraySet':case 'refTest':case 'refCast':case 'refFunc':case 'refCastFunction':case 'callRef':case 'returnCallRef':
      arr(value,2);text(value[1]);return;
    case 'arrayCopy':arr(value,3);text(value[1]);text(value[2]);return;
    case 'i32Const':case 'i64Const':arr(value,2);decimal(value[1]);return;
    case 'ifStart': { arr(value,2); const option=arr(value[1]); if(option[0]==='some'){arr(option,2);wasmValueType(option[1]);} else optionText(option); return; }
  }
  if(tag==='localGet'||tag==='localSet'){arr(value,2);natural(value[1]);return;}
  if(tag==='arrayNewFixed'){arr(value,3);text(value[1]);natural(value[2]);return;}
  if(tag==='structGet'||tag==='structGetS'||tag==='structGetU'){arr(value,3);text(value[1]);natural(value[2]);return;}
  fail('WASM_INSTRUCTION');
}
export function decodeWasmIrArtifact(bytes,limits){
  const root=decodeComparatorJson(bytes,{maxBytes:128*1024*1024,maxDepth:512,maxNodes:4000000,...limits});
  arr(root,7); if(root[0]!==wasmIrEncodingContract)fail('WASM_CONTRACT');
  const work=[]; const push=(kind,value)=>work.push([kind,value]); const many=(kind,values)=>{for(const value of arr(values))push(kind,value);};
  many('struct',root[1]);many('array',root[2]);many('functionType',root[3]);many('function',root[4]);
  for(const ref of arr(root[5]))text(ref);many('export',root[6]);
  while(work.length){
    const [kind,value]=work.pop();
    switch(kind){
      case 'struct':arr(value,4);text(value[0]);optionText(value[1]);bool(value[2]);many('structField',value[3]);break;
      case 'structField':arr(value,2);text(value[0]);wasmStorage(value[1]);break;
      case 'array':arr(value,3);text(value[0]);wasmStorage(value[1]);bool(value[2]);break;
      case 'functionType':arr(value,3);text(value[0]);for(const t of arr(value[1]))wasmValueType(t);for(const t of arr(value[2]))wasmValueType(t);break;
      case 'function':arr(value,6);text(value[0]);optionText(value[1]);for(const t of arr(value[2]))wasmValueType(t);for(const t of arr(value[3]))wasmValueType(t);for(const t of arr(value[4]))wasmValueType(t);for(const ins of arr(value[5]))wasmInstruction(ins);break;
      case 'export':arr(value,2);text(value[0]);text(value[1]);break;
      default:fail('WASM_KIND');
    }
  }
  return root;
}

export function checkedTargetIrStageArtifacts(stages,{maxBytes=128*1024*1024}={}){
  if(!stages||typeof stages!=='object')return Object.freeze({});
  const result={};
  for(const [field,domain,contract,decode] of [
    ['jsIr','js-ir',jsIrEncodingContract,decodeJsIrArtifact],
    ['wasmIr','wasm-ir',wasmIrEncodingContract,decodeWasmIrArtifact],
  ]){
    if(!Object.hasOwn(stages,field))continue;
    if(typeof stages[field]!=='string')fail('STAGE_TYPE');
    const bytes=Buffer.from(stages[field]);
    if(bytes.byteLength>maxBytes)fail('BYTES_LIMIT');
    decode(bytes,{maxBytes});
    result[field]=Object.freeze({bytes,identity:artifactId(bytes,domain,contract)});
  }
  return Object.freeze(result);
}

/** Exact inventory boundary after decoding both modules. This checks names,
 * order and arity only, not lowering semantics or target instruction validity.
 */
export function assertJsDeclarationInventory(specialized, target) {
  if (specialized[4].length !== target[2].length) throw new Error('PSC_JS_LINEAGE_TARGET_DECLARATION_COVERAGE');
  for (let index = 0; index < target[2].length; index++) {
    const a = specialized[4][index], b = target[2][index];
    if (a[0] !== b[0] || a[2].length !== b[1].length ||
        a[2].some((parameter, i) => parameter[0] !== b[1][i]))
      throw new Error('PSC_JS_LINEAGE_TARGET_DECLARATION_INVENTORY');
  }
}
