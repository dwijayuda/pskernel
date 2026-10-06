import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const cases = [
  ['scripts/compile-with-generated.mjs', [
    'sources: chunks,',
    'let environment = compiler.psSelfHostProdPreludeEnvironment;',
    'let declarationsRev = compiler.List.nil();',
    'for (let index = 0; index < sourceChunks.length; index += 1)',
    'compiler.psCompilerParseSource(sourceKindValue, source)',
    'compiler.psElabModule(environment, parsed)',
    'environment = elaborated.environment;',
    'declarationsRev = compiler.psListAppend(',
    'compiler.psListReverse(elaborated.declarations),',
    'compiler.psCompilerElaborateSourcesWorker(',
    'compiler.psCompilerPrepareElaborated(elaborated)',
    'compiler.psCompilerTypeScriptFromPrepared(prepared)',
  ]],
  ['packages/compiler/src/Ps/Compiler/Candidate.lean', [
    'psCompilerElaborateSourcesWorker sourceKind rest',
    'match psCompilerParseSource sourceKind source with',
    'match psElabModule environment sourceModule with',
    'smaller elaborated.environment',
    '(psListAppend (psListReverse elaborated.declarations) declarationsRev)',
    'psCompilerElaborateSourcesWorker sourceKind sources psSelfHostProdPreludeEnvironment List.nil',
    '| Except.ok elaborated => psCompilerPrepareElaborated elaborated',
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
const generatedSelfhost = await readFile(
  new URL('../scripts/compile-with-generated.mjs', import.meta.url),
  'utf8',
);
assert(
  !generatedSelfhost.includes('psCompilerPrepareSources'),
  'generated-JS selfhost must reject missing incremental APIs instead of falling back to aggregate preparation',
);
assert(
  !generatedSelfhost.includes('aggregate'),
  'generated-JS selfhost must not contain an implicit aggregate preparation mode',
);
const api = await readFile(new URL('../packages/compiler/src/Ps/Compiler/Candidate.lean', import.meta.url), 'utf8');
const prepared = await readFile(new URL('../packages/compiler/src/Ps/Compiler/Model.lean', import.meta.url), 'utf8');
assert.deepEqual([...prepared.matchAll(/^  (\w+) :/gm)].map(item => item[1]), ['declarations']);
assert(!api.includes('prepared.canonicalAdmissions'), 'admissions must come from the declarations, never a cached serialization');
const session = await readFile(new URL('./kernel-checked-session.mjs', import.meta.url), 'utf8');
assert(session.indexOf('freezeGraph(prepared);') < session.indexOf('const admissions = admissionsFrom(compiler, prepared);'));
assert(session.includes('admissionsFrom(compiler, item.prepared) !== item.admissions'));
assert(session.includes('compiler.psCompilerTypeScriptFromPrepared(item.prepared)'));
console.log('PSC2_MODULAR_PREPARATION_SOURCE: PASS (ordered shared environment, combined admission and unchanged kernel gate)');
