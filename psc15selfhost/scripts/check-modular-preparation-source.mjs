import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const cases = [
  ['scripts/compile-with-generated.mjs', [
    'sources: chunks,',
    'compiler.List.cons(head, tail), compiler.List.nil()',
    'compiler.psCompilerPrepareSources(project.sourceKind, sources)',
    'compiler.psCompilerTypeScriptFromPrepared(prepared)',
  ]],
  ['packages/compiler/src/Ps/Compiler/Api.lean', [
    'psCompilerElaborateSourcesWorker sourceKind rest',
    'match psCompilerParseSource sourceKind source with',
    'match psElabModule environment sourceModule with',
    'smaller elaborated.environment',
    '(psListAppend (psListReverse elaborated.declarations) declarationsRev)',
    'psCompilerElaborateSourcesWorker sourceKind sources psSelfHostProdPreludeEnvironment List.nil',
    '| Except.ok elaborated => psCompilerPrepareElaborated elaborated',
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
console.log('PSC2_MODULAR_PREPARATION_SOURCE: PASS (ordered shared environment, combined admission and unchanged kernel gate)');
