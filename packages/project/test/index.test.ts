import {
  BuildCache,
  createBuildPlan,
  createSourceBuildPlan,
  sourceDependencyClosure,
} from '../src/index.js';

function equal(a:unknown,b:unknown):void{
  if(a!==b)throw new Error(
    `expected ${String(b)}, got ${String(a)}`,
  );
}
function throws(f:()=>unknown,pattern:RegExp):void{
  try{
    f();
  }catch(error){
    if(pattern.test(String(error)))return;
    throw error;
  }
  throw new Error('expected function to throw '+String(pattern));
}

equal(
  createBuildPlan([
    {name:'app',dependencies:['core']},
    {name:'core',dependencies:[]},
  ]).order.join(','),
  'core,app',
);

let cycle=false;
try{
  createBuildPlan([
    {name:'a',dependencies:['b']},
    {name:'b',dependencies:['a']},
  ]);
}catch{
  cycle=true;
}
equal(cycle,true);

const mixed=createSourceBuildPlan([
  {
    module:'App',
    sourcePath:'src/App.ps',
    sourceKind:'proofscript',
    imports:['Data'],
  },
  {
    module:'Data',
    sourcePath:'src/Data.lean',
    sourceKind:'lean-subset',
    imports:[],
  },
]);
equal(mixed.order.join(','),'Data,App');
equal(mixed.modules.get('App')?.sourceKind,'proofscript');
equal(mixed.modules.get('Data')?.sourceKind,'lean-subset');
equal(
  sourceDependencyClosure(mixed,'App').join(','),
  'Data',
);
equal(
  sourceDependencyClosure(mixed,'Data').join(','),
  '',
);

throws(
  ()=>createSourceBuildPlan([
    {
      module:'Data',
      sourcePath:'src/Data.ps',
      sourceKind:'proofscript',
      imports:[],
    },
    {
      module:'Data',
      sourcePath:'src/Data.lean',
      sourceKind:'lean-subset',
      imports:[],
    },
  ]),
  /PS_PROJECT_SOURCE_AMBIGUITY/,
);

throws(
  ()=>createSourceBuildPlan([
    {
      module:'App',
      sourcePath:'src/App.ps',
      sourceKind:'proofscript',
      imports:['Missing'],
    },
  ]),
  /missing dependency 'Missing'/,
);

const cache=new BuildCache<number>();
cache.set('x',1);
equal(cache.get('x'),1);

console.log('ok - @proofscript/project mixed-source graph foundation');

import {
  mkdtempSync,
  mkdirSync,
  rmSync,
  writeFileSync,
} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {
  nodeProjectResolutionForEntry,
  projectSourceRootsFromConfig,
  resolveLogicalModuleSource,
} from '../src/node.js';

{
  const root=mkdtempSync(join(tmpdir(),'proofscript-project-'));
  try{
    mkdirSync(join(root,'src'),{recursive:true});
    writeFileSync(
      join(root,'psconfig.json'),
      JSON.stringify({sourceRoots:['src']}),
    );
    writeFileSync(join(root,'src','Core.lean'),'theorem core : Prop := by exact True.intro\n');
    const entry=join(root,'src','Main.ps');
    writeFileSync(entry,'import Core;');
    const resolution=nodeProjectResolutionForEntry(entry);
    equal(resolution.sourceRoots.length,1);
    equal(
      resolveLogicalModuleSource(resolution.sourceRoots,'Core'),
      join(root,'src','Core.lean'),
    );
    equal(projectSourceRootsFromConfig(['src','src']).length,1);
  }finally{
    rmSync(root,{recursive:true,force:true});
  }
}
console.log('ok - @proofscript/project shared Node source-root resolver');
