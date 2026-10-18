import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { cp, mkdir, readFile, writeFile, readdir, rm, stat } from 'node:fs/promises';
import { existsSync, readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { dirname, join, relative, resolve, basename } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { stageNpmHost, normalizeFacadeEntry } from './npm-host-packaging.mjs';
const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const dist = join(root,'dist/npm-distribution');
const build = join(root,'dist/npm-build');
const V='0.1.0-psc0.1';
const coreNames=['foundation','syntax','core','environment','meta','elab','bridge','compiler-ir','erasure','compiler','backend-ts','bootstrap','pskernel-core'];
// The Wasm-GC checker is explicitly unqualified/private: never stage or publish it.
const optionalNames=['backend-js','backend-rust','backend-wasm','cli','pskernel-lean','stdlib'];
const names=[...coreNames,...optionalNames];
const providerNames=new Set(['pskernel-lean']);
const directNames=new Set(['compiler','pskernel-core']);
const sourceOnlyNames=new Set(['stdlib']);
const hash=b=>createHash('sha256').update(b).digest('hex');
const outname=d=>'@proofscript/'+d;
const run=(command,args,cwd=root,{timeout=600000,quiet=false}={})=>{
  console.log('PSC_NPM_RUN '+command+' '+args.join(' '));
  const x=spawnSync(command,args,{cwd,encoding:'utf8',stdio:quiet?'pipe':'inherit',timeout,maxBuffer:16*1024*1024,windowsHide:true});
  if(x.error||x.status!==0)throw Error('PSC_NPM_RUN_FAILED '+command+' '+(x.error?.message||x.stderr||x.stdout||x.status));
  return x.stdout||'';
};
async function walk(p) {
  const entries=await readdir(p,{withFileTypes:true}); let files=[];
  for(const e of entries) {
    const f=join(p,e.name);
    if(e.isSymbolicLink())throw Error('PSC_NPM_SYMLINK_NOT_ALLOWED '+f);
    if(e.isDirectory())files.push(...await walk(f));
    else if(e.isFile())files.push(f);
  }
  return files.sort();
}
const safeRead=async p=>JSON.parse(await readFile(p,'utf8'));
async function packedRegistryToolchain(tarballs) {
  const packs=[];
  for(const name of ['typescript@7.0.2','@typescript/typescript-linux-x64@7.0.2','@typescript/typescript-win32-x64@7.0.2']) {
    const response=JSON.parse(run('npm',['pack',name,'--pack-destination',tarballs,'--ignore-scripts','--json'],root,{quiet:true}));
    if(!Array.isArray(response)||response.length!==1)throw Error('PSC_NPM_TOOLCHAIN_TARBALL: '+name);
    packs.push(join(tarballs,response[0].filename));
  }
  return packs;
}
const exceptTag=o=>o&&typeof o==='object'?Object.getOwnPropertySymbols(o).map(s=>o[s]).find(v=>typeof v==='string'):undefined;
const unwrap=(x,what)=>{
  if(exceptTag(x)==='ok')return x.value;
  const detail=JSON.stringify(x?.error,(_key,v)=>typeof v==='bigint'?v.toString():v);
  throw Error('PSC_NPM_TRANSLATION_FAILED '+what+' '+String(detail).slice(0,1000));
};
function verifyDistExists(){
  for(const d of ['compiler','pskernel-core'])for(const ext of ['js','ts','d.ts','js.map'])if(!existsSync(join(build,d,'index.'+ext)))throw Error('PSC_NPM_COMPILATION_MISSING '+d+'/'+ext);
  if(!existsSync(join(build,'pskernel-core','prelude.json')))throw Error('PSC_NPM_PRELUDE_MISSING');
}
async function writeCoreRuntime(stage,providerSrc) {
  const output=join(stage,'dist');
  for(const name of ['index.js','index.ts','index.d.ts','index.js.map'])await cp(join(build,'pskernel-core',name),join(output,name));
  await cp(join(build,'pskernel-core','prelude.json'),join(output,'prelude.json'));
  for(const [from,to] of [['npm-runtime/generated-core-provider.mjs','generated-core-provider.mjs'],['npm-runtime/core-cli.mjs','core-cli.mjs'],['npm-runtime/core-checker.mjs','core-checker.mjs']])await cp(join(root,from),join(output,to));
  const expected={schemaVersion:1,package:'@proofscript/pskernel-core',baseMainCommit:'748ee630e43ee1a89643cbc8cec3e31087788b08',kernelSha256:hash(await readFile(join(output,'index.js'))),preludeSha256:hash(await readFile(join(output,'prelude.json'))),adapterSha256:hash(await readFile(join(output,'generated-core-provider.mjs'))),processSha256:hash(await readFile(join(output,'core-cli.mjs'))),checkedAlgorithm:'psKernelV1AdmitDeclaration',defaultProvider:'psc0-generated-js-core',leanWasmFallback:false};
  await writeFile(join(output,'kernel-manifest.json'),JSON.stringify(expected,null,2)+'\n');
  providerSrc.proofscript={...providerSrc.proofscript,kernelQualification:'psc0-js-core-cloud-gated/1',kernelSourceCommit:expected.baseMainCommit,generatedJsSha256:expected.kernelSha256};
  providerSrc.exports={'.':'./dist/index.js','./check':'./dist/core-checker.mjs','./package.json':'./package.json'};
  providerSrc.files=['dist/','src/','README.md'];
}
async function producePackage(variant,name,compiler) {
  const source=name==='stdlib'?join(root,'stdlib'):join(root,'packages',name);
  const stage=join(dist,variant,'staging','scoped',name);
  const metadata=await safeRead(join(root,'packages',name,'package.json'));
  await mkdir(stage,{recursive:true});
  const external=providerNames.has(name);
  if(external) {
    for(const e of await readdir(source,{withFileTypes:true})) {
      if(e.name==='package.json'||e.name==='node_modules'||e.name==='dist')continue;
      await cp(join(source,e.name),join(stage,e.name),{recursive:true});
    }
    metadata.version='4.34.0'; delete metadata.types;
    metadata.files=['index.mjs','host/','wasm/','provider/','kernel/','source/','scripts/','patches/','LEAN_LICENSE','*.json','README.md','BUILDING.md'];
    metadata.proofscript={...metadata.proofscript,sourceVariant:'native-provider'};
  } else {
    const conversion={schemaVersion:1,package:outname(name),requestedVariant:variant,translated:0,preservedLean:0,preservedNonLean:0,exceptions:[]};
    const from=name==='stdlib'?source:join(source,'src'),to=join(stage,'src');
    if(!existsSync(from))throw Error('PSC_NPM_PACKAGE_SOURCE_MISSING '+name);
    if(variant==='lean'){
      if(name==='stdlib')await cp(join(from,'ProofScript'),join(to,'ProofScript'),{recursive:true});
      else await cp(from,to,{recursive:true});
    } else {
      const files=name==='stdlib'?await walk(join(from,'ProofScript')):await walk(from);
      for(const file of files) {
        const rel=relative(from,file);
        if(!file.endsWith('.lean')) {
          await mkdir(dirname(join(to,rel)),{recursive:true}); await cp(file,join(to,rel)); conversion.preservedNonLean++; continue;
        }
        const text=await readFile(file,'utf8'); let transformed,reason;
        try {
          transformed=unwrap(compiler.psCompilerTranslateSource(compiler.PsCompilerSourceKind.lean,compiler.PsCompilerSourceKind.proofScript,text),name+'/'+rel);
          assert.equal(typeof transformed,'string');
          if(exceptTag(compiler.psParseProofScriptSource(transformed))!=='ok')throw Error('PSC_NPM_GENERATED_PS_INVALID: '+rel);
        } catch(error) { reason=String(error?.message||error).slice(0,900); }
        if(reason) {
          const fallback=join(to,rel); await mkdir(dirname(fallback),{recursive:true}); await cp(file,fallback);
          conversion.preservedLean++; conversion.exceptions.push({path:rel,reason});
          console.log('PSC_NPM_PS_CONVERSION_LIMIT: '+name+'/'+rel+' ('+reason.slice(0,180)+')');
        } else {
          const output=join(to,rel.replace(/\.lean$/u,'.ps')); await mkdir(dirname(output),{recursive:true}); await writeFile(output,transformed); conversion.translated++;
        }
      }
    }
    if(variant==='ps'){
      await writeFile(join(stage,'SOURCE_CONVERSION.json'),JSON.stringify(conversion,null,2)+'\n');
      console.log('PSC_NPM_SOURCE_COVERAGE '+name+' translated='+conversion.translated+' retainedLean='+conversion.preservedLean);
    }
    const lib=join(stage,'dist'); await mkdir(lib,{recursive:true});
    if(directNames.has(name)){
      if(name==='pskernel-core')await writeCoreRuntime(stage,metadata);
      else for(const ext of ['js','ts','d.ts','js.map'])await cp(join(build,'compiler','index.'+ext),join(lib,'index.'+ext));
    } else if(sourceOnlyNames.has(name)) {
      await writeFile(join(lib,'index.mjs'),"export const proofscriptLibrary = "+JSON.stringify({name:outname(name),version:V,modulePrefix:'ProofScript',sourceVariant:variant,sourceOnly:true})+";\n");
    } else {
      await writeFile(join(lib,'index.mjs'),"export * from '@proofscript/compiler';\n"+"export const proofscriptPackage = "+JSON.stringify({name:outname(name),version:V,sourceVariant:variant,runtimeModel:'psc0-shared-selfhost-compiler/1'})+";\n");
    }
  }
  normalizeFacadeEntry(metadata,name);
  metadata.version=external?'4.34.0':V; metadata.private=false;
  if(!external)metadata.files=['dist/','src/','README.md','SOURCE_CONVERSION.json'];
  metadata.proofscript={...metadata.proofscript,sourceVariant:external?'native-provider':variant,runtimeModel:directNames.has(name)?'compiled-psc0-js':sourceOnlyNames.has(name)?'source-only-library':'shared-psc0-js-facade',verifiedIndependentPackageCompilation:false};
  if(metadata.dependencies)for(const d of Object.keys(metadata.dependencies))metadata.dependencies[d]=providerNames.has(d.replace('@proofscript/',''))?'4.34.0':V;
  await writeFile(join(stage,'package.json'),JSON.stringify(metadata,null,2)+'\n');
  await writeFile(join(stage,'README.md'),['# '+metadata.name,'','PSC0 npm module from pinned main source. Source variant: '+variant+'.',coreNames.includes(name)?'Installation: required PSC0 compiler closure.':'Installation: optional package; not installed by default with proofscript.','Runtime: '+(directNames.has(name)?'compiled ProofScript JavaScript':sourceOnlyNames.has(name)?'source-only npm library':'shared PSC0 JS module facade')+'.',external?'External Lean provider retains its actual native assets.':'src/ contains source files; SOURCE_CONVERSION.json records any retained Lean originals.','The JS Core checker is gated by release qualification and never falls back to Lean-WASM.','A scoped package facade is not an independent compiler/backend implementation.',''].join('\n'));
  const files=await walk(stage);
  if(!files.some(f=>basename(f)==='package.json'))throw Error('PSC_NPM_PACKAGE_EMPTY '+name);
  return stage;
}
async function bundleVariant(variant,compiler) {
  const target=join(dist,variant),tarballs=join(target,'tarballs'); await mkdir(tarballs,{recursive:true});
  const packages=[],conversions=[];
  for(const name of names) {
    const staged=await producePackage(variant,name,compiler);
    if(variant==='ps'&&!providerNames.has(name))conversions.push(await safeRead(join(staged,'SOURCE_CONVERSION.json')));
    const desc=JSON.parse(run('npm',['pack',staged,'--pack-destination',tarballs,'--json','--ignore-scripts'],root,{quiet:true}));
    if(!Array.isArray(desc)||desc.length!==1)throw Error('PSC_NPM_PACK_OUTPUT '+name);
    packages.push(join(tarballs,desc[0].filename)); console.log('PSC_NPM_PACKED '+name+' => '+desc[0].filename);
  }
  const umbrella=join(target,'staging','root'); await stageNpmHost(root,umbrella);
  const meta=await safeRead(join(root,'packages','proofscript','package.json'));
  meta.proofscript={...meta.proofscript,sourceVariant:variant,architectureHost:'checked-host/1',checkerProvider:'@proofscript/pskernel-core/check',defaultCheckerExecution:'generated-js-core',leanWasmRole:'optional-comparison'};
  meta.dependencies=Object.fromEntries([...coreNames.map(d=>[outname(d),V]),['typescript','7.0.2']]); meta.bundledDependencies=coreNames.map(outname);
  await writeFile(join(umbrella,'package.json'),JSON.stringify(meta,null,2)+'\n');
  await writeFile(join(umbrella,'README.md'),'# proofscript\n\nPSC0 npm compiler, '+variant+' source edition. Bounded checking, not full PSCV.\nThe entry .js/.ts file points to an immutable .psc-artifacts generation holding source, JS, declarations, maps and receipt.\nNo automatic kernel fallback.\n');
  const coreTarballs=packages.filter((_,i)=>coreNames.includes(names[i]));
  run('npm',['install','--ignore-scripts','--no-audit','--no-fund','--no-package-lock','--install-strategy=hoisted','--prefix',umbrella,...coreTarballs,'typescript@7.0.2'],root,{timeout:900000});
  await writeFile(join(umbrella,'package.json'),JSON.stringify(meta,null,2)+'\n');
  const manifest={schemaVersion:1,version:V,sourceVariant:variant,coreAuthority:'js-core-qualified-scope-only',scope:coreNames.length,corePackages:coreNames.map(outname),optionalPackages:optionalNames.map(outname),toolchainPackages:['typescript@7.0.2','@typescript/typescript-linux-x64@7.0.2','@typescript/typescript-win32-x64@7.0.2'],explicitlyNotBundled:['typescript',...optionalNames.map(outname)],sourceCommit:process.env.GITHUB_SHA||'unknown',packageNames:names.map(outname),testedThirdPartyNpmLibrary:true,sourceConversion:{translated:conversions.reduce((s,x)=>s+x.translated,0),preservedLean:conversions.reduce((s,x)=>s+x.preservedLean,0),exceptions:conversions.flatMap(x=>x.exceptions.map(e=>({package:x.package,...e})))}};
  await writeFile(join(umbrella,'MANIFEST.json'),JSON.stringify(manifest,null,2)+'\n');
  const actual=JSON.parse(run('npm',['pack',umbrella,'--pack-destination',tarballs,'--json','--ignore-scripts'],root,{quiet:true}))[0]?.filename;
  if(!actual)throw Error('PSC_NPM_UMBRELLA_PACK_NO_FILENAME');
  const rootTgz=join(tarballs,actual),toolchains=await packedRegistryToolchain(tarballs),prefix=join(target,'installed'),cache=join(target,'isolated-npm-cache');
  run('npm',['install','--global','--prefix',prefix,'--cache',cache,'--offline','--ignore-scripts','--no-audit','--no-fund','--no-package-lock',rootTgz,toolchains[0],toolchains[1]],root,{timeout:600000});
  const cli=join(prefix,'lib','node_modules','proofscript','bin','psc.js');
  if(!existsSync(cli))throw Error('PSC_NPM_GLOBAL_BIN_MISSING');
  run(process.execPath,[cli,'version','--json'],root,{timeout:120000});
  const installedCore=join(prefix,'lib','node_modules','proofscript','node_modules','@proofscript');
  for(const name of coreNames)if(!existsSync(join(installedCore,name)))throw Error('PSC_NPM_CORE_MODULE_MISSING: '+name);
  for(const name of optionalNames)if(existsSync(join(installedCore,name))||existsSync(join(prefix,'lib','node_modules','@proofscript',name)))throw Error('PSC_NPM_OPTIONAL_MODULE_BUNDLED: '+name);
  console.log('PSC_NPM_MINIMAL_GLOBAL_INSTALL: PASS '+coreNames.length+' required, '+optionalNames.length+' absent');
  const example=join(target,'canary-project'); await mkdir(example,{recursive:true});
  const ext=variant==='ps'?'.ps':'.lean';
  await writeFile(join(example,'Main'+ext),'def answer : Nat := 42\n');
  run(process.execPath,[cli,'check','Main'+ext,'--json'],example,{timeout:120000});
  run(process.execPath,[cli,'build','Main'+ext,'--out','Main.js','--json'],example,{timeout:240000});
  const program=await import(pathToFileURL(join(example,'Main.js')).href),answer=program.answer;
  if(answer!==42n&&!(typeof answer==='function'&&answer()===42n))throw Error('PSC_NPM_OUTPUT_WRONG_ANSWER');
  await writeFile(join(example,'IllTyped'+ext),'def answer : Nat := Type\n');
  const negative=spawnSync(process.execPath,[cli,'build','IllTyped'+ext,'--out','Bad.js'],{cwd:example,encoding:'utf8',timeout:120000});
  if(negative.status===0||existsSync(join(example,'Bad.js')))throw Error('PSC_NPM_FAILED_OPEN_ON_BAD_SOURCE');
  run(process.execPath,['scripts/npm-library-canary.mjs',variant,join(target,'thirdparty-canary'),cli],root,{timeout:480000});
  const files=await Promise.all([rootTgz,...packages,...toolchains].map(async f=>({name:basename(f),sha256:hash(await readFile(f)),bytes:(await stat(f)).size})));
  const index={...manifest,packages:files,installedCanary:{checked:true,built:true,output42n:true,negativeRefusal:true,thirdPartyLibrary:true,optionalPackagesAbsent:true,typescriptPlatformPresent:true},sourceType:variant};
  await writeFile(join(target,'manifest.json'),JSON.stringify(index,null,2)+'\n');
  const zipName='proofscript-psc0-'+variant+'-npm-packages.zip',installGuide=join(target,'INSTALL.md');
  await writeFile(installGuide,['# ProofScript PSC0 npm '+variant+' edition','','Only the core compiler closure and JS checker are bundled. Other scoped tarballs are optional.','Outputs use one executable entry point and immutable .psc-artifacts generations. Copy that directory with the entry point.','','Windows x64 offline (PowerShell):','npm install -g --offline --ignore-scripts .\\proofscript-'+V+'.tgz .\\typescript-7.0.2.tgz .\\typescript-typescript-win32-x64-7.0.2.tgz','','Linux x64 offline:','npm install -g --offline --ignore-scripts ./proofscript-'+V+'.tgz ./typescript-7.0.2.tgz ./typescript-typescript-linux-x64-7.0.2.tgz','','Registry-backed: npm install -g ./proofscript-'+V+'.tgz','After explicit publication: npm install -g proofscript','TypeScript 7.0.2 is not bundled, allowing npm to select its correct native platform dependency.','Optional backends and stdlib are separate npm installations.',''].join('\n'));
  const archivePath=join(dist,zipName);
  run('zip',['-q','-j',archivePath,...packages,rootTgz,...toolchains,join(target,'manifest.json'),installGuide],root,{timeout:120000});
  console.log('PSC_NPM_VARIANT_PASS '+variant+' '+zipName);
  return {archivePath,manifest:index};
}
async function main() {
  verifyDistExists();
  const compiler=await import(pathToFileURL(join(build,'compiler','index.js')).href);
  await rm(dist,{recursive:true,force:true}); const result=[];
  for(const variant of ['ps','lean'])result.push(await bundleVariant(variant,compiler));
  await writeFile(join(dist,'npm-release-manifest.json'),JSON.stringify(result.map(({archivePath,manifest})=>({archive:basename(archivePath),variant:manifest.sourceVariant,commit:manifest.sourceCommit,packageCount:manifest.scope,sha256:hash(readFileSync(archivePath))})),null,2)+'\n');
}
await main();
