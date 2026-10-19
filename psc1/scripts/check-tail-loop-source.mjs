import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const source = await readFile(new URL('../packages/backend-ts/src/Ps/BackendTs/Module.lean', import.meta.url), 'utf8');
const relevant = source.slice(source.indexOf('structure PsTsTailAlias'), source.indexOf('def psTsFlattenLines'));
const markers = [
  'psTsTailParametersMatch parameters arguments',
  'if psListAny shadows parameters then Option.none',
  'if psListIsEmpty types then',
  'if psTsTailBindingSafe declaration aliases name then',
  'if psTsTailBindingSafe declaration aliases binding.name then',
  'if psTsTailBindingSafe declaration aliases temporary then',
  'if Nat.beq alias.arity (psListLength arguments) then',
  'if Nat.beq (psListLength actual) (psListLength declaration.parameters) then',
  '| PsVerifiedIrIntrinsic.arrayMap => false',
  '| PsVerifiedIrIntrinsic.arrayFoldl => false',
  'if psListIsEmpty declaration.typeParameters then',
  'psTsEmitDeclarationGeneral brands tags declaration',
  '"] = [", psTsJoin ", " printed, "]; continue;"',
];
const validate = text => markers.forEach(marker => assert(text.includes(marker), `missing tail loop guard: ${marker}`));
validate(relevant);
for (const marker of markers) assert.throws(() => validate(relevant.replaceAll(marker, 'removed')));
console.log('PSC2_TAIL_LOOP_SOURCE: PASS (closed tail calls, simultaneous updates, capture and arity guards, bounded analysis and general fallback)');
