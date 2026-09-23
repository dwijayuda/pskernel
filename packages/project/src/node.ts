import {existsSync,readFileSync} from 'node:fs';
import {
  dirname,
  isAbsolute,
  join,
  resolve,
} from 'node:path';

function moduleRelativePath(module:string):string {
  const parts=module.split('.');
  if(
    parts.length===0
    ||parts.some((part)=>part.length===0)
  ){
    throw new Error(
      "PS_PROJECT_IMPORT_NAME: invalid logical module '"+module+"'",
    );
  }
  return join(...parts);
}

export function projectSourceRootsFromConfig(
  value:unknown,
):readonly string[] {
  if(value===undefined)return [];
  if(!Array.isArray(value)){
    throw new Error(
      'PS_PROJECT_CONFIG_SOURCE_ROOTS: sourceRoots must be an array of relative paths',
    );
  }
  const roots:string[]=[];
  for(const root of value){
    if(
      typeof root!=='string'
      ||root.length===0
      ||isAbsolute(root)
    ){
      throw new Error(
        'PS_PROJECT_CONFIG_SOURCE_ROOTS: each source root must be a non-empty relative path',
      );
    }
    if(!roots.includes(root))roots.push(root);
  }
  return roots;
}

const NPM_PACKAGE_ROOT=/^(?:@[a-z0-9][a-z0-9._-]*\/)?[a-z0-9][a-z0-9._-]*$/;
const EXACT_PACKAGE_VERSION=/^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$/;

export type ProjectRuntimeDependencies=Readonly<Record<string,string>>;

export function projectRuntimeDependenciesFromConfig(
  value:unknown,
):ProjectRuntimeDependencies {
  if(value===undefined)return {};
  if(
    typeof value!=='object'
    ||value===null
    ||Array.isArray(value)
  ){
    throw new Error(
      'PS_PROJECT_CONFIG_RUNTIME_DEPENDENCIES: runtimeDependencies must be an object of exact npm package versions',
    );
  }
  const out:Record<string,string>={};
  for(const [source,version] of Object.entries(value)){
    if(!NPM_PACKAGE_ROOT.test(source)){
      throw new Error(
        "PS_PROJECT_CONFIG_RUNTIME_DEPENDENCIES: '"+source+
        "' must be an npm package root; subpaths, relative paths, and node: specifiers are not in the first FFI policy",
      );
    }
    if(
      typeof version!=='string'
      ||!EXACT_PACKAGE_VERSION.test(version)
    ){
      throw new Error(
        "PS_PROJECT_CONFIG_RUNTIME_DEPENDENCIES: '"+source+
        "' must use an exact x.y.z package version",
      );
    }
    out[source]=version;
  }
  return out;
}

export function resolvedProjectSourceRoots(
  configDirectory:string,
  configured:readonly string[],
  fallbackDirectory:string,
):readonly string[] {
  return configured.length===0
    ?[resolve(fallbackDirectory)]
    :[...new Set(
        configured.map((root)=>resolve(configDirectory,root)),
      )];
}

export function resolveLogicalModuleSource(
  sourceRoots:readonly string[],
  module:string,
):string {
  const relative=moduleRelativePath(module);
  const candidates:string[]=[];
  for(const root of sourceRoots){
    const ps=join(root,relative+'.ps');
    const lean=join(root,relative+'.lean');
    if(existsSync(ps))candidates.push(ps);
    if(existsSync(lean))candidates.push(lean);
  }
  if(candidates.length>1){
    throw new Error(
      "PS_PROJECT_SOURCE_AMBIGUITY: logical module '"+module+
      "' resolves to multiple sources: "+
      candidates.map((item)=>"'"+item+"'").join(', '),
    );
  }
  if(candidates.length===0){
    throw new Error(
      "PS_PROJECT_SOURCE_MISSING: no .ps or .lean source for module '"+
      module+"' below configured roots: "+
      sourceRoots.map((root)=>"'"+root+"'").join(', '),
    );
  }
  return candidates[0]!;
}

export function findProjectConfigSync(
  start:string,
):string|undefined {
  let current=resolve(start);
  while(true){
    const candidate=join(current,'psconfig.json');
    if(existsSync(candidate))return candidate;
    const parent=dirname(current);
    if(parent===current)return undefined;
    current=parent;
  }
}

export interface NodeProjectResolution {
  readonly configPath?:string;
  readonly configDirectory:string;
  readonly sourceRoots:readonly string[];
}

export function nodeProjectResolutionForEntry(
  entryPath:string,
):NodeProjectResolution {
  const fallbackDirectory=dirname(resolve(entryPath));
  const configPath=findProjectConfigSync(fallbackDirectory);
  if(configPath===undefined){
    return {
      configDirectory:fallbackDirectory,
      sourceRoots:[fallbackDirectory],
    };
  }
  const parsed=JSON.parse(readFileSync(configPath,'utf8')) as {
    readonly sourceRoots?:unknown;
  };
  const configured=projectSourceRootsFromConfig(parsed.sourceRoots);
  const configDirectory=dirname(configPath);
  return {
    configPath,
    configDirectory,
    sourceRoots:resolvedProjectSourceRoots(
      configDirectory,
      configured,
      fallbackDirectory,
    ),
  };
}
