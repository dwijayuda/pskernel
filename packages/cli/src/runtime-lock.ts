import {createHash} from 'node:crypto';
import {readFile} from 'node:fs/promises';
import {join} from 'node:path';
import type {
  RuntimeDependencyPolicyReport,
} from './runtime-dependencies.js';
import {
  asRuntimeLockRecord,
  parseRuntimeLockDocument,
  parseRuntimeLockPackage,
  type RuntimeDependencyLockReport,
  type RuntimeLockPackage,
} from './runtime-lock-format.js';

export type {
  RuntimeDependencyLockReport,
  RuntimeLockEdge,
  RuntimeLockPackage,
} from './runtime-lock-format.js';

function mergeRequired(
  existing:RuntimeLockPackage|undefined,
  incoming:RuntimeLockPackage,
):RuntimeLockPackage {
  if(existing===undefined)return incoming;
  return existing.required||!incoming.required
    ?existing
    :{...existing,required:true};
}

async function installedIdentity(
  projectDirectory:string,
  pkg:RuntimeLockPackage,
):Promise<{readonly name:string;readonly version:string}|null> {
  const path=join(projectDirectory,...pkg.location.split('/'),'package.json');
  let text:string;
  try{
    text=await readFile(path,'utf8');
  }catch{
    if(!pkg.required)return null;
    throw new Error(
      "PS_RUNTIME_LOCK_INSTALLED_MISSING: required package '"+pkg.name+
      "' is not installed at '"+path+"'",
    );
  }
  let parsed:unknown;
  try{
    parsed=JSON.parse(text);
  }catch{
    throw new Error(
      "PS_RUNTIME_LOCK_INSTALLED_PACKAGE_JSON: '"+pkg.location+
      "' has invalid package.json",
    );
  }
  const record=asRuntimeLockRecord(parsed,pkg.location+' package.json');
  if(typeof record.name!=='string'||typeof record.version!=='string'){
    throw new Error(
      "PS_RUNTIME_LOCK_INSTALLED_PACKAGE_JSON: '"+pkg.location+
      "' must expose string name/version",
    );
  }
  return {name:record.name,version:record.version};
}

async function readRuntimeLock(
  projectDirectory:string,
):Promise<ReturnType<typeof parseRuntimeLockDocument>> {
  const lockPath=join(projectDirectory,'package-lock.json');
  let text:string;
  try{
    text=await readFile(lockPath,'utf8');
  }catch{
    throw new Error(
      "PS_RUNTIME_LOCK_MISSING: runtime externals require '"+lockPath+
      "' for verified build/run",
    );
  }
  return parseRuntimeLockDocument(text);
}

function directRoots(
  policy:RuntimeDependencyPolicyReport,
  packages:ReturnType<typeof parseRuntimeLockDocument>['packages'],
){
  const roots=new Map<string,string>();
  for(const dependency of policy.used){
    roots.set(dependency.packageRoot,dependency.version);
  }
  return [...roots.entries()].sort().map(([packageRoot,version])=>{
    const location='node_modules/'+packageRoot;
    if(packages[location]===undefined){
      throw new Error(
        "PS_RUNTIME_LOCK_ROOT_MISSING: package-lock.json has no entry for '"+
        packageRoot+"'",
      );
    }
    const descriptor=asRuntimeLockRecord(packages[location],location);
    if(descriptor.version!==version){
      throw new Error(
        "PS_RUNTIME_LOCK_ROOT_VERSION: '"+packageRoot+
        "' policy requires "+version+
        ', lockfile has '+String(descriptor.version),
      );
    }
    return {packageRoot,location};
  });
}

function transitiveClosure(
  packages:ReturnType<typeof parseRuntimeLockDocument>['packages'],
  roots:readonly {readonly packageRoot:string;readonly location:string}[],
):readonly RuntimeLockPackage[] {
  const closure=new Map<string,RuntimeLockPackage>();
  const queue=roots.map((root)=>({location:root.location,required:true}));
  while(queue.length>0){
    const next=queue.shift()!;
    const parsed=parseRuntimeLockPackage(
      packages,
      next.location,
      next.required,
    );
    const merged=mergeRequired(closure.get(next.location),parsed);
    const previous=closure.get(next.location);
    closure.set(next.location,merged);
    if(previous!==undefined&&previous.required===merged.required)continue;
    for(const edge of merged.dependencies){
      if(edge.target===null)continue;
      const edgeRequired=
        merged.required
        &&edge.kind!=='optional'
        &&edge.kind!=='peer-optional';
      queue.push({location:edge.target,required:edgeRequired});
    }
  }
  return [...closure.values()]
    .sort((a,b)=>a.location.localeCompare(b.location));
}

async function verifyInstalledClosure(
  projectDirectory:string,
  packages:readonly RuntimeLockPackage[],
):Promise<void> {
  for(const pkg of packages){
    const installed=await installedIdentity(projectDirectory,pkg);
    if(installed===null)continue;
    if(installed.name!==pkg.name){
      throw new Error(
        "PS_RUNTIME_LOCK_INSTALLED_IDENTITY: lock entry '"+pkg.location+
        "' resolves '"+pkg.name+"', installed metadata names '"+
        installed.name+"'",
      );
    }
    if(installed.version!==pkg.version){
      throw new Error(
        "PS_RUNTIME_LOCK_INSTALLED_VERSION: '"+pkg.name+
        "' lock version "+pkg.version+', installed '+installed.version,
      );
    }
  }
}

export async function verifyRuntimeDependencyLock(
  projectDirectory:string,
  policy:RuntimeDependencyPolicyReport,
):Promise<RuntimeDependencyLockReport|null> {
  if(policy.used.length===0)return null;
  const {packages}=await readRuntimeLock(projectDirectory);
  const roots=directRoots(policy,packages);
  const locked=transitiveClosure(packages,roots);
  await verifyInstalledClosure(projectDirectory,locked);

  const schema='proofscript-runtime-lock-v2' as const;
  const canonical={
    schema,
    lockfileVersion:3 as const,
    roots,
    packages:locked,
  };
  const integrity='sha256:'+createHash('sha256')
    .update(JSON.stringify(canonical),'utf8')
    .digest('hex');
  return {...canonical,integrity};
}
