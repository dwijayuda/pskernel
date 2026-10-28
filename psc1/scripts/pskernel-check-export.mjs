import {supervise,exitCodeFor} from './pskernel-preview-supervisor.mjs';

const args=process.argv.slice(2);let inputPath,timeoutMilliseconds=60000,progress=false,error=null;
for(let i=0;i<args.length;i++){
  if(args[i]==='--timeout-ms'){
    const n=args[++i];if(!n||!/^[1-9][0-9]*$/u.test(n))error='invalid --timeout-ms';else timeoutMilliseconds=Number(n);
  }else if(args[i]==='--progress')progress=true;
  else if(args[i].startsWith('--'))error='unknown option '+args[i];
  else if(inputPath)error='exactly one input file is required';else inputPath=args[i];
}
if(!inputPath)error='usage: node check-export.mjs [--timeout-ms 1..1500000] [--progress] input.ndjson';
const controller=new AbortController();
const cancel=()=>controller.abort();process.on('SIGINT',cancel);process.on('SIGTERM',cancel);
let result;
if(error){result=await supervise({timeoutMilliseconds:0});Object.assign(result,{stage:'arguments',reason:error});}
else if(process.platform!=='linux'||Number(process.versions.node.split('.')[0])!==22){
  result=await supervise({timeoutMilliseconds:0});Object.assign(result,{outcome:'declinedUnsupported',stage:'host-profile',reason:'qualified host profile requires Linux and Node 22'});
}else result=await supervise({inputPath,timeoutMilliseconds,signal:controller.signal,
  onProgress:progress?v=>process.stderr.write('PSKERNEL_PREVIEW_PROGRESS '+JSON.stringify(v)+'\n'):undefined});
process.removeListener('SIGINT',cancel);process.removeListener('SIGTERM',cancel);
process.stdout.write(JSON.stringify(result)+'\n');process.exitCode=exitCodeFor(result.outcome);
