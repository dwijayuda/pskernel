import {existsSync,readFileSync} from 'node:fs';
import {dirname,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {Environment} from 'lean-ts-kernel';
import {
  PROOFSCRIPT_LEAN_VERSION,
  replayLeanEnvironment,
} from './index.js';

export interface LeanEnvironmentStatus {
  readonly loaded:boolean;
  readonly source?:string;
  readonly message?:string;
  readonly declarations?:number;
}

export interface LeanEnvironmentProvider {
  create():Environment;
  status():LeanEnvironmentStatus;
}

export interface LeanEnvironmentProviderOptions {
  readonly candidatePaths?:readonly string[];
  readonly expectedLeanVersion?:string;
}

function defaultCandidates():readonly string[] {
  const here=dirname(fileURLToPath(import.meta.url));
  return [
    process.env.PROOFSCRIPT_LEAN_FOUNDATION??'',
    process.env.PROOFSCRIPT_INIT_PRELUDE??'',
    resolve(process.cwd(),'oracle/fixtures/lean434-init-prelude.ndjson'),
    resolve(here,'../../../../oracle/fixtures/lean434-init-prelude.ndjson'),
  ].filter((value)=>value.length>0);
}

export function createLeanEnvironmentProvider(
  options:LeanEnvironmentProviderOptions={},
):LeanEnvironmentProvider {
  let base:Environment|undefined;
  let currentStatus:LeanEnvironmentStatus={
    loaded:false,
    message:'Lean environment has not been loaded yet.',
  };
  let attempted=false;

  const ensure=():void=>{
    if(attempted)return;
    attempted=true;
    const candidates=options.candidatePaths??defaultCandidates();
    const source=candidates.find((path)=>existsSync(path));
    if(source===undefined){
      currentStatus={
        loaded:false,
        message:
          'Lean 4.34 compiler base/Init.Prelude replay fixture was not found; '+
          'the caller must fail closed or explicitly choose an empty environment.',
      };
      return;
    }

    try{
      const replayed=replayLeanEnvironment(
        readFileSync(source,'utf8'),
        options.expectedLeanVersion??PROOFSCRIPT_LEAN_VERSION,
      );
      base=replayed.environment;
      currentStatus={
        loaded:true,
        source,
        declarations:base.size,
      };
    }catch(error){
      currentStatus={
        loaded:false,
        source,
        message:
          'Failed to replay Lean environment: '+
          (error instanceof Error?error.message:String(error)),
      };
    }
  };

  return {
    create(){
      ensure();
      return base?.clone()??new Environment();
    },
    status(){
      ensure();
      return currentStatus;
    },
  };
}

export function requireLeanEnvironment(
  provider:LeanEnvironmentProvider,
):Environment {
  const status=provider.status();
  if(!status.loaded){
    throw new Error(
      'PS_ENV_INIT_PRELUDE_REQUIRED: '+
      (status.message??'Lean Init.Prelude environment is unavailable'),
    );
  }
  return provider.create();
}
