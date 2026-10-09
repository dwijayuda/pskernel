// A deliberately small command profile, not a second general Wasm validator.
// V8 validates instruction types after this bounded structural/capability check.
export const commandWasmLimits = Object.freeze({
  moduleBytes: 4096, linearMemoryBytes: 0, locals: 32, controlDepth: 32, wallTimeMs: 2000,
});
const error = suffix => { throw new Error('PSC_EXTENSION_WASM_' + suffix); };
const equal = (a, b) => a.length === b.length && b.every((value, index) => a[index] === value);

function reader(bytes) { return { bytes, at: 0 }; }
function byte(input) {
  if (input.at >= input.bytes.length) error('TRUNCATED');
  return input.bytes[input.at++];
}
function integer(input, maximum = 4096) {
  let value = 0;
  for (let index = 0; index < 5; index++) {
    const part = byte(input);
    if (index === 4 && (part & 0xf0)) error('INTEGER');
    value += (part & 0x7f) * 2 ** (7 * index);
    if (!(part & 0x80)) {
      if ((index > 0 && part === 0) || value > maximum) error('INTEGER');
      return value;
    }
  }
  error('INTEGER');
}
function section(input, expected) {
  if (byte(input) !== expected) error('SECTION');
  const length = integer(input);
  if (input.at + length > input.bytes.length) error('TRUNCATED');
  const part = reader(input.bytes.subarray(input.at, input.at + length));
  input.at += length;
  return part;
}
function signedInteger(input) {
  for (let index = 0; index < 5; index++) {
    const part = byte(input);
    if (index === 4 && (part & 0xf0) !== 0 && (part & 0xf0) !== 0x70) error('INTEGER');
    if (!(part & 0x80)) return;
  }
  error('INTEGER');
}

export function assertCommandWasmProfile(bytes) {
  if (!(bytes instanceof Uint8Array) || bytes.length > commandWasmLimits.moduleBytes ||
      !equal(bytes.subarray(0, 8), [0, 97, 115, 109, 1, 0, 0, 0])) error('HEADER');
  const input = reader(bytes);
  input.at = 8;
  // Exactly one (i32) -> i32 function, exported as psc_event. No custom,
  // import, memory, table, global, start, data, element, tag or GC sections.
  if (!equal(section(input, 1).bytes, [1, 0x60, 1, 0x7f, 1, 0x7f]) ||
      !equal(section(input, 3).bytes, [1, 0]) ||
      !equal(section(input, 7).bytes, [1, 9, 112, 115, 99, 95, 101, 118, 101, 110, 116, 0, 0])) {
    error('ABI');
  }
  const code = section(input, 10);
  if (input.at !== bytes.length || integer(code, 1) !== 1) error('SECTION');
  const bodyLength = integer(code);
  if (bodyLength !== code.bytes.length - code.at) error('BODY');
  let locals = 0;
  const groups = integer(code, commandWasmLimits.locals);
  for (let group = 0; group < groups; group++) {
    locals += integer(code, commandWasmLimits.locals);
    if (locals > commandWasmLimits.locals || byte(code) !== 0x7f) error('LOCALS');
  }
  let depth = 1;
  while (code.at < code.bytes.length) {
    const opcode = byte(code);
    if ([0x02, 0x03, 0x04].includes(opcode)) {
      if (![0x40, 0x7f].includes(byte(code)) || ++depth > commandWasmLimits.controlDepth) error('CONTROL');
    } else if (opcode === 0x0b) {
      if (--depth === 0) {
        if (code.at !== code.bytes.length) error('BODY');
        return true;
      }
    } else if (opcode === 0x0c || opcode === 0x0d) {
      integer(code, commandWasmLimits.controlDepth);
    } else if (opcode >= 0x20 && opcode <= 0x22) {
      integer(code, locals); // one parameter at index zero, followed by locals
    } else if (opcode === 0x41) {
      signedInteger(code);
    } else if (![0x00, 0x01, 0x05, 0x0f, 0x1a, 0x1b].includes(opcode) &&
        !(opcode >= 0x45 && opcode <= 0x4f) && !(opcode >= 0x67 && opcode <= 0x78)) {
      // In particular: no calls/recursion, references, heap allocation, memory,
      // SIMD, threads/atomics, host services or future instruction prefixes.
      error('OPCODE');
    }
  }
  error('BODY');
}
