import {spawn,spawnSync} from 'node:child_process';
import {createWriteStream,existsSync} from 'node:fs';
import {pipeline} from 'node:stream/promises';
import {createInterface} from 'node:readline';
import {delimiter,dirname,join,resolve} from 'node:path';
import {createModuleArtifact} from '@proofscript/module';

function fail(message){throw new Error(`@proofscript/lean4export: ${message}`);}

export function parseLeanVersion(text){
  const line=String(text).split(/\r?\n/,1)[0]?.trim()??'';
  const m=/Lean \(version ([^,\s)]+).*commit ([0-9a-f]+).*?(Release|Debug|RelWithDebInfo)?\)?/i.exec(line)
    ?? /Lean \(version ([^,\s)]+)/i.exec(line);
  if(!m)return {line,version:null,commit:null,build:null};
  return {
    line,
    version:m[1]??null,
    commit:m[2]??null,
    build:m[3]??null
  };
}

export function discoverLean({
  binDir,
  expectedVersion='4.34.0',
  env=process.env
}={}){
  const exeName=process.platform==='win32'?'lean.exe':'lean';
  const candidates=[
    binDir,
    env.LEAN434_BIN,
    ...(env.PATH??'').split(delimiter)
  ].filter(Boolean).map(p=>resolve(p));
  const found=candidates.find(p=>existsSync(join(p,exeName)));
  if(!found)fail(`Lean executable '${exeName}' not found; set binDir/LEAN434_BIN or PATH`);
  const executable=join(found,exeName);
  const r=spawnSync(executable,['--version'],{encoding:'utf8',env});
  if(r.error)throw r.error;
  if(r.status!==0)fail(`Lean --version exited ${r.status}: ${String(r.stderr??'').trim()}`);
  const info=parseLeanVersion(r.stdout);
  if(!info.version)fail(`could not parse Lean version from: ${info.line}`);
  if(expectedVersion!==null&&info.version!==expectedVersion)
    fail(`expected Lean ${expectedVersion}, got ${info.version}`);
  return {
    ...info,
    binDir:found,
    executable
  };
}

function childEnv(toolchain,env){
  return {...env,PATH:`${toolchain.binDir}${delimiter}${env.PATH??''}`};
}

export function spawnLeanExporter({
  script,
  moduleName,
  args=[],
  cwd=process.cwd(),
  binDir,
  expectedVersion='4.34.0',
  env=process.env,
  stdio=['ignore','pipe','pipe']
}){
  if(typeof script!=='string'||script.length===0)fail('script is required');
  if(typeof moduleName!=='string'||moduleName.length===0)fail('moduleName is required');
  const toolchain=discoverLean({binDir,expectedVersion,env});
  const scriptPath=resolve(cwd,script);
  const child=spawn(toolchain.executable,['--run',scriptPath,moduleName,...args],{
    cwd:resolve(cwd),
    env:childEnv(toolchain,env),
    stdio
  });
  return {toolchain,child,scriptPath};
}

export async function* streamLeanExporterLines(options){
  const {toolchain,child}=spawnLeanExporter(options);
  if(!child.stdout||!child.stderr)fail('streaming requires piped stdout/stderr');
  let stderr='';
  child.stderr.setEncoding('utf8');
  child.stderr.on('data',d=>stderr+=d);
  const rl=createInterface({input:child.stdout,crlfDelay:Infinity});
  for await(const line of rl)yield line;
  const [code,signal]=await new Promise(resolve=>child.on('close',(c,s)=>resolve([c,s])));
  if(code!==0||signal)fail(`Lean exporter exited code=${code} signal=${signal??'none'}\n${stderr}`);
  void toolchain;
}

export async function collectLeanExport(options,{maxBytes=64*1024*1024}={}){
  if(!Number.isSafeInteger(maxBytes)||maxBytes<1024)fail('maxBytes must be an integer >= 1024');
  const {child,toolchain}=spawnLeanExporter(options);
  if(!child.stdout||!child.stderr)fail('collection requires piped stdout/stderr');
  let stdout='',stderr='',bytes=0;
  child.stdout.setEncoding('utf8');child.stderr.setEncoding('utf8');
  child.stdout.on('data',d=>{
    bytes+=Buffer.byteLength(d,'utf8');
    if(bytes>maxBytes){child.kill('SIGKILL');return;}
    stdout+=d;
  });
  child.stderr.on('data',d=>stderr+=d);
  const [code,signal]=await new Promise(resolve=>child.on('close',(c,s)=>resolve([c,s])));
  if(bytes>maxBytes)fail(`export exceeded maxBytes=${maxBytes}`);
  if(code!==0||signal)fail(`Lean exporter exited code=${code} signal=${signal??'none'}\n${stderr}`);
  return {text:stdout,stderr,toolchain};
}

export async function exportLeanToFile(options,output){
  const outPath=resolve(output);
  const {child,toolchain}=spawnLeanExporter(options);
  if(!child.stdout||!child.stderr)fail('file export requires piped stdout/stderr');
  let stderr='';
  child.stderr.setEncoding('utf8');child.stderr.on('data',d=>stderr+=d);
  const piping=pipeline(child.stdout,createWriteStream(outPath));
  const [code,signal]=await new Promise(resolve=>child.on('close',(c,s)=>resolve([c,s])));
  await piping;
  if(code!==0||signal)fail(`Lean exporter exited code=${code} signal=${signal??'none'}\n${stderr}`);
  return {file:outPath,stderr,toolchain};
}

export async function exportLeanModuleArtifact({
  artifactModule,
  dependencies=[],
  metadata,
  maxBytes,
  ...exportOptions
}){
  if(typeof artifactModule!=='string'||artifactModule.length===0)fail('artifactModule is required');
  const {text,toolchain}=await collectLeanExport(exportOptions,{maxBytes});
  return {
    artifact:createModuleArtifact({
      module:artifactModule,
      declarations:text,
      dependencies,
      kernel:{
        semantics:'lean4',
        leanVersion:toolchain.version,
        apiVersion:'0.1.0'
      },
      metadata
    }),
    toolchain
  };
}

export function defaultDependencyExporterPath(repoRoot=process.cwd()){
  return join(resolve(repoRoot),'oracle','replay-probe','DependencyExport.lean');
}
