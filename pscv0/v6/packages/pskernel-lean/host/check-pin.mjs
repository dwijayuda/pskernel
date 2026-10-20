import {readFileSync} from 'node:fs';
import {spawnSync} from 'node:child_process';

const pin=JSON.parse(
  readFileSync(new URL('../LEAN_SOURCE_PIN.json',import.meta.url),'utf8'),
);
const leanExecutable=process.platform==='win32'?'lean.exe':'lean';

function runLean(args,label){
  const run=spawnSync(leanExecutable,args,{
    encoding:'utf8',
    windowsHide:true,
  });
  if(run.error){
    throw new Error(`failed to start Lean for ${label}: ${run.error.message}`,{
      cause:run.error,
    });
  }
  if(run.status!==0){
    throw new Error(
      `Lean ${label} exited ${run.status}: ${(run.stderr??'').trim()}`,
    );
  }
  return (run.stdout??'').trim();
}

const versionText=runLean(['--version'],'version check');
if(!versionText.includes(`version ${pin.version}`)){
  throw new Error(
    `Lean provider version drift: expected ${pin.version}, got ${versionText}`,
  );
}

const gitHash=runLean(['--githash'],'githash check');
if(gitHash!==pin.commit){
  throw new Error(
    `Lean provider commit drift: expected ${pin.commit}, got ${gitHash}`,
  );
}

if(pin.toolchain!=='leanprover/lean4:v4.34.0'){
  throw new Error(`unexpected provider toolchain pin: ${pin.toolchain}`);
}
if(pin.providerProtocol!=='pskernel-lean/1'){
  throw new Error(`unexpected provider protocol pin: ${pin.providerProtocol}`);
}
if(pin.providerProfile!=='lean4.34-core'){
  throw new Error(`unexpected provider profile pin: ${pin.providerProfile}`);
}

console.log(
  `PSC2_LEAN_KERNEL_PIN: PASS ${pin.version} ${pin.commit}`,
);
