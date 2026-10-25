// Admitted portable IR -> pinned emit-only worker -> pinned target consumer.
// No source frontend or independent-checker capability crosses this boundary.
import fs from 'node:fs';import path from 'node:path';import {createHash} from 'node:crypto';
const sha=b=>createHash('sha256').update(b).digest('hex');
const fail=code=>{throw Error('PSC1_PROVIDER_'+code);};
const exact=(value,keys)=>{if(!value||typeof value!=='object'||Array.isArray(value)||Object.keys(value).sort().join(',')!==[...keys].sort().join(','))fail('RESPONSE_FIELDS');};
export function prepareOptionalProvider(stage,candidate,target,provider,outputAbi,run){
 if(!provider||provider.target!==target)fail('UNAVAILABLE');
 const input=path.join(stage,'provider-request.json'),names=path.join(stage,'provider-public-names.json');
 const request=JSON.stringify(['psc1-portable-backend-provider/1',target,candidate.specializedIr,candidate.publicNames,outputAbi==='io-dispatcher']);
 fs.writeFileSync(input,request);fs.writeFileSync(names,JSON.stringify(candidate.publicNames));
 // The digest is transport identity only, never validation/admission authority.
 const stdout=run('optional-provider',['emit-portable',input],provider.executable,{PSC1_BACKEND_REQUEST_SHA256:sha(request)});
 if(sha(fs.readFileSync(input))!==sha(request))fail('REQUEST_CHANGED');
 const response=JSON.parse(stdout);
 exact(response,['protocol','target','leanVersion','leanCommit','requestSha256','publicNames','ioDispatcherAbi','candidateOnly','source','auxiliary','runtimeVersion','runtimeSource','runtimeRequirements','declarationLines']);
 if(response.protocol!=='psc1-backend-provider/1'||response.target!==target||response.leanVersion!=='4.35.0'||
 response.leanCommit!=='eb6cafb7290e8bd5f2937522d8d804f58f02bafc'||response.requestSha256!==sha(request)||
 JSON.stringify(response.publicNames)!==JSON.stringify(candidate.publicNames)||response.ioDispatcherAbi!==(outputAbi==='io-dispatcher')||
 response.candidateOnly!==true||typeof response.source!=='string'||!response.source||
 response.runtimeVersion!=='psc1-'+target+'-runtime/1'||typeof response.auxiliary!=='string'||typeof response.runtimeSource!=='string'||
 !Array.isArray(response.runtimeRequirements)||!response.runtimeRequirements.every(x=>typeof x==='string')||!Array.isArray(response.declarationLines))fail('RESPONSE_IDENTITY');
 const targetFile=target==='python'?'target.py':'target.php';
 fs.writeFileSync(path.join(stage,targetFile),response.source);
 fs.writeFileSync(path.join(stage,'provider-response.json'),stdout);
 const observed=JSON.parse(run('provider-target-check',[target+'-check',path.join(stage,targetFile),names],provider.executable));
 if(observed.accepted!==true||JSON.stringify(observed.publicNames)!==JSON.stringify(candidate.publicNames))fail('TARGET_CONSUMER');
 const provenance={schema:'psc1-checked-provider-receipt/1',target,package:provider.package,sourceCommit:provider.sourceCommit,
   binarySha256:provider.pins.find(pin=>pin.path===provider.executable)?.sha256,requestSha256:sha(request),responseSha256:sha(stdout),
   specializedIrSha256:sha(JSON.stringify(candidate.specializedIr)),candidateOnly:true,admissionAuthority:false,publicationAuthority:false,
   strictIr:'native-rechecked-roundtrip-exact',targetRuntime:observed.runtime};
 fs.writeFileSync(path.join(stage,'provider-receipt.json'),JSON.stringify(provenance));
 return {targetFile,runtimeFile:targetFile,sourceFile:targetFile,files:[targetFile,'provider-request.json','provider-public-names.json','provider-response.json','provider-receipt.json'],
   consumer:observed.runtime+'-syntax-exact-public-API',compilerTarget:'js',provider:provenance};
}
