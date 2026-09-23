import {
  Environment,
  Kernel,
  app,
  bvar,
  constant,
  forallE,
  lam,
  levelSucc,
  levelZero,
  mkAppN,
  nameFromDotted,
  natLit,
  sort,
} from 'lean-ts-kernel';
import {
  admitCheckedCoreAdmissions,
  admitCheckedCoreModule,
} from '@proofscript/checked-core';
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


{
  const base=new Environment();
  const kernel=new Kernel(base);
  const Nat=nameFromDotted('TestNat');
  kernel.addAxiom({
    kind:'axiom',
    name:Nat,
    levelParams:[],
    type:sort(levelSucc(levelZero)),
  });
  const User=nameFromDotted('User');
  const UserMk=nameFromDotted('User.mk');
  const age=nameFromDotted('age');
  const make=nameFromDotted('make');
  const get=nameFromDotted('get');
  const userType=constant(User);
  const natType=constant(Nat);
  const checked=admitCheckedCoreAdmissions(base,[
    {
      kind:'structure',
      declaration:{
        levelParams:[],
        numParams:0,
        types:[{
          name:User,
          type:sort(levelSucc(levelZero)),
          ctors:[{
            name:UserMk,
            type:forallE(age,natType,userType),
          }],
        }],
      },
      structure:{
        name:User,
        constructor:UserMk,
        fields:[{name:'age',index:0,binderInfo:'default'}],
      },
    },
    {
      kind:'constant',
      declaration:{
        kind:'definition',
        name:make,
        levelParams:[],
        type:forallE(age,natType,userType),
        value:lam(age,natType,app(constant(UserMk),bvar(0))),
        hints:{kind:'regular',height:1n},
        safety:'safe',
      },
    },
    {
      kind:'constant',
      declaration:{
        kind:'definition',
        name:get,
        levelParams:[],
        type:forallE(nameFromDotted('user'),userType,natType),
        value:lam(
          nameFromDotted('user'),
          userType,
          {kind:'proj',typeName:User,index:0,expr:bvar(0)},
        ),
        hints:{kind:'regular',height:1n},
        safety:'safe',
      },
    },
  ]);
  const erased=eraseCheckedCoreModule(checked);
  equal(erased.structures?.length,1);
  equal(erased.structures?.[0]?.name,'User');
  const makeIr=erased.declarations.find((item)=>item.name==='make');
  const getIr=erased.declarations.find((item)=>item.name==='get');
  equal(makeIr?.body.kind,'record');
  equal(getIr?.body.kind,'projection');
}
console.log('ok - @proofscript/erasure verified runtime structures');


{
  const base=new Environment();
  const kernel=new Kernel(base);
  const Nat=nameFromDotted('TestNat');
  kernel.addAxiom({
    kind:'axiom',
    name:Nat,
    levelParams:[],
    type:sort(levelSucc(levelZero)),
  });
  const Maybe=nameFromDotted('MaybeNat');
  const None=nameFromDotted('MaybeNat.none');
  const Some=nameFromDotted('MaybeNat.some');
  const valueName=nameFromDotted('value');
  const maybeType=constant(Maybe);
  const checked=admitCheckedCoreAdmissions(base,[
    {
      kind:'inductive',
      declaration:{
        levelParams:[],
        numParams:0,
        types:[{
          name:Maybe,
          type:sort(levelSucc(levelZero)),
          ctors:[
            {name:None,type:maybeType},
            {
              name:Some,
              type:forallE(
                valueName,
                constant(Nat),
                maybeType,
              ),
            },
          ],
        }],
      },
    },
    {
      kind:'constant',
      declaration:{
        kind:'definition',
        name:nameFromDotted('noneValue'),
        levelParams:[],
        type:maybeType,
        value:constant(None),
        hints:{kind:'regular',height:1n},
        safety:'safe',
      },
    },
    {
      kind:'constant',
      declaration:{
        kind:'definition',
        name:nameFromDotted('oneValue'),
        levelParams:[],
        type:maybeType,
        value:app(constant(Some),natLit(1n)),
        hints:{kind:'regular',height:1n},
        safety:'safe',
      },
    },
  ]);
  const erased=eraseCheckedCoreModule(checked);
  equal(erased.inductives?.length,1);
  equal(erased.inductives?.[0]?.name,'MaybeNat');
  equal(erased.inductives?.[0]?.constructors.length,2);
  equal(
    erased.declarations.find((item)=>item.name==='noneValue')?.body.kind,
    'constructor',
  );
  equal(
    erased.declarations.find((item)=>item.name==='oneValue')?.body.kind,
    'constructor',
  );
}
console.log('ok - @proofscript/erasure verified ADT constructors');


{
  const base=new Environment();
  const kernel=new Kernel(base);
  const Nat=nameFromDotted('TestNat');
  kernel.addAxiom({
    kind:'axiom',
    name:Nat,
    levelParams:[],
    type:sort(levelSucc(levelZero)),
  });
  const Maybe=nameFromDotted('MaybeNat');
  const None=nameFromDotted('MaybeNat.none');
  const Some=nameFromDotted('MaybeNat.some');
  const maybeType=constant(Maybe);
  const checkedBase=admitCheckedCoreAdmissions(base,[{
    kind:'inductive',
    declaration:{
      levelParams:[],
      numParams:0,
      types:[{
        name:Maybe,
        type:sort(levelSucc(levelZero)),
        ctors:[
          {name:None,type:maybeType},
          {
            name:Some,
            type:forallE(
              nameFromDotted('value'),
              constant(Nat),
              maybeType,
            ),
          },
        ],
      }],
    },
  }]);
  const recursor=nameFromDotted('MaybeNat.rec');
  const motive=lam(
    nameFromDotted('_'),
    maybeType,
    constant(Nat),
  );
  const matchValue={
    kind:'definition' as const,
    name:nameFromDotted('getOrZero'),
    levelParams:[],
    type:forallE(nameFromDotted('value'),maybeType,constant(Nat)),
    value:lam(
      nameFromDotted('value'),
      maybeType,
      mkAppN(
        constant(recursor,[levelZero]),
        [
          motive,
          natLit(0),
          lam(
            nameFromDotted('x'),
            constant(Nat),
            bvar(0),
          ),
          bvar(0),
        ],
      ),
    ),
    hints:{kind:'regular' as const,height:1n},
    safety:'safe' as const,
  };
  const checked=admitCheckedCoreAdmissions(base,[
    {
      kind:'inductive',
      declaration:{
        levelParams:[],
        numParams:0,
        types:[{
          name:Maybe,
          type:sort(levelSucc(levelZero)),
          ctors:[
            {name:None,type:maybeType},
            {
              name:Some,
              type:forallE(
                nameFromDotted('value'),
                constant(Nat),
                maybeType,
              ),
            },
          ],
        }],
      },
    },
    {kind:'constant',declaration:matchValue},
  ]);
  void checkedBase;
  const erased=eraseCheckedCoreModule(checked);
  const body=erased.declarations.find(
    (item)=>item.name==='getOrZero',
  )?.body;
  equal(body?.kind,'match');
  if(body?.kind==='match'){
    equal(body.inductive,'MaybeNat');
    equal(body.alternatives.length,2);
    equal(body.alternatives[0]?.constructor,'none');
    equal(body.alternatives[1]?.constructor,'some');
    equal(body.alternatives[1]?.bindings[0]?.field,'value');
    equal(body.alternatives[1]?.body.kind,'var');
  }
}
console.log('ok - @proofscript/erasure verified ADT recursor match lowering');
