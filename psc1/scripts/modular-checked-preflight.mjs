// Exercise the real loader's filesystem preconditions before any build/download.
// A wrong hash must refuse before parsing this ordinary package.json as a graph.
import path from 'node:path';
import assert from 'node:assert/strict';
import { loadExecutableCompiler } from '../host-tools/executable/loader.mjs';

await assert.rejects(
  () => loadExecutableCompiler({
    root: path.resolve('host-tools'),
    manifestFile: path.resolve('host-tools/package.json'),
    manifestSha256: '0'.repeat(64),
    variant: 'js',
  }),
  /PSC1_EXECUTABLE_MANIFEST_HASH/,
);
console.log('PSC1_MODULAR_LOADER_PREFLIGHT PASS');
