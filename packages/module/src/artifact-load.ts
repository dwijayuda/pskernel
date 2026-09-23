import {Buffer} from 'node:buffer';
import {
  admitCheckedCoreAdmissions,
} from '@proofscript/checked-core';
import {Environment} from 'lean-ts-kernel';
import {Lean4ExportReplay} from 'lean-ts-kernel/lean4export';
import {
  moduleFail,
  moduleKernelMatchesCurrent,
} from './canonical.js';
import {
  DEFAULT_KERNEL,
  type LoadModuleArtifactOptions,
  type LoadModuleArtifactResult,
  type ModuleArtifactSummary,
} from './artifact-types.js';
import {
  parseCheckedAdmissionsPayload,
  verifyModuleArtifact,
  verifyModuleDependencies,
} from './artifact-verify.js';

export function loadModuleArtifact(
  artifact:unknown,
  {
    env=new Environment(),
    dependencyIntegrities=new Map<string,string>(),
  }:LoadModuleArtifactOptions={},
):LoadModuleArtifactResult {
  if(!verifyModuleArtifact(artifact)){
    moduleFail('invalid module artifact');
  }
  verifyModuleDependencies(artifact,dependencyIntegrities);

  if(artifact.version===1){
    const replay=new Lean4ExportReplay(
      env,
      {expectedLeanVersion:artifact.kernel.leanVersion},
    );
    const stats=replay.replay(artifact.payload.text);
    return {
      payloadKind:'lean4export-ndjson',
      env:replay.env,
      stats,
      module:artifact.module,
      integrity:artifact.integrity,
    };
  }

  if(!moduleKernelMatchesCurrent(artifact.kernel)){
    moduleFail(
      'checked admissions kernel compatibility mismatch; expected '+
      DEFAULT_KERNEL.leanVersion+'/'+DEFAULT_KERNEL.apiVersion,
    );
  }
  const admissions=parseCheckedAdmissionsPayload(artifact.payload);
  const checked=admitCheckedCoreAdmissions(env,admissions);
  return {
    payloadKind:'proofscript-checked-admissions-json',
    env:checked.environment,
    admissions,
    module:artifact.module,
    integrity:artifact.integrity,
  };
}

export function moduleArtifactSummary(
  artifact:unknown,
):ModuleArtifactSummary {
  if(!verifyModuleArtifact(artifact)){
    moduleFail('invalid module artifact');
  }
  return {
    format:artifact.format+'@'+artifact.version,
    module:artifact.module,
    kernel:artifact.kernel,
    dependencies:artifact.dependencies.length,
    payloadKind:artifact.payload.kind,
    payloadBytes:Buffer.byteLength(artifact.payload.text,'utf8'),
    payloadIntegrity:artifact.payload.integrity,
    integrity:artifact.integrity,
  };
}
