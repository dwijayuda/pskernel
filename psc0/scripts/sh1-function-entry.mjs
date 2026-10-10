import assert from 'node:assert/strict';

// Bootstrap tooling only. R and the C1 compiler it produces retain R's flat
// function-value convention. N1/C2/C3 use canonical unary returned values.
// These three existing APIs have the exact source prefixes below. Source
// parsing/emission has one current convention; this is not a language mode.
// Each public declaration has fixed named JavaScript parameters; generated
// returned closures use __ps$wrap and are invoked with the stated unary group.
const currentGroups = Object.freeze({
  psNameEq: Object.freeze([1, 1]),
  psExprAlphaEq: Object.freeze([1, 1]),
  psErasureEtaParameters: Object.freeze([2, 1, 1]),
});

export function invokeCompilerValueEntry(compiler, name, arguments_) {
  assert(Object.hasOwn(currentGroups, name), 'PSC0_SH1_COMPILER_ENTRY_NAME: ' + name);
  const groups = currentGroups[name];
  const total = groups.reduce((sum, count) => sum + count, 0);
  assert(Array.isArray(arguments_) && arguments_.length === total,
    'PSC0_SH1_COMPILER_ENTRY_ARGUMENTS: ' + name);
  const entry = compiler[name];
  assert.equal(typeof entry, 'function', 'PSC0_SH1_COMPILER_ENTRY_MISSING: ' + name);
  // Exactly the retained producer ABI; no catch/retry or result-based fallback.
  if (entry.length === total) return Reflect.apply(entry, undefined, arguments_);
  assert.equal(entry.length, groups[0], 'PSC0_SH1_COMPILER_ENTRY_ARITY: ' + name);
  let value = entry;
  let offset = 0;
  for (const count of groups) {
    assert.equal(typeof value, 'function', 'PSC0_SH1_COMPILER_ENTRY_RESULT: ' + name);
    value = Reflect.apply(value, undefined, arguments_.slice(offset, offset + count));
    offset += count;
  }
  return value;
}
