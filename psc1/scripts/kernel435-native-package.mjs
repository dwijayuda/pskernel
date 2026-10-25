// Assemble only independently executed CI artifacts; this script does not grant kernel acceptance.
import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import assert from 'node:assert/strict';import {spawnSync} from 'node:child_process';
const root=process.cwd(),out=path.resolve('dist/kernel435-native-package'),pkg=path.join(out,'package'),inputs=JSON.parse(fs.readFileSync('scripts/kernel435-native-package-inputs.json','utf8'));
const sha=b=>crypto.createHash('sha256').update(b).digest('hex'),run=(cmd,args,opts={})=>{const r=spawnSync(cmd,args,{cwd:root,encoding:'utf8',timeout:240000,maxBuffer:64*1024*1024,...opts});assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,(r.stdout||'')+(r.stderr||''));return r.stdout;};
assert.ok(out.startsWith(path.join(root,'dist')+path.sep));fs.rmSync(out,{recursive:true,force:true});fs.mkdirSync(pkg,{recursive:true});
const token=process.env.GH_TOKEN;assert.ok(token,'read-only Actions token required');
const api=async p=>{const r=await fetch('https://api.github.com/repos/dwijayuda/pskernel/'+p,{headers:{Authorization:'Bearer '+token,'X-GitHub-Api-Version':'2022-11-28'}});assert.equal(r.ok,true,'GitHub '+r.status+' '+p);return r;};
const base=path.resolve('packages/pskernel-lean');
for(const p of ['index.mjs','index.d.ts','host','LEAN_SOURCE_PIN.json'])fs.cpSync(path.join(base,p),path.join(pkg,p),{recursive:true});
const meta=JSON.parse(fs.readFileSync(path.join(base,'package.json'),'utf8'));assert.equal(meta.version,'4.35.0');assert.equal(meta.name,'@proofscript/pskernel-lean');delete meta.scripts?.prepublishOnly;assert.ok(!Object.keys(meta.scripts||{}).some(k=>['install','postinstall','preinstall'].includes(k)));
fs.writeFileSync(path.join(pkg,'package.json'),JSON.stringify(meta,null,2)+'\n');
const source=path.join(out,'overlay'),manifestFile=path.join(out,'source.json');
run(process.execPath,['scripts/kernel-provider-source.mjs','.',source,manifestFile]);
const sourceManifest=JSON.parse(fs.readFileSync(manifestFile,'utf8'));
assert.equal(sourceManifest.modules.length,25,'current canonical provider source closure changed');
for(const m of sourceManifest.modules){const dst=path.join(pkg,'source/proofscript',m.source);fs.mkdirSync(path.dirname(dst),{recursive:true});fs.copyFileSync(m.source,dst);}
fs.mkdirSync(path.join(pkg,'scripts'),{recursive:true});fs.copyFileSync('scripts/kernel-provider-source.mjs',path.join(pkg,'scripts/plan-source.mjs'));fs.copyFileSync(path.join(base,'scripts/build-native-slim.mjs'),path.join(pkg,'scripts/build-native-slim.mjs'));fs.copyFileSync(manifestFile,path.join(pkg,'SOURCE_MANIFEST.json'));
const official=path.resolve(process.env.PSC1_OFFICIAL_LEAN_SOURCE||'');assert.ok(process.env.PSC1_OFFICIAL_LEAN_SOURCE);assert.equal(run('git',['-C',official,'rev-parse','HEAD']).trim(),'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
assert.equal(run('git',['-C',official,'status','--porcelain','--','src/kernel','LICENSE']).trim(),'','audit snapshot must be clean official source');
fs.cpSync(path.join(official,'src/kernel'),path.join(pkg,'kernel'),{recursive:true});fs.copyFileSync(path.join(official,'LICENSE'),path.join(pkg,'LEAN_LICENSE'));
const manifest={schema:1,package:meta.name,packageVersion:'4.35.0',protocol:'pskernel-lean/1',provider:'lean4-cpp',leanVersion:'4.35.0',leanCommit:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',profile:'lean4.35-core',sourceCommit:process.env.GITHUB_SHA,sourceClosureDigest:sourceManifest.sourceClosureDigest,targets:{}};
for(const s of inputs.sources){
 assert.ok(['linux-x64','linux-arm64','darwin-x64','darwin-arm64','win32-x64'].includes(s.target));assert.ok(!Object.hasOwn(manifest.targets,s.target));
 const jobs=await(await api('actions/runs/'+s.run+'/jobs?per_page=100')).json(),job=jobs.jobs.find(j=>j.id===s.job);assert.equal(job?.conclusion,'success','input job must have completed successfully');
 const artifact=await(await api('actions/artifacts/'+s.artifact)).json();assert.equal(artifact.expired,false);assert.equal(artifact.workflow_run.id,s.run);assert.equal(artifact.workflow_run.head_sha,s.commit);assert.equal(artifact.digest,'sha256:'+s.zipSha256);
 const zip=Buffer.from(await(await api('actions/artifacts/'+s.artifact+'/zip')).arrayBuffer());assert.equal(sha(zip),s.zipSha256);
 const dir=path.join(out,'inputs',s.target);fs.mkdirSync(dir,{recursive:true});const z=path.join(dir,'input.zip');fs.writeFileSync(z,zip);
 run('python3',['-c',String.raw`import zipfile,sys,pathlib
root=pathlib.Path(sys.argv[2]).resolve()
with zipfile.ZipFile(sys.argv[1]) as z:
 for i in z.infolist():
  p=(root/i.filename).resolve()
  assert p.is_relative_to(root) and not ((i.external_attr>>16)&0o170000)==0o120000
 z.extractall(root)
`,z,dir]);
 const [platform,arch]=s.target.split('-'),binaryName='psc2_lean_kernel_provider'+(platform==='win32'?'.exe':''),binary=path.join(dir,'dist/kernel435',binaryName),receipt=JSON.parse(fs.readFileSync(path.join(dir,'dist/kernel435/native-size-'+arch+'.json'),'utf8')),diff=JSON.parse(fs.readFileSync(path.join(dir,'dist/kernel435/native-'+arch+'.json'),'utf8')),src=JSON.parse(fs.readFileSync(path.join(dir,'packages/pskernel-lean/.native-slim-build/source.json'),'utf8'));
 assert.equal(src.sourceClosureDigest,sourceManifest.sourceClosureDigest,'current provider differs from qualified artifact');assert.equal(receipt.sourceCommit,s.commit);assert.equal(receipt.platform,platform);assert.equal(receipt.arch,arch);assert.equal(receipt.standalone,true);assert.equal(receipt.under7000000Bytes,true);assert.equal(diff.status,'passed');assert.equal(diff.mode,'native');assert.equal(diff.testedCommit,s.commit);assert.equal(diff.observations.length,14);
 const b=fs.readFileSync(binary);assert.equal(b.length,receipt.bytes);assert.ok(b.length<7000000);assert.equal(sha(b),receipt.sha256);assert.equal(diff.candidateSha256,receipt.sha256);
 const rel='prebuilt/'+s.target+'/'+binaryName,dst=path.join(pkg,rel);fs.mkdirSync(path.dirname(dst),{recursive:true});fs.writeFileSync(dst,b,{mode:0o755});
 manifest.targets[s.target]={path:rel,sha256:receipt.sha256,size:b.length,sourceCommit:s.commit,qualification:{run:s.run,job:s.job,artifact:s.artifact,zipSha256:s.zipSha256,standalone:true,parityCases:14}};
}
assert.ok(Object.keys(manifest.targets).length>0);
fs.writeFileSync(path.join(pkg,'PREBUILT_MANIFEST.json'),JSON.stringify(manifest,null,2)+'\n');
fs.writeFileSync(path.join(pkg,'README.md'),'# @proofscript/pskernel-lean 4.35.0\n\nIndependent official Lean C++ kernel for PSC1 canonical admission protocol version 2. Node 22.23.3 or newer. No install-time downloads or compilation. The included manifest lists exactly the qualified targets; missing targets fail explicitly. Use createKernel() and await kernel.checkCanonicalAdmissions(canonicalJson). A rejected proof returns accepted:false; process, identity, integrity and resource failures throw. This checker does not elaborate source or establish compiler semantic preservation.\n\nThe source snapshot and SOURCE_MANIFEST.json contain the exact 25-module provider closure. The kernel/ audit snapshot is official Lean commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Rebuild explicitly with npm run build:kernel using that SDK; no rebuild is performed during installation. Native initialization is limited to util/kernel modules, generated provider module initialization remains intact. Only the unused Lake library is removed from official linker flags. Finite kernel checks are preserved.\n');
const pack=JSON.parse(run('npm',['pack',pkg,'--json','--ignore-scripts','--pack-destination',out]));assert.equal(pack.length,1);const tar=path.join(out,pack[0].filename),bytes=fs.readFileSync(tar);
const report={schema:'psc1-kernel435-native-package/1',sourceCommit:process.env.GITHUB_SHA,status:'assembled-qualified-binaries-not-yet-installed',package:meta.name,version:meta.version,tarball:pack[0].filename,bytes:bytes.length,sha256:sha(bytes),sourceClosureDigest:sourceManifest.sourceClosureDigest,targets:manifest.targets};
fs.writeFileSync(path.join(out,'package-receipt.json'),JSON.stringify(report,null,2)+'\n');console.log('PSC1_KERNEL435_NATIVE_PACKAGE: '+JSON.stringify(report));
