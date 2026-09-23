import {createHash} from 'node:crypto';
import {
  admitCheckedCoreAdmissions,
  type CheckedCoreAdmission,
} from '@proofscript/checked-core';
import {compileCheckedCore} from '@proofscript/compiler';
import {elaborateV061Declarations} from '@proofscript/elab';
import {
  DEFAULT_KERNEL,
  canonicalJson,
} from '@proofscript/module';
import {BuildCache} from '@proofscript/project';
import {lowerV061ModuleToLean} from '@proofscript/syntax';
import {canonicalSourceIdentity} from './canonical-source.js';
import {
  requireVerifiedBaseEnvironment,
} from './verified-pipeline.js';
import type {ResolvedSourceProject} from './project-sources.js';

const MODULE_CACHE_SCHEMA='proofscript-checked-module-cache-v1';
const PROJECT_INTEGRITY_SCHEMA='proofscript-project-integrity-v1';

export interface VerifiedProjectCachedModule {
  readonly admissions:readonly CheckedCoreAdmission[];
}

export type VerifiedProjectModuleCache=
  BuildCache<VerifiedProjectCachedModule>;

const sharedModuleCache:VerifiedProjectModuleCache=
  new BuildCache<VerifiedProjectCachedModule>();

export interface VerifiedProjectCheckOptions {
  readonly moduleCache?:VerifiedProjectModuleCache;
}

export function createVerifiedProjectModuleCache():
VerifiedProjectModuleCache {
  return new BuildCache<VerifiedProjectCachedModule>();
}

function sha256Canonical(value:unknown):string {
  return 'sha256:'+createHash('sha256')
    .update(canonicalJson(value),'utf8')
    .digest('hex');
}

function dependencyClosure(
  project:ResolvedSourceProject,
  module:string,
):Set<string> {
  const out=new Set<string>();
  const visit=(name:string):void=>{
    const source=project.sources.get(name);
    if(source===undefined){
      throw new Error(
        "PS_PROJECT_INTERNAL_SOURCE: unresolved module '"+name+"'",
      );
    }
    for(const dependency of source.imports){
      if(out.has(dependency))continue;
      out.add(dependency);
      visit(dependency);
    }
  };
  visit(module);
  return out;
}

function directDependencyIntegrities(
  project:ResolvedSourceProject,
  module:string,
  integrities:ReadonlyMap<string,string>,
):readonly {readonly module:string;readonly integrity:string}[] {
  const source=project.sources.get(module);
  if(source===undefined){
    throw new Error(
      "PS_PROJECT_INTERNAL_SOURCE: unresolved module '"+module+"'",
    );
  }
  return [...source.imports]
    .sort()
    .map((dependency)=>{
      const integrity=integrities.get(dependency);
      if(integrity===undefined){
        throw new Error(
          "PS_PROJECT_INTERNAL_INTEGRITY: dependency '"+dependency+
          "' of '"+module+"' has no integrity key",
        );
      }
      return {module:dependency,integrity};
    });
}

function checkedModuleIntegrity(
  project:ResolvedSourceProject,
  module:string,
  integrities:ReadonlyMap<string,string>,
):string {
  const source=project.sources.get(module);
  if(source===undefined){
    throw new Error(
      "PS_PROJECT_INTERNAL_SOURCE: unresolved module '"+module+"'",
    );
  }
  return sha256Canonical({
    schema:MODULE_CACHE_SCHEMA,
    kernel:DEFAULT_KERNEL,
    module,
    canonicalSourceHash:source.canonicalSourceHash,
    dependencies:directDependencyIntegrities(
      project,
      module,
      integrities,
    ),
  });
}

function checkedProjectIntegrity(
  project:ResolvedSourceProject,
  integrities:ReadonlyMap<string,string>,
):string {
  return sha256Canonical({
    schema:PROJECT_INTEGRITY_SCHEMA,
    kernel:DEFAULT_KERNEL,
    entryModule:project.entryModule,
    modules:project.plan.order.map((module)=>{
      const integrity=integrities.get(module);
      if(integrity===undefined){
        throw new Error(
          "PS_PROJECT_INTERNAL_INTEGRITY: module '"+module+
          "' has no integrity key",
        );
      }
      return {module,integrity};
    }),
  });
}

export function clearVerifiedProjectModuleCache():void {
  sharedModuleCache.clear();
}

export function checkVerifiedSourceProject(
  project:ResolvedSourceProject,
  options:VerifiedProjectCheckOptions={},
){
  const base=requireVerifiedBaseEnvironment();
  const localAdmissions=
    new Map<string,readonly CheckedCoreAdmission[]>();
  const moduleIntegrities=new Map<string,string>();
  const cache=options.moduleCache??sharedModuleCache;
  let moduleCacheHits=0;
  let moduleCacheMisses=0;

  for(const name of project.plan.order){
    const source=project.sources.get(name);
    if(source===undefined){
      throw new Error(
        "PS_PROJECT_INTERNAL_SOURCE: missing planned module '"+name+"'",
      );
    }
    const integrity=checkedModuleIntegrity(
      project,
      name,
      moduleIntegrities,
    );
    moduleIntegrities.set(name,integrity);

    const cached=cache.get(integrity);
    if(cached!==undefined){
      localAdmissions.set(name,cached.admissions);
      moduleCacheHits+=1;
      continue;
    }

    const closure=dependencyClosure(project,name);
    const dependencyAdmissions=project.plan.order
      .filter((candidate)=>closure.has(candidate))
      .flatMap((candidate)=>[
        ...(localAdmissions.get(candidate)??[]),
      ]);
    const dependencyChecked=admitCheckedCoreAdmissions(
      base,
      dependencyAdmissions,
    );
    const checked=elaborateV061Declarations(
      source.surface,
      dependencyChecked.environment,
      dependencyChecked,
    );
    localAdmissions.set(name,checked.admissions);
    cache.set(integrity,{admissions:checked.admissions});
    moduleCacheMisses+=1;
  }

  const allAdmissions=project.plan.order.flatMap(
    (name)=>[...(localAdmissions.get(name)??[])],
  );
  const checkedCore=admitCheckedCoreAdmissions(
    base,
    allAdmissions,
  );
  const entry=project.sources.get(project.entryModule);
  if(entry===undefined){
    throw new Error(
      'PS_PROJECT_INTERNAL_ENTRY: entry module was not loaded',
    );
  }
  const canonical=canonicalSourceIdentity(entry.surface);
  const featureIds=[
    ...new Set(
      project.plan.order.flatMap(
        (name)=>project.sources.get(name)?.surface.featureIds??[],
      ),
    ),
  ];
  const projectIntegrity=checkedProjectIntegrity(
    project,
    moduleIntegrities,
  );

  return {
    surface:entry.surface,
    ...canonical,
    checkedCore,
    lean:lowerV061ModuleToLean(entry.surface),
    featureIds,
    projectIntegrity,
    sourceRoots:project.sourceRoots,
    moduleCacheHits,
    moduleCacheMisses,
    moduleOrder:project.plan.order,
    moduleSources:project.plan.order.map((name)=>{
      const source=project.sources.get(name)!;
      return {
        module:name,
        sourcePath:source.sourcePath,
        sourceKind:source.sourceKind,
        canonicalSourceHash:source.canonicalSourceHash,
        moduleIntegrity:moduleIntegrities.get(name)!,
      };
    }),
  };
}

export function compileVerifiedSourceProject(
  project:ResolvedSourceProject,
  fileName:string,
  options:VerifiedProjectCheckOptions={},
){
  const checked=checkVerifiedSourceProject(project,options);
  const compiled=compileCheckedCore(checked.checkedCore,fileName);
  return {...checked,...compiled};
}
