import { artifactId } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';

export const irEncodingContract = 'psc-runtime-ir-json/1';
const primitives = new Set('nat int uint8 uint16 uint32 uint64 usize int8 int16 int32 int64 isize float float32 bool char string unit'.split(' '));
const machines = new Set('uint8 uint16 uint32 uint64 usize int8 int16 int32 int64 isize'.split(' '));
const simpleIntrinsics = new Set('uint8OfNat natAdd natSub natMul natDiv natMod natEq natNe natLe natLt intOfNat intRepr intNegSucc intNeg intAdd intSub intMul intEq intLe intLt boolNot boolAnd boolOr boolEq boolNe charOfNat charToNat stringPush stringSingleton stringLength stringAppend stringUtf8ByteSize stringNext stringGet stringAtEnd stringExtract stringEq arrayEmptyWithCapacity arraySize arrayPush arrayGet arrayGetD arraySet arraySetIfInBounds arrayMap arrayFoldl'.split(' '));
const fail = () => { throw new Error('PSC_IR_ENCODING_SCHEMA'); };
const arr = (value, count) => { if (!Array.isArray(value) || (count !== undefined && value.length !== count)) fail(); return value; };
const str = value => { if (typeof value !== 'string' || !value.isWellFormed()) fail(); };
const member = (value, values) => { if (!values.has(value)) fail(); };
function intrinsic(value) {
  arr(value);
  if (simpleIntrinsics.has(value[0])) { arr(value, 1); return; }
  arr(value, 3);
  switch (value[0]) {
    case 'machineIntBinary': member(value[1], machines); member(value[2], new Set(['add','sub','mul','bitAnd','bitOr','bitXor'])); break;
    case 'machineIntCompare': member(value[1], machines); member(value[2], new Set(['eq','ne','lt','le','gt','ge'])); break;
    case 'floatBinary': member(value[1], new Set(['float','float32'])); member(value[2], new Set(['add','sub','mul','div'])); break;
    case 'floatCompare': member(value[1], new Set(['float','float32'])); member(value[2], new Set(['eq','ne','lt','le','gt','ge'])); break;
    default: fail();
  }
}
function literal(value) {
  arr(value);
  switch (value[0]) {
    case 'natural': arr(value, 2); if (typeof value[1] !== 'string' || !/^(?:0|[1-9][0-9]*)(?![\s\S])/u.test(value[1])) fail(); break;
    case 'integer': arr(value, 2); if (typeof value[1] !== 'string' || !/^(?:0|-?[1-9][0-9]*)(?![\s\S])/u.test(value[1])) fail(); break;
    case 'machineInteger': arr(value, 3); member(value[1], machines); literal(['integer', value[2]]); break;
    case 'bool': arr(value, 2); if (typeof value[1] !== 'boolean') fail(); break;
    case 'string': arr(value, 2); str(value[1]); if (!value[1].isWellFormed()) fail(); break;
    case 'unit': arr(value, 1); break;
    default: fail();
  }
}

/** Checks only the complete encoding schema. Type/scope/invariant validation
 * remains a separate pass; even construction IR with unknown types is encodable.
 */
export function decodeIrArtifact(bytes, limits = {}) {
  const root = decodeComparatorJson(bytes, { maxBytes: 128 * 1024 * 1024, maxDepth: 512, maxNodes: 2000000, ...limits });
  arr(root, 5); if (root[0] !== irEncodingContract) fail();
  const work = [];
  const push = (kind, value) => work.push([kind, value]);
  const many = (kind, values) => { for (const value of arr(values)) push(kind, value); };
  const binders = values => { for (const value of arr(values)) str(value); };
  many('import', root[1]); many('structure', root[2]); many('inductive', root[3]); many('declaration', root[4]);
  while (work.length) {
    const [kind, value] = work.pop(); arr(value);
    switch (kind) {
      case 'import': arr(value, 4); str(value[0]); str(value[1]); str(value[2]); push('type', value[3]); break;
      case 'structure': arr(value, 3); str(value[0]); binders(value[1]); many('fieldType', value[2]); break;
      case 'inductive': arr(value, 3); str(value[0]); binders(value[1]); many('constructor', value[2]); break;
      case 'constructor': arr(value, 2); str(value[0]); many('fieldType', value[1]); break;
      case 'fieldType': arr(value, 2); str(value[0]); push('type', value[1]); break;
      case 'declaration': arr(value, 5); str(value[0]); binders(value[1]); many('fieldType', value[2]); push('type', value[3]); push('expr', value[4]); break;
      case 'field': arr(value, 2); str(value[0]); push('expr', value[1]); break;
      case 'binding': arr(value, 3); str(value[0]); str(value[1]); push('type', value[2]); break;
      case 'alternative': arr(value, 3); str(value[0]); many('binding', value[1]); push('expr', value[2]); break;
      case 'type':
        switch (value[0]) {
          case 'unknown': arr(value, 1); break;
          case 'typeParameter': arr(value, 2); str(value[1]); break;
          case 'primitive': arr(value, 2); member(value[1], primitives); break;
          case 'named': arr(value, 3); str(value[1]); many('type', value[2]); break;
          case 'function': arr(value, 3); many('type', value[1]); push('type', value[2]); break;
          default: fail();
        }
        break;
      case 'expr':
        switch (value[0]) {
          case 'literal': arr(value, 2); literal(value[1]); break;
          case 'var': arr(value, 2); str(value[1]); break;
          case 'intrinsic': arr(value, 4); intrinsic(value[1]); many('type', value[2]); many('expr', value[3]); break;
          case 'lambda': arr(value, 4); many('fieldType', value[1]); push('type', value[2]); push('expr', value[3]); break;
          case 'call': arr(value, 4); push('expr', value[1]); many('type', value[2]); many('expr', value[3]); break;
          case 'let': arr(value, 5); str(value[1]); push('type', value[2]); push('expr', value[3]); push('expr', value[4]); break;
          case 'if': arr(value, 4); many('expr', value.slice(1)); break;
          case 'record': arr(value, 4); str(value[1]); many('type', value[2]); many('field', value[3]); break;
          case 'projection': arr(value, 5); str(value[1]); many('type', value[2]); push('expr', value[3]); str(value[4]); break;
          case 'constructor': arr(value, 5); str(value[1]); str(value[2]); many('type', value[3]); many('field', value[4]); break;
          case 'match': arr(value, 5); str(value[1]); many('type', value[2]); push('expr', value[3]); many('alternative', value[4]); break;
          default: fail();
        }
        break;
      default: fail();
    }
  }
  return root;
}

export function checkedIrStageArtifacts(stages, { maxBytes = 128 * 1024 * 1024 } = {}) {
  if (stages === undefined) return undefined;
  if (!stages || typeof stages.runtimeIr !== 'string' || typeof stages.verifiedIr !== 'string') fail();
  const result = {};
  const fields = [['runtimeIr', 'runtime-ir'], ['verifiedIr', 'verified-ir']];
  if (Object.hasOwn(stages, 'specializedIr')) {
    if (typeof stages.specializedIr !== 'string') fail();
    fields.push(['specializedIr', 'specialized-ir']);
  }
  for (const [field, domain] of fields) {
    if (Buffer.byteLength(stages[field]) > maxBytes) throw new Error('PSC_IR_ENCODING_BYTES_LIMIT');
    const bytes = Buffer.from(stages[field]);
    decodeIrArtifact(bytes, { maxBytes });
    result[field] = Object.freeze({ bytes, identity: artifactId(bytes, domain, irEncodingContract) });
  }
  return Object.freeze(result);
}
