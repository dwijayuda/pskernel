// A real file descriptor, not Node's nonblocking spawnSync input pipe, is
// required by Emscripten's synchronous readToEnd adapter. An EAGAIN or a
// crashed process is NEVER a proof rejection or a successful admission.
import {spawnSync} from 'node:child_process';
import {mkdtempSync,writeFileSync,openSync,closeSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import path from 'node:path';

export function runJsonProvider(executable,args,input,timeoutMs=180000){
  if(typeof executable!=='string'||!executable||
     !Array.isArray(args)||args.some(a=>typeof a!=='string'))
    throw new TypeError('invalid provider command');
  if(input!==undefined&&typeof input!=='string')
    throw new TypeError('provider input must be a string');
  if(!Number.isSafeInteger(timeoutMs)||timeoutMs<=0)
    throw new TypeError('invalid timeout');
  let directory;
  let fd;
  try{
    if(input!==undefined){
      directory=mkdtempSync(path.join(tmpdir(),'psc0-wasm-parity-'));
      const sourceFile=path.join(directory,'admissions.json');
      writeFileSync(sourceFile,input,{encoding:'utf8',mode:0o600});
      fd=openSync(sourceFile,'r');
    }
    const result=spawnSync(executable,args,{
      stdio:[fd??'ignore','pipe','pipe'],
      encoding:'utf8',maxBuffer:32*1024*1024,
      timeout:timeoutMs,killSignal:'SIGKILL',windowsHide:true,
    });
    if(result.error||result.status!==0||result.signal){
      const detail=result.error?.message ??
        result.stderr?.trim().slice(0,400) ?? String(result.signal??result.status);
      throw new Error('provider transport failure: '+detail);
    }
    let value;
    try{value=JSON.parse(result.stdout.trim());}
    catch{throw new Error('provider transport returned malformed JSON');}
    if(!value||typeof value!=='object'||Array.isArray(value))
      throw new Error('provider response must be a JSON object');
    return value;
  }finally{
    if(fd!==undefined)closeSync(fd);
    if(directory!==undefined)rmSync(directory,{recursive:true,force:true});
  }
}
