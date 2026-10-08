import test from 'node:test';
import assert from 'node:assert/strict';
import { k, tag, list, randomGenerator } from './binding-values.mjs';
import { runtimeName, runtimeLevel, runtimeFuel } from './fixture-values.mjs';
import { decodeLevel } from './universe-values.mjs';

const N = s => ['str', ['anonymous'], s], Z = ['zero'], P = n => ['param', N(n)];
const S = x => ['succ', x], M = (x,y) => ['max', x,y], I = (x,y) => ['imax', x,y];
const start = (names, levels, target) => k.psKernelLevelInstantiateStart(
  list(names.map(n => runtimeName(k, n))), list(levels.map(l => runtimeLevel(k, l))), runtimeLevel(k, target));
function drive(state, budget=20000) {
  for (let steps=1;steps<=budget;steps++) {
    const out = k.psKernelLevelInstantiateStep(state);
    if (tag(out)==='final') return { status:tag(out.result), result:out.result, steps };
    assert.equal(tag(out),'next'); state=out.state;
  }
  return {status:'outOfFuel',steps:budget};
}
function instantiate(names, levels, value, budget) {
  return drive(start(names.map(N),levels,value), budget);
}
test('universe substitution is simultaneous, preserving parameters inside replacements',()=> {
  const r=instantiate(['u','v'],[P('v'),S(Z)],M(P('u'),P('v')));
  assert.equal(r.status,'done'); assert.deepEqual(decodeLevel(r.result.value),M(P('v'),S(Z)));
});
test('universe substitution preserves successor, max and imax operand order',()=> {
  const r=instantiate(['u','v'],[S(Z),S(S(Z))],I(S(P('u')),M(P('v'),P('u'))));
  assert.equal(r.status,'done'); assert.deepEqual(decodeLevel(r.result.value),I(S(S(Z)),M(S(S(Z)),S(Z))));
});
for(const [label,names,levels,target,status] of [
  ['closed empty context',[],[],I(S(Z),Z),'done'],
  ['missing argument',['u'],[],Z,'invalidParameters'],
  ['extra argument',[],[Z],Z,'invalidParameters'],
  ['duplicate parameter',['u','u'],[Z,S(Z)],P('u'),'invalidParameters'],
  ['unbound parameter',[],[],P('u'),'undeclaredParameter'],
  ['unbound nested parameter',['u'],[Z],I(P('u'),S(P('v'))),'undeclaredParameter'],
]) test('universe instantiation: '+label,()=>assert.equal(instantiate(names,levels,target).status,status));
test('anonymous parameters are rejected before traversing a target',()=> {
  assert.equal(drive(start([['anonymous']],[Z],Z)).status,'invalidParameters');
});
test('structured and dotted-root parameter names remain distinct',()=> {
  const structured=['str',N('A'),'B'], dotted=N('A.B');
  const r=drive(start([structured,dotted],[Z,S(Z)],M(['param',structured],['param',dotted])));
  assert.equal(r.status,'done'); assert.deepEqual(decodeLevel(r.result.value),M(Z,S(Z)));
});
test('one budget covers parameter validation, name lookup and reconstruction',()=> {
  const make=()=>start([N('u'),N('v')],[S(Z),Z],M(P('u'),I(P('v'),P('u'))));
  const full=drive(make()); assert.equal(full.status,'done');
  assert.equal(drive(make(),full.steps-1).status,'outOfFuel');
  assert.deepEqual(drive(make(),full.steps).result,full.result);
  assert.deepEqual(k.psKernelLevelInstantiateRun(runtimeFuel(k,full.steps),make()),full.result);
  assert.equal(tag(k.psKernelLevelInstantiateRun(runtimeFuel(k,full.steps-1),make())),'outOfFuel');
});
test('deep inputs exhaust iteratively and cannot manufacture a value',()=> {
  let level=k.PsKernelLevel.zero;
  for(let i=0;i<50000;i++)level=k.PsKernelLevel.succ(level);
  const state=k.psKernelLevelInstantiateStart(k.PsKernelList.nil(),k.PsKernelList.nil(),level);
  const result=drive(state,1024); assert.equal(result.status,'outOfFuel'); assert.equal(result.result,undefined);
});
test('invalid reconstruction states fail explicitly',()=> {
  const state=k.PsKernelLevelInstantiateState.running(k.PsKernelList.nil(),list([k.PsKernelLevelInstantiateTask.max]),list([k.PsKernelLevel.zero]));
  assert.equal(drive(state).status,'invalidState');
});
test('512 deterministic trees match independent simultaneous substitution',()=> {
  const rand=randomGenerator(234701), replacements=[P('v'),S(Z),I(P('outer'),S(Z))];
  const tree=depth=>depth===0?(rand(4)===0?Z:P(['u','v','w'][rand(3)])):
    [()=>S(tree(depth-1)),()=>M(tree(depth-1),tree(depth-1)),()=>I(tree(depth-1),tree(depth-1))][rand(3)]();
  const spec=x=>x[0]==='param'?replacements[['u','v','w'].indexOf(x[1][2])]:
    x[0]==='zero'?x:x[0]==='succ'?S(spec(x[1])):[x[0],spec(x[1]),spec(x[2])];
  for(let i=0;i<512;i++) {
    const input=tree(4), r=instantiate(['u','v','w'],replacements,input);
    assert.equal(r.status,'done','case '+i); assert.deepEqual(decodeLevel(r.result.value),spec(input),'case '+i);
  }
});
