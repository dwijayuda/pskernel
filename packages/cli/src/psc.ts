import {LEAN_SEMANTICS_VERSION,PROOFSCRIPT_SPEC_VERSION} from '@proofscript/syntax';
import {parseCommonArgs} from './args.js';
import {HELP,PSC_VERSION} from './help.js';
import {outputResult} from './output.js';
import {buildCommand} from './commands/build.js';
import {checkCommand} from './commands/check.js';
import {cleanCommand} from './commands/clean.js';
import {emitLeanCommand} from './commands/emit-lean.js';
import {initCommand} from './commands/init.js';
import {runCommand} from './commands/run.js';

export {HELP,PSC_VERSION};

export async function runPsc(argv:readonly string[]):Promise<number>{
  try{
    const [command,...rest]=argv;
    if(command===undefined||command==='--help'||command==='-h'||command==='help'){
      console.log(HELP);
      return 0;
    }
    if(command==='--version'||command==='-v'||command==='version'){
      console.log('psc '+PSC_VERSION+' (ProofScript '+PROOFSCRIPT_SPEC_VERSION+', Lean '+LEAN_SEMANTICS_VERSION+')');
      return 0;
    }
    if(command==='init'){
      outputResult(await initCommand(rest),false);
      return 0;
    }

    const common=parseCommonArgs(rest);
    if(command==='check')outputResult(await checkCommand(common),common.json);
    else if(command==='build')outputResult((await buildCommand(common)).report,common.json);
    else if(command==='run'){
      const result=await runCommand(common);
      if(common.json)console.log(JSON.stringify(result,null,2));
    }else if(command==='emit-lean'){
      process.stdout.write(await emitLeanCommand(common));
    }else if(command==='clean'){
      outputResult(await cleanCommand(common),common.json);
    }else{
      throw new Error("PS_CLI_UNKNOWN_COMMAND: unknown command '"+command+"'; run 'psc --help'");
    }
    return 0;
  }catch(error){
    console.error(error instanceof Error?error.message:String(error));
    return 1;
  }
}
