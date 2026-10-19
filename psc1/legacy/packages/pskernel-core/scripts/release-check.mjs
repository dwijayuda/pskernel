// A release-process gate, not a soundness theorem or a hostile-code boundary.
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
export const requiredReleaseGates=Object.freeze([
 'term-checking','conversion','inductive-admission','quotient-admission',
 'primitive-validation','axiom-policy','bounded-input-validation',
 'checked-module-integration','compiler-kernel-closure','generated-kernel-fixed-point',
 'promised-library-replay','full-workspace-ci','license-and-attribution','release-provenance'
]);
export function releaseBlockers(manifest,capabilities,apiKeys){
 const errors=[];
 if(manifest.private!==false)errors.push('PACKAGE_PRIVATE');
 if(capabilities.canCheckProofs!==true||capabilities.authoritative!==true)errors.push('NO_PROOF_CHECKING_AUTHORITY');
 if(!apiKeys.includes('checkBundle')&&!apiKeys.includes('createSession'))errors.push('NO_CHECKING_API');
 if(capabilities.status!=='release-candidate')errors.push('NOT_A_RELEASE_CANDIDATE');
 for(const id of requiredReleaseGates){const g=capabilities.releaseGates?.[id];
  if(g?.status!=='passed'||typeof g.evidence!=='string'||!g.evidence.trim())errors.push('INCOMPLETE_GATE:'+id);
 }
 if(!manifest.license||manifest.license==='UNLICENSED')errors.push('RELEASE_LICENSE_UNRESOLVED');
 return errors;
}
const here=fileURLToPath(import.meta.url);
if(process.argv[1]&&path.resolve(process.argv[1])===here){
 const root=path.resolve(path.dirname(here),'..');
 const manifest=JSON.parse(fs.readFileSync(path.join(root,'package.json'),'utf8'));
 const capabilities=JSON.parse(fs.readFileSync(path.join(root,'manifests/CAPABILITIES.json'),'utf8'));
 const api=await import('@proofscript/pskernel-core');
 const errors=releaseBlockers(manifest,capabilities,Object.keys(api));
 console.log(JSON.stringify({releaseReady:errors.length===0,blockers:errors},null,2));
 if(errors.length)process.exitCode=1;
}
