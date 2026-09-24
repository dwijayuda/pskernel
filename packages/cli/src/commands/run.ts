import {pathToFileURL} from 'node:url';
import {buildCommand} from './build.js';
import type {
  CommonArgs,
  VerifiedRunReport,
} from '../types.js';
import {
  encodeVerifiedRuntimeResult,
  prepareVerifiedMainArguments,
} from '../verified-runtime.js';

export async function runCommand(
  common:CommonArgs,
):Promise<VerifiedRunReport>{
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

  const main=build.verifiedIr.declarations.find(
    (declaration)=>declaration.name==='main',
  );
  if(main===undefined){
    throw new Error("PS_RUN_NO_MAIN: no executable declaration named 'main'");
  }
  const args=prepareVerifiedMainArguments(
    main,
    common.passthrough,
    {module:build.verifiedIr,runtimeExports:mod},
  );

  const value=await (fn as (...values:unknown[])=>unknown)(...args);
  const displayed=encodeVerifiedRuntimeResult(
    value,
    main.resultType,
    build.verifiedIr,
  );

  if(value!==undefined&&!common.json){
    console.log(
      typeof displayed==='object'&&displayed!==null
        ?JSON.stringify(displayed)
        :displayed,
    );
  }

  return {
    ...build.report,
    command:'run' as const,
    mainResult:displayed,
  };
}
