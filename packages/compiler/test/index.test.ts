import {
  Environment,
  bvar,
  forallE,
  lam,
  levelSucc,
  levelZero,
  nameFromDotted,
  sort,
} from 'lean-ts-kernel';
import {admitCheckedCoreModule} from '@proofscript/checked-core';
import {compileCheckedCore} from '../src/index.js';

function equal(actual:unknown,expected:unknown):void {
  if(actual!==expected){
    throw new Error('expected '+String(expected)+', got '+String(actual));
  }
}

{
  const alpha=nameFromDotted('α');
  const x=nameFromDotted('x');
  const identity=nameFromDotted('identity');
  const alphaType=sort(levelSucc(levelZero));
  const checked=admitCheckedCoreModule(new Environment(),[{
    kind:'definition',
    name:identity,
    levelParams:[],
    type:forallE(
      alpha,
      alphaType,
      forallE(x,bvar(0),bvar(1),'default'),
      'implicit',
    ),
    value:lam(
      alpha,
      alphaType,
      lam(x,bvar(0),bvar(0),'default'),
      'implicit',
    ),
    hints:{kind:'regular',height:1n},
    safety:'safe',
  }]);

  const result=compileCheckedCore(checked,'identity.ts');
  equal(
    result.typeScript.includes(
      'export function identity<T0>(x: T0): T0 { return x; }',
    ),
    true,
  );
  equal(result.emitted.javascript.includes('function identity(x)'),true);
  equal(result.emitted.javascript.includes('T0'),false);
  equal(
    result.emitted.declaration.includes(
      'identity<T0>(x: T0): T0',
    ),
    true,
  );
}
console.log('ok - @proofscript/compiler checked-core orchestration');


{
  const source=compileCheckedCore;
  equal(typeof source,'function');
}
console.log('ok - @proofscript/compiler IR keeps language primitive identity upstream of TS mapping');
