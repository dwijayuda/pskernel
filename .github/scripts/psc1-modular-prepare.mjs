import fs from 'node:fs';import path from 'node:path';
import assert from 'node:assert/strict';
import {readQualifiedArtifact}from'../../psc1/scripts/kernel435-qualified-artifact.mjs';
const input=JSON.parse(fs.readFileSync('../.github/scripts/psc1-modular-boundary-input.json'));
const root=path.resolve('dist/modular-toolchain');fs.mkdirSync(root,{recursive:true});
for(const [kind,pin]of Object.entries(input).filter(([k])=>['package','targets'].includes(k))){
 const archive=await readQualifiedArtifact(pin,path.join(root,kind+'-input'));
 const names=kind==='package'?['tarballs','package-receipt.json','compiler-admissions.json','consumer-descriptors.json']:
 ['target-tarballs','target-archive-correspondence.json'];
 for(const name of names)fs.cpSync(path.join(archive,name),path.join(root,name),{recursive:true});
}
