import { artifactKey, verifyArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';

export const jsScalarAbiContract = 'psc-js-scalar-abi-plan/1';
const kinds = new Set(['nat', 'int', 'uint8', 'uint16', 'uint32', 'uint64', 'usize',
  'int8', 'int16', 'int32', 'int64', 'isize', 'float', 'float32', 'bool', 'char', 'string', 'unit']);
const fail = code => { throw new TypeError('PSC_JS_ABI_' + code); };
const text = value => typeof value === 'string' && value.length > 0;
const fields = (value, names) => {
  if (!value || typeof value !== 'object' || Array.isArray(value) ||
      Object.keys(value).sort().join(',') !== [...names].sort().join(',')) fail('SCHEMA');
};
const names = value => Array.isArray(value) && value.every(text) && new Set(value).size === value.length;
function data(object, key) {
  if (!object || typeof object !== 'object') fail('BINDING');
  const descriptor = Object.getOwnPropertyDescriptor(object, key);
  if (!descriptor || !Object.hasOwn(descriptor, 'value')) fail('BINDING');
  return descriptor.value;
}
const integerNumber = (value, lo, hi) => typeof value === 'number' && Number.isInteger(value) &&
  !Object.is(value, -0) && value >= lo && value <= hi;
const integerBig = (value, lo, hi) => typeof value === 'bigint' && value >= lo && value <= hi;

export function jsScalarAbiValue(kind, value, wordBits) {
  switch (kind) {
    case 'nat': return typeof value === 'bigint' && value >= 0n;
    case 'int': return typeof value === 'bigint';
    case 'uint8': return integerNumber(value, 0, 255);
    case 'uint16': return integerNumber(value, 0, 65535);
    case 'uint32': return integerNumber(value, 0, 4294967295);
    case 'int8': return integerNumber(value, -128, 127);
    case 'int16': return integerNumber(value, -32768, 32767);
    case 'int32': return integerNumber(value, -2147483648, 2147483647);
    case 'uint64': return integerBig(value, 0n, (1n << 64n) - 1n);
    case 'int64': return integerBig(value, -(1n << 63n), (1n << 63n) - 1n);
    case 'usize': return (wordBits === 32 || wordBits === 64) && integerBig(value, 0n, (1n << BigInt(wordBits)) - 1n);
    case 'isize': return (wordBits === 32 || wordBits === 64) && integerBig(value, -(1n << BigInt(wordBits - 1)), (1n << BigInt(wordBits - 1)) - 1n);
    case 'bool': return typeof value === 'boolean';
    case 'float': return typeof value === 'number';
    case 'float32': return typeof value === 'number' && (Number.isNaN(value) || Object.is(Math.fround(value), value));
    case 'char': {
      if (typeof value !== 'string' || value.length < 1 || value.length > 2) return false;
      const code = value.codePointAt(0);
      return !(code >= 0xd800 && code <= 0xdfff) && String.fromCodePoint(code) === value;
    }
    case 'string': return typeof value === 'string' && value.isWellFormed();
    case 'unit': return value === undefined;
    default: return false;
  }
}

/** Consumer pins a freshly validated plan; providers are explicit host-selected
 * namespaces of synchronous functions. Neither a plan nor this binding checks
 * foreign behavior, constrains host effects, or creates compiler authority.
 */
export function bindJsScalarImports({ plan, expectedPlanId, providers, grantedCapabilities,
  limits = {} }) {
  if (!names(grantedCapabilities)) fail('CAPABILITY_POLICY');
  if (plan?.identity?.domain !== 'abi-plan' || plan.identity.contract !== jsScalarAbiContract ||
      artifactKey(plan.identity) !== artifactKey(expectedPlanId)) fail('PLAN_ID');
  const maxBytes = limits.maxBytes ?? 1024 * 1024;
  const maxStringCodeUnits = limits.maxStringCodeUnits ?? 8 * 1024 * 1024;
  const maxIntegerBits = limits.maxIntegerBits ?? 65536;
  if (!Number.isSafeInteger(maxStringCodeUnits) || maxStringCodeUnits < 0 ||
      !Number.isSafeInteger(maxIntegerBits) || maxIntegerBits < 0 || maxIntegerBits > 1048576) fail('VALUE_LIMIT_POLICY');
  const integerLimit = 1n << BigInt(maxIntegerBits);
  const withinBudget = item => {
    if (typeof item === 'string' && item.length > maxStringCodeUnits) fail('STRING_LIMIT');
    if (typeof item === 'bigint' && (item >= integerLimit || item <= -integerLimit)) fail('INTEGER_LIMIT');
  };
  if (!Number.isSafeInteger(maxBytes) || maxBytes < 0 || !(plan.bytes instanceof Uint8Array) ||
      plan.bytes.byteLength > maxBytes) fail('PLAN_BYTES_LIMIT');
  const bytes = Buffer.from(plan.bytes);
  verifyArtifact(bytes, expectedPlanId);
  const value = decodeComparatorJson(bytes, { maxBytes: 1024 * 1024, maxDepth: 12, maxNodes: 65536, ...limits });
  fields(value, ['contract', 'imports', 'runtimeSemantics', 'target', 'wordBits']);
  if (value.contract !== jsScalarAbiContract || value.target !== 'javascript' ||
      value.runtimeSemantics !== 'psc-runtime-semantics/1' || ![32, 64].includes(value.wordBits) ||
      !Array.isArray(value.imports) || value.imports.length > 4096) fail('PROFILE');
  const prepared = [], seen = new Set(), grants = new Set(grantedCapabilities);
  for (const entry of value.imports) {
    fields(entry, ['capabilities', 'exportName', 'localName', 'moduleId', 'parameters', 'result']);
    if (![entry.exportName, entry.localName, entry.moduleId].every(text) || seen.has(entry.localName) ||
        !names(entry.capabilities) || !Array.isArray(entry.parameters) || entry.parameters.length > 256 ||
        !entry.parameters.every(kind => kinds.has(kind)) || !kinds.has(entry.result)) fail('IMPORT');
    if (entry.capabilities.some(capability => !grants.has(capability))) fail('CAPABILITY_DENIED');
    seen.add(entry.localName);
    prepared.push(entry);
  }
  // Validate the whole policy before observing any provider. Own data
  // descriptors reject accessors; this is not a defense against hostile Proxy
  // objects or host functions. Providers are part of the declared host TCB.
  const bound = Object.create(null);
  for (const entry of prepared) {
    const fn = data(data(providers, entry.moduleId), entry.exportName);
    if (typeof fn !== 'function') fail('FUNCTION');
    const wrapped = (...args) => {
      if (args.length !== entry.parameters.length) fail('ARITY');
      for (let i = 0; i < args.length; i++) {
        withinBudget(args[i]);
        if (!jsScalarAbiValue(entry.parameters[i], args[i], value.wordBits)) fail('ARGUMENT');
      }
      const result = Reflect.apply(fn, undefined, args);
      withinBudget(result);
      if (!jsScalarAbiValue(entry.result, result, value.wordBits)) fail('RESULT');
      return result;
    };
    Object.freeze(wrapped);
    Object.defineProperty(bound, entry.localName, { value: wrapped, enumerable: true });
  }
  return Object.freeze(bound);
}
