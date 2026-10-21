#!/usr/bin/env node
import { readFileSync, writeFileSync, mkdirSync, statSync } from 'node:fs';
import { createHash } from 'node:crypto';
import path from 'node:path';

const [output, kind, ...inputs] = process.argv.slice(2);
if (!output || !['native', 'lean-generated-js', 'canonical-ps-generated-js'].includes(kind) || inputs.length === 0) {
  throw new Error('usage: pskernel-artifact-manifest.mjs OUTPUT KIND FILE...');
}
const sourceSha = process.env.GITHUB_SHA;
if (!/^[0-9a-f]{40}$/.test(sourceSha ?? '')) {
  throw new Error('a full GITHUB_SHA is required; no unanchored artifact receipt');
}
const repository = process.env.GITHUB_REPOSITORY;
if (repository !== 'dwijayuda/pskernel') throw new Error('unexpected source repository');
const ownedFiles = new Set(inputs.map(input => path.resolve(input)));
const files = inputs.map(input => {
  const full = path.resolve(input);
  if (!statSync(full).isFile()) throw new Error('artifact must be a regular file: ' + input);
  const bytes = readFileSync(full);
  if (full.endsWith('.js.map')) {
    const map = JSON.parse(bytes.toString('utf8'));
    if (map.version !== 3 || !Array.isArray(map.sources) || map.sources.length === 0 ||
        typeof map.mappings !== 'string' || map.mappings.length === 0) {
      throw new Error('invalid generated source map: ' + input);
    }
    for (let index = 0; index < map.sources.length; index++) {
      if (typeof map.sourcesContent?.[index] === 'string') continue;
      const source = map.sources[index];
      if (typeof source !== 'string' || !ownedFiles.has(path.resolve(
          path.dirname(full), map.sourceRoot ?? '', source))) {
        throw new Error('source map refers to an unpackaged source: ' + input);
      }
    }
  }
  if (bytes.length === 0) throw new Error('empty artifact: ' + input);
  return {
    path: path.relative(process.cwd(), full).split(path.sep).join('/'),
    bytes: bytes.length,
    sha256: createHash('sha256').update(bytes).digest('hex'),
  };
});
if (new Set(files.map(file => file.path)).size !== files.length) {
  throw new Error('duplicate artifact input');
}
const runId = process.env.GITHUB_RUN_ID;
const result = {
  schema: 'pskernel-core-artifacts-v1',
  repository,
  sourceSha,
  sourceUrl: 'https://github.com/' + repository + '/tree/' + sourceSha,
  workflowRun: runId ? 'https://github.com/' + repository + '/actions/runs/' + runId : null,
  runAttempt: process.env.GITHUB_RUN_ATTEMPT ?? null,
  kind,
  leanToolchain: 'leanprover/lean4:v4.35.0',
  leanCommit: 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',
  typescript: kind === 'native' ? null : '7.0.2',
  node: process.version,
  checkerFuelDefault: 4096,
  qualification: 'File integrity receipt only. Qualification requires the linked workflow to finish successfully.',
  files,
};
mkdirSync(path.dirname(path.resolve(output)), { recursive: true });
writeFileSync(output, JSON.stringify(result, null, 2) + '\n');
console.log('PSC1_KERNEL_ARTIFACT_MANIFEST ' + JSON.stringify(result));
