import assert from 'node:assert/strict';
import { spawn, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdtemp, mkdir, readFile, writeFile, rm, access } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { setTimeout as delay } from 'node:timers/promises';
import { pathToFileURL } from 'node:url';
import path from 'node:path';

const [proofscriptTarball, pslspTarball, evidenceDirectory] = process.argv.slice(2)
  .map(value => path.resolve(value));
assert(proofscriptTarball?.endsWith('.tgz') && pslspTarball?.endsWith('.tgz') &&
  evidenceDirectory && process.env.PSC0_SMOKE_NPM_CLI, 'PSC_LSP_SMOKE_INPUTS');
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const temp = await mkdtemp(path.join(tmpdir(), 'psc editor installed spaces-'));
const project = path.join(temp, 'checked project');
const boundedEnv = { ...process.env, PATH: path.dirname(process.execPath) };
for (const key of ['PSC0_TSC', 'PSC0_TYPESCRIPT_VERSION', 'PSC_KERNEL_CORE_PROVIDER_BIN',
  'PSC_LEAN_KERNEL_PROVIDER_BIN', 'NODE_PATH', 'LEAN_PATH', 'ELAN_HOME',
  'LEAN_SRC_PATH', 'PSC0_TEST_KERNEL_CORE_PROVIDER_BIN']) delete boundedEnv[key];
let server;
const observations = [];
try {
  await mkdir(path.join(project, 'src'), { recursive: true });
  await mkdir(evidenceDirectory, { recursive: true });
  await writeFile(path.join(project, 'package.json'), JSON.stringify({
    name: 'proofscript-editor-smoke', private: true, type: 'module',
    proofscript: { profile: 'checked', entry: 'src/Main.ps', out: 'src/Main.ts', extensions: [] },
  }, null, 2) + '\n');
  const saved = 'def answer : Nat := 42\n';
  const sourceFile = path.join(project, 'src/Main.ps');
  await writeFile(sourceFile, saved);
  const npm = spawnSync(process.execPath, [process.env.PSC0_SMOKE_NPM_CLI,
    'install', '--save-dev', '--save-exact', '--ignore-scripts', '--no-audit', '--no-fund',
    proofscriptTarball, pslspTarball], {
      cwd: project, env: process.env, encoding: 'utf8',
      timeout: 120000, maxBuffer: 5 * 1024 * 1024,
    });
  assert.equal(npm.status, 0, npm.stderr || npm.stdout);
  const psc = path.join(project, 'node_modules/proofscript/bin/psc.mjs');
  const languageServer = path.join(project, 'node_modules/pslsp/bin/pslsp.mjs');
  await Promise.all([access(psc), access(languageServer)]);
  observations.push('exact preview5 proofscript + pslsp installed without scripts or source checkout');

  function query(text) {
    const proc = spawnSync(process.execPath, [psc, 'query', 'src/Main.ps', '--stdin', '--json'], {
      cwd: project, env: boundedEnv, input: text,
      encoding: 'utf8', timeout: 90000, maxBuffer: 2 * 1024 * 1024,
    });
    assert.equal(proc.status, 0, proc.stderr);
    assert.match(proc.stderr, /^PSC_EXTENSIONS: \[\]\n/u);
    const result = JSON.parse(proc.stdout);
    assert.equal(result.kind, 'psc-source-query/1');
    assert.equal(result.sourceSha256, hash(text));
    assert.equal(result.scope, 'document-with-saved-import-closure');
    assert.equal(result.irChecked, false);
    assert.equal(result.abiChecked, false);
    assert.equal(result.targetChecked, false);
    assert.equal(result.semanticPreservationProved, false);
    assert.equal(result.pscvVerified, false);
    return result;
  }
  const accepted = query('def answer : Nat := 43\n');
  assert.equal(accepted.status, 'accepted');
  assert.equal(accepted.kernelAdmissionAccepted, true);
  assert.deepEqual(accepted.diagnostics, []);
  assert.equal(accepted.editorBuffer, undefined);
  observations.push('unsaved valid buffer has real kernel admission and no execution claim');
  const invalid = query('def answer : Nat := )\n');
  assert.equal(invalid.status, 'rejected');
  assert.equal(invalid.kernelAdmissionAccepted, false);
  assert.equal(invalid.diagnostics.length, 1);
  assert.equal(invalid.diagnostics[0].severity, 1);
  assert.equal(typeof invalid.diagnostics[0].message, 'string');
  assert.equal(await readFile(sourceFile, 'utf8'), saved);
  await assert.rejects(access(path.join(project, 'src/Main.ts')), { code: 'ENOENT' });
  await assert.rejects(access(path.join(project, 'src/Main.checked.json')), { code: 'ENOENT' });
  observations.push('unsaved invalid buffer reports rejection without touching disk or publishing');

  const uri = pathToFileURL(sourceFile).href;
  const messages = [];
  let pending = Buffer.alloc(0), stderr = '', closed;
  server = spawn(process.execPath, [languageServer, '--stdio'], {
    cwd: project, env: boundedEnv, stdio: ['pipe', 'pipe', 'pipe'], windowsHide: true,
  });
  server.stdout.on('data', chunk => {
    pending = Buffer.concat([pending, chunk]);
    assert(pending.length < 4 * 1024 * 1024);
    for (;;) {
      const start = pending.indexOf('\r\n\r\n');
      if (start < 0) break;
      const size = Number(/Content-Length: ([0-9]+)/u.exec(
        pending.subarray(0, start).toString('ascii'))?.[1]);
      assert(Number.isSafeInteger(size) && size > 0 && size < 1024 * 1024);
      if (pending.length < start + 4 + size) break;
      const message = JSON.parse(pending.subarray(start + 4, start + 4 + size).toString('utf8'));
      pending = pending.subarray(start + 4 + size);
      messages.push(message);
    }
  });
  server.stderr.on('data', chunk => { stderr += chunk; });
  server.once('close', (code, signal) => { closed = { code, signal }; });
  const send = item => {
    const body = Buffer.from(JSON.stringify({ jsonrpc: '2.0', ...item }));
    server.stdin.write(Buffer.from('Content-Length: ' + body.length + '\r\n\r\n'));
    server.stdin.write(body);
  };
  async function until(predicate, label, timeout = 90000) {
    const start = Date.now();
    while (Date.now() - start < timeout) {
      const value = predicate();
      if (value) return value;
      assert(!closed, 'PSC_LSP_SMOKE_EARLY_EXIT ' + label + ' ' + JSON.stringify(closed) + stderr.slice(-800));
      await delay(50);
    }
    assert.fail('PSC_LSP_SMOKE_TIMEOUT_' + label + ': ' + stderr.slice(-600));
  }
  send({ method: 'initialize', id: 1,
    params: { rootUri: pathToFileURL(project).href, capabilities: {} } });
  const initialized = await until(() => messages.find(x => x.id === 1), 'initialize');
  assert.equal(initialized.result.serverInfo.name, 'pslsp');
  assert.deepEqual(initialized.result.capabilities.textDocumentSync, { openClose: true, change: 1 });
  assert.equal(initialized.result.capabilities.hoverProvider, false);
  observations.push('framed LSP initialization advertises only implemented diagnostics/full sync');
  send({ method: 'initialized', params: {} });
  send({ method: 'textDocument/didOpen', params: {
    textDocument: { uri, languageId: 'proofscript', version: 1, text: saved },
  } });
  const first = await until(() => messages.find(x => x.method === 'textDocument/publishDiagnostics' &&
    x.params.uri === uri && x.params.version === 1), 'didOpen');
  assert.deepEqual(first.params.diagnostics, []);
  send({ method: 'textDocument/didChange', params: {
    textDocument: { uri, version: 2 }, contentChanges: [{ text: 'def answer : Nat := )\n' }],
  } });
  const rejection = await until(() => messages.find(x => x.method === 'textDocument/publishDiagnostics' &&
    x.params.uri === uri && x.params.version === 2), 'unsavedInvalid');
  assert.equal(rejection.params.diagnostics.length, 1);
  assert.equal(rejection.params.diagnostics[0].severity, 1);
  send({ method: 'textDocument/didChange', params: {
    textDocument: { uri, version: 3 }, contentChanges: [{ text: 'def answer : Nat := 43\n' }],
  } });
  const recovery = await until(() => messages.find(x => x.method === 'textDocument/publishDiagnostics' &&
    x.params.uri === uri && x.params.version === 3), 'unsavedValid');
  assert.deepEqual(recovery.params.diagnostics, []);
  send({ method: 'textDocument/didClose', params: { textDocument: { uri } } });
  const clear = await until(() => messages.find(x => x.method === 'textDocument/publishDiagnostics' &&
    x.params.uri === uri && !Object.hasOwn(x.params, 'version')), 'didClose');
  assert.deepEqual(clear.params.diagnostics, []);
  assert.equal(await readFile(sourceFile, 'utf8'), saved);
  await assert.rejects(access(path.join(project, 'src/Main.ts')), { code: 'ENOENT' });
  observations.push('real editor buffer rejection/recovery/close never changes saved source or writes TS');
  send({ method: 'shutdown', id: 7, params: null });
  await until(() => messages.find(x => x.id === 7), 'shutdown');
  send({ method: 'exit' });
  await until(() => closed, 'exit');
  assert.equal(closed.code, 0, stderr);

  await writeFile(path.join(evidenceDirectory, 'installed-lsp-smoke.json'),
    JSON.stringify({ kind: 'psc0-installed-lsp-smoke', passed: true,
      platform: process.platform, node: process.versions.node,
      sourceFileUnchanged: true, outputPublished: false,
      productSha256: hash(await readFile(proofscriptTarball)),
      pslspSha256: hash(await readFile(pslspTarball)),
      observations, diagnostics: invalid.diagnostics,
      noHoverOrDefinitionClaim: true }, null, 2) + '\n');
  console.log('PSC_LSP_INSTALLED: PASS ' + JSON.stringify({
    count: observations.length, platform: process.platform, node: process.versions.node,
  }));
} finally {
  if (server && server.exitCode === null) {
    server.kill('SIGTERM');
    await delay(100);
    if (server.exitCode === null) server.kill('SIGKILL');
  }
  await rm(temp, { recursive: true, force: true });
}
