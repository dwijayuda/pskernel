import assert from 'node:assert/strict';
import { test } from 'node:test';
import { auditCompilerOwnership, leanCode } from './compiler-ownership.mjs';
function fixture() {
  const entries = [
    { folder: 'foundation', name: '@fixture/foundation', role: 'semantic' },
    { folder: 'compiler-ir', name: '@fixture/ir', role: 'semantic' },
    { folder: 'backend-js', name: '@fixture/js', role: 'backend' },
    { folder: 'driver-js', name: '@fixture/driver', role: 'driver' },
  ];
  const dependencies = [{}, { '@fixture/foundation': '1' }, { '@fixture/ir': '1' }, { '@fixture/js': '1' }];
  const sources = ['def foundationValue : Nat := 1',
    'import Ps.Foundation\ndef irValue : Nat := foundationValue',
    'import Ps.Ir\ndef emitJs : Nat := irValue',
    'import Ps.Js\ndef compileJs : Nat := emitJs'];
  const modules = ['Ps/Foundation', 'Ps/Ir', 'Ps/Js', 'Ps/Driver'];
  return { policy: { schemaVersion: 1, contract: 'psc-compiler-ownership/1', packages: entries,
    externalPackages: [], bootstrapEntryDependencies: {}, neutralRuntimeFiles: ['packages/compiler-ir/src/Ps/Ir.lean'] },
    packages: entries.map((entry, index) => ({ folder: entry.folder,
      manifest: { name: entry.name, version: '1', dependencies: dependencies[index], proofscript: {} },
      modules: [{ path: 'packages/' + entry.folder + '/src/' + modules[index] + '.lean', source: sources[index] }] })),
    backendRegistry: { backendVersion: '1', backends: [{ packagePath: 'packages/backend-js', emitterId: 'emitJs' }] },
    primaryBootstrapEntry: 'unused' };
}
test('static ownership follows actual imports and filters comments and strings', () => {
  const f = fixture();
  f.packages[0].modules[0].source += '\n/- outer /- import Missing.Nested -/ end -/\n-- import Missing.Line\ndef s : String := "import Missing.String"';
  assert.equal(auditCompilerOwnership(f).modules, 4);
  assert.equal(leanCode('"x"\nimport X').trim(), 'import X');
  assert.throws(() => leanCode('/- unfinished'), /LEXICAL/);
});
test('semantic/backend isolation, stale identities and missing declarations fail closed', () => {
  const mutations = [
    f => { f.packages[1].manifest.dependencies['@fixture/js'] = '1'; },
    f => { f.packages[2].manifest.dependencies['@fixture/driver'] = '1'; },
    f => { f.packages[2].manifest.dependencies = {}; },
    f => { f.packages[0].manifest.name = '@fixture/stale'; },
    f => { f.packages[2].manifest.dependencies['@fixture/nonexistent'] = '1'; },
    f => { f.packages[2].modules[0].source = 'import Missing.Module'; },
  ];
  for (const mutate of mutations) { const f = fixture(); mutate(f); assert.throws(() => auditCompilerOwnership(f), /PSC_OWNERSHIP_/); }
});
test('cycles, target leakage, lowering in drivers and unregistered emitters reject', () => {
  const mutations = [
    f => { f.packages[0].manifest.dependencies['@fixture/ir'] = '1'; },
    f => { f.packages[1].modules[0].source += '\ndef x := PsJsExpr.literal'; },
    f => { f.packages[3].modules[0].source += '\ndef x := PsWasmModule.mk'; },
    f => { f.backendRegistry.backends[0].emitterId = 'missingEmitter'; },
  ];
  for (const mutate of mutations) { const f = fixture(); mutate(f); assert.throws(() => auditCompilerOwnership(f), /PSC_OWNERSHIP_/); }
});

test('character quote does not hide a forbidden target dependency from ownership', () => {
  const f = fixture();
  f.packages[1].modules[0].source += "\ndef quote : Char := '\"'\ndef x := PsJsExpr.literal";
  assert.throws(() => auditCompilerOwnership(f), /TARGET_LEAK/);
});

test('source declaration interop is available to the JS driver but cannot enter semantic or backend layers', () => {
  const f = fixture();
  f.policy.packages.push({ folder: 'interface-ts', name: '@fixture/declarations', role: 'interop' });
  f.packages.push({ folder: 'interface-ts',
    manifest: { name: '@fixture/declarations', version: '1', proofscript: {}, dependencies: { '@fixture/ir': '1' } },
    modules: [{ path: 'packages/interface-ts/src/Ps/InterfaceTs.lean', source: 'import Ps.Ir\ndef declarations : Nat := irValue' }] });
  f.packages[3].manifest.dependencies['@fixture/declarations'] = '1';
  f.packages[3].modules[0].source += '\nimport Ps.InterfaceTs';
  assert.equal(auditCompilerOwnership(f).packages, 5);
  for (const index of [1, 2]) {
    const changed = structuredClone(f);
    changed.packages[index].manifest.dependencies['@fixture/declarations'] = '1';
    assert.throws(() => auditCompilerOwnership(changed), /SEMANTIC_DEPENDENCY|BACKEND_FRONTEND_DEPENDENCY/);
  }
});
