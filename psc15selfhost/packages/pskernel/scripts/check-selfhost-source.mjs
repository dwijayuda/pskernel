#!/usr/bin/env node
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const packageRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const entry = path.join(packageRoot, 'PSC1KernelSelfHost.lean');
const visited = new Set();
const ordered = [];
const failures = [];
let partialDefinitions = 0;
const partialDefinitionBaseline = 128;

function modulePath(name) {
  if (name === 'PSC1KernelSelfHost') return entry;
  if (!name.startsWith('PSC1Kernel.')) return null;
  return path.join(packageRoot, ...name.split('.')) + '.lean';
}

async function visit(file) {
  const full = path.resolve(file);
  if (visited.has(full)) return;
  visited.add(full);

  const source = await readFile(full, 'utf8');
  ordered.push(path.relative(packageRoot, full).split(path.sep).join('/'));

  partialDefinitions += source.match(/\bpartial\s+def\b/gu)?.length ?? 0;

  const forbidden = [
    [/^\s*import\s+Std\./mu, 'Std import'],
    [/^\s*import\s+Lean\./mu, 'Lean frontend/runtime import'],
    [/^\s*import\s+PSC1Kernel\.(?:Replay|ReplayJson|NativeMap|Test)(?:\.|\s|$)/mu,
      'non-semantic kernel adapter import'],
    [/\bunsafe\s+(?:def|theorem|opaque)\b/gu, 'unsafe declaration'],
    [/@\[\s*implemented_by/gu, 'implemented_by escape'],
    [/\bextern\b/gu, 'extern declaration'],
  ];
  for (const [pattern, label] of forbidden) {
    if (pattern.test(source)) {
      failures.push(`${path.relative(packageRoot, full)}: ${label}`);
    }
  }

  for (const match of source.matchAll(/^\s*import\s+([A-Za-z0-9_.]+)\s*$/gmu)) {
    const moduleName = match[1];
    const local = modulePath(moduleName);
    if (local) {
      await visit(local);
    } else if (!moduleName.startsWith('Init.')) {
      failures.push(
        `${path.relative(packageRoot, full)}: unsupported external import ${moduleName}`,
      );
    }
  }
}

await visit(entry);

if (failures.length) {
  throw new Error('PSC1KERNEL_SELFHOST_SOURCE_REJECTED\n' + failures.join('\n'));
}

console.log('PSC1KERNEL_SELFHOST_SOURCE: PASS');
console.log(`modules=${ordered.length}`);
console.log(`partialDefinitions=${partialDefinitions}`);
console.log(`partialDefinitionBaseline=${partialDefinitionBaseline}`);
console.log(
  'note=partial definitions remain migration debt; this gate forbids host/runtime trust escapes',
);
