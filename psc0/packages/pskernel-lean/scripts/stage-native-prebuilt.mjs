import {createHash} from 'node:crypto';
import {
  chmod,
  copyFile,
  mkdir,
  readFile,
  rm,
  stat,
  writeFile,
} from 'node:fs/promises';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {supportedLeanKernelProviderTargets} from '../host/prebuilt.mjs';

const identity=Object.freeze({
  packageVersion:'4.34.0',
  protocol:'pskernel-lean/1',
  provider:'lean4-cpp',
  leanVersion:'4.34.0',
  leanCommit:'293d5d0c0c3f3dded4688b3ccd6a33939ac5102b',
  profile:'lean4.34-core',
});

function executableName(target){
  return target.startsWith('win32-')
    ? 'psc2_lean_kernel_provider.exe'
    : 'psc2_lean_kernel_provider';
}

function assertHealth(health){
  if(!health||typeof health!=='object'||Array.isArray(health)){
    throw new Error('provider health must be a JSON object');
  }
  if(health.status!=='ok'){
    throw new Error(`provider health status mismatch: ${String(health.status)}`);
  }
  for(const key of ['protocol','provider','leanVersion','leanCommit','profile']){
    if(health[key]!==identity[key]){
      throw new Error(
        `provider health ${key} mismatch: expected ${identity[key]}, got ${String(health[key])}`,
      );
    }
  }
}

export async function stageNativePrebuilt({
  target,
  binaryPath,
  sourceCommit,
  leanGithash,
  health,
  outDir,
}){
  if(!supportedLeanKernelProviderTargets.includes(target)){
    throw new Error(`unsupported Lean kernel prebuilt target: ${String(target)}`);
  }
  if(typeof sourceCommit!=='string'||!/^[0-9a-f]{40}$/u.test(sourceCommit)){
    throw new Error('source commit must be a 40-character lowercase git SHA');
  }
  if(leanGithash!==identity.leanCommit){
    throw new Error(
      `Lean githash mismatch: expected ${identity.leanCommit}, got ${String(leanGithash)}`,
    );
  }
  assertHealth(health);

  let sourceStat;
  try{
    sourceStat=await stat(binaryPath);
  }catch(cause){
    if(cause?.code==='ENOENT'){
      throw new Error(`provider executable is missing: ${binaryPath}`,{cause});
    }
    throw cause;
  }
  if(!sourceStat.isFile()){
    throw new Error(`provider executable is not a file: ${binaryPath}`);
  }

  const expectedName=executableName(target);
  if(path.basename(binaryPath)!==expectedName){
    throw new Error(
      `provider executable name mismatch for ${target}: expected ${expectedName}`,
    );
  }

  const bytes=await readFile(binaryPath);
  const sha256=createHash('sha256').update(bytes).digest('hex');
  const metadata={
    target,
    sourceCommit,
    packageVersion:identity.packageVersion,
    protocol:identity.protocol,
    provider:identity.provider,
    profile:identity.profile,
    leanVersion:identity.leanVersion,
    leanCommit:identity.leanCommit,
    executable:expectedName,
    sha256,
    size:bytes.length,
  };

  await rm(outDir,{recursive:true,force:true});
  await mkdir(outDir,{recursive:true});
  const stagedBinary=path.join(outDir,expectedName);
  await copyFile(binaryPath,stagedBinary);
  if(!target.startsWith('win32-')){
    await chmod(stagedBinary,sourceStat.mode);
  }
  await writeFile(
    path.join(outDir,'artifact.json'),
    `${JSON.stringify(metadata,null,2)}\n`,
  );
  return metadata;
}

function parseArgs(argv){
  const values={};
  for(let index=0;index<argv.length;index+=2){
    const flag=argv[index];
    const value=argv[index+1];
    if(!flag?.startsWith('--')||value===undefined){
      throw new Error(`invalid argument sequence near ${String(flag)}`);
    }
    values[flag.slice(2)]=value;
  }
  return values;
}

async function parseHealthJson(value){
  if(value.trimStart().startsWith('{')){
    return JSON.parse(value);
  }
  return JSON.parse(await readFile(value,'utf8'));
}

async function main(){
  const args=parseArgs(process.argv.slice(2));
  const required=['target','binary','source-commit','lean-githash','health-json','out'];
  for(const key of required){
    if(!args[key]){
      throw new Error(`missing --${key}`);
    }
  }
  const metadata=await stageNativePrebuilt({
    target:args.target,
    binaryPath:args.binary,
    sourceCommit:args['source-commit'],
    leanGithash:args['lean-githash'],
    health:await parseHealthJson(args['health-json']),
    outDir:args.out,
  });
  process.stdout.write(`${JSON.stringify(metadata)}\n`);
}

if(process.argv[1]&&pathToFileURL(path.resolve(process.argv[1])).href===import.meta.url){
  main().catch(error=>{
    process.stderr.write(`${error?.stack??error}\n`);
    process.exitCode=1;
  });
}
