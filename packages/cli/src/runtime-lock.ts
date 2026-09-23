import {createHash} from 'node:crypto';
import {readFile} from 'node:fs/promises';
import {join} from 'node:path';
import type {
  RuntimeDependencyPolicyReport,
} from './runtime-dependencies.js';

type JsonRecord=Record<string,unknown>;

export interface RuntimeLockEdge {
  readonly kind:'dependency'|'optional'|'peer'|'peer-optional';
  readonly name:string;
  readonly spec:string;
  readonly target:string|null;
}

export interface RuntimeLockPackage {
  readonly location:string;
  readonly name:string;
  readonly version:string;
  readonly resolved:string;
  readonly integrity:string;
  readonly required:boolean;
  readonly dependencies:readonly RuntimeLockEdge[];
}

export interface RuntimeDependencyLockReport {
  readonly schema:'proofscript-runtime-lock-v1';
  readonly lockfileVersion:3;
  readonly integrity:string;
  readonly roots:readonly {
    readonly source:string;
    readonly location:string;
  }[];
  readonly packages:readonly RuntimeLockPackage[];
}

function asRecord(value:unknown,label:string):JsonRecord {
  if(typeof value!=='object'||value===null||Array.isArray(value)){
    throw new Error('PS_RUNTIME_LOCK_FORMAT: '+label+' must be an object');
  }
  return value as JsonRecord;
}

function stringMap(value:unknown,label:string):Record<string,string> {
  if(value===undefined)return {};
  const record=asRecord(value,label);
  const out:Record<string,string>={};
  for(const [name,spec] of Object.entries(record)){
    if(typeof spec!=='string'){
      throw new Error(
        'PS_RUNTIME_LOCK_FORMAT: '+label+"['"+name+"'] must be a string",
      );
    }
    out[name]=spec;
  }
  return out;
}

function packageNameFromLocation(location:string):string {
  const marker='node_modules/';
  const index=location.lastIndexOf(marker);
  if(index<0){
    throw new Error(
      "PS_RUNTIME_LOCK_LOCATION: invalid package location '"+location+"'",
    );
  }
  const tail=location.slice(index+marker.length);
  const parts=tail.split('/');
  if(parts[0]?.startsWith('@')){
    if(parts.length!==2){
      throw new Error(
        "PS_RUNTIME_LOCK_LOCATION: invalid scoped package location '"+location+"'",
      );
    }
    return parts[0]+'/'+parts[1];
  }
  if(parts.length!==1||parts[0]?.length===0){
    throw new Error(
      "PS_RUNTIME_LOCK_LOCATION: invalid package location '"+location+"'",
    );
  }
  return parts[0]!;
}

function dependencyCandidates(
  owner:string,
  name:string,
):readonly string[] {
  const suffix='node_modules/'+name;
  const candidates:string[]=[];
  let current=owner;
  while(current.length>0){
    candidates.push(current+'/'+suffix);
    const index=current.lastIndexOf('/node_modules/');
    current=index<0?'':current.slice(0,index);
  }
  candidates.push(suffix);
  return [...new Set(candidates)];
}

function resolveDependencyLocation(
  packages:JsonRecord,
  owner:string,
  name:string,
):string|undefined {
  return dependencyCandidates(owner,name).find(
    (candidate)=>packages[candidate]!==undefined,
  );
}

function dependencyEdges(
  packages:JsonRecord,
  owner:string,
  descriptor:JsonRecord,
):readonly RuntimeLockEdge[] {
  const required=stringMap(
    descriptor.dependencies,
    owner+'.dependencies',
  );
  const optional=stringMap(
    descriptor.optionalDependencies,
    owner+'.optionalDependencies',
  );
  const peers=stringMap(
    descriptor.peerDependencies,
    owner+'.peerDependencies',
  );
  const peerMeta=descriptor.peerDependenciesMeta===undefined
    ?{}
    :asRecord(
      descriptor.peerDependenciesMeta,
      owner+'.peerDependenciesMeta',
    );
  const names=[...new Set([
    ...Object.keys(required),
    ...Object.keys(optional),
    ...Object.keys(peers),
  ])].sort();

  return names.map((name)=>{
    let kind:RuntimeLockEdge['kind'];
    let spec:string;
    let missingAllowed=false;
    if(optional[name]!==undefined){
      kind='optional';
      spec=optional[name]!;
      missingAllowed=true;
    }else if(required[name]!==undefined){
      kind='dependency';
      spec=required[name]!;
    }else{
      const meta=peerMeta[name];
      const optionalPeer=
        typeof meta==='object'
        &&meta!==null
        &&!Array.isArray(meta)
        &&(meta as JsonRecord).optional===true;
      kind=optionalPeer?'peer-optional':'peer';
      spec=peers[name]!;
      missingAllowed=optionalPeer;
    }
    const target=resolveDependencyLocation(packages,owner,name);
    if(target===undefined&&!missingAllowed){
      throw new Error(
        "PS_RUNTIME_LOCK_DEPENDENCY_MISSING: '"+owner+
        "' requires '"+name+"' but package-lock.json has no resolvable entry",
      );
    }
    return {kind,name,spec,target:target??null};
  });
}

function parsePackage(
  packages:JsonRecord,
  location:string,
  required:boolean,
):RuntimeLockPackage {
  const descriptor=asRecord(
    packages[location],
    "package-lock packages['"+location+"']",
  );
  if(descriptor.link===true){
    throw new Error(
      "PS_RUNTIME_LOCK_LINK_UNSUPPORTED: linked package '"+location+
      "' is outside the first runtime lock policy",
    );
  }
  const {version,resolved,integrity}=descriptor;
  if(
    typeof version!=='string'
    ||typeof resolved!=='string'
    ||typeof integrity!=='string'
    ||integrity.length===0
  ){
    throw new Error(
      "PS_RUNTIME_LOCK_PACKAGE_SOURCE: '"+location+
      "' must have string version/resolved/integrity metadata",
    );
  }
  return {
    location,
    name:packageNameFromLocation(location),
    version,
    resolved,
    integrity,
    required,
    dependencies:dependencyEdges(packages,location,descriptor),
  };
}

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
  const record=asRecord(parsed,pkg.location+' package.json');
  if(typeof record.name!=='string'||typeof record.version!=='string'){
    throw new Error(
      "PS_RUNTIME_LOCK_INSTALLED_PACKAGE_JSON: '"+pkg.location+
      "' must expose string name/version",
    );
  }
  return {name:record.name,version:record.version};
}

export async function verifyRuntimeDependencyLock(
  projectDirectory:string,
  policy:RuntimeDependencyPolicyReport,
):Promise<RuntimeDependencyLockReport|null> {
  if(policy.used.length===0)return null;

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
  let parsed:unknown;
  try{
    parsed=JSON.parse(text);
  }catch{
    throw new Error('PS_RUNTIME_LOCK_JSON: package-lock.json is invalid JSON');
  }
  const root=asRecord(parsed,'package-lock.json');
  if(root.lockfileVersion!==3){
    throw new Error(
      'PS_RUNTIME_LOCK_VERSION: first runtime lock policy requires lockfileVersion 3',
    );
  }
  const packages=asRecord(root.packages,'package-lock.json packages');
  const roots=policy.used.map((dependency)=>{
    const location='node_modules/'+dependency.source;
    if(packages[location]===undefined){
      throw new Error(
        "PS_RUNTIME_LOCK_ROOT_MISSING: package-lock.json has no entry for '"+
        dependency.source+"'",
      );
    }
    const descriptor=asRecord(packages[location],location);
    if(descriptor.version!==dependency.version){
      throw new Error(
        "PS_RUNTIME_LOCK_ROOT_VERSION: '"+dependency.source+
        "' policy requires "+dependency.version+
        ', lockfile has '+String(descriptor.version),
      );
    }
    return {source:dependency.source,location};
  });

  const closure=new Map<string,RuntimeLockPackage>();
  const queue=roots.map((root)=>({location:root.location,required:true}));
  while(queue.length>0){
    const next=queue.shift()!;
    const parsedPackage=parsePackage(packages,next.location,next.required);
    const merged=mergeRequired(closure.get(next.location),parsedPackage);
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

  const locked=[...closure.values()]
    .sort((a,b)=>a.location.localeCompare(b.location));
  for(const pkg of locked){
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

  const schema='proofscript-runtime-lock-v1' as const;
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
