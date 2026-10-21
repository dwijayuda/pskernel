// Host transport for the current independently executing checked V1 API.
// The shared canonical wire codec has no environment or checking authority.
// No kernel-decision fallback exists here.
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import {
  createWireDecoder,
  parseCanonicalAdmissions,
} from '../npm-runtime/canonical-admissions-wire.mjs';

const identity = Object.freeze({
  protocol: 'pskernel-canonical-provider/1',
  provider: 'pskernel-core-v1',
  leanVersion: '4.35.0',
  leanCommit: 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',
  scope: 'canonical-v2-empty-environment',
});
const failure = (outcome, stage, message, extra = {}) =>
  ({ accepted: false, outcome, stage, message, ...extra });

class CanonicalWireError extends Error {
  constructor(outcome, message) { super(message); this.outcome = outcome; }
}
const wireBad = message => { throw new CanonicalWireError('malformedInput', message); };
const wireUnsupported = message => { throw new CanonicalWireError('declinedUnsupported', message); };
function keys(value, allowed) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) wireBad('expected object');
  if (Object.keys(value).some(key => !allowed.includes(key))) wireUnsupported('unrecognized transport field');
  if (allowed.some(key => !Object.hasOwn(value, key))) wireBad('missing required transport field');
}
function tagged(value, cases) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) wireBad('expected object');
  if (typeof value.k !== 'string') wireBad('expected tag');
  if (!Object.hasOwn(cases, value.k)) wireUnsupported('unsupported transport tag');
  keys(value, cases[value.k]);
  return value.k;
}
function depthGuard(depth) {
  if (depth >= 4096) throw new CanonicalWireError('resourceExhausted', 'transport depth exceeded');
}
function checkName(value, depth = 0) {
  depthGuard(depth);
  const tag = tagged(value, { a: ['k'], s: ['k','p','v'], n: ['k','p','v'] });
  if (tag !== 'a') checkName(value.p, depth + 1);
}
function checkLevel(value, depth = 0) {
  depthGuard(depth);
  const tag = tagged(value, { z: ['k'], s: ['k','o'], max: ['k','l','r'],
    imax: ['k','l','r'], p: ['k','n'] });
  if (tag === 's') checkLevel(value.o, depth + 1);
  if (tag === 'max' || tag === 'imax') {
    checkLevel(value.l, depth + 1); checkLevel(value.r, depth + 1);
  }
  if (tag === 'p') checkName(value.n, depth + 1);
}
function each(values, fn) {
  if (!Array.isArray(values)) wireBad('expected array');
  values.forEach(value => fn(value));
}
function checkExpr(value, depth = 0) {
  depthGuard(depth);
  const tag = tagged(value, {
    b:['k','i'], sort:['k','l'], const:['k','n','ls'], app:['k','f','a'],
    lam:['k','n','t','b','bi'], forall:['k','n','t','b','bi'],
    let:['k','n','t','v','b'], nat:['k','v'], str:['k','v'], proj:['k','n','i','e'],
  });
  const d = depth + 1;
  if (tag === 'sort') checkLevel(value.l, d);
  if (tag === 'const') { checkName(value.n, d); each(value.ls, x => checkLevel(x, d)); }
  if (tag === 'app') { checkExpr(value.f, d); checkExpr(value.a, d); }
  if (tag === 'lam' || tag === 'forall' || tag === 'let') {
    checkName(value.n, d); checkExpr(value.t, d); checkExpr(value.b, d);
    if (tag === 'let') checkExpr(value.v, d);
    else if (!['default','implicit','strictImplicit','instImplicit'].includes(value.bi)) wireBad('binder tag');
  }
  if (tag === 'proj') { checkName(value.n, d); checkExpr(value.e, d); }
}
function validateRequest(value) {
  keys(value, ['kind','declaration']);
  const d = value.declaration;
  if (typeof value.kind !== 'string') wireBad('expected admission kind string');
  if (value.kind === 'constant') {
    const tag = tagged(d, {
      definition:['k','n','lp','t','v','s','h'],
      theorem:['k','n','lp','t','v'],
    });
    checkName(d.n); each(d.lp, checkName); checkExpr(d.t); checkExpr(d.v);
    if (tag === 'definition') {
      if (typeof d.s !== 'string') wireBad('expected definition safety string');
      keys(d.h, ['k','h']);
      if (typeof d.h.k !== 'string') wireBad('expected definition hint string');
    }
  } else if (value.kind === 'inductive') {
    keys(d, ['lp','np','ts']); each(d.lp, checkName);
    each(d.ts, type => {
      keys(type, ['n','t','cs']); checkName(type.n); checkExpr(type.t);
      each(type.cs, ctor => { keys(ctor, ['n','t']); checkName(ctor.n); checkExpr(ctor.t); });
    });
  } else wireUnsupported('admission kind outside canonical provider scope');
}

function variant(value) {
  if (value === null || typeof value !== 'object') throw Error('invalid generated variant');
  const tags = Object.getOwnPropertySymbols(value).map(key => value[key]);
  if (tags.length !== 1 || typeof tags[0] !== 'string') throw Error('invalid generated variant tag');
  return tags[0];
}

function unpack(result) {
  const tag = variant(result);
  if (tag === 'ok' && Object.hasOwn(result, 'value')) return { ok: true, value: result.value };
  if (tag === 'error' && Object.hasOwn(result, 'error')) return { ok: false, error: result.error };
  throw Error('invalid generated Except');
}

function fromKernel(error) {
  const tag = variant(error);
  if (!['rejectedInvalid', 'declinedUnsupported', 'resourceExhausted', 'internalError'].includes(tag) ||
      typeof error.message !== 'string') throw Error('invalid generated kernel error');
  const extra = tag === 'resourceExhausted' ? { resource: variant(error.resource) } : {};
  return failure(tag, 'kernel', error.message, extra);
}

function fromTransport(error) {
  const message = String(error?.message || error);
  if (error instanceof CanonicalWireError) return failure(error.outcome, 'transport', message);
  if (error instanceof RangeError) return failure('resourceExhausted', 'transport', message, { resource: 'hostStack' });
  if (error instanceof SyntaxError) return failure('malformedInput', 'transport', message);
  if (/^PSC0_GENERATED_CORE_(?:NAME|LEVEL|EXPR)_DEPTH$/u.test(message))
    return failure('resourceExhausted', 'transport', message);
  if (/^PSC0_GENERATED_CORE_(?:UNSUPPORTED_DEFINITION|CONSTANT_KIND|ADMISSION_KIND|ADMISSIONS_VERSION|EXPR_TAG|LEVEL_TAG)$/u.test(message))
    return failure('declinedUnsupported', 'transport', message);
  if (message.startsWith('PSC0_GENERATED_CORE_'))
    return failure('malformedInput', 'transport', message);
  return failure('internalError', 'provider', message);
}

// This API accepts a fresh canonical batch, never an externally supplied
// environment, cache, receipt or native evaluator. No partial session escapes.
export function checkCanonicalBatch(kernel, source, { fuel = 4096n } = {}) {
  if (typeof source !== 'string') throw TypeError('canonical admissions must be UTF-8 text');
  if (typeof fuel !== 'bigint' || fuel < 0n || fuel > 4096n)
    throw RangeError('provider fuel must be a BigInt in 0..4096');
  const wrap = result => Object.freeze({ ...identity, fuel: String(fuel), ...result });
  if (Buffer.byteLength(source, 'utf8') > 16 * 1024 * 1024)
    return wrap(failure('resourceExhausted', 'transport', 'transport input byte limit exceeded'));
  let index;
  try {
    const target = kernel.psKernelTargetIdentityV1;
    if (target?.contract !== 'KernelContract-v1' ||
        target.leanVersion !== identity.leanVersion || target.leanCommit !== identity.leanCommit)
      return wrap(failure('declinedUnsupported', 'provider', 'kernel target identity mismatch'));
    const wire = JSON.parse(source);
    keys(wire, ['format', 'version', 'admissions']);
    if (typeof wire.format !== 'string') wireBad('expected admissions format string');
    const requests = parseCanonicalAdmissions(source);
    if (requests.length > 20000)
      return wrap(failure('resourceExhausted', 'transport', 'transport declaration count exceeded'));
    const decoder = createWireDecoder(kernel);
    const initial = unpack(kernel.psKernelKernelSessionEmpty(
      { ...kernel.psKernelResourcePolicyDefault, fuel }, kernel.psKernelProviderDefault));
    if (!initial.ok) return wrap(fromKernel(initial.error));
    let session = initial.value;
    const preflight = unpack(kernel.psKernelKernelSessionPreflight(session));
    if (!preflight.ok) return wrap(fromKernel(preflight.error));
    for (index = 0; index < requests.length; index++) {
      validateRequest(requests[index]);
      const request = decoder.request(requests[index]);
      const checked = unpack(kernel.psKernelV1AdmitDeclaration(session, request));
      if (!checked.ok) return wrap({ ...fromKernel(checked.error), declarationIndex: index });
      session = checked.value.session;
    }
    const size = kernel.psKernelEnvironmentSize(session.environment);
    if (typeof size !== 'bigint' || size > BigInt(Number.MAX_SAFE_INTEGER))
      throw Error('invalid generated environment size');
    return wrap({ accepted: true, outcome: 'accepted', stage: 'complete',
      declarationCount: requests.length, environmentSize: Number(size) });
  } catch (error) {
    return wrap({ ...fromTransport(error), ...(index === undefined ? {} : { declarationIndex: index }) });
  }
}

if (process.argv[1] && pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url) {
  const args = process.argv.slice(2);
  if (!(args.length === 1 || (args.length === 3 && args[1] === '--fuel'))) {
    console.error('usage: node pskernel-canonical-provider.mjs kernel.js [--fuel 0..4096] < canonical-admissions.json');
    process.exitCode = 2;
  } else {
    try {
      const fuelText = args.length === 3 ? args[2] : '4096';
      if (!/^(0|[1-9][0-9]*)$/u.test(fuelText) || BigInt(fuelText) > 4096n)
        throw RangeError('provider fuel must be in 0..4096');
      const kernel = await import(pathToFileURL(path.resolve(args[0])).href);
      console.log(JSON.stringify(checkCanonicalBatch(kernel, readFileSync(0, 'utf8'),
        { fuel: BigInt(fuelText) })));
    } catch (error) {
      console.log(JSON.stringify({ ...identity, fuel: args[2] || '4096',
        ...failure('internalError', 'provider', String(error?.message || error)) }));
      process.exitCode = 2;
    }
  }
}
