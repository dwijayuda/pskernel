import {
  VERIFIED_IR_INTRINSIC_ARITY,
  freeVariables,
  validateIrModule,
  validateVerifiedIrModule,
} from '../src/index.js';
function equal(a:unknown,b:unknown):void{if(a!==b)throw new Error(`expected ${String(b)}, got ${String(a)}`);}
{
  const expr={kind:'lambda',params:['x'],body:{kind:'call',fn:{kind:'var',name:'f'},args:[{kind:'var',name:'x'},{kind:'var',name:'y'}]}} as const;
  equal(freeVariables(expr).join(','),'f,y');
}
equal(validateIrModule({name:'M',bindings:[{name:'main',value:{kind:'literal',value:1}}]}),true);
let threw=false;try{validateIrModule({name:'M',bindings:[{name:'x',value:{kind:'literal',value:1}},{name:'x',value:{kind:'literal',value:2}}]});}catch{threw=true;}
equal(threw,true);
console.log('ok - @proofscript/compiler-ir foundation');


{
  const module={
    kind:'proofscript-verified-ir' as const,
    declarations:[{
      name:'identity',
      typeParameters:[{name:'T0'}],
      parameters:[{
        name:'x',
        type:{kind:'typeParameter' as const,name:'T0'},
      }],
      resultType:{kind:'typeParameter' as const,name:'T0'},
      body:{kind:'var' as const,name:'x'},
    }],
  };
  equal(validateVerifiedIrModule(module),true);
}
console.log('ok - @proofscript/compiler-ir verified dependent-core IR schema');


{
  const module={
    kind:'proofscript-verified-ir' as const,
    declarations:[{
      name:'add',
      typeParameters:[],
      parameters:[
        {name:'x',type:{kind:'primitive' as const,name:'Nat' as const}},
        {name:'y',type:{kind:'primitive' as const,name:'Nat' as const}},
      ],
      resultType:{kind:'primitive' as const,name:'Nat' as const},
      body:{
        kind:'intrinsic' as const,
        operation:'nat.add' as const,
        args:[
          {kind:'var' as const,name:'x'},
          {kind:'var' as const,name:'y'},
        ],
      },
    }],
  };
  equal(validateVerifiedIrModule(module),true);
}
console.log('ok - @proofscript/compiler-ir verified Nat intrinsic');


{
  equal(VERIFIED_IR_INTRINSIC_ARITY['bool.not'],1);
  equal(VERIFIED_IR_INTRINSIC_ARITY['char.ofNat'],1);
  equal(VERIFIED_IR_INTRINSIC_ARITY['char.toNat'],1);
  equal(VERIFIED_IR_INTRINSIC_ARITY['string.singleton'],1);
  equal(VERIFIED_IR_INTRINSIC_ARITY['string.length'],1);
  equal(VERIFIED_IR_INTRINSIC_ARITY['string.push'],2);
  equal(VERIFIED_IR_INTRINSIC_ARITY['string.append'],2);
  equal(VERIFIED_IR_INTRINSIC_ARITY['nat.sub'],2);
  let invalid=false;
  try{
    validateVerifiedIrModule({
      kind:'proofscript-verified-ir',
      declarations:[{
        name:'badNot',
        typeParameters:[],
        parameters:[{
          name:'x',
          type:{kind:'primitive',name:'Bool'},
        }],
        resultType:{kind:'primitive',name:'Bool'},
        body:{
          kind:'intrinsic',
          operation:'bool.not',
          args:[
            {kind:'var',name:'x'},
            {kind:'var',name:'x'},
          ],
        },
      }],
    });
  }catch(error){
    invalid=/expects 1 argument/.test(String(error));
  }
  equal(invalid,true);
}
console.log('ok - @proofscript/compiler-ir verified intrinsic contract');

{
  const module={
    kind:'proofscript-verified-ir' as const,
    imports:[{
      localName:'hostLength',
      source:'host-lib',
      importedName:'length',
      type:{
        kind:'function' as const,
        parameters:[{kind:'primitive' as const,name:'String' as const}],
        result:{kind:'primitive' as const,name:'Nat' as const},
      },
    }],
    declarations:[{
      name:'main',
      typeParameters:[],
      parameters:[{
        name:'value',
        type:{kind:'primitive' as const,name:'String' as const},
      }],
      resultType:{kind:'primitive' as const,name:'Nat' as const},
      body:{
        kind:'call' as const,
        fn:{kind:'var' as const,name:'hostLength'},
        args:[{kind:'var' as const,name:'value'}],
      },
    }],
  };
  equal(validateVerifiedIrModule(module),true);

  let collision=false;
  try{
    validateVerifiedIrModule({
      ...module,
      declarations:[{
        ...module.declarations[0]!,
        name:'hostLength',
      }],
    });
  }catch(error){
    collision=/duplicate verified IR value/.test(String(error));
  }
  equal(collision,true);
}
console.log('ok - @proofscript/compiler-ir external import boundary');
