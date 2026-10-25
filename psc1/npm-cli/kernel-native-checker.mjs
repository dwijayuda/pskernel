#!/usr/bin/env node
// Explicit optional native comparison; the default wrapper remains Wasm.
process.argv.push('--provider','native');
await import('./kernel-checker.mjs');
