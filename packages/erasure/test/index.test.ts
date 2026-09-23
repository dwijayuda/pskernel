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
import {validateVerifiedIrModule} from '@proofscript/compiler-ir/verified';
import {eraseCheckedCoreModule} from '../src/index.js';

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
  const type=forallE(
    alpha,
    alphaType,
    forallE(x,bvar(0),bvar(1),'default'),
    'implicit',
  );
  const value=lam(
    alpha,
    alphaType,
    lam(x,bvar(0),bvar(0),'default'),
    'implicit',
  );
  const checked=admitCheckedCoreModule(new Environment(),[{
    kind:'definition',
    name:identity,
    levelParams:[],
    type,
    value,
    hints:{kind:'regular',height:1n},
    safety:'safe',
  }]);

  const erased=eraseCheckedCoreModule(checked);
  equal(validateVerifiedIrModule(erased),true);
  equal(erased.declarations.length,1);
  const declaration=erased.declarations[0]!;
  equal(declaration.name,'identity');
  equal(declaration.typeParameters.length,1);
  equal(declaration.typeParameters[0]?.name,'T0');
  equal(declaration.parameters.length,1);
  equal(declaration.parameters[0]?.name,'x');
  equal(declaration.parameters[0]?.type.kind,'typeParameter');
  equal(declaration.resultType.kind,'typeParameter');
  equal(declaration.body.kind,'var');
  if(declaration.body.kind==='var')equal(declaration.body.name,'x');
}
console.log('ok - @proofscript/erasure generic identity');


{
  const alpha=nameFromDotted('α');
  const P=nameFromDotted('P');
  const h=nameFromDotted('h');
  const x=nameFromDotted('x');
  const keep=nameFromDotted('keep');
  const type=forallE(
    alpha,
    sort(levelSucc(levelZero)),
    forallE(
      P,
      sort(levelZero),
      forallE(
        h,
        bvar(0),
        forallE(x,bvar(2),bvar(3),'default'),
        'default',
      ),
      'default',
    ),
    'implicit',
  );
  const value=lam(
    alpha,
    sort(levelSucc(levelZero)),
    lam(
      P,
      sort(levelZero),
      lam(
        h,
        bvar(0),
        lam(x,bvar(2),bvar(0),'default'),
        'default',
      ),
      'default',
    ),
    'implicit',
  );
  const checked=admitCheckedCoreModule(new Environment(),[{
    kind:'definition',
    name:keep,
    levelParams:[],
    type,
    value,
    hints:{kind:'regular',height:1n},
    safety:'safe',
  }]);
  const erased=eraseCheckedCoreModule(checked);
  const declaration=erased.declarations[0]!;
  equal(declaration.typeParameters.length,1);
  equal(declaration.parameters.length,1);
  equal(declaration.parameters[0]?.name,'x');
  equal(declaration.resultType.kind,'typeParameter');
}
console.log('ok - @proofscript/erasure Prop and proof binder erasure');
