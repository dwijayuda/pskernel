// Trusted checker bridge. Generated request JSON cannot select this provider.
import {checkInstalledAdmissions} from '../host-tools/installed-engine-resolver.mjs';
export async function runChecker(provider){
 try{
  const chunks=[];let bytes=0;for await(const chunk of process.stdin){bytes+=chunk.length;if(bytes>128*1024*1024)throw Error('PSC1_ADMISSION_INPUT_LIMIT');chunks.push(chunk);}
  const source=new TextDecoder('utf-8',{fatal:true}).decode(Buffer.concat(chunks)),result=await checkInstalledAdmissions(source,provider),selected=provider==='native'?'native':'wasm';
  console.log(JSON.stringify({...result.results[selected],accepted:result.accepted,...(!result.agreement?{errorKind:'provider-disagreement'}:{})}));
 }catch(error){console.error(String(error?.message||error));process.exitCode=1;}
}
