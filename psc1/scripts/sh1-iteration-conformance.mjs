import assert from 'node:assert/strict';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { readBootstrapClosure, stripBootstrapImports } from './sh1-source-snapshot.mjs';
import { runCommand, sha256, unwrap } from './sh1-capabilities.mjs';

// A two-module workspace exercises the public resident CLI without compiling
// the compiler's full source closure again.
export async function runIterationConformance({
  compiler, compilerPath, compilerSha256, root, outDir,
}) {
  const workspace = path.join(outDir, 'workspace');
  const sources = [
    ['packages/foundation/src/Ps/Foundation/Smoke.lean',
      'def sh1CliBase : Nat := 11\n'],
    ['packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean',
      'import Ps.Foundation.Smoke\n\ndef sh1CliResult : Nat := Nat.add sh1CliBase 7\n'],
  ];
  for (const [relative, source] of sources) {
    const destination = path.join(workspace, relative);
    await mkdir(path.dirname(destination), { recursive: true });
    await writeFile(destination, source);
  }
  const closure = await readBootstrapClosure(workspace);
  const result = runCommand(process.execPath, [
    path.join(root, 'scripts/sh1-iterate.mjs'),
    '--compiler', compilerPath, '--compiler-sha256', compilerSha256,
    '--workspace', workspace, '--out', path.join(outDir, 'products'), '--loop',
  ], {
    cwd: root, encoding: 'utf8', stdio: 'pipe',
    input: 'prepare\nemit\nquit\n', timeout: 60000, maxBuffer: 4 * 1024 * 1024,
  });
  const prefix = 'PSC0_SH1_ITERATION: ';
  const receipts = result.stdout.split('\n').filter((line) => line.startsWith(prefix))
    .map((line) => JSON.parse(line.slice(prefix.length)));
  assert.equal(receipts.length, 3, 'PSC0_SH1_CLI_REQUESTS');
  assert.equal(receipts[0].preparation.cache.prefixModules, 0);
  assert.equal(receipts[0].preparation.cache.preparedModules, 2);
  for (const receipt of receipts) {
    assert.equal(receipt.compilerSha256, compilerSha256);
    assert.equal(receipt.sourceClosureSha256, closure.sha256);
    assert.equal(receipt.moduleCount, 2);
    assert.equal(receipt.evidence, 'admission-ready');
  }
  for (const receipt of receipts.slice(1)) {
    assert.equal(receipt.preparation.cache.prefixModules, 2);
    assert.equal(receipt.preparation.cache.parseHits, 0);
    assert.equal(receipt.preparation.cache.parseMisses, 0);
    assert.equal(receipt.preparation.cache.preparedModules, 0);
    assert.equal(receipt.preparation.cache.finishHit, true);
    for (const stage of ['parse', 'prepare', 'finish']) {
      assert.equal(receipt.preparation.timingsMs[stage], 0);
    }
  }
  const inputs = closure.ordered.map(({ source }) => stripBootstrapImports(source));
  const list = inputs.reduceRight((tail, head) => compiler.List.cons(head, tail), compiler.List.nil());
  const prepared = unwrap(compiler.psCompilerPrepareSources(compiler.PsCompilerSourceKind.lean, list),
    'CLI_REFERENCE_PREPARE');
  const admissions = unwrap(compiler.psCompilerAdmissionsFromPrepared(prepared), 'CLI_REFERENCE_ADMISSIONS');
  const typeScript = unwrap(compiler.psCompilerTypeScriptFromPrepared(prepared), 'CLI_REFERENCE_EMIT');
  const emitted = receipts[2];
  assert.equal(emitted.artifacts.admissionsSha256, sha256(admissions));
  assert.equal(emitted.artifacts.typeScriptSha256, sha256(typeScript));
  assert.equal(await readFile(path.join(emitted.outputDirectory, 'admissions.json'), 'utf8'), admissions);
  assert.equal(await readFile(path.join(emitted.outputDirectory, 'index.ts'), 'utf8'), typeScript);
  assert.deepEqual(JSON.parse(await readFile(path.join(emitted.outputDirectory, 'source-closure.json'))),
    closure.manifest);
  const published = JSON.parse(await readFile(path.join(emitted.outputDirectory, 'receipt.json')));
  assert.equal(published.sourceClosureSha256, closure.sha256);
  assert.deepEqual(published.artifacts, emitted.artifacts);

  // A wrong pin must fail before importing even a minimal executable canary.
  const canary = path.join(outDir, 'must-not-execute.mjs');
  await writeFile(canary, "throw new Error('PSC0_SH1_CANARY_EXECUTED');\n");
  assert.throws(() => runCommand(process.execPath, [
    path.join(root, 'scripts/sh1-iterate.mjs'),
    '--compiler', canary, '--compiler-sha256', '0'.repeat(64), '--once',
    '--workspace', workspace,
  ], { cwd: root, encoding: 'utf8', stdio: 'pipe', timeout: 30000 }), (error) => {
    assert.match(error.message, /PSC0_SH1_COMPILER_PIN_MISMATCH/u);
    assert(!error.message.includes('PSC0_SH1_CANARY_EXECUTED'));
    return true;
  });
  const receipt = {
    schemaVersion: 1,
    evidence: 'resident-cli-bounded-conformance',
    compilerSha256,
    sourceClosureSha256: closure.sha256,
    requests: receipts,
    wrongCompilerPin: 'rejected-before-import',
    aggregateCorrespondence: 'same-compiler API, not an independent implementation oracle',
    kernelChecked: false,
  };
  await writeFile(path.join(outDir, 'receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
  process.stdout.write('PSC0_SH1_ITERATION_CONFORMANCE: PASS (cold, warm, atomic products, compiler pin)\n');
  return receipt;
}
