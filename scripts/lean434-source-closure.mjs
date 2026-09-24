import fs from 'node:fs';
import path from 'node:path';

const repoRoot=process.cwd();
const bootstrapConfigPath=path.join(
  repoRoot,'packages','runtime','lean434-bootstrap.json',
);
const bootstrapConfig=JSON.parse(
  fs.readFileSync(bootstrapConfigPath,'utf8'),
);
if(
  bootstrapConfig.format!=='proofscript-lean434-js-bootstrap'
  ||bootstrapConfig.formatVersion!==1
  ||bootstrapConfig.leanVersion!=='4.34.0'
){
  throw new Error('invalid Lean 4.34 JS bootstrap configuration');
}
const sourceRoot=path.join(repoRoot,...bootstrapConfig.sourceRoot.split('/'));

const roots=process.argv.slice(2);
const requestedRoots=roots.length===0
  ?['Lean.Parser','Lean.Meta.Basic','Lean.Elab.Frontend']
  :roots;

const prunedImportsByModule=new Map(
  Object.entries(bootstrapConfig.prunedImports??{}).map(([moduleName,items])=>[
    moduleName,
    new Map(items.map((item)=>[item.module,item.reason])),
  ]),
);

function modulePath(moduleName){
  return path.join(sourceRoot,...moduleName.split('.'))+'.lean';
}

function normalizeRel(file){
  return path.relative(repoRoot,file).replaceAll(path.sep,'/');
}

function stripLeanComments(text){
  let out='';
  let blockDepth=0;
  let lineComment=false;
  let inString=false;
  let escaped=false;
  for(let i=0;i<text.length;i+=1){
    const a=text[i];
    const b=text[i+1];
    if(lineComment){
      if(a==='\n'){
        lineComment=false;
        out+='\n';
      }else out+=' ';
      continue;
    }
    if(blockDepth>0){
      if(a==='/'&&b==='-'){
        blockDepth+=1;
        out+='  ';
        i+=1;
      }else if(a==='-'&&b==='/'){
        blockDepth-=1;
        out+='  ';
        i+=1;
      }else if(a==='\n')out+='\n';
      else out+=' ';
      continue;
    }
    if(inString){
      out+=a;
      if(escaped)escaped=false;
      else if(a==='\\')escaped=true;
      else if(a==='"')inString=false;
      continue;
    }
    if(a==='"'){
      inString=true;
      out+=a;
      continue;
    }
    if(a==='-'&&b==='-'){
      lineComment=true;
      out+='  ';
      i+=1;
      continue;
    }
    if(a==='/'&&b==='-'){
      blockDepth=1;
      out+='  ';
      i+=1;
      continue;
    }
    out+=a;
  }
  return out;
}

function parseImports(text){
  const out=[];
  for(const line of stripLeanComments(text).split(/\r?\n/u)){
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
const appliedPrunes=[];
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
  const rawImports=parseImports(text);
  const configuredPrunes=prunedImportsByModule.get(moduleName)??new Map();
  for(const [dep,reason] of configuredPrunes){
    if(!rawImports.includes(dep)){
      throw new Error(
        'bootstrap import prune drift: '+moduleName+
        ' no longer imports '+dep,
      );
    }
    appliedPrunes.push({module:moduleName,import:dep,reason});
  }
  const imports=rawImports.filter((dep)=>!configuredPrunes.has(dep));
  const externSymbols=extractExternSymbols(text);
  const implementedBy=extractImplementedBy(text);
  const features=Object.fromEntries(
    Object.entries(patterns).map(([name,re])=>[name,count(text,re)]),
  );
  visited.set(moduleName,{
    module:moduleName,
    path:normalizeRel(file),
    bytes:Buffer.byteLength(text),
    rawImports,
    imports,
    prunedImports:rawImports.filter((dep)=>configuredPrunes.has(dep)),
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
  formatVersion:2,
  leanVersion:'4.34.0',
  bootstrapConfig:normalizeRel(bootstrapConfigPath),
  roots:requestedRoots,
  totals:{
    modules:modules.length,
    bytes,
    missingModules:missing.size,
    prunedImportEdges:appliedPrunes.length,
    externSymbols:externSymbols.length,
    implementedExternSymbols:coveredExternSymbols.length,
    uncoveredExternSymbols:uncoveredExternSymbols.length,
    implementedByTargets:allImplementedBy.size,
  },
  byTopLevel,
  appliedPrunes:appliedPrunes.sort((a,b)=>
    (a.module+'.'+a.import).localeCompare(b.module+'.'+b.import)
  ),
  externCoverage:{
    implemented:coveredExternSymbols,
    missing:uncoveredExternSymbols,
  },
  missingModules:[...missing].sort(),
  rootsDetail:requestedRoots.map((root)=>{
    const item=visited.get(root);
    return item===undefined
      ?{module:root,missing:true}
      :{
          module:root,
          rawImports:item.rawImports,
          imports:item.imports,
          prunedImports:item.prunedImports,
        };
  }),
  modules,
};

process.stdout.write(JSON.stringify(report,null,2)+'\n');
