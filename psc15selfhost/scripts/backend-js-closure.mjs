import { readFileSync, readdirSync } from 'node:fs';
import path from 'node:path';
import { packageBySection, parseImports } from './workspace-layout.mjs';

const sourcePackages = new Set(['backend-js', 'compiler-ir', 'bridge']);
const packageNames = new Set(['@proofscript/backend-js-next', '@proofscript/compiler-ir-next',
  '@proofscript/bridge-next', '@proofscript/core', '@proofscript/foundation']);

// This is an architectural guard, not a substitute for the actual source compiler.
export function collectBackendJsClosure(root) {
  const manifests = new Map();
  for (const folder of readdirSync(path.join(root, 'packages'), { withFileTypes: true })) {
    if (!folder.isDirectory()) continue;
    const manifest = JSON.parse(readFileSync(path.join(root, 'packages', folder.name, 'package.json'), 'utf8'));
    if (manifests.has(manifest.name)) throw new Error(`JS_DUPLICATE_PACKAGE: ${manifest.name}`);
    manifests.set(manifest.name, manifest);
  }
  const backend = manifests.get('@proofscript/backend-js-next');
  if (backend?.proofscript?.bootstrap !== false || backend?.proofscript?.portable !== true) {
    throw new Error('JS_BOOTSTRAP_ISOLATION');
  }
  const checkedPackages = new Set();
  function checkPackage(name) {
    if (!packageNames.has(name)) throw new Error(`JS_PACKAGE_DEPENDENCY: ${name}`);
    if (checkedPackages.has(name)) return;
    checkedPackages.add(name);
    const manifest = manifests.get(name);
    if (!manifest || manifest.proofscript?.portable === false) throw new Error(`JS_PACKAGE_DEPENDENCY: ${name}`);
    for (const field of ['dependencies', 'optionalDependencies', 'peerDependencies', 'devDependencies']) {
      for (const dependency of Object.keys(manifest[field] ?? {})) checkPackage(dependency);
    }
  }
  checkPackage('@proofscript/backend-js-next');
  const visiting = new Set();
  const visited = new Set();
  const ordered = [];
  function visit(name) {
    if (visiting.has(name)) throw new Error(`JS_SOURCE_CYCLE: ${name}`);
    if (visited.has(name)) return;
    const parts = name.split('.');
    const folder = parts[0] === 'Ps' ? packageBySection.get(parts[1]) : undefined;
    if (!sourcePackages.has(folder)) throw new Error(`JS_SOURCE_DEPENDENCY: ${name}`);
    const file = path.join(root, 'packages', folder, 'src', ...parts) + '.lean';
    const source = readFileSync(file, 'utf8');
    visiting.add(name);
    for (const imported of parseImports(source)) visit(imported);
    visiting.delete(name);
    visited.add(name);
    ordered.push({ file, source });
  }
  visit('Ps.BackendJs.Module');
  return ordered;
}
