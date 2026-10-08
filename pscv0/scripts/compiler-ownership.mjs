import { maskLeanSource } from './lean-source-mask.mjs';
const fail = (code, detail) => { throw new Error('PSC_OWNERSHIP_' + code + ': ' + detail); };

export function leanCode(source) {
  return maskLeanSource(source, { strict: true });
}

export function auditCompilerOwnership({ policy, packages, backendRegistry, primaryBootstrapEntry }) {
  if (policy.contract !== 'psc-compiler-ownership/1' || policy.schemaVersion !== 1) fail('POLICY', 'schema');
  const declared = new Map(), byName = new Map(), actual = new Map(), modules = new Map(), edges = new Map();
  for (const entry of policy.packages) {
    if (!['semantic', 'backend', 'driver', 'composition', 'host-cli', 'interop', 'incremental', 'assurance'].includes(entry.role)) fail('ROLE', entry.folder);
    if (declared.has(entry.folder) || byName.has(entry.name)) fail('IDENTITY', entry.folder);
    declared.set(entry.folder, entry); byName.set(entry.name, entry);
  }
  for (const entry of policy.externalPackages) {
    if (byName.has(entry.name)) fail('IDENTITY', entry.name);
    byName.set(entry.name, { ...entry, role: 'external' });
  }
  for (const item of packages) {
    const entry = declared.get(item.folder);
    if (!entry || actual.has(item.folder) || item.manifest.name !== entry.name) fail('IDENTITY', item.folder);
    actual.set(item.folder, item); edges.set(item.folder, new Set());
    for (const module of item.modules) {
      if (!module.path.startsWith('packages/' + item.folder + '/src/') || !module.path.endsWith('.lean')) fail('SOURCE_PATH', module.path);
      const name = module.path.split('/src/')[1].slice(0, -5).replaceAll('/', '.');
      if (modules.has(name)) fail('DUPLICATE_MODULE', name);
      modules.set(name, { ...module, folder: item.folder });
    }
  }
  if (actual.size !== declared.size) fail('PACKAGE_SET', 'missing package');
  function checkEdge(from, to) {
    const owner = declared.get(from);
    if (to.role === 'external' && !to.allowedConsumers.includes(from)) fail('EXTERNAL_DEPENDENCY', from + ' -> ' + to.folder);
    if (owner.role === 'semantic' && !['semantic'].includes(to.role)) fail('SEMANTIC_DEPENDENCY', from + ' -> ' + to.folder);
    if (['interop', 'incremental'].includes(owner.role) && !['semantic', 'interop', 'incremental'].includes(to.role)) fail('COMPANION_DEPENDENCY', from + ' -> ' + to.folder);
    if (owner.role === 'backend' && !['semantic', 'interop'].includes(to.role)) fail('BACKEND_DEPENDENCY', from + ' -> ' + to.folder);
    if (owner.role === 'backend' && !['compiler-ir', 'foundation', 'bridge', 'interface-ir'].includes(to.folder)) fail('BACKEND_FRONTEND_DEPENDENCY', from + ' -> ' + to.folder);
    if (owner.role === 'driver' && !(['compiler', 'compiler-ir', 'foundation', 'interface-ir'].includes(to.folder) ||
        to.folder === from.replace('driver-', 'backend-') ||
        (from === 'driver-js' && to.folder === 'interface-ts'))) fail('DRIVER_DEPENDENCY', from + ' -> ' + to.folder);
    if (to.role !== 'external') edges.get(from).add(to.folder);
  }
  for (const item of packages) {
    const dependencies = item.manifest.dependencies ?? {};
    for (const name of Object.keys(dependencies)) {
      const target = byName.get(name);
      if (!target) fail('UNDECLARED_PACKAGE', item.folder + ' -> ' + name);
      checkEdge(item.folder, target);
      if (target.role !== 'external' && dependencies[name] !== actual.get(target.folder).manifest.version)
        fail('PACKAGE_VERSION', item.folder + ' -> ' + name);
    }
    const scoped = item.manifest.proofscript.entryDependencies ?? {};
    for (const [entryPath, entryDependencies] of Object.entries(scoped)) {
      const permitted = policy.bootstrapEntryDependencies[entryPath];
      if (item.folder !== 'bootstrap' || !permitted ||
          'packages/bootstrap/' + entryPath === primaryBootstrapEntry ||
          Object.keys(entryDependencies).join(',') !== declared.get(permitted).name ||
          entryDependencies[declared.get(permitted).name] !== actual.get(permitted).manifest.version)
        fail('ENTRY_DEPENDENCIES', item.folder + '/' + entryPath);
      if (!item.modules.some(module => module.path === 'packages/bootstrap/' + entryPath)) fail('ENTRY_MISSING', entryPath);
      checkEdge(item.folder, declared.get(permitted));
    }
    for (const module of item.modules) {
      const code = leanCode(module.source);
      if (policy.neutralRuntimeFiles.includes(module.path) && /\bPs(?:Js|Wasm|Rust|Ts)[A-Z]|\bPs\.Backend/u.test(code))
        fail('TARGET_LEAK', module.path);
      if (declared.get(item.folder).role === 'driver' &&
          (/\bPs(?:Js|Wasm)(?:Expr|Stmt|Instruction|Function|Module)\./u.test(code) ||
           /^\s*def\s+ps(?:Js|Wasm|Rust|Ts)(?:Lower|Emit|Encode)/mu.test(code)))
        fail('DRIVER_LOWERING', module.path);
      for (const match of code.matchAll(/^\s*import[ \t]+([^\n]+)/gmu)) {
        for (const name of match[1].trim().split(/\s+/u)) {
          const imported = modules.get(name);
          const target = imported ? declared.get(imported.folder) :
            policy.externalPackages.find(entry => name.startsWith(entry.modulePrefix));
          if (!target) fail('UNRESOLVED_IMPORT', module.path + ' -> ' + name);
          if (imported?.folder === item.folder) continue;
          const resolved = byName.get(target.name);
          checkEdge(item.folder, resolved);
          const entryPath = module.path.slice(('packages/' + item.folder + '/').length);
          if (!Object.hasOwn(dependencies, target.name) && !Object.hasOwn(scoped[entryPath] ?? {}, target.name))
            fail('MISSING_DEPENDENCY', module.path + ' -> ' + target.name);
        }
      }
    }
  }
  const visiting = new Set(), complete = new Set();
  function visit(folder) {
    if (visiting.has(folder)) fail('DEPENDENCY_CYCLE', folder);
    if (complete.has(folder)) return;
    visiting.add(folder); for (const target of edges.get(folder)) visit(target);
    visiting.delete(folder); complete.add(folder);
  }
  for (const folder of declared.keys()) visit(folder);
  const backendFolders = policy.packages.filter(item => item.role === 'backend').map(item => 'packages/' + item.folder).sort();
  if (JSON.stringify(backendFolders) !== JSON.stringify(backendRegistry.backends.map(item => item.packagePath).sort())) fail('BACKEND_REGISTRATION', 'exact backend ownership');
  for (const backend of backendRegistry.backends) {
    const folder = backend.packagePath.slice('packages/'.length), owner = actual.get(folder);
    if (owner.manifest.version !== backendRegistry.backendVersion) fail('BACKEND_VERSION', folder);
    if (!owner.modules.some(module => new RegExp('^def[ \\t]+' + backend.emitterId + '(?:[ \\t\\r\\n]|$)', 'm').test(leanCode(module.source))))
      fail('EMITTER_OWNER', backend.emitterId);
  }
  return { packages: actual.size, modules: modules.size, dependencyEdges: [...edges.values()].reduce((sum, values) => sum + values.size, 0),
    authority: 'static-ownership-audit-only' };
}
