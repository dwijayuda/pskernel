import { canonicalBytes, canonicalArtifact, artifactKey } from './artifact-evidence.mjs';
import { assertCanonicalAdmissionsEnvelope } from './kernel-contract.mjs';

export const comparatorExportLimits = Object.freeze({ maxBytes: 16 * 1024 * 1024,
  maxDepth: 128, maxNodes: 1000000, maxAdmissions: 100000 });

export class ComparatorExportError extends Error {
  constructor(kind, code) { super(code); this.kind = kind; this.code = code; }
}
const reject = code => { throw new ComparatorExportError('rejected', code); };
const unsupported = code => { throw new ComparatorExportError('inconclusive', code); };

export function decodeComparatorJson(bytes, limits = comparatorExportLimits) {
  const bound = { ...comparatorExportLimits, ...limits };
  if (Object.values(bound).some(value => !Number.isSafeInteger(value) || value < 0)) throw new Error('PSC_COMPARATOR_LIMIT_POLICY');
  if (!(bytes instanceof Uint8Array)) reject('export-bytes-required');
  if (bytes.byteLength > bound.maxBytes) throw new ComparatorExportError('resourceExhausted', 'export-bytes');
  let value;
  try { value = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes)); }
  catch { reject('export-json'); }
  let canonical;
  try { canonical = canonicalBytes(value, bound); }
  catch (error) {
    if (error instanceof RangeError) throw new ComparatorExportError('resourceExhausted', 'export-host-stack');
    if (/EXHAUSTED/u.test(error.message)) throw new ComparatorExportError('resourceExhausted', 'export-structure');
    reject('export-canonical-shape');
  }
  if (!canonical.equals(Buffer.from(bytes))) reject('export-not-canonical');
  return value;
}

function exactFields(value, expected) {
  if (!value || typeof value !== 'object' || Array.isArray(value) ||
      Object.keys(value).sort().join(',') !== [...expected].sort().join(',')) reject('export-schema');
}

/** Conservative public meaning extracted from the actual kernel payload.
 * Transparent definition bodies, hints and safety are retained. Only theorem
 * proof bodies are omitted, and acceptance still requires checking those proofs.
 * Additional axioms, opaque/unsafe/partial declarations and unknown admission
 * forms fail closed in this initial closed-additional-assumptions profile.
 */
export function comparatorAdmissionsInterface(source, limits = comparatorExportLimits) {
  if (typeof source !== 'string') reject('admissions-text');
  const bound = { ...comparatorExportLimits, ...limits };
  const payload = decodeComparatorJson(Buffer.from(source), bound);
  exactFields(payload, ['admissions', 'format', 'version']);
  try { assertCanonicalAdmissionsEnvelope(source); }
  catch { reject('admissions-envelope'); }
  if (payload.admissions.length > bound.maxAdmissions) throw new ComparatorExportError('resourceExhausted', 'admission-count');
  const projected = [];
  for (const admission of payload.admissions) {
    exactFields(admission, ['kind', 'declaration']);
    const declaration = admission.declaration;
    if (admission.kind === 'constant') {
      if (!declaration || typeof declaration !== 'object' || Array.isArray(declaration)) reject('constant-shape');
      if (declaration.k === 'theorem') {
        exactFields(declaration, ['k', 'lp', 'n', 't', 'v']);
        const { v: _proof, ...statement } = declaration;
        projected.push({ kind: 'constant', declaration: statement });
      } else if (declaration.k === 'definition') {
        exactFields(declaration, ['h', 'k', 'lp', 'n', 's', 't', 'v']);
        if (declaration.s !== 'safe') unsupported('unsafe-or-partial-definition');
        projected.push(admission);
      } else if (declaration.k === 'axiom') {
        reject('additional-axiom-forbidden');
      } else unsupported('constant-kind-unsupported');
    } else if (admission.kind === 'inductive') {
      exactFields(declaration, ['lp', 'np', 'ts']);
      if (!Array.isArray(declaration.ts) || declaration.ts.length === 0) reject('inductive-shape');
      for (const type of declaration.ts) {
        exactFields(type, ['cs', 'n', 't']);
        if (!Array.isArray(type.cs)) reject('constructor-list');
        for (const constructor of type.cs) exactFields(constructor, ['n', 't']);
      }
      projected.push(admission);
    } else unsupported('admission-kind-unsupported');
  }
  return canonicalArtifact({ contract: 'psc-comparator-public-interface/1',
    admissionOrder: projected, additionalAssumptions: [] }, 'public-interface', 'psc-comparator-public-interface/1');
}

export function decodeComparatorExport(bytes, challenge, limits = comparatorExportLimits) {
  const value = decodeComparatorJson(bytes, limits);
  exactFields(value, ['contract', 'challengeId', 'sourceClosureId', 'admissions']);
  if (value.contract !== 'psc-comparator-export/1') reject('export-contract');
  if (artifactKey(value.challengeId) !== artifactKey(challenge.identity)) reject('challenge-mismatch');
  if (artifactKey(value.sourceClosureId) !== artifactKey(challenge.value.sourceClosureId)) reject('source-mismatch');
  const actual = comparatorAdmissionsInterface(value.admissions, limits);
  if (artifactKey(actual.identity) !== artifactKey(challenge.value.expectedInterfaceId)) reject('statement-or-interface-mismatch');
  return { admissions: value.admissions, interface: actual, additionalAssumptions: [] };
}
