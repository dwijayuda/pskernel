// Validate authoring workspaces and publishable/staged packages as distinct
// schemas. A publishable npm package still MUST have its real source tree.
import { access, readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { allowedBootstrapPackageNames, forbiddenBootstrapPackages } from './bootstrap-closure-contract.mjs';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const json = async p => JSON.parse(await readFile(p, 'utf8'));
const need = async p => { try { await access(p); } catch { throw new Error('PSC_WORKSPACE_PATH_MISSING: ' + p); } };
const ordinary = new Set([...allowedBootstrapPackageNames, 'backend-js', 'backend-rust', 'backend-wasm', 'cli', 'pskernel-core']);
const providers = new Set(['pskernel-lean', 'pskernel-lean-wasm']);
const manifest = await json(path.join(root, 'package.json'));
for (const name of ['packages/*', 'host', 'stdlib']) if (!manifest.workspaces?.includes(name)) throw new Error('PSC1_WORKSPACE_ROOT_MISSING: ' + name);
const paths = ['host', 'stdlib', ...(await readdir(path.join(root, 'packages'), { withFileTypes: true })).filter(x => x.isDirectory()).map(x => 'packages/' + x.name)];
const identities = new Set();
for (const relative of paths) {
  const directory = path.join(root, relative), pkg = await json(path.join(directory, 'package.json'));
  if (identities.has(pkg.name)) throw new Error('PSC_NPM_DUPLICATE_WORKSPACE_NAME: ' + pkg.name);
  identities.add(pkg.name);
  const config = pkg.proofscript;
  if (!config) throw new Error('PSC1_WORKSPACE_PROOFSCRIPT_METADATA: ' + pkg.name);
  if (relative === 'packages/proofscript') {
    if (pkg.name !== 'proofscript' || pkg.private !== false || pkg.bin?.psc !== './bin/psc.js') throw new Error('PSC_NPM_WORKSPACE_ROOT_CLI');
    const required = new Set([...allowedBootstrapPackageNames.map(n => '@proofscript/' + n), '@proofscript/pskernel-core']);
    const bundled = pkg.bundledDependencies;
    if (!Array.isArray(bundled) || bundled.length !== required.size || bundled.some(n => !required.has(n)) || new Set(bundled).size !== required.size) throw new Error('PSC_NPM_CORE_BUNDLE_SCOPE');
    if (Object.keys(pkg.dependencies).sort().join() !== [...required, 'typescript'].sort().join() || pkg.dependencies.typescript !== '7.0.2') throw new Error('PSC_NPM_CORE_DEPENDENCIES');
    await need(path.join(root, 'npm-cli/psc.js')); continue;
  }
  if (relative === 'packages/stdlib') {
    if (pkg.name !== '@proofscript/stdlib' || pkg.private !== false || config.library?.modulePrefix !== 'ProofScript' || config.library?.sourceRoot !== 'src') throw new Error('PSC_NPM_WORKSPACE_STDLIB_SOURCE');
    await need(path.join(root, 'stdlib/ProofScript')); continue;
  }
  if (relative.startsWith('packages/')) {
    const name = path.basename(relative);
    if (pkg.name !== '@proofscript/' + name || pkg.private !== false || pkg.publishConfig?.access !== 'public' || config.npmArchitecture !== 'psc0-monolithic-runtime-with-scoped-source-packages/1') throw new Error('PSC_NPM_PUBLISHABLE_SCHEMA: ' + name);
    if (ordinary.has(name)) {
      await need(path.join(directory, 'src'));
      const entries = await readdir(path.join(directory, 'src'));
      if (!entries.length) throw new Error('PSC_NPM_EMPTY_SOURCE_ROOT: ' + name);
    } else if (providers.has(name) && forbiddenBootstrapPackages.has(name)) {
      await need(path.join(directory, 'index.mjs')); await need(path.join(directory, 'host'));
    } else throw new Error('PSC_NPM_UNKNOWN_PACKAGE_ROLE: ' + name);
    if (!pkg.exports || !Array.isArray(pkg.files)) throw new Error('PSC_NPM_PACKAGE_EXPORTS: ' + name);
    continue;
  }
  // Preserve original authoring contracts rather than exempting all directories.
  if (relative === 'stdlib' && (pkg.name !== '@proofscript/stdlib-authoring' || pkg.private !== true)) throw new Error('PSC_NPM_STDLIB_AUTHORING_IDENTITY');
  if (!Array.isArray(config.sourceRoots) || !config.sourceRoots.length) throw new Error('PSC1_WORKSPACE_SOURCE_ROOTS: ' + pkg.name);
  if (!Array.isArray(config.testRoots) || !config.testRoots.length || config.outDir !== 'dist') throw new Error('PSC1_WORKSPACE_AUTHORING_METADATA: ' + pkg.name);
  for (const source of config.sourceRoots) await need(path.resolve(directory, source));
}
const project = await json(path.join(root, 'psconfig.json'));
await need(path.join(root, project.entry));
await need(path.join(root, manifest.bin.psc));
console.log('PSC1_WORKSPACE_SHAPE: PASS (' + paths.length + ' workspaces; explicit authoring/publishing schemas)');
