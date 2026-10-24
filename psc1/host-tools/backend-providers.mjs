// Filesystem/process transport only. This module has no parser, elaborator,
// kernel admission or publication authority. Providers are explicit compiler
// components, not portable source-library plugins.
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
import {isDeepStrictEqual} from 'node:util';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const pin=JSON.parse(fs.readFileSync(path.join(root,'NATIVE_SOURCE_PIN.json'),'utf8'));
export const backendProviderProtocol='psc1-backend-provider/1';
export const backendProviderMaxBytes=64*1024*1024;
const targets=new Set(['python','php']);
const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
const fail=(code,detail='')=>{throw Error(code+(detail?': '+detail:''));};
const read=file=>JSON.parse(fs.readFileSync(file,'utf8'));
const exact=(value,keys,code)=>{
 if(!value||typeof value!=='object'||Array.isArray(value)||
  JSON.stringify(Object.keys(value).sort())!==JSON.stringify([...keys].sort()))fail(code);
};
function executable(file,expected,packageRoot){
 const resolved=fs.realpathSync(file),rel=path.relative(fs.realpathSync(packageRoot),resolved);
 if(!rel||rel==='..'||rel.startsWith('..'+path.sep)||path.isAbsolute(rel))fail('PSC1_PROVIDER_PATH_ESCAPE');
 const stat=fs.statSync(resolved);
 if(!stat.isFile()||stat.size!==expected.bytes||sha(fs.readFileSync(resolved))!==expected.sha256)
  fail('PSC1_PROVIDER_BINARY_INTEGRITY');
 return resolved;
}
export function resolveBackendProvider(target,importer){
 if(!targets.has(target))fail('PSC1_PROVIDER_TARGET');
 const packageName='@proofscript/backend-'+target;
 const distributionFile=path.join(root,'NATIVE_DISTRIBUTION.json');
 if(!fs.existsSync(distributionFile)){
  const workspace=read(path.join(root,'package.json'));
  if(workspace.name!=='@proofscript/psc1-workspace'||workspace.private!==true)
   fail('PSC1_PROVIDER_DISTRIBUTION_MISSING');
  const binary=path.join(root,'.lake/build/bin/psc1_backend_'+target);
  if(!fs.existsSync(binary))fail('PSC1_BACKEND_PROVIDER_MISSING','lake build psc1_backend_'+target);
  const stat=fs.statSync(binary),digest=sha(fs.readFileSync(binary));
  return {target,packageName,version:'workspace',binary,
   binarySha256:digest,binaryBytes:stat.size,compilerSourceCommit:null,mode:'explicit-workspace-build'};
 }
 const distribution=read(distributionFile),core=read(path.join(root,'package.json'));
 let manifest;
 for(const from of [path.resolve(importer),path.join(root,'package.json')]){
  try{manifest=createRequire(from).resolve(packageName+'/package.json');break;}
  catch(error){if(error.code!=='MODULE_NOT_FOUND'&&error.code!=='ERR_PACKAGE_PATH_NOT_EXPORTED')throw error;}
 }
 if(!manifest)fail('PSC1_BACKEND_PROVIDER_MISSING','npm install '+packageName);
 const meta=read(manifest),contract=meta.proofscript?.backendProvider;
 exact(contract,['schema','protocol','target','compilerProtocol','compilerProfile',
  'leanVersion','leanCommit','compilerSourceCommit','runtimeContract','native','resources'],
  'PSC1_PROVIDER_PACKAGE_SCHEMA');
 if(meta.name!==packageName||meta.version!==core.version||contract.schema!=='psc1-backend-package/1'||
  contract.protocol!==backendProviderProtocol||contract.target!==target||
  contract.compilerProtocol!==pin.compilerProtocol||contract.compilerProfile!==pin.compilerProfile||
  contract.leanVersion!==pin.version||contract.leanCommit!==pin.commit||
  contract.runtimeContract!=='psc1-runtime-semantics/1'||
  !/^[a-f0-9]{40}$/.test(contract.compilerSourceCommit)||
  contract.compilerSourceCommit!==distribution.sourceCommit)fail('PSC1_PROVIDER_PACKAGE_IDENTITY');
 if(!isDeepStrictEqual(contract,distribution.backendProviderPackages?.[target]))
  fail('PSC1_PROVIDER_PACKAGE_IDENTITY','provider must match the core-pinned build artifact');
 exact(contract.native,['path','sha256','bytes'],'PSC1_PROVIDER_NATIVE_SCHEMA');
 if(contract.native.path!=='native/bin/psc1_backend_'+target||
  !/^[a-f0-9]{64}$/.test(contract.native.sha256)||
  !Number.isSafeInteger(contract.native.bytes)||contract.native.bytes<=0)
  fail('PSC1_PROVIDER_NATIVE_SCHEMA');
 if(!Array.isArray(contract.resources))fail('PSC1_PROVIDER_RESOURCES');
 const packageRoot=path.dirname(manifest);
 for(const resource of contract.resources){
  exact(resource,['path','sha256','bytes'],'PSC1_PROVIDER_RESOURCE_SCHEMA');
  if(typeof resource.path!=='string'||!/^resources\/[A-Za-z0-9_.-]+$/.test(resource.path)||
   !/^[a-f0-9]{64}$/.test(resource.sha256)||!Number.isSafeInteger(resource.bytes)||resource.bytes<0)
   fail('PSC1_PROVIDER_RESOURCE_SCHEMA');
  executable(path.join(packageRoot,resource.path),resource,packageRoot);
 }
 const binary=executable(path.join(packageRoot,contract.native.path),contract.native,packageRoot);
 return {target,packageName,version:meta.version,binary,binarySha256:contract.native.sha256,
  binaryBytes:contract.native.bytes,compilerSourceCommit:contract.compilerSourceCommit,mode:'installed-package'};
}
const requestKeys=['protocol','target','leanVersion','leanCommit','ir','publicNames','ioDispatcherAbi'];
const responseKeys=['protocol','target','leanVersion','leanCommit','requestSha256','publicNames',
 'ioDispatcherAbi','candidateOnly','source','auxiliary','runtimeVersion','runtimeSource',
 'runtimeRequirements','declarationLines'];
export function emitBackendProvider(stage,target,requestFile,importer){
 const provider=resolveBackendProvider(target,importer);
 const requestPath=fs.realpathSync(requestFile),stagePath=fs.realpathSync(stage);
 if(path.dirname(requestPath)!==stagePath||path.basename(requestPath)!=='backend-request.json')
  fail('PSC1_PROVIDER_REQUEST_PATH');
 if(fs.statSync(requestPath).size>backendProviderMaxBytes)fail('PSC1_PROVIDER_REQUEST_LIMIT');
 const requestBytes=fs.readFileSync(requestPath),request=JSON.parse(requestBytes);
 exact(request,requestKeys,'PSC1_PROVIDER_REQUEST_SCHEMA');
 if(request.protocol!==backendProviderProtocol||request.target!==target||
  request.leanVersion!==pin.version||request.leanCommit!==pin.commit||
  !Array.isArray(request.publicNames)||!request.publicNames.every(x=>typeof x==='string')||
  typeof request.ioDispatcherAbi!=='boolean')fail('PSC1_PROVIDER_REQUEST_IDENTITY');
 const identity=spawnSync(provider.binary,['--identity'],{encoding:'utf8',timeout:10000,maxBuffer:1024*1024});
 if(identity.error||identity.status!==0)fail('PSC1_PROVIDER_EXECUTION_IDENTITY');
 const id=JSON.parse(identity.stdout);
 exact(id,['protocol','target','leanVersion','leanCommit','candidateOnly'],'PSC1_PROVIDER_EXECUTION_IDENTITY');
 if(id.protocol!==backendProviderProtocol||id.target!==target||id.leanVersion!==pin.version||
  id.leanCommit!==pin.commit||id.candidateOnly!==true)fail('PSC1_PROVIDER_EXECUTION_IDENTITY');
 const requestSha256=sha(requestBytes);
 const result=spawnSync(provider.binary,['emit',requestPath],{encoding:'utf8',timeout:120000,
  maxBuffer:backendProviderMaxBytes,env:{...process.env,PSC1_BACKEND_REQUEST_SHA256:requestSha256}});
 if(result.error||result.status!==0)fail('PSC1_PROVIDER_EXECUTION_FAILED',
  result.error?.message||result.stderr?.slice(-6000)||String(result.signal));
 if(Buffer.byteLength(result.stdout)>backendProviderMaxBytes)fail('PSC1_PROVIDER_RESPONSE_LIMIT');
 if(sha(fs.readFileSync(requestPath))!==requestSha256||
  sha(fs.readFileSync(provider.binary))!==provider.binarySha256)fail('PSC1_PROVIDER_EXECUTION_MUTATION');
 const response=JSON.parse(result.stdout);
 exact(response,responseKeys,'PSC1_PROVIDER_RESPONSE_SCHEMA');
 if(response.protocol!==backendProviderProtocol||response.target!==target||
  response.leanVersion!==pin.version||response.leanCommit!==pin.commit||
  response.requestSha256!==requestSha256||response.candidateOnly!==true||
  JSON.stringify(response.publicNames)!==JSON.stringify(request.publicNames)||
  response.ioDispatcherAbi!==request.ioDispatcherAbi||
  response.runtimeVersion!=='psc1-'+target+'-runtime/1'||
  !['source','auxiliary','runtimeSource'].every(k=>typeof response[k]==='string')||
  !Array.isArray(response.runtimeRequirements)||!response.runtimeRequirements.every(x=>typeof x==='string')||
  !Array.isArray(response.declarationLines)||!response.declarationLines.every(
   x=>Array.isArray(x)&&x.length===2&&typeof x[0]==='string'&&Number.isSafeInteger(x[1])&&x[1]>=0))
  fail('PSC1_PROVIDER_RESPONSE_IDENTITY');
 const infoFile=path.join(stagePath,'psc1-input.json'),info=read(infoFile);
 const receipt={protocol:backendProviderProtocol,target,packageName:provider.packageName,
  version:provider.version,mode:provider.mode,compilerSourceCommit:provider.compilerSourceCommit,
  binarySha256:provider.binarySha256,requestSha256,responseSha256:sha(Buffer.from(result.stdout)),
  candidateOnly:true,publicationAuthority:'core-host'};
 fs.writeFileSync(infoFile,JSON.stringify({...info,backendProvider:receipt},null,2)+'\n');
 return response;
}

export function validateBackendProviderReceipt(value,target){
 exact(value,['protocol','target','packageName','version','mode','compilerSourceCommit',
  'binarySha256','requestSha256','responseSha256','candidateOnly','publicationAuthority'],
  'PSC1_PROVIDER_RECEIPT_SCHEMA');
 if(!targets.has(target)||value.target!==target||value.protocol!==backendProviderProtocol||
  value.packageName!=='@proofscript/backend-'+target||typeof value.version!=='string'||
  !['explicit-workspace-build','installed-package'].includes(value.mode)||
  value.candidateOnly!==true||value.publicationAuthority!=='core-host'||
  !['binarySha256','requestSha256','responseSha256'].every(k=>/^[a-f0-9]{64}$/.test(value[k]))||
  (value.mode==='installed-package'?!/^[a-f0-9]{40}$/.test(value.compilerSourceCommit):value.compilerSourceCommit!==null))
  fail('PSC1_PROVIDER_RECEIPT_IDENTITY');
 return value;
}
