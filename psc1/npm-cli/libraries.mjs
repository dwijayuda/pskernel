// Declarative, source-only resolution for npm-published ProofScript libraries.
// This file does not import or execute code from third-party npm packages.
import { createRequire } from 'node:module';
import { readFile, realpath } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';

const namespacePattern=/^[A-Za-z_][A-Za-z_0-9]*(?:\.[A-Za-z_][A-Za-z_0-9]*)*$/u;
function fail(code, detail='') { throw Error('PSC_LIBRARY_'+code+(detail?': '+detail:'')); }
function inside(root, filename) {
  const rel=path.relative(root,filename);
  return rel!=='' && rel!=='..' && !rel.startsWith('..'+path.sep) && !path.isAbsolute(rel);
}
async function loadJson(file) {
  const data=await readFile(file,'utf8');
  if(Buffer.byteLength(data,'utf8')>1024*1024)fail('METADATA_LIMIT',file);
  const value=JSON.parse(data);
  if(!value || Array.isArray(value) || typeof value!=='object')fail('METADATA_SHAPE',file);
  return value;
}
export async function nearestProject(directory) {
  let here=path.resolve(directory);
  for(let i=0;i<64;i++){
    const file=path.join(here,'package.json');
    if(existsSync(file))return {root:here,meta:await loadJson(file),file};
    const parent=path.dirname(here);
    if(parent===here)break;
    here=parent;
  }
  return {root:path.resolve(directory),meta:{},file:null};
}
function declaredLibraries(project) {
  const cfg=project.meta.proofscript;
  if(cfg===undefined)return [];
  if(!cfg || typeof cfg!=='object' || Array.isArray(cfg))fail('PROJECT_POLICY');
  const libs=cfg.libraries;
  if(libs===undefined)return [];
  if(!libs || typeof libs!=='object' || Array.isArray(libs))fail('LIBRARIES_SHAPE');
  const result=[];
  for(const [namespace,packageName] of Object.entries(libs)){
    if(!namespacePattern.test(namespace) || namespace==='Ps'||namespace.startsWith('Ps.'))fail('RESERVED_NAMESPACE',namespace);
    if(namespace==='ProofScript' && packageName!=='@proofscript/stdlib')fail('RESERVED_STDLIB',String(packageName));
    if(namespace.startsWith('ProofScript.') && packageName!=='@proofscript/stdlib')fail('RESERVED_STDLIB',namespace);
    if(typeof packageName!=='string' || !/^(?:@[a-z0-9._-]+\/)?[a-z0-9._-]+$/u.test(packageName))fail('PACKAGE_NAME',namespace);
    if(!Object.hasOwn(project.meta.dependencies||{},packageName) &&
       !Object.hasOwn(project.meta.devDependencies||{},packageName))fail('UNDECLARED_DEPENDENCY',packageName);
    result.push({namespace,packageName});
  }
  return result.sort((a,b)=>b.namespace.length-a.namespace.length);
}
export async function resolveSourceModule(moduleName,sourceKind,project) {
  if(!namespacePattern.test(moduleName))fail('MODULE_NAME',String(moduleName));
  if(!['ps','lean'].includes(sourceKind))fail('SOURCE_KIND',String(sourceKind));
  if(moduleName==='Ps' || moduleName.startsWith('Ps.'))fail('RESERVED_MODULE',moduleName);
  const mapping=declaredLibraries(project).find(m=>moduleName===m.namespace||
    moduleName.startsWith(m.namespace+'.'));
  const parts=moduleName.split('.');
  if(!mapping){
    if(moduleName==='ProofScript'||moduleName.startsWith('ProofScript.'))fail('STDLIB_NOT_CONFIGURED','install @proofscript/stdlib and register it');
    const root=await realpath(project.root);
    for(const base of ['src','.']){
      const filename=path.join(project.root,base,...parts)+'.'+sourceKind;
      if(!existsSync(filename))continue;
      const resolved=await realpath(filename);
      if(!inside(root,resolved))fail('LOCAL_SOURCE_ESCAPE',filename);
      return resolved;
    }
    fail('MODULE_NOT_FOUND',moduleName);
  }
  const req=createRequire(project.file || path.join(project.root,'package.json'));
  let pkgFile;
  try { pkgFile=req.resolve(mapping.packageName+'/package.json'); }
  catch { fail('PACKAGE_NOT_INSTALLED',mapping.packageName); }
  const pkg=await loadJson(pkgFile);
  if(pkg.name!==mapping.packageName)fail('PACKAGE_IDENTITY',mapping.packageName);
  const library=pkg.proofscript?.library;
  if(library?.schemaVersion!==1||library?.modulePrefix!==mapping.namespace||
     library?.sourceRoot!=='src')fail('PACKAGE_MANIFEST',mapping.packageName);
  const realRoot=await realpath(path.dirname(pkgFile));
  const relativeModule=path.join('src',...parts)+'.'+sourceKind;
  const candidate=path.join(realRoot,relativeModule);
  if(!existsSync(candidate))fail('SOURCE_VARIANT_MISSING',mapping.packageName+'/'+relativeModule);
  const resolved=await realpath(candidate);
  if(!inside(realRoot,resolved))fail('PACKAGE_SOURCE_ESCAPE',candidate);
  return resolved;
}
