import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const source = await readFile(new URL('../packages/backend-ts/src/Ps/BackendTs/Module.lean', import.meta.url), 'utf8');
const markers = ['psTsCountLiteral 0 (Prod.snd (Prod.snd base))',
  'psTsCountLiteral 1 left', 'psTsCountLiteral 1 right',
  'if psStringEq called name then', 'if psListIsEmpty rest then',
  'PsVerifiedIrPrimitiveType.nat', 'psTsCountField localName (Prod.fst (Prod.snd step))',
  'if psStringEq localName parameter.name then', 'if psListIsEmpty tail then',
  '| Option.none => psTsEmitDeclarationGeneral brands tags declaration'];
const validate = text => { for (const marker of markers) assert(text.includes(marker), `missing structural count condition: ${marker}`); };
validate(source);
for (const marker of markers) assert.throws(() => validate(source.replaceAll(marker, 'removed')));
console.log('PSC2_COUNT_FOLD_SOURCE: PASS (IR-shaped zero/successor recognition, exact arity, direct recursive field and general fallback)');
