import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import assert from 'node:assert/strict';
import {fileURLToPath, pathToFileURL} from 'node:url';
import {LspClient} from './lsp-client.mjs';

// A reproducible end-to-end observation, not a compiler microbenchmark. Run the
// same file against an extracted prior package using PSC1_LSP_ENTRY and
// PSC1_PERF_BASELINE=1, then against the candidate on the same Actions runner.
const toolsRoot = fileURLToPath(new URL('../', import.meta.url));
const entry = process.env.PSC1_LSP_ENTRY || path.join(toolsRoot, 'lsp/dist/server.cjs');
const baseline = process.env.PSC1_PERF_BASELINE === '1';
const expectedVersion = process.env.PSC1_PERF_EXPECTED_VERSION || '0.1.2';
const legacyBaseline = baseline && expectedVersion === '0.1.0';
const label = process.env.PSC1_PERF_LABEL || (baseline ? 'baseline' : 'candidate');
const debounceSetting = process.env.PSC1_PERF_DEBOUNCE_MS || '50';
const debounceOverride = debounceSetting === 'default' ? null : Number(debounceSetting);
assert.ok(debounceOverride === null || (Number.isSafeInteger(debounceOverride) && debounceOverride >= 0 && debounceOverride <= 5000));
const output = process.env.PSC1_PERF_OUTPUT || path.join(toolsRoot, 'dist/performance-receipt.json');
const terminal = new Set(['checked', 'partial', 'rejected', 'error', 'unsupported', 'untrusted']);
const sourceFor = number => `def answer : Nat := ${number}\n`;
const round = value => Math.round(value * 100) / 100;
const median = values => [...values].sort((a, b) => a - b)[Math.floor(values.length / 2)];
const temporary = await fs.mkdtemp(path.join(os.tmpdir(), 'psc1-editor-latency-'));
const source = path.join(temporary, 'Main.ps');
const uri = pathToFileURL(source).href;
const samples = [];
const env = {...process.env};
for (const key of Object.keys(env)) {
  if (key.toUpperCase() === 'PATH' || key.startsWith('PSC1_') ||
      ['NODE_OPTIONS', 'LEAN_PATH', 'ELAN_TOOLCHAIN', 'LD_LIBRARY_PATH', 'DYLD_LIBRARY_PATH'].includes(key)) delete env[key];
}
env.PATH = path.dirname(process.execPath);
let client, server, startupMs;

async function observe(kind, version, send, expectedValue) {
  const before = await client.request('psc1/serverInfo', {});
  const after = client.messages.length;
  const started = performance.now();
  send();
  const message = await client.waitFor(message => message.method === 'psc1/documentStatus' &&
    message.params.uri === uri && message.params.version === version && terminal.has(message.params.state),
  {after, timeoutMs: 90000});
  const terminalIndex = client.messages.indexOf(message);
  const wallMs = client.messageTimes[terminalIndex] - started;
  const status = message.params;
  assert.equal(status.state, 'checked', `${kind}: ${JSON.stringify(status)}`);
  assert.equal(status.receipt.logicalAdmission, 'accepted');
  assert.deepEqual(status.receipt.kernelProviders, ['wasm']);
  assert.ok(status.declarations.some(declaration => declaration.name === 'answer' && declaration.verified));
  assert.match(status.receipt.admissionsSha256, /^[a-f0-9]{64}$/);
  if (!legacyBaseline) {
    assert.equal(status.receipt.targetValidation, 'not-run');
    assert.equal(status.snapshotVersions[uri], version);
  }
  const info = await client.request('psc1/serverInfo', {});
  const checkingIndex = client.messages.findIndex((message, index) => index >= after &&
    message.method === 'psc1/documentStatus' && message.params.uri === uri &&
    message.params.version === version && message.params.state === 'checking');
  const row = {kind, version, sourceValue: expectedValue, notificationToCheckedMs: round(wallMs),
    notificationToCheckingMs: checkingIndex < 0 ? null : round(client.messageTimes[checkingIndex] - started),
    compilerReportedMs: status.elapsedMs, phases: status.timings || null,
    cacheHit: status.cacheHit === true, reused: status.reused === true,
    reusedKernelHealth: status.reusedKernelHealth ?? null,
    checksStarted: info.metrics.checksStarted - before.metrics.checksStarted,
    admissionsSha256: status.receipt.admissionsSha256,
    sourceClosureDigest: status.receipt.sourceClosureDigest};
  samples.push(row);
  return {row, status};
}

try {
  await fs.writeFile(source, sourceFor(100));
  await fs.writeFile(path.join(temporary, 'proofscript.json'), JSON.stringify({
    schema: 'proofscript-project/1', entryModule: 'Main', files: [{module: 'Main', path: 'Main.ps'}],
  }));
  const launched = performance.now();
  client = new LspClient(entry, {cwd: temporary, env});
  await client.request('initialize', {
    processId: process.pid, rootUri: pathToFileURL(temporary).href,
    capabilities: {workspace: {workspaceFolders: true}, textDocument: {publishDiagnostics: {versionSupport: true}}},
    workspaceFolders: [{uri: pathToFileURL(temporary).href, name: 'latency'}],
    initializationOptions: {trusted: true, ...(debounceOverride === null ? {} : {debounceMs: debounceOverride}), timeoutMs: 60000},
  });
  client.notify('initialized', {});
  startupMs = round(performance.now() - launched);
  server = await client.request('psc1/serverInfo', {});
  assert.equal(server.version, expectedVersion, 'Measure the requested actual server version');
  await observe('cold-open', 1, () => client.notify('textDocument/didOpen', {
    textDocument: {uri, languageId: 'proofscript', version: 1, text: sourceFor(100)},
  }), 100);
  for (let version = 2; version <= 4; version++) {
    const value = 99 + version;
    const {row} = await observe('distinct-edit', version, () => client.notify('textDocument/didChange', {
      textDocument: {uri, version}, contentChanges: [{text: sourceFor(value)}],
    }), value);
    assert.equal(row.checksStarted, 1, 'Every distinct source must receive a genuine new check');
  }
  await fs.writeFile(source, sourceFor(103));
  const saved = await observe('unchanged-save', 4,
    () => client.notify('textDocument/didSave', {textDocument: {uri}}), 103);
  if (!legacyBaseline) {
    assert.equal(saved.status.reused, true);
    assert.equal(saved.status.trigger, 'save');
    assert.equal(saved.row.checksStarted, 0);
  }
  const restored = await observe('repeat-snapshot', 5, () => client.notify('textDocument/didChange', {
    textDocument: {uri, version: 5}, contentChanges: [{text: sourceFor(102)}],
  }), 102);
  const prior = samples.find(sample => sample.kind === 'distinct-edit' && sample.sourceValue === 102);
  assert.equal(restored.row.admissionsSha256, prior.admissionsSha256);
  assert.equal(restored.row.sourceClosureDigest, prior.sourceClosureDigest);
  if (!legacyBaseline) {
    assert.equal(restored.row.cacheHit, true);
    assert.equal(restored.row.checksStarted, 0);
  }
  const finalServer = await client.request('psc1/serverInfo', {});
  const freshSamples = samples.filter(sample => sample.kind === 'cold-open' || sample.kind === 'distinct-edit');
  assert.equal(new Set(freshSamples.map(sample => sample.sourceClosureDigest)).size, 4);
  assert.equal(new Set(freshSamples.map(sample => sample.admissionsSha256)).size, 4);
  if (expectedVersion === '0.1.2') {
    assert.equal(finalServer.metrics.workerStarts, 1);
    assert.equal(finalServer.metrics.workerReuses, 3);
    freshSamples.forEach((sample, index) => assert.equal(sample.reusedKernelHealth, index > 0));
  }
  const [code] = await client.shutdown(); assert.equal(code, 0);
  const edits = samples.filter(sample => sample.kind === 'distinct-edit').map(sample => sample.notificationToCheckedMs);
  const receipt = {schema: 'psc1-editor-end-to-end-latency/1', status: 'passed', label, baseline,
    testedCommit: process.env.PSC1_PERF_SERVER_COMMIT || (baseline ? null : process.env.GITHUB_SHA || null),
    measurementHarnessCommit: process.env.GITHUB_SHA || null, measuredServer: server,
    node: process.version, platform: process.platform, architecture: process.arch,
    cpu: os.cpus()[0]?.model, startupMs, debounceMs: server.settings.debounceMs,
    debounceSelection: debounceOverride === null ? 'server-default' : 'explicit-controlled-override',
    compilerMocks: false, everyDistinctSnapshotIndependentlyChecked: true, reusedSamplesDisclosed: true,
    summary: {coldOpenMs: samples[0].notificationToCheckedMs,
      distinctEditMedianMs: round(median(edits)), distinctEditMaxMs: round(Math.max(...edits)),
      unchangedSaveMs: saved.row.notificationToCheckedMs,
      repeatedSnapshotMs: restored.row.notificationToCheckedMs},
    finalMetrics: finalServer.metrics, samples,
    interpretation: 'Wall latency includes scheduling, compiler and independent kernel checking. Three distinct edits are observations, not a statistically stable benchmark. Cached/save samples retain historical compiler phase fields; checksStarted=0 means those phases did not run again.'};
  await fs.mkdir(path.dirname(output), {recursive: true});
  await fs.writeFile(output, JSON.stringify(receipt, null, 2) + '\n');
  console.log('PSC1_EDITOR_LATENCY', JSON.stringify({label, platform: process.platform, summary: receipt.summary,
    checksStarted: finalServer.metrics.checksStarted}));
} catch (error) {
  await fs.mkdir(path.dirname(output), {recursive: true});
  await fs.writeFile(output, JSON.stringify({schema: 'psc1-editor-end-to-end-latency/1', status: 'failed',
    label, baseline, testedCommit: process.env.GITHUB_SHA || null, node: process.version,
    platform: process.platform, startupMs, server, samples, error: String(error?.stack || error)}, null, 2) + '\n');
  throw error;
} finally {
  client?.dispose();
  await fs.rm(temporary, {recursive: true, force: true, maxRetries: 5, retryDelay: 200});
}
