import {existsSync,readFileSync,readdirSync,statSync} from 'node:fs';
import {join} from 'node:path';
import {fileURLToPath} from 'node:url';

const root=fileURLToPath(new URL('..',import.meta.url));
const mapPath=join(root,'packages','package-map.json');
const map=JSON.parse(readFileSync(mapPath,'utf8'));
if(!Array.isArray(map.packages))throw new Error('package-map: packages must be an array');

const byName=new Map();
for(const pkg of map.packages){
  if(typeof pkg.name!=='string'||pkg.name.length===0)throw new Error('package-map: every package needs a name');
  if(byName.has(pkg.name))throw new Error('package-map: duplicate package '+pkg.name);
  if(!Array.isArray(pkg.dependsOn))throw new Error('package-map: dependsOn must be an array for '+pkg.name);
  byName.set(pkg.name,pkg);
}

for(const pkg of map.packages){
  for(const dep of pkg.dependsOn){
    if(!byName.has(dep))throw new Error(`package-map: ${pkg.name} depends on unknown package ${dep}`);
    if(dep===pkg.name)throw new Error(`package-map: ${pkg.name} depends on itself`);
  }
}
const kernel=byName.get('kernel');
if(kernel===undefined)throw new Error('package-map: kernel entry missing');
if(kernel.dependsOn.length!==0)throw new Error('package-map: trusted kernel must not depend on outer packages');

const visiting=new Set(),done=new Set();
function visit(name,stack=[]){
  if(done.has(name))return;
  if(visiting.has(name))throw new Error('package-map: dependency cycle '+[...stack,name].join(' -> '));
  visiting.add(name);
  for(const dep of byName.get(name).dependsOn)visit(dep,[...stack,name]);
  visiting.delete(name);done.add(name);
}
for(const name of [...byName.keys()].sort())visit(name);

for(const pkg of map.packages){
  if(pkg.name==='kernel')continue;
  const dir=join(root,pkg.path);
  const manifestPath=join(dir,'package.json');
  if(!existsSync(manifestPath))throw new Error(`package-map: missing manifest for ${pkg.name}`);
  const manifest=JSON.parse(readFileSync(manifestPath,'utf8'));
  if(manifest.name!==pkg.packageName)throw new Error(`package-map: manifest name drift for ${pkg.name}`);
  if(manifest.proofscript?.status!==pkg.status)throw new Error(`package-map: status drift for ${pkg.name}`);
  if(pkg.sourceLanguage==='typescript'&&manifest.proofscript?.sourceLanguage!=='typescript'){
    throw new Error(`package-map: TypeScript source policy missing in manifest for ${pkg.name}`);
  }
}

function walk(path){
  for(const entry of readdirSync(path)){
    const full=join(path,entry);
    const stat=statSync(full);
    if(stat.isDirectory()){
      if(entry==='dist'||entry==='node_modules')continue;
      walk(full);
    }else if(full.endsWith('.mjs')){
      throw new Error('package-map: hand-authored .mjs package source '+full);
    }
  }
}
walk(join(root,'packages'));

console.log(`package-map: PASS (${map.packages.length} packages; dependency graph acyclic)`);
