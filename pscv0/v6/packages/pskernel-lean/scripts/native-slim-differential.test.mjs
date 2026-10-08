import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';

function parseArgs(argv){
  const out={};
  for(let i=0;i<argv.length;i+=2){
    const key=argv[i];
    const value=argv[i+1];
    if(!key?.startsWith('--')||value===undefined){
      throw new Error(`invalid argument sequence near ${String(key)}`);
    }
    out[key.slice(2)]=value;
  }
  return out;
}
const args=parseArgs(process.argv.slice(2));
if(!args.reference||!args.candidate){
  throw new Error('expected --reference and --candidate');
}

function run(binary,command,input){
  const result=spawnSync(binary,[command],{
    input,
    encoding:'utf8',
    windowsHide:true,
    maxBuffer:16*1024*1024,
  });
  assert.equal(
    result.status,
    0,
    `${binary} ${command} failed\nstdout:\n${result.stdout??''}\nstderr:\n${result.stderr??''}`,
  );
  return JSON.parse((result.stdout??'').trim());
}

const accepted=JSON.stringify({
  protocol:'pskernel-lean/1',
  format:'proofscript-checked-admissions',
  version:2,
  admissions:[{kind:'constant',declaration:{
    h:{h:'1',k:'regular'},k:'definition',lp:[],
    n:{k:'s',p:{k:'a'},v:'SlimDifferential.True'},s:'safe',
    t:{k:'const',ls:[],n:{k:'s',p:{k:'a'},v:'Nat'}},
    v:{k:'nat',v:'1'},
  }}],
});
const rejected=JSON.stringify({
  protocol:'pskernel-lean/1',
  format:'proofscript-checked-admissions',
  version:2,
  admissions:[{kind:'constant',declaration:{
    h:{h:'1',k:'regular'},k:'definition',lp:[],
    n:{k:'s',p:{k:'a'},v:'SlimDifferential.Bad'},s:'safe',
    t:{k:'const',ls:[],n:{k:'s',p:{k:'a'},v:'Nat'}},
    v:{k:'sort',l:{k:'z'}},
  }}],
});

for(const fixture of [
  {command:'--health',input:undefined,name:'health'},
  {command:'--check',input:accepted,name:'accepted'},
  {command:'--check',input:rejected,name:'kernel-rejection'},
  {command:'--check',input:'{',name:'malformed'},
]){
  const reference=run(args.reference,fixture.command,fixture.input);
  const candidate=run(args.candidate,fixture.command,fixture.input);
  assert.deepEqual(candidate,reference,`${fixture.name}: slim provider must exactly match Lake reference`);
}
console.log('PSC2_LEAN_KERNEL_NATIVE_SLIM_DIFFERENTIAL: PASS');
