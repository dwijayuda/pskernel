// Build/package source inventory only. Kernel acceptance always runs separately.
import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import assert from 'node:assert/strict';
const [workspaceArg,outputArg,manifestArg]=process.argv.slice(2);
assert.ok(workspaceArg&&outputArg&&manifestArg,'workspace, overlay and manifest required');
const workspace=path.resolve(workspaceArg),output=path.resolve(outputArg),manifest=path.resolve(manifestArg);
const roots=['packages/foundation/src','packages/core/src','packages/environment/src','packages/bridge/src','packages/pskernel-lean/provider'];
const seen=new Set(),active=new Set(),modules=[];
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
function visit(module){
 if(seen.has(module))return;
 assert.match(module,/^(Ps\.|PsKernelLean\.)[A-Za-z0-9_.]+$/);assert.ok(!active.has(module),'import cycle '+module);
 const relative=module.replaceAll('.','/')+'.lean';
 const matches=roots.map(root=>path.join(workspace,root,relative)).filter(fs.existsSync);assert.equal(matches.length,1,'missing/ambiguous '+module);
 const file=matches[0],st=fs.lstatSync(file);assert.ok(st.isFile()&&!st.isSymbolicLink());const bytes=fs.readFileSync(file),text=new TextDecoder('utf-8',{fatal:true}).decode(bytes);
 active.add(module);
 for(const line of text.split(/\r?\n/)){const m=line.match(/^import\s+(.+?)(?:\s+--.*)?\s*$/);if(m)for(const dep of m[1].trim().split(/\s+/))if(/^(Ps\.|PsKernelLean\.)/.test(dep))visit(dep);}
 const destination=path.join(output,relative);fs.mkdirSync(path.dirname(destination),{recursive:true});fs.writeFileSync(destination,bytes);
 modules.push({module,source:path.relative(workspace,file).replaceAll(path.sep,'/'),bytes:bytes.length,sha256:sha(bytes)});
 active.delete(module);seen.add(module);
}
visit('PsKernelLean.Main');assert.ok(modules.length>=6);
const report={schema:'psc1-kernel-provider-source/1',source:'current-psc1-semantic-provider',sourceCommit:process.env.GITHUB_SHA||'package-local-source',entryModule:'PsKernelLean.Main',modules,bytes:modules.reduce((s,r)=>s+r.bytes,0),sourceClosureDigest:sha(JSON.stringify(modules))};
fs.mkdirSync(path.dirname(manifest),{recursive:true});fs.writeFileSync(manifest,JSON.stringify(report,null,2)+'\n');
console.log('PSC1_KERNEL_PROVIDER_SOURCE: '+JSON.stringify(report));
