// Apply the owner's project license to owned packages only. Third-party bytes stay intact.
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import assert from 'node:assert/strict';
const license=fs.readFileSync(fileURLToPath(new URL('../../LICENSE',import.meta.url)),'utf8');
const notice=fs.readFileSync(fileURLToPath(new URL('../../NOTICE',import.meta.url)),'utf8');
export function projectOwnedName(name){
  return ['proofscript','lean-ts-kernel','pskernel-cli'].includes(name)||name?.startsWith('@proofscript/');
}
export function applyProjectLicense(directory){
  const metaFile=path.join(directory,'package.json'),meta=JSON.parse(fs.readFileSync(metaFile));
  assert.ok(projectOwnedName(meta.name),'never rewrite a third-party package license: '+meta.name);
  const changed=[],added=[];
  const licenseFile=path.join(directory,'LICENSE');
  let canonical='LICENSE';
  if(fs.existsSync(licenseFile)){
    assert.ok(fs.lstatSync(licenseFile).isFile()&&!fs.lstatSync(licenseFile).isSymbolicLink());
    // Preserve pre-existing license bytes; provide the new owner grant separately.
    if(fs.readFileSync(licenseFile,'utf8')!==license)canonical='APACHE-2.0.txt';
  }
  const destination=path.join(directory,canonical);
  if(!fs.existsSync(destination)){fs.writeFileSync(destination,license,{flag:'wx'});added.push(canonical);}
  else assert.equal(fs.readFileSync(destination,'utf8'),license,'canonical project license changed');
  changed.push(canonical);
  const noticeFile=path.join(directory,'NOTICE');
  if(fs.existsSync(noticeFile)){
    const previous=fs.readFileSync(noticeFile,'utf8');
    if(!previous.includes(notice))fs.writeFileSync(noticeFile,previous+'\n\n'+notice);
  }else{fs.writeFileSync(noticeFile,notice,{flag:'wx'});added.push('NOTICE');}
  changed.push('NOTICE');
  meta.license='Apache-2.0';
  if(Array.isArray(meta.files))for(const file of [canonical,'NOTICE'])
    if(!meta.files.includes(file))meta.files.push(file);
  fs.writeFileSync(metaFile,JSON.stringify(meta,null,2)+'\n');
  return {package:meta.name,license:'Apache-2.0',addedFiles:added,changedFiles:['package.json',...changed],
    thirdPartyPolicy:'all existing dependency/attribution files retained'};
}
