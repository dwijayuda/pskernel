import type {CheckedSoftwareModule,SoftwareType} from '@proofscript/language';
import type {VerifiedIrModule} from '@proofscript/compiler-ir/verified';
import type {TranslationTarget} from '@proofscript/syntax';
import type {WasmEmitResult} from '@proofscript/compiler';
import type {LoadedPsConfig} from './config.js';
import type {VerifiedAssuranceReport} from './verified-assurance.js';
import type {RuntimeDependencyPolicyReport} from './runtime-dependencies.js';
import type {RuntimeDependencyLockReport} from './runtime-lock-format.js';
import type {WrittenModuleArtifact} from './project-artifact-output.js';

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

export interface CliBaseReport {
  readonly source:string;
  readonly declarations:number;
  readonly featureIds:readonly string[];
  readonly languageVersion:string;
  readonly surfaceBaseline:string;
  readonly leanSemantics:string;
  readonly sourceKind:string;
  readonly canonicalSourceHash:string;
}

export interface VerifiedProjectReportFields {
  readonly moduleCount:number;
  readonly moduleOrder:readonly string[];
  readonly moduleSources:readonly {
    readonly module:string;
    readonly sourcePath:string;
    readonly sourceKind:string;
    readonly canonicalSourceHash:string;
    readonly moduleIntegrity:string;
    readonly moduleArtifactIntegrity:string;
  }[];
  readonly projectIntegrity:string;
  readonly sourceRoots:readonly string[];
  readonly moduleCacheHits:number;
  readonly moduleCacheMisses:number;
  readonly semanticPipeline:'verified-core';
  readonly proofStatus:'kernel-verified';
  readonly assurance:VerifiedAssuranceReport;
  readonly runtimeDependencyPolicy:RuntimeDependencyPolicyReport;
}

export interface WasmTargetReportFields {
  readonly buildTarget:BuildTarget;
  readonly binaryenVersion?:WasmEmitResult['binaryenVersion'];
  readonly wasmProfile?:WasmEmitResult['profile'];
  readonly wasmOptimized?:WasmEmitResult['optimized'];
  readonly wasmExports?:WasmEmitResult['exports'];
  readonly wasmRuntimeImports?:WasmEmitResult['imports'];
  readonly wasmBigIntLiterals?:WasmEmitResult['bigintLiterals'];
}

export interface VerifiedCheckReport
extends CliBaseReport,VerifiedProjectReportFields,WasmTargetReportFields {
  readonly ok:true;
  readonly command:'check';
}

export interface UnverifiedCheckReport extends CliBaseReport {
  readonly ok:true;
  readonly command:'check';
  readonly proofStatus:'software-typechecked-only';
}

export type CheckReport=VerifiedCheckReport|UnverifiedCheckReport;

export interface CliBuildArtifacts {
  readonly typescript:string;
  readonly javascript:string;
  readonly declarations:string;
  readonly sourceMap:string|null;
  readonly lean:string;
  readonly manifest:string;
}

export interface VerifiedBuildReport
extends CliBaseReport,VerifiedProjectReportFields,WasmTargetReportFields {
  readonly ok:true;
  readonly command:'build';
  readonly runtimeDependencyLock:RuntimeDependencyLockReport|null;
  readonly outputDirectory:string;
  readonly artifacts:CliBuildArtifacts&{
    readonly modules:readonly WrittenModuleArtifact[];
    readonly webassembly?:string;
    readonly wat?:string;
  };
  readonly typescriptVersion:string;
}

export interface UnverifiedBuildReport extends CliBaseReport {
  readonly ok:true;
  readonly command:'build';
  readonly proofStatus:'software-typechecked-only';
  readonly outputDirectory:string;
  readonly artifacts:CliBuildArtifacts;
  readonly typescriptVersion:string;
  readonly proofStatusDetail:string;
}

export interface VerifiedBuildResult {
  readonly report:VerifiedBuildReport;
  readonly verifiedIr:VerifiedIrModule;
  readonly wasm?:WasmEmitResult;
  readonly checked?:never;
  readonly jsPath:string;
}

export interface UnverifiedBuildResult {
  readonly report:UnverifiedBuildReport;
  readonly checked:CheckedSoftwareModule;
  readonly verifiedIr?:never;
  readonly wasm?:never;
  readonly jsPath:string;
}

export type BuildResult=VerifiedBuildResult|UnverifiedBuildResult;

export type VerifiedRunReport=Omit<VerifiedBuildReport,'command'>&{
  readonly command:'run';
  readonly mainResult:unknown;
};

export type UnverifiedRunReport=Omit<UnverifiedBuildReport,'command'>&{
  readonly command:'run';
  readonly mainResult:unknown;
};

export type RunReport=VerifiedRunReport|UnverifiedRunReport;

export interface RuntimeArgument {
  readonly text:string;
  readonly type:SoftwareType;
}
