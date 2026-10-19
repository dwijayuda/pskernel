import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const source = await readFile(new URL('../packages/environment/src/Ps/Environment/Basic.lean', import.meta.url), 'utf8');
const markers = ['inductive PsEnvironmentIndex where',
  'Nat.mod (Nat.add (Nat.mul hash 31) (Char.toNat char)) 65521',
  'psEnvironmentIndexFindWorker 16 environment.index (psEnvironmentNameHash name)',
  'psEnvironmentFindInList name (psEnvironmentIndexFindWorker',
  'if psNameEq name (psDeclarationName declaration) then',
  'psEnvironmentIndexSetWorker 16 index hash (List.cons declaration (psEnvironmentRemoveName name bucket))',
  '(psEnvironmentIndexInsert environment.index declaration)',
  '(List.cons declaration environment.declarations)',
];
const validate = text => { for (const marker of markers) assert(text.includes(marker), `missing environment index guard: ${marker}`); };
validate(source);
for (const marker of markers) assert.throws(() => validate(source.replaceAll(marker, 'removed')));
assert.equal(source.match(/\(psEnvironmentIndexInsert environment.index declaration\)/g)?.length, 3);
console.log('PSC2_ENVIRONMENT_INDEX_SOURCE: PASS (bounded immutable trie, full-name collision checks, all insertion paths and preserved ordered list)');
