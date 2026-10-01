import {
  admitCheckedCoreAdmissions,
  type CheckedCoreAdmission,
  type CheckedCoreClass,
  type CheckedCoreInstance,
  type CheckedCoreStructure,
} from '@proofscript/checked-core';
import {
  elaborateV061Declarations,
  type V061ElaborationSeed,
} from '@proofscript/elab';
import {
  createSourceBuildPlan,
  sourceDependencyClosure,
  type ProjectSourceModule,
} from '@proofscript/project';
import {
  createDefaultSourceFrontendRegistry,
  type SourceKind,
  type V061Module,
} from '@proofscript/syntax';
import {Environment} from 'lean-ts-kernel';
import type {TextDocumentSnapshot} from './model.js';

const frontends=createDefaultSourceFrontendRegistry();

export interface ProjectResolvedSource {
  readonly uri:string;
  readonly sourceKind:SourceKind;
  readonly text:string;
}

export interface LanguageServiceProjectHost {
  entryModule(snapshot:TextDocumentSnapshot):string;
  resolveImport(
    entry:TextDocumentSnapshot,
    importer:ProjectResolvedSource,
    logicalModule:string,
  ):ProjectResolvedSource;
}

interface LoadedProjectSource extends ProjectSourceModule {
  readonly uri:string;
  readonly text:string;
  readonly surface:V061Module;
}

interface ModuleMetadata {
  readonly structures:readonly CheckedCoreStructure[];
  readonly classes:readonly CheckedCoreClass[];
  readonly instances:readonly CheckedCoreInstance[];
}

export interface ProjectAnalysisSource extends ProjectResolvedSource {
  readonly module:string;
  readonly surface:V061Module;
}
export interface ProjectAnalysisContext {
  readonly entryModule:string;
  readonly moduleOrder:readonly string[];
  readonly environment:Environment;
  readonly seed:V061ElaborationSeed;
  readonly sources:ReadonlyMap<string,ProjectAnalysisSource>;
}

function seedFromModules(
  names:readonly string[],
  metadata:ReadonlyMap<string,ModuleMetadata>,
):V061ElaborationSeed {
  return {
    structures:names.flatMap((name)=>metadata.get(name)?.structures??[]),
    classes:names.flatMap((name)=>metadata.get(name)?.classes??[]),
    instances:names.flatMap((name)=>metadata.get(name)?.instances??[]),
  };
}

function openOverride(
  resolved:ProjectResolvedSource,
  getOpenDocument:(uri:string)=>TextDocumentSnapshot|undefined,
):ProjectResolvedSource {
  const open=getOpenDocument(resolved.uri);
  return open===undefined
    ?resolved
    :{
        uri:open.uri,
        sourceKind:open.sourceKind,
        text:open.text,
      };
}

export function buildProjectAnalysisContext(
  entry:TextDocumentSnapshot,
  baseEnvironment:Environment,
  host:LanguageServiceProjectHost,
  getOpenDocument:(uri:string)=>TextDocumentSnapshot|undefined,
):ProjectAnalysisContext {
  const entryModule=host.entryModule(entry);
  const loaded=new Map<string,LoadedProjectSource>();

  const load=(
    module:string,
    resolved:ProjectResolvedSource,
  ):void=>{
    const source=openOverride(resolved,getOpenDocument);
    const prior=loaded.get(module);
    if(prior!==undefined){
      if(prior.uri!==source.uri){
        throw new Error(
          "PS_LS_PROJECT_AMBIGUITY: logical module '"+module+
          "' resolved to both '"+prior.uri+"' and '"+source.uri+"'",
        );
      }
      return;
    }
    const surface=frontends.require(source.sourceKind).parse(source.text);
    loaded.set(module,{
      module,
      sourcePath:source.uri,
      sourceKind:source.sourceKind,
      imports:surface.imports??[],
      uri:source.uri,
      text:source.text,
      surface,
    });
    for(const dependency of surface.imports??[]){
      load(
        dependency,
        host.resolveImport(entry,source,dependency),
      );
    }
  };

  load(entryModule,{
    uri:entry.uri,
    sourceKind:entry.sourceKind,
    text:entry.text,
  });
  const plan=createSourceBuildPlan([...loaded.values()]);
  const localAdmissions=
    new Map<string,readonly CheckedCoreAdmission[]>();
  const metadata=new Map<string,ModuleMetadata>();

  for(const name of plan.order){
    if(name===entryModule)continue;
    const source=loaded.get(name);
    if(source===undefined){
      throw new Error(
        "PS_LS_PROJECT_INTERNAL: missing loaded module '"+name+"'",
      );
    }
    const closure=sourceDependencyClosure(plan,name);
    const dependencyAdmissions=closure.flatMap(
      (dependency)=>[...(localAdmissions.get(dependency)??[])],
    );
    const dependencyChecked=admitCheckedCoreAdmissions(
      baseEnvironment,
      dependencyAdmissions,
    );
    const checked=elaborateV061Declarations(
      source.surface,
      dependencyChecked.environment,
      seedFromModules(closure,metadata),
    );
    localAdmissions.set(name,checked.admissions);
    metadata.set(name,{
      structures:checked.structures,
      classes:checked.classes,
      instances:checked.instances,
    });
  }

  const entryClosure=sourceDependencyClosure(plan,entryModule);
  const entryAdmissions=entryClosure.flatMap(
    (dependency)=>[...(localAdmissions.get(dependency)??[])],
  );
  const imported=admitCheckedCoreAdmissions(
    baseEnvironment,
    entryAdmissions,
  );
  return {
    entryModule,
    moduleOrder:plan.order,
    environment:imported.environment,
    seed:seedFromModules(entryClosure,metadata),
    sources:new Map(
      [...loaded.entries()].map(([name,source])=>[
        name,
        {
          module:name,
          uri:source.uri,
          sourceKind:source.sourceKind,
          text:source.text,
          surface:source.surface,
        },
      ]),
    ),
  };
}
