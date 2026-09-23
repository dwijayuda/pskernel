
import {mkdir,readFile,rm,writeFile} from 'node:fs/promises';
import {existsSync} from 'node:fs';
import {basename,dirname,extname,join,resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
import {
  LEAN_SEMANTICS_VERSION,
  PROOFSCRIPT_SPEC_VERSION,
  lowerV061ModuleToLean,
  parseV061Module,
} from '@proofscript/syntax';
import {checkV061SoftwareModule,type CheckedSoftwareModule,type SoftwareType} from '@proofscript/language';
import {compileTypeScript,emitV061TypeScript} from '@proofscript/backend-ts';
import {DEFAULT_CONFIG,findPsConfig,loadPsConfig,type LoadedPsConfig} from './config.js';

export const PSC_VERSION='0.1.0';

export const HELP=`ProofScript compiler

Usage:
  psc init [dir] [--lib] [-y]
  psc check [entry.ps] [-p, --project <path>] [--json]
  psc build [entry.ps] [-p, --project <path>] [--json]
  psc run [entry.ps] [-p, --project <path>] [--json] [-- <args...>]
  psc emit-lean [entry.ps] [-p, --project <path>]
  psc clean [-p, --project <path>]
  psc --version
  psc --help

Commands:
  init       Create a ProofScript project and psconfig.json
  check      Parse and type-check without writing build outputs
  build      Check, emit canonical Lean + TypeScript, then let TypeScript emit JS/.d.ts
  run        Build and invoke exported main with arguments after --
  emit-lean  Print canonical Lean lowering for the supported reference slice
  clean      Remove the configured output directory

Current language track:
  ProofScript v0.7 with v0.6.1 compiler-ready surface baseline
  Lean semantic target: ${LEAN_SEMANTICS_VERSION}
`;

interface CommonArgs {
  readonly entry?:string;
  readonly project?:string;
  readonly json:boolean;
  readonly passthrough:readonly string[];
}

function parseCommon(args:readonly string[]):CommonArgs{
  const split=args.indexOf('--');
  const own=split<0?[...args]:args.slice(0,split);
  const passthrough=split<0?[]:args.slice(split+1);
  let entry:string|undefined,project:string|undefined,json=false;
  for(let i=0;i<own.length;i+=1){
    const arg=own[i]!;
    if(arg==='-p'||arg==='--project'){
      const value=own[++i];
      if(value===undefined)throw new Error('PS_CLI_OPTION_VALUE: --project requires a value');
      project=value;
    }else if(arg==='--json'){
      json=true;
    }else if(arg.startsWith('-')){
      throw new Error("PS_CLI_UNKNOWN_OPTION: unknown option '"+arg+"'");
    }else if(entry===undefined){
      entry=arg;
    }else{
      throw new Error("PS_CLI_USAGE: unexpected argument '"+arg+"'");
    }
  }
  return {entry,project,json,passthrough};
}

async function resolveInput(common:CommonArgs):Promise<{loaded:LoadedPsConfig;sourcePath:string;source:string}>{
  const discovered=common.project!==undefined?undefined:await findPsConfig();
  const loaded=common.project!==undefined||discovered!==undefined
    ? await loadPsConfig(common.project)
    : common.entry!==undefined
      ? {path:'<defaults>',directory:process.cwd(),config:{...DEFAULT_CONFIG,entry:common.entry}}
      : await loadPsConfig();
  const sourcePath=resolve(loaded.directory,common.entry??loaded.config.entry);
  const source=await readFile(sourcePath,'utf8');
  return {loaded,sourcePath,source};
}

function checkSource(source:string){
  const surface=parseV061Module(source);
  const checked=checkV061SoftwareModule(surface);
  return {surface,checked,lean:lowerV061ModuleToLean(surface)};
}

export async function checkCommand(common:CommonArgs){
  const input=await resolveInput(common);
  const result=checkSource(input.source);
  return {
    ok:true,
    command:'check',
    source:input.sourcePath,
    declarations:result.checked.declarations.length,
    featureIds:result.surface.featureIds,
    languageVersion:PROOFSCRIPT_SPEC_VERSION,
    surfaceBaseline:'0.6.1-compiler-ready',
    leanSemantics:LEAN_SEMANTICS_VERSION,
    proofStatus:'software-typechecked-only',
  };
}

export interface BuildResult {
  readonly report:Record<string,unknown>;
  readonly checked:CheckedSoftwareModule;
  readonly jsPath:string;
}

export async function buildCommand(common:CommonArgs):Promise<BuildResult>{
  const input=await resolveInput(common);
  const result=checkSource(input.source);
  const tsSource=emitV061TypeScript(result.checked);
  const stem=extname(input.sourcePath)==='.ps'?basename(input.sourcePath,'.ps'):basename(input.sourcePath);
  const outDir=resolve(input.loaded.directory,input.loaded.config.compilerOptions.outDir);
  await mkdir(outDir,{recursive:true});

  const compiled=compileTypeScript(tsSource,stem+'.ts');
  const tsPath=join(outDir,stem+'.ts');
  const jsPath=join(outDir,stem+'.js');
  const dtsPath=join(outDir,stem+'.d.ts');
  const leanPath=join(outDir,stem+'.lean');
  const mapPath=join(outDir,stem+'.js.map');
  const manifestPath=join(outDir,stem+'.proofscript.json');

  const report={
    ok:true,
    command:'build',
    source:input.sourcePath,
    outputDirectory:outDir,
    artifacts:{
      typescript:tsPath,
      javascript:jsPath,
      declarations:dtsPath,
      sourceMap:compiled.sourceMap===undefined?null:mapPath,
      lean:leanPath,
      manifest:manifestPath,
    },
    declarations:result.checked.declarations.length,
    featureIds:result.surface.featureIds,
    languageVersion:PROOFSCRIPT_SPEC_VERSION,
    surfaceBaseline:'0.6.1-compiler-ready',
    leanSemantics:LEAN_SEMANTICS_VERSION,
    typescriptVersion:compiled.typescriptVersion,
    proofStatus:'software-typechecked-only',
    proofStatusDetail:'The current software subset is structurally lowered and type-checked; theorem/proof declarations are not yet elaborated to pskernel.',
  };

  const writes=[
    writeFile(tsPath,tsSource,'utf8'),
    writeFile(jsPath,compiled.javascript,'utf8'),
    writeFile(dtsPath,compiled.declaration,'utf8'),
    writeFile(leanPath,result.lean,'utf8'),
    writeFile(manifestPath,JSON.stringify(report,null,2)+'\n','utf8'),
  ];
  if(compiled.sourceMap!==undefined)writes.push(writeFile(mapPath,compiled.sourceMap,'utf8'));
  await Promise.all(writes);
  return {report,checked:result.checked,jsPath};
}

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
  return {...build.report,command:'run',mainResult:value===undefined?null:(typeof value==='bigint'?value.toString():value)};
}

async function initCommand(args:readonly string[]){
  let target='.',lib=false;
  for(const arg of args){
    if(arg==='--lib')lib=true;
    else if(arg==='-y'||arg==='--yes')continue;
    else if(arg.startsWith('-'))throw new Error("PS_CLI_UNKNOWN_OPTION: unknown option '"+arg+"'");
    else if(target==='.')target=arg;
    else throw new Error("PS_CLI_USAGE: unexpected argument '"+arg+"'");
  }
  const dir=resolve(target);
  await mkdir(join(dir,'src'),{recursive:true});
  const configPath=join(dir,'psconfig.json');
  if(existsSync(configPath))throw new Error('PS_INIT_EXISTS: psconfig.json already exists in '+dir);

  const entry=lib?'src/index.ps':'src/main.ps';
  const source=lib
    ? 'const answer : Nat := 42;\nfunction add(x : Nat, y : Nat) : Nat := x + y;\n'
    : 'const answer : Nat := 42;\nfunction main(x : Nat) : Nat := x + answer;\n';
  const packageJson={
    name:basename(dir),
    private:true,
    type:'module',
    scripts:lib
      ? {check:'psc check',build:'psc build'}
      : {check:'psc check',build:'psc build',start:'psc run -- 1'},
  };
  const config={...DEFAULT_CONFIG,entry};

  await Promise.all([
    writeFile(configPath,JSON.stringify(config,null,2)+'\n','utf8'),
    writeFile(join(dir,entry),source,'utf8'),
    writeFile(join(dir,'package.json'),JSON.stringify(packageJson,null,2)+'\n','utf8'),
    writeFile(join(dir,'.gitignore'),'dist/\n.proofscript/\nnode_modules/\n','utf8'),
  ]);
  return {ok:true,command:'init',directory:dir,entry,kind:lib?'library':'application'};
}

async function cleanCommand(common:CommonArgs){
  const loaded=await loadPsConfig(common.project);
  const outDir=resolve(loaded.directory,loaded.config.compilerOptions.outDir);
  await rm(outDir,{recursive:true,force:true});
  return {ok:true,command:'clean',removed:outDir};
}

function output(result:unknown,json:boolean):void{
  if(json)console.log(JSON.stringify(result,null,2));
  else if(typeof result==='object'&&result!==null){
    const value=result as Record<string,unknown>;
    if(value.command==='check')console.log('✓ ProofScript check passed ('+String(value.declarations)+' declarations)');
    else if(value.command==='build')console.log('✓ Built '+String(value.source)+' → '+String(value.outputDirectory));
    else if(value.command==='init')console.log('✓ Initialized ProofScript '+String(value.kind)+' in '+String(value.directory));
    else if(value.command==='clean')console.log('✓ Removed '+String(value.removed));
  }
}

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
      output(await initCommand(rest),false);
      return 0;
    }
    const common=parseCommon(rest);
    if(command==='check')output(await checkCommand(common),common.json);
    else if(command==='build')output((await buildCommand(common)).report,common.json);
    else if(command==='run'){
      const result=await runCommand(common);
      if(common.json)console.log(JSON.stringify(result,null,2));
    }
    else if(command==='emit-lean'){
      const input=await resolveInput(common);
      process.stdout.write(lowerV061ModuleToLean(parseV061Module(input.source)));
    }
    else if(command==='clean')output(await cleanCommand(common),common.json);
    else throw new Error("PS_CLI_UNKNOWN_COMMAND: unknown command '"+command+"'; run 'psc --help'");
    return 0;
  }catch(error){
    console.error(error instanceof Error?error.message:String(error));
    return 1;
  }
}
