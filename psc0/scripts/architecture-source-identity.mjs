// Cheap inheritance guard, NOT a new self-host fixed point. Host-only work is
// accepted only while the actual qualified compiler source remains identical.
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { allowedBootstrapPackageNames } from './bootstrap-closure-contract.mjs';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const git = args => execFileSync('git', args, { cwd: root, encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 });
const qualified = '1fa5559a72b293defc56ef7e7020cf82d4b44b79';
const baseline = '58234f52f15f961f599799e2e93ec1f1f0f86962';
const runtimeSource = '2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a';
const code = allowedBootstrapPackageNames.map(n => 'psc0/packages/' + n + '/src');
const pins = ['psc0/psconfig.json', 'psc0/selfhost-seed.json', 'psc0/selfhost-seed-recovery.json', 'psc0/lean-toolchain', 'psc0/scripts/typescript-cli.mjs', 'psc0/scripts/bootstrap-closure-contract.mjs'];
const untouchedKernel = ['psc0/packages/pskernel-core', 'psc0/npm-runtime'];
function inventory(revision, paths) { return git(['ls-tree', '-r', '--full-tree', revision, '--', ...paths]).trim().split('\n').filter(Boolean).sort(); }
const current = inventory('HEAD', code);
assert(current.length > 0, 'No compiler source inventory');
assert.deepEqual(current, inventory(qualified, code), 'PSC_SELFHOST_SOURCE_CHANGED: cannot inherit strict qualification');
assert.deepEqual(current, inventory(runtimeSource, code), 'PSC_REUSED_COMPILER_SOURCE_MISMATCH');
assert.deepEqual(inventory('HEAD', pins), inventory(baseline, pins), 'PSC_SELFHOST_PIN_CHANGED');
assert.deepEqual(inventory('HEAD', untouchedKernel), inventory(baseline, untouchedKernel), 'PSC_KERNEL_WORKSTREAM_MODIFIED');
git(['diff', '--exit-code', 'HEAD', '--', ...code, ...pins, ...untouchedKernel]);
const config = JSON.parse(readFileSync(path.join(root, 'psconfig.json'), 'utf8'));
assert.equal(config.sourceGrammar.edition, 'ps-0.9-r3');
assert.equal(config.sourceGrammar.mode, 'new-only');
assert.equal(JSON.parse(readFileSync(path.join(root, 'package.json'), 'utf8')).devDependencies.typescript, '7.0.2');
const section = Object.fromEntries(allowedBootstrapPackageNames.map(n => [n.split('-').map(s => s[0].toUpperCase() + s.slice(1)).join(''), n]));
const seen = new Set(), active = new Set();
function visit(relative) {
  if (active.has(relative)) throw new Error('PSC_SELFHOST_IMPORT_CYCLE: ' + relative);
  if (seen.has(relative)) return;
  const text = readFileSync(path.join(root, relative), 'utf8');
  active.add(relative);
  for (const line of text.split(/\r?\n/u)) {
    const match = line.match(/^\s*import\s+([A-Za-z_][A-Za-z_0-9.]*)\s*$/u);
    if (!match) continue;
    const parts = match[1].split('.'), pkg = section[parts[1]];
    if (parts[0] !== 'Ps' || !pkg) throw new Error('PSC_SELFHOST_CLOSURE_ESCAPES_COMPILER: ' + match[1]);
    visit('packages/' + pkg + '/src/' + parts.join('/') + '.lean');
  }
  active.delete(relative); seen.add(relative);
}
visit('packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean');
const report = { schema: 'psc0-host-change-selfhost-preservation/1', source: git(['rev-parse', 'HEAD']).trim(), qualifiedCompilerSource: qualified, reusedRuntimeSource: runtimeSource, grammar: 'ps-0.9-r3/new-only', sourceFiles: current.length, closureModules: seen.size, sourceInventorySha256: createHash('sha256').update(current.join('\n')).digest('hex'), compilerSourceUnchanged: true, compilerQualificationInherited: true, kernelSourceUnchanged: true, expensiveFixedPointExecuted: false, newInstalledFixedPointClaimed: false };
mkdirSync(path.join(root, 'dist/architecture-evidence'), { recursive: true });
writeFileSync(path.join(root, 'dist/architecture-evidence/source-preservation.json'), JSON.stringify(report, null, 2) + '\n');
console.log('PSC_SELFHOST_SOURCE_PRESERVATION: PASS ' + JSON.stringify(report));
