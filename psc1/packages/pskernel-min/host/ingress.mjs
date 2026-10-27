// Bounded bytes-only research ingress. The parser only proposes a witness.
// Acceptance belongs exclusively to the generated psMinCoreAdmit implementation.
// Production checker modes remain gated in toolchain.mjs.
const U8 = Uint8Array;
const u8Prototype = U8.prototype;
const typedPrototype = Object.getPrototypeOf(u8Prototype);
const getLength = Object.getOwnPropertyDescriptor(typedPrototype, 'length').get;
const getBuffer = Object.getOwnPropertyDescriptor(typedPrototype, 'buffer').get;
const jsonParse = JSON.parse;
const textDecoder = new TextDecoder('utf-8', { fatal: true });
const decodeText = TextDecoder.prototype.decode;
const view = ArrayBuffer.isView;
const prototype = Object.getPrototypeOf;
const apply = Reflect.apply;
const frozen = Object.freeze;
export const ingressLimits = frozen({
  bytes: 65536, jsonDepth: 112, jsonContainers: 4096, nodes: 4096,
  expressionDepth: 48, nameDepth: 16, nameBytes: 128,
  declarations: 128, numberExclusive: 4096, numberDigits: 4,
});
export const regularIngressLimits = frozen({
  bytes: 2 * 1024 * 1024, jsonDepth: 768, jsonContainers: 131072, nodes: 65536,
  expressionDepth: 256, nameDepth: 16, nameBytes: 128,
  declarations: 512, numberExclusive: 65537, numberDigits: 5,
});
const failure = code => frozen({ accepted: false, code, delegated: false });
function snapshot(input, limits) {
  if (!view(input) || prototype(input) !== u8Prototype) throw Error('INPUT_TYPE');
  const buffer = apply(getBuffer, input, []);
  if (prototype(buffer) !== ArrayBuffer.prototype) throw Error('INPUT_BUFFER');
  const length = apply(getLength, input, []);
  if (length > limits.bytes) throw Error('BYTE_BUDGET');
  const copy = new U8(length);
  for (let i = 0; i < length; ++i) copy[i] = input[i];
  return copy;
}
function preflight(bytes, limits) {
  let depth = 0, count = 0, quoted = false;
  for (const byte of bytes) {
    if (byte < 32 || byte > 126 || byte === 92) throw Error('ASCII_PROFILE');
    if (byte === 34) quoted = !quoted;
    else if (!quoted) {
      if (byte === 123 || byte === 91) {
        if (++depth > limits.jsonDepth || ++count > limits.jsonContainers)
          throw Error('JSON_BUDGET');
      } else if (byte === 125 || byte === 93) {
        if (--depth < 0) throw Error('JSON_SHAPE');
      }
    }
  }
  if (quoted || depth !== 0) throw Error('JSON_SHAPE');
}
function ascii(bytes) { return apply(decodeText, textDecoder, [bytes]); }

// The host supplies the generated module through a trusted dependency. Inputs
// cannot nominate another module, provider, executable or checker mode.
export function createCoreIngress(generated) { return createByteIngress(generated, false); }
export function createRegularCoreIngress(generated) { return createByteIngress(generated, true); }
function createByteIngress(generated, regular) {
  const G = generated;
  const limits = regular ? regularIngressLimits : ingressLimits;
  const list = values => {
    let result = G.List.nil();
    for (let i = values.length - 1; i >= 0; --i) result = G.List.cons(values[i], result);
    return result;
  };
  const byteList = bytes => list(Array.from(bytes, BigInt));
  const reject = code => { throw Error(code); };
  const natural = value => {
    if (!Number.isSafeInteger(value) || value < 0 || value >= limits.numberExclusive) reject('NUMBER');
    return BigInt(value);
  };
  const decimal = value => {
    if (typeof value !== 'string' || value.length > limits.numberDigits || !/^(0|[1-9][0-9]*)$/.test(value)) reject('DECIMAL');
    return natural(Number(value));
  };
  const text = value => {
    if (typeof value !== 'string' || value.length > limits.nameBytes) reject('NAME_TEXT');
    const codes = [];
    for (const char of value) {
      const code = char.charCodeAt(0);
      if (code < 32 || code > 126 || code === 34 || code === 92) reject('NAME_TEXT');
      codes.push(BigInt(code));
    }
    return list(codes);
  };
  return function checkCanonicalBytes(input) {
    try {
      const bytes = snapshot(input, limits);
      preflight(bytes, limits);
      let source = jsonParse(ascii(bytes));
      let nodes = 0;
      const node = (value, depth, limit) => {
        if (depth > limit || ++nodes > limits.nodes ||
            !value || typeof value !== 'object' || Array.isArray(value)) reject('AST_BUDGET');
      };
      const name = (value, depth = 1) => {
        node(value, depth, limits.nameDepth);
        if (value.k === 'a') return G.PsMinCoreName.anonymous;
        if (value.k === 's') return G.PsMinCoreName.str(name(value.p, depth + 1), text(value.v));
        if (value.k === 'n') return G.PsMinCoreName.num(name(value.p, depth + 1), decimal(value.v));
        reject('NAME_TAG');
      };
      const level = value => {
        node(value, 1, 1);
        if (value.k === 'z') return 0n;
        if (value.k === 's') {
          node(value.o, 1, 1);
          if (value.o.k === 'z') return 1n;
        }
        reject('LEVEL');
      };
      const binder = value => {
        const index = ['default', 'implicit', 'strictImplicit', 'instImplicit'].indexOf(value);
        if (index < 0) reject('BINDER');
        return BigInt(index);
      };
      const expr = (value, depth = 1) => {
        node(value, depth, limits.expressionDepth);
        const E = G.PsMinCoreExpr;
        if (regular && value.k === 'sort') return E.sort(level(value.l));
        if (regular && value.k === 'proj') return E.projection(name(value.n), natural(value.i), expr(value.e, depth + 1));
        if (value.k === 'b') return E.bvar(natural(value.i));
        if (value.k === 'nat') return E.natural(decimal(value.v));
        if (value.k === 'const') {
          if (!Array.isArray(value.ls) || value.ls.length > 1) reject('LEVELS');
          return E.constant(name(value.n), list(value.ls.map(level)));
        }
        if (value.k === 'app') return E.app(expr(value.f, depth + 1), expr(value.a, depth + 1));
        if (value.k === 'lam' || value.k === 'forall') {
          const n = name(value.n), bi = binder(value.bi);
          const t = expr(value.t, depth + 1), b = expr(value.b, depth + 1);
          return value.k === 'lam' ? E.lam(n, bi, t, b) : E.forallE(n, bi, t, b);
        }
        if (value.k === 'let') return E.letE(name(value.n), expr(value.t, depth + 1),
          expr(value.v, depth + 1), expr(value.b, depth + 1));
        reject('EXPRESSION_TAG');
      };
      if (!source || typeof source !== 'object' || source.format !== 'proofscript-checked-admissions' ||
          source.version !== 2 || !Array.isArray(source.admissions) ||
          source.admissions.length > limits.declarations) reject('ROOT');
      const declarations = source.admissions.map(admission => {
        if (regular && admission?.kind === 'inductive') {
          const d = admission.declaration;
          if (!d || !Array.isArray(d.lp) || d.lp.length !== 0 || d.np !== 0 ||
              !Array.isArray(d.ts) || d.ts.length !== 1) reject('INDUCTIVE_DOMAIN');
          const family = d.ts[0];
          if (!family || !Array.isArray(family.cs) || family.cs.length > limits.declarations) reject('CONSTRUCTORS');
          const constructors = family.cs.map(c => G.psMinRegCoreMakeConstructor(name(c.n), expr(c.t)));
          return G.PsMinRegCoreEntry.inductiveE(G.psMinRegCoreMakeGroup(name(family.n), expr(family.t), list(constructors)));
        }
        if (admission?.kind !== 'constant') reject('ADMISSION_KIND');
        const d = admission.declaration;
        if (!d || d.k !== 'definition' || d.s !== 'safe' ||
            !Array.isArray(d.lp) || d.lp.length !== 0 ||
            !d.h || d.h.k !== 'regular') reject('DECLARATION');
        const definition = G.psMinCoreMakeDeclaration(name(d.n), decimal(d.h.h), expr(d.t), expr(d.v));
        return regular ? G.PsMinRegCoreEntry.definition(definition) : definition;
      });
      source = null;
      // The exact original snapshot is checked, including unknown/duplicate
      // fields, ordering, numbers, metadata and complete input consumption.
      const checked = regular ? G.psMinRegCoreAdmit(byteList(bytes), list(declarations))
        : G.psMinCoreAdmit(byteList(bytes), list(declarations));
      const none = G.Option.none();
      const tag = Object.getOwnPropertySymbols(none)[0];
      if (checked[tag] !== 'some') return failure('PSC1_MIN_CORE_REFUSED');
      const interpreted = regular ? checked.value.checked : checked.value;
      return frozen({ accepted: true, code: 'PSC1_MIN_CORE_ACCEPTED', delegated: false,
        profile: regular ? 'psc1-min-core-regular/1' : 'psc1-min-core-simple/1', byteLength: bytes.length,
        declarationCount: declarations.length, source: checked.value.source,
        normalized: interpreted.normalized, types: interpreted.types });
    } catch (error) {
      // All failures remain refusals. No provider fallback is reachable here.
      return failure('PSC1_MIN_CORE_' + (error?.message || 'REFUSED'));
    }
  };
}
