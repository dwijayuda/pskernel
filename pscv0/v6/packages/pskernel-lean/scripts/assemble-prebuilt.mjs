import {createHash} from 'node:crypto';
import {
  chmod,
  copyFile,
  mkdir,
  readFile,
  readdir,
  rename,
  rm,
  stat,
  writeFile,
} from 'node:fs/promises';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {supportedLeanKernelProviderTargets} from '../host/prebuilt.mjs';

const repositoryFileSizeLimit=100*1024*1024;
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

function assertMetadataIdentity(metadata,dirName){
  for(const key of ['packageVersion','protocol','provider','leanVersion','leanCommit','profile']){
    if(metadata?.[key]!==identity[key]){
      throw new Error(
        `staged artifact ${dirName} ${key} mismatch: expected ${identity[key]}, got ${String(metadata?.[key])}`,
      );
    }
  }
  if(typeof metadata.sourceCommit!=='string'||!/^[0-9a-f]{40}$/u.test(metadata.sourceCommit)){
    throw new Error(`staged artifact ${dirName} sourceCommit is invalid`);
  }
}

async function loadAndValidateArtifacts(artifactsDir){
  const entries=(await readdir(artifactsDir,{withFileTypes:true}))
    .filter(entry=>entry.isDirectory())
    .sort((left,right)=>left.name.localeCompare(right.name));
  const byTarget=new Map();
  let sourceCommit=null;

  for(const entry of entries){
    const dir=path.join(artifactsDir,entry.name);
    let metadata;
    try{
      metadata=JSON.parse(await readFile(path.join(dir,'artifact.json'),'utf8'));
    }catch(cause){
      throw new Error(`staged artifact ${entry.name} has invalid artifact.json`,{cause});
    }
    const target=metadata?.target;
    if(!supportedLeanKernelProviderTargets.includes(target)){
      throw new Error(`unsupported staged target: ${String(target)}`);
    }
    if(byTarget.has(target)){
      throw new Error(`duplicate staged target: ${target}`);
    }
    assertMetadataIdentity(metadata,entry.name);
    if(sourceCommit===null){
      sourceCommit=metadata.sourceCommit;
    }else if(metadata.sourceCommit!==sourceCommit){
      throw new Error(
        `staged artifact ${target} sourceCommit mismatch: expected ${sourceCommit}, got ${metadata.sourceCommit}`,
      );
    }

    const expectedExecutable=executableName(target);
    if(metadata.executable!==expectedExecutable||
      path.basename(metadata.executable)!==metadata.executable){
      throw new Error(`staged artifact ${target} executable name mismatch`);
    }
    if(!Number.isSafeInteger(metadata.size)||metadata.size<0){
      throw new Error(`staged artifact ${target} size metadata is invalid`);
    }
    if(metadata.size>=repositoryFileSizeLimit){
      throw new Error(
        `staged artifact ${target} exceeds repository size limit: ${metadata.size} bytes >= ${repositoryFileSizeLimit}`,
      );
    }
    const binaryPath=path.join(dir,metadata.executable);
    let binaryStat;
    try{
      binaryStat=await stat(binaryPath);
    }catch(cause){
      if(cause?.code==='ENOENT'){
        throw new Error(`staged artifact ${target} executable is missing`,{cause});
      }
      throw cause;
    }
    if(!binaryStat.isFile()){
      throw new Error(`staged artifact ${target} executable is not a file`);
    }
    const bytes=await readFile(binaryPath);
    const actualSha=createHash('sha256').update(bytes).digest('hex');
    if(metadata.sha256!==actualSha){
      throw new Error(
        `staged artifact ${target} checksum mismatch: expected ${String(metadata.sha256)}, got ${actualSha}`,
      );
    }
    if(metadata.size!==bytes.length){
      throw new Error(
        `staged artifact ${target} size mismatch: expected ${String(metadata.size)}, got ${bytes.length}`,
      );
    }
    byTarget.set(target,{metadata,binaryPath});
  }

  const actualTargets=[...byTarget.keys()].sort();
  const expectedTargets=[...supportedLeanKernelProviderTargets].sort();
  if(JSON.stringify(actualTargets)!==JSON.stringify(expectedTargets)){
    throw new Error(
      `artifact target set mismatch: expected ${expectedTargets.join(', ')}, got ${actualTargets.join(', ')}`,
    );
  }
  return {byTarget,sourceCommit};
}

export async function assemblePrebuilt({artifactsDir,packageRoot}){
  const {byTarget,sourceCommit}=await loadAndValidateArtifacts(artifactsDir);
  const targets={};
  for(const target of supportedLeanKernelProviderTargets){
    const {metadata}=byTarget.get(target);
    targets[target]={
      path:`prebuilt/${target}/${metadata.executable}`,
      sha256:metadata.sha256,
      size:metadata.size,
      sourceCommit,
    };
  }
  const manifest={
    schema:1,
    package:'@proofscript/pskernel-lean',
    packageVersion:identity.packageVersion,
    protocol:identity.protocol,
    provider:identity.provider,
    leanVersion:identity.leanVersion,
    leanCommit:identity.leanCommit,
    profile:identity.profile,
    sourceCommit,
    targets,
  };

  await mkdir(packageRoot,{recursive:true});
  const nonce=`${process.pid}-${Date.now()}`;
  const tempPrebuilt=path.join(packageRoot,`.prebuilt.tmp-${nonce}`);
  const tempManifest=path.join(packageRoot,`.PREBUILT_MANIFEST.tmp-${nonce}.json`);
  await rm(tempPrebuilt,{recursive:true,force:true});
  await mkdir(tempPrebuilt,{recursive:true});
  try{
    for(const target of supportedLeanKernelProviderTargets){
      const {metadata,binaryPath}=byTarget.get(target);
      const targetDir=path.join(tempPrebuilt,target);
      await mkdir(targetDir,{recursive:true});
      const destination=path.join(targetDir,metadata.executable);
      await copyFile(binaryPath,destination);
      if(!target.startsWith('win32-')){
        await chmod(destination,0o755);
      }
    }
    await writeFile(tempManifest,`${JSON.stringify(manifest,null,2)}\n`);

    const finalPrebuilt=path.join(packageRoot,'prebuilt');
    const finalManifest=path.join(packageRoot,'PREBUILT_MANIFEST.json');
    await rm(finalPrebuilt,{recursive:true,force:true});
    await rename(tempPrebuilt,finalPrebuilt);
    await rm(finalManifest,{force:true});
    await rename(tempManifest,finalManifest);
  }catch(error){
    await rm(tempPrebuilt,{recursive:true,force:true});
    await rm(tempManifest,{force:true});
    throw error;
  }
  return manifest;
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

async function main(){
  const args=parseArgs(process.argv.slice(2));
  if(!args.artifacts)throw new Error('missing --artifacts');
  if(!args['package-root'])throw new Error('missing --package-root');
  const manifest=await assemblePrebuilt({
    artifactsDir:args.artifacts,
    packageRoot:args['package-root'],
  });
  process.stdout.write(`${JSON.stringify(manifest)}\n`);
}

if(process.argv[1]&&pathToFileURL(path.resolve(process.argv[1])).href===import.meta.url){
  main().catch(error=>{
    process.stderr.write(`${error?.stack??error}\n`);
    process.exitCode=1;
  });
}
