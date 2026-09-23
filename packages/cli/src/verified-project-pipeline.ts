import {
  admitCheckedCoreAdmissions,
  type CheckedCoreAdmission,
} from '@proofscript/checked-core';
import {compileCheckedCore} from '@proofscript/compiler';
import {elaborateV061Declarations} from '@proofscript/elab';
import {lowerV061ModuleToLean} from '@proofscript/syntax';
import {canonicalSourceIdentity} from './canonical-source.js';
import {
  requireVerifiedBaseEnvironment,
} from './verified-pipeline.js';
import type {ResolvedSourceProject} from './project-sources.js';

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

export function checkVerifiedSourceProject(
  project:ResolvedSourceProject,
){
  const base=requireVerifiedBaseEnvironment();
  const localAdmissions=
    new Map<string,readonly CheckedCoreAdmission[]>();

  for(const name of project.plan.order){
    const source=project.sources.get(name);
    if(source===undefined){
      throw new Error(
        "PS_PROJECT_INTERNAL_SOURCE: missing planned module '"+name+"'",
      );
    }
    const closure=dependencyClosure(project,name);
    const dependencyAdmissions=project.plan.order
      .filter((candidate)=>closure.has(candidate))
      .flatMap((candidate)=>[
        ...(localAdmissions.get(candidate)??[]),
      ]);
    const dependencyEnvironment=admitCheckedCoreAdmissions(
      base,
      dependencyAdmissions,
    ).environment;
    const checked=elaborateV061Declarations(
      source.surface,
      dependencyEnvironment,
    );
    localAdmissions.set(name,checked.admissions);
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

  return {
    surface:entry.surface,
    ...canonical,
    checkedCore,
    lean:lowerV061ModuleToLean(entry.surface),
    featureIds,
    moduleOrder:project.plan.order,
    moduleSources:project.plan.order.map((name)=>{
      const source=project.sources.get(name)!;
      return {
        module:name,
        sourcePath:source.sourcePath,
        sourceKind:source.sourceKind,
        canonicalSourceHash:source.canonicalSourceHash,
      };
    }),
  };
}

export function compileVerifiedSourceProject(
  project:ResolvedSourceProject,
  fileName:string,
){
  const checked=checkVerifiedSourceProject(project);
  const compiled=compileCheckedCore(checked.checkedCore,fileName);
  return {...checked,...compiled};
}
