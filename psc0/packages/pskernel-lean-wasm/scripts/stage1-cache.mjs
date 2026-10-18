// Reproducible, pinned, integrity-checked cache for expensive Lean 4.35.0
// stage0 i386 and stage1 wasm32 libraries. NEVER marks a proof kernel
// qualified: native/Wasm admission, identity, and transport still run afresh.
// Source SHA, compatibility patch and build flags, toolchain fingerprint, and
// every relevant target .olean and .a are bound before reuse.
import {createHash} from 'node:crypto';
import {createReadStream} from 'node:fs';
import {readdir,readFile,writeFile,mkdir,stat,realpath} from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const packageRoot=path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const stampName='.psc0-stage1-cache-manifest.json';
const inputFiles=[
  'LEAN_SOURCE_PIN.json','EMSCRIPTEN_PIN.json',
  'scripts/build-wasm.sh','scripts/apply-lean435-compat.mjs',
  'scripts/stage1-cache.mjs',
  'scripts/verify-lean435-runtime.mjs',
];
const required=[
  'stage0/bin/lean','stage1/leanc.sh',
  'stage1/lib/temp/libleancpp_1.a',
  'stage1/lib/lean/libleanrt.a',
  'stage1/lib/lean/libInit.a',
  'stage1/lib/lean/libStd.a',
  'stage1/lib/lean/libLean.a',
  'stage1/lib/lean/Lean.olean',
];
const upstream='eb6cafb7290e8bd5f2937522d8d804f58f02bafc';

async function digest(file) {
  const hash=createHash('sha256');
  await new Promise((resolve,reject)=>{
    const stream=createReadStream(file);
    stream.on('data',chunk=>hash.update(chunk));
    stream.on('end',resolve);
    stream.on('error',reject);
  });
  return hash.digest('hex');
}
async function inputsSha256() {
  const hash=createHash('sha256');
  for(const name of inputFiles){
    hash.update(name+'\u0000');
    hash.update(await readFile(path.join(packageRoot,name)));
    hash.update('\u0000');
  }
  return hash.digest('hex');
}
export function actualToolchainIdentity(){
  const capture=(program,args)=>{
    const out=execFileSync(program,args,{encoding:'utf8',timeout:20000});
    return out.trim().split(/\r?\n/)[0];
  };
  const emcc=capture('emcc',['--version']);
  if(!emcc.includes('6.0.9'))throw Error('cache toolchain is not Emscripten 6.0.9');
  return {emcc,clang:capture('clang++',['--version']),
    platform:process.platform,arch:process.arch};
}
async function discover(buildDir) {
  const dest=new Set(required);
  const libraryDir=path.join(buildDir,'stage1/lib/lean');
  async function walk(dir){
    for(const entry of await readdir(dir,{withFileTypes:true})){
      const full=path.join(dir,entry.name);
      if(entry.isDirectory())await walk(full);
      else if(entry.name.endsWith('.olean') || entry.name.endsWith('.a'))
        dest.add(path.relative(buildDir,full).replaceAll(path.sep,'/'));
    }
  }
  await walk(libraryDir);
  const found=[...dest].sort();
  if(found.filter(x=>x.endsWith('.olean')).length<100)
    throw Error('cache lacks the complete official wasm32 Lean .olean sysroot');
  for(const name of required)if(!dest.has(name))throw Error('missing mandatory '+name);
  return found;
}
async function asset(buildDir,name) {
  if(name.startsWith('/')||name.includes('..')||name.includes('\\'))
    throw Error('unsafe cache asset path '+name);
  const file=path.join(buildDir,name);
  const resolved=await realpath(file);
  if(!resolved.startsWith(buildDir+path.sep))
    throw Error('cache asset escaped build directory: '+name);
  const metadata=await stat(file);
  if(!metadata.isFile()||metadata.size<=0)throw Error('missing/empty cache asset '+name);
  return {path:name,bytes:metadata.size,sha256:await digest(file)};
}
async function identity(buildDir,toolchain){
  if(!toolchain||typeof toolchain!=='object')throw Error('missing toolchain fingerprint');
  const pin=JSON.parse(await readFile(path.join(packageRoot,'LEAN_SOURCE_PIN.json'),'utf8'));
  const em=JSON.parse(await readFile(path.join(packageRoot,'EMSCRIPTEN_PIN.json'),'utf8'));
  if(pin.leanCommit!==upstream||pin.leanVersion!=='4.35.0'||pin.memoryModel!=='linear'||
     pin.languageProfile!=='pscv0-v7.2'||em.version!=='6.0.9')
    throw Error('stage1 cache source or target pin mismatch');
  return {schemaVersion:1,buildDir,upstreamCommit:upstream,
    inputDigest:await inputsSha256(),toolchain};
}
export async function sealStage1(buildPath,toolchain) {
  const dir=path.resolve(buildPath);
  const root=await identity(dir,toolchain);
  const names=await discover(dir);
  const files=[];
  for(const name of names)files.push(await asset(dir,name));
  const manifest={...root,files};
  await mkdir(dir,{recursive:true});
  await writeFile(path.join(dir,stampName),JSON.stringify(manifest,null,2)+'\n',{mode:0o600});
  console.log('PSC0_STAGE1_CACHE_SEALED '+files.length+' immutable target assets');
  return manifest;
}
export async function verifyStage1(buildPath,toolchain) {
  const dir=path.resolve(buildPath);
  const saved=JSON.parse(await readFile(path.join(dir,stampName),'utf8'));
  const expected=await identity(dir,toolchain);
  for(const key of ['schemaVersion','buildDir','upstreamCommit','inputDigest']){
    if(saved[key]!==expected[key])throw Error('stage1 cache identity mismatch: '+key);
  }
  if(JSON.stringify(saved.toolchain)!==JSON.stringify(expected.toolchain))
    throw Error('stage1 cache compiler fingerprint mismatch');
  const list=await discover(dir);
  if(JSON.stringify(saved.files.map(x=>x.path))!==JSON.stringify(list))
    throw Error('stage1 cache target library or olean file set changed');
  for(let i=0;i<list.length;i++){
    const current=await asset(dir,list[i]),record=saved.files[i];
    if(current.bytes!==record?.bytes || current.sha256!==record?.sha256)
      throw Error('stage1 cache corrupted or changed: '+list[i]);
  }
  console.log('PSC0_STAGE1_CACHE_VERIFIED '+list.length+' immutable target assets');
  return saved;
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  const cmd=process.argv[2],root=process.argv[3];
  if(!root||!['seal','verify'].includes(cmd))
    throw Error('usage: node stage1-cache.mjs <seal|verify> <lean4-build-directory>');
  const toolchain=actualToolchainIdentity();
  if(cmd==='seal')await sealStage1(root,toolchain);
  else await verifyStage1(root,toolchain);
}
