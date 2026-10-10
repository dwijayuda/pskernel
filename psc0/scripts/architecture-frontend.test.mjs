import assert from 'node:assert/strict';
import { test } from 'node:test';
import { PassThrough } from 'node:stream';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';
import path from 'node:path';
import os from 'node:os';
import { FRONTEND_PROTOCOL, receiveFrames } from '../npm-cli/frontend-wire.mjs';
import { createFrontendTransport, frontendLimits } from '../npm-cli/frontend-transport.mjs';
const fixture = `
import { createInterface } from 'node:readline';
const send = f => process.stdout.write(JSON.stringify(f) + '\\n');
for await (const line of createInterface({ input: process.stdin })) {
  const f = JSON.parse(line);
  const response = value => send({ protocol:f.protocol, id:f.id, kind:'result', value });
  if (f.op === 'ready') response({ pid:process.pid, injected:process.env.NODE_OPTIONS || null });
  else if (f.op === 'loop') { while (true) {} }
  else if (f.op === 'exit') process.exit(7);
  else if (f.op === 'invalid') process.stdout.write('not JSON\\n');
  else if (f.op === 'partial') { process.stdout.write('{'); process.exit(0); }
  else if (f.op === 'oversize') process.stdout.write('x'.repeat(2048));
  else if (f.op === 'stderr') process.stderr.write('x'.repeat(2048));
  else if (f.op === 'wrong-id') send({ protocol:f.protocol, id:f.id+1, kind:'result', value:true });
  else if (f.op === 'wrong-version') send({ protocol:'not-psc', id:f.id, kind:'result', value:true });
  else if (f.op === 'unexpected-kernel') send({ protocol:f.protocol, id:f.id, kind:'admissions', value:'[]' });
  else if (f.op === 'duplicate') { response(true); response(true); }
  else if (f.op === 'delay') setTimeout(() => response(true), 30);
  else if (f.op === 'check') {
    if (f.data.unchecked) response(true);
    else {
      send({ protocol:f.protocol, id:f.id, kind:'admissions', value:'[]' });
      if (f.data.early) response(true);
    }
  } else if (f.op === 'kernel-result') response(f.data);
  else if (f.op === 'refuse') send({ protocol:f.protocol, id:f.id, kind:'error', message:'fixture refusal' });
}
`;
async function peer(t, options = {}) {
  const dir = await mkdtemp(path.join(os.tmpdir(), 'psc-peer-'));
  const script = path.join(dir, 'peer.mjs');
  await writeFile(script, fixture);
  const transport = createFrontendTransport({ script: pathToFileURL(script), limits: { timeoutMs: 10000, heapMb: 128 }, ...options });
  t.after(async () => { await transport.close(); await rm(dir, { recursive: true, force: true }); });
  return transport;
}
function assertGone(pid) {
  assert.throws(() => process.kill(pid, 0), error => error.code === 'ESRCH');
}
test('owned frontend runs in a distinct process and reaps before completion', async t => {
  const p = await peer(t);
  const ready = await p.request('ready');
  assert.equal(ready.pid, p.stats().childPid);
  assert.notEqual(ready.pid, process.pid);
  await p.close(); assertGone(ready.pid);
});
test('frontend launcher does not inherit Node preload or heap override options', async t => {
  const original = process.env.NODE_OPTIONS;
  process.env.NODE_OPTIONS = '--require=psc-nonexistent-preload';
  let p;
  try { p = await peer(t); }
  finally { if (original === undefined) delete process.env.NODE_OPTIONS; else process.env.NODE_OPTIONS = original; }
  assert.equal((await p.request('ready')).injected, null);
});
test('independent timer interrupts CPU-bound JS and permanently declines the session', async t => {
  const p = await peer(t, { limits: { timeoutMs: 1500, heapMb: 128 } });
  const ready = await p.request('ready');
  const pending = p.request('loop');
  await assert.rejects(pending, /TIME_LIMIT/);
  await assert.rejects(p.request('ready'), /TIME_LIMIT/);
  await p.close(); assertGone(ready.pid);
});
test('cancellation interrupts an owned busy process with no restart', async t => {
  const controller = new AbortController();
  const p = await peer(t, { signal: controller.signal });
  await p.request('ready');
  const pending = p.request('loop');
  controller.abort();
  await assert.rejects(pending, /CANCELLED/);
  await p.close(); assertGone(p.stats().childPid);
});
for (const [op, error] of [
  ['exit', /EXIT/], ['invalid', /JSON/], ['partial', /TRUNCATED|EXIT/],
  ['wrong-id', /IDENTITY/], ['wrong-version', /IDENTITY/],
  ['unexpected-kernel', /ADMISSION_PROTOCOL/], ['refuse', /DECLINED/],
]) test('frontend refuses ' + op + ' without accepting a later request', async t => {
  const p = await peer(t);
  await assert.rejects(p.request(op), error);
  await assert.rejects(p.request('ready'));
});
test('unterminated oversized responses fail before JSON allocation', async t => {
  const p = await peer(t, { maxFrameBytes: 256 });
  await assert.rejects(p.request('oversize'), /FRAME_LIMIT/);
});
test('diagnostics have an independent cumulative byte budget', async t => {
  const p = await peer(t, { maxDiagnosticsBytes: 256 });
  await assert.rejects(p.request('stderr'), /DIAGNOSTIC_LIMIT/);
});
test('concurrent requests are not interleaved', async t => {
  const p = await peer(t);
  const pending = p.request('delay');
  await assert.rejects(p.request('ready'), /CONCURRENT/);
  assert.equal(await pending, true);
});
test('a duplicate result permanently invalidates the live channel', async t => {
  const p = await peer(t);
  await p.request('duplicate');
  // A second request cannot be accepted as an answer to the duplicated result.
  await assert.rejects(p.request('ready'), /IDENTITY/);
});
test('checking must call the parent kernel exactly once before returning', async t => {
  let calls = 0;
  const p = await peer(t, { onAdmissions: text => { assert.equal(text, '[]'); calls++; return { accepted: true }; } });
  assert.deepEqual(await p.request('check'), { accepted: true });
  assert.equal(calls, 1);
});
test('an unchecked result cannot bypass the parent kernel', async t => {
  const p = await peer(t, { onAdmissions: () => assert.fail('kernel must not be fabricated') });
  await assert.rejects(p.request('check', { unchecked: true }), /UNCHECKED_RESULT/);
});
test('a result arriving before the parent kernel decision is rejected', async t => {
  const p = await peer(t, { onAdmissions: () => new Promise(resolve => setTimeout(() => resolve({ accepted: true }), 50)) });
  await assert.rejects(p.request('check', { early: true }), /RESPONSE_ORDER/);
});
test('wire preserves split UTF-8 and rejects empty/primitive frames', () => {
  const stream = new PassThrough(), received = [], failures = [];
  receiveFrames(stream, x => received.push(x), e => failures.push(e));
  const encoded = Buffer.from(JSON.stringify({ name: 'λ' }) + '\n');
  for (const byte of encoded) stream.write(Buffer.from([byte]));
  assert.deepEqual(received, [{ name: 'λ' }]);
  stream.write(Buffer.from('true\n')); stream.end();
  assert.equal(failures.length, 1);
  assert.match(failures[0].message, /FRAME_SHAPE/);
  const empty = new PassThrough();
  receiveFrames(empty, () => assert.fail('empty frame'), error => assert.match(error.message, /EMPTY_FRAME/));
  empty.end(Buffer.from('\n'));
});
test('resource settings require explicit finite host-owned values', () => {
  for (const values of [{ timeoutMs: Infinity }, { timeoutMs: 0 }, { heapMb: 1 }, { heapMb: '4096' }, { pluginBudget: 99 }]) assert.throws(() => frontendLimits(values), /LIMIT/);
  assert.equal(frontendLimits({ timeoutMs: 3600000 }).timeoutMs, 3600000);
  assert.equal(frontendLimits().heapMb, 4096);
});
