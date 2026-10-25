import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {spawnSync} from 'node:child_process';import {createIndependentKernelToolchain,loadKernelDistribution} from '../host-tools/kernel-toolchain.mjs';
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
export async function kernelMain(args,root){
 let provider='wasm',assurance,command,input;for(let i=0;i<args.length;i++){const a=args[i];if(a==='--assurance'){assurance=args[++i];if(!['checked','ordinary','verified'].includes(assurance))throw Error('PSC1_KERNEL_ASSURANCE');}else if(a==='--provider'){provider=args[++i];if(!['native','wasm','both'].includes(provider))throw Error('PSC1_KERNEL_PROVIDER');}else if(!command&&['--identity','check','check-source'].includes(a))command=a;else if(!input&&!a.startsWith('--'))input=a;else throw Error('PSC1_KERNEL_USAGE: kernel --identity | check admissions.json | check-source input.lean|ps [--provider native|wasm|both]');}
 if(!command||(command==='--identity'&&input)||(command!=='--identity'&&!input))throw Error('PSC1_KERNEL_USAGE');
 if(assurance&&command!=='check-source')throw Error('PSC1_KERNEL_ASSURANCE_REQUIRES_SOURCE');
 const toolchain=await createIndependentKernelToolchain({root,provider});if(command==='--identity'){console.log(JSON.stringify(toolchain.metadata));return;}
 let source;
 if(command==='check'){
  const st=fs.lstatSync(input);if(!st.isFile()||st.isSymbolicLink()||st.size>128*1024*1024)throw Error('PSC1_KERNEL_INPUT_KIND_SIZE');
  source=new TextDecoder('utf-8',{fatal:true}).decode(fs.readFileSync(input));
 }else{
  // The existing compiler captures/elaborates and emits canonical admissions once.
  // This command checks that graph; it does not publish a separately reread build.
  if(!/\.(lean|ps)$/.test(input))throw Error('PSC1_KERNEL_SOURCE_EXTENSION');
  const d=loadKernelDistribution(root),n=d.nativeCompiler;if(!n||!/^[0-9a-f]{64}$/.test(n.sha256||'')||typeof n.path!=='string')throw Error('PSC1_KERNEL_NATIVE_COMPILER_MISSING');
  const binary=path.resolve(root,n.path),rel=path.relative(root,binary);if(!rel||rel.startsWith('..')||path.isAbsolute(rel))throw Error('PSC1_KERNEL_NATIVE_COMPILER_PATH');
  const st=fs.lstatSync(binary);if(!st.isFile()||st.isSymbolicLink()||sha(fs.readFileSync(binary))!==n.sha256)throw Error('PSC1_KERNEL_NATIVE_COMPILER_CHECKSUM');
  const env={...process.env,PSC1_LIBRARY_RESOLVER:path.join(root,'npm-cli/libraries.mjs'),LD_LIBRARY_PATH:[path.join(root,'native/lib'),process.env.LD_LIBRARY_PATH].filter(Boolean).join(path.delimiter)};
  const r=spawnSync(binary,['admissions',path.resolve(input),...(assurance?['--assurance',assurance]:[])],{cwd:process.cwd(),env,encoding:'utf8',timeout:240000,maxBuffer:128*1024*1024,killSignal:'SIGKILL',windowsHide:true});
  if(r.error||r.status!==0)throw Error('PSC1_KERNEL_SOURCE_REFUSED: '+(r.error?.message||r.stderr));
  if(sha(fs.readFileSync(binary))!==n.sha256)throw Error('PSC1_KERNEL_NATIVE_COMPILER_CHANGED');
  source=r.stdout;const parsed=JSON.parse(source);if(parsed.format!=='proofscript-checked-admissions'||parsed.version!==2)throw Error('PSC1_KERNEL_SOURCE_ADMISSIONS_FORMAT');
 }
 const result=await toolchain.checkCanonicalAdmissions(source);console.log(JSON.stringify(result));if(!result.accepted)process.exitCode=1;
}
