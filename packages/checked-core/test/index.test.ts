import {
  Environment,
  constant,
  levelSucc,
  levelZero,
  nameFromDotted,
  sort,
} from 'lean-ts-kernel';
import {admitCheckedCoreModule} from '../src/index.js';

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
