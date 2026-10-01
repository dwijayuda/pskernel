import {rm} from 'node:fs/promises';
import {resolve} from 'node:path';
import {loadPsConfig} from '../config.js';
import type {CommonArgs} from '../types.js';

export async function cleanCommand(common:CommonArgs){
  const loaded=await loadPsConfig(common.project);
  const outDir=resolve(loaded.directory,loaded.config.compilerOptions.outDir);
  await rm(outDir,{recursive:true,force:true});
  return {ok:true,command:'clean',removed:outDir};
}
