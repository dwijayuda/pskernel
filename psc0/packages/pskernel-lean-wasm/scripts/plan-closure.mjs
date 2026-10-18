// Build-time only. Resolve the *live*, version-controlled PSC0 Lean source
// import DAG; never rely on copied PSC2 provider source or a fixed module list.
import {existsSync} from 'node:fs';
import {readFile,mkdir,copyFile,writeFile} from 'node:fs/promises';
import path from 'node:path';
const [psc0,output,manifest]=process.argv.slice(2);
if(!psc0||!output||!manifest) throw new Error('usage: node plan-closure.mjs <psc0> <overlay-src> <manifest>');
const roots=[
  'packages/foundation/src','packages/core/src','packages/environment/src',
  'packages/bridge/src','packages/pskernel-lean/provider',
  'packages/pskernel-lean-wasm/src',
];
const completed=new Set(),active=new Set(),ordered=[];
async function visit(name) {
  if(completed.has(name)) return;
  if(active.has(name)) throw new Error('PSC0 circular import: '+name);
  if(!/^(Ps\.|PsKernelLean\.|PsKernelLeanWasm\.)[A-Za-z0-9_.]+$/.test(name))
    throw new Error('invalid PSC0 module: '+name);
  const relative=name.replaceAll('.','/')+'.lean';
  const matches=roots.map(r=>path.join(psc0,r,relative)).filter(existsSync);
  if(matches.length!==1) throw new Error('PSC0 missing/ambiguous module: '+name+' ('+matches.length+')');
  active.add(name);
  const source=await readFile(matches[0],'utf8');
  for(const line of source.split(/\r?\n/)) {
    const match=line.match(/^import\s+(.+?)(?:\s+--.*)?\s*$/);
    if(!match) continue;
    for(const dep of match[1].trim().split(/\s+/)) {
      if(/^(Ps\.|PsKernelLean\.|PsKernelLeanWasm\.)/.test(dep)) await visit(dep);
    }
  }
  await mkdir(path.dirname(path.join(output,relative)),{recursive:true});
  await copyFile(matches[0],path.join(output,relative));
  ordered.push({module:name,source:path.relative(psc0,matches[0])});
  active.delete(name);
  completed.add(name);
}
await visit('PsKernelLeanWasm.Main');
await mkdir(path.dirname(manifest),{recursive:true});
await writeFile(manifest,JSON.stringify({schemaVersion:1,source:'live-psc0',modules:ordered},null,2)+'\n');
console.log('PSC0_WASM_SOURCE_CLOSURE: '+ordered.length+' live Lean modules');
