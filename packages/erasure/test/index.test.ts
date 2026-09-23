import {
  Environment,
  bvar,
  forallE,
  lam,
  levelSucc,
  levelZero,
  nameFromDotted,
  sort,
  constant,
  mkAppN,
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


{
  const env=new Environment();
  const Nat=nameFromDotted('Nat');
  env.add({
    kind:'axiom',
    name:Nat,
    levelParams:[],
    type:sort(levelSucc(levelZero)),
  });
  const binaryType=forallE(
    nameFromDotted('x'),
    constant(Nat),
    forallE(
      nameFromDotted('y'),
      constant(Nat),
      constant(Nat),
    ),
  );
  for(const name of ['Nat.add','Nat.sub','Nat.mul']){
    env.add({
      kind:'axiom',
      name:nameFromDotted(name),
      levelParams:[],
      type:binaryType,
    });
  }
  const x=nameFromDotted('x');
  const y=nameFromDotted('y');
  const add=nameFromDotted('add');
  const value=lam(
    x,
    constant(Nat),
    lam(
      y,
      constant(Nat),
      mkAppN(
        constant(nameFromDotted('Nat.add')),
        [bvar(1),bvar(0)],
      ),
    ),
  );
  const checked=admitCheckedCoreModule(env,[{
    kind:'definition',
    name:add,
    levelParams:[],
    type:binaryType,
    value,
    hints:{kind:'regular',height:1n},
    safety:'safe',
  }]);
  const erased=eraseCheckedCoreModule(checked);
  equal(erased.declarations[0]?.body.kind,'intrinsic');
  if(erased.declarations[0]?.body.kind==='intrinsic'){
    equal(erased.declarations[0]?.body.operation,'nat.add');
  }
}
console.log('ok - @proofscript/erasure Nat intrinsic lowering');


{
  const env=new Environment();
  const Nat=nameFromDotted('Nat');
  env.add({
    kind:'axiom',
    name:Nat,
    levelParams:[],
    type:sort(levelSucc(levelZero)),
  });
  const id=nameFromDotted('natIdentity');
  const type=forallE(
    nameFromDotted('x'),
    constant(Nat),
    constant(Nat),
  );
  const value=lam(
    nameFromDotted('x'),
    constant(Nat),
    bvar(0),
  );
  const checked=admitCheckedCoreModule(env,[{
    kind:'definition',
    name:id,
    levelParams:[],
    type,
    value,
    hints:{kind:'regular',height:1n},
    safety:'safe',
  }]);
  const declaration=eraseCheckedCoreModule(checked).declarations[0]!;
  equal(declaration.parameters[0]?.type.kind,'primitive');
  if(declaration.parameters[0]?.type.kind==='primitive'){
    equal(declaration.parameters[0].type.name,'Nat');
  }
  equal(declaration.resultType.kind,'primitive');
  if(declaration.resultType.kind==='primitive'){
    equal(declaration.resultType.name,'Nat');
  }
}
console.log('ok - @proofscript/erasure semantic primitive type identity');
