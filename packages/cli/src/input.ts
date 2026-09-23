import {readFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {DEFAULT_CONFIG,findPsConfig,loadPsConfig} from './config.js';
import type {CommonArgs,ResolvedInput} from './types.js';

export async function resolveInput(common:CommonArgs):Promise<ResolvedInput>{
  const discovered=common.project===undefined?await findPsConfig():undefined;
  const loaded=common.project!==undefined||discovered!==undefined
    ? await loadPsConfig(common.project)
    : common.entry!==undefined
      ? {path:'<defaults>',directory:process.cwd(),config:{...DEFAULT_CONFIG,entry:common.entry}}
      : await loadPsConfig();

  const sourcePath=resolve(loaded.directory,common.entry??loaded.config.entry);
  const source=await readFile(sourcePath,'utf8');
  return {loaded,sourcePath,source};
}
