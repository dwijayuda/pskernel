import { mkdtempSync, readFileSync, writeFileSync, copyFileSync, rmSync, existsSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { collectBackendJsClosure } from './backend-js-closure.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const sources = collectBackendJsClosure(root);
const out = mkdtempSync(path.join(os.tmpdir(), 'psc-js-source-'));
const canonicalPsDiagnostic = '/tmp/backend-js-source-BackendJs.ps';
const generatedTsDiagnostic = '/tmp/backend-js-source-backend.ts';

function phase(label, command, args, cwd, timeoutMs = 90000) {
  console.log(`BACKEND_JS_SOURCE_PHASE: ${label}: START`);
  const result = spawnSync(command, args, {
    cwd,
    stdio: 'inherit',
    timeout: timeoutMs,
  });
  if (result.error) {
    const code = result.error.code ?? result.error.message;
    throw new Error(`BACKEND_JS_SOURCE_PHASE_FAILED: ${label} (${code})`);
  }
  if (result.status !== 0) {
    throw new Error(`BACKEND_JS_SOURCE_PHASE_FAILED: ${label} (exit ${result.status})`);
  }
  console.log(`BACKEND_JS_SOURCE_PHASE: ${label}: PASS`);
}

function runPsc1(label, args, timeoutMs = 90000) {
  phase(label, 'lake', ['exe', 'psc1', ...args], root, timeoutMs);
}

function flattened(entries) {
  return entries.map(({ source }) => source.split(/\r?\n/u)
    .filter(line => !/^\s*import\s/u.test(line)).join('\n')).join('\n\n');
}

function checkProbeVariant(label, source, timeoutMs = 15000) {
  const file = path.join(out, `BackendJsProbe-${label}.lean`);
  writeFileSync(file, flattened([...sources, { source }]));
  runPsc1(`probe-${label}`, ['check', file], timeoutMs);
}

try {
  const lean = path.join(out, 'BackendJs.lean');
  const ps = path.join(out, 'BackendJs.ps');
  const backendJs = path.join(out, 'backend.js');
  const backendMjs = path.join(out, 'backend.mjs');
  const probeRunner = path.join(out, 'generated-backend-probe.mjs');
  const probe = readFileSync(path.join(root, 'test/BackendJsSelfhostProbe.lean'), 'utf8');

  for (let index = 0; index < sources.length; index += 1) {
    const prefix = sources.slice(0, index + 1);
    const prefixFile = path.join(out, `BackendJsPrefix${index + 1}.lean`);
    const relative = path.relative(root, sources[index].file).replaceAll(path.sep, '/');
    writeFileSync(prefixFile, flattened(prefix));
    runPsc1(
      `lean-prefix-${index + 1}:${relative}`,
      ['check', prefixFile],
      index === 0 ? 90000 : 30000,
    );
  }

  checkProbeVariant('trivial', `
def psJsProbeTrivial (_value : Unit) : String :=
  "ok"
`);

  checkProbeVariant('small-ir', `
def psJsProbeSmallIr (_value : Unit) : String :=
  let body := PsVerifiedIrExpr.letE
    "a-b"
    (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
    (PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 42))
    (PsVerifiedIrExpr.var "a-b");
  let declaration := PsVerifiedIrDeclaration.mk
    "answer" List.nil List.nil
    (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
    body;
  let module := PsVerifiedIrModule.mk List.nil List.nil List.nil
    (List.cons declaration List.nil);
  match psJsEmitModule module with
  | Except.error _ => "BACKEND_JS_PROBE_ERROR"
  | Except.ok output => output
`);

  // Large-Nat backend semantics are exercised by backend-js-tests.mjs. Keep
  // this gate focused on PSC1 admission of the production self-host source so
  // a diagnostic-only literal construction cannot dominate bootstrap time.
  writeFileSync(lean, flattened([...sources, { source: probe }]));
  runPsc1('lean-check-with-probe', ['check', lean], 30000);
  runPsc1('lean-to-ps', ['translate', lean, '--to', 'ps', '--out', ps]);
  copyFileSync(ps, canonicalPsDiagnostic);
  runPsc1('ps-check', ['check', ps]);
  console.log('BACKEND_JS_PSC1_SOURCE: PASS (Lean and canonical PS admission-ready checks)');

  runPsc1('ps-build', ['build', ps, '--out', backendJs]);
  copyFileSync(backendJs, backendMjs);
  writeFileSync(probeRunner, `
import assert from 'node:assert/strict';
import { writeFileSync } from 'node:fs';

const compiled = await import('./backend.mjs');
const emitted = compiled.psJsSelfhostProbe(undefined);
assert.equal(typeof emitted, 'string');
writeFileSync('./probe.mjs', emitted);
const result = await import('./probe.mjs');
assert.equal(result.answer, 42n);
`);
  phase('generated-execution', process.execPath, [probeRunner], out);
  console.log('BACKEND_JS_GENERATED_EXECUTION: PASS (PSC1 -> PS -> TS seed -> executable backend -> direct JS)');
} finally {
  const generatedTs = path.join(out, 'backend.ts');
  if (existsSync(generatedTs)) {
    copyFileSync(generatedTs, generatedTsDiagnostic);
  }
  rmSync(out, { recursive: true, force: true });
}
