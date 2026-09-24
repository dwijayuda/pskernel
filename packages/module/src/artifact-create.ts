import {
  encodeCheckedCoreAdmissions,
} from '@proofscript/checked-core';
import {
  canonicalJson,
  moduleKernelValid,
  moduleSha256,
  normalizeDeclarationStream,
  normalizeModuleDependencies,
  moduleFail,
} from './canonical.js';
import {
  CHECKED_MODULE_FORMAT_VERSION,
  DEFAULT_KERNEL,
  MODULE_FORMAT,
  MODULE_FORMAT_VERSION,
  type CheckedAdmissionsPayload,
  type CreateCheckedModuleArtifactOptions,
  type CreateModuleArtifactOptions,
  type JsonValue,
  type KernelCompatibility,
  type ModuleArtifactV1,
  type ModuleArtifactV2,
  type ModuleDependency,
} from './artifact-types.js';

function commonBody(options:{
  readonly module:string;
  readonly dependencies:readonly ModuleDependency[];
  readonly kernel:KernelCompatibility;
  readonly metadata:JsonValue|undefined;
}){
  if(options.module.length===0){
    moduleFail('module name must be a non-empty string');
  }
  if(!moduleKernelValid(options.kernel)){
    moduleFail('invalid kernel compatibility descriptor');
  }
  return {
    format:MODULE_FORMAT,
    module:options.module,
    kernel:{...options.kernel},
    dependencies:normalizeModuleDependencies(options.dependencies),
    ...(options.metadata===undefined?{}:{metadata:options.metadata}),
  } as const;
}

export function createModuleArtifact({
  module,
  declarations,
  dependencies=[],
  kernel=DEFAULT_KERNEL,
  metadata,
}:CreateModuleArtifactOptions):ModuleArtifactV1 {
  const text=normalizeDeclarationStream(declarations);
  const payload={
    kind:'lean4export-ndjson',
    formatVersion:'3.1.0',
    integrity:moduleSha256(text),
    text,
  } as const;
  const body={
    ...commonBody({module,dependencies,kernel,metadata}),
    version:MODULE_FORMAT_VERSION,
    payload,
  } satisfies Omit<ModuleArtifactV1,'integrity'>;
  return {...body,integrity:moduleSha256(canonicalJson(body))};
}

export function createCheckedModuleArtifact({
  module,
  admissions,
  dependencies=[],
  kernel=DEFAULT_KERNEL,
  metadata,
}:CreateCheckedModuleArtifactOptions):ModuleArtifactV2 {
  const encoded=encodeCheckedCoreAdmissions(admissions);
  const text=canonicalJson(encoded)+'\n';
  const payload:CheckedAdmissionsPayload={
    kind:'proofscript-checked-admissions-json',
    formatVersion:'1.1.0',
    integrity:moduleSha256(text),
    text,
  };
  const body={
    ...commonBody({module,dependencies,kernel,metadata}),
    version:CHECKED_MODULE_FORMAT_VERSION,
    payload,
  } satisfies Omit<ModuleArtifactV2,'integrity'>;
  return {...body,integrity:moduleSha256(canonicalJson(body))};
}
