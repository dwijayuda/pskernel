import assert from 'node:assert/strict';
import { test } from 'node:test';
import { execFileSync } from 'node:child_process';
import { decodePublicApi } from './public-api-artifact.mjs';
import { decodeIrArtifact } from './ir-artifact.mjs';

test('actual compiler retains source-generic API even when closed specialization omits its export', () => {
  const command = process.platform === 'win32' ? '.lake/build/bin/pscv_ir_encoding_tests.exe' : '.lake/build/bin/pscv_ir_encoding_tests';
  const output = JSON.parse(execFileSync(command, ['--public-api'], { encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 }));
  const api = decodePublicApi(Buffer.from(output.publicApi)), specialized = decodeIrArtifact(Buffer.from(output.specializedIr));
  const forward = api[2].find(item => item[0] === 'constant' && item[2].v === 'forward');
  assert.ok(forward);
  assert.equal(forward[4].k, 'forall');
  assert.equal(forward[4].n.v, 'A');
  assert.equal(forward[4].b.k, 'forall');
  assert.equal(specialized[4].some(item => item[0] === 'forward'), false);
});
