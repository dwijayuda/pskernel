import {pathToFileURL} from 'node:url';
import type {SoftwareType} from '@proofscript/language';
import {buildCommand} from './build.js';
import type {CommonArgs} from '../types.js';
import {
  encodeVerifiedRuntimeResult,
  prepareVerifiedMainArguments,
} from '../verified-runtime.js';

function parseRuntimeArg(value:string,type:SoftwareType):unknown{
  if(typeof type!=='string'){
    throw new Error(
      'PS_RUN_ARG: function-typed main parameters are not supported by CLI argument conversion',
    );
  }
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

function displayRuntimeValue(value:unknown):unknown {
  if(value===undefined)return null;
  return typeof value==='bigint'?value.toString():value;
}

export async function runCommand(common:CommonArgs){
  const build=await buildCommand(common);
  const mod=await import(
    pathToFileURL(build.jsPath).href+'?v='+Date.now()
  ) as Record<string,unknown>;
  const fn=mod.main;
  if(typeof fn!=='function'){
    throw new Error(
      'PS_RUN_MAIN_EXPORT: generated module does not export callable main',
    );
  }

  let args:readonly unknown[];
  if(common.verified){
    const main=build.verifiedIr?.declarations.find(
      (declaration)=>declaration.name==='main',
    );
    if(main===undefined){
      throw new Error("PS_RUN_NO_MAIN: no executable declaration named 'main'");
    }
    if(build.verifiedIr===undefined){
      throw new Error(
        'PS_RUN_VERIFIED_IR_MISSING: verified build did not retain compiler IR',
      );
    }
    args=prepareVerifiedMainArguments(
      main,
      common.passthrough,
      {module:build.verifiedIr,runtimeExports:mod},
    );
  }else{
    const main=build.checked?.declarations.find(
      (declaration)=>declaration.name==='main',
    );
    if(main===undefined){
      throw new Error("PS_RUN_NO_MAIN: no declaration named 'main'");
    }
    if(main.params.length!==common.passthrough.length){
      throw new Error(
        'PS_RUN_ARITY: main expects '+main.params.length+
        ' arguments, got '+common.passthrough.length,
      );
    }
    args=main.params.map(
      (param,index)=>parseRuntimeArg(common.passthrough[index]!,param.type),
    );
  }

  const value=await (fn as (...values:unknown[])=>unknown)(...args);
  let displayed:unknown;
  if(common.verified){
    const main=build.verifiedIr?.declarations.find(
      (declaration)=>declaration.name==='main',
    );
    if(main===undefined||build.verifiedIr===undefined){
      throw new Error(
        'PS_RUN_VERIFIED_RESULT_TYPE: verified main result metadata is unavailable',
      );
    }
    displayed=encodeVerifiedRuntimeResult(
      value,
      main.resultType,
      build.verifiedIr,
    );
  }else{
    displayed=displayRuntimeValue(value);
  }

  if(value!==undefined&&!common.json){
    console.log(
      typeof displayed==='object'&&displayed!==null
        ?JSON.stringify(displayed)
        :displayed,
    );
  }

  return {
    ...build.report,
    command:'run',
    mainResult:displayed,
  };
}
