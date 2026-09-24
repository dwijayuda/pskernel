import {
  PROOFSCRIPT_LEAN_VERSION,
  replayLeanEnvironment,
} from '../src/index.js';
import {
  createLeanEnvironmentProvider,
  requireLeanEnvironment,
} from '../src/node.js';
import {LEAN434_PINNED_GITHASH} from 'lean-ts-kernel/lean4export';

function equal(actual:unknown,expected:unknown):void {
  if(actual!==expected){
    throw new Error('expected '+String(expected)+', got '+String(actual));
  }
}

{
  const replayed=replayLeanEnvironment(
    JSON.stringify({
      meta:{
        lean:{version:PROOFSCRIPT_LEAN_VERSION,githash:LEAN434_PINNED_GITHASH},
        format:{version:'3.1.0'},
      },
    })+'\n',
  );
  equal(replayed.environment.size,0);
  equal(replayed.stats.declarations,0);
}
{
  const provider=createLeanEnvironmentProvider({
    candidatePaths:['/definitely/missing/proofscript-prelude.ndjson'],
  });
  equal(provider.status().loaded,false);
  let failed=false;
  try{requireLeanEnvironment(provider);}
  catch(error){
    failed=/PS_ENV_INIT_PRELUDE_REQUIRED/.test(String(error));
  }
  equal(failed,true);
}
console.log('ok - @proofscript/environment replay and fail-closed provider');
