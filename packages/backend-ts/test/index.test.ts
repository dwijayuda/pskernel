import {compileTypeScript,emitExpression,emitModule,emitVerifiedTypeScript} from '../src/index.js';
function equal(a:unknown,b:unknown):void{if(a!==b)throw new Error(`expected ${String(b)}, got ${String(a)}`);}
equal(emitExpression({kind:'literal',value:3n}),'3n');
equal(emitExpression({kind:'call',fn:{kind:'var',name:'f'},args:[{kind:'literal',value:1}]}),'f(1)');
const output=emitModule({name:'Demo',bindings:[{name:'main',value:{kind:'ctor',tag:'Some',fields:[{kind:'literal',value:1}]}}]});
equal(output.includes('export const main'),true);
equal(output.includes('"Some"'),true);
console.log('ok - @proofscript/backend-ts foundation');

{
  const source=emitVerifiedTypeScript({
    kind:'proofscript-verified-ir',
    declarations:[{
      name:'identity',
      typeParameters:[{name:'T0'}],
      parameters:[{
        name:'x',
        type:{kind:'typeParameter',name:'T0'},
      }],
      resultType:{kind:'typeParameter',name:'T0'},
      body:{kind:'var',name:'x'},
    }],
  });
  equal(source.includes(
    'export function identity<T0>(x: T0): T0 { return x; }',
  ),true);
  const compiled=compileTypeScript(source,'verified-identity.ts');
  equal(
    compiled.javascript.includes('export function identity(x)'),
    true,
  );
  equal(compiled.javascript.includes('T0'),false);
  equal(
    compiled.declaration.includes(
      'export declare function identity<T0>(x: T0): T0;',
    ),
    true,
  );
}
console.log('ok - @proofscript/backend-ts verified generic TypeScript emission');


{
  const source=emitVerifiedTypeScript({
    kind:'proofscript-verified-ir',
    declarations:[
      {
        name:'add',
        typeParameters:[],
        parameters:[
          {name:'x',type:{kind:'primitive',name:'Nat'}},
          {name:'y',type:{kind:'primitive',name:'Nat'}},
        ],
        resultType:{kind:'primitive',name:'Nat'},
        body:{
          kind:'intrinsic',
          operation:'nat.add',
          args:[
            {kind:'var',name:'x'},
            {kind:'var',name:'y'},
          ],
        },
      },
      {
        name:'sub',
        typeParameters:[],
        parameters:[
          {name:'x',type:{kind:'primitive',name:'Nat'}},
          {name:'y',type:{kind:'primitive',name:'Nat'}},
        ],
        resultType:{kind:'primitive',name:'Nat'},
        body:{
          kind:'intrinsic',
          operation:'nat.sub',
          args:[
            {kind:'var',name:'x'},
            {kind:'var',name:'y'},
          ],
        },
      },
    ],
  });
  equal(source.includes('return (x + y);'),true);
  equal(source.includes('__ps_a >= __ps_b ? __ps_a - __ps_b : 0n'),true);
  const compiled=compileTypeScript(source,'verified-nat.ts');
  equal(compiled.javascript.includes('x + y'),true);
  equal(compiled.javascript.includes('__ps_a >= __ps_b'),true);
}
console.log('ok - @proofscript/backend-ts verified Nat intrinsic emission');


{
  const source=emitVerifiedTypeScript({
    kind:'proofscript-verified-ir',
    structures:[{
      name:'User',
      fields:[{
        name:'age',
        type:{kind:'primitive',name:'Nat'},
      }],
    }],
    declarations:[
      {
        name:'make',
        typeParameters:[],
        parameters:[{
          name:'age',
          type:{kind:'primitive',name:'Nat'},
        }],
        resultType:{kind:'named',name:'User',args:[]},
        body:{
          kind:'record',
          structure:'User',
          fields:[{
            name:'age',
            value:{kind:'var',name:'age'},
          }],
        },
      },
      {
        name:'get',
        typeParameters:[],
        parameters:[{
          name:'user',
          type:{kind:'named',name:'User',args:[]},
        }],
        resultType:{kind:'primitive',name:'Nat'},
        body:{
          kind:'projection',
          target:{kind:'var',name:'user'},
          field:'age',
        },
      },
    ],
  });
  equal(source.includes('export interface User {'),true);
  equal(source.includes('unique symbol = Symbol("ProofScript.User")'),true);
  equal(source.includes('return { [__ps$brand$0]: true, age: age };'),true);
  equal(source.includes('return user.age;'),true);
  const compiled=compileTypeScript(source,'verified-structure.ts');
  equal(compiled.declaration.includes('export interface User'),true);
  equal(compiled.javascript.includes('Symbol("ProofScript.User")'),true);
}
console.log('ok - @proofscript/backend-ts verified nominal structure emission');


{
  const source=emitVerifiedTypeScript({
    kind:'proofscript-verified-ir',
    inductives:[{
      name:'MaybeNat',
      constructors:[
        {name:'none',fields:[]},
        {
          name:'some',
          fields:[{
            name:'value',
            type:{kind:'primitive',name:'Nat'},
          }],
        },
      ],
    }],
    declarations:[
      {
        name:'noneValue',
        typeParameters:[],
        parameters:[],
        resultType:{kind:'named',name:'MaybeNat',args:[]},
        body:{
          kind:'constructor',
          inductive:'MaybeNat',
          constructor:'none',
          fields:[],
        },
      },
      {
        name:'oneValue',
        typeParameters:[],
        parameters:[],
        resultType:{kind:'named',name:'MaybeNat',args:[]},
        body:{
          kind:'constructor',
          inductive:'MaybeNat',
          constructor:'some',
          fields:[{
            name:'value',
            value:{kind:'literal',value:1n},
          }],
        },
      },
    ],
  });
  equal(source.includes('export type MaybeNat ='),true);
  equal(source.includes('unique symbol = Symbol("ProofScript.MaybeNat.tag")'),true);
  equal(source.includes('"none": { [__ps$tag$0]: "none" } as MaybeNat'),true);
  equal(source.includes('"some": (__field0: bigint): MaybeNat'),true);
  equal(source.includes('MaybeNat["some"](1n)'),true);
  const compiled=compileTypeScript(source,'verified-adt.ts');
  equal(compiled.declaration.includes('export type MaybeNat ='),true);
  equal(compiled.declaration.includes('export declare const MaybeNat'),true);
}
console.log('ok - @proofscript/backend-ts verified ADT constructor emission');


{
  const source=emitVerifiedTypeScript({
    kind:'proofscript-verified-ir',
    inductives:[{
      name:'MaybeNat',
      constructors:[
        {name:'none',fields:[]},
        {
          name:'some',
          fields:[{
            name:'value',
            type:{kind:'primitive',name:'Nat'},
          }],
        },
      ],
    }],
    declarations:[{
      name:'getOrZero',
      typeParameters:[],
      parameters:[{
        name:'value',
        type:{kind:'named',name:'MaybeNat',args:[]},
      }],
      resultType:{kind:'primitive',name:'Nat'},
      body:{
        kind:'match',
        inductive:'MaybeNat',
        scrutinee:{kind:'var',name:'value'},
        alternatives:[
          {
            constructor:'none',
            bindings:[],
            body:{kind:'literal',value:0n},
          },
          {
            constructor:'some',
            bindings:[{
              field:'value',
              name:'x',
              type:{kind:'primitive',name:'Nat'},
            }],
            body:{kind:'var',name:'x'},
          },
        ],
      },
    }],
  });
  equal(source.includes('switch (__ps$match$0[__ps$tag$0])'),true);
  equal(source.includes('case "none": return 0n;'),true);
  equal(
    source.includes(
      'case "some": return ((x: bigint) => x)(__ps$match$0.value);',
    ),
    true,
  );
  const compiled=compileTypeScript(source,'verified-match.ts');
  equal(compiled.javascript.includes('switch (__ps$match$0[__ps$tag$0])'),true);
}
console.log('ok - @proofscript/backend-ts verified ADT match emission');


{
  const source=emitVerifiedTypeScript({
    kind:'proofscript-verified-ir',
    inductives:[{
      name:'PsOption',
      typeParameters:[{name:'T0'}],
      constructors:[
        {name:'none',fields:[]},
        {
          name:'some',
          fields:[{
            name:'value',
            type:{kind:'typeParameter',name:'T0'},
          }],
        },
      ],
    }],
    declarations:[
      {
        name:'noneNat',
        typeParameters:[],
        parameters:[],
        resultType:{
          kind:'named',
          name:'PsOption',
          args:[{kind:'primitive',name:'Nat'}],
        },
        body:{
          kind:'constructor',
          inductive:'PsOption',
          constructor:'none',
          typeArgs:[{kind:'primitive',name:'Nat'}],
          fields:[],
        },
      },
      {
        name:'oneNat',
        typeParameters:[],
        parameters:[],
        resultType:{
          kind:'named',
          name:'PsOption',
          args:[{kind:'primitive',name:'Nat'}],
        },
        body:{
          kind:'constructor',
          inductive:'PsOption',
          constructor:'some',
          typeArgs:[{kind:'primitive',name:'Nat'}],
          fields:[{
            name:'value',
            value:{kind:'literal',value:1n},
          }],
        },
      },
    ],
  });
  equal(source.includes('export type PsOption<T0> ='),true);
  equal(
    source.includes(
      '"none": <T0>(): PsOption<T0> =>',
    ),
    true,
  );
  equal(
    source.includes(
      '"some": <T0>(__field0: T0): PsOption<T0> =>',
    ),
    true,
  );
  equal(source.includes('PsOption["none"]<bigint>()'),true);
  equal(source.includes('PsOption["some"]<bigint>(1n)'),true);
  const compiled=compileTypeScript(source,'generic-adt.ts');
  equal(compiled.javascript.includes('<T0>'),false);
  equal(compiled.declaration.includes('type PsOption<T0>'),true);
}
console.log('ok - @proofscript/backend-ts verified generic ADT TypeScript emission');


{
  const source=emitVerifiedTypeScript({
    kind:'proofscript-verified-ir',
    structures:[{
      name:'Box',
      typeParameters:[{name:'T0'}],
      fields:[{
        name:'value',
        type:{kind:'typeParameter',name:'T0'},
      }],
    }],
    declarations:[{
      name:'unbox',
      typeParameters:[{name:'T0'}],
      parameters:[{
        name:'box',
        type:{
          kind:'named',
          name:'Box',
          args:[{kind:'typeParameter',name:'T0'}],
        },
      }],
      resultType:{kind:'typeParameter',name:'T0'},
      body:{
        kind:'projection',
        target:{kind:'var',name:'box'},
        field:'value',
      },
    }],
  });
  equal(source.includes('export interface Box<T0> {'),true);
  equal(
    source.includes(
      'export function unbox<T0>(box: Box<T0>): T0',
    ),
    true,
  );
  const compiled=compileTypeScript(source,'generic-structure.ts');
  equal(compiled.javascript.includes('function unbox(box)'),true);
  equal(compiled.declaration.includes('interface Box<T0>'),true);
}
console.log('ok - @proofscript/backend-ts generic structure TypeScript emission');

{
  const source=emitVerifiedTypeScript({
    kind:'proofscript-verified-ir',
    imports:[{
      localName:'hostLength',
      source:'host-lib',
      importedName:'length',
      type:{
        kind:'function',
        parameters:[{kind:'primitive',name:'String'}],
        result:{kind:'primitive',name:'Nat'},
      },
    }],
    declarations:[{
      name:'main',
      typeParameters:[],
      parameters:[{
        name:'value',
        type:{kind:'primitive',name:'String'},
      }],
      resultType:{kind:'primitive',name:'Nat'},
      body:{
        kind:'call',
        fn:{kind:'var',name:'hostLength'},
        args:[{kind:'var',name:'value'}],
      },
    }],
  });
  equal(
    source.includes('import { length as hostLength } from "host-lib";'),
    true,
  );
  equal(
    source.includes(
      'export function main(value: string): bigint { return hostLength(value); }',
    ),
    true,
  );
}
console.log('ok - @proofscript/backend-ts external ESM import emission');
