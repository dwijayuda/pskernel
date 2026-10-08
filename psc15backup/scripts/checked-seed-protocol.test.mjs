import assert from 'node:assert/strict';
import { Readable } from 'node:stream';
import { test } from 'node:test';
import { checkedSeedFrames, checkedSeedLimits } from './checked-seed-protocol.mjs';

async function read(chunks, limits = {}, maxFrames = 2) {
  const observation = { stdoutBytes: 0, frames: 0, largestFrameBytes: 0 }, values = [];
  for await (const frame of checkedSeedFrames(Readable.from(chunks), checkedSeedLimits(limits), observation, maxFrames)) values.push(frame);
  return { observation, values };
}

test('native protocol framing preserves split UTF-8 and two frames across arbitrary chunks', async () => {
  const bytes = Buffer.from('{"text":"λ"}\r\n{"done":true}');
  const chunks = Array.from(bytes, byte => Buffer.from([byte]));
  const small = await read(chunks, { stdoutBytes: bytes.length, frameBytes: 32 });
  const large = await read([bytes], { stdoutBytes: bytes.length * 2, frameBytes: 64 });
  assert.deepEqual(small, large);
  assert.deepEqual(small.values, [{ text: 'λ' }, { done: true }]);
  assert.equal(small.observation.stdoutBytes, bytes.length);
  assert.equal(small.observation.frames, 2);
});

test('native protocol bounds both unterminated frames and total stdout before decoding', async () => {
  await assert.rejects(read([Buffer.from('12345')], { frameBytes: 4 }), error =>
    error.kind === 'resourceExhausted' && error.resource === 'frameBytes' && error.observed === 5);
  await assert.rejects(read([Buffer.from('{}\n'), Buffer.from('{}\n')], { stdoutBytes: 5 }), error =>
    error.kind === 'resourceExhausted' && error.resource === 'stdoutBytes' && error.observed === 6);
  await assert.rejects(read([Buffer.from('{}\n{}\n{}\n')]), /EXTRA_FRAME/);
  await assert.rejects(read([Buffer.from('{}\n\n')]), /SESSION_JSON/);
  await assert.rejects(read([Buffer.from([0xff, 10])]), /SESSION_JSON/);
  assert.throws(() => checkedSeedLimits({ frameBytes: -1 }), /BUDGET_POLICY/);
  assert.throws(() => checkedSeedLimits({ unknown: 1 }), /BUDGET_POLICY/);
});

test('only the explicit declaration session admits a bounded third response', async () => {
  const frames = Buffer.from('{"phase":"prepared"}\n{"phase":"emitted"}\n{"phase":"declarations"}\n');
  assert.equal((await read([frames], {}, 3)).observation.frames, 3);
  await assert.rejects(read([frames]), /EXTRA_FRAME/);
  await assert.rejects(read([frames, Buffer.from('{}\n')], {}, 3), /EXTRA_FRAME/);
  await assert.rejects(read([frames], {}, 4), /FRAME_POLICY/);
});
