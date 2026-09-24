import fs from 'node:fs';
import path from 'node:path';

const repoRoot=process.cwd();
const sourceRoot=path.join(repoRoot,'study','lean4-4.34.0','src');

const roots=process.argv.slice(2);
const requestedRoots=roots.length===0
  ?['Lean.Parser','Lean.Meta.Basic','Lean.Elab.Frontend']
  :roots;

function modulePath(moduleName){
  return path.join(sourceRoot,...moduleName.split('.'))+'.lean';
}

function normalizeRel(file){
  return path.relative(repoRoot,file).replaceAll(path.sep,'/');
}

function parseImports(text){
  const out=[];
  for(const line of text.split(/\r?\n/u)){
    const m=line.match(/^\s*(?:public\s+)?(?:meta\s+)?import(?:\s+all)?\s+([A-Za-z0-9_'.]+)/u);
    if(m)out.push(m[1]);
  }
  return [...new Set(out)].sort();
}

function extractExternSymbols(text){
  const symbols=new Set();
  const re=/@\[\s*extern(?:\s+[A-Za-z_][A-Za-z0-9_.]*)?\s+"([^"]+)"/gu;
  for(const m of text.matchAll(re))symbols.add(m[1]);
  return [...symbols].sort();
}

function extractImplementedBy(text){
  const out=new Set();
  const re=/@\[\s*implemented_by\s+([A-Za-z0-9_'.]+)/gu;
  for(const m of text.matchAll(re))out.add(m[1]);
  return [...out].sort();
}

function count(text,re){
  re.lastIndex=0;
  let n=0;
  while(re.exec(text)!==null)n++;
  return n;
}

const patterns={
  extern:/@\[\s*extern\b/gu,
  implementedBy:/@\[\s*implemented_by\b/gu,
  unsafe:/\bunsafe\b/gu,
  partialDef:/\bpartial\s+def\b/gu,
  opaque:/\bopaque\b/gu,
  builtinInitialize:/\bbuiltin_initialize\b/gu,
  io:/\bIO\b/gu,
  task:/\bTask\b/gu,
  ref:/\bRef\b/gu,
};

const runtimeSource=fs.readFileSync(
  path.join(repoRoot,'packages','runtime','src','lean4.ts'),
  'utf8',
);
const implementedExterns=new Set(
  [...runtimeSource.matchAll(/leanSymbol:'([^']+)'/gu)].map((m)=>m[1]),
);

const visited=new Map();
const missing=new Set();
const stack=[...requestedRoots].reverse();

while(stack.length){
  const moduleName=stack.pop();
  if(visited.has(moduleName))continue;
  const file=modulePath(moduleName);
  if(!fs.existsSync(file)){
    missing.add(moduleName);
    continue;
  }
  const text=fs.readFileSync(file,'utf8');
  const imports=parseImports(text);
  const externSymbols=extractExternSymbols(text);
  const implementedBy=extractImplementedBy(text);
  const features=Object.fromEntries(
    Object.entries(patterns).map(([name,re])=>[name,count(text,re)]),
  );
  visited.set(moduleName,{
    module:moduleName,
    path:normalizeRel(file),
    bytes:Buffer.byteLength(text),
    imports,
    externSymbols,
    implementedBy,
    features,
  });
  for(const dep of [...imports].reverse()){
    if(!visited.has(dep))stack.push(dep);
  }
}

const modules=[...visited.values()].sort((a,b)=>a.module.localeCompare(b.module));
const allExterns=new Set();
const allImplementedBy=new Set();
let bytes=0;
for(const item of modules){
  bytes+=item.bytes;
  for(const symbol of item.externSymbols)allExterns.add(symbol);
  for(const name of item.implementedBy)allImplementedBy.add(name);
}

const externSymbols=[...allExterns].sort();
const coveredExternSymbols=externSymbols.filter((x)=>implementedExterns.has(x));
const uncoveredExternSymbols=externSymbols.filter((x)=>!implementedExterns.has(x));

const byTopLevel={};
for(const item of modules){
  const top=item.module.split('.')[0]??item.module;
  byTopLevel[top]=(byTopLevel[top]??0)+1;
}

const report={
  format:'proofscript-lean434-source-closure',
  formatVersion:1,
  leanVersion:'4.34.0',
  roots:requestedRoots,
  totals:{
    modules:modules.length,
    bytes,
    missingModules:missing.size,
    externSymbols:externSymbols.length,
    implementedExternSymbols:coveredExternSymbols.length,
    uncoveredExternSymbols:uncoveredExternSymbols.length,
    implementedByTargets:allImplementedBy.size,
  },
  byTopLevel,
  externCoverage:{
    implemented:coveredExternSymbols,
    missing:uncoveredExternSymbols,
  },
  missingModules:[...missing].sort(),
  modules,
};

process.stdout.write(JSON.stringify(report,null,2)+'\n');
