
import {readFile} from 'node:fs/promises';
import {dirname,join,resolve} from 'node:path';
import {existsSync} from 'node:fs';

export interface PsConfig {
  readonly languageVersion:'0.7';
  readonly entry:string;
  readonly compilerOptions:{
    readonly outDir:string;
    readonly emitTypeScript:boolean;
    readonly declaration:boolean;
    readonly sourceMap:boolean;
  };
}

export const DEFAULT_CONFIG:PsConfig={
  languageVersion:'0.7',
  entry:'src/main.ps',
  compilerOptions:{
    outDir:'dist',
    emitTypeScript:true,
    declaration:true,
    sourceMap:true,
  },
};

export interface LoadedPsConfig {
  readonly path:string;
  readonly directory:string;
  readonly config:PsConfig;
}

export async function findPsConfig(start=process.cwd()):Promise<string|undefined>{
  let current=resolve(start);
  while(true){
    const candidate=join(current,'psconfig.json');
    if(existsSync(candidate))return candidate;
    const parent=dirname(current);
    if(parent===current)return undefined;
    current=parent;
  }
}

export async function loadPsConfig(project?:string):Promise<LoadedPsConfig>{
  let path:string|undefined;
  if(project!==undefined){
    const resolved=resolve(project);
    path=resolved.endsWith('.json')?resolved:join(resolved,'psconfig.json');
  }else{
    path=await findPsConfig();
  }
  if(path===undefined)throw new Error("PS_CLI_NO_CONFIG: no psconfig.json found; run 'psc init'");
  const parsed=JSON.parse(await readFile(path,'utf8')) as Partial<PsConfig>;
  if(parsed.languageVersion!==undefined&&parsed.languageVersion!=='0.7'){
    throw new Error("PS_CLI_CONFIG_VERSION: only languageVersion '0.7' is supported by this compiler milestone");
  }
  const compiler:Partial<PsConfig['compilerOptions']>=parsed.compilerOptions??{};
  const config:PsConfig={
    languageVersion:'0.7',
    entry:typeof parsed.entry==='string'?parsed.entry:DEFAULT_CONFIG.entry,
    compilerOptions:{
      outDir:typeof compiler.outDir==='string'?compiler.outDir:DEFAULT_CONFIG.compilerOptions.outDir,
      emitTypeScript:typeof compiler.emitTypeScript==='boolean'?compiler.emitTypeScript:DEFAULT_CONFIG.compilerOptions.emitTypeScript,
      declaration:typeof compiler.declaration==='boolean'?compiler.declaration:DEFAULT_CONFIG.compilerOptions.declaration,
      sourceMap:typeof compiler.sourceMap==='boolean'?compiler.sourceMap:DEFAULT_CONFIG.compilerOptions.sourceMap,
    },
  };
  return {path,directory:dirname(path),config};
}
