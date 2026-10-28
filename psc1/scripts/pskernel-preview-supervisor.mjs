import {spawn} from 'node:child_process';
import {open,readFile} from 'node:fs/promises';
import {constants} from 'node:fs';
import {createHash,randomUUID} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {TARGET} from './pskernel-preview-policy.mjs';
import {parseExactJSON} from './pskernel-arena-replay.mjs';

export const LIMITS=Object.freeze({fuel:4096,oldSpaceMiB:2048,inputLimitBytes:67108864,
  stdoutLimitBytes:262144,stderrLimitBytes:1048576});
const hash=b=>createHash('sha256').update(b).digest('hex');
const here=path.dirname(fileURLToPath(import.meta.url));
const outcomes=new Set(['accepted','rejectedInvalid','declinedUnsupported','resourceExhausted','internalError']);
const digits=x=>typeof x==='string'&&/^(0|[1-9][0-9]*)$/u.test(x);
const count=x=>Number.isSafeInteger(x)&&x>=0;
const exactKeys=(x,keys)=>x&&typeof x==='object'&&!Array.isArray(x)&&
  Object.keys(x).length===keys.length&&keys.every(k=>Object.hasOwn(x,k));

export function validateWorkerResult(value,identity){
  if(!value||typeof value!=='object'||Array.isArray(value)||value.format!=='pskernel-preview-worker-v1'||
    value.requestId!==identity.requestId||value.inputSha256!==identity.inputSha256||
    value.programSha256!==identity.programSha256||value.policySha256!==identity.policySha256||
    value.fuel!=='4096'||!outcomes.has(value.outcome)||typeof value.stage!=='string'||value.stage.length>128||
    !(value.reason===null||typeof value.reason==='string'&&value.reason.length<=4096)||
    typeof value.coreInvoked!=='boolean'||typeof value.metadataValidated!=='boolean'||
    typeof value.assumptionPolicyValidated!=='boolean'||!Array.isArray(value.assumptions)||value.assumptions.length>4)
    throw Error('invalid worker result identity or shape');
  const seen=new Set();
  for(const a of value.assumptions){
    if(!exactKeys(a,['name','universeParameters','standardSchema'])||typeof a.name!=='string'||
      a.name.length>4096||!count(a.universeParameters)||typeof a.standardSchema!=='boolean'||seen.has(a.name))
      throw Error('invalid assumption inventory');
    seen.add(a.name);
    if(a.standardSchema&&(!Object.hasOwn(identity.pins.schemas,a.name)||
      String(a.universeParameters)!==identity.pins.schemas[a.name].universeParameters))
      throw Error('assumption differs from pinned policy');
  }
  if(value.outcome==='accepted'&&(value.stage!=='complete'||value.reason!==null||
    !value.coreInvoked||!value.metadataValidated||!value.assumptionPolicyValidated||
    value.assumptions.some(a=>!a.standardSchema)||!count(value.admissionCommands)||
    !count(value.exportedDeclarations)||!digits(value.arenaNodes)))throw Error('acceptance omitted checking evidence');
  if(value.outcome!=='accepted'&&value.metadataValidated)throw Error('failed result claims complete validation');
  return value;
}

async function boundedInput(inputPath){
  const handle=await open(inputPath,constants.O_RDONLY|constants.O_NONBLOCK);
  try{
    if(!(await handle.stat()).isFile())throw Object.assign(Error('input must be a regular file'),{previewCause:'input-kind'});
    let bytes=0;const chunks=[];
    while(bytes<=LIMITS.inputLimitBytes){
      const chunk=Buffer.alloc(Math.min(65536,LIMITS.inputLimitBytes+1-bytes));
      const r=await handle.read(chunk,0,chunk.length,null);if(!r.bytesRead)break;
      chunks.push(chunk.subarray(0,r.bytesRead));bytes+=r.bytesRead;
    }
    if(bytes>LIMITS.inputLimitBytes)throw Object.assign(Error('input exceeds 64 MiB strict file profile'),{previewCause:'input-size'});
    return Buffer.concat(chunks,bytes);
  }finally{await handle.close();}
}

// Options are a trusted embedding API. The command line never accepts worker,
// program, policy or executable overrides from the checked input.
export async function supervise({inputPath,inputBytes,kernelPath=path.join(here,'kernel.js'),
  workerPath=path.join(here,'pskernel-preview-worker.mjs'),pinsPath=path.join(here,'pskernel-preview-axioms.json'),
  executable=process.execPath,timeoutMilliseconds=60000,signal,onProgress=()=>{}}={}){
  const start=performance.now(),requestId=randomUUID();let input,program,pinsBytes,pins;
  const resources={...LIMITS,wallDeadlineMilliseconds:timeoutMilliseconds};
  const result=(outcome,stage,reason,host,worker)=>({format:'pskernel-preview-v1',
    target:{contract:'KernelContract-v1',leanVersion:TARGET.version,leanCommit:TARGET.githash},
    requestId,input:input?{bytes:input.length,sha256:hash(input)}:null,
    program:program?{bytes:program.length,sha256:hash(program)}:null,
    assumptionPolicy:{id:'pinned-standard-axioms-v1',sha256:pinsBytes?hash(pinsBytes):null,
      validated:worker?.assumptionPolicyValidated??false},resources,outcome,stage,reason,
    assumptions:worker?.assumptions??[],checking:{coreInvoked:worker?.coreInvoked??false,
      metadataValidated:worker?.metadataValidated??false,...(worker?.outcome==='accepted'?{
        admissionCommands:worker.admissionCommands,exportedDeclarations:worker.exportedDeclarations,arenaNodes:worker.arenaNodes}:{})},
    host:{...host,wallMilliseconds:Math.round(performance.now()-start)},
    logicalSoundnessProved:false,strictArenaCompatibility:false});
  if(!Number.isSafeInteger(timeoutMilliseconds)||timeoutMilliseconds<1||timeoutMilliseconds>1500000)
    return result('internalError','configuration','deadline must be an integer from 1 to 1500000 ms',{cause:'configuration',workerReaped:false});
  try{
    input=inputBytes===undefined?await boundedInput(inputPath):Buffer.from(inputBytes);
    if(input.length>LIMITS.inputLimitBytes)throw Object.assign(Error('input exceeds 64 MiB strict file profile'),{previewCause:'input-size'});
    [program,pinsBytes]=await Promise.all([readFile(kernelPath),readFile(pinsPath)]);
    pins=JSON.parse(pinsBytes.toString('utf8'));
    if(pins.format!=='pskernel-preview-axioms-v1'||pins.leanVersion!==TARGET.version||pins.leanCommit!==TARGET.githash)
      throw Error('assumption policy target mismatch');
  }catch(error){
    const exhausted=error.previewCause==='input-size';
    return result(exhausted?'resourceExhausted':'internalError','input-or-identity',String(error.message).slice(0,4096),
      {cause:error.previewCause??'input-or-identity',workerReaped:false});
  }
  if(signal?.aborted)return result('resourceExhausted','supervisor','operation cancelled before launch',{cause:'cancelled',workerReaped:false});
  const identity={requestId,inputSha256:hash(input),programSha256:hash(program),policySha256:hash(pinsBytes),pins};
  return await new Promise(resolve=>{
    let child,forced=null,launchError=null,stdoutBytes=0,stderrBytes=0,stdout=[],stderr=[],timer,settled=false;
    let exited=false,code=null,exitSignal=null;
    const cleanup=()=>{clearTimeout(timer);signal?.removeEventListener('abort',cancel);};
    const killGroup=()=>{if(child?.pid){try{process.kill(-child.pid,'SIGKILL');}catch(error){if(error.code!=='ESRCH'){try{child.kill('SIGKILL');}catch{}}}}};
    const stop=cause=>{if(!forced){forced=cause;killGroup();}};
    const cancel=()=>stop('cancelled');
    const host=()=>({cause:forced??launchError,exitCode:code,signal:exitSignal,workerPid:child?.pid??null,
      workerReaped:exited,stdoutBytes,stderrBytes});
    const finish=()=>{
      if(settled)return;settled=true;cleanup();
      if(forced)return resolve(result('resourceExhausted','supervisor','worker stopped: '+forced,host()));
      if(launchError)return resolve(result('internalError','supervisor','worker launch or input pipe failed',host()));
      const err=Buffer.concat(stderr).toString('utf8');
      if(code!==0||exitSignal){
        const heap=/FATAL ERROR:.*(?:heap out of memory|allocation failed)/iu.test(err);
        return resolve(result(heap?'resourceExhausted':'internalError','supervisor',heap?'worker reported heap exhaustion':'worker did not terminate successfully',
          {...host(),cause:heap?'host-heap':exitSignal?'host-signal':'host-exit'}));
      }
      try{
        const text=new TextDecoder('utf-8',{fatal:true}).decode(Buffer.concat(stdout));
        const lines=text.trimEnd().split('\n');if(lines.length!==1||!lines[0])throw Error('missing or duplicate worker envelope');
        const numbers=value=>{
          if(typeof value==='bigint'){const n=Number(value);if(!Number.isSafeInteger(n))throw Error('inexact worker integer');return n;}
          if(Array.isArray(value))return value.map(numbers);
          if(value&&typeof value==='object')return Object.fromEntries(Object.entries(value).map(([k,v])=>[k,numbers(v)]));
          return value;
        };
        const value=validateWorkerResult(numbers(parseExactJSON(lines[0])),identity);
        resolve(result(value.outcome,value.stage,value.reason,host(),value));
      }catch(error){resolve(result('internalError','worker-protocol',String(error.message).slice(0,4096),{...host(),cause:'invalid-worker-envelope'}));}
    };
    try{child=spawn(executable,['--max-old-space-size=2048',path.resolve(workerPath),path.resolve(kernelPath),requestId,
      identity.inputSha256,identity.programSha256,identity.policySha256,path.resolve(pinsPath)],
      {detached:true,env:{PATH:'',LC_ALL:'C'},stdio:['pipe','pipe','pipe'],shell:false,windowsHide:true});}
    catch{launchError='launch';return finish();}
    child.on('error',()=>{launchError='launch';});
    child.stdin.on('error',error=>{if(error.code!=='EPIPE'){launchError='stdin';killGroup();}});
    child.stdout.on('data',b=>{stdoutBytes+=b.length;if(stdoutBytes>LIMITS.stdoutLimitBytes)stop('stdout-limit');else stdout.push(b);});
    let progressTail='';
    child.stderr.on('data',b=>{
      stderrBytes+=b.length;if(stderrBytes>LIMITS.stderrLimitBytes){stop('stderr-limit');return;}stderr.push(b);
      progressTail+=b.toString('utf8');const lines=progressTail.split('\n');progressTail=lines.pop();
      for(const line of lines){if(!line.startsWith('PSKERNEL_PREVIEW_PROGRESS '))continue;
        try{const v=JSON.parse(line.slice(26));if(typeof v.stage==='string'&&v.stage.length<=128&&typeof v.coreInvoked==='boolean'&&count(v.records))
          onProgress({stage:v.stage,coreInvoked:v.coreInvoked,records:v.records});}catch{}}
    });
    child.on('exit',(status,sig)=>{exited=true;code=status;exitSignal=sig;killGroup();});
    child.on('close',(status,sig)=>{code=status;exitSignal=sig;finish();});
    timer=setTimeout(()=>stop('wall-deadline'),timeoutMilliseconds);
    signal?.addEventListener('abort',cancel,{once:true});if(signal?.aborted)cancel();
    child.stdin.end(input);
  });
}

export const exitCodeFor=outcome=>({accepted:0,rejectedInvalid:1,declinedUnsupported:2,resourceExhausted:3,internalError:4})[outcome]??4;
