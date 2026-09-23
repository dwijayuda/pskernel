import type {CommonArgs} from './types.js';

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
