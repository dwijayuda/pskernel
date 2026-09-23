import {
  Environment,
  constant,
  levelSucc,
  levelZero,
  nameFromDotted,
  sort,
} from 'lean-ts-kernel';
import {admitCheckedCoreAdmissions,admitCheckedCoreModule} from '../src/index.js';

function equal(actual:unknown,expected:unknown):void {
  if(actual!==expected){
    throw new Error('expected '+String(expected)+', got '+String(actual));
  }
}

{
  const base=new Environment();
  const A=nameFromDotted('A');
  const a=nameFromDotted('a');
  const id=nameFromDotted('idA');
  base.add({
    kind:'axiom',
    name:A,
    levelParams:[],
    type:sort(levelSucc(levelZero)),
  });
  base.add({
    kind:'axiom',
    name:a,
    levelParams:[],
    type:constant(A),
  });
  const checked=admitCheckedCoreModule(base,[{
    kind:'definition',
    name:id,
    levelParams:[],
    type:constant(A),
    value:constant(a),
    hints:{kind:'regular',height:1n},
    safety:'safe',
  }]);
  equal(checked.kind,'proofscript-checked-core');
  equal(checked.definitions.length,1);
  equal(checked.theorems.length,0);
  equal(checked.environment.find(id)?.kind,'definition');
  equal(base.find(id),undefined);
}

{
  const base=new Environment();
  let rejected=false;
  try{
    admitCheckedCoreModule(base,[{
      kind:'theorem',
      name:nameFromDotted('bad'),
      levelParams:[],
      type:sort(levelZero),
      value:sort(levelZero),
    }]);
  }catch{
    rejected=true;
  }
  equal(rejected,true);
}
console.log('ok - @proofscript/checked-core kernel admission boundary');


{
  const Box=nameFromDotted('Box');
  const mk=nameFromDotted('Box.mk');
  const Nat=nameFromDotted('Nat');
  const base=new Environment();
  base.add({
    kind:'axiom',
    name:Nat,
    levelParams:[],
    type:sort(levelSucc(levelZero)),
  });
  const checked=admitCheckedCoreAdmissions(base,[{
    kind:'structure',
    structure:{
      name:Box,
      constructor:mk,
      fields:[{name:'value',index:0,binderInfo:'default'}],
    },
    declaration:{
      levelParams:[],
      numParams:0,
      types:[{
        name:Box,
        type:sort(levelSucc(levelZero)),
        ctors:[{
          name:mk,
          type:{
            kind:'forall',
            name:nameFromDotted('value'),
            type:constant(Nat),
            body:constant(Box),
            binderInfo:'default',
          },
        }],
      }],
    },
  }]);
  equal(checked.inductiveDeclarations.length,1);
  equal(checked.inductives.length,1);
  equal(checked.structures.length,1);
  equal(checked.structures[0]?.fields[0]?.name,'value');
  equal(checked.environment.find(Box)?.kind,'inductive');
  equal(checked.environment.find(mk)?.kind,'constructor');
  equal(
    checked.environment.find(nameFromDotted('Box.rec'))?.kind,
    'recursor',
  );
  equal(base.find(Box),undefined);
}
console.log('ok - @proofscript/checked-core mixed inductive admission');


{
  const Sized=nameFromDotted('Sized');
  const mk=nameFromDotted('Sized.mk');
  const Nat=nameFromDotted('Nat');
  const base=new Environment();
  base.add({
    kind:'axiom',
    name:Nat,
    levelParams:[],
    type:sort(levelSucc(levelZero)),
  });
  const checked=admitCheckedCoreAdmissions(base,[{
    kind:'class',
    structure:{
      name:Sized,
      constructor:mk,
      fields:[{name:'size',index:0,binderInfo:'default'}],
    },
    declaration:{
      levelParams:[],
      numParams:0,
      types:[{
        name:Sized,
        type:sort(levelSucc(levelZero)),
        ctors:[{
          name:mk,
          type:{
            kind:'forall',
            name:nameFromDotted('size'),
            type:constant(Nat),
            body:constant(Sized),
            binderInfo:'default',
          },
        }],
      }],
    },
  }]);
  equal(checked.classes.length,1);
  equal(checked.structures.length,1);
  equal(checked.classes[0]?.name.kind,'str');
  equal(checked.environment.find(Sized)?.kind,'inductive');
}
console.log('ok - @proofscript/checked-core class metadata admission');
