import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

function modulePath(sourceRoot,moduleName){
  return path.join(sourceRoot,...moduleName.split('.'))+'.lean';
}

function parseImports(source){
  const imports=[];
  for(const rawLine of source.split(/\r?\n/u)){
    const line=rawLine.replace(/--.*$/u,'').trim();
    const match=/^(?:public\s+)?import\s+(.+)$/u.exec(line);
    if(!match) continue;
    for(const token of match[1].trim().split(/\s+/u)){
      if(token.length>0) imports.push(token);
    }
  }
  return imports;
}

export function resolveProviderModules(sourceRoot,roots=['PsKernelLean.Main']){
  if(typeof sourceRoot!=='string'||sourceRoot.length===0){
    throw new TypeError('provider source root must be a non-empty string');
  }
  if(!Array.isArray(roots)||roots.length===0){
    throw new TypeError('provider roots must be a non-empty array');
  }

  const ordered=[];
  const states=new Map();

  function visit(moduleName,required){
    const file=modulePath(sourceRoot,moduleName);
    if(!fs.existsSync(file)){
      if(required) throw new Error(`provider root module missing: ${moduleName}`);
      return;
    }
    const state=states.get(moduleName);
    if(state==='done') return;
    if(state==='visiting'){
      throw new Error(`provider local import cycle at ${moduleName}`);
    }
    states.set(moduleName,'visiting');
    const source=fs.readFileSync(file,'utf8');
    for(const dependency of parseImports(source)){
      visit(dependency,false);
    }
    states.set(moduleName,'done');
    ordered.push(moduleName);
  }

  for(const root of roots) visit(root,true);
  return ordered;
}

const invokedPath=process.argv[1]===undefined?null:path.resolve(process.argv[1]);
if(invokedPath===fileURLToPath(import.meta.url)){
  const sourceRoot=process.argv[2];
  const roots=process.argv.slice(3);
  const modules=resolveProviderModules(
    sourceRoot,
    roots.length===0?['PsKernelLean.Main']:roots,
  );
  for(const moduleName of modules) console.log(moduleName.replaceAll('.','/'));
}
