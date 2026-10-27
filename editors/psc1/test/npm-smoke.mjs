import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {fileURLToPath, pathToFileURL} from 'node:url';
import {LspClient} from './lsp-client.mjs';

const toolsRoot = fileURLToPath(new URL('../', import.meta.url));
const packageManifest = JSON.parse(await fs.readFile(path.join(toolsRoot, 'lsp/package.json'), 'utf8'));
const tarball = path.join(toolsRoot, 'dist',
  `${packageManifest.name.replace(/^@/, '').replaceAll('/', '-')}-${packageManifest.version}.tgz`);
const temp = await fs.mkdtemp(path.join(os.tmpdir(), 'psc1-lsp-installed-'));
let npm;
for (const candidate of [process.env.npm_execpath,
  path.join(path.dirname(process.execPath), 'node_modules/npm/bin/npm-cli.js'),
  path.resolve(path.dirname(process.execPath), '../lib/node_modules/npm/bin/npm-cli.js')].filter(Boolean)) {
  try { await fs.access(candidate); npm = candidate; break; } catch { /* Next supported Node installation layout. */ }
}
assert.ok(npm, 'Cannot locate the npm CLI installed with the selected Node runtime');
let client;
try {
  await fs.writeFile(path.join(temp, 'package.json'), '{"private":true}');
  const installed = spawnSync(process.execPath, [npm, 'install', '--offline', '--ignore-scripts',
    '--no-audit', '--no-fund', '--registry=http://127.0.0.1:9', '--cache', path.join(temp, 'empty-cache'), tarball],
  {cwd: temp, encoding: 'utf8', timeout: 120000});
  assert.equal(installed.error, undefined, String(installed.error));
  assert.equal(installed.status, 0, installed.stdout + installed.stderr);
  const binary = typeof packageManifest.bin === 'string' ? packageManifest.bin : Object.values(packageManifest.bin)[0];
  assert.equal(typeof binary, 'string');
  const entry = path.join(temp, 'node_modules', packageManifest.name, binary);
  const source = path.join(temp, 'Main.ps');
  const uri = pathToFileURL(source).href;
  await fs.writeFile(source, 'def answer : Nat := 42\n');
  await fs.writeFile(path.join(temp, 'proofscript.json'), JSON.stringify({
    schema: 'proofscript-project/1', entryModule: 'Main', files: [{module: 'Main', path: 'Main.ps'}],
  }));
  const env = {...process.env};
  for (const key of Object.keys(env)) {
    if (key.toUpperCase() === 'PATH' || key.startsWith('PSC1_') || ['NODE_OPTIONS', 'LEAN_PATH', 'ELAN_TOOLCHAIN',
      'LD_LIBRARY_PATH', 'DYLD_LIBRARY_PATH'].includes(key)) delete env[key];
  }
  env.PATH = path.dirname(process.execPath);
  client = new LspClient(entry, {cwd: temp, env});
  await client.request('initialize', {processId: process.pid, rootUri: pathToFileURL(temp).href,
    capabilities: {}, initializationOptions: {trusted: true, debounceMs: 0, timeoutMs: 60000}});
  client.notify('initialized', {});
  client.notify('textDocument/didOpen', {textDocument: {uri, languageId: 'proofscript', version: 1,
    text: 'def answer : Nat := 42\n'}});
  const status = (await client.waitFor(message => message.method === 'psc1/documentStatus' &&
    message.params.uri === uri && ['checked', 'rejected', 'error'].includes(message.params.state), {timeoutMs: 90000})).params;
  assert.equal(status.state, 'checked', JSON.stringify(status));
  assert.equal(status.receipt.logicalAdmission, 'accepted');
  assert.deepEqual(status.receipt.kernelProviders, ['wasm']);
  assert.equal(status.receipt.targetValidation, 'not-run');
  assert.equal(status.receipt.publication, 'not-requested');
  assert.match(status.receipt.admissionsSha256, /^[a-f0-9]{64}$/);
  assert.ok(status.declarations.some(d => d.name === 'answer' && d.verified));
  const [code] = await client.shutdown(); assert.equal(code, 0);
  const receipt = {schema: 'psc1-lsp-npm-installed/1', status: 'passed', testedCommit: process.env.GITHUB_SHA,
    name: packageManifest.name, version: packageManifest.version, platform: process.platform, architecture: process.arch,
    tarballSha256: crypto.createHash('sha256').update(await fs.readFile(tarball)).digest('hex'),
    offlineInstall: true, emptyNpmCache: true, lifecycleScriptsDisabled: true,
    sdkFreePath: true, checked: {state: status.state, receipt: status.receipt, elapsedMs: status.elapsedMs}};
  await fs.writeFile(path.join(toolsRoot, 'dist/npm-test-receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
  console.log('PSC1 installed npm LSP smoke passed', receipt);
} finally {
  client?.dispose();
  await fs.rm(temp, {recursive: true, force: true, maxRetries: 5, retryDelay: 200});
}
