import type {TranslationTarget} from '@proofscript/syntax';
import type {CommonArgs,TranslateArgs} from './types.js';

export function parseCommonArgs(args:readonly string[]):CommonArgs {
  const split=args.indexOf('--');
  const own=split<0?[...args]:args.slice(0,split);
  const passthrough=split<0?[]:args.slice(split+1);
  let entry:string|undefined;
  let project:string|undefined;
  let json=false;
  let verified=false;

  for(let i=0;i<own.length;i+=1){
    const arg=own[i]!;
    if(arg==='-p'||arg==='--project'){
      const value=own[++i];
      if(value===undefined)throw new Error('PS_CLI_OPTION_VALUE: --project requires a value');
      project=value;
    }else if(arg==='--json'){
      json=true;
    }else if(arg==='--verified'){
      verified=true;
    }else if(arg.startsWith('-')){
      throw new Error("PS_CLI_UNKNOWN_OPTION: unknown option '"+arg+"'");
    }else if(entry===undefined){
      entry=arg;
    }else{
      throw new Error("PS_CLI_USAGE: unexpected argument '"+arg+"'");
    }
  }

  return {
    ...(entry===undefined?{}:{entry}),
    ...(project===undefined?{}:{project}),
    json,
    verified,
    passthrough,
  };
}


function parseTranslationTarget(value:string|undefined):TranslationTarget {
  if(value==='ps'||value==='lean')return value;
  if(value===undefined){
    throw new Error('PS_CLI_TRANSLATE_TARGET: --to requires ps or lean');
  }
  throw new Error(
    "PS_CLI_TRANSLATE_TARGET: unsupported target '"+value+
    "'; expected ps or lean",
  );
}

export function parseTranslateArgs(args:readonly string[]):TranslateArgs {
  if(args.includes('--')){
    throw new Error(
      'PS_CLI_TRANSLATE_PASSTHROUGH: translate does not accept runtime arguments',
    );
  }
  const commonArgs:string[]=[];
  let target:TranslationTarget|undefined;
  for(let index=0;index<args.length;index+=1){
    const arg=args[index]!;
    if(arg==='--to'){
      if(target!==undefined){
        throw new Error(
          'PS_CLI_TRANSLATE_TARGET: --to may be specified only once',
        );
      }
      target=parseTranslationTarget(args[++index]);
      continue;
    }
    commonArgs.push(arg);
  }
  if(target===undefined){
    throw new Error(
      'PS_CLI_TRANSLATE_TARGET: translate requires --to ps or --to lean',
    );
  }
  const common=parseCommonArgs(commonArgs);
  if(common.verified){
    throw new Error(
      'PS_CLI_TRANSLATE_VERIFIED: source translation does not use --verified',
    );
  }
  if(common.json){
    throw new Error(
      'PS_CLI_TRANSLATE_JSON: source translation writes canonical source text',
    );
  }
  return {...common,target};
}
