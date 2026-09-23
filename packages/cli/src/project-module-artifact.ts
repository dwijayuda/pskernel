import type {
  CheckedCoreAdmission,
} from '@proofscript/checked-core';
import {
  createCheckedModuleArtifact,
  loadModuleArtifact,
  type ModuleArtifactV2,
} from '@proofscript/module';
import type {Environment} from 'lean-ts-kernel';

export interface VerifiedModuleArtifactDependency {
  readonly module:string;
  readonly artifact:ModuleArtifactV2;
}

export interface VerifiedModuleArtifactInput {
  readonly module:string;
  readonly admissions:readonly CheckedCoreAdmission[];
  readonly canonicalSourceHash:string;
  readonly sourceCacheKey:string;
  readonly dependencyEnvironment:Environment;
  readonly dependencies:readonly VerifiedModuleArtifactDependency[];
}

export function createReplayGatedModuleArtifact(
  input:VerifiedModuleArtifactInput,
):ModuleArtifactV2 {
  const dependencies=input.dependencies.map((dependency)=>({
    module:dependency.module,
    integrity:dependency.artifact.integrity,
  }));
  const artifact=createCheckedModuleArtifact({
    module:input.module,
    admissions:input.admissions,
    dependencies,
    metadata:{
      schema:'proofscript-project-module-v1',
      canonicalSourceHash:input.canonicalSourceHash,
      sourceCacheKey:input.sourceCacheKey,
    },
  });
  const loaded=loadModuleArtifact(artifact,{
    env:input.dependencyEnvironment,
    dependencyIntegrities:new Map(
      dependencies.map((dependency)=>[
        dependency.module,
        dependency.integrity,
      ]),
    ),
  });
  if(loaded.payloadKind!=='proofscript-checked-admissions-json'){
    throw new Error(
      'PS_PROJECT_MODULE_ARTIFACT_KIND: expected checked-admission payload',
    );
  }
  if(loaded.admissions.length!==input.admissions.length){
    throw new Error(
      'PS_PROJECT_MODULE_ARTIFACT_REPLAY: admission count changed during replay',
    );
  }
  return artifact;
}
