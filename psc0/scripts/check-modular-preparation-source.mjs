import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const cases = [
  ['scripts/compile-with-generated.mjs', [
    "import { buildChecked } from './checked-build.mjs'",
    'const receipt = await buildChecked({',
    'compilerPath: path.resolve(root, compiler)',
    'entryPath: path.resolve(root, entry)',
  ]],
  // Shape/ownership guard for the pure prefix seam. Generated session admission
  // correspondence and transition cases provide the semantic evidence.
  ['packages/compiler/src/Ps/Compiler/Api.lean', [
    'sourceKind psSelfHostProdPreludeEnvironment List.nil',
    'psCompilerPreparationStepParsed state sourceModule',
    'state.sourceKind elaborated.environment',
    'PsElabModuleResult.mk state.environment (psListReverse state.declarationsRev)',
    'psCompilerPrepareElaborated (psCompilerPreparationElaborated state)',
    '(PsCompilerPreparationState.mk sourceKind environment declarationsRev) with',
    'psCompilerPreparationSourcesWorker rest next',
    '(sources : List String)\n    (state : PsCompilerPreparationState) :\n    Except PsCompilerError PsCompilerPreparationState :=',
    'match psCompilerParseSource state.sourceKind source with',
    'match psElabModule state.environment sourceModule with',
    '| Except.ok next => psCompilerPreparationSourcesWorker rest next',
    '(psListAppend (psListReverse elaborated.declarations) state.declarationsRev)',
    '(psCompilerPreparationStart sourceKind) with',
    '| Except.ok state => psCompilerPreparationFinish state',
    'Except.ok (PsCompilerAdmissionReadyModule.mk elaborated.declarations)',
    'match psEncodeCheckedAdmissionsCanonical prepared.declarations with',
    'Except.ok (String.Internal.append canonicalAdmissions "\\n")',
  ]],
  ['scripts/LeanCheckedSeed.lean', [
    'psCompilerPrepareSources kind sources',
    'psCheckedSeedPreparedSession prepared',
    'if currentAdmissions != admissions then',
    'PSC2_CHECKED_PAYLOAD_CHANGED',
  ]],
  ['scripts/checked-seed-session.mjs', [
    "sources.join('\\n\\n') + '\\n' !== source",
    'JSON.stringify(sources)',
    'checkAdmissions(prepared.admissions)',
    "kernelResult?.accepted !== true",
  ]],
  ['scripts/checked-build.mjs', [
    'sources: snapshot.sources,',
    'session.checkSources(kind, snapshot.sources)',
  ]],
];
for (const [file, markers] of cases) {
  const source = await readFile(new URL('../' + file, import.meta.url), 'utf8');
  const validate = text => {
    for (const marker of markers) assert(text.includes(marker), `${file}: missing ${marker}`);
  };
  validate(source);
  for (const marker of markers) assert.throws(() => validate(source.replaceAll(marker, 'removed')));
}
const api = await readFile(new URL('../packages/compiler/src/Ps/Compiler/Api.lean', import.meta.url), 'utf8');
function structureFields(name) {
  const lines = api.split(/\r?\n/u);
  const start = lines.indexOf('structure ' + name + ' where');
  assert(start !== -1, 'missing preparation structure: ' + name);
  const fields = [];
  for (let index = start + 1; index < lines.length; index++) {
    const line = lines[index];
    if (line !== '' && !/^[ \t]/u.test(line)) break;
    const field = /^[ \t]+([^ \t:]+)[ \t]*:/u.exec(line);
    if (field) fields.push(field[1]);
  }
  return fields;
}
assert.deepEqual(structureFields('PsCompilerAdmissionReadyModule'), ['declarations']);
assert.deepEqual(structureFields('PsCompilerPreparationState'),
  ['sourceKind', 'environment', 'declarationsRev']);
assert(!api.includes('prepared.canonicalAdmissions'), 'admissions must come from the declarations, never a cached serialization');
// Normalize checkout line endings only for this source-shape inspection.
// Runtime inputs, emitted artifacts and receipt hashes retain their exact bytes.
const session = (await readFile(new URL('./checked-prepared-session.mjs', import.meta.url), 'utf8'))
  .replaceAll('\r\n', '\n');
const freezeIndex = session.indexOf('freezeGraph(prepared);');
const admissionsIndex = session.indexOf(
  'const admissions = admissionsFrom(compiler, prepared, projectUnits !== undefined);');
assert(freezeIndex !== -1 && admissionsIndex !== -1,
  'prepared graph freezing and project-aware admission serialization must both be present');
assert(freezeIndex < admissionsIndex, 'freeze the prepared graph before serializing admission');
assert(session.includes('admissionsFrom(compiler, item.prepared, project) !== item.admissions'));
assert(session.includes("const emitter = project ? 'psCompilerCheckedTypeScriptProjectFromPrepared'\n" +
  "      : 'psCompilerCheckedTypeScriptFromPrepared';"),
  'emission selection must remain closed over the two checked emitters');
assert(session.includes('compiler[emitter](irPolicy.options, item.prepared)'));
assert(!session.includes('psCompilerTypeScriptFromPrepared'),
  'protected prepared sessions must not retain a raw TypeScript emission fallback');
console.log('PSC2_MODULAR_PREPARATION_SOURCE: PASS (ordered shared environment, combined admission and checked IR emission)');
