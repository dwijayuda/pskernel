import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';
import path from 'node:path';

const require = createRequire(import.meta.url);
const directory = path.dirname(fileURLToPath(import.meta.url));
const packageManifest = require('../package.json');
const bundle = require('./kernel-manifest.json');
const expected = Object.freeze({
  protocol:'pskernel-core-js/1',
  provider:'psc0-generated-js-core',
  leanVersion:'4.34.0',
  profile:'lean4.34-core',
});
const sha = b => createHash('sha256').update(b).digest('hex');
function verify() {
  for(const [file,expectedHash] of [
    ['index.js',bundle.kernelSha256],['prelude.json',bundle.preludeSha256],
    ['generated-core-provider.mjs',bundle.adapterSha256],
    ['core-cli.mjs',bundle.processSha256],
  ]) {
    if (!/^[a-f0-9]{64}$/u.test(expectedHash)||sha(readFileSync(path.join(directory,file)))!==expectedHash) {
      throw new Error('PSC_JS_CORE_RUNTIME_IDENTITY_MISMATCH: '+file);
    }
  }
  if (packageManifest.name !== '@proofscript/pskernel-core' ||
      packageManifest.proofscript?.kernelQualification !== 'psc0-js-core-cloud-gated/1') {
    throw new Error('PSC_JS_CORE_PACKAGE_IDENTITY');
  }
}
export function checkCanonicalAdmissions(admissions,{timeoutMs=90000,maxMemoryMb=512}={}) {
  if(typeof admissions!=='string')throw TypeError('canonical admissions must be UTF-8 text');
  if(!Number.isSafeInteger(timeoutMs)||timeoutMs<1||timeoutMs>120000||
     !Number.isSafeInteger(maxMemoryMb)||maxMemoryMb<64||maxMemoryMb>1024) throw TypeError('invalid provider bounds');
  if(Buffer.byteLength(admissions,'utf8')>16*1024*1024) throw Error('PSC_JS_CORE_INPUT_TOO_LARGE');
  verify();
  const run=spawnSync(process.execPath,['--max-old-space-size='+maxMemoryMb,path.join(directory,'core-cli.mjs')],{
    input:admissions,encoding:'utf8',timeout:timeoutMs,killSignal:'SIGKILL',
    maxBuffer:4*1024*1024,windowsHide:true,
  });
  if(run.error||run.status!==0) throw Error('PSC_JS_CORE_PROCESS_FAILED: '+(run.error?.code||run.signal||run.status));
  let response;
  try { response=JSON.parse(run.stdout); } catch { throw Error('PSC_JS_CORE_INVALID_JSON'); }
  for(const [k,v] of Object.entries(expected)) if(response[k]!==v)throw Error('PSC_JS_CORE_PROVIDER_IDENTITY: '+k);
  if(typeof response.accepted!=='boolean')throw Error('PSC_JS_CORE_DECISION_INVALID');
  if(response.accepted&&('errorKind' in response||'declarationIndex' in response))throw Error('PSC_JS_CORE_CONTRADICTORY_ACCEPTANCE');
  return Object.freeze({...response,kernelSha256:bundle.kernelSha256,
    kernelSourceRevision:bundle.baseMainCommit,
    trustStatus:'qualified-scope-only'});
}
