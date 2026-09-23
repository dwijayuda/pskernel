import type {CheckedCoreAdmission} from '@proofscript/checked-core';
import type {Environment} from 'lean-ts-kernel';
import type {ReplayStats} from 'lean-ts-kernel/lean4export';

export type Sha256=`sha256:${string}`;
export type JsonPrimitive=string|number|boolean|null;
export type JsonValue=
  JsonPrimitive|readonly JsonValue[]|{[key:string]:JsonValue};

export interface KernelCompatibility {
  readonly semantics:'lean4';
  readonly leanVersion:string;
  readonly apiVersion:string;
}
export interface ModuleDependency {
  readonly module:string;
  readonly integrity:Sha256;
}
export interface Lean4ExportPayload {
  readonly kind:'lean4export-ndjson';
  readonly formatVersion:'3.1.0';
  readonly integrity:Sha256;
  readonly text:string;
}
export interface CheckedAdmissionsPayload {
  readonly kind:'proofscript-checked-admissions-json';
  readonly formatVersion:'1.0.0';
  readonly integrity:Sha256;
  readonly text:string;
}
interface ModuleArtifactBase {
  readonly format:'proofscript-module';
  readonly module:string;
  readonly kernel:KernelCompatibility;
  readonly dependencies:readonly ModuleDependency[];
  readonly metadata?:JsonValue;
  readonly integrity:Sha256;
}
export interface ModuleArtifactV1 extends ModuleArtifactBase {
  readonly version:1;
  readonly payload:Lean4ExportPayload;
}
export interface ModuleArtifactV2 extends ModuleArtifactBase {
  readonly version:2;
  readonly payload:CheckedAdmissionsPayload;
}
export type ModuleArtifact=ModuleArtifactV1|ModuleArtifactV2;

export interface CreateModuleArtifactOptions {
  readonly module:string;
  readonly declarations:string;
  readonly dependencies?:readonly ModuleDependency[];
  readonly kernel?:KernelCompatibility;
  readonly metadata?:JsonValue;
}
export interface CreateCheckedModuleArtifactOptions {
  readonly module:string;
  readonly admissions:readonly CheckedCoreAdmission[];
  readonly dependencies?:readonly ModuleDependency[];
  readonly kernel?:KernelCompatibility;
  readonly metadata?:JsonValue;
}
export interface LoadModuleArtifactOptions {
  readonly env?:Environment;
  readonly dependencyIntegrities?:ReadonlyMap<string,string>;
}
export interface Lean4ExportLoadResult {
  readonly payloadKind:'lean4export-ndjson';
  readonly env:Environment;
  readonly stats:ReplayStats;
  readonly module:string;
  readonly integrity:Sha256;
}
export interface CheckedAdmissionsLoadResult {
  readonly payloadKind:'proofscript-checked-admissions-json';
  readonly env:Environment;
  readonly admissions:number;
  readonly module:string;
  readonly integrity:Sha256;
}
export type LoadModuleArtifactResult=
  Lean4ExportLoadResult|CheckedAdmissionsLoadResult;

export interface ModuleArtifactSummary {
  readonly format:string;
  readonly module:string;
  readonly kernel:KernelCompatibility;
  readonly dependencies:number;
  readonly payloadKind:string;
  readonly payloadBytes:number;
  readonly payloadIntegrity:Sha256;
  readonly integrity:Sha256;
}

export const MODULE_FORMAT='proofscript-module' as const;
export const MODULE_FORMAT_VERSION=1 as const;
export const CHECKED_MODULE_FORMAT_VERSION=2 as const;
export const DEFAULT_KERNEL:KernelCompatibility={
  semantics:'lean4',
  leanVersion:'4.34.0',
  apiVersion:'0.1.0',
};
