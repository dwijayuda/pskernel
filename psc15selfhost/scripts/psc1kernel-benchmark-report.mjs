import { spawnSync } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// Expected successful operations in the fixed, deliberately small native corpus.
// A fast failure is never a performance improvement.
const cases = [
  ['environment_indexed_ns', 'environment_hits', '2000/2000'],
  ['cache_indexed_ns', 'cache_hits', '2000/2000'],
  ['name_hash_ns', 'accumulators', '22628000/59274000'],
  ['environment_prehashed_ns', 'hits', '2000/2000'],
  ['infer_cold_ns', 'hits', '1000/1000'],
  ['proof_probe_ns', 'hits', '1000/1000'],
  ['whnf_cold_ns', 'whnf_hits', '1000/1000'],
  ['defeq_cold_ns', 'defeq_hits', '1000/1000'],
  ['official_lean_whnf_ns', 'hits', '1000/1000'],
  ['official_lean_defeq_ns', 'hits', '1000/1000'],
  ['beta_pskernel_ns', 'hits', '1000/1000'],
  ['application_infer_only_pskernel_ns', 'hits', '1000'],
  ['application_check_pskernel_ns', 'hits', '1000/1000/1000'],
  ['dependent_application_check_pskernel_ns', 'hits', '1000/1000'],
  ['recursor_pskernel_ns', 'hits', '1000/1000'],
  ['inductive_admission_pskernel_ns', 'hits', '100/100'],
  ['indexed_inductive_admission_pskernel_ns', 'hits', '100/100'],
  ['mutual_inductive_admission_pskernel_ns', 'hits', '100/100'],
  ['nested_inductive_admission_pskernel_ns', 'hits', '100/100'],
  ['nested_wide_setup', 'nested_wide_setup', 'ok'],
  ['nested_wide_validate_templates', 'nested_wide_validate_templates', 'ok'],
  ['nested_wide_validate_originals', 'nested_wide_validate_originals', 'ok'],
  ['nested_wide_validate_aux', 'nested_wide_validate_aux', 'ok'],
  ['nested_wide_admission_pskernel_ns', 'hits', '50/50'],
  ['nested_wide_stage_preprocess_ns', 'hits', '50/50/50/50'],
  ['nested_wide_validate_templates_ns', 'hits', '50/50/50'],
  ['nested_wide_main_rules_current_ns', 'hits', '50/50'],
  ['nested_stage_preprocess_ns', 'hits', '100/100/100/100'],
  ['nested_validate_templates_ns', 'hits', '100/100/100'],
  ['nested_validate_original_ctors_ns', 'hits', '100/100/100/100'],
  ['nested_original_rec_type_ns', 'hits', '100/100/100/100'],
  ['nested_infer_original_rules_ns', 'hits', '100/100/100'],
  ['structural_defeq_pskernel_ns', 'hits', '1000/1000'],
];

const comparisons = {
  whnf: ['pskernel_cold_whnf_ns', 'official_lean_whnf_ns'],
  defeq: ['pskernel_cold_defeq_ns', 'official_lean_defeq_ns'],
  beta: ['beta_pskernel_ns', 'beta_lean_ns'],
  application: ['application_check_pskernel_ns', 'application_check_lean_ns'],
  dependent_application: ['dependent_application_check_pskernel_ns', 'dependent_application_check_lean_ns'],
  recursor: ['recursor_pskernel_ns', 'recursor_lean_ns'],
  ordinary: ['inductive_admission_pskernel_ns', 'inductive_admission_lean_ns'],
  indexed: ['indexed_inductive_admission_pskernel_ns', 'indexed_inductive_admission_lean_ns'],
  mutual: ['mutual_inductive_admission_pskernel_ns', 'mutual_inductive_admission_lean_ns'],
  nested: ['nested_inductive_admission_pskernel_ns', 'nested_inductive_admission_lean_ns'],
  nested_wide: ['nested_wide_admission_pskernel_ns', 'nested_wide_admission_lean_ns'],
  structural_defeq: ['structural_defeq_pskernel_ns', 'structural_defeq_lean_ns'],
};

export function validateSample(log) {
  const rows = new Map();
  const timings = {};
  const profiles = log.split(/\r?\n/).filter(line => line.startsWith('PSKERNEL_PROFILE '));
  for (const line of log.split(/\r?\n/)) {
    if (!line.startsWith('PSKERNEL_BENCH ')) continue;
    const fields = {};
    for (const field of line.slice('PSKERNEL_BENCH '.length).split(/\s+/)) {
      const match = /^([a-z0-9_]+)=(\S+)$/.exec(field);
      if (!match || Object.hasOwn(fields, match[1])) throw new Error(`Malformed benchmark row: ${line}`);
      fields[match[1]] = match[2];
    }
    const key = Object.keys(fields)[0];
    if (rows.has(key) || !cases.some(([name]) => name === key)) throw new Error(`Unexpected/duplicate benchmark row: ${key}`);
    rows.set(key, fields);
    for (const [name, value] of Object.entries(fields)) {
      if (!name.endsWith('_ns')) continue;
      if (!/^\d+$/.test(value) || !Number.isSafeInteger(Number(value)) || Number(value) <= 0 || Object.hasOwn(timings, name)) {
        throw new Error(`Invalid/duplicate timing: ${name}=${value}`);
      }
      timings[name] = Number(value);
    }
  }
  for (const [name, field, expected] of cases) {
    if (rows.get(name)?.[field] !== expected) throw new Error(`Incomplete/failed benchmark: ${name}, expected ${field}=${expected}`);
  }
  const ratios = {};
  for (const [name, [numerator, denominator]] of Object.entries(comparisons)) {
    if (!(timings[numerator] > 0 && timings[denominator] > 0)) throw new Error(`Missing comparison timings: ${name}`);
    ratios[name] = timings[numerator] / timings[denominator];
  }
  const fingerprint = [...rows].map(([name, fields]) => [name,
    Object.fromEntries(Object.entries(fields).filter(([key]) => !key.endsWith('_ns')))]);
  return { timings, ratios, fingerprint, profiles };
}

function statistics(values) {
  const sorted = [...values].sort((a, b) => a - b);
  const middle = Math.floor(sorted.length / 2);
  const median = sorted.length % 2 ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2;
  return { median, min: sorted[0], max: sorted.at(-1) };
}

export function summarizeSamples(samples) {
  if (samples.length < 1 || samples.length > 5) throw new Error('Require 1 to 5 bounded samples');
  for (const sample of samples) {
    if (JSON.stringify(sample.fingerprint) !== JSON.stringify(samples[0].fingerprint) ||
        JSON.stringify(Object.keys(sample.timings)) !== JSON.stringify(Object.keys(samples[0].timings))) {
      throw new Error('Benchmark corpus changed between samples');
    }
  }
  const summarize = field => Object.fromEntries(Object.keys(samples[0][field]).map(key =>
    [key, statistics(samples.map(sample => sample[field][key]))]));
  return {
    schemaVersion: 1,
    runtime: 'lean-native',
    sampleCount: samples.length,
    timingsNs: summarize('timings'),
    // Median of within-sample ratios: never divide unrelated runner medians.
    pskernelOverLean: summarize('ratios'),
    samples,
  };
}

export function runBenchmark(binary, count, output) {
  if (!Number.isInteger(count) || count < 1 || count > 5) throw new Error('Require 1 to 5 bounded samples');
  mkdirSync(path.dirname(output), { recursive: true });
  const samples = [];
  for (let index = 0; index < count; index++) {
    const result = spawnSync(binary, [], { encoding: 'utf8', timeout: 30_000, maxBuffer: 2 * 1024 * 1024 });
    writeFileSync(`${output}.sample-${index + 1}.log`, (result.stdout ?? '') + (result.stderr ?? ''));
    if (result.error || result.status !== 0) throw new Error(`Benchmark sample failed: ${result.error ?? result.status}`);
    samples.push(validateSample(result.stdout));
  }
  const report = { ...summarizeSamples(samples), commit: process.env.GITHUB_SHA ?? null };
  writeFileSync(`${output}.json`, JSON.stringify(report, null, 2) + '\n');
  const markdown = [
    '## PSKernel native benchmark', '',
    `Samples: ${count}; each process limited to 30 seconds. Timings are observations, not release guarantees.`, '',
    '| Workload | Median PSKernel / Lean | Range |', '| --- | ---: | ---: |',
    ...Object.entries(report.pskernelOverLean).map(([name, value]) =>
      `| ${name} | ${value.median.toFixed(2)}x | ${value.min.toFixed(2)}–${value.max.toFixed(2)}x |`), '',
    'All benchmark success counts validated. Full compiler/kernel fixed-point generation was not run.', '',
    'Untimed cache diagnostics (first sample):', '', '```text', ...samples[0].profiles, '```', '',
  ].join('\n');
  writeFileSync(`${output}.md`, markdown);
  process.stdout.write(markdown);
  return report;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  if (args.length !== 3) throw new Error('Usage: node scripts/psc1kernel-benchmark-report.mjs <binary> <samples:1..5> <output-prefix>');
  runBenchmark(path.resolve(args[0]), Number(args[1]), path.resolve(args[2]));
}
