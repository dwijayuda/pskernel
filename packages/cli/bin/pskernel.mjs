#!/usr/bin/env node
import {createReadStream,readFileSync,writeFileSync} from 'node:fs';
import {createInterface} from 'node:readline';
import {resolve} from 'node:path';
import {Lean4ExportReplay} from 'lean-ts-kernel/lean4export';
import {
  createModuleArtifact,
  decodeModuleArtifact,
  encodeModuleArtifact,
  loadModuleArtifact,
  moduleArtifactSummary,
  verifyModuleArtifact
} from '@proofscript/module';

function usage(code=0){
  const out=code===0?console.log:console.error;
  out(`usage:
  pskernel replay <lean4export.ndjson>
  pskernel check <lean4export.ndjson>

  pskernel module pack <module-name> <lean4export.ndjson> <out.psmodule>
  pskernel module verify <module.psmodule>
  pskernel module inspect <module.psmodule>
  pskernel module check <module.psmodule>

  pskernel --help`);
  process.exit(code);
}

async function replayFile(file){
  const path=resolve(file);
  const replay=new Lean4ExportReplay();
  const rl=createInterface({
    input:createReadStream(path,{encoding:'utf8'}),
    crlfDelay:Infinity
  });
  for await(const line of rl) replay.replayLine(line);
  const stats=replay.finish();
  return {ok:true,file:path,stats,constants:replay.env.size};
}

function readArtifact(file){
  const path=resolve(file);
  return {path,artifact:decodeModuleArtifact(readFileSync(path,'utf8'))};
}

async function run(argv){
  const [cmd,...rest]=argv;
  if(cmd===undefined||cmd==='--help'||cmd==='-h')usage(0);

  if(cmd==='replay'||cmd==='check'){
    if(rest.length!==1)usage(2);
    return replayFile(rest[0]);
  }

  if(cmd==='module'){
    const [sub,...args]=rest;
    if(sub==='pack'){
      if(args.length!==3)usage(2);
      const [moduleName,input,output]=args;
      const artifact=createModuleArtifact({
        module:moduleName,
        declarations:readFileSync(resolve(input),'utf8')
      });
      const outPath=resolve(output);
      writeFileSync(outPath,encodeModuleArtifact(artifact),'utf8');
      return {ok:true,action:'module-pack',file:outPath,...moduleArtifactSummary(artifact)};
    }
    if(sub==='verify'){
      if(args.length!==1)usage(2);
      const {path,artifact}=readArtifact(args[0]);
      verifyModuleArtifact(artifact);
      return {ok:true,action:'module-verify',file:path,...moduleArtifactSummary(artifact)};
    }
    if(sub==='inspect'){
      if(args.length!==1)usage(2);
      const {path,artifact}=readArtifact(args[0]);
      return {ok:true,action:'module-inspect',file:path,...moduleArtifactSummary(artifact)};
    }
    if(sub==='check'){
      if(args.length!==1)usage(2);
      const {path,artifact}=readArtifact(args[0]);
      const loaded=loadModuleArtifact(artifact);
      return {
        ok:true,
        action:'module-check',
        file:path,
        module:loaded.module,
        integrity:loaded.integrity,
        stats:loaded.stats,
        constants:loaded.env.size
      };
    }
    usage(2);
  }

  usage(2);
}

try{
  const result=await run(process.argv.slice(2));
  console.log(JSON.stringify(await result,null,2));
}catch(error){
  console.error(JSON.stringify({
    ok:false,
    error:error instanceof Error?(error.stack??error.message):String(error)
  },null,2));
  process.exit(1);
}
