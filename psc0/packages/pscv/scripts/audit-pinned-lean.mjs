#!/usr/bin/env node
/**
 * CI-only source-provenance regeneration. It never imports executable Lean
 * modules or promotes Standard registry activation/certification.
 */
import { execFileSync } from 'node:child_process';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import {
  canonicalJSON, extractLeanProvenanceBlueprint, evaluateLeanProvenance,
  pinnedLeanCommit, pinnedLeanVersion, normativeSha256,
} from '../src/lean-provenance.mjs';

const fail = code => { throw new Error('PSC_PSCV_SOURCE_AUDIT_' + code); };
if (process.argv.length !== 4) fail('ARGUMENTS');
const sourceDir = path.resolve(process.argv[2]);
const outputDir = path.resolve(process.argv[3]);
const refPath = fileURLToPath(new URL('../../../../pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md', import.meta.url));

const git = (...args) => execFileSync('git', ['-C', sourceDir, ...args], {
  encoding: 'utf8', timeout: 15000, maxBuffer: 8 * 1024 * 1024,
}).trimEnd();
const blob = id => execFileSync('git', ['-C', sourceDir, 'cat-file', 'blob', id], {
  timeout: 15000, maxBuffer: 8 * 1024 * 1024,
});

const commit = git('rev-parse', 'HEAD');
if (commit !== pinnedLeanCommit) fail('WRONG_LEAN_COMMIT');
const reference = await readFile(refPath, 'utf8');
const blueprint = extractLeanProvenanceBlueprint(reference);
const entries = [];
for (const row of blueprint.roots) {
  const listing = git('ls-tree', '--full-tree', 'HEAD', '--', row.path);
  const lines = listing.split('\n');
  if (lines.length !== 1) fail('MISSING_PINNED_ROOT');
  const match = /^100644 blob ([a-f0-9]{40})\t(src\/[A-Za-z0-9_./-]+\.lean)$/u.exec(lines[0]);
  if (!match || match[1] !== row.gitBlobSha1 || match[2] !== row.path) {
    fail('ROOT_BLOB_MISMATCH:' + row.path);
  }
  const data = blob(match[1]);
  if (data.length === 0 || data.length > 8 * 1024 * 1024) fail('BLOB_SIZE');
  entries.push({ path: row.path, gitBlobSha1: row.gitBlobSha1,
    sizeBytes: data.length, lineCount: data.toString('utf8').split(/\r?\n/u).length });
}
const audit = evaluateLeanProvenance(blueprint, { commit, entries }, reference);
await mkdir(outputDir, { recursive: true });
await writeFile(path.join(outputDir, 'source-provenance-blueprint.json'),
  canonicalJSON(blueprint) + '\n');
await writeFile(path.join(outputDir, 'source-provenance-audit.json'),
  canonicalJSON(audit) + '\n');
process.stdout.write(JSON.stringify({
  status: audit.status, leanVersion:pinnedLeanVersion, leanCommit:commit,
  normativeSha256, roots:entries.length,
  provenanceBlueprintSha256:blueprint.provenanceBlueprintSha256,
  sourceAuditDigest:audit.sourceAuditDigest,
  standardManifestComplete:false, verifiedExecutableAuthorized:false,
}) + '\n');
