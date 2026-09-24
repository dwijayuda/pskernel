import type {CheckedSoftwareModule,SoftwareType} from '@proofscript/language';
import type {VerifiedIrModule} from '@proofscript/compiler-ir/verified';
import type {TranslationTarget} from '@proofscript/syntax';
import type {WasmEmitResult} from '@proofscript/compiler';
import type {LoadedPsConfig} from './config.js';
import type {VerifiedAssuranceReport} from './verified-assurance.js';
import type {RuntimeDependencyPolicyReport} from './runtime-dependencies.js';
import type {RuntimeDependencyLockReport} from './runtime-lock.js';

export type BuildTarget='js'|'wasm';

export interface CommonArgs {
  readonly entry?:string;
  readonly project?:string;
  readonly json:boolean;
  readonly verified:boolean;
  readonly buildTarget?:BuildTarget;
  readonly passthrough:readonly string[];
}

export interface TranslateArgs extends CommonArgs {
  readonly target:TranslationTarget;
}

export interface ResolvedInput {
  readonly loaded:LoadedPsConfig;
  readonly sourcePath:string;
  readonly source:string;
}

export interface BuildArtifacts {
  readonly typescript:string;
  readonly javascript:string;
  readonly declarations:string;
  readonly sourceMap:string|null;
  readonly lean:string;
  readonly manifest:string;
  readonly modules?:readonly string[];
  readonly webassembly?:string;
  readonly wat?:string;
}

export interface BuildReport extends Record<string,unknown> {
  readonly ok:boolean;
  readonly command:'build';
  readonly source:string;
  readonly declarations:number;
  readonly featureIds:readonly string[];
  readonly languageVersion:string;
  readonly surfaceBaseline:string;
  readonly leanSemantics:string;
  readonly proofStatus:string;
  readonly sourceKind:string;
  readonly canonicalSourceHash:string;
  readonly outputDirectory:string;
  readonly artifacts:BuildArtifacts;
  readonly typescriptVersion:string;
  readonly semanticPipeline?:'verified-core';
  readonly assurance?:VerifiedAssuranceReport;
  readonly runtimeDependencyPolicy?:RuntimeDependencyPolicyReport;
  readonly runtimeDependencyLock?:RuntimeDependencyLockReport|null;
  readonly moduleCount?:number;
  readonly moduleOrder?:readonly string[];
  readonly sourceRoots?:readonly string[];
}

export interface BuildResult {
  readonly report:BuildReport;
  readonly checked?:CheckedSoftwareModule;
  readonly verifiedIr?:VerifiedIrModule;
  readonly wasm?:WasmEmitResult;
  readonly jsPath:string;
}

export interface RunResult
  extends Omit<BuildReport,'command'> {
  readonly command:'run';
  readonly mainResult:unknown;
}

export interface RuntimeArgument {
  readonly text:string;
  readonly type:SoftwareType;
}
