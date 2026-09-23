import type {CheckedSoftwareModule,SoftwareType} from '@proofscript/language';
import type {LoadedPsConfig} from './config.js';

export interface CommonArgs {
  readonly entry?:string;
  readonly project?:string;
  readonly json:boolean;
  readonly passthrough:readonly string[];
}

export interface ResolvedInput {
  readonly loaded:LoadedPsConfig;
  readonly sourcePath:string;
  readonly source:string;
}

export interface BuildResult {
  readonly report:Record<string,unknown>;
  readonly checked:CheckedSoftwareModule;
  readonly jsPath:string;
}

export interface RuntimeArgument {
  readonly text:string;
  readonly type:SoftwareType;
}
