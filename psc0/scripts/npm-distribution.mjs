import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { cp, mkdir, mkdtemp, readFile, writeFile, readdir, rm, stat } from 'node:fs/promises';
import { existsSync, readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { dirname, extname, join, relative, resolve, basename } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const dist = join(root,'dist/npm-distribution');
const build = join(root,'dist/npm-build');
const V='0.1.0-psc0.0';
const names=[
  'backend-js','backend-rust','backend-ts','backend-wasm','bootstrap','bridge',
  'cli','compiler-ir','compiler','core','elab','environment','erasure',
  'foundation','meta','pskernel-core','pskernel-lean-wasm','pskernel-lean','syntax'
];
const providerNames=new Set(['pskernel-lean-wasm','pskernel-lean']);
const directNames=new Set(['compiler','pskernel-core']);
const hash=b=>createHash('sha256').update(b).digest('hex');
const portable=d=>!providerNames.has(d);
const outname=d=>'@proofscript/'+d;
const run=(command,args,cwd=root,{timeout=600000,quiet=false}={})=>{
  console.log('PSC_NPM_RUN '+command+' '+args.join(' '));
  const x=spawnSync(command,args,{cwd,encoding:'utf8',stdio:quiet?'pipe':'inherit',timeout,
    maxBuffer:16*1024*1024,windowsHide:true});
  if(x.error||x.status!==0)throw Error('PSC_NPM_RUN_FAILED '+command+' '+(x.error?.message||x.stderr||x.stdout||x.status));
  return x.stdout||'';
};
async function walk(p) {
  const entries=await readdir(p,{withFileTypes:true});
  let files=[];
  for(const e of entries) {
    const f=join(p,e.name);
    if(e.isSymbolicLink()) throw Error('PSC_NPM_SYMLINK_NOT_ALLOWED '+f);
    if(e.isDirectory())files.push(...await walk(f));
    else if(e.isFile())files.push(f);
  }
  return files.sort();
}
const safeRead=async p=>JSON.parse(await readFile(p,'utf8'));
const exceptTag=o=>o&&typeof o==='object'?Object.getOwnPropertySymbols(o).map(s=>o[s]).find(v=>typeof v==='string'):undefined;
const unwrap=(x,what)=>{
  if(exceptTag(x)==='ok')return x.value;
  const detail=JSON.stringify(x?.error,(_key,v)=>typeof v==='bigint'?v.toString():v);
  throw Error('PSC_NPM_TRANSLATION_FAILED '+what+' '+String(detail).slice(0,1000));
};
function verifyDistExists(){
  for(const d of ['compiler','pskernel-core'])
    for(const ext of ['js','ts','d.ts','js.map']) {
      if(!existsSync(join(build,d,'index.'+ext)))throw Error('PSC_NPM_COMPILATION_MISSING '+d+'/'+ext);
    }
  if(!existsSync(join(build,'pskernel-core','prelude.json')))throw Error('PSC_NPM_PRELUDE_MISSING');
}
async function writeCoreRuntime(stage,providerSrc) {
  const output=join(stage,'dist');
  for(const name of ['index.js','index.ts','index.d.ts','index.js.map'])
    await cp(join(build,'pskernel-core',name),join(output,name));
  await cp(join(build,'pskernel-core','prelude.json'),join(output,'prelude.json'));
  for(const [from,to] of [
    ['npm-runtime/generated-core-provider.mjs','generated-core-provider.mjs'],
    ['npm-runtime/core-cli.mjs','core-cli.mjs'],
    ['npm-runtime/core-checker.mjs','core-checker.mjs']])await cp(join(root,from),join(output,to));
  const expected={
    schemaVersion:1,
    package:'@proofscript/pskernel-core',
    baseMainCommit:'748ee630e43ee1a89643cbc8cec3e31087788b08',
    kernelSha256:hash(await readFile(join(output,'index.js'))),
    preludeSha256:hash(await readFile(join(output,'prelude.json'))),
    adapterSha256:hash(await readFile(join(output,'generated-core-provider.mjs'))),
    processSha256:hash(await readFile(join(output,'core-cli.mjs'))),
    checkedAlgorithm:'psKernelV1AdmitDeclaration',
    defaultProvider:'psc0-generated-js-core',
    leanWasmFallback:false,
  };
  await writeFile(join(output,'kernel-manifest.json'),JSON.stringify(expected,null,2)+'\n');
  providerSrc.proofscript={...providerSrc.proofscript,
    kernelQualification:'psc0-js-core-cloud-gated/1',
    kernelSourceCommit:expected.baseMainCommit,generatedJsSha256:expected.kernelSha256};
  providerSrc.exports={'.':'./dist/index.js','./check':'./dist/core-checker.mjs','./package.json':'./package.json'};
  providerSrc.files=['dist/','src/','README.md'];
}
async function producePackage(variant,name,compiler) {
  const source=join(root,'packages',name);
  const stage=join(dist,variant,'staging','scoped',name);
  const metadata=await safeRead(join(source,'package.json'));
  await mkdir(stage,{recursive:true});
  const external=providerNames.has(name);
  if(external) {
    // Official Lean implementation remains a separate optional provider, not rewritten as .ps.
    for(const e of await readdir(source,{withFileTypes:true})) {
      if(e.name==='package.json'||e.name==='node_modules'||e.name==='dist')continue;
      const rel=join(source,e.name);
      await cp(rel,join(stage,e.name),{recursive:true});
    }
    metadata.version='4.34.0';
    delete metadata.types;
    metadata.files=['index.mjs','host/','wasm/','provider/','kernel/','source/',
      'scripts/','patches/','LEAN_LICENSE','*.json','README.md','BUILDING.md'];
    // All future npm releases must preserve the existing WASM identity.
    metadata.proofscript={...metadata.proofscript,sourceVariant:'native-provider'};
  } else {
    const from=join(source,'src'),to=join(stage,'src');
    if(!existsSync(from))throw Error('PSC_NPM_PACKAGE_SOURCE_MISSING '+name);
    if(variant==='lean')await cp(from,to,{recursive:true});
    else {
      const files=await walk(from);
      for(const file of files) {
        const rel=relative(from,file);
        if(!file.endsWith('.lean')) {
          await mkdir(dirname(join(to,rel)),{recursive:true});
          await cp(file,join(to,rel)); continue;
        }
        const text=await readFile(file,'utf8');
        const transformed=unwrap(compiler.psCompilerTranslateSource(
          compiler.PsCompilerSourceKind.lean,
          compiler.PsCompilerSourceKind.proofScript,text),name+'/'+rel);
        const candidate=rel.replace(/\.lean$/u,'.ps');
        assert.equal(typeof transformed,'string');
        const parsed=compiler.psParseProofScriptSource(transformed);
        if(exceptTag(parsed)!=='ok')throw Error('PSC_NPM_GENERATED_PS_INVALID '+name+'/'+candidate);
        const output=join(to,candidate);
        await mkdir(dirname(output),{recursive:true});
        await writeFile(output,transformed);
      }
    }
    const lib=join(stage,'dist');
    await mkdir(lib,{recursive:true});
    if(directNames.has(name)){
      if(name==='pskernel-core')await writeCoreRuntime(stage,metadata);
      else for(const ext of ['js','ts','d.ts','js.map'])
        await cp(join(build,'compiler','index.'+ext),join(lib,'index.'+ext));
    } else {
      await writeFile(join(lib,'index.mjs'),
        "export * from '@proofscript/compiler';\n"+
        "export const proofscriptPackage = "+JSON.stringify({name:outname(name),version:V,sourceVariant:variant,
          runtimeModel:'psc0-shared-selfhost-compiler/1'})+";\n");
    }
  }
  metadata.version=external?'4.34.0':V;
  metadata.private=false;
  metadata.proofscript={...metadata.proofscript,sourceVariant:external?'native-provider':variant,
    runtimeModel:directNames.has(name)?'compiled-psc0-js':'shared-psc0-js-facade',
    verifiedIndependentPackageCompilation:false};
  if(metadata.dependencies)for(const d of Object.keys(metadata.dependencies))
    metadata.dependencies[d]=providerNames.has(d.replace('@proofscript/',''))?'4.34.0':V;
  await writeFile(join(stage,'package.json'),JSON.stringify(metadata,null,2)+'\n');
  await writeFile(join(stage,'README.md'),[
    '# '+metadata.name,'',
    'PSC0 npm module from pinned main source. Source variant: '+variant+'.',
    'Runtime: '+(directNames.has(name)?'compiled ProofScript JavaScript':'shared PSC0 JS module facade')+'.',
    external?'This external Lean provider retains its original Lean/C/JS assets; it has not been translated to ProofScript.':
      'src/ contains the complete source tree in '+(variant==='ps'?'.ps':'.lean')+' form.',
    'The JS Core checker is gated by release qualification and never falls back to Lean-WASM.',
    'A scoped package facade is not an independent compiler/backend implementation.',
    '',
  ].join('\n'));
  const files=await walk(stage);
  if(!files.some(f=>basename(f)==='package.json'))throw Error('PSC_NPM_PACKAGE_EMPTY '+name);
  return stage;
}
function createCanary(pkg,dir) {
  const args=['--ignore-scripts','--no-audit','--no-fund','--no-package-lock',
    '--install-strategy=hoisted','--prefix',dir];
  return args;
}
async function bundleVariant(variant,compiler) {
  const target=join(dist,variant);
  const tarballs=join(target,'tarballs');
  await mkdir(tarballs,{recursive:true});
  const packages=[];
  for(const name of names) {
    const staged=await producePackage(variant,name,compiler);
    const tarName=run('npm',['pack',staged,'--pack-destination',tarballs,'--json',
      '--ignore-scripts'],root,{quiet:true});
    const desc=JSON.parse(tarName);
    if(!Array.isArray(desc)||desc.length!==1)throw Error('PSC_NPM_PACK_OUTPUT '+name);
    packages.push(join(tarballs,desc[0].filename));
    console.log('PSC_NPM_PACKED '+name+' => '+desc[0].filename);
  }
  const umbrella=join(target,'staging','root');
  await mkdir(join(umbrella,'bin'),{recursive:true});
  await cp(join(root,'npm-cli','psc.js'),join(umbrella,'bin','psc.js'));
  const meta=await safeRead(join(root,'packages','proofscript','package.json'));
  meta.proofscript={...meta.proofscript,sourceVariant:variant,
    checkerProvider:'@proofscript/pskernel-core/check',
    defaultCheckerExecution:'generated-js-core',
    leanWasmRole:'optional-comparison'};
  for(const d of names)meta.dependencies[outname(d)]=providerNames.has(d)?'4.34.0':V;
  await writeFile(join(umbrella,'package.json'),JSON.stringify(meta,null,2)+'\n');
  await writeFile(join(umbrella,'README.md'),
    '# proofscript\n\nInstallable PSC0 compiler/npm bundle. Source variant: '+variant+
    '\nDefault proof checker: JS PSKernel Core, *without fallback*. See scoped package manifests.'+
    '\nSource and semantic profile are PSC0 bounded, not full PSCV.\n');
  // Install all 19 local workspace packages without npm publication, then restore registry manifests.
  run('npm',['install',...createCanary(meta,umbrella),...packages,'typescript@7.0.2'],root,{timeout:900000});
  await writeFile(join(umbrella,'package.json'),JSON.stringify(meta,null,2)+'\n');
  const manifest={schemaVersion:1,version:V,sourceVariant:variant,
    coreAuthority:'js-core-qualified-scope-only',scope:packages.length,
    sourceCommit:process.env.GITHUB_SHA||'unknown',
    packageNames:names.map(outname),
  };
  await writeFile(join(umbrella,'MANIFEST.json'),JSON.stringify(manifest,null,2)+'\n');
  const packageResult=JSON.parse(run('npm',['pack',umbrella,'--pack-destination',tarballs,
    '--json','--ignore-scripts'],root,{quiet:true}));
  const actual=packageResult[0]?.filename;
  if(!actual)throw Error('PSC_NPM_UMBRELLA_PACK_NO_FILENAME');
  const rootTgz=join(tarballs,actual);
  // Install exactly the final public tarball offline. Do not resolve unpublished packages.
  const prefix=join(target,'installed');
  run('npm',['install','--global','--prefix',prefix,'--offline','--ignore-scripts',
    '--no-audit','--no-fund','--no-package-lock',rootTgz],root,{timeout:600000});
  const cli=join(prefix,'lib','node_modules','proofscript','bin','psc.js');
  if(!existsSync(cli))throw Error('PSC_NPM_GLOBAL_BIN_MISSING');
  run(process.execPath,[cli,'version','--json'],root,{timeout:120000});
  const example=join(target,'canary-project');
  await mkdir(example,{recursive:true});
  const ext=variant==='ps'?'.ps':'.lean';
  await writeFile(join(example,'Main'+ext),'def answer : Nat := 42\n');
  run(process.execPath,[cli,'check','Main'+ext,'--json'],example,{timeout:120000});
  run(process.execPath,[cli,'build','Main'+ext,'--out','Main.js','--json'],example,{timeout:240000});
  const program=await import(pathToFileURL(join(example,'Main.js')).href);
  const answer=program.answer;
  if(answer!==42n && !(typeof answer==='function' && answer()===42n)) throw Error('PSC_NPM_OUTPUT_WRONG_ANSWER');
  await writeFile(join(example,'IllTyped'+ext),'def answer : Nat := Type\n');
  const negative=spawnSync(process.execPath,[cli,'build','IllTyped'+ext,'--out','Bad.js'],{
    cwd:example,encoding:'utf8',timeout:120000});
  if(negative.status===0||existsSync(join(example,'Bad.js'))) throw Error('PSC_NPM_FAILED_OPEN_ON_BAD_SOURCE');
  const files=await Promise.all([rootTgz,...packages].map(async f=>({
    name:basename(f),sha256:hash(await readFile(f)),bytes:(await stat(f)).size,
  })));
  const index={...manifest,packages:files,installedCanary:{checked:true,built:true,
      output42n:true,negativeRefusal:true},sourceType:variant};
  await writeFile(join(target,'manifest.json'),JSON.stringify(index,null,2)+'\n');
  const zipName='proofscript-psc0-'+variant+'-npm-packages.zip';
  // Artifact contains installable tarballs, manifest and complete source variants, but not build temp files.
  const archivePath=join(dist,zipName);
  run('zip',['-q','-j',archivePath,...packages,rootTgz,join(target,'manifest.json')],root,{timeout:120000});
  console.log('PSC_NPM_VARIANT_PASS '+variant+' '+zipName);
  return {archivePath,manifest:index};
}
async function main() {
  verifyDistExists();
  const compiler=await import(pathToFileURL(join(build,'compiler','index.js')).href);
  await rm(dist,{recursive:true,force:true});
  const result=[];
  for(const variant of ['ps','lean']) result.push(await bundleVariant(variant,compiler));
  await writeFile(join(dist,'npm-release-manifest.json'),
    JSON.stringify(result.map(({archivePath,manifest})=>({
      archive:basename(archivePath),variant:manifest.sourceVariant,
      commit:manifest.sourceCommit,packageCount:manifest.scope,
      sha256:hashFileSync(archivePath),
    })),null,2)+'\n');
}
function hashFileSync(p){return createHash('sha256').update(readFileSync(p)).digest('hex');}
await main();
