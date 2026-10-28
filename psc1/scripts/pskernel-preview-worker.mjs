import {readFileSync,writeSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
import {replayText} from './pskernel-arena-replay.mjs';
import {scanAssumptions,PolicyFailure} from './pskernel-preview-policy.mjs';

const hash=b=>createHash('sha256').update(b).digest('hex');
const [kernelPath,requestId,inputHash,programHash,policyHash,pinsPath]=process.argv.slice(2);
let assumptions=[],validated=false,lastStage='input',coreInvoked=false;
const progress=value=>{
  lastStage=value.stage??lastStage;coreInvoked=value.coreInvoked??coreInvoked;
  writeSync(2,'PSKERNEL_PREVIEW_PROGRESS '+JSON.stringify({stage:lastStage,coreInvoked,records:value.records??0})+'\n');
};
const base={format:'pskernel-preview-worker-v1',requestId,inputSha256:inputHash,
  programSha256:programHash,policySha256:policyHash,fuel:'4096'};
let result;
try{
  const bytes=readFileSync(0),pinsBytes=readFileSync(pinsPath),program=readFileSync(kernelPath);
  if(bytes.length>67108864||hash(bytes)!==inputHash||hash(pinsBytes)!==policyHash||hash(program)!==programHash)
    throw Error('worker identity mismatch');
  let text;try{text=new TextDecoder('utf-8',{fatal:true}).decode(bytes);}
  catch{throw new PolicyFailure('rejectedInvalid','transport','input is not valid UTF-8');}
  progress({stage:'assumption-scan',coreInvoked:false});
  const policy=scanAssumptions(text,JSON.parse(pinsBytes.toString('utf8')),progress);
  assumptions=policy.assumptions;validated=true;
  progress({stage:'module-load',coreInvoked:false});
  const kernel=await import(pathToFileURL(kernelPath).href);
  const checked=replayText(kernel,text,progress);
  if(checked.verdict!=='accepted'||checked.coreInvoked!==true||checked.metadataValidated!==true)
    throw Error('incomplete independent checking receipt');
  result={...base,outcome:'accepted',stage:'complete',reason:null,assumptions,
    assumptionPolicyValidated:validated,coreInvoked:true,metadataValidated:true,
    admissionCommands:checked.admissionCommands,exportedDeclarations:checked.exportedDeclarations,
    arenaNodes:checked.arenaNodes};
}catch(error){
  const mapping={rejected:'rejectedInvalid',malformed:'rejectedInvalid',unsupported:'declinedUnsupported',
    resource_exhausted:'resourceExhausted',internal_error:'internalError',driver_error:'internalError'};
  const outcome=error instanceof PolicyFailure?error.outcome:
    mapping[error.verdict]??(error instanceof RangeError?'resourceExhausted':'internalError');
  result={...base,outcome,stage:error.stage??lastStage,reason:String(error.message??error).slice(0,4096),
    assumptions:error.assumptions??assumptions,assumptionPolicyValidated:validated,
    coreInvoked:error.replayStats?.coreInvoked??coreInvoked,metadataValidated:false};
}
writeSync(1,JSON.stringify(result)+'\n');
