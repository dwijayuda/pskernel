/**
 * Experimental PSCV-RC-v2 Lean 4.35.0-rc3 SOURCE provenance audit.
 *
 * Appendix K.1/K.2 name immutable DECLARATION/PROVER source roots. Those
 * roots explicitly DO NOT select/activate the Standard registries. This
 * verifier must never issue STD-ENV or PSCV-CERT, or assign a conformance
 * identity from its own output. The missing registry, class-mode, coverage
 * and proof obligations are permanent blockers until separately qualified.
 */
import { createHash } from 'node:crypto';

export const normativeSha256 =
  '4c02626fd0b991e8526c64b65f4ffb66b9ce7b688298e82fb0309802a263db71';
export const pinnedLeanCommit = '470d5ce1400764999581fd26d5d72b00d990b0f4';
export const pinnedLeanVersion = '4.35.0-rc3';
export const pinnedStandardIdentity = 'STD-ENV-PSCV-V1-L435RC3-RC1';
export const provenanceProtocol = 'psc-lean435rc3-provenance/0';
export const requiredRegistryGroups = Object.freeze([
  'instances', 'default_instances', 'coercions', 'simp',
  'simprocs', 'ext', 'grind',
]);

const sha = x => createHash('sha256').update(x).digest('hex');
const fail = code => { throw new Error('PSC_PSCV_PIN_AUDIT_' + code); };
const line = (kind, text) => ({ kind, text });
const sortKeys = x => Array.isArray(x) ? x.map(sortKeys) : x !== null &&
  typeof x === 'object' ? Object.fromEntries(Object.keys(x).sort()
    .map(key => [key, sortKeys(x[key])])) : x;
export const canonicalJSON = value => JSON.stringify(sortKeys(value));

export function extractLeanProvenanceBlueprint(reference) {
  if (typeof reference !== 'string' || Buffer.byteLength(reference, 'utf8') < 1024 ||
      sha(Buffer.from(reference, 'utf8')) !== normativeSha256) fail('NORMATIVE_REFERENCE_IDENTITY');
  const start = reference.indexOf('## Appendix K — ');
  const stop = reference.indexOf('\n## Appendix L', start);
  if (start < 0 || stop <= start) fail('APPENDIX_K');
  const appendix = reference.slice(start, stop);
  const a = appendix.indexOf('### K.1 ');
  const b = appendix.indexOf('### K.2 ');
  const c = appendix.indexOf('### K.3 ');
  if (a < 0 || b <= a || c <= b) fail('APPENDIX_K_SECTIONS');

  const take = (part, category) => {
    const rows = [...part.matchAll(/^\| \x60(src\/[A-Za-z0-9_./-]+\.lean)\x60 \| \x60([a-f0-9]{40})\x60 \|$/gmu)]
      .map(match => ({
        category, path: match[1], gitBlobSha1: match[2],
      }));
    // Only the pinned reference determines rows; no npm-provided registry
    // may replace/add them. The known reference currently has 23 + 17 roots.
    if (rows.length !== (category === 'semantic' ? 23 : 17)) fail('ROOT_COUNT');
    return rows;
  };
  const entries = [...take(appendix.slice(a, b), 'semantic'),
    ...take(appendix.slice(b, c), 'prover')];
  const unique = new Set(entries.map(x => x.path));
  if (unique.size !== 40 || entries.some(x => x.path.includes('..') ||
      x.path.includes('//') || x.path.startsWith('/'))) fail('PATH_REUSE');
  const identity = sortKeys({
    protocol: provenanceProtocol,
    semanticPin: { leanVersion: pinnedLeanVersion, leanCommit: pinnedLeanCommit },
    sourceReferenceSha256: normativeSha256,
    environmentIdentity: pinnedStandardIdentity,
    roots: entries.sort((a, b) => a.path.localeCompare(b.path, 'en')),
  });
  return {
    ...identity,
    provenanceBlueprintSha256: sha(Buffer.from(canonicalJSON(identity))),
    // These fields are deliberately NOT a registry snapshot.
    standardManifestComplete: false,
    registryOrderFrozen: false,
    classParameterModesFrozen: false,
    verificationRegistryFrozen: false,
    activatedRegistries: null,
    pscvVerified: false,
    executableAuthorization: false,
  };
}

/**
 * Only a trusted CI job can obtain 'audited-source-blobs' by checking the
 * exact leanprover/lean4 Git commit, tree entries and referenced blob bytes.
 * The result STILL CANNOT establish the complete normative Standard
 * environment or permit compiler emission.
 */
export function evaluateLeanProvenance(blueprint, pinnedGitEvidence, normativeReferenceText) {
  const expectedBlueprint = extractLeanProvenanceBlueprint(normativeReferenceText);
  if (canonicalJSON(blueprint) !== canonicalJSON(expectedBlueprint)) {
    fail('BLUEPRINT_IS_NOT_NORMATIVE');
  }
  if (!blueprint || blueprint.protocol !== provenanceProtocol ||
      blueprint.standardManifestComplete !== false ||
      blueprint.registryOrderFrozen !== false ||
      blueprint.executableAuthorization !== false ||
      !Array.isArray(blueprint.roots) || blueprint.roots.length !== 40) {
    fail('BLUEPRINT_IDENTITY');
  }
  if (!pinnedGitEvidence ||
      pinnedGitEvidence.commit !== pinnedLeanCommit ||
      !Array.isArray(pinnedGitEvidence.entries) ||
      pinnedGitEvidence.entries.length !== blueprint.roots.length) {
    fail('SOURCE_CHECKOUT_IDENTITY');
  }
  const expected = new Map(blueprint.roots.map(x => [x.path, x.gitBlobSha1]));
  const seen = new Set();
  for (const row of pinnedGitEvidence.entries) {
    if (typeof row?.path !== 'string' || seen.has(row.path) ||
        expected.get(row.path) !== row.gitBlobSha1 ||
        (!Number.isSafeInteger(row.lineCount) || row.lineCount < 1 ||
        row.lineCount > 100000 || !Number.isSafeInteger(row.sizeBytes) ||
        row.sizeBytes < 1 || row.sizeBytes > 8 * 1024 * 1024)) fail('GIT_PROVENANCE_ENTRY');
    seen.add(row.path);
  }
  if (seen.size !== 40) fail('GIT_PROVENANCE_COVERAGE');
  return sortKeys({
    schemaVersion: 0, kind: 'psc-provenance-audit-result/0',
    status: 'source-provenance-checked-not-standard-registry',
    sourceReferenceSha256: normativeSha256,
    environmentIdentity: pinnedStandardIdentity,
    semanticPin: { leanVersion: pinnedLeanVersion, leanCommit: pinnedLeanCommit },
    provenanceBlueprintSha256: blueprint.provenanceBlueprintSha256,
    immutableSourceBlobsChecked: seen.size,
    sourceAuditDigest: sha(Buffer.from(canonicalJSON(pinnedGitEvidence))),
    // The separate normative release blockers remain false even after
    // every source blob validates. A package cannot promote itself here.
    registrySnapshotGenerated: false,
    registrySnapshotCanonicalSha256: null,
    classParameterModesVerified: false,
    verificationRegistryVerified: false,
    fullPSCVConformance: false,
    pscvCertificateIssuerAvailable: false,
    verifiedExecutableAuthorized: false,
  });
}
