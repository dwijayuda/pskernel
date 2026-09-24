import fs from 'node:fs';
import path from 'node:path';

const repoRoot=process.cwd();
const sourceRoot=path.join(repoRoot,'study','lean4-4.34.0','src');

const targets=[
  ['Init','Init'],
  ['Parser',path.join('Lean','Parser')],
  ['Meta',path.join('Lean','Meta')],
  ['Elab',path.join('Lean','Elab')],
  ['Compiler',path.join('Lean','Compiler')],
];

const featurePatterns={
  extern:/@\[\s*extern\b/g,
  implementedBy:/@\[\s*implemented_by\b/g,
  unsafe:/\bunsafe\b/g,
  partialDef:/\bpartial\s+def\b/g,
  opaque:/\bopaque\b/g,
  builtinInitialize:/\bbuiltin_initialize\b/g,
  io:/\bIO\b/g,
  baseIO:/\bBaseIO\b/g,
  eio:/\bEIO\b/g,
  st:/\bST\b/g,
  task:/\bTask\b/g,
  ref:/\bRef\b/g,
  array:/\bArray\b/g,
  string:/\bString\b/g,
  name:/\bName\b/g,
  expr:/\bExpr\b/g,
  syntax:/\bSyntax\b/g,
};

function countMatches(text,re){
  re.lastIndex=0;
  let n=0;
  while(re.exec(text)!==null)n++;
  return n;
}

function walkLeanFiles(dir){
  const out=[];
  const todo=[dir];
  while(todo.length){
    const current=todo.pop();
    for(const entry of fs.readdirSync(current,{withFileTypes:true})
      .sort((a,b)=>a.name.localeCompare(b.name))){
      const full=path.join(current,entry.name);
      if(entry.isDirectory())todo.push(full);
      else if(entry.isFile()&&entry.name.endsWith('.lean'))out.push(full);
    }
  }
  return out.sort();
}

function extractExternSymbols(text){
  const symbols=new Set();
  // The first bootstrap pass only records ordinary quoted extern symbols.
  // Backend-specific/adhoc entries remain visible through the raw extern count
  // and can be parsed structurally once the compatibility frontend owns attrs.
  const re=/@\[\s*extern(?:\s+[A-Za-z_][A-Za-z0-9_.]*)?\s+"([^"]+)"/g;
  for(const m of text.matchAll(re))symbols.add(m[1]);
  return [...symbols].sort();
}

if(!fs.existsSync(sourceRoot)){
  throw new Error('missing pinned Lean source at '+path.relative(repoRoot,sourceRoot));
}

const report={
  format:'proofscript-lean434-js-runtime-census',
  formatVersion:1,
  leanVersion:'4.34.0',
  sourceRoot:path.relative(repoRoot,sourceRoot).replaceAll(path.sep,'/'),
  totals:{
    files:0,
    bytes:0,
    features:Object.fromEntries(Object.keys(featurePatterns).map(k=>[k,0])),
    externSymbols:[],
  },
  targets:[],
};

const allExternSymbols=new Set();

for(const [name,relative] of targets){
  const dir=path.join(sourceRoot,relative);
  const files=walkLeanFiles(dir);
  const target={
    name,
    root:path.relative(repoRoot,dir).replaceAll(path.sep,'/'),
    files:files.length,
    bytes:0,
    features:Object.fromEntries(Object.keys(featurePatterns).map(k=>[k,0])),
    externSymbols:[],
    featureFiles:[],
  };
  const targetExternSymbols=new Set();

  for(const file of files){
    const text=fs.readFileSync(file,'utf8');
    const rel=path.relative(repoRoot,file).replaceAll(path.sep,'/');
    const features={};
    let interesting=false;
    for(const [feature,re] of Object.entries(featurePatterns)){
      const count=countMatches(text,re);
      features[feature]=count;
      target.features[feature]+=count;
      report.totals.features[feature]+=count;
      if(count>0&&[
        'extern','implementedBy','unsafe','partialDef','opaque',
        'builtinInitialize','io','baseIO','eio','st','task','ref'
      ].includes(feature))interesting=true;
    }
    const externSymbols=extractExternSymbols(text);
    for(const symbol of externSymbols){
      targetExternSymbols.add(symbol);
      allExternSymbols.add(symbol);
    }
    const bytes=Buffer.byteLength(text);
    target.bytes+=bytes;
    report.totals.bytes+=bytes;
    report.totals.files++;
    if(interesting){
      target.featureFiles.push({path:rel,features,externSymbols});
    }
  }

  target.externSymbols=[...targetExternSymbols].sort();
  target.featureFiles.sort((a,b)=>a.path.localeCompare(b.path));
  report.targets.push(target);
}

report.totals.externSymbols=[...allExternSymbols].sort();

process.stdout.write(JSON.stringify(report,null,2)+'\n');
