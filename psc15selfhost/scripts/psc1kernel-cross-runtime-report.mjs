import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { iterations, requestCases, workloads } from './psc1kernel-cross-runtime-corpus.mjs';
import { assessBudgets, budgetMarkdown, requireBudgetPass } from './psc1kernel-m3-budgets.mjs';
import { runMeasuredNative } from './psc1kernel-measure.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const positive = value => Number.isSafeInteger(value) && value > 0;
export function validateAdmissionWorker(sample, caseIndex) {
  assert.equal(sample.runtime, 'js-admission');
  assert.equal(sample.caseIndex, caseIndex);
  assert.equal(sample.guards, true);
  assert.ok(positive(sample.pid) && positive(sample.importNs) && positive(sample.peakRssKiB));
  const expected = requestCases[caseIndex];
  assert.ok(expected);
  assert.equal(sample.admission.count, expected.count);
  assert.equal(sample.admission.bad, expected.bad);
  assert.equal(sample.admission.accepted, !expected.bad);
  assert.ok(positive(sample.admission.ns));
  return sample;
}
export function validateWorker(sample, runtime) {
  assert.equal(sample.runtime, runtime);
  if (runtime === 'js') {
    assert.equal(sample.guards, true);
    assert.ok(positive(sample.importNs));
    assert.ok(positive(sample.peakRssKiB));
    assert.ok(positive(sample.pid));
    assert.equal(sample.admissionWorkers.length, requestCases.length);
    const processIds = new Set([sample.pid]);
    for (const [index, admission] of sample.admissionWorkers.entries()) {
      validateAdmissionWorker(admission, index);
      assert.ok(!processIds.has(admission.pid), 'Each admission needs a separate fresh process');
      processIds.add(admission.pid);
      for (const field of ['node', 'arch', 'platform']) {
        assert.equal(typeof sample[field], 'string');
        assert.equal(admission[field], sample[field]);
      }
      assert.deepEqual(sample.admissions[index], admission.admission);
    }
    assert.equal(sample.rows.length, workloads.length);
    assert.deepEqual([...sample.rows.map(x => x.name)].sort(), [...workloads].sort());
    for (const row of sample.rows) {
      assert.equal(row.name, workloads[row.kind]);
      assert.equal(row.hits, iterations);
      assert.ok(positive(row.ns) && positive(row.firstCallNs));
    }
  } else {
    assert.equal(runtime, 'wasm');
    assert.ok(positive(sample.healthRequestNs));
    assert.equal(sample.identity?.leanCommit, '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b');
  }
  assert.equal(sample.admissions.length, requestCases.length);
  for (let i = 0; i < requestCases.length; i++) {
    const row = sample.admissions[i], expected = requestCases[i];
    assert.equal(row.count, expected.count);
    assert.equal(row.bad, expected.bad);
    assert.equal(row.accepted, !expected.bad);
    assert.ok(positive(row.ns));
  }
  return sample;
}

export function parseNative(stdout, kind) {
  const match = /^CROSS_NATIVE (\d+) (\d+) (\d+)\s*$/.exec(stdout);
  assert.ok(match, 'missing/extra native output');
  assert.equal(Number(match[1]), kind);
  assert.equal(Number(match[2]), iterations);
  assert.ok(positive(Number(match[3])));
  return Number(match[3]);
}
export function stats(values) {
  assert.ok(values.length > 0 && values.every(x => Number.isFinite(x) && x > 0));
  const sorted = [...values].sort((a, b) => a - b), mid = Math.floor(sorted.length / 2);
  return { median: sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2,
    min: sorted[0], max: sorted.at(-1) };
}
function run(executable, args, log) {
  const start = process.hrtime.bigint();
  const result = spawnSync(executable, args, { encoding: 'utf8', timeout: 30_000,
    maxBuffer: 4 * 1024 * 1024, windowsHide: true });
  const processNs = Number(process.hrtime.bigint() - start);
  writeFileSync(log, (result.stdout ?? '') + (result.stderr ?? ''));
  if (result.error || result.status !== 0) throw Error(`Bounded worker failed: ${result.error ?? result.status}; ${log}`);
  return { stdout: result.stdout, processNs };
}
export function runCrossRuntime(generated, native, count, output) {
  assert.equal(count, 3, 'Require exactly 3 M3 samples');
  mkdirSync(path.dirname(output), { recursive: true });
  const samples = [];
  for (let i = 0; i < count; i++) {
    const jsRun = run(process.execPath, [path.join(here, 'psc1kernel-cross-runtime-worker.mjs'), 'js', generated, String(i)], `${output}.${i}.js.log`);
    const jsAdmissionRuns = requestCases.map((_, caseIndex) =>
      run(process.execPath, [path.join(here, 'psc1kernel-cross-runtime-worker.mjs'),
        'js-admission', generated, String(caseIndex)], `${output}.${i}.js-admission-${caseIndex}.log`));
    const admissionWorkers = jsAdmissionRuns.map((r, index) => validateAdmissionWorker(JSON.parse(r.stdout), index));
    const js = validateWorker({ ...JSON.parse(jsRun.stdout), admissionWorkers,
      admissions: admissionWorkers.map(worker => worker.admission) }, 'js');
    const nativeRuns = workloads.map((_, kind) => runMeasuredNative(native, [String(kind)], `${output}.${i}.native-${kind}.log`));
    const nativeNs = nativeRuns.map((r, kind) => parseNative(r.stdout, kind));
    const wasmRun = run(process.execPath, [path.join(here, 'psc1kernel-cross-runtime-worker.mjs'), 'wasm'], `${output}.${i}.wasm.log`);
    const wasm = validateWorker(JSON.parse(wasmRun.stdout), 'wasm');
    samples.push({ js, nativeNs, nativePeakRssKiB: Math.max(...nativeRuns.map(x => x.peakRssKiB)),
      wasm, jsProcessNs: jsRun.processNs, jsAdmissionProcessNs: jsAdmissionRuns.map(r => r.processNs),
      wasmProcessNs: wasmRun.processNs });
  }
  const observations = {};
  for (const [kind, name] of workloads.entries()) {
    observations[`native.${name}`] = samples.map(s => s.nativeNs[kind] / 1e6);
    observations[`js.${name}`] = samples.map(s => s.js.rows.find(r => r.kind === kind).ns / 1e6);
    observations[`js.firstCall.${name}`] = samples.map(s => s.js.rows.find(r => r.kind === kind).firstCallNs / 1e6);
  }
  observations['native.peakRss'] = samples.map(s => s.nativePeakRssKiB / 1024);
  observations['js.peakRss'] = samples.map(s => Math.max(s.js.peakRssKiB,
    ...s.js.admissionWorkers.map(w => w.peakRssKiB)) / 1024);
  observations['js.import'] = samples.map(s => Math.max(s.js.importNs,
    ...s.js.admissionWorkers.map(w => w.importNs)) / 1e6);
  for (const [index, name] of ['admit1', 'admit128', 'reject4'].entries()) {
    observations[`js.${name}`] = samples.map(s => s.js.admissions[index].ns / 1e6);
  }
  const budgetResult = assessBudgets('cross', observations);
  const report = {
    schemaVersion: 3, budgets: budgetResult, commit: process.env.GITHUB_SHA ?? null, samples,
    node: process.version, arch: process.arch, platform: process.platform,
    generatedSha256: createHash('sha256').update(readFileSync(generated)).digest('hex'),
    iterations, kernelCache: 'cold per operation', engineWarmup: 100,
    admissionIsolation: 'one fresh process per case per sample; import/guards only before timing',
    importNs: stats(observations['js.import'].map(ms => ms * 1e6)),
    rows: workloads.map((name, kind) => ({ name,
      jsNs: stats(samples.map(x => x.js.rows.find(r => r.kind === kind).ns)),
      nativeNs: stats(samples.map(x => x.nativeNs[kind])),
      jsOverNative: stats(samples.map(x => x.js.rows.find(r => r.kind === kind).ns / x.nativeNs[kind])),
      firstCallNs: stats(samples.map(x => x.js.rows.find(r => r.kind === kind).firstCallNs)),
    })),
    admissions: requestCases.map((fixture, i) => ({ ...fixture,
      jsDirectNs: stats(samples.map(x => x.js.admissions[i].ns)),
      wasmRequestNs: stats(samples.map(x => x.wasm.admissions[i].ns)),
    })),
    wasmHealthRequestNs: stats(samples.map(x => x.wasm.healthRequestNs)),
  };
  writeFileSync(`${output}.json`, JSON.stringify(report, null, 2) + '\n');
  const ms = ns => (ns / 1e6).toFixed(3);
  const markdown = [
    '## PSKernel bounded cross-runtime baseline', '',
    `${count} fresh-process samples; Node ${process.version}; 30-second process caps.`,
    'Same portable fixture functions in native and JS. Inputs prepared outside timing; 100 warmup calls; cold kernel cache per operation.', '',
    'Each JS admission case uses a separate fresh process after import/guards, with natural GC inside the timed call included. Import and RSS budgets use the maximum across all four JS workers per sample.', '',
    '| Workload (1,000 operations) | JS median ms | Native median ms | JS/native median | Ratio range |',
    '| --- | ---: | ---: | ---: | ---: |',
    ...report.rows.map(r => `| ${r.name} | ${ms(r.jsNs.median)} | ${ms(r.nativeNs.median)} | ${r.jsOverNative.median.toFixed(2)}x | ${r.jsOverNative.min.toFixed(2)}–${r.jsOverNative.max.toFixed(2)}x |`), '',
    `JS maximum-worker import median: ${ms(report.importNs.median)} ms. First-call timings are stored separately in JSON (after guard checks; not pristine JIT startup).`, '',
    '| Declaration batch | JS direct fixture ms | Lean WASM full request ms |', '| --- | ---: | ---: |',
    ...report.admissions.map(r => `| ${r.count}, ${r.bad ? 'reject final' : 'accept'} | ${ms(r.jsDirectNs.median)} | ${ms(r.wasmRequestNs.median)} |`), '',
    `WASM health request median: ${ms(report.wasmHealthRequestNs.median)} ms.`,
    'Admission columns are different boundaries, not a kernel speed ratio: WASM includes artifact verification, subprocess startup, parsing, provider prelude and checking. JS calls the fixture directly with its smaller test environment.',
    'The health request is a separate observation, not a startup value subtracted from checks. Both execute matching declaration bodies, including exact >2^53 naturals and an ill-typed rejection.',
    'No WASM rebuild, full compiler/kernel fixed point, or large proof-library replay. This is bounded Node evidence, not browser/provider readiness.', '',
    budgetMarkdown(budgetResult),
  ].join('\n');
  writeFileSync(`${output}.md`, markdown);
  process.stdout.write(markdown);
  requireBudgetPass(budgetResult);
  return report;
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const [generated, native, count, output] = process.argv.slice(2);
  if (!output) throw Error('Usage: <generated.js> <native-binary> <samples:3> <output-prefix>');
  runCrossRuntime(path.resolve(generated), path.resolve(native), Number(count), path.resolve(output));
}
