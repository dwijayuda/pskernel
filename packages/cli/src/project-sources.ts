import {readFile} from 'node:fs/promises';
import {
  basename,
  dirname,
  extname,
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
import {
  resolveLogicalModuleSource,
  resolvedProjectSourceRoots,
} from '@proofscript/project/node';
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

function entryLogicalName(sourcePath:string):string {
  return basename(sourcePath,extname(sourcePath));
}

export async function resolveSourceProject(
  input:ResolvedInput,
):Promise<ResolvedSourceProject> {
  const rootDirectory=dirname(input.sourcePath);
  const configured=input.loaded.config.sourceRoots;
  const sourceRoots=resolvedProjectSourceRoots(
    input.loaded.directory,
    configured,
    rootDirectory,
  );
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
      const dependencyPath=resolveLogicalModuleSource(
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
