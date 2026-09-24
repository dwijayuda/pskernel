import fs from 'node:fs';
import {spawn} from 'node:child_process';
import {createInterface} from 'node:readline';
import {createHash} from 'node:crypto';
import {resolve} from 'node:path';
import {Lean4ExportReplay} from '../dist/src/integration/lean4export.js';

const args=process.argv.slice(2);
const fileArg=args.find(a=>!a.startsWith('--'));
const binIdx=args.indexOf('--con-leche-bin');
const conLecheBin=binIdx>=0?args[binIdx+1]:(process.env.CONLECHE_BIN||'con-leche');
const jobsIdx=args.indexOf('--jobs');
const jobs=jobsIdx>=0?args[jobsIdx+1]:(process.env.CONLECHE_JOBS||'1');
if(!fileArg)throw new Error('usage: formal-cosign <file.ndjson> [--con-leche-bin PATH] [--jobs N]');
const file=resolve(fileArg);
if(!fs.existsSync(file))throw new Error('formal-cosign: file not found: '+file);
const formalLock=JSON.parse(fs.readFileSync('FORMAL_LOCK.json','utf8'));
const inputSha256=createHash('sha256').update(fs.readFileSync(file)).digest('hex');

async function pskernelAccept(path){
  const replay=new Lean4ExportReplay();
  const rl=createInterface({input:fs.createReadStream(path),crlfDelay:Infinity});
  try{
    for await(const line of rl)replay.replayLine(line);
    const stats=replay.finish();
    return {ok:true,constants:replay.env.size,stats};
  }catch(e){
    return {ok:false,error:e instanceof Error?(e.stack??e.message):String(e)};
  }
}

async function runConLeche(path){
  return await new Promise((resolveRun,reject)=>{
    const p=spawn(conLecheBin,['--verified',`--jobs=${jobs}`,path],{stdio:['ignore','pipe','pipe']});
    let stdout='',stderr='';
    p.stdout.setEncoding('utf8');p.stderr.setEncoding('utf8');
    p.stdout.on('data',d=>stdout+=d);p.stderr.on('data',d=>stderr+=d);
    p.on('error',reject);
    p.on('close',(code,signal)=>resolveRun({code,signal,stdout:stdout.trim(),stderr:stderr.trim()}));
  });
}

const ps=await pskernelAccept(file);
if(!ps.ok){
  console.log(JSON.stringify({certified:false,pskernel:'reject',conLeche:'not-run',file,inputSha256,error:ps.error},null,2));
  process.exit(1);
}
let cl;
try{cl=await runConLeche(file);}
catch(e){
  console.log(JSON.stringify({certified:false,pskernel:'accept',conLeche:'unavailable',file,inputSha256,error:e instanceof Error?e.message:String(e)},null,2));
  process.exit(3);
}
const verdict=cl.code===0?'accept':cl.code===2?'decline':cl.code===1?'reject':'error';
const certified=verdict==='accept';
console.log(JSON.stringify({
  certified,
  assurance:'formal-soundness-cosign-v1',
  file,
  inputSha256,
  formalChecker:{
    repository:formalLock.checker.repository,
    commit:formalLock.checker.commit,
    mode:formalLock.checker.mode,
    theorem:formalLock.checker.theorem,
    toolchain:formalLock.checker.toolchain
  },
  transport:formalLock.transport,
  pskernel:{verdict:'accept',constants:ps.constants,stats:ps.stats},
  conLeche:{verdict,exitCode:cl.code,signal:cl.signal,stdout:cl.stdout,stderr:cl.stderr},
  formalClaim:certified
    ? "Both pskernel and pinned ConLeche --verified accepted this exact export stream. The formal soundness claim is ConLeche's acceptance theorem/model guarantee, not an equivalence proof about pskernel."
    : null
},null,2));
process.exit(certified?0:verdict==='decline'?2:1);
