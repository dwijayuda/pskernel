import assert from 'node:assert/strict';
import { test } from 'node:test';
import { runBoundedProcess } from './bounded-process.mjs';

const run = (source, options = {}) => runBoundedProcess({ binary: process.execPath,
  args: ['--input-type=module', '-e', source], cwd: process.cwd(), env: {}, ...options });

test('bounded execution returns data without semantic authority', async () => {
  const result = await run('process.stdin.pipe(process.stdout)', { input: Buffer.from('bounded') });
  assert.equal(result.kind, 'accepted'); assert.equal(result.authority, 'none');
  assert.equal(result.value.stdout.toString(), 'bounded');
  assert.equal(result.observation.peakMemory, null);
  const failed = await run('process.exit(7)');
  assert.equal(failed.kind, 'internalError'); assert.equal(failed.process.code, 7);
});

test('output, input and wall budgets preserve resource classification', async () => {
  const excessive = await run('process.stdout.write("x".repeat(100000))', { limits: { stdoutBytes: 16 } });
  assert.equal(excessive.kind, 'resourceExhausted'); assert.equal(excessive.resource, 'stdoutBytes');
  const input = await run('process.exit(0)', { input: Buffer.from('input'), limits: { inputBytes: 1 } });
  assert.equal(input.kind, 'resourceExhausted'); assert.equal(input.resource, 'inputBytes');
  const timeout = await run('setInterval(() => {}, 1000)', { limits: { wallTimeMs: 100 } });
  assert.equal(timeout.kind, 'resourceExhausted'); assert.equal(timeout.resource, 'wallTime');
  const controller = new AbortController(); controller.abort();
  const cancelled = await run('process.exit(0)', { signal: controller.signal });
  assert.equal(cancelled.kind, 'resourceExhausted'); assert.equal(cancelled.resource, 'cancelled');
});
