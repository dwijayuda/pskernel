import {existsSync} from 'node:fs';
import {readFile} from 'node:fs/promises';
import {
  basename,
  dirname,
  extname,
  join,
  resolve,
} from 'node:path';
import {
  createDefaultSourceFrontendRegistry,
  sourceKindFromFileName,
  type V061Module,
} from '@proofscript/syntax';
import {
  createSourceBuildPlan,
  type ProjectSourceModule,
  type SourceBuildPlan,
} from '@proofscript/project';
import {canonicalSourceIdentity} from './canonical-source.js';
import type {ResolvedInput} from './types.js';

const frontends=createDefaultSourceFrontendRegistry();

export interface LoadedProjectSource extends ProjectSourceModule {
  readonly source:string;
  readonly surface:V061Module;
  readonly canonicalSourceHash:string;
}

export interface ResolvedSourceProject {
  readonly entryModule:string;
  readonly rootDirectory:string;
  readonly sourceRoots:readonly string[];
  readonly plan:SourceBuildPlan;
  readonly sources:ReadonlyMap<string,LoadedProjectSource>;
}

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

function resolveImportedSource(
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

function entryLogicalName(sourcePath:string):string {
  return basename(sourcePath,extname(sourcePath));
}

export async function resolveSourceProject(
  input:ResolvedInput,
):Promise<ResolvedSourceProject> {
  const rootDirectory=dirname(input.sourcePath);
  const configured=input.loaded.config.sourceRoots;
  const sourceRoots=configured.length===0
    ?[rootDirectory]
    :[...new Set(
        configured.map((root)=>resolve(input.loaded.directory,root)),
      )];
  const entryModule=entryLogicalName(input.sourcePath);
  const loaded=new Map<string,LoadedProjectSource>();

  const load=async(
    module:string,
    sourcePath:string,
    providedSource?:string,
  ):Promise<void>=>{
    const absolute=resolve(sourcePath);
    const prior=loaded.get(module);
    if(prior!==undefined){
      if(resolve(prior.sourcePath)!==absolute){
        throw new Error(
          "PS_PROJECT_SOURCE_AMBIGUITY: logical module '"+module+
          "' has multiple sources",
        );
      }
      return;
    }

    const source=providedSource??await readFile(absolute,'utf8');
    const frontend=frontends.forFile(absolute);
    const surface=frontend.parse(source);
    const canonical=canonicalSourceIdentity(surface);
    const item:LoadedProjectSource={
      module,
      sourcePath:absolute,
      sourceKind:sourceKindFromFileName(absolute),
      imports:surface.imports??[],
      source,
      surface,
      canonicalSourceHash:canonical.canonicalSourceHash,
    };
    loaded.set(module,item);

    for(const dependency of item.imports){
      const dependencyPath=resolveImportedSource(
        sourceRoots,
        dependency,
      );
      await load(dependency,dependencyPath);
    }
  };

  await load(entryModule,input.sourcePath,input.source);
  const plan=createSourceBuildPlan([...loaded.values()]);
  return {
    entryModule,
    rootDirectory,
    sourceRoots,
    plan,
    sources:loaded,
  };
}
