// End-to-end source rename qualification, using actual checked production outputs.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { createLosslessSourceTool, createSourceOwnershipTool,
  createSourceBindingTool, createCheckedSourceConverter } from '../host-tools/source-refactoring.mjs';
import { readOwnedCompilerSources } from '../host-tools/compiler-source-inputs.mjs';
import { boundedRun } from '../host-tools/generated-target-tools.mjs';

const root = process.cwd(), work = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-binding-integration-'));
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const pin = name => {
  const executable = path.resolve('.lake/build/bin/' + name);
  return { executable, sha256: hash(fs.readFileSync(executable)) };
};
const lexical = createLosslessSourceTool(pin('psc1_lossless_source'));
const checker = pin('psc1_independent_checker');
const ownership = createSourceOwnershipTool({
  lexicalTool: lexical, ...pin('psc1_source_ownership'),
  checkerExecutable: checker.executable, checkerSha256: checker.sha256,
});
const bindings = createSourceBindingTool({ ownershipTool: ownership });
const converter = createCheckedSourceConverter({ ownershipTool: ownership });
const env = { ...process.env, PSC1_HOST_TOOLS: path.resolve('host-tools/artifacts.mjs') };
const records = [], compiler = [];
function retain(status) {
  fs.writeFileSync(path.join(output, 'progress.json'), JSON.stringify({
    schema: 'psc1-source-binding-progress/1', testedCommit: process.env.GITHUB_SHA,
    status, records, compiler, sourceFilesWritten: false, publication: false,
  }, null, 2) + '\n');
}
const output = path.resolve('dist/source-bindings');
fs.mkdirSync(output, { recursive: true });
fs.writeFileSync(path.join(work, 'package.json'), '{"type":"module"}\n');
function run(command, args, options = {}) {
  const result = boundedRun(command, args, { timeoutMs: 240000, timeoutPolicy: 'standard-240s',
    env, ...options });
  assert.equal(result.error, null, result.stderr);
  assert.equal(result.status, 0, result.stdout + result.stderr);
  return result;
}
const capture = (text, grammar, module = 'Test.Main') =>
  lexical.capture({ module, grammar, bytes: Buffer.from(text) });
function findBinder(index, moduleName, functionName, localName) {
  const module = index.modules.find(item => item.module === moduleName);
  const choices = module.bindings.flatMap(batch => batch.traces.filter(trace =>
    trace.name.at(-1)?.[1] === functionName).flatMap(trace =>
      trace.binders.filter(binder => binder.sourceBacked && binder.region === 'body' &&
        JSON.stringify(binder.name) === JSON.stringify([['s', localName]]))));
  assert.equal(choices.length, 1, moduleName + '/' + functionName + '/' + localName);
  return choices[0];
}
async function observe(source, grammar, stage, target) {
  const folder = path.join(work, grammar, stage, target);
  fs.mkdirSync(folder, { recursive: true });
  const input = path.join(folder, 'Main.' + grammar);
  fs.writeFileSync(input, source);
  const extension = { js: 'js', ts: 'ts', rust: 'rs', python: 'py', php: 'php' }[target] ?? 'wasm';
  const destination = path.join(folder, 'module.' + extension);
  const extra = target === 'wasm-component' ? ['--export', 'answer'] : [];
  run(pin('psc1').executable, ['build', input, '--target', target, ...extra, '--out', destination]);
  const manifestBytes = fs.readFileSync(destination + '.bundle.json');
  const manifest = JSON.parse(manifestBytes);
  assert.equal(manifest.logicalChecker, 'lean4:4.35.0');
  assert.equal(manifest.logicalCheckerCommit, 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
  assert.equal(manifest.target, target);
  assert.equal(manifest.assurance, 'checked-logical');
  const generation = path.dirname(fs.realpathSync(destination + '.bundle.json'));
  for (const item of manifest.files)
    assert.equal(hash(fs.readFileSync(path.join(generation, item.path))), item.sha256);
  let values;
  if (target === 'js' || target === 'ts') {
    let modulePath = fs.realpathSync(destination);
    if (target === 'ts') {
      assert.ok(process.env.PSC1_TSC);
      const copied = path.join(folder, 'consumer/module.ts');
      fs.mkdirSync(path.dirname(copied));
      fs.copyFileSync(modulePath, copied);
      run(process.execPath, [process.env.PSC1_TSC, '--ignoreConfig', '--strict', '--target', 'ES2022',
        '--module', 'NodeNext', '--moduleResolution', 'NodeNext', '--outDir',
        path.join(folder, 'consumer/out'), copied]);
      modulePath = path.join(folder, 'consumer/out/module.js');
    }
    const api = await import(pathToFileURL(modulePath).href);
    assert.deepEqual(Object.keys(api), ['answer']);
    values = [false, true].map(flag => api.answer(flag));
  } else if (target === 'rust') {
    const crate = path.join(folder, 'crate');
    fs.cpSync(fs.realpathSync(destination.replace(/\.rs$/, '.cargo')), crate,
      { recursive: true, dereference: true });
    const library = path.join(crate, 'src/lib.rs');
    fs.chmodSync(library, 0o644);
    fs.appendFileSync(library, '\n#[cfg(test)] mod renamed_source { use super::*; ' +
      '#[test] fn results() { assert_eq!(answer(false), true); assert_eq!(answer(true), false); } }\n');
    const result = run('cargo', ['test', '--locked', '--manifest-path', path.join(crate, 'Cargo.toml')],
      { env: { ...env, CARGO_TARGET_DIR: path.join(work, 'cargo-target') } });
    assert.match(result.stdout, /test renamed_source::results \.\.\. ok/);
    values = [true, false];
  } else if (target === 'wasm-core') {
    run('wasm-tools', ['validate', destination]);
    const instance = await WebAssembly.instantiate(fs.readFileSync(destination));
    values = [0, 1].map(flag => Boolean(instance.instance.exports.answer(flag)));
  } else if (target === 'wasm-component') {
    run('wasm-tools', ['validate', destination]);
    values = [false, true].map(flag =>
      run('wasmtime', ['run', '--invoke', 'answer(' + flag + ')', destination]).stdout.trim() === 'true');
  } else if (target === 'python') {
    const result = run('python3', ['-I', '-c',
      'import importlib.util,json,sys\ns=importlib.util.spec_from_file_location("observed",sys.argv[1])\n' +
      'm=importlib.util.module_from_spec(s)\ns.loader.exec_module(m)\n' +
      'assert m.__all__==["answer"]\nprint(json.dumps([m.answer(False),m.answer(True)]))\n',
      destination]);
    values = JSON.parse(result.stdout);
  } else {
    const result = run('php', ['-d', 'memory_limit=1G', '-r',
      '$m=require $argv[1];if(array_keys($m)!==["answer"])throw new Exception("exports");' +
      'echo json_encode([$m["answer"](false),$m["answer"](true)],JSON_THROW_ON_ERROR);',
      destination]);
    values = JSON.parse(result.stdout);
  }
  assert.deepEqual(values, [true, false], grammar + '/' + stage + '/' + target);
  return { grammar, stage, target, values, sourceSha256: hash(source),
    closureSha256: manifest.sourceClosureSha256, artifactSha256: hash(fs.readFileSync(destination)),
    manifestSha256: hash(manifestBytes), independentAdmission: true, strictIr: true };
}
try {
  const lean = capture('def answer (flag : Bool) : Bool := let selected : Bool := flag; !selected\n', 'lean');
  const plain = ownership.analyze({ snapshots: [lean], entry: 'Test.Main' });
  const conversion = converter.convert({ index: plain, snapshots: [lean], targetGrammar: 'ps' });
  const ps = converter.candidateSnapshots(conversion)[0];
  for (const snapshot of [lean, ps]) {
    const snapshots = [snapshot], grammar = snapshot.grammar;
    const index = bindings.analyze({ snapshots, entry: 'Test.Main' });
    const binder = findBinder(index, 'Test.Main', 'answer', 'selected');
    const report = bindings.rename({ index, snapshots, binder, newName: 'chosenValue' });
    for (const target of ['js', 'ts', 'rust', 'wasm-core', 'wasm-component', 'python', 'php']) {
      const before = await observe(lexical.reconstruct(snapshot), grammar, 'before', target);
      const after = await observe(bindings.readCandidate(report, 'Test.Main'), grammar, 'after', target);
      assert.deepEqual(after.values, before.values);
      records.push(before, after);
      retain('in-progress');
      console.log('PSC1_RENAME_BACKEND:', grammar, target, 'before/after passed');
    }
  }
  const owned = readOwnedCompilerSources('Ps.CompilerUnified.Service');
  for (const grammar of ['lean', 'ps']) {
    const sources = grammar === 'lean' ? owned : JSON.parse(
      fs.readFileSync('dist/source-conversion/census-ps.json', 'utf8')).records.map(row =>
      ({ module: row.module, text: row.inputSource }));
    assert.equal(sources.length, owned.length);
    const snapshots = sources.map(row => capture(row.text, grammar, row.module));
    console.log('PSC1_BINDING_COMPILER_STARTED:', grammar, snapshots.length);
    const index = bindings.analyze({
      snapshots, entry: 'Ps.CompilerUnified.Service', assurance: 'ordinary-checked',
    });
    const ordinary = ownership.analyze({
      snapshots, entry: 'Ps.CompilerUnified.Service', assurance: 'ordinary-checked',
    });
    assert.equal(index.admissionsSha256, ordinary.admissionsSha256);
    assert.equal(index.originalIrSha256, ordinary.originalIrSha256);
    const binder = findBinder(index, 'Ps.Elab.SourceTrace', 'psElabSourceTraceWithLocals', 'pruned');
    const report = bindings.rename({ index, snapshots, binder, newName: 'retainedTrace' });
    const candidate = bindings.readCandidate(report, 'Ps.Elab.SourceTrace');
    fs.writeFileSync(path.join(output, 'SourceTrace.candidate.' + grammar), candidate);
    const traces = index.modules.flatMap(module => module.bindings.flatMap(batch => batch.traces));
    const record = { grammar, modules: index.modules.length, members: index.sourceCoreDeclarations,
      sourceClosureDigest: index.sourceClosureDigest, admissionsSha256: index.admissionsSha256,
      originalIrSha256: index.originalIrSha256, metrics: index.metrics,
      traces: traces.length, complete: traces.filter(trace => trace.complete).length,
      binders: traces.reduce((sum, trace) => sum + trace.binders.length, 0),
      references: traces.reduce((sum, trace) => sum + trace.references.length, 0),
      candidateSha256: hash(candidate), report };
    compiler.push(record);
    retain('in-progress');
    console.log('PSC1_BINDING_COMPILER:', JSON.stringify({
      grammar, modules: record.modules, members: record.members,
      sourceClosureDigest: record.sourceClosureDigest, traces: record.traces,
      complete: record.complete, binders: record.binders, references: record.references,
      elapsedMs: index.metrics.elapsedMs, renameElapsedMs: report.elapsedMs,
    }));
  }
  assert.equal(compiler[0].admissionsSha256, compiler[1].admissionsSha256);
  assert.equal(compiler[0].originalIrSha256, compiler[1].originalIrSha256);
  fs.writeFileSync(path.join(output, 'integration.json'), JSON.stringify({
    schema: 'psc1-source-binding-integration/1', testedCommit: process.env.GITHUB_SHA,
    checker: 'lean4:4.35.0', checkerCommit: 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',
    records, compiler, sourceFilesWritten: false, publication: false,
  }, null, 2) + '\n');
  retain('passed');
  console.log('PSC1_BINDING_INTEGRATION: PASS', JSON.stringify({
    executedArtifacts: records.length, compilerGrammars: compiler.length,
  }));
} finally { fs.rmSync(work, { recursive: true, force: true }); }
