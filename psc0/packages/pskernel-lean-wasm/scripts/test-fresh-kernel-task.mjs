import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';

const root=fileURLToPath(new URL('../',import.meta.url));
const source=readFileSync(new URL('../src/PsKernelLeanWasm/Main.lean',import.meta.url),'utf8');
const admission=readFileSync(new URL('../../pskernel-lean/provider/PsKernelLean/Admission.lean',import.meta.url),'utf8');

test('official Lean 4.35 kernel checking is deferred inside fresh task worker',()=>{
  assert.match(source,/let task ← IO\.asTask do/);
  assert.match(source,/let result ← IO\.lazyPure \(fun _ =>[\s\S]*?PsKernelLean\.admitDeclarations prelude declarations\)/);
  assert.doesNotMatch(source,/return PsKernelLean\.admitDeclarations prelude declarations/);
});
test('real kernel budgets remain finite and admission remains checked',()=>{
  assert.match(admission,/env\.addDeclCore 2000000 20000 declaration none/);
  assert.match(source,/match ← IO\.ofExcept \(← IO\.wait task\) with/);
  assert.match(source,/return rejected error\.kind\.code/);
});
