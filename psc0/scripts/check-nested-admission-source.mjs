import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const source = await readFile(new URL('../packages/bridge/src/Ps/Bridge/CheckedAdmissions.lean', import.meta.url), 'utf8');
const markers = [
  'def psCheckedAdmissionNatToString\n    (value : Nat) : String :=\n  Int.repr (Int.ofNat value)',
  'def psCheckedNestedContainerFields',
  'if psCheckedNestedContains name arg then false else psCheckedNestedDirect name fn',
  'if psCheckedNestedDirect name type then shapes',
  'psCheckedNestedName "List"', 'psCheckedNestedName "Option"', 'psCheckedNestedName "Prod"',
  'smaller (psListAppend rest fresh) (psListAppend done [type])',
  'PsExpr.sortE psCheckedNestedLevel',
  'psCheckedNestedDirectHypotheses hypotheses',
  'if psListIsEmpty info.levelParams then',
  'if Nat.beq info.numParams 0 then', 'if Nat.beq info.numIndices 0 then',
  'PsExpr.constE (PsName.str info.name "rec") [psCheckedNestedLevel]',
  'PsDeclaration.definitionDecl (PsName.str info.name "_pscShallowRec")',
  'if psListIsEmpty wrappers then psEncodeCheckedAdmissionsNormalized declarations',
  '(psListAppend psCheckedNestedUnitDeclarations (psCheckedNestedNormalize wrappers declarations))',
];
const validate = text => { for (const marker of markers) assert(text.includes(marker), `missing nested admission guard: ${marker}`); };
validate(source);
for (const marker of markers) assert.throws(() => validate(source.replaceAll(marker, 'removed')));
console.log('PSC2_NESTED_ADMISSION_SOURCE: PASS (breadth-first containers, universe-correct auxiliary motives, checked definitions and unsupported-shape rejection)');
