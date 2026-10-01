import {existsSync,readFileSync} from 'node:fs';
import {dirname,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {Environment} from 'lean-ts-kernel';
import {
  PROOFSCRIPT_LEAN_VERSION,
  replayLeanEnvironment,
  replayLeanEnvironmentInto,
} from './index.js';

export interface LeanEnvironmentStatus {
  readonly loaded:boolean;
  readonly source?:string;
  readonly foundationSource?:string;
  readonly message?:string;
  readonly declarations?:number;
}

export interface LeanEnvironmentProvider {
  create():Environment;
  status():LeanEnvironmentStatus;
}

export interface LeanEnvironmentProviderOptions {
  readonly candidatePaths?:readonly string[];
  readonly foundationCandidatePaths?:readonly string[];
  readonly expectedLeanVersion?:string;
}

function defaultBaseCandidates():readonly string[] {
  const here=dirname(fileURLToPath(import.meta.url));
  return [
    process.env.PROOFSCRIPT_INIT_PRELUDE??'',
    resolve(process.cwd(),'oracle/fixtures/lean434-init-prelude.ndjson'),
    resolve(here,'../../../../oracle/fixtures/lean434-init-prelude.ndjson'),
  ].filter((value)=>value.length>0);
}

function defaultFoundationCandidates():readonly string[] {
  const here=dirname(fileURLToPath(import.meta.url));
  return [
    process.env.PROOFSCRIPT_LEAN_FOUNDATION??'',
    resolve(
      process.cwd(),
      'oracle/fixtures/lean434-proofscript-selfhost-foundation.ndjson',
    ),
    resolve(
      here,
      '../../../../oracle/fixtures/lean434-proofscript-selfhost-foundation.ndjson',
    ),
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
    const candidates=options.candidatePaths??defaultBaseCandidates();
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

    const expectedLeanVersion=
      options.expectedLeanVersion??PROOFSCRIPT_LEAN_VERSION;
    const foundationCandidates=
      options.foundationCandidatePaths
      ??(options.candidatePaths===undefined
        ?defaultFoundationCandidates()
        :[]);
    const foundationSource=foundationCandidates.find(
      (path)=>existsSync(path),
    );
    if(foundationCandidates.length>0&&foundationSource===undefined){
      currentStatus={
        loaded:false,
        source,
        message:
          'Lean 4.34 ProofScript self-host foundation delta was not found; '+
          'the verified compiler requires the pinned base plus foundation delta.',
      };
      return;
    }

    try{
      const replayed=replayLeanEnvironment(
        readFileSync(source,'utf8'),
        expectedLeanVersion,
      );
      const completed=foundationSource===undefined
        ?replayed
        :replayLeanEnvironmentInto(
          replayed.environment,
          readFileSync(foundationSource,'utf8'),
          expectedLeanVersion,
        );
      base=completed.environment;
      currentStatus={
        loaded:true,
        source,
        ...(foundationSource===undefined?{}:{foundationSource}),
        declarations:base.size,
      };
    }catch(error){
      currentStatus={
        loaded:false,
        source,
        ...(foundationSource===undefined?{}:{foundationSource}),
        message:
          'Failed to replay Lean compiler environment: '+
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
