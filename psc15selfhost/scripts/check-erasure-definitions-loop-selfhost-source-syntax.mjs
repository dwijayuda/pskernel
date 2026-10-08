import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const source = await readFile(new URL('../packages/erasure/src/Ps/Erasure/Definition.lean', import.meta.url), 'utf8');
const required = [
  /def psErasureReverseIrDeclarationsAcc[\s\S]*?match declarations with/,
  /psErasureReverseIrDeclarationsAcc rest;\s*fun \(acc : List PsVerifiedIrDeclaration\) =>\s*smaller \(List\.cons declaration acc\)/,
  /def psEraseRuntimeDeclaration[\s\S]*?\| PsDeclaration\.definitionDecl name _ type value =>\s*psEraseDefinition environment scope name type value/,
  /\| PsDeclaration\.partialDecl name _ type value =>\s*psEraseDefinition environment scope name type value/,
  /\| _ => Except\.ok Option\.none/,
  /def psEraseDefinitionsObservedWorker[\s\S]*?match declarations with/,
  /psEraseDefinitionsObservedWorker environment scope rest;/,
  /match psEraseRuntimeDeclaration environment scope declaration with\s*\| Except\.error error => Except\.error error\s*\| Except\.ok result =>/,
  /\| Option\.none => declarationsRev\s*\| Option\.some lowered => List\.cons lowered declarationsRev;/,
  /smaller observe nextDeclarations nextCorrespondence/,
  /psErasureReverseCorrespondenceAcc rest;/,
  /psErasureReverseIrDeclarationsAcc declarationsRev List\.nil/,
  /psErasureReverseCorrespondenceAcc correspondenceRev List\.nil/,
  /psEraseDefinitionsObservedWorker\s+environment scope declarations false declarationsRev List\.nil with/,
  /psEraseDefinitionsLoopWorker environment scope declarations declarationsRev/,
];
function check(text) {
  const block = text.match(/def psErasureReverseIrDeclarationsAcc[\s\S]*?(?=\nstructure PsErasureModuleProduct)/)?.[0];
  assert.ok(block, 'PSC2_ERASURE_DEFINITIONS_LOOP_MISSING');
  for (const pattern of required) assert.match(block, pattern, 'PSC2_ERASURE_DEFINITIONS_LOOP_STRUCTURE');
  assert.doesNotMatch(block, /\.reverse\b|\| \[\],|\| declaration :: rest,|\| Except\.ok \(|\| \.(?:definition|partial)Decl/,
    'PSC2_ERASURE_DEFINITIONS_LOOP_FORBIDDEN');
}
check(source);
for (const marker of [
  'psEraseDefinitionsObservedWorker environment scope rest;',
  '| Except.error error => Except.error error',
  'smaller observe nextDeclarations nextCorrespondence',
  'psErasureReverseCorrespondenceAcc correspondenceRev List.nil',
]) assert.throws(() => check(source.replaceAll(marker, 'missing')), /PSC2_ERASURE_DEFINITIONS_LOOP_/);
console.log('PSC2_ERASURE_DEFINITIONS_LOOP: PASS (one decreasing fold, first-error propagation, ordered IR and optional correspondence)');
