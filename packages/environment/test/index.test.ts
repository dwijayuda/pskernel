import {
  PROOFSCRIPT_LEAN_VERSION,
  replayLeanEnvironment,
  replayLeanEnvironmentInto,
} from '../src/index.js';
import {
  createLeanEnvironmentProvider,
  requireLeanEnvironment,
} from '../src/node.js';
import {nameFromDotted} from 'lean-ts-kernel';
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
        lean:{
          version:PROOFSCRIPT_LEAN_VERSION,
          githash:LEAN434_PINNED_GITHASH,
        },
        format:{version:'3.1.0'},
      },
    })+'\n',
  );
  equal(replayed.environment.size,0);
  equal(replayed.stats.declarations,0);
}
{
  const meta=JSON.stringify({
    meta:{
      lean:{
          version:PROOFSCRIPT_LEAN_VERSION,
          githash:LEAN434_PINNED_GITHASH,
        },
      format:{version:'3.1.0'},
    },
  });
  const segmented=[
    JSON.stringify({environment:{module:'Fixture'}}),
    JSON.stringify({segment:{index:0}}),
    meta,
    JSON.stringify({in:1,str:{pre:0,str:'A'}}),
    JSON.stringify({il:1,succ:0}),
    JSON.stringify({ie:0,sort:1}),
    JSON.stringify({
      axiom:{
        name:1,
        levelParams:[],
        type:0,
        isUnsafe:false,
      },
    }),
    JSON.stringify({segment:{index:1}}),
    meta,
    JSON.stringify({in:1,str:{pre:0,str:'A'}}),
    JSON.stringify({in:2,str:{pre:0,str:'B'}}),
    JSON.stringify({ie:0,const:{name:1,us:[]}}),
    JSON.stringify({
      axiom:{
        name:2,
        levelParams:[],
        type:0,
        isUnsafe:false,
      },
    }),
  ].join('\n')+'\n';
  const replayed=replayLeanEnvironment(segmented);
  equal(replayed.environment.size,2);
  equal(replayed.stats.declarations,2);
}
{
  const meta=JSON.stringify({
    meta:{
      lean:{
        version:PROOFSCRIPT_LEAN_VERSION,
        githash:LEAN434_PINNED_GITHASH,
      },
      format:{version:'3.1.0'},
    },
  });
  const base=replayLeanEnvironment([
    meta,
    JSON.stringify({in:1,str:{pre:0,str:'Base'}}),
    JSON.stringify({il:1,succ:0}),
    JSON.stringify({ie:0,sort:1}),
    JSON.stringify({
      axiom:{
        name:1,
        levelParams:[],
        type:0,
        isUnsafe:false,
      },
    }),
  ].join('\n')+'\n');
  const delta=[
    JSON.stringify({environment:{
      module:'Fixture',
      baseModule:'BaseFixture',
    }}),
    JSON.stringify({segment:{index:0,kind:'declaration'}}),
    meta,
    JSON.stringify({in:1,str:{pre:0,str:'Base'}}),
    JSON.stringify({in:2,str:{pre:0,str:'Delta'}}),
    JSON.stringify({ie:0,const:{name:1,us:[]}}),
    JSON.stringify({
      axiom:{
        name:2,
        levelParams:[],
        type:0,
        isUnsafe:false,
      },
    }),
  ].join('\n')+'\n';
  const replayed=replayLeanEnvironmentInto(base.environment,delta);
  equal(replayed.environment.size,2);
  equal(replayed.stats.declarations,1);
}
{
  const provider=createLeanEnvironmentProvider();
  const status=provider.status();
  equal(status.loaded,true);
  equal(
    status.foundationSource?.endsWith(
      'lean434-proofscript-selfhost-foundation.ndjson',
    ),
    true,
  );
  const environment=requireLeanEnvironment(provider);
  equal(
    environment.find(nameFromDotted('String.Internal.length'))!==undefined,
    true,
  );
  equal(environment.find(nameFromDotted('Char.toNat'))!==undefined,true);
  equal(environment.find(nameFromDotted('Array.set'))!==undefined,true);
  equal(
    environment.find(nameFromDotted('Array.setIfInBounds'))!==undefined,
    true,
  );
  equal(environment.find(nameFromDotted('Array.map'))!==undefined,true);
  equal(environment.find(nameFromDotted('Array.foldl'))!==undefined,true);
}
console.log('ok - @proofscript/environment certified self-host compiler base');

{
  const provider=createLeanEnvironmentProvider({
    candidatePaths:['/definitely/missing/proofscript-foundation.ndjson'],
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
