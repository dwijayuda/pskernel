import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {fileURLToPath, pathToFileURL} from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const repository = path.resolve(here, '../../..');
const compilerRoot = path.join(repository, 'editors/psc1/lsp/compiler/package');
const {loadProject} = await import(pathToFileURL(path.join(repository, 'editors/psc1/lsp/src/project.mjs')).href);
const sha = value => crypto.createHash('sha256').update(value).digest('hex');
let consumed = false;

process.on('message', async ({root, example}) => {
  if (consumed) return;
  consumed = true;
  const started = performance.now();
  let report;
  try {
    const directory = path.join(root, example.id);
    const entry = example.files.find(file => file.module === example.entryModule);
    assert.ok(entry, 'Entry module is declared');
    const project = await loadProject(pathToFileURL(path.join(directory, entry.path)).href,
      new Map(), [{uri: pathToFileURL(directory).href, name: example.id}]);
    const manifest = JSON.parse(fs.readFileSync(path.join(compilerRoot, 'package.json')));
    assert.equal(manifest.name, 'proofscript');
    assert.equal(manifest.version, '0.1.0-psc1.12');
    const api = await import(pathToFileURL(path.join(compilerRoot, 'dist/index.js')).href);
    const options = {sources: project.sources, entryModule: project.entryModule,
      assurance: 'checked', engine: 'js', target: 'js', kernel: 'wasm'};
    const prepared = api.compileCandidate(options);
    const candidate = prepared.candidate;
    const files = project.files.map(file => ({module: file.module,
      path: example.files.find(row => row.module === file.module).path, sha256: file.sha256}));
    if (example.expected === 'rejected') {
      assert.equal(candidate.status, 'refused', 'Intentional diagnostic must be refused by the real compiler');
      if (example.expectedPhase) assert.equal(candidate.phase, example.expectedPhase);
      if (example.expectedCode) assert.equal(candidate.code, example.expectedCode);
      report = {id: example.id, status: 'passed', expected: 'rejected', files,
        actual: {state: 'rejected', phase: candidate.phase, code: candidate.code,
          module: candidate.module, declaration: candidate.declaration}, logicalAdmission: 'not-run'};
    } else {
      assert.equal(candidate.status, 'candidate', JSON.stringify(candidate));
      assert.equal(candidate.candidateOnly, true);
      const compiled = api.compile(options);
      assert.equal(compiled.status, 'accepted');
      assert.equal(compiled.logicalAdmission, 'accepted');
      assert.equal(compiled.receipt.logicalAdmission, 'accepted');
      assert.deepEqual(compiled.kernelProviders, ['wasm']);
      assert.equal(compiled.receipt.sourceClosureDigest, candidate.sourceClosureDigest);
      assert.equal(compiled.compilerSourceClosureDigest, prepared.compilerSourceClosureDigest);
      assert.equal(compiled.receipt.admissionsSha256, sha(candidate.admissionRequest.admissions));
      assert.equal(candidate.sourceClosureDigest, sha(JSON.stringify(project.sources.map(source => ({
        module: source.module, kind: source.kind, utf8Sha256: sha(source.text)})))));
      const generated = path.join(process.env.TMPDIR, 'example-target.mjs');
      fs.writeFileSync(generated, compiled.source);
      const application = await import(pathToFileURL(generated).href);
      const observed = {};
      for (const [name, expected] of Object.entries(example.expectedExports || {})) {
        assert.ok(Object.hasOwn(application, name), 'Generated module exports ' + name);
        const actual = application[name];
        if (typeof expected === 'number') {
          assert.ok(Number.isSafeInteger(expected));
          assert.ok(typeof actual === 'number' || typeof actual === 'bigint', name + ' has a numeric runtime value');
          assert.equal(String(actual), String(expected), name + ' runtime value');
        } else assert.equal(actual, expected, name + ' runtime value');
        observed[name] = {expected, actual: typeof actual === 'bigint' ? actual.toString() : actual,
          runtimeType: typeof actual};
      }
      report = {id: example.id, status: 'passed', expected: 'checked', files,
        actual: {state: 'checked', logicalAdmission: 'accepted', kernelProviders: compiled.kernelProviders,
          compilerSourceClosureDigest: compiled.compilerSourceClosureDigest,
          sourceClosureDigest: compiled.receipt.sourceClosureDigest,
          admissionsSha256: compiled.receipt.admissionsSha256,
          targetSourceSha256: sha(compiled.source), publication: compiled.publication,
          formalPreservation: compiled.formalPreservation}, runtimeAssertions: observed};
    }
  } catch (error) {
    report = {id: example.id, status: 'failed', expected: example.expected,
      error: String(error?.message || error), stack: String(error?.stack || '').slice(0, 6000)};
  }
  report.elapsedMs = Math.round(performance.now() - started);
  if (process.connected) process.send(report, () => {process.disconnect(); process.exit(0);});
  else process.exit(1);
});
