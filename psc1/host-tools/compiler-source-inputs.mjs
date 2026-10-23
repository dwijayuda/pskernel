// Host-owned exact closure capture; generated compiler consumes the captured text.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
export function readOwnedCompilerSources(entry) {
const lake=fs.readFileSync('lakefile.lean','utf8'),index=new Map();
for(const match of lake.matchAll(/lean_lib\s+(\w+)\s+where\n([\s\S]*?)(?=\n(?:lean_|@)|$)/g)){
 const dir=match[2].match(/srcDir\s*:=\s*"([^"]+)"/)?.[1];if(!dir)continue;
 for(const m of match[2].matchAll(/`([\w.]+)/g)){
  const name=m[1],file=path.join(dir,...name.split('.'))+'.lean';
  index.set(name,{module:name,path:file,text:fs.readFileSync(file,'utf8')});
 }
}
const ordered=[],seen=new Set(),active=new Set();
function visit(name){
 if(seen.has(name))return;assert.ok(!active.has(name),'source cycle');active.add(name);
 const row=index.get(name);assert.ok(row&&row.path.startsWith('packages/')&&!/pskernel-lean|\/cli\//.test(row.path),'owned portable source '+name);
 for(const m of row.text.matchAll(/^import\s+(.+)$/gm))for(const dep of m[1].trim().split(/\s+/))visit(dep);
 active.delete(name);seen.add(name);ordered.push(row);
}
visit(entry);

return ordered;
}
