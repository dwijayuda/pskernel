import assert from 'node:assert/strict';
import { test } from 'node:test';
import { execFileSync } from 'node:child_process';
import { decodeErasureDeclarations } from './erasure-declarations.mjs';

test('actual erasure observation preserves IR and distinguishes generic functions, proofs and generated declarations', () => {
  const command = process.platform === 'win32' ? '.lake/build/bin/pscv_ir_encoding_tests.exe' : '.lake/build/bin/pscv_ir_encoding_tests';
  const output = JSON.parse(execFileSync(command, ['--erasure-declarations'], { encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 }));
  const table = decodeErasureDeclarations(Buffer.from(output.erasureCorrespondence),
    { publicApi: Buffer.from(output.publicApi), runtimeIr: Buffer.from(output.runtimeIr) });
  const entries = table[2];
  assert.deepEqual(entries.find(item => item[0].v === 'forward')?.[1], ['runtime', 'forward']);
  assert.deepEqual(entries.find(item => item[0].v === 'proofId')?.[1], ['proof-erased']);
  assert.deepEqual(entries.find(item => item[0].v === 'Box')?.[1], ['no-runtime-declaration']);
  assert.deepEqual(entries.find(item => item[0].v === 'answer')?.[1], ['runtime', 'answer']);
});
