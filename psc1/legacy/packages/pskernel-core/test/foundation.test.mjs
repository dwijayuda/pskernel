import assert from 'node:assert/strict';
import test from 'node:test';
import * as k from '../dist/foundation.js';
import { cases, runCase, runtimeFuel, runtimeText } from './fixture-values.mjs';
for (const c of cases) test(c.label, () => {
  assert.equal(runCase(k,c), k.PsKernelCompareResult[c.expected]);
  assert.equal(runCase(k,{...c,left:c.right,right:c.left}), k.PsKernelCompareResult[c.expected], 'symmetry');
  if (c.expected !== 'outOfFuel') assert.equal(runCase(k,{...c,fuel:1024}), k.PsKernelCompareResult[c.expected], 'additional fuel must preserve a result');
});
test('empty worklist finishes with no fuel',()=> {
  assert.equal(k.psKernelCompareTasks(k.PsKernelFuel.stop,k.PsKernelList.nil()),k.PsKernelCompareResult.equal);
});
test('exhaustion is not converted into inequality',()=> {
  assert.notEqual(k.PsKernelCompareResult.outOfFuel,k.PsKernelCompareResult.different);
  assert.notEqual(k.PsKernelCompareResult.outOfFuel,k.PsKernelCompareResult.equal);
});
test('all 256 small natural pairs preserve exact equality',()=> {
  for(let a=0;a<16;a++) for(let b=0;b<16;b++) {
    assert.equal(runCase(k,{kind:'natural',left:String(a),right:String(b),fuel:32}), a===b?k.PsKernelCompareResult.equal:k.PsKernelCompareResult.different);
  }
});
test('global fuel is shared across independent queued comparisons',()=> {
  const t=k.PsKernelCompareTask.name(k.PsKernelName.anonymous,k.PsKernelName.anonymous);
  const tasks=k.PsKernelList.cons(t,k.PsKernelList.cons(t,k.PsKernelList.nil()));
  assert.equal(k.psKernelCompareTasks(runtimeFuel(k,1),tasks),k.PsKernelCompareResult.outOfFuel);
  assert.equal(k.psKernelCompareTasks(runtimeFuel(k,2),tasks),k.PsKernelCompareResult.equal);
});
test('separately allocated data compare without object-identity assumptions',()=> {
  const n=k.PsKernelName, t=k.PsKernelCompareTask, l=k.PsKernelList;
  const a=n.str(n.str(n.anonymous,runtimeText(k,'prefix')),runtimeText(k,'leaf')),b=n.str(n.str(n.anonymous,runtimeText(k,'prefix')),runtimeText(k,'leaf'));
  assert.notEqual(a,b);
  const input=l.cons(t.name(a,b),l.nil());
  const before=JSON.stringify(input);
  assert.equal(k.psKernelCompareTasks(runtimeFuel(k,256),input),k.PsKernelCompareResult.equal);
  assert.equal(JSON.stringify(input),before,'comparison must not mutate supplied well-formed data');
});
