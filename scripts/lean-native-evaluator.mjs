import {spawnSync} from 'node:child_process';
import {nameToString} from '../dist/src/core/name.js';

export function createLeanNativeEvaluator({lean,moduleName,cwd=process.cwd(),env=process.env,runner=spawnSync,timeoutMs=Number(env.PSKERNEL_NATIVE_TIMEOUT_MS??'60000')}){
  if(typeof lean!=='string'||lean.length===0)throw new Error('native oracle: lean executable is required');
  if(typeof moduleName!=='string'||moduleName.length===0)throw new Error('native oracle: module name is required');
  if(!Number.isSafeInteger(timeoutMs)||timeoutMs<1000)throw new Error(`native oracle: invalid timeoutMs ${timeoutMs}`);
  const cache=new Map();
  return {
    evaluate(_kernelEnv,request){
      const constant=nameToString(request.constant);
      const key=`${request.kind}:${constant}`;
      const cached=cache.get(key);
      if(cached!==undefined)return cached;
      const startedAt=Date.now();
      if(env.PSKERNEL_NATIVE_DIAG==='1')console.error(`[native-diag] MISS ${key}`);
      const r=runner(
        lean,
        ['--run','oracle/replay-probe/NativeEval.lean',moduleName,request.kind,constant],
        {cwd,env,encoding:'utf8',maxBuffer:16*1024*1024,timeout:timeoutMs,killSignal:'SIGKILL'},
      );
      if(r.error)throw new Error(`native oracle execution failed for ${key}: ${r.error.message}`,{cause:r.error});
      if(r.status!==0||r.signal){
        throw new Error(
          `native oracle failed for ${key}: code=${r.status} signal=${r.signal??'none'}\n${r.stderr??''}`,
        );
      }
      let payload;
      try{payload=JSON.parse((r.stdout??'').trim());}
      catch(e){throw new Error(`native oracle returned invalid JSON for ${key}: ${r.stdout??''}`,{cause:e});}
      let result;
      if(request.kind==='nat'){
        if(payload?.kind!=='nat'||typeof payload.value!=='string'||!/^[0-9]+$/.test(payload.value)){
          throw new Error(`native oracle returned invalid Nat payload for ${key}`);
        }
        result={kind:'nat',value:BigInt(payload.value)};
      }else{
        if(payload?.kind!=='bool'||typeof payload.value!=='boolean'){
          throw new Error(`native oracle returned invalid Bool payload for ${key}`);
        }
        result={kind:'bool',value:payload.value};
      }
      cache.set(key,result);
      if(env.PSKERNEL_NATIVE_DIAG==='1')console.error(`[native-diag] DONE ${key} ms=${Date.now()-startedAt}`);
      return result;
    },
  };
}
