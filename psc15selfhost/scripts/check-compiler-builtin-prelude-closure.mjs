import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root=fileURLToPath(new URL('../',import.meta.url));
const builtinPath=path.join(root,'packages','core','src','Ps','Core','Builtin.lean');
const preludePaths=[
  path.join(root,'packages','environment','src','Ps','Environment','Prelude.lean'),
  path.join(root,'packages','environment','src','Ps','Environment','SelfHostPrelude.lean'),
  path.join(root,'packages','environment','src','Ps','Environment','SelfHostProd.lean'),
];
const compilerRoots=[
  path.join(root,'packages','meta','src'),
  path.join(root,'packages','elab','src'),
  path.join(root,'packages','erasure','src'),
  path.join(root,'packages','compiler-ir','src'),
  path.join(root,'packages','compiler','src'),
];

function walk(dir){
  const out=[];
  for(const entry of fs.readdirSync(dir,{withFileTypes:true})){
    const p=path.join(dir,entry.name);
    if(entry.isDirectory()) out.push(...walk(p));
    else if(entry.isFile()&&entry.name.endsWith('.lean')) out.push(p);
  }
  return out;
}

const builtin=fs.readFileSync(builtinPath,'utf8');
const defined=new Set(
  [...builtin.matchAll(/^def\s+(ps[A-Za-z0-9]+Name)\s*:\s*PsName\s*:=/gmu)].map(m=>m[1]),
);

const prelude=preludePaths.map(p=>fs.readFileSync(p,'utf8')).join('\n');
const declared=new Set([
  ...[...prelude.matchAll(/PsDeclaration\.axiomDecl\s+(ps[A-Za-z0-9]+Name)\b/gmu)].map(m=>m[1]),
  ...[...prelude.matchAll(/PsInductiveInfo\.mk\s+(ps[A-Za-z0-9]+Name)\b/gmu)].map(m=>m[1]),
  ...[...prelude.matchAll(/PsConstructorInfo\.mk\s+(ps[A-Za-z0-9]+Name)\b/gmu)].map(m=>m[1]),
  ...[...prelude.matchAll(/PsRecursorInfo\.mk\s+(ps[A-Za-z0-9]+Name)\b/gmu)].map(m=>m[1]),
]);

const references=new Map();
for(const dir of compilerRoots){
  for(const file of walk(dir)){
    const source=fs.readFileSync(file,'utf8');
    for(const name of defined){
      const re=new RegExp('\\b'+name+'\\b','u');
      if(re.test(source)){
        const rel=path.relative(root,file).replaceAll(path.sep,'/');
        const current=references.get(name)??[];
        current.push(rel);
        references.set(name,current);
      }
    }
  }
}

const missing=[...references.keys()].filter(name=>!declared.has(name)).sort();
assert.deepEqual(
  missing,
  [],
  'compiler semantic layers reference builtin names absent from final self-host prelude',
);

const unusedUndeclared=[...defined].filter(name=>!declared.has(name)&&!references.has(name)).sort();
const report={
  schemaVersion:1,
  builtinNameCount:defined.size,
  finalPreludeBuiltinDeclarationCount:[...defined].filter(name=>declared.has(name)).length,
  compilerReferencedBuiltinCount:references.size,
  compilerReferencedBuiltins:[...references.entries()]
    .sort(([a],[b])=>a.localeCompare(b,'en'))
    .map(([name,files])=>({name,files:[...new Set(files)].sort()})),
  missing,
  undeclaredButUnreferencedBuiltins:unusedUndeclared,
};
const outDir=path.join(root,'.lake','lean434-type-audit');
fs.mkdirSync(outDir,{recursive:true});
fs.writeFileSync(
  path.join(outDir,'compiler-builtin-prelude-closure.json'),
  JSON.stringify(report,null,2)+'\n',
);
console.log('COMPILER_BUILTIN_PRELUDE_CLOSURE: PASS '+JSON.stringify({
  builtinNameCount:report.builtinNameCount,
  finalPreludeBuiltinDeclarationCount:report.finalPreludeBuiltinDeclarationCount,
  compilerReferencedBuiltinCount:report.compilerReferencedBuiltinCount,
  undeclaredButUnreferencedBuiltins:report.undeclaredButUnreferencedBuiltins,
}));
