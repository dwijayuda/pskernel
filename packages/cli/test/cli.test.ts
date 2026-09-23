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
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-verified-recursive-run-'),
  );
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
      'inductive PsList(α : Type) where { '+
      '| nil; | cons(head : α, tail : PsList(α)); } '+
      'function length {α : Type}(xs : PsList(α)) : Nat := '+
      'match xs with { | .nil => 0; '+
      '| .cons head tail => 1 + length(tail); }; '+
      'function main(x : Nat) : Nat := '+
      'length(PsList.cons(x, PsList.cons(x, PsList.nil)));\n',
      'utf8',
    );
    const result=await runCommand({
      project:directory,
      json:true,
      verified:true,
      passthrough:['9'],
    });
    equal(result.mainResult,'2');
    equal(result.semanticPipeline,'verified-core');
    equal(result.proofStatus,'kernel-verified');
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc verified structural recursion run filesystem pipeline');


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


{
  const result=compileVerifiedSource(
    'inductive MaybeNat where { | none; | some(value : Nat); } '+
    'function getOrZero(value : MaybeNat) : Nat := '+
    'match value with { | .none => 0; | .some x => x; };',
    'adt-match.ts',
  );
  const get=result.ir.declarations.find(
    (item)=>item.name==='getOrZero',
  );
  equal(get?.body.kind,'match');
  equal(result.typeScript.includes('case "none": return 0n;'),true);
  equal(
    result.typeScript.includes(
      'case "some": return ((x: bigint) => x)(__ps$match$0.value);',
    ),
    true,
  );
  equal(result.emitted.javascript.includes('case "some"'),true);
}
console.log('ok - psc verified ADT match pipeline');


{
  const result=compileVerifiedSource(
    'inductive PsOption(α : Type) where { | none; | some(value : α); } '+
  'const noneNat : PsOption(Nat) := PsOption.none; '+
  'const oneNat : PsOption(Nat) := PsOption.some(1);',
    'generic-adt.ts',
  );
  equal(result.typeScript.includes('export type PsOption<T0> ='),true);
  equal(result.typeScript.includes('PsOption["none"]<bigint>()'),true);
  equal(result.typeScript.includes('PsOption["some"]<bigint>(1n)'),true);
  equal(result.emitted.javascript.includes('<T0>'),false);
}
console.log('ok - psc verified generic ADT constructor pipeline');


{
  const result=compileVerifiedSource(
    'inductive PsOption(α : Type) where { | none; | some(value : α); } '+
  'function getOr {α : Type}'+
  '(value : PsOption(α), fallback : α) : α := '+
  'match value with { | .none => fallback; | .some x => x; };',
    'generic-adt-match.ts',
  );
  const getOr=result.ir.declarations.find(
    (item)=>item.name==='getOr',
  );
  equal(getOr?.body.kind,'match');
  equal(
    result.typeScript.includes(
      'function getOr<T0>(value: PsOption<T0>, fallback: T0): T0',
    ),
    true,
  );
  equal(result.typeScript.includes('(x: T0) => x'),true);
  equal(result.emitted.javascript.includes('case "some"'),true);
}
console.log('ok - psc verified generic ADT match pipeline');


{
  const result=compileVerifiedSource(
    'inductive PsList(α : Type) where { '+
    '| nil; | cons(head : α, tail : PsList(α)); } '+
    'function headOr {α : Type}'+
    '(value : PsList(α), fallback : α) : α := '+
    'match value with { | .nil => fallback; | .cons head tail => head; };',
    'recursive-adt.ts',
  );
  const list=result.checkedCore.environment.find(
    nameFromDotted('PsList'),
  );
  equal(list?.kind,'inductive');
  if(list?.kind==='inductive')equal(list.isRec,true);
  equal(
    result.typeScript.includes(
      'readonly tail: PsList<T0>;',
    ),
    true,
  );
  equal(
    result.typeScript.includes(
      'function headOr<T0>(value: PsList<T0>, fallback: T0): T0',
    ),
    true,
  );
  equal(result.typeScript.includes('case "cons"'),true);
  equal(result.emitted.javascript.includes('case "cons"'),true);
}
console.log('ok - psc verified recursive ADT match pipeline');


{
  const result=compileVerifiedSource(
    'inductive PsList(α : Type) where { '+
    '| nil; | cons(head : α, tail : PsList(α)); } '+
    'function length {α : Type}(xs : PsList(α)) : Nat := '+
    'match xs with { | .nil => 0; | .cons head tail => 1 + length(tail); };',
    'recursive-function.ts',
  );
  const length=result.ir.declarations.find(
    (item)=>item.name==='length',
  );
  equal(length?.body.kind,'match');
  equal(
    result.typeScript.includes(
      'function length<T0>(xs: PsList<T0>): bigint',
    ),
    true,
  );
  equal(
    result.typeScript.includes(
      '1n + length(tail)',
    ),
    true,
  );
  equal(
    result.emitted.javascript.includes('length(tail)'),
    true,
  );
}
console.log('ok - psc verified structural recursive function pipeline');


{
  const result=compileVerifiedSource(
    'inductive PsListInvariant(α : Type) where { '+
    '| nil; | cons(head : α, tail : PsListInvariant(α)); } '+
    'function countFrom {α : Type}'+
    '(base : Nat, xs : PsListInvariant(α)) : Nat := '+
    'match xs with { | .nil => base; '+
    '| .cons head tail => 1 + countFrom(base, tail); };',
    'invariant-recursion.ts',
  );
  equal(
    result.typeScript.includes(
      'function countFrom<T0>(base: bigint, xs: PsListInvariant<T0>): bigint',
    ),
    true,
  );
  equal(
    result.typeScript.includes('countFrom(base, tail)'),
    true,
  );
  equal(
    result.emitted.javascript.includes('countFrom(base, tail)'),
    true,
  );
}
console.log('ok - psc verified invariant structural recursion pipeline');


{
  const directory=await mkdtemp(
    join(tmpdir(),'proofscript-verified-invariant-recursion-'),
  );
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
      'inductive PsList(α : Type) where { '+
      '| nil; | cons(head : α, tail : PsList(α)); } '+
      'function countFrom {α : Type}(base : Nat, xs : PsList(α)) : Nat := '+
      'match xs with { | .nil => base; '+
      '| .cons head tail => 1 + countFrom(base, tail); }; '+
      'function main(x : Nat) : Nat := '+
      'countFrom(x, PsList.cons(x, PsList.cons(x, PsList.nil)));\n',
      'utf8',
    );
    const result=await runCommand({
      project:directory,
      json:true,
      verified:true,
      passthrough:['5'],
    });
    equal(result.mainResult,'7');
    equal(result.semanticPipeline,'verified-core');
    equal(result.proofStatus,'kernel-verified');
  }finally{
    await rm(directory,{recursive:true,force:true});
  }
}
console.log('ok - psc verified invariant structural recursion run');
