import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
const [baselineRoot, candidateRoot, destination] = process.argv.slice(2).map(p => path.resolve(p));
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
fs.mkdirSync(destination, { recursive: true });
const results = {};
for (const [label, root] of [['baseline', baselineRoot], ['candidate', candidateRoot]]) {
  const output = path.join(destination, label);
  fs.mkdirSync(output, { recursive: true });
  const binary = path.join(root, '.lake/build/bin/psc1_specialize_queue_benchmark');
  const timeFile = path.join(output, 'time.txt');
  const start = performance.now();
  const run = spawnSync('/usr/bin/time', ['-v', '-o', timeFile, binary, output],
    { cwd: root, encoding: 'utf8', timeout: 240000, maxBuffer: 32 * 1024 * 1024 });
  assert.equal(run.error, undefined, label + ' process error');
  assert.equal(run.status, 0, label + ': ' + run.stderr);
  process.stdout.write(run.stdout);
  const result = JSON.parse(fs.readFileSync(path.join(output, 'result.json'), 'utf8'));
  const time = fs.readFileSync(timeFile, 'utf8');
  const input = fs.readFileSync(path.join(output, 'input.ir.json'));
  results[label] = { ...result, elapsedMs: Math.round(performance.now() - start),
    maximumRssKiB: Number(time.match(/Maximum resident set size \(kbytes\):\s*(\d+)/)?.[1]),
    inputSha256: sha(input), inputBytes: input.length, binarySha256: sha(fs.readFileSync(binary)) };
}
assert.equal(results.baseline.status, 'refused');
assert.equal(results.baseline.code, 'fuel-exhausted');
assert.equal(results.candidate.status, 'accepted');
assert.equal(results.baseline.inputSha256, results.candidate.inputSha256);
assert.equal(results.candidate.allConcreteDeclarationsRetained, true);
const receipt = { schema: 'psc1-specialization-queue-comparison/1',
  baselineCommit: 'a37a4ce61139db229f86d50645c65a0597119035',
  candidateCommit: process.env.GITHUB_SHA, queueBudget: 16384, processTimeoutMs: 240000,
  fixtureSha256: sha(fs.readFileSync(path.join(candidateRoot, 'scripts/SpecializeQueueBenchmark.lean'))),
  results, formalPreservation: 'not-provided', generatedCompilerExecution: 'separate-diagnostic' };
fs.writeFileSync(path.join(destination, 'comparison.json'), JSON.stringify(receipt, null, 2) + '\n');
console.log('PSC1_QUEUE_COMPARISON: ' + JSON.stringify(receipt));
