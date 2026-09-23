import {HELP} from '../src/help.js';
import {parseCommonArgs} from '../src/args.js';

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
  const args=parseCommonArgs(['src/main.ps','-p','demo','--json','--','41','true']);
  equal(args.entry,'src/main.ps');
  equal(args.project,'demo');
  equal(args.json,true);
  equal(args.passthrough.join(','),'41,true');
}
{
  const args=parseCommonArgs(['--project','psconfig.json']);
  equal(args.project,'psconfig.json');
  equal(args.json,false);
}
throws(()=>parseCommonArgs(['--wat']),/PS_CLI_UNKNOWN_OPTION/);
throws(()=>parseCommonArgs(['a.ps','b.ps']),/PS_CLI_USAGE/);
equal(HELP.includes('psc init'),true);
equal(HELP.includes('psc check'),true);
equal(HELP.includes('psc build'),true);
equal(HELP.includes('psc run'),true);

console.log('ok - psc CLI argument/UX contract');
