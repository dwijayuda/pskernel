import {pathToFileURL} from 'node:url';
import type {SoftwareType} from '@proofscript/language';
import {buildCommand} from './build.js';
import type {CommonArgs} from '../types.js';

function parseRuntimeArg(value:string,type:SoftwareType):unknown{
  switch(type){
    case 'Nat':{
      const n=BigInt(value);
      if(n<0n)throw new Error('PS_RUN_ARG: Nat argument cannot be negative');
      return n;
    }
    case 'Int':return BigInt(value);
    case 'Bool':
      if(value==='true')return true;
      if(value==='false')return false;
      throw new Error("PS_RUN_ARG: Bool argument must be 'true' or 'false'");
    case 'String':return value;
    case 'Unit':return undefined;
  }
}

export async function runCommand(common:CommonArgs){
  const build=await buildCommand(common);
  const main=build.checked.declarations.find((decl)=>decl.name==='main');
  if(main===undefined)throw new Error("PS_RUN_NO_MAIN: no declaration named 'main'");
  if(main.params.length!==common.passthrough.length){
    throw new Error('PS_RUN_ARITY: main expects '+main.params.length+' arguments, got '+common.passthrough.length);
  }

  const mod=await import(pathToFileURL(build.jsPath).href+'?v='+Date.now()) as Record<string,unknown>;
  const fn=mod.main;
  if(typeof fn!=='function')throw new Error('PS_RUN_MAIN_EXPORT: generated module does not export callable main');

  const args=main.params.map((param,index)=>parseRuntimeArg(common.passthrough[index]!,param.type));
  const value=await (fn as (...values:unknown[])=>unknown)(...args);
  if(value!==undefined&&!common.json)console.log(typeof value==='bigint'?value.toString():value);

  return {
    ...build.report,
    command:'run',
    mainResult:value===undefined?null:(typeof value==='bigint'?value.toString():value),
  };
}
