#!/usr/bin/env node
import {createReadStream,readFileSync,writeFileSync} from 'node:fs';
import {createInterface} from 'node:readline';
import {resolve} from 'node:path';
import {Lean4ExportReplay} from 'lean-ts-kernel/lean4export';
import {createModuleArtifact,decodeModuleArtifact,encodeModuleArtifact,loadModuleArtifact,moduleArtifactSummary,verifyModuleArtifact,type ModuleArtifact} from '@proofscript/module';

function usage(code=0):never {
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

async function replayFile(file:string):Promise<Record<string,unknown>>{
  const path=resolve(file),replay=new Lean4ExportReplay(),rl=createInterface({input:createReadStream(path,{encoding:'utf8'}),crlfDelay:Infinity});
  for await(const line of rl)replay.replayLine(line);
  const stats=replay.finish();
  return {ok:true,file:path,stats,constants:replay.env.size};
}
function readArtifact(file:string):{path:string;artifact:ModuleArtifact}{
  const path=resolve(file);
  return {path,artifact:decodeModuleArtifact(readFileSync(path,'utf8'))};
}
async function run(argv:readonly string[]):Promise<Record<string,unknown>>{
  const [cmd,...rest]=argv;
  if(cmd===undefined||cmd==='--help'||cmd==='-h')usage(0);
  if(cmd==='replay'||cmd==='check'){
    if(rest.length!==1||rest[0]===undefined)usage(2);
    return replayFile(rest[0]);
  }
  if(cmd==='module'){
    const [sub,...args]=rest;
    if(sub==='pack'){
      if(args.length!==3)usage(2);
      const [moduleName,input,output]=args;
      if(moduleName===undefined||input===undefined||output===undefined)usage(2);
      const artifact=createModuleArtifact({module:moduleName,declarations:readFileSync(resolve(input),'utf8')}),outPath=resolve(output);
      writeFileSync(outPath,encodeModuleArtifact(artifact),'utf8');
      return {ok:true,action:'module-pack',file:outPath,...moduleArtifactSummary(artifact)};
    }
    if(sub==='verify'||sub==='inspect'||sub==='check'){
      if(args.length!==1||args[0]===undefined)usage(2);
      const {path,artifact}=readArtifact(args[0]);
      if(sub==='verify'){verifyModuleArtifact(artifact);return {ok:true,action:'module-verify',file:path,...moduleArtifactSummary(artifact)};}
      if(sub==='inspect')return {ok:true,action:'module-inspect',file:path,...moduleArtifactSummary(artifact)};
      const loaded=loadModuleArtifact(artifact);
      return {ok:true,action:'module-check',file:path,module:loaded.module,integrity:loaded.integrity,stats:loaded.stats,constants:loaded.env.size};
    }
    usage(2);
  }
  usage(2);
}
try{console.log(JSON.stringify(await run(process.argv.slice(2)),null,2));}
catch(error){console.error(JSON.stringify({ok:false,error:error instanceof Error?(error.stack??error.message):String(error)},null,2));process.exit(1);}
