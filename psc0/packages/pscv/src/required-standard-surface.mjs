/**
 * Read-only extraction of required operator/literal surface in exact
 * PSCV-RC-v2 section 24.3. Snapshot names are REQUIREMENT DATA, not
 * proven Lean declarations or active registrations.
 */
import { createHash } from 'node:crypto';
import { normativeSha256 } from './lean-provenance.mjs';

const hash = text => createHash('sha256').update(text).digest('hex');
const fail = code => { throw new Error('PSC_PSCV_REQUIRED_SURFACE_' + code); };
const freeze = x => Object.freeze(x);
const tick = String.fromCharCode(96);

export function extractRequiredStandardSurface(reference) {
  if (typeof reference !== 'string' || hash(reference) !== normativeSha256) {
    fail('REFERENCE_IDENTITY');
  }
  const start = reference.indexOf('### 24.3 Required Standard overloaded surface');
  const stop = reference.indexOf('\n### 24.4 Grammar registrations', start);
  if (start < 0 || stop <= start) fail('SECTION_IDENTITY');
  const section = reference.slice(start, stop);
  const rows = [];
  const seen = new Set();
  for (const line of section.split('\n')) {
    if (!line.startsWith('| '+tick)) continue;
    const match = /^\| \x60([^\x60]+)\x60 \| (.*?) \| (.*?) \|$/u.exec(line);
    if (!match) fail('SURFACE_ROW');
    const [, id, family, right] = match;
    if (seen.has(id) || id.length > 90 || family.length > 160 ||
        right.length > 600) fail('SURFACE_DUPLICATE_OR_LENGTH');
    seen.add(id);
    const names = [...right.matchAll(/\x60([^\x60]+)\x60/gu)].map(x=>x[1]);
    if (names.length < 1 || names.some(x=>x.length > 128 ||
      !/^[A-Za-z0-9_.-]+$/u.test(x)) ||
      !['direct ',tick].some(x=>right.startsWith(x))) fail('SNAPSHOT_ID');
    rows.push(freeze({
      id, guaranteedFamily:family,
      referencedSnapshotIds:freeze(names),
      entryResolution:'not-extracted',
      sourceLocator:null,
      semanticallyValidated:false,
    }));
  }
  if (rows.length !== 230) fail('SURFACE_CLOSURE_COUNT');
  const snapshotIds=freeze([...new Set(rows.flatMap(x=>x.referencedSnapshotIds))].sort());
  const sourceRows=freeze(rows.sort((a,b)=>a.id.localeCompare(b.id,'en')));
  const sourceDigest=hash(JSON.stringify({rows:sourceRows,snapshotIds}));
  return freeze({
    schemaVersion:0,kind:'psc-required-standard-surface/0',
    normativeSha256,semanticPin:'lean4.35.0-rc3',
    requiredRows:sourceRows,
    requiredSnapshotIds:snapshotIds,
    sourceDigest,
    sourceRowsCount:sourceRows.length,
    uniqueReferencedIdsCount:snapshotIds.length,
    allowedSemanticRegistry:null,
    exactInstanceOrderingQualified:false,
    declarationMappingsQualified:false,
    sourceLineProvenanceQualified:false,
    completeStandardEnvironment:false,
    verifiedExecutableAuthorized:false,
    pscvVerified:false,
  });
}
