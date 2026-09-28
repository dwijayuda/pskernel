import {existsSync} from 'node:fs';
import {readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {checkCanonicalAdmissions} from '../packages/pskernel-lean/host/node-provider.mjs';
import {packageBySection,parseImports} from './workspace-layout.mjs';

const scriptPath=fileURLToPath(import.meta.url);
const scriptDir=path.dirname(scriptPath);
const selfhostRoot=path.resolve(scriptDir,'..');

function stripImports(source){
  return source
    .split(/\r?\n/u)
    .filter(line=>!/^\s*import\s+[A-Za-z0-9_.]+\s*;?\s*$/u.test(line))
    .join('\n')
    .trim();
}

function findWorkspaceRoot(entryPath){
  let current=path.dirname(entryPath);
  for(let fuel=0;fuel<64;fuel+=1){
    if(
      existsSync(path.join(current,'packages'))&&
      existsSync(path.join(current,'stdlib'))
    ){
      return current;
    }
    const parent=path.dirname(current);
    if(parent===current)break;
    current=parent;
  }
  throw new Error(`PSC2_SELFHOST_WORKSPACE_NOT_FOUND: ${entryPath}`);
}

function moduleBasePath(workspaceRoot,moduleName){
  const parts=moduleName.split('.');
  if(parts[0]==='ProofScript'){
    return path.join(workspaceRoot,'stdlib',...parts);
  }
  if(parts[0]==='Ps'&&parts.length>=2){
    const packageName=packageBySection.get(parts[1]);
    if(!packageName){
      throw new Error(`PSC2_SELFHOST_UNKNOWN_PACKAGE: ${moduleName}`);
    }
    return path.join(
      workspaceRoot,
      'packages',
      packageName,
      'src',
      ...parts,
    );
  }
  return path.join(workspaceRoot,...parts);
}

function resolveModuleSource(workspaceRoot,moduleName){
  const base=moduleBasePath(workspaceRoot,moduleName);
  const leanPath=base+'.lean';
  const proofScriptPath=base+'.ps';
  const hasLean=existsSync(leanPath);
  const hasProofScript=existsSync(proofScriptPath);

  if(hasLean&&hasProofScript){
    if(moduleName.startsWith('Ps.')||moduleName.startsWith('ProofScript.')){
      return leanPath;
    }
    throw new Error(`PSC2_SELFHOST_SOURCE_AMBIGUITY: ${moduleName}`);
  }
  if(hasLean)return leanPath;
  if(hasProofScript)return proofScriptPath;
  throw new Error(`PSC2_SELFHOST_SOURCE_MISSING: ${moduleName}`);
}

function exceptTag(value){
  if(value===null||typeof value!=='object')return undefined;
  for(const symbol of Object.getOwnPropertySymbols(value)){
    const tag=value[symbol];
    if(tag==='ok'||tag==='error')return tag;
  }
  return undefined;
}

function unwrapExcept(value,stage){
  const tag=exceptTag(value);
  if(tag==='ok')return value.value;
  if(tag==='error'){
    throw new Error(
      `PSC2_SELFHOST_${stage.toUpperCase()}_FAILED: ${JSON.stringify(value.error)}`,
    );
  }
  throw new Error(`PSC2_SELFHOST_${stage.toUpperCase()}_RESULT_SHAPE`);
}

function requireCompilerApi(compiler){
  const required=[
    'PsCompilerSourceKind',
    'psCompilerTranslateSource',
    'psCompilerAdmissionsSource',
  ];
  for(const name of required){
    if(!(name in compiler)){
      throw new Error(`PSC2_SELFHOST_COMPILER_EXPORT_MISSING: ${name}`);
    }
  }
}

function sourceKind(compiler,sourcePath){
  if(sourcePath.endsWith('.lean')){
    return compiler.PsCompilerSourceKind.lean;
  }
  if(sourcePath.endsWith('.ps')){
    return compiler.PsCompilerSourceKind.proofScript;
  }
  throw new Error(`PSC2_SELFHOST_SOURCE_KIND: ${sourcePath}`);
}

async function flattenProject(compiler,entryPath){
  const workspaceRoot=findWorkspaceRoot(entryPath);
  const targetKind=sourceKind(compiler,entryPath);
  const visited=new Set();
  const ordered=[];

  async function visit(sourcePath){
    const absolute=path.resolve(sourcePath);
    if(visited.has(absolute))return;
    visited.add(absolute);

    if(!existsSync(absolute)){
      throw new Error(`PSC2_SELFHOST_SOURCE_MISSING: ${absolute}`);
    }

    const source=await readFile(absolute,'utf8');
    for(const moduleName of parseImports(source)){
      await visit(resolveModuleSource(workspaceRoot,moduleName));
    }
    ordered.push({path:absolute,source});
  }

  await visit(entryPath);

  const chunks=[];
  for(const item of ordered){
    const itemKind=sourceKind(compiler,item.path);
    const normalized=itemKind===targetKind
      ? item.source
      : unwrapExcept(
          compiler.psCompilerTranslateSource(
            itemKind,
            targetKind,
            item.source,
          ),
          'translate',
        );
    const body=stripImports(normalized);
    if(body.length>0)chunks.push(body);
  }

  return {
    moduleCount:ordered.length,
    sourceKind:targetKind,
    source:chunks.join('\n\n')+'\n',
  };
}

function kernelRejectionError(result){
  const kind=typeof result?.errorKind==='string'
    ? result.errorKind
    : 'unknown-error';
  const index=Number.isInteger(result?.declarationIndex)
    ? ` at declaration ${result.declarationIndex}`
    : '';
  const detail=typeof result?.message==='string'&&result.message.length>0
    ? `: ${result.message}`
    : '';
  return new Error(`PSC2_KERNEL_REJECTED: ${kind}${index}${detail}`);
}

export async function checkGeneratedProjectWithKernel({
  compilerPath,
  entryPath,
  kernel='lean434',
  binaryPath,
}){
  if(kernel!=='lean434'){
    throw new Error(`PSC2_KERNEL_PROVIDER: expected lean434, got ${kernel}`);
  }

  const resolvedCompiler=path.resolve(compilerPath);
  const resolvedEntry=path.resolve(entryPath);
  if(!existsSync(resolvedCompiler)){
    throw new Error(`PSC2_SELFHOST_COMPILER_MISSING: ${resolvedCompiler}`);
  }
  if(!resolvedEntry.endsWith('.ps')&&!resolvedEntry.endsWith('.lean')){
    throw new Error(`PSC2_SELFHOST_SOURCE_KIND: ${resolvedEntry}`);
  }

  const compiler=await import(pathToFileURL(resolvedCompiler).href);
  requireCompilerApi(compiler);
  const project=await flattenProject(compiler,resolvedEntry);
  const admissions=unwrapExcept(
    compiler.psCompilerAdmissionsSource(
      project.sourceKind,
      project.source,
    ),
    'admissions',
  );
  const result=checkCanonicalAdmissions(
    admissions,
    binaryPath===undefined?{}:{binaryPath},
  );
  if(!result.accepted){
    throw kernelRejectionError(result);
  }
  return result;
}

function usage(){
  return [
    'usage:',
    '  node scripts/check-with-generated.mjs <compiler.js> <entry.lean|entry.ps> --kernel lean434',
  ].join('\n');
}

function option(args,name){
  const index=args.indexOf(name);
  return index>=0?args[index+1]:undefined;
}

if(process.argv[1]&&path.resolve(process.argv[1])===scriptPath){
  const args=process.argv.slice(2);
  const compilerPath=args[0];
  const entryPath=args[1];
  const kernel=option(args,'--kernel');
  if(!compilerPath||!entryPath||!kernel){
    throw new Error(usage());
  }
  const result=await checkGeneratedProjectWithKernel({
    compilerPath:path.resolve(selfhostRoot,compilerPath),
    entryPath:path.resolve(selfhostRoot,entryPath),
    kernel,
  });
  process.stdout.write(
    `PSC2_KERNEL_CHECK: PASS (${result.provider} ${result.leanVersion} ${result.leanCommit})\n`,
  );
}
