import {mkdtemp,rm,writeFile,mkdir} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {parseCommonArgs} from '../src/args.js';
import {compileVerifiedSource} from '../src/verified-pipeline.js';
import {parseVerifiedRuntimeArg,prepareVerifiedMainArguments} from '../src/verified-runtime.js';
import {runCommand} from '../src/commands/run.js';

function equal(actual:unknown,expected:unknown):void{
  if(actual!==expected)throw new Error('expected '+String(expected)+', got '+String(actual));
}
function throws(fn:()=>unknown,pattern:RegExp):void{
  try{fn();}catch(error){
    if(pattern.test(error instanceof Error?error.message:String(error)))return;
    throw error;
  }
  throw new Error('expected throw '+String(pattern));
}

{
  const args=parseCommonArgs(['src/main.ps','-p','demo','--verified','--json','--','41','true']);
  equal(args.entry,'src/main.ps');
  equal(args.project,'demo');
  equal(args.json,true);
  equal(args.verified,true);
  equal(args.passthrough.join(','),'41,true');
}
{
  const args=parseCommonArgs(['--project','psconfig.json']);
  equal(args.project,'psconfig.json');
  equal(args.json,false);
  equal(args.verified,false);
}
throws(()=>parseCommonArgs(['--wat']),/PS_CLI_UNKNOWN_OPTION/);
throws(()=>parseCommonArgs(['a.ps','b.ps']),/PS_CLI_USAGE/);
console.log('ok - psc CLI argument/UX contract');


{
  const result=compileVerifiedSource(
    'function identity {α : Type}(x : α) : α := x;',
    'identity.ts',
  );
  equal(result.checkedCore.kind,'proofscript-checked-core');
  equal(
    result.typeScript.includes('identity<T0>(x: T0): T0'),
    true,
  );
  equal(result.emitted.javascript.includes('function identity(x)'),true);
  equal(result.emitted.javascript.includes('T0'),false);
}
console.log('ok - psc verified checked-core compiler pipeline');


{
  const result=compileVerifiedSource(
    'function add(x : Nat, y : Nat) : Nat := x + y; '+
    'function twice(x : Nat) : Nat := add(x, x);',
    'nat.ts',
  );
  equal(result.checkedCore.definitions.length,2);
  equal(result.typeScript.includes('return (x + y);'),true);
  equal(result.typeScript.includes('return add(x, x);'),true);
  equal(result.emitted.javascript.includes('function twice(x)'),true);
}
console.log('ok - psc verified Nat source pipeline');


{
  equal(parseVerifiedRuntimeArg('42',{kind:'primitive',name:'Nat'}),42n);
  equal(parseVerifiedRuntimeArg('-42',{kind:'primitive',name:'Int'}),-42n);
  equal(parseVerifiedRuntimeArg('true',{kind:'primitive',name:'Bool'}),true);
  equal(parseVerifiedRuntimeArg('hello',{kind:'primitive',name:'String'}),'hello');
  equal(parseVerifiedRuntimeArg('()',{kind:'primitive',name:'Unit'}),undefined);
  throws(
    ()=>parseVerifiedRuntimeArg('-1',{kind:'primitive',name:'Nat'}),
    /Nat argument cannot be negative/,
  );
  throws(
    ()=>parseVerifiedRuntimeArg('yes',{kind:'primitive',name:'Bool'}),
    /Bool argument/,
  );
  const args=prepareVerifiedMainArguments({
    name:'main',
    typeParameters:[],
    parameters:[
      {name:'x',type:{kind:'primitive',name:'Nat'}},
      {name:'flag',type:{kind:'primitive',name:'Bool'}},
    ],
    resultType:{kind:'primitive',name:'Nat'},
    body:{kind:'var',name:'x'},
  },['7','false']);
  equal(args[0],7n);
  equal(args[1],false);
}
console.log('ok - psc verified runtime ABI');


{
  const directory=await mkdtemp(join(tmpdir(),'proofscript-verified-run-'));
  try{
    await mkdir(join(directory,'src'),{recursive:true});
    await writeFile(
      join(directory,'psconfig.json'),
      JSON.stringify({
        languageVersion:'0.7',
        entry:'src/main.ps',
        compilerOptions:{
          outDir:'dist',
          emitTypeScript:true,
          declaration:true,
          sourceMap:true,
        },
      },null,2)+'\n',
      'utf8',
    );
    await writeFile(
      join(directory,'src','main.ps'),
      'function main(x : Nat) : Nat := x + x;\n',
      'utf8',
    );
    const result=await runCommand({
      project:directory,
      json:true,
      verified:true,
      passthrough:['21'],
    });
    equal(result.mainResult,'42');
    equal(result.semanticPipeline,'verified-core');
    equal(result.proofStatus,'kernel-verified');
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc verified run filesystem pipeline');


{
  const result=compileVerifiedSource(
    'function min(x : Nat, y : Nat) : Nat := '+
    'if (x <= y) { x } else { y };',
    'if.ts',
  );
  equal(
    result.typeScript.includes('return ((x <= y) ? x : y);'),
    true,
  );
  equal(result.emitted.javascript.includes('x <= y ? x : y'),true);
}
console.log('ok - psc verified proposition-based if pipeline');


{
  const result=compileVerifiedSource(
    'structure User where { age : Nat; } '+
    'function make(age : Nat) : User := { age := age : User }; '+
    'function get(user : User) : Nat := user.age;',
    'structure.ts',
  );
  equal(result.checkedCore.structures.length,1);
  equal(result.ir.structures?.length,1);
  equal(result.typeScript.includes('export interface User {'),true);
  equal(
    result.typeScript.includes(
      'function make(age: bigint): User',
    ),
    true,
  );
  equal(
    result.typeScript.includes(
      'return { [__ps$brand$0]: true, age: age };',
    ),
    true,
  );
  equal(result.typeScript.includes('return user.age;'),true);
  equal(result.emitted.javascript.includes('Symbol("ProofScript.User")'),true);
  equal(result.emitted.javascript.includes('function get(user)'),true);
  equal(result.emitted.declaration.includes('export interface User'),true);
}
{
  throws(
    ()=>compileVerifiedSource(
      'structure SigmaBox where { T : Type; value : T; } '+
      'function makeSigma(x : Nat) : SigmaBox := '+
      '{ T := Nat, value := x : SigmaBox };',
      'dependent-structure.ts',
    ),
    /PS_ERASE_DEPENDENT_STRUCTURE_FIELD_UNSUPPORTED/,
  );
}
console.log('ok - psc verified nominal structure pipeline');


{
  const result=compileVerifiedSource(
    'inductive MaybeNat where { | none; | some(value : Nat); } '+
    'const noneValue : MaybeNat := MaybeNat.none; '+
    'const oneValue : MaybeNat := MaybeNat.some(1);',
    'adt.ts',
  );
  equal(result.checkedCore.inductives.length,1);
  equal(result.ir.inductives?.length,1);
  equal(result.ir.inductives?.[0]?.name,'MaybeNat');
  equal(result.typeScript.includes('export type MaybeNat ='),true);
  equal(
    result.typeScript.includes(
      'unique symbol = Symbol("ProofScript.MaybeNat.tag")',
    ),
    true,
  );
  equal(
    result.typeScript.includes(
      '"some": (__field0: bigint): MaybeNat',
    ),
    true,
  );
  equal(
    result.typeScript.includes(
      'export const oneValue: MaybeNat = MaybeNat["some"](1n);',
    ),
    true,
  );
  equal(
    result.emitted.javascript.includes('Symbol("ProofScript.MaybeNat.tag")'),
    true,
  );
  equal(
    result.emitted.declaration.includes('export type MaybeNat ='),
    true,
  );
  equal(
    result.emitted.declaration.includes('export declare const MaybeNat'),
    true,
  );
}
console.log('ok - psc verified ADT constructor pipeline');
