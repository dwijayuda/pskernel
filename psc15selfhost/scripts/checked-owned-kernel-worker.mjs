import { parentPort, workerData } from 'node:worker_threads';
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { ownedCheckedIdentity } from './checked-kernel-identity.mjs';

const kernelUrl = new URL('../packages/pskernel-core/dist/foundation.js', import.meta.url);
if (createHash('sha256').update(readFileSync(kernelUrl)).digest('hex') !== ownedCheckedIdentity.generatedKernelSha256) {
  throw new Error('PSC2_OWNED_GENERATED_IDENTITY');
}
const k = await import(kernelUrl.href);
const tag = value => value?.[Object.getOwnPropertySymbols(value ?? {})[0]];
const nil = () => k.PsKernelList.nil();
const list = values => values.reduceRight((tail, head) => k.PsKernelList.cons(head, tail), nil());
let nodes = 0;
const fail = errorKind => { throw Object.assign(new Error(errorKind), { errorKind }); };
function shape(value, keys, depth) {
  if (++nodes > 1000000 || depth > 512) fail('input-limit');
  if (!value || Array.isArray(value) || typeof value !== 'object' ||
      Object.keys(value).sort().join(',') !== [...keys].sort().join(',')) fail('invalid-wire-shape');
}
function natural(value) {
  if (typeof value === 'number') {
    if (!Number.isSafeInteger(value) || value < 0) fail('invalid-natural');
    value = String(value);
  }
  if (typeof value !== 'string' || value.length > 5000 || !/^(0|[1-9][0-9]*)$/u.test(value)) fail('invalid-natural');
  const bits = BigInt(value).toString(2);
  if (bits === '0') return k.PsKernelNatural.zero;
  let out = k.PsKernelPositive.one;
  for (const bit of bits.slice(1)) out = k.PsKernelPositive[bit === '0' ? 'bit0' : 'bit1'](out);
  return k.PsKernelNatural.positive(out);
}
function text(value) {
  if (typeof value !== 'string' || !value.isWellFormed()) fail('invalid-text');
  const bytes = new TextEncoder().encode(value);
  let out = k.PsKernelText.empty;
  for (let i = bytes.length - 1; i >= 0; i--) out = k.PsKernelText.byte(natural(bytes[i]), out);
  return out;
}
function name(value, depth = 0) {
  shape(value, value?.k === 'a' ? ['k'] : ['k', 'p', 'v'], depth);
  if (value.k === 'a') return k.PsKernelName.anonymous;
  if (value.k === 's') return k.PsKernelName.str(name(value.p, depth + 1), text(value.v));
  if (value.k === 'n') return k.PsKernelName.num(name(value.p, depth + 1), natural(value.v));
  fail('unsupported-name');
}
function level(value, depth = 0) {
  const keys = { z: ['k'], s: ['k', 'o'], p: ['k', 'n'], max: ['k', 'l', 'r'], imax: ['k', 'l', 'r'] };
  if (!keys[value?.k]) fail('unsupported-level');
  shape(value, keys[value.k], depth);
  if (value.k === 'z') return k.PsKernelLevel.zero;
  if (value.k === 's') return k.PsKernelLevel.succ(level(value.o, depth + 1));
  // This provider profile has no universe-parameter context yet.
  if (value.k === 'p') fail('unsupported-universe-parameter');
  return k.PsKernelLevel[value.k](level(value.l, depth + 1), level(value.r, depth + 1));
}
function expr(value, depth = 0) {
  const keys = { b: ['k','i'], sort: ['k','l'], const: ['k','n','ls'], app: ['k','f','a'],
    lam: ['k','n','t','b','bi'], forall: ['k','n','t','b','bi'], let: ['k','n','t','v','b'] };
  if (!keys[value?.k]) fail(`unsupported-expression:${value?.k}`);
  shape(value, keys[value.k], depth);
  const E = k.PsKernelExpr, sub = item => expr(item, depth + 1);
  switch (value.k) {
    case 'b': return E.bvar(natural(value.i));
    case 'sort': return E.sortE(level(value.l, depth + 1));
    case 'const':
      if (!Array.isArray(value.ls) || value.ls.length !== 0) fail('unsupported-universe-instantiation');
      return E.constE(name(value.n, depth + 1), nil());
    case 'app': return E.app(sub(value.f), sub(value.a));
    case 'let': return E.letE(name(value.n, depth + 1), sub(value.t), sub(value.v), sub(value.b));
    default: {
      const binders = { default: 'explicit', implicit: 'implicit', strictImplicit: 'strictImplicit', instImplicit: 'instanceImplicit' };
      if (typeof value.bi !== 'string' || !Object.hasOwn(binders, value.bi)) fail('invalid-binder');
      const binder = binders[value.bi];
      return E[value.k === 'lam' ? 'lam' : 'forallE'](name(value.n, depth + 1), sub(value.t), sub(value.b), k.PsKernelBinder[binder]);
    }
  }
}
let admissionIndex = 0;
try {
  const input = JSON.parse(workerData.admissions);
  shape(input, ['format', 'version', 'admissions'], 0);
  if (input.format !== 'proofscript-checked-admissions' || input.version !== 2 || !Array.isArray(input.admissions)) fail('invalid-wire-format');
  const definitions = [];
  for (const admission of input.admissions) {
    shape(admission, ['kind', 'declaration'], 0);
    if (admission.kind !== 'constant') fail(`unsupported-admission:${admission.kind}`);
    const d = admission.declaration;
    if (d?.k !== 'definition') fail(`unsupported-declaration:${d?.k}`);
    shape(d, ['k','n','lp','t','v','h','s'], 0);
    if (!Array.isArray(d.lp) || d.lp.length) fail('unsupported-universe-parameter');
    if (d.s !== 'safe') fail('unsupported-safety');
    shape(d.h, ['k','h'], 0);
    if (d.h.k !== 'regular') fail('unsupported-reducibility');
    natural(d.h.h); // Height is a reduction hint; it grants no admission authority.
    definitions.push(k.PsKernelDefinition.definition(name(d.n), expr(d.t), expr(d.v)));
    admissionIndex++;
  }
  let state = k.psKernelAdmissionStart(list(definitions));
  admissionIndex = 0;
  let answer;
  for (let steps = 0; steps < workerData.maxSteps; steps++) {
    const out = k.psKernelAdmissionStep(state);
    if (tag(out) === 'final') {
      const result = out.result, status = tag(result);
      answer = status === 'admitted'
        ? { accepted: true, admissionCount: definitions.length, steps: steps + 1 }
        : { accepted: false, errorKind: status === 'rejected' ? tag(result.error) : status, admissionIndex, steps: steps + 1 };
      break;
    }
    if (tag(out) !== 'next') fail('invalid-generated-step');
    if (tag(state) === 'checking' && tag(out.state) === 'pending') admissionIndex++;
    state = out.state;
  }
  parentPort.postMessage(answer ?? { accepted: false, errorKind: 'outOfFuel', admissionIndex, steps: workerData.maxSteps });
} catch (error) {
  parentPort.postMessage({ accepted: false, errorKind: error.errorKind ?? 'invalid-input-or-kernel-failure', admissionIndex });
}
