import assert from 'node:assert/strict';
import { test } from 'node:test';
import { spawn } from 'node:child_process';
import { mkdtemp, mkdir, writeFile, copyFile, rm, readFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { setTimeout as delay } from 'node:timers/promises';

const sourceRoot = fileURLToPath(new URL('../../../', import.meta.url));
const frame = value => {
  const body = Buffer.from(JSON.stringify(value));
  return Buffer.concat([Buffer.from('Content-Length: ' + body.length + '\r\n\r\n'), body]);
};
async function until(predicate, message, timeout = 16000) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    const value = predicate();
    if (value) return value;
    await delay(25);
  }
  assert.fail('PSC_LSP_TEST_TIMEOUT: ' + message);
}

test('bounded LSP diagnostics use unsaved buffers and suppress stale document versions', async t => {
  const temporary = await mkdtemp(path.join(tmpdir(), 'pslsp test spaces-'));
  t.after(() => rm(temporary, { force: true, recursive: true }));
  const modules = path.join(temporary, 'node_modules');
  const project = path.join(temporary, 'project');
  const serverDir = path.join(modules, 'pslsp/bin');
  const compilerDir = path.join(modules, 'proofscript/bin');
  await Promise.all([mkdir(serverDir, { recursive: true }),
    mkdir(compilerDir, { recursive: true }),
    mkdir(path.join(project, 'src'), { recursive: true })]);
  await copyFile(path.join(sourceRoot, 'packages/pslsp/bin/pslsp.mjs'),
    path.join(serverDir, 'pslsp.mjs'));
  await writeFile(path.join(modules, 'pslsp/package.json'),
    JSON.stringify({ name: 'pslsp', version: '0.1.0-preview.5', type: 'module' }));
  await writeFile(path.join(modules, 'proofscript/package.json'),
    JSON.stringify({ name: 'proofscript', version: '0.1.0-preview.5', type: 'module' }));
  const mock = [
    "import { createHash } from 'node:crypto';",
    "import path from 'node:path';",
    "let source = ''; for await (const chunk of process.stdin) source += chunk;",
    "const hash = createHash('sha256').update(source).digest('hex');",
    "if (source.includes('SLOW')) await new Promise(resolve => setTimeout(resolve, 650));",
    "const bad = source.includes('INVALID');",
    "process.stdout.write(JSON.stringify({",
    " kind: 'psc-source-query/1', entryPath: path.resolve(process.argv[3]),",
    " sourceSha256: hash, status: bad ? 'rejected' : 'accepted',",
    " kernelAdmissionAccepted: !bad,",
    " diagnostics: bad ? [{ source: 'ProofScript', severity: 1,",
    "   code: 'PSC_TEST_INVALID', message: 'Mock compiler rejected source',",
    "   range: { start: { line: 0, character: 0 }, end: { line: 0, character: 2 } } }] : [],",
    "}) + '\\n');",
  ].join('\n');
  await writeFile(path.join(compilerDir, 'psc.mjs'), mock);
  const file = path.join(project, 'src/Main.ps');
  await writeFile(file, 'def answer : Nat := 42\n');
  const uri = pathToFileURL(file).href;
  const server = spawn(process.execPath, [path.join(serverDir, 'pslsp.mjs'), '--stdio'], {
    cwd: project, stdio: ['pipe', 'pipe', 'pipe'], windowsHide: true,
  });
  let left = Buffer.alloc(0), stderr = '';
  const messages = [];
  server.stdout.on('data', data => {
    left = Buffer.concat([left, data]);
    for (;;) {
      const end = left.indexOf('\r\n\r\n');
      if (end < 0) break;
      const header = left.subarray(0, end).toString('ascii');
      const size = Number(/Content-Length: ([0-9]+)/u.exec(header)?.[1]);
      assert(Number.isInteger(size) && size > 0);
      if (left.length < end + 4 + size) break;
      messages.push(JSON.parse(left.subarray(end + 4, end + 4 + size).toString('utf8')));
      left = left.subarray(end + 4 + size);
    }
  });
  server.stderr.on('data', data => { stderr += data; });
  t.after(() => { if (server.exitCode === null) server.kill('SIGTERM'); });
  function send(value) { server.stdin.write(frame({ jsonrpc: '2.0', ...value })); }
  send({ id: 1, method: 'initialize', params: { rootUri: pathToFileURL(project).href, capabilities: {} } });
  const init = await until(() => messages.find(x => x.id === 1), 'initialize');
  assert.equal(init.result.serverInfo.name, 'pslsp');
  assert.deepEqual(init.result.capabilities.textDocumentSync, { openClose: true, change: 1 });
  assert.equal(init.result.capabilities.hoverProvider, false);
  assert.equal(init.result.capabilities.definitionProvider, false);
  send({ method: 'initialized', params: {} });
  send({ method: 'textDocument/didOpen', params: {
    textDocument: { uri, languageId: 'proofscript', version: 1, text: 'good unsaved' },
  } });
  const first = await until(() => messages.find(x => x.method === 'textDocument/publishDiagnostics' &&
    x.params.uri === uri && x.params.version === 1), 'valid unsaved');
  assert.deepEqual(first.params.diagnostics, []);
  send({ method: 'textDocument/didChange', params: {
    textDocument: { uri, version: 2 }, contentChanges: [{ text: 'SLOW INVALID' }],
  } });
  await delay(180);
  send({ method: 'textDocument/didChange', params: {
    textDocument: { uri, version: 3 }, contentChanges: [{ text: 'good new unsaved' }],
  } });
  const third = await until(() => messages.find(x => x.method === 'textDocument/publishDiagnostics' &&
    x.params.version === 3), 'superseded valid');
  assert.deepEqual(third.params.diagnostics, []);
  await delay(750);
  assert.equal(messages.some(x => x.method === 'textDocument/publishDiagnostics' &&
    x.params.version === 2), false, 'slow old check never clears new diagnostics');
  send({ method: 'textDocument/didChange', params: {
    textDocument: { uri, version: 4 }, contentChanges: [{ text: 'INVALID' }],
  } });
  const fourth = await until(() => messages.find(x => x.method === 'textDocument/publishDiagnostics' &&
    x.params.version === 4), 'invalid query');
  assert.equal(fourth.params.diagnostics[0].code, 'PSC_TEST_INVALID');
  send({ method: 'textDocument/didClose', params: { textDocument: { uri } } });
  const closed = await until(() => messages.find(x => x.method === 'textDocument/publishDiagnostics' &&
    x.params.uri === uri && !Object.hasOwn(x.params, 'version')), 'close clears diagnostics');
  assert.deepEqual(closed.params.diagnostics, []);
  assert.equal(await readFile(file, 'utf8'), 'def answer : Nat := 42\n');
  send({ id: 8, method: 'textDocument/hover', params: { textDocument: { uri },
    position: { line: 0, character: 0 } } });
  assert.equal((await until(() => messages.find(x => x.id === 8), 'hover')).error.code, -32601);
  send({ id: 9, method: 'shutdown', params: null });
  await until(() => messages.find(x => x.id === 9), 'shutdown');
  send({ method: 'exit' });
  await until(() => server.exitCode !== null, 'clean exit');
  assert.equal(server.exitCode, 0, stderr);
});
