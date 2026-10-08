import { artifactId, canonicalArtifact, verifyArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';

class ValidationError extends Error {
  constructor(kind, code) { super('PSC_WASM_LITERAL_' + code); this.kind = kind; }
}
const invalid = code => { throw new ValidationError('rejectedInvalid', code); };
const unsupported = code => { throw new ValidationError('declinedUnsupported', code); };
const exhausted = code => { throw new ValidationError('resourceExhausted', code); };
const defaults = { maxBytes: 16 * 1024 * 1024, maxFunctions: 100000, maxNameBytes: 4096, maxExpectationBytes: 8 * 1024 * 1024 };

// Independent bounded decoder. It does not call the compiler's Wasm encoder,
// execute a proposed module, or accept imports/start functions/host effects.
class Reader {
  constructor(bytes, limits) { this.bytes = bytes; this.at = 0; this.limits = limits; }
  byte() { if (this.at >= this.bytes.length) invalid('TRUNCATED'); return this.bytes[this.at++]; }
  take(length) {
    if (!Number.isSafeInteger(length) || length < 0 || length > this.bytes.length - this.at) invalid('LENGTH');
    const value = this.bytes.subarray(this.at, this.at + length); this.at += length; return value;
  }
  u32() {
    let value = 0;
    for (let i = 0; i < 5; i++) {
      const byte = this.byte(), payload = byte & 127;
      if (i === 4 && (byte & 240)) invalid('ULEB_RANGE');
      value += payload * 2 ** (i * 7);
      if (!(byte & 128)) return value;
    }
    invalid('ULEB_LENGTH');
  }
  i32() {
    let value = 0n;
    for (let i = 0; i < 5; i++) {
      const byte = this.byte(), payload = byte & 127;
      if (i === 4 && ((byte & 128) || (payload > 7 && payload < 120))) invalid('SLEB_RANGE');
      value |= BigInt(payload) << BigInt(i * 7);
      if (!(byte & 128)) {
        if (byte & 64) value -= 1n << BigInt((i + 1) * 7);
        if (value < -2147483648n || value > 2147483647n) invalid('I32_RANGE');
        return value;
      }
    }
    invalid('SLEB_LENGTH');
  }
  count() { const count = this.u32(); if (count > this.limits.maxFunctions) exhausted('VECTOR_COUNT'); return count; }
  name() {
    const length = this.u32(); if (length > this.limits.maxNameBytes) exhausted('NAME_BYTES');
    try { return new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(this.take(length)); }
    catch (error) { if (error instanceof ValidationError) throw error; invalid('UTF8'); }
  }
  done() { if (this.at !== this.bytes.length) invalid('TRAILING_BYTES'); }
  section() { return new Reader(this.take(this.u32()), this.limits); }
}

function decode(bytes, bound) {
  const reader = new Reader(bytes, bound);
  if (!reader.take(8).equals(Buffer.from([0, 97, 115, 109, 1, 0, 0, 0]))) invalid('HEADER');
  const types = [], functions = [], exports = [], bodies = [];
  let previousSection = 0;
  function functionType(section) {
    if (types.length >= bound.maxFunctions) exhausted('TYPE_COUNT');
    if (section.byte() !== 0x60) unsupported('TYPE_FORM');
    if (section.u32() !== 0 || section.u32() !== 1 || section.byte() !== 0x7f) unsupported('SIGNATURE');
    types.push('i32');
  }
  while (reader.at < reader.bytes.length) {
    const id = reader.byte(), section = reader.section();
    if (id === 0) {
      section.name(); section.take(section.bytes.length - section.at); continue;
    }
    if (![1, 3, 7, 10].includes(id)) unsupported('SECTION_' + id);
    if (id <= previousSection) invalid('SECTION_ORDER_OR_DUPLICATE');
    previousSection = id;
    const count = section.count();
    for (let i = 0; i < count; i++) {
      if (id === 1) {
        // PSC emits one explicit rec group even for nonrecursive function
        // types. Only groups containing plain closed function types qualify.
        if (section.bytes[section.at] === 0x4e) {
          section.byte(); const groupSize = section.count();
          for (let j = 0; j < groupSize; j++) functionType(section);
        } else functionType(section);
      } else if (id === 3) functions.push(section.u32());
      else if (id === 7) {
        const name = section.name(); if (section.byte() !== 0) unsupported('EXPORT_KIND');
        exports.push({ name, index: section.u32() });
      } else {
        const body = section.section();
        if (body.u32() !== 0) unsupported('LOCALS');
        if (body.byte() !== 0x41) unsupported('BODY');
        const value = body.i32();
        if (body.byte() !== 0x0b) unsupported('BODY');
        body.done(); bodies.push(value);
      }
    }
    section.done();
  }
  if (functions.length !== bodies.length || functions.some(index => index >= types.length)) invalid('FUNCTION_TYPES_OR_CODE');
  if (new Set(exports.map(entry => entry.name)).size !== exports.length || exports.some(entry => entry.index >= functions.length)) invalid('EXPORTS');
  return { functions, exports, bodies };
}

/** The relation is binary -> exact literal expectation, not arbitrary Core ->
 * binary. A production caller must separately bind/check the source expectation.
 * No result is a kernel capability or a global preservation theorem.
 */
export function validateWasmLiteralBinary(input, expectation, resourceLimits = {}) {
  try {
    const bound = { ...defaults, ...resourceLimits };
    if (Object.keys(bound).some(key => !Object.hasOwn(defaults, key)) ||
        Object.values(bound).some(n => !Number.isSafeInteger(n) || n < 0)) invalid('LIMIT_POLICY');
    if (!(input instanceof Uint8Array) || input.byteLength > bound.maxBytes ||
        !(expectation?.bytes instanceof Uint8Array) || expectation.bytes.byteLength > bound.maxExpectationBytes) exhausted('BYTES');
    const bytes = Buffer.from(input), expectedBytes = Buffer.from(expectation.bytes);
    verifyArtifact(expectedBytes, expectation.identity);
    if (expectation.identity.domain !== 'wasm-literal-expectation' || expectation.identity.contract !== 'psc-wasm-literal-expectation/1') invalid('EXPECTATION_ID');
    const expected = decodeComparatorJson(expectedBytes, { maxBytes: bound.maxExpectationBytes });
    if (!expected || Object.keys(expected).sort().join(',') !== 'contract,exports' ||
        expected.contract !== 'psc-wasm-literal-expectation/1' || !Array.isArray(expected.exports)) invalid('EXPECTATION_SCHEMA');
    if (expected.exports.length > bound.maxFunctions) exhausted('EXPECTED_COUNT');
    const expectations = new Map();
    for (const entry of expected.exports) {
      if (!entry || Object.keys(entry).sort().join(',') !== 'name,type,value' || typeof entry.name !== 'string' ||
          Buffer.byteLength(entry.name) > bound.maxNameBytes || expectations.has(entry.name) ||
          !['uint32', 'int32', 'bool'].includes(entry.type) || typeof entry.value !== 'string' ||
          entry.value.length > 11 || !/^(0|-?[1-9][0-9]*)(?![\s\S])/u.test(entry.value)) invalid('EXPECTATION_ENTRY');
      const integer = BigInt(entry.value);
      const minimum = entry.type === 'int32' ? -2147483648n : 0n;
      const maximum = entry.type === 'uint32' ? 4294967295n : entry.type === 'bool' ? 1n : 2147483647n;
      if (integer < minimum || integer > maximum) invalid('EXPECTATION_RANGE');
      expectations.set(entry.name, BigInt.asIntN(32, integer));
    }
    const module = decode(bytes, bound);
    if (module.exports.length !== expectations.size || module.functions.length !== expectations.size ||
        new Set(module.exports.map(entry => entry.index)).size !== module.functions.length) invalid('MODULE_SHAPE');
    for (const entry of module.exports) {
      if (!expectations.has(entry.name) || expectations.get(entry.name) !== module.bodies[entry.index]) invalid('LITERAL_MISMATCH');
    }
    return { kind: 'accepted', contract: 'psc-wasm-literal-binary-validation/1',
      binaryId: artifactId(bytes, 'wasm-binary', 'webassembly-core/1'),
      expectationId: canonicalArtifact(expected, 'wasm-literal-expectation', 'psc-wasm-literal-expectation/1').identity,
      relation: 'closed-i32-literal-export-behavior', functions: module.functions.length,
      authority: 'validation-data-only', sourcePreservation: 'requires-separately-checked-binding', releaseAccepted: false };
  } catch (error) {
    return { kind: error.kind === 'rejected' ? 'rejectedInvalid' : error.kind === 'inconclusive' ? 'declinedUnsupported' : error.kind ?? 'rejectedInvalid', code: error.message };
  }
}
