import { publicApiNameKey } from './public-api-artifact.mjs';

// A deliberately syntactic source projection. It does not normalize Core,
// decide propositions or infer types from RuntimeIR / target code.
export const sourceSignatureProfile = 'psc-source-signature-structural/1';
const fail = code => { throw new Error('PSC_SOURCE_SIGNATURE_' + code); };
const rootName = name => JSON.stringify([['s', name]]);
const primitives = new Map([
  ['Nat', 'nat'], ['Int', 'int'], ['UInt8', 'uint8'], ['UInt16', 'uint16'],
  ['UInt32', 'uint32'], ['UInt64', 'uint64'], ['USize', 'usize'],
  ['Int8', 'int8'], ['Int16', 'int16'], ['Int32', 'int32'], ['Int64', 'int64'],
  ['ISize', 'isize'], ['Float', 'float'], ['Float32', 'float32'],
  ['Bool', 'bool'], ['Char', 'char'], ['String', 'string'], ['Unit', 'unit'],
].map(([name, kind]) => [rootName(name), kind]));

/** Call after decodePublicApi. Keep source generics independently of any
 * executable specialization/export policy. Unsupported source syntax is an
 * explicit product failure, never any/unknown or a guessed erased type.
 */
export function projectSourceSignature(expression, { maxNodes = 100000, maxDepth = 128 } = {}) {
  if (![maxNodes, maxDepth].every(n => Number.isSafeInteger(n) && n > 0) || maxDepth > 128) fail('RESOURCE_POLICY');
  let work = 0;
  const tick = depth => { if (++work > maxNodes || depth > maxDepth) fail('RESOURCE'); };
  function type(value, scope, depth) {
    tick(depth);
    if (value.k === 'const') {
      const kind = primitives.get(publicApiNameKey(value.n));
      if (!kind || value.ls.length) fail('NAMED_TYPE_UNSUPPORTED');
      return ['scalar', kind];
    }
    if (value.k === 'b') {
      const binding = scope[scope.length - 1 - value.i];
      if (binding?.kind !== 'type') fail('DEPENDENT_VALUE_TYPE_UNSUPPORTED');
      return ['parameter', binding.index];
    }
    if (value.k === 'app' && value.f.k === 'const' &&
        publicApiNameKey(value.f.n) === rootName('Array') && value.f.ls.length === 0) {
      return ['array', type(value.a, scope, depth + 1)];
    }
    if (value.k === 'forall') {
      const parameters = []; let body = value, inner = scope;
      while (body.k === 'forall') {
        tick(depth);
        if (inner.length >= maxDepth) fail('RESOURCE');
        if (body.t.k === 'sort') fail('HIGHER_RANK_TYPE_UNSUPPORTED');
        parameters.push(type(body.t, inner, depth + 1));
        inner = [...inner, { kind: 'value' }]; body = body.b;
      }
      return ['function', parameters, type(body, inner, depth + 1)];
    }
    fail('TYPE_FORM_UNSUPPORTED');
  }
  const typeParameters = []; let body = expression, scope = [];
  while (body.k === 'forall' && body.t.k === 'sort') {
    tick(0);
    if (scope.length >= maxDepth) fail('RESOURCE');
    // A syntactic successor is never Prop, even at an abstract universe.
    // Sort u without a successor may be Prop and is not guessed to be erased.
    if (body.t.l.k !== 's') fail('PROPOSITION_OR_AMBIGUOUS_SORT');
    const index = typeParameters.length;
    typeParameters.push({ sourceName: body.n, binderInfo: body.bi, name: 'T' + index });
    scope.push({ kind: 'type', index }); body = body.b;
  }
  return { profile: sourceSignatureProfile, typeParameters, type: type(body, scope, 0) };
}

export function sourceSignatureRuntimeType(type, typeParameters = []) {
  if (type[0] === 'scalar') return ['primitive', type[1]];
  if (type[0] === 'parameter') return ['typeParameter', typeParameters[type[1]]];
  if (type[0] === 'array') return ['named', 'Array', [sourceSignatureRuntimeType(type[1], typeParameters)]];
  if (type[0] === 'function') return ['function',
    type[1].map(value => sourceSignatureRuntimeType(value, typeParameters)),
    sourceSignatureRuntimeType(type[2], typeParameters)];
  fail('PROJECTED_TYPE');
}

const representation = Object.freeze({
  nat: 'bigint', int: 'bigint', uint64: 'bigint', int64: 'bigint', usize: 'bigint', isize: 'bigint',
  uint8: 'number', uint16: 'number', uint32: 'number', int8: 'number', int16: 'number', int32: 'number',
  float: 'number', float32: 'number', bool: 'boolean', char: 'string', string: 'string', unit: 'undefined',
});
export function printSourceSignatureType(type) {
  if (type[0] === 'scalar') return representation[type[1]];
  if (type[0] === 'parameter') return 'T' + type[1];
  if (type[0] === 'array') return 'Array<' + printSourceSignatureType(type[1]) + '>';
  if (type[0] === 'function') return '(' +
    type[1].map((value, index) => '_arg' + index + ': ' + printSourceSignatureType(value)).join(', ') +
    ') => ' + printSourceSignatureType(type[2]);
  fail('PROJECTED_TYPE');
}
