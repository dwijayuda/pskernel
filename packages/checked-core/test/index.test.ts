import {
  Environment,
  constant,
  forallE,
  levelSucc,
  levelZero,
  nameFromDotted,
  sort,
} from 'lean-ts-kernel';
import {admitCheckedCoreAdmissions,admitCheckedCoreModule,decodeCheckedCoreAdmissions,encodeCheckedCoreAdmissions} from '../src/index.js';

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


{
  const Boxed=nameFromDotted('Boxed');
  const mk=nameFromDotted('Boxed.mk');
  const boxedNat=nameFromDotted('boxedNat');
  const Nat=nameFromDotted('Nat');
  const base=new Environment();
  base.add({
    kind:'axiom',
    name:Nat,
    levelParams:[],
    type:sort(levelSucc(levelZero)),
  });
  const checked=admitCheckedCoreAdmissions(base,[
    {
      kind:'class',
      structure:{
        name:Boxed,
        constructor:mk,
        fields:[{name:'value',index:0,binderInfo:'default'}],
      },
      declaration:{
        levelParams:[],
        numParams:0,
        types:[{
          name:Boxed,
          type:sort(levelSucc(levelZero)),
          ctors:[{
            name:mk,
            type:{
              kind:'forall',
              name:nameFromDotted('value'),
              type:constant(Nat),
              body:constant(Boxed),
              binderInfo:'default',
            },
          }],
        }],
      },
    },
    {
      kind:'instance',
      instance:{
        name:boxedNat,
        className:Boxed,
        anonymous:false,
      },
      declaration:{
        kind:'definition',
        name:boxedNat,
        levelParams:[],
        type:constant(Boxed),
        value:{
          kind:'app',
          fn:constant(mk),
          arg:{kind:'lit',literal:{kind:'nat',value:0n}},
        },
        hints:{kind:'regular',height:1n},
        safety:'safe',
      },
    },
  ]);
  equal(checked.instances.length,1);
  equal(checked.instances[0]?.anonymous,false);
  equal(checked.environment.find(boxedNat)?.kind,'definition');
}
console.log('ok - @proofscript/checked-core instance registry metadata');

{
  const base=new Environment();
  const A=nameFromDotted('Codec.A');
  const a=nameFromDotted('Codec.a');
  const id=nameFromDotted('Codec.id');
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
  const original=[{
    kind:'constant' as const,
    declaration:{
      kind:'definition' as const,
      name:id,
      levelParams:[],
      type:constant(A),
      value:constant(a),
      hints:{kind:'regular' as const,height:2n},
      safety:'safe' as const,
    },
  }];
  const encoded=encodeCheckedCoreAdmissions(original);
  const decoded=decodeCheckedCoreAdmissions(encoded);
  const checked=admitCheckedCoreAdmissions(base,decoded);
  equal(checked.definitions.length,1);
  equal(checked.environment.find(id)?.kind,'definition');
  equal(
    (checked.environment.find(id) as {hints?:{kind:string;height?:bigint}})?.hints?.height,
    2n,
  );
  let rejected=false;
  try{
    encodeCheckedCoreAdmissions([{
      kind:'constant',
      declaration:{
        kind:'theorem',
        name:nameFromDotted('Codec.bad'),
        levelParams:[],
        type:sort(levelZero),
        value:{kind:'mvar',id:'?bad'},
      },
    }]);
  }catch(error){
    rejected=/metavariables are not persistent/.test(String(error));
  }
  equal(rejected,true);
}
console.log('ok - @proofscript/checked-core persistent admission codec');

{
  const base=new Environment();
  const Nat=nameFromDotted('Nat');
  const hostInc=nameFromDotted('hostInc');
  base.add({
    kind:'axiom',
    name:Nat,
    levelParams:[],
    type:sort(levelSucc(levelZero)),
  });
  const admissions=[{
    kind:'external' as const,
    declaration:{
      kind:'axiom' as const,
      name:hostInc,
      levelParams:[],
      type:forallE(
        nameFromDotted('x'),
        constant(Nat),
        constant(Nat),
      ),
      isUnsafe:false,
    },
    binding:{source:'host-lib',importedName:'inc'},
  }];
  const encoded=encodeCheckedCoreAdmissions(admissions);
  equal(encoded.version,2);
  const decoded=decodeCheckedCoreAdmissions(encoded);
  const checked=admitCheckedCoreAdmissions(base,decoded);
  equal(checked.externals.length,1);
  equal(checked.environment.find(hostInc)?.kind,'axiom');
  equal(
    (checked.environment.find(hostInc) as {isUnsafe?:boolean})?.isUnsafe,
    false,
  );
}
console.log('ok - @proofscript/checked-core external admission codec');

{
  const base=new Environment();
  const Nat=nameFromDotted('Nat');
  base.add({
    kind:'axiom',
    name:Nat,
    levelParams:[],
    type:sort(levelSucc(levelZero)),
  });
  let rejected=false;
  try{
    admitCheckedCoreAdmissions(base,[{
      kind:'external',
      declaration:{
        kind:'axiom',
        name:nameFromDotted('badExternal'),
        levelParams:[],
        type:sort(levelZero),
        isUnsafe:false,
      },
      binding:{source:'host-lib',importedName:'badExternal'},
    }]);
  }catch(error){
    rejected=/first-order primitive runtime function/.test(String(error));
  }
  equal(rejected,true);
}
console.log('ok - @proofscript/checked-core rejects proof-valued external');
