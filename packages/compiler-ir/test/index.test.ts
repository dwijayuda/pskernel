import {
  VERIFIED_IR_INTRINSIC_ARITY,
  freeVariables,
  lowerCheckedSoftwareModule,
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
  const ir=lowerCheckedSoftwareModule({
    kind:'checked-v061-software-module',
    inductives:[],
    structures:[],
    declarations:[{
      kind:'function',
      name:'incTwice',
      params:[{name:'x',type:'Nat'}],
      resultType:'Nat',
      body:{
        kind:'let',name:'y',declaredType:'Nat',resultType:'Nat',
        value:{kind:'binary',operator:'+',resultType:'Nat',left:{kind:'reference',name:'x',resultType:'Nat'},right:{kind:'nat',value:1n,resultType:'Nat'}},
        body:{kind:'binary',operator:'+',resultType:'Nat',left:{kind:'reference',name:'y',resultType:'Nat'},right:{kind:'nat',value:1n,resultType:'Nat'}},
      },
    }],
  });
  equal(ir.kind,'proofscript-software-ir');
  equal(ir.declarations[0]?.body.kind,'let');
}
console.log('ok - @proofscript/compiler-ir software lowering');

{
  const ir=lowerCheckedSoftwareModule({
    kind:'checked-v061-software-module',
    inductives:[],
    structures:[],
    declarations:[{
      kind:'const',name:'increment',params:[],
      resultType:{kind:'function',parameter:'Nat',result:'Nat'},
      body:{
        kind:'lambda',
        binders:[{name:'x',type:'Nat'}],
        resultType:{kind:'function',parameter:'Nat',result:'Nat'},
        body:{
          kind:'binary',operator:'+',resultType:'Nat',
          left:{kind:'reference',name:'x',resultType:'Nat'},
          right:{kind:'nat',value:1n,resultType:'Nat'},
        },
      },
    }],
  });
  equal(ir.declarations[0]?.body.kind,'lambda');
}
console.log('ok - @proofscript/compiler-ir software lambda lowering');

{
  const ir=lowerCheckedSoftwareModule({
    kind:'checked-v061-software-module',
    inductives:[],
    structures:[],
    declarations:[{
      kind:'function',name:'choose',params:[{name:'flag',type:'Bool'}],resultType:'Nat',
      body:{
        kind:'match',resultType:'Nat',
        scrutinee:{kind:'reference',name:'flag',resultType:'Bool'},
        alternatives:[
          {pattern:{kind:'bool',value:true},body:{kind:'nat',value:1n,resultType:'Nat'}},
          {pattern:{kind:'bool',value:false},body:{kind:'nat',value:2n,resultType:'Nat'}},
        ],
      },
    }],
  });
  equal(ir.declarations[0]?.body.kind,'match');
}
console.log('ok - @proofscript/compiler-ir Bool match lowering');

{
  const userType={kind:'nominal',name:'User'} as const;
  const ir=lowerCheckedSoftwareModule({
    kind:'checked-v061-software-module',
    inductives:[],
    structures:[{name:'User',fields:[{name:'name',type:'String'},{name:'age',type:'Nat'}]}],
    declarations:[{
      kind:'const',name:'ada',params:[],resultType:userType,
      body:{
        kind:'record',structure:'User',resultType:userType,
        fields:[
          {name:'name',value:{kind:'string',value:'Ada',resultType:'String'}},
          {name:'age',value:{kind:'nat',value:33n,resultType:'Nat'}},
        ],
      },
    }],
  });
  equal(ir.structures[0]?.name,'User');
  equal(ir.declarations[0]?.body.kind,'record');
}
console.log('ok - @proofscript/compiler-ir nominal structure lowering');

{
  const maybe={kind:'nominal',name:'MaybeNat'} as const;
  const ir=lowerCheckedSoftwareModule({
    kind:'checked-v061-software-module',
    structures:[],
    inductives:[{
      name:'MaybeNat',
      constructors:[
        {name:'none',qualifiedName:'MaybeNat.none',fields:[]},
        {name:'some',qualifiedName:'MaybeNat.some',fields:[{name:'value',type:'Nat'}]},
      ],
    }],
    declarations:[{
      kind:'const',name:'one',params:[],resultType:maybe,
      body:{
        kind:'constructor',inductive:'MaybeNat',constructor:'some',resultType:maybe,
        fields:[{name:'value',value:{kind:'nat',value:1n,resultType:'Nat'}}],
      },
    }],
  });
  equal(ir.inductives[0]?.name,'MaybeNat');
  equal(ir.declarations[0]?.body.kind,'constructor');
}
console.log('ok - @proofscript/compiler-ir inductive ADT lowering');


{
  const ir=lowerCheckedSoftwareModule({
    kind:'checked-v061-software-module',
    structures:[],
    inductives:[],
    declarations:[{
      kind:'function',
      name:'f',
      params:[{name:'x',type:'Nat'}],
      resultType:'Nat',
      body:{
        kind:'call',
        callee:'helper',
        args:[{kind:'reference',name:'x',resultType:'Nat'}],
        callStyle:'direct',
        resultType:'Nat',
      },
      whereDeclarations:[{
        name:'helper',
        params:[{name:'y',type:'Nat'}],
        resultType:'Nat',
        body:{
          kind:'binary',
          operator:'+',
          resultType:'Nat',
          left:{kind:'reference',name:'y',resultType:'Nat'},
          right:{kind:'nat',value:1n,resultType:'Nat'},
        },
      }],
    }],
  });
  equal(ir.declarations[0]?.whereDeclarations?.[0]?.name,'helper');
}
console.log('ok - @proofscript/compiler-ir where helper lowering');


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
  equal(VERIFIED_IR_INTRINSIC_ARITY['nat.sub'],2);
  equal(VERIFIED_IR_INTRINSIC_ARITY['uint32.add'],2);
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

{
  const module={
    kind:'proofscript-verified-ir' as const,
    declarations:[{
      name:'add32',
      typeParameters:[],
      parameters:[
        {name:'x',type:{kind:'primitive' as const,name:'UInt32' as const}},
        {name:'y',type:{kind:'primitive' as const,name:'UInt32' as const}},
      ],
      resultType:{kind:'primitive' as const,name:'UInt32' as const},
      body:{
        kind:'intrinsic' as const,
        operation:'uint32.add' as const,
        args:[
          {kind:'var' as const,name:'x'},
          {kind:'var' as const,name:'y'},
        ],
      },
    }],
  };
  equal(validateVerifiedIrModule(module),true);
}
console.log('ok - @proofscript/compiler-ir verified UInt wrapping add intrinsic');
