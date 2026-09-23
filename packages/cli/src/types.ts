import type {CheckedSoftwareModule,SoftwareType} from '@proofscript/language';
import type {VerifiedIrModule} from '@proofscript/compiler-ir/verified';
import type {TranslationTarget} from '@proofscript/syntax';
import type {LoadedPsConfig} from './config.js';

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

export interface BuildResult {
  readonly report:Record<string,unknown>;
  readonly checked?:CheckedSoftwareModule;
  readonly verifiedIr?:VerifiedIrModule;
  readonly jsPath:string;
}

export interface RuntimeArgument {
  readonly text:string;
  readonly type:SoftwareType;
}
