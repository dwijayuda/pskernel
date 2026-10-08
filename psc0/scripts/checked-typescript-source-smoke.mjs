// Runtime integration test for the strictly separated checked-source receipt.
// Requires the already built Lean-native compiler seed and native PSKernel Core.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { existsSync } from 'node:fs';
import { mkdir, readFile, rm } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildChecked, defaultCheckedSeed } from './checked-build.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const outputDir = path.join(root, 'dist/joint-kernel/diagnostics/checked-typescript-only');
const outputPath = path.join(outputDir, 'example.ts');
await rm(outputDir, { recursive: true, force: true });
await mkdir(outputDir, { recursive: true });
try {
  const receipt = await buildChecked({
    entryPath: path.join(root, 'packages/foundation/src/Ps/Foundation/List.lean'),
    seedPath: defaultCheckedSeed,
    kernel: 'pskernel-core',
    emission: 'typescript-only',
    outputPath,
  });
  assert.equal(receipt.kind, 'psc2-checked-typescript');
  assert.equal(receipt.schemaVersion, 3);
  assert.equal(receipt.emission, 'typescript-only');
  assert.equal(receipt.provider.provider, 'pskernel-core-native');
  assert.equal(receipt.compiler.engine, 'native-seed');
  const [typescript, admissions, onDisk] = await Promise.all([
    readFile(outputPath),
    readFile(path.join(outputDir, 'example.admissions.json')),
    readFile(path.join(outputDir, 'example.checked.json'), 'utf8'),
  ]);
  const hash = data => createHash('sha256').update(data).digest('hex');
  assert.equal(receipt.typeScriptSha256, hash(typescript));
  assert.equal(receipt.typeScriptBytes, typescript.length);
  assert.equal(receipt.canonicalAdmissionsSha256, hash(admissions));
  assert.deepEqual(JSON.parse(onDisk), receipt);
  assert.equal(existsSync(path.join(outputDir, 'example.js')), false);
  assert.equal(existsSync(path.join(outputDir, 'example.d.ts')), false);
  assert.equal(existsSync(path.join(outputDir, 'example.js.map')), false);
  assert.equal(Object.hasOwn(receipt, 'javaScriptSha256'), false);
  console.log('PSC0_CHECKED_TYPESCRIPT_ONLY_SMOKE: PASS source=' +
    receipt.sourceCount + ' bytes=' + typescript.length +
    ' executable=false');
} finally {
  await rm(outputDir, { recursive: true, force: true });
}
