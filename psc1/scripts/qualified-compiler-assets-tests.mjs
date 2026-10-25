// Actual qualified G1 evidence must remain insufficient for G3 promotion.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { readQualifiedCompilerAssets } from './qualified-compiler-assets.mjs';
const source = JSON.parse(fs.readFileSync('scripts/generated-io-g1-inputs.json'));
const input = { schema: 'psc1-qualified-compiler-generation-inputs/1',
  sourceClosureDigest: source.compilerSourceClosureDigest,
  engines: Object.fromEntries(Object.entries(source.engines).map(([engine, row]) => [engine,
    { ...row, manifestSha256: '0'.repeat(64), executableSha256: '0'.repeat(64) }])) };
await assert.rejects(readQualifiedCompilerAssets(input,
  path.resolve('dist/insufficient-g1-promotion'), '0.1.0-psc1.5'), /js:mode/);
console.log('PSC1_COMPILER_PROMOTION_REFUSAL: PASS actual G1 cannot be labeled G3');
