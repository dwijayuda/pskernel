// Bounded child adapter for the genuine unified compiler service.
import fs from 'node:fs';import crypto from 'node:crypto';import {pathToFileURL} from 'node:url';
const [file,expected,kind,input,output]=process.argv.slice(2),sha=b=>crypto.createHash('sha256').update(b).digest('hex');
if(!['embedded','bundle'].includes(kind)||!/^[0-9a-f]{64}$/.test(expected||''))throw Error('PSC1_CANDIDATE_RUNNER_ARGUMENTS');
if(sha(fs.readFileSync(file))!==expected)throw Error('PSC1_CANDIDATE_SERVICE_IDENTITY');
const data=fs.readFileSync(input);if(data.length>128*1024*1024)throw Error('PSC1_CANDIDATE_INPUT_LIMIT');
const module=await import(pathToFileURL(file).href),fn=kind==='embedded'?module.psCompilerServiceCandidate:module.compileCandidate;
if(typeof fn!=='function')throw Error('PSC1_CANDIDATE_SERVICE_EXPORT');
const result=fn(data.toString('utf8'));if(typeof result!=='string'||Buffer.byteLength(result)>128*1024*1024)throw Error('PSC1_CANDIDATE_OUTPUT_LIMIT');
if(sha(fs.readFileSync(file))!==expected||sha(fs.readFileSync(input))!==sha(data))throw Error('PSC1_CANDIDATE_INPUT_CHANGED');
fs.writeFileSync(output,result,{flag:'wx'});
