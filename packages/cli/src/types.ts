import type {VerifiedIrModule} from '@proofscript/compiler-ir/verified';
import type {TranslationTarget} from '@proofscript/syntax';
import type {LoadedPsConfig} from './config.js';
import type {VerifiedAssuranceReport} from './verified-assurance.js';
import type {RuntimeDependencyPolicyReport} from './runtime-dependencies.js';
import type {RuntimeDependencyLockReport} from './runtime-lock-format.js';
import type {WrittenModuleArtifact} from './project-artifact-output.js';

export interface CommonArgs {
  readonly entry?:string;
  readonly project?:string;
  readonly json:boolean;
  /**
   * Deprecated compatibility marker. check/build/run always use the
   * pskernel-admitted checked-core path.
   */
  readonly verified:boolean;
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

export interface VerifiedCheckReport
extends CliBaseReport,VerifiedProjectReportFields {
  readonly ok:true;
  readonly command:'check';
}

export type CheckReport=VerifiedCheckReport;

export interface CliBuildArtifacts {
  readonly typescript:string;
  readonly javascript:string;
  readonly declarations:string;
  readonly sourceMap:string|null;
  readonly lean:string;
  readonly manifest:string;
}

export interface VerifiedBuildReport
extends CliBaseReport,VerifiedProjectReportFields {
  readonly ok:true;
  readonly command:'build';
  readonly runtimeDependencyLock:RuntimeDependencyLockReport|null;
  readonly outputDirectory:string;
  readonly artifacts:CliBuildArtifacts&{
    readonly modules:readonly WrittenModuleArtifact[];
  };
  readonly typescriptVersion:string;
}

export interface VerifiedBuildResult {
  readonly report:VerifiedBuildReport;
  readonly verifiedIr:VerifiedIrModule;
  readonly jsPath:string;
}

export type BuildResult=VerifiedBuildResult;

export type VerifiedRunReport=Omit<VerifiedBuildReport,'command'>&{
  readonly command:'run';
  readonly mainResult:unknown;
};

export type RunReport=VerifiedRunReport;
