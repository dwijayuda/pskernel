// CI-only platform ABI probe; not a compiler qualification or installation claim.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
import {readQualifiedArtifact, sha256} from '../scripts/kernel435-qualified-artifact.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
process.chdir(root);
assert.equal(process.platform, 'linux'); assert.ok(['x64', 'arm64'].includes(process.arch));
assert.equal(process.versions.node, '22.23.3'); assert.equal(process.argv.length, 2);
const platform = 'linux-' + process.arch;
const out = path.resolve('dist/platform-preflight');
assert.ok(!fs.existsSync(out)); fs.mkdirSync(out, {recursive:true});
const json = value => JSON.stringify(value, null, 2) + '\n';
const put = (file, value) => {fs.mkdirSync(path.dirname(file), {recursive:true}); fs.writeFileSync(file, value);};
const read = file => JSON.parse(fs.readFileSync(file, 'utf8'));
const report = {schema:'psc1-platform-abi-preflight/1', status:'running',
  testedCommit:process.env.GITHUB_SHA, runId:process.env.GITHUB_RUN_ID,
  environmentId:process.env.PSC1_QUALIFICATION_ENVIRONMENT, platform,
  startedAt:new Date().toISOString(), observations:[],
  fullCompilerQualified:false, admissionCached:false};
const save = () => put(path.join(out, 'preflight.json'), json(report));
process.on('uncaughtExceptionMonitor', error => {
  report.status='failed'; report.error={message:String(error.message),cause:error.cause??null};save();
});
function run(label, exe, args, options={}) {
  const before=Date.now(), result=spawnSync(exe,args,{encoding:'utf8',timeout:120000,maxBuffer:16*1024*1024,...options});
  const stdout=Buffer.isBuffer(result.stdout)?result.stdout:Buffer.from(result.stdout??'');
  const stderr=Buffer.isBuffer(result.stderr)?result.stderr:Buffer.from(result.stderr??'');
  put(path.join(out,'logs',label+'.stdout'),stdout);put(path.join(out,'logs',label+'.stderr'),stderr);
  const observation={label,executable:exe,args,status:result.status,signal:result.signal,error:result.error?String(result.error):null,
    elapsedMs:Date.now()-before,stdoutSha256:sha256(stdout),stderrSha256:sha256(stderr)};
  report.observations.push(observation);save();
  assert.equal(result.error,undefined,String(result.error));assert.equal(result.status,0,stdout.toString()+stderr.toString());
  return options.encoding===null?stdout:stdout.toString('utf8');
}
const shaEnvironment=sha256;
function environmentFacts(directory) {
  const limited = (value, maximum = 512) =>
    typeof value === 'string' ? value.slice(0, maximum) : null;
  const releasePath = '/etc/os-release';
  const releaseFd = fs.openSync(releasePath, 'r');
  let releaseBytes;
  try {
    const releaseStat = fs.fstatSync(releaseFd);
    assert.ok(releaseStat.isFile() && releaseStat.size > 0 && releaseStat.size <= 16384,
      'bounded regular OS release metadata required');
    const buffer = Buffer.alloc(16385);
    const length = fs.readSync(releaseFd, buffer, 0, buffer.length, 0);
    assert.ok(length <= 16384 && length === releaseStat.size, 'OS release metadata changed');
    releaseBytes = buffer.subarray(0, length);
  } finally { fs.closeSync(releaseFd); }
  const header = process.report.getReport().header;
  const filesystem = fs.statfsSync(directory, { bigint: true });
  const versions = Object.fromEntries(Object.entries(process.versions)
    .filter(([name, value]) => /^[A-Za-z0-9_-]{1,64}$/.test(name) && typeof value === 'string')
    .slice(0, 64).map(([name, value]) => [name, limited(value, 128)]));
  return {
    schema: 'psc1-independent-environment/1',
    platform: process.platform, arch: process.arch,
    kernel: { release: limited(os.release()), version: limited(os.version(), 1024) },
    runtime: { version: process.version, versions,
      glibcVersionRuntime: limited(header.glibcVersionRuntime, 128),
      glibcVersionCompiler: limited(header.glibcVersionCompiler, 128) },
    osRelease: { bytes: releaseBytes.length, sha256: shaEnvironment(releaseBytes),
      text: new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(releaseBytes) },
    filesystem: Object.fromEntries(['type', 'bsize', 'blocks', 'bfree', 'bavail', 'files', 'ffree']
      .map(name => [name, String(filesystem[name])])),
    user: { uid: process.getuid(), gid: process.getgid() }
  };
}
report.environment=environmentFacts(out);save();
const pin={run:40509034127,job:122205738648,artifact:12736781848,
  commit:'892e1895b6be54f2fff4957a66b34d293c4105b8',
  zipSha256:'c88036b06889606bcc3bc4b9af2d888ccffe2d1330187e932e2602230d1e0eff'};
const archive=await readQualifiedArtifact(pin,path.join(out,'qualified-native'));
function findTar(directory) {
 const hits=[];
 for(const name of fs.readdirSync(directory)){const file=path.join(directory,name),stat=fs.lstatSync(file);
  assert.ok(!stat.isSymbolicLink());if(stat.isDirectory())hits.push(...findTar(file));
  else if(name==='proofscript-pskernel-lean-4.35.0-psc1.13.tgz')hits.push(file);}
 return hits;
}
const archives=findTar(archive);assert.equal(archives.length,1);
const bytes=fs.readFileSync(archives[0]);assert.equal(bytes.length,6453041);
assert.equal(sha256(bytes),'472eff8cf60b17bbb551d1ef1a331c417fd4833dccd86478a6ae5242fe20bbc7');
const names=run('native-archive-list','tar',['tzf',archives[0]]).trim().split('\n');
assert.ok(names.every(name=>name.startsWith('package/')&&!name.split('/').includes('..')));
const unpacked=path.join(out,'native');fs.mkdirSync(unpacked);
run('native-archive-extract','tar',['xzf',archives[0],'--no-same-owner','-C',unpacked]);
const nativeRoot=path.join(unpacked,'package/dist/implementation');
const manifest=read(path.join(nativeRoot,'PREBUILT_MANIFEST.json'));
assert.equal(manifest.leanVersion,'4.35.0');assert.equal(manifest.leanCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
assert.equal(manifest.protocol,'pskernel-lean/1');assert.equal(manifest.provider,'lean4-cpp');
const target=manifest.targets[platform];assert.ok(target);
assert.ok(/^[a-zA-Z0-9_./-]+$/.test(target.path)&&!target.path.split('/').includes('..'));
const checker=path.join(nativeRoot,target.path),checkerBytes=fs.readFileSync(checker);
assert.equal(checkerBytes.length,target.size);assert.equal(sha256(checkerBytes),target.sha256);
const prefix='node-v22.23.3-'+platform, runtimeArchive=prefix+'.tar.xz';
async function fetchBytes(url){const result=await fetch(url,{signal:AbortSignal.timeout(120000)});assert.equal(result.status,200);
 const data=Buffer.from(await result.arrayBuffer());assert.ok(data.length<256*1024*1024);return data;}
const upstream='https://nodejs.org/dist/v22.23.3/',sums=await fetchBytes(upstream+'SHASUMS256.txt');
const sum=sums.toString().split('\n').find(line=>line.trim().endsWith('  '+runtimeArchive));assert.ok(sum);
const archiveSha256=sum.split(/\s+/)[0];assert.match(archiveSha256,/^[0-9a-f]{64}$/);
const downloaded=await fetchBytes(upstream+runtimeArchive);assert.equal(sha256(downloaded),archiveSha256);
const runtimeTar=path.join(out,runtimeArchive);put(runtimeTar,downloaded);
const runtimeExtract=path.join(out,'runtime-extract');fs.mkdirSync(runtimeExtract);
run('runtime-archive-extract','tar',['xf',runtimeTar,'--no-same-owner','-C',runtimeExtract,prefix+'/bin/node']);
const runtimeFile=path.join(runtimeExtract,prefix,'bin/node'),runtimeStat=fs.lstatSync(runtimeFile);
assert.ok(runtimeStat.isFile()&&!runtimeStat.isSymbolicLink()&&runtimeStat.size>0&&runtimeStat.size<256*1024*1024);
const runtimeBytes=fs.readFileSync(runtimeFile);
assert.equal(sha256(runtimeBytes),sha256(fs.readFileSync(process.execPath)));
const runtime=path.join(out,'psc-runtime');put(runtime,runtimeBytes);fs.chmodSync(runtime,0o755);
report.native={input:pin,manifestSha256:sha256(fs.readFileSync(path.join(nativeRoot,'PREBUILT_MANIFEST.json'))),target};
report.runtime={version:'22.23.3',upstream,archive:runtimeArchive,archiveSha256,
 executableBytes:runtimeBytes.length,executableSha256:sha256(runtimeBytes),verification:'official HTTPS release SHA256; no signature claim'};
save();
assert.equal(run('private-runtime-version',runtime,['--version']).trim(),'v22.23.3');
const health=JSON.parse(run('genuine-checker-health',checker,['--health']));
assert.equal(health.leanVersion,'4.35.0');assert.equal(health.leanCommit,manifest.leanCommit);assert.equal(health.provider,'lean4-cpp');
report.checkerHealth=health;
const libraries=new Map();
for(const [label,file] of [['runtime',runtime],['checker',checker],['shell',fs.realpathSync('/bin/sh')]]){
 const listing=run(label+'-system-libraries','ldd',[file]);assert.ok(!listing.includes('not found'),listing);
 for(const match of listing.matchAll(/(?:=>\s*)?(\/[^\s()]+)\s+\(/g)){
  const absolute=match[1];assert.ok(absolute.startsWith('/lib/')||absolute.startsWith('/lib64/')||
   absolute.startsWith('/usr/lib/'+(process.arch==='arm64'?'aarch64':'x86_64')+'-linux-gnu/'));
  const value=fs.readFileSync(absolute);libraries.set(absolute,{path:absolute,realPath:fs.realpathSync(absolute),bytes:value.length,sha256:sha256(value)});
 }
}
assert.ok(libraries.size>0);report.systemLibraries=[...libraries.values()].sort((a,b)=>a.path.localeCompare(b.path));
const shell=fs.realpathSync('/bin/sh'),shellBytes=fs.readFileSync(shell);
report.shell={path:shell,bytes:shellBytes.length,sha256:sha256(shellBytes)};
report.status='passed-runtime-kernel-abi-preflight';report.completedAt=new Date().toISOString();save();
console.log('PSC1_PLATFORM_ABI_PREFLIGHT: '+JSON.stringify(report));
