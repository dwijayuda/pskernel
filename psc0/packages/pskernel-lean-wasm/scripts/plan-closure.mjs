// Build-time only. Resolve the *live*, version-controlled PSC0 Lean source
// import DAG; never rely on copied PSC2 provider source or a fixed module list.
import {existsSync} from 'node:fs';
import {readFile,mkdir,copyFile,writeFile,readdir} from 'node:fs/promises';
import path from 'node:path';
const [psc0,output,manifest]=process.argv.slice(2);
if(!psc0||!output||!manifest) throw new Error('usage: node plan-closure.mjs <psc0> <overlay-src> <manifest>');
// Discover the *direct*, live PSC0 package roots rather than assuming that
// the current compiler's transitive imports fit a handwritten subset.
// Exclude symlinks/archives; never search legacy snapshots or synthesize a
// missing module. Ambiguous names remain a hard build failure.
const packageEntries=await readdir(path.join(psc0,'packages'),{withFileTypes:true});
const roots=packageEntries
  .filter(entry=>entry.isDirectory() &&
    existsSync(path.join(psc0,'packages',entry.name,'src')))
  .map(entry=>'packages/'+entry.name+'/src')
  .sort();
roots.push('packages/pskernel-lean/provider');
// A package might have both src and provider; only the explicit official
// Lean adapter path is authoritative for PsKernelLean.*.

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
await writeFile(manifest,JSON.stringify({schemaVersion:1,source:'live-psc0',sourceRoots:roots,modules:ordered},null,2)+'\n');
console.log('PSC0_WASM_SOURCE_CLOSURE: '+ordered.length+' live Lean modules');
