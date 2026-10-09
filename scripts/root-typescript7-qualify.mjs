import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import {
  copyFileSync, existsSync, mkdirSync, readFileSync, realpathSync, statSync, writeFileSync,
} from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const output=path.join(root,'dist','typescript7-root');
const version='7.0.2';
const sourceRef=process.env.GITHUB_SHA;
assert.match(sourceRef??'',/^[a-f0-9]{40}$/,'run from the source-pinned GitHub workflow');
assert.equal(process.version,'v22.23.3');
assert.equal(process.argv.length,2,'no alternate compiler or compatibility profile is supported');
mkdirSync(output,{recursive:true});
const npm=process.platform==='win32'?'npm.cmd':'npm';
const commands=[];
const files=[];
const sha256=(bytes)=>createHash('sha256').update(bytes).digest('hex');
const readJson=(file)=>JSON.parse(readFileSync(file,'utf8'));
const relative=(file)=>path.relative(root,file).split(path.sep).join('/');
const packageDirectories=[
  'backend-ts','browser','checked-core','cli','compiler-ir','compiler','conformance','elab',
  'environment','erasure','language-service','lean4export','lsp','meta','module','pretty',
  'project','runtime','syntax','tactic',
];
const manifestPaths=['package.json',...packageDirectories.map((name)=>'packages/'+name+'/package.json')];

function git(args) {
  const result=spawnSync('git',args,{cwd:root,encoding:'utf8',timeout:30_000});
  assert.equal(result.error,undefined);
  assert.equal(result.status,0,result.stderr);
  return result.stdout.trim();
}
assert.equal(git(['rev-parse','HEAD']),sourceRef);

function run(name,args) {
  const started=Date.now();
  const result=spawnSync(npm,args,{
    cwd:root,encoding:'utf8',timeout:12*60_000,maxBuffer:64*1024*1024,
  });
  const stdout=result.stdout??'';
  const stderr=result.stderr??'';
  const stdoutPath=path.join(output,name+'.stdout.log');
  const stderrPath=path.join(output,name+'.stderr.log');
  writeFileSync(stdoutPath,stdout);
  writeFileSync(stderrPath,stderr);
  process.stdout.write(stdout);
  process.stderr.write(stderr);
  const record={
    name,command:['npm',...args],exitCode:result.status,signal:result.signal,
    elapsedMs:Date.now()-started,stdoutSha256:sha256(Buffer.from(stdout)),
    stderrSha256:sha256(Buffer.from(stderr)),
    ...(result.error?{executionError:String(result.error)}:{}),
  };
  commands.push(record);
  assert.equal(result.error,undefined,name+' execution failed');
  assert.equal(result.signal,null,name+' terminated');
  assert.equal(result.status,0,name+' failed');
}

function exactFile(file) {
  const bytes=readFileSync(file);
  const content=bytes.toString('utf8');
  assert.deepEqual(Buffer.from(content,'utf8'),bytes,'evidence must be exact UTF-8');
  const metadata={path:relative(file),sha256:sha256(bytes),bytes:bytes.length};
  const single=JSON.stringify({...metadata,content});
  files.push(metadata);
  if(Buffer.byteLength('PS_ROOT_TS7_EVIDENCE_FILE '+single)<=8192) {
    console.log('PS_ROOT_TS7_EVIDENCE_FILE '+single);
    return;
  }
  const fragments=[];
  for(let index=0;index<content.length;) {
    let stop=Math.min(index+1024,content.length);
    if(stop<content.length&&content.charCodeAt(stop-1)>=0xd800&&content.charCodeAt(stop-1)<=0xdbff&&
       content.charCodeAt(stop)>=0xdc00&&content.charCodeAt(stop)<=0xdfff)stop-=1;
    fragments.push(content.slice(index,stop));
    index=stop;
  }
  console.log('PS_ROOT_TS7_EVIDENCE_FILE_MANIFEST '+JSON.stringify({...metadata,chunkCount:fragments.length}));
  fragments.forEach((fragment,chunkIndex)=>{
    const payload=JSON.stringify({...metadata,chunkIndex,chunkCount:fragments.length,content:fragment});
    const line='PS_ROOT_TS7_EVIDENCE_FILE_CHUNK '+payload;
    assert.ok(Buffer.byteLength(line)<=8192,'bounded exact-content evidence line');
    console.log(line);
  });
}

let failure;
let profile;
let lockGenerated=false;
const startedAt=new Date().toISOString();
try {
  const manifests=manifestPaths.map((file)=>{
    const value=readJson(path.join(root,file));
    const dependency=value.dependencies?.typescript??value.devDependencies?.typescript;
    assert.equal(dependency,version,file+' must pin only the current compiler');
    return {path:file,value};
  });
  const rootManifest=manifests[0].value;
  assert.deepEqual(rootManifest.workspaces,['packages/*']);
  const lockPath=path.join(root,'package-lock.json');
  const priorLock=readJson(lockPath);
  const sameDependencies=(left={},right={})=>{
    const ordered=(value)=>JSON.stringify(Object.entries(value).sort(([a],[b])=>a.localeCompare(b)));
    return ordered(left)===ordered(right);
  };
  lockGenerated=manifests.some(({path:file,value})=>{
    const key=file==='package.json'?'':path.posix.dirname(file);
    const locked=priorLock.packages?.[key];
    return !locked||!sameDependencies(value.dependencies,locked.dependencies)||
      !sameDependencies(value.devDependencies,locked.devDependencies);
  });
  // Initial migration resolves the exact requested pins without installing TS5.
  // Once the authenticated lock is committed, future runs use npm ci directly.
  if(lockGenerated)run('resolve-lock',['install','--package-lock-only','--ignore-scripts','--no-audit','--no-fund']);
  const lock=readJson(lockPath);
  for(const {path:file,value} of manifests) {
    const key=file==='package.json'?'':path.posix.dirname(file);
    assert.ok(lock.packages?.[key],file+' lock entry missing');
    assert.ok(sameDependencies(value.dependencies,lock.packages[key].dependencies),file+' runtime lock drift');
    assert.ok(sameDependencies(value.devDependencies,lock.packages[key].devDependencies),file+' development lock drift');
  }
  for(const [name,entry] of Object.entries(lock.packages)) {
    if(name.endsWith('/typescript'))assert.equal(entry.version,version,name+' has a retired compiler');
    assert.ok(!name.includes('/@typescript/typescript5')&&!name.includes('/@typescript/typescript6'),
      'historical compiler API alias is not part of future development');
  }
  assert.equal(lock.packages['node_modules/typescript'].version,version);
  copyFileSync(lockPath,path.join(output,'package-lock.json'));
  exactFile(path.join(output,'package-lock.json'));
  run('install',['ci','--ignore-scripts','--no-audit','--no-fund']);
  assert.equal(sha256(readFileSync(lockPath)),sha256(readFileSync(path.join(output,'package-lock.json'))),
    'npm ci changed the authenticated lock');

  const require=createRequire(import.meta.url);
  const packageFile=realpathSync(require.resolve('typescript/package.json'));
  const metadata=readJson(packageFile);
  assert.equal(metadata.name,'typescript');
  assert.equal(metadata.version,version);
  assert.equal(typeof metadata.bin?.tsc,'string');
  const cli=realpathSync(path.resolve(path.dirname(packageFile),metadata.bin.tsc));
  const cliRelative=path.relative(path.dirname(packageFile),cli);
  assert.ok(cliRelative!==''&&cliRelative!=='..'&&!cliRelative.startsWith('..'+path.sep)&&!path.isAbsolute(cliRelative));
  assert.ok(statSync(cli).isFile());
  const reported=spawnSync(process.execPath,[cli,'--version'],{encoding:'utf8',timeout:30_000});
  assert.equal(reported.error,undefined);
  assert.equal(reported.status,0,reported.stderr);
  assert.equal(reported.stdout.trim(),'Version '+version);
  assert.equal(reported.stderr.trim(),'');
  const optionalDependencies=metadata.optionalDependencies??{};
  assert.equal(optionalDependencies['@typescript/typescript-'+process.platform+'-'+process.arch],version);
  assert.ok(Object.values(optionalDependencies).every((item)=>item===version));
  copyFileSync(packageFile,path.join(output,'installed-typescript-package.json'));
  profile={
    schemaVersion:1,kind:'root-typescript7-installed-profile',sourceRef,
    workflowRunId:Number(process.env.GITHUB_RUN_ID),workflowRunAttempt:Number(process.env.GITHUB_RUN_ATTEMPT),
    node:process.version,platform:process.platform,architecture:process.arch,
    typescript:version,reportedVersion:reported.stdout.trim(),launcherSha256:sha256(readFileSync(cli)),
    lockGenerated,packageLockSha256:sha256(readFileSync(lockPath)),
    manifests:manifestPaths.map((file)=>({path:file,sha256:sha256(readFileSync(path.join(root,file)))})),
    optionalDependencies,retiredCompilerRuntimeUsed:false,
  };
  writeFileSync(path.join(output,'installed-profile.json'),JSON.stringify(profile,null,2)+'\n');
  exactFile(path.join(output,'installed-typescript-package.json'));
  exactFile(path.join(output,'installed-profile.json'));

  // Existing root gates, once in their dependency order. No PSC0 rebuild, Lean
  // oracle/corpus replay, kernel implementation edit, or seed promotion occurs.
  run('root-build',['run','build']);
  run('package-tests',['run','test:packages']);
  run('conformance-build',['run','build','--workspace','@proofscript/conformance']);
  run('lean4export-build',['run','build','--workspace','@proofscript/lean4export']);
  run('package-integration',['run','test:package-integration']);
  run('package-boundaries',['run','check:packages']);
  assert.equal(git(['rev-parse','HEAD']),sourceRef);
  const changed=git(['diff','--name-only']).split('\n').filter(Boolean);
  assert.ok(changed.every((file)=>file==='package-lock.json'),'qualification modified tracked source');
} catch(error) {
  failure=error;
} finally {
  const receipt={
    schemaVersion:1,kind:'root-typescript7-qualification',sourceRef,
    workflowRunId:Number(process.env.GITHUB_RUN_ID),workflowRunAttempt:Number(process.env.GITHUB_RUN_ATTEMPT),
    startedAt,completedAt:new Date().toISOString(),passed:failure===undefined,
    node:process.version,typescript:version,lockGenerated,
    packageLockSha256:existsSync(path.join(output,'package-lock.json'))?
      sha256(readFileSync(path.join(output,'package-lock.json'))):null,
    installedProfileSha256:existsSync(path.join(output,'installed-profile.json'))?
      sha256(readFileSync(path.join(output,'installed-profile.json'))):null,
    commands,retiredCompilerRuntimeUsed:false,psc0Qualification:false,
    kernelOracleOrCorpusExecuted:false,seedSelectionChanged:false,
    ...(failure?{failure:String(failure)}:{}),
  };
  const receiptFile=path.join(output,'qualification.json');
  writeFileSync(receiptFile,JSON.stringify(receipt,null,2)+'\n');
  exactFile(receiptFile);
  const indexFile=path.join(output,'evidence-index.json');
  writeFileSync(indexFile,JSON.stringify({schemaVersion:1,sourceRef,files},null,2)+'\n');
  exactFile(indexFile);
}
if(failure)throw failure;
