import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath, pathToFileURL} from 'node:url';
import {LspClient} from './lsp-client.mjs';

const toolsRoot = fileURLToPath(new URL('../', import.meta.url));
const entry = process.env.PSC1_LSP_ENTRY || path.join(toolsRoot, 'lsp/dist/server.cjs');
const terminal = new Set(['checked', 'partial', 'rejected', 'error', 'unsupported', 'untrusted']);
const statusFor = (uri, version, predicate = () => true) => message =>
  message.method === 'psc1/documentStatus' && message.params.uri === uri &&
  (version === undefined || message.params.version === version) && predicate(message.params);
const completed = (uri, version) => statusFor(uri, version, p => terminal.has(p.state));
const open = (client, uri, text, version = 1, languageId = 'proofscript') =>
  client.notify('textDocument/didOpen', {textDocument: {uri, text, version, languageId}});
const change = (client, uri, text, version) => client.notify('textDocument/didChange', {
  textDocument: {uri, version}, contentChanges: [{text}],
});
const config = files => ({schema: 'proofscript-project/1', entryModule: 'Main', files});
const cleanEnvironment = () => {
  const env = {...process.env, PATH: path.dirname(process.execPath)};
  for (const key of Object.keys(env)) {
    if (key.startsWith('PSC1_') || ['NODE_OPTIONS', 'LEAN_PATH', 'ELAN_TOOLCHAIN',
      'LD_LIBRARY_PATH', 'DYLD_LIBRARY_PATH'].includes(key)) delete env[key];
  }
  return env;
};

async function initialize(client, roots, options = {}) {
  const result = await client.request('initialize', {
    processId: process.pid,
    rootUri: pathToFileURL(roots[0]).href,
    workspaceFolders: roots.map((root, index) => ({uri: pathToFileURL(root).href, name: `workspace${index}`})),
    capabilities: {
      workspace: {workspaceFolders: true},
      general: {positionEncodings: ['utf-16']},
      textDocument: {publishDiagnostics: {relatedInformation: true, versionSupport: true},
        documentSymbol: {hierarchicalDocumentSymbolSupport: true},
        hover: {contentFormat: ['markdown', 'plaintext']},
        completion: {completionItem: {snippetSupport: false}}},
    },
    initializationOptions: {trusted: true, enableLean: true, debounceMs: 50, timeoutMs: 60000, ...options},
  });
  client.notify('initialized', {});
  return result;
}

function assertRejected(status) {
  assert.equal(status.state, 'rejected', JSON.stringify(status));
  assert.ok(status.diagnostics.some(d => d.severity === 1), JSON.stringify(status));
  assert.ok(status.diagnostics.every(d => typeof d.message === 'string' && d.message.length));
  assert.ok(status.declarations.every(d => d.verified !== true), 'Rejected project must not carry verified declarations');
}

test('real packaged PSC1 checks, imports, versions, editor requests and lifecycle', {timeout: 480000}, async t => {
  const temp = await fs.mkdtemp(path.join(os.tmpdir(), 'psc1-lsp-integration-'));
  const single = path.join(temp, 'single project with spaces');
  const multi = path.join(temp, 'import project');
  await fs.mkdir(single); await fs.mkdir(multi);
  const mainFile = path.join(single, 'Main.ps');
  const mainUri = pathToFileURL(mainFile).href;
  // Deliberately contradictory disk state proves the server checks the buffer.
  await fs.writeFile(mainFile, 'def answer : Nat := true\n');
  await fs.writeFile(path.join(single, 'proofscript.json'), JSON.stringify(config([{module: 'Main', path: 'Main.ps'}])));
  const libText = 'namespace Lib\ndef base : Nat := 40\nend Lib\n';
  const importText = 'import Lib\ndef answer : Nat := Lib.base + 2\n';
  await fs.writeFile(path.join(multi, 'Lib.lean'), libText);
  await fs.writeFile(path.join(multi, 'Main.lean'), importText);
  await fs.writeFile(path.join(multi, 'proofscript.json'), JSON.stringify(config([
    {module: 'Lib', path: 'Lib.lean'}, {module: 'Main', path: 'Main.lean'},
  ])));
  const client = new LspClient(entry, {cwd: single, env: cleanEnvironment()});
  const observations = [];
  try {
    const initialized = await initialize(client, [single, multi]);
    assert.ok(initialized.capabilities.textDocumentSync);
    const positionEncoding = initialized.capabilities.positionEncoding || 'utf-16';
    assert.equal(positionEncoding, 'utf-16');
    const server = await client.request('psc1/serverInfo', {});
    assert.ok(server && typeof server === 'object');

    await t.test('open uses unsaved text and genuine independently checked admission', async () => {
      open(client, mainUri, 'def answer : Nat := 42\n');
      const status = (await client.waitFor(completed(mainUri, 1))).params;
      assert.equal(status.state, 'checked', JSON.stringify(status));
      assert.equal(status.compilerVersion, '0.1.0-psc1.12');
      assert.equal(status.receipt.logicalAdmission, 'accepted');
      assert.deepEqual(status.receipt.kernelProviders, ['wasm']);
      assert.ok(status.declarations.some(d => d.name === 'answer' && d.verified === true), JSON.stringify(status));
      assert.ok(!status.diagnostics.some(d => d.severity === 1));
      observations.push({case: 'unsaved-valid', state: status.state, elapsedMs: status.elapsedMs});
    });

    await t.test('Infoview uses checked declarations and does not invent proof goals', async () => {
      const info = await client.request('psc1/infoview', {
        textDocument: {uri: mainUri}, position: {line: 0, character: 6}, version: 1,
      });
      assert.equal(info.version, 1); assert.equal(info.state, 'checked');
      assert.equal(info.goalsAvailable, false);
      assert.ok(info.declaration && info.declaration.name === 'answer', JSON.stringify(info));
      if (initialized.capabilities.documentSymbolProvider) {
        const symbols = await client.request('textDocument/documentSymbol', {textDocument: {uri: mainUri}});
        assert.ok(symbols.some(d => d.name === 'answer'));
      }
      if (initialized.capabilities.hoverProvider) {
        const hover = await client.request('textDocument/hover', {textDocument: {uri: mainUri}, position: {line: 0, character: 6}});
        assert.match(JSON.stringify(hover), /Nat/);
      }
      if (initialized.capabilities.completionProvider) {
        const result = await client.request('textDocument/completion', {textDocument: {uri: mainUri}, position: {line: 0, character: 6}});
        assert.ok(Array.isArray(result) ? result.length : result?.items?.length);
      }
      observations.push({case: 'editor-requests', capabilities: initialized.capabilities});
    });

    await t.test('ill-typed unsaved source publishes real rejection and valid ranges', async () => {
      const after = client.messages.length;
      change(client, mainUri, '-- Unicode λ 😀\r\ndef answer : Nat := true\r\n', 2);
      const status = (await client.waitFor(completed(mainUri, 2), {after})).params;
      assertRejected(status);
      const published = await client.waitFor(message => message.method === 'textDocument/publishDiagnostics' &&
        message.params.uri === mainUri && message.params.version === 2 && message.params.diagnostics.length, {after});
      for (const diagnostic of published.params.diagnostics) {
        assert.ok(diagnostic.range.start.line >= 0 && diagnostic.range.start.line <= 2);
        assert.ok(diagnostic.range.start.character >= 0);
        assert.ok(diagnostic.range.end.line >= diagnostic.range.start.line);
      }
      observations.push({case: 'real-type-rejection', state: status.state, diagnostics: status.diagnostics});
    });

    await t.test('UTF-16 incremental edit repairs source without saving', async () => {
      const after = client.messages.length;
      client.notify('textDocument/didChange', {textDocument: {uri: mainUri, version: 3}, contentChanges: [
        {range: {start: {line: 0, character: 13}, end: {line: 0, character: 15}}, text: '🐈'},
        {range: {start: {line: 1, character: 20}, end: {line: 1, character: 24}}, text: '42'},
      ]});
      const status = (await client.waitFor(completed(mainUri, 3), {after})).params;
      assert.equal(status.state, 'checked', JSON.stringify(status));
      await client.waitFor(message => message.method === 'textDocument/publishDiagnostics' &&
        message.params.uri === mainUri && message.params.version === 3 &&
        !message.params.diagnostics.some(d => d.severity === 1), {after});
      observations.push({case: 'unicode-incremental-repair', state: status.state});
    });

    await t.test('superseded in-flight work cannot overwrite the newest document', async () => {
      const after = client.messages.length;
      change(client, mainUri, 'def answer : Nat := true\n', 4);
      await client.waitFor(statusFor(mainUri, 4, p => p.state === 'checking'), {after});
      change(client, mainUri, 'def answer : Nat := 44\n', 5);
      await client.waitFor(statusFor(mainUri, 5, p => p.state === 'pending' || p.state === 'checking'), {after});
      const supersession = client.messages.findIndex((m, i) => i >= after && statusFor(mainUri, 5)(m));
      const latest = (await client.waitFor(completed(mainUri, 5), {after})).params;
      assert.equal(latest.state, 'checked', JSON.stringify(latest));
      await client.request('psc1/serverInfo', {});
      assert.ok(!client.messages.slice(supersession).some(m => completed(mainUri, 4)(m)), 'Stale terminal result published after newer document was accepted');
      const request = client.request('psc1/infoview', {textDocument: {uri: mainUri}, position: {line: 0, character: 5}, version: 5});
      client.notify('$/cancelRequest', {id: request.requestId});
      // Cancellation may race with an already completed cheap request; either a
      // normal reply or the specified cancellation error must settle the request.
      await request.catch(error => { assert.equal(error.code, -32800); });
      observations.push({case: 'inflight-supersession-and-cancellation', state: latest.state});
    });

    await t.test('save and explicit recheck preserve the real compiler result', async () => {
      await fs.writeFile(mainFile, 'def answer : Nat := 44\n');
      const after = client.messages.length;
      client.notify('textDocument/didSave', {textDocument: {uri: mainUri}});
      await client.request('psc1/recheck', {uri: mainUri});
      const status = (await client.waitFor(completed(mainUri, 5), {after})).params;
      assert.equal(status.state, 'checked', JSON.stringify(status));
    });

    await t.test('multi-root project imports and unsaved dependency invalidation', async () => {
      const importedUri = pathToFileURL(path.join(multi, 'Main.lean')).href;
      const libUri = pathToFileURL(path.join(multi, 'Lib.lean')).href;
      const after = client.messages.length;
      open(client, importedUri, importText, 1, 'proofscript-lean');
      const first = (await client.waitFor(completed(importedUri, 1), {after})).params;
      assert.equal(first.state, 'checked', JSON.stringify(first));
      open(client, libUri, libText, 1, 'proofscript-lean');
      const libFirst = (await client.waitFor(completed(libUri, 1), {after})).params;
      assert.equal(libFirst.state, 'checked', JSON.stringify(libFirst));
      const changedAfter = client.messages.length;
      change(client, libUri, 'namespace Lib\ndef base : Nat := true\nend Lib\n', 2);
      const rejected = (await client.waitFor(statusFor(importedUri, 1,
        p => terminal.has(p.state) && p.projectGeneration > libFirst.projectGeneration), {after: changedAfter})).params;
      assertRejected(rejected);
      assert.notEqual(rejected.projectGeneration, first.projectGeneration);
      const restoredAfter = client.messages.length;
      client.notify('textDocument/didClose', {textDocument: {uri: libUri}});
      const restored = (await client.waitFor(statusFor(importedUri, 1,
        p => terminal.has(p.state) && p.projectGeneration > rejected.projectGeneration), {after: restoredAfter})).params;
      assert.equal(restored.state, 'checked', JSON.stringify(restored));
      client.notify('textDocument/didClose', {textDocument: {uri: importedUri}});
      observations.push({case: 'unsaved-import-and-close-restoration', state: restored.state});
    });

    await t.test('valid theorem is checked and invalid proof is refused by the real compiler', async () => {
      const after = client.messages.length;
      change(client, mainUri, 'theorem identity(P : Prop, h : P) : P := h\ndef answer : Nat := 42\n', 6);
      const proved = (await client.waitFor(completed(mainUri, 6), {after})).params;
      assert.equal(proved.state, 'checked', JSON.stringify(proved));
      assert.ok(proved.declarations.some(d => d.name === 'identity' && d.verified));
      change(client, mainUri, 'theorem identity(P : Prop, h : P) : P := 0\ndef answer : Nat := 42\n', 7);
      const refused = (await client.waitFor(completed(mainUri, 7), {after})).params;
      assertRejected(refused);
      observations.push({case: 'real-proof-refusal', stage: 'compiler elaboration before kernel admission',
        state: refused.state, diagnostics: refused.diagnostics});
    });

    await t.test('malformed source recovers without restarting the server', async () => {
      const after = client.messages.length;
      change(client, mainUri, 'def answer : :=\n', 8);
      const rejected = (await client.waitFor(completed(mainUri, 8), {after})).params;
      assertRejected(rejected);
      change(client, mainUri, 'def answer : Nat := 45\n', 9);
      const recovered = (await client.waitFor(completed(mainUri, 9), {after})).params;
      assert.equal(recovered.state, 'checked', JSON.stringify(recovered));
      observations.push({case: 'parse-error-recovery', state: recovered.state});
    });

    await t.test('compiler-origin declaration coordinates use UTF-16 after an emoji', async () => {
      const after = client.messages.length;
      change(client, mainUri, '/- 😀 -/ def answer : Nat := 42\n', 10);
      const status = (await client.waitFor(completed(mainUri, 10), {after})).params;
      assert.equal(status.state, 'checked', JSON.stringify(status));
      const answer = status.declarations.find(d => d.name === 'answer');
      assert.deepEqual(answer.selectionRange.start, {line: 0, character: 13});
      assert.deepEqual(answer.selectionRange.end, {line: 0, character: 19});
      observations.push({case: 'compiler-origin-utf16', range: answer.selectionRange});
    });

    await t.test('project metadata cannot choose an executable and watchers recover', async () => {
      const projectFile = path.join(single, 'proofscript.json');
      const projectUri = pathToFileURL(projectFile).href;
      const original = config([{module: 'Main', path: 'Main.ps'}]);
      await fs.writeFile(projectFile, JSON.stringify({...original, checkerExecutable: '/untrusted/checker'}));
      const after = client.messages.length;
      client.notify('workspace/didChangeWatchedFiles', {changes: [{uri: projectUri, type: 2}]});
      const refused = (await client.waitFor(completed(mainUri, 10), {after})).params;
      assert.equal(refused.state, 'error');
      assert.ok(refused.diagnostics.some(d => /PROJECT_FIELDS/.test(d.code)));
      assert.ok(!refused.declarations.some(d => d.verified));
      await fs.writeFile(projectFile, JSON.stringify(original));
      const restoredAfter = client.messages.length;
      client.notify('workspace/didChangeWatchedFiles', {changes: [{uri: projectUri, type: 2}]});
      const restored = (await client.waitFor(completed(mainUri, 10), {after: restoredAfter})).params;
      assert.equal(restored.state, 'checked', JSON.stringify(restored));
      observations.push({case: 'untrusted-metadata-refusal-and-watch-recovery', state: restored.state});
    });

    await t.test('close clears open-buffer diagnostics and graceful shutdown exits zero', async () => {
      const after = client.messages.length;
      client.notify('textDocument/didClose', {textDocument: {uri: mainUri}});
      await client.waitFor(message => message.method === 'textDocument/publishDiagnostics' &&
        message.params.uri === mainUri && message.params.diagnostics.length === 0, {after});
      const [code, signal] = await client.shutdown();
      assert.equal(code, 0); assert.equal(signal, null);
    });
    const out = path.join(toolsRoot, 'dist'); await fs.mkdir(out, {recursive: true});
    await fs.writeFile(path.join(out, 'lsp-test-receipt.json'), JSON.stringify({
      schema: 'psc1-lsp-tests/1', testedCommit: process.env.GITHUB_SHA,
      compilerBackend: 'real packaged PSC1 with official Lean WASM kernel',
      compilerMocks: false, node: process.version, server, observations,
    }, null, 2) + '\n');
  } finally {
    client.dispose();
    await fs.rm(temp, {recursive: true, force: true});
  }
});

test('untrusted workspace does not check code or grant verification', {timeout: 45000}, async () => {
  const temp = await fs.mkdtemp(path.join(os.tmpdir(), 'psc1-lsp-untrusted-'));
  const client = new LspClient(entry, {cwd: temp, env: cleanEnvironment()});
  try {
    await initialize(client, [temp], {trusted: false});
    const uri = pathToFileURL(path.join(temp, 'Main.ps')).href;
    open(client, uri, 'def answer : Nat := 42\n');
    const status = (await client.waitFor(completed(uri, 1), {timeoutMs: 10000})).params;
    assert.equal(status.state, 'untrusted');
    assert.ok(!status.declarations.some(d => d.verified));
    const [code] = await client.shutdown(); assert.equal(code, 0);
  } finally { client.dispose(); await fs.rm(temp, {recursive: true, force: true}); }
});
