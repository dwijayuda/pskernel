import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { runBenchmark } from './psc1kernel-benchmark-report.mjs';

// Opt-in diagnostic only. Rebuild only the native benchmark with the previous
// cache publication path, preserving the new helper for the matched microcase.
// No compiler bootstrap, proof-library replay, or generated JS is invoked.
export function previousPublicationPath(source) {
  const promotion = 'psKernelExprMapIndexInsert\n        16\n        index\n        hash\n        key\n        (Prod.snd entry)';
  const insertion = 'psKernelExprMapIndexInsert\n              16\n              index\n              hash\n              expr\n              value)';
  if (source.split(promotion).length !== 2 || source.split(insertion).length !== 2) {
    throw new Error('Cache comparison requires the reviewed single-descent publication shape');
  }
  return source.replace(promotion,
    'psKernelExprMapIndexSet\n        16\n        index\n        hash\n        (psKernelExprMapInsertIn key (Prod.snd entry) (psKernelExprMapIndexBucket 16 index hash))')
    .replace(insertion,
      'psKernelExprMapIndexSet\n              16\n              index\n              hash\n              (psKernelExprMapInsertIn expr value (psKernelExprMapIndexBucket 16 index hash)))');
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  if (process.argv.length !== 3) throw new Error('Usage: node scripts/psc1kernel-cache-comparison.mjs <candidate-report-prefix>');
  const prefix = path.resolve(process.argv[2]);
  const root = fileURLToPath(new URL('../', import.meta.url));
  const sourceFile = path.join(root, 'packages/pskernel-core/src/Ps/KernelCore/Runtime/Acceleration/Cache.lean');
  const original = fs.readFileSync(sourceFile, 'utf8');
  const previous = previousPublicationPath(original.replaceAll('\r\n', '\n'));
  const candidate = JSON.parse(fs.readFileSync(prefix + '.json', 'utf8'));
  const sha = source => createHash('sha256').update(source).digest('hex');
  let baseline;
  try {
    fs.writeFileSync(sourceFile, previous);
    const build = spawnSync('lake', ['build', 'psc1_kernel_core_bench'], {
      cwd: root, encoding: 'utf8', timeout: 240_000, maxBuffer: 4 * 1024 * 1024,
    });
    if (build.error || build.status !== 0) throw new Error(`Comparison build failed: ${build.error ?? build.status}\n${build.stdout}\n${build.stderr}`);
    baseline = runBenchmark(path.join(root, '.lake/build/bin/psc1_kernel_core_bench' + (process.platform === 'win32' ? '.exe' : '')),
      3, prefix + '-double-walk');
  } finally {
    fs.writeFileSync(sourceFile, original);
  }
  assert.deepEqual(candidate.samples[0].fingerprint, baseline.samples[0].fingerprint,
    'Cache variants must complete exactly the same successful operations');
  const comparisons = Object.fromEntries(Object.keys(candidate.pskernelOverLean).map(key => [key, {
    singleWalkOverLean: candidate.pskernelOverLean[key],
    doubleWalkOverLean: baseline.pskernelOverLean[key],
    singleOverDoubleRatio: candidate.pskernelOverLean[key].median / baseline.pskernelOverLean[key].median,
  }]));
  const report = {
    commit: process.env.GITHUB_SHA ?? null,
    singleWalkSourceSha256: sha(original), doubleWalkSourceSha256: sha(previous),
    sameRunner: true, samplesPerVariant: 3, comparisons,
    limitation: 'Sequential builds/processes on one runner; ratios are observations, not release guarantees.',
  };
  fs.writeFileSync(prefix + '-comparison.json', JSON.stringify(report, null, 2) + '\n');
  const markdown = ['## Same-runner cache publication comparison', '',
    'Three samples per variant; one extra native benchmark build capped at four minutes. Lower is faster.', '',
    '| Workload | Single-walk / Lean | Double-walk / Lean | Relative ratio |', '| --- | ---: | ---: | ---: |',
    ...Object.entries(comparisons).map(([name, value]) =>
      `| ${name} | ${value.singleWalkOverLean.median.toFixed(3)} | ${value.doubleWalkOverLean.median.toFixed(3)} | ${value.singleOverDoubleRatio.toFixed(3)} |`), '',
    'Both variants completed identical operation counts. Production source restored after the experiment.', '',
  ].join('\n');
  fs.writeFileSync(prefix + '-comparison.md', markdown);
  process.stdout.write(markdown);
}
