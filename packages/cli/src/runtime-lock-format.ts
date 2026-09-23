export type JsonRecord=Record<string,unknown>;

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
  readonly schema:'proofscript-runtime-lock-v2';
  readonly lockfileVersion:3;
  readonly integrity:string;
  readonly roots:readonly {
    readonly packageRoot:string;
    readonly location:string;
  }[];
  readonly packages:readonly RuntimeLockPackage[];
}

export interface RuntimeLockDocument {
  readonly packages:JsonRecord;
}

export function asRuntimeLockRecord(
  value:unknown,
  label:string,
):JsonRecord {
  if(typeof value!=='object'||value===null||Array.isArray(value)){
    throw new Error('PS_RUNTIME_LOCK_FORMAT: '+label+' must be an object');
  }
  return value as JsonRecord;
}

function stringMap(
  value:unknown,
  label:string,
):Record<string,string> {
  if(value===undefined)return {};
  const record=asRuntimeLockRecord(value,label);
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
  ownerRequired:boolean,
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
    :asRuntimeLockRecord(
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
    let missingAllowed=!ownerRequired;
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

export function parseRuntimeLockDocument(
  text:string,
):RuntimeLockDocument {
  let parsed:unknown;
  try{
    parsed=JSON.parse(text);
  }catch{
    throw new Error('PS_RUNTIME_LOCK_JSON: package-lock.json is invalid JSON');
  }
  const root=asRuntimeLockRecord(parsed,'package-lock.json');
  if(root.lockfileVersion!==3){
    throw new Error(
      'PS_RUNTIME_LOCK_VERSION: first runtime lock policy requires lockfileVersion 3',
    );
  }
  return {
    packages:asRuntimeLockRecord(
      root.packages,
      'package-lock.json packages',
    ),
  };
}

export function parseRuntimeLockPackage(
  packages:JsonRecord,
  location:string,
  required:boolean,
):RuntimeLockPackage {
  const descriptor=asRuntimeLockRecord(
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
    ||!/^(?:sha512|sha1)-\S+/.test(integrity)
  ){
    throw new Error(
      "PS_RUNTIME_LOCK_PACKAGE_SOURCE: '"+location+
      "' must have version/resolved plus sha512/sha1 SRI metadata",
    );
  }
  return {
    location,
    name:packageNameFromLocation(location),
    version,
    resolved,
    integrity,
    required,
    dependencies:dependencyEdges(
      packages,
      location,
      descriptor,
      required,
    ),
  };
}
