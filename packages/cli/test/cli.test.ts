import {parseCommonArgs} from '../src/args.js';
import {compileVerifiedSource} from '../src/verified-pipeline.js';

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
