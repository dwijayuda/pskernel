import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
const gitBlob = bytes => createHash('sha1').update(`blob ${bytes.length}\0`).update(bytes).digest('hex');
const selected = Object.freeze({
  revision: 'v7.2', repoPath: 'psc0/PSCV0_LANGUAGE_REFERENCE_v7.2.md', bytes: 337963,
  sha256: 'c65487eccbd2829d1d9e5e1be3bc7f4cb37849b841ab3257ea0dd47665b8a30e',
  gitBlobSha1: '694115223777599ba28ee175e14bb642b7b6aa4b',
  leanCommit: 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc'
});

// This guard establishes document identity, not implemented language conformance.
// No legacy path or grammar fallback: historical editions are receipts only.
export async function verifyPscv0Reference() {
  const bytes = await readFile(path.join(root, 'PSCV0_LANGUAGE_REFERENCE_v7.2.md'));
  const adoption = JSON.parse(await readFile(path.join(root, 'docs/PSCV0_REFERENCE_ADOPTION.json'), 'utf8'));
  assert.equal(bytes.length, selected.bytes, 'v7.2 reference byte count');
  assert.equal(sha256(bytes), selected.sha256, 'v7.2 reference SHA-256');
  assert.equal(gitBlob(bytes), selected.gitBlobSha1, 'v7.2 reference Git identity');
  assert.equal(adoption.schema, 'psc0-language-reference-adoption/3');
  for (const key of ['revision','repoPath','bytes','sha256','gitBlobSha1'])
    assert.equal(adoption.reference[key], selected[key], `reference metadata ${key}`);
  assert.equal(adoption.referenceLeanPin.commit, selected.leanCommit);
  assert.deepEqual(adoption.sourcePolicy.legacyCompatibilityModes, []);
  assert.equal(adoption.sourcePolicy.oldParserFallbackAllowed, false);
  assert.equal(adoption.sourcePolicy.nativeLeanSemanticsUnchanged, true);
  assert.equal(adoption.conformance.fullV72, false);
  assert.deepEqual(adoption.approvedLogicalAssumptions, ['propext','Quot.sound']);
  assert.equal(adoption.requiredAssurancePolicy.automaticVerifiedToOrdinaryDowngrade, false);
  const surface = await readFile(path.join(root, 'packages/syntax/src/Ps/Syntax/Pscv0/Surface.lean'), 'utf8');
  const constant = name => {
    const match = new RegExp(`def\\s+${name}\\s*:\\s*String\\s*:=\\s*"([^"]+)"`).exec(surface);
    assert.ok(match, `missing portable reference identity ${name}`);
    return match[1];
  };
  assert.equal(constant('psPscv0ReferenceRevision'), selected.revision);
  assert.equal(constant('psPscv0ReferencePath'), selected.repoPath);
  assert.equal(constant('psPscv0ReferenceSha256'), selected.sha256);
  assert.equal(constant('psPscv0ReferenceGitBlob'), selected.gitBlobSha1);
  return {...selected, fullConformance: false, evidence: 'normative-document-identity-only'};
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url))
  console.log('PSCV0_REFERENCE_V72_IDENTITY: ' + JSON.stringify(await verifyPscv0Reference()));
