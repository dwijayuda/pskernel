import {existsSync,readFileSync} from 'node:fs';
import {dirname,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {
  Environment,
  Lean4ExportReplay,
} from 'lean-ts-kernel';

export interface EditorEnvironmentStatus {
  readonly loaded:boolean;
  readonly source?:string;
  readonly message?:string;
  readonly declarations?:number;
}

export interface EditorEnvironmentProvider {
  create():Environment;
  status():EditorEnvironmentStatus;
}

export interface EditorEnvironmentOptions {
  readonly candidatePaths?:readonly string[];
}

function defaultCandidates():readonly string[] {
  const here=dirname(fileURLToPath(import.meta.url));
  return [
    process.env.PROOFSCRIPT_INIT_PRELUDE??'',
    resolve(process.cwd(),'oracle/fixtures/lean434-init-prelude.ndjson'),
    resolve(here,'../../../../oracle/fixtures/lean434-init-prelude.ndjson'),
  ].filter((value)=>value.length>0);
}

export function createInitPreludeEnvironmentProvider(
  options:EditorEnvironmentOptions={},
):EditorEnvironmentProvider {
  let base:Environment|undefined;
  let currentStatus:EditorEnvironmentStatus={
    loaded:false,
    message:'Init.Prelude environment has not been loaded yet.',
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
          'Lean 4.34 Init.Prelude replay fixture was not found; '+
          'editor checking uses an empty environment and reports unresolved names as unsupported.',
      };
      return;
    }

    try{
      const text=readFileSync(source,'utf8');
      const replay=new Lean4ExportReplay(
        new Environment(),
        {expectedLeanVersion:'4.34.0'},
      );
      replay.replay(text);
      base=replay.env;
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
          'Failed to replay Init.Prelude for editor analysis: '+
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
