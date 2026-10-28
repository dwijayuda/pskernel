// Strict IR cycle fixture only. The independent source/Core admission evidence
// comes from the separate installed v3 workload, not this constructed IR test.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import assert from 'node:assert/strict';
import {run} from '../../host-tools/modular/compiler.mjs';
import {verifyPrintedGraph} from '../../host-tools/modular/graph.mjs';
const fixture=JSON.parse(fs.readFileSync('dist/modular/partition-fixture.json','utf8'));
const temporary=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-partition-cycle-'));
const tsc=path.resolve('../node_modules/typescript/bin/tsc');
try{
 const observations=[];
 for(const variant of ['js','ts']){
  const cwd=path.join(temporary,variant);fs.mkdirSync(cwd);
  const paths={},output=[];
  for(const [index,name]of fixture.packages.entries()){
   const root=path.join(cwd,'node_modules',name);fs.mkdirSync(root,{recursive:true});
   fs.writeFileSync(path.join(root,'package.json'),JSON.stringify({name,type:'module',
     exports:{'.':'./index.mjs','./ts':'./index.mjs'}}));
   if(variant==='js')fs.writeFileSync(path.join(root,'index.mjs'),fixture.js[index].source);
   else{
    fs.writeFileSync(path.join(root,'source.mts'),fixture.ts[index].source);
    const config=path.join(cwd,'unit-'+index+'.json');
    fs.writeFileSync(config,JSON.stringify({compilerOptions:{strict:true,noEmitOnError:true,verbatimModuleSyntax:true,
      target:'ES2022',module:'NodeNext',moduleResolution:'NodeNext',declaration:true,types:[],lib:['ES2022','DOM'],
      rootDir:root,outDir:path.join(root,'compiled'),paths},files:[path.join(root,'source.mts')]}));
    run(process.execPath,[tsc,'--project',config]);
    fs.copyFileSync(path.join(root,'compiled/source.mjs'),path.join(root,'index.mjs'));
    fs.copyFileSync(path.join(root,'compiled/source.d.mts'),path.join(root,'index.d.mts'));
    paths[name+'/ts']=[path.join(root,'index.d.mts')];
   }
   output.push(fs.readFileSync(path.join(root,'index.mjs'),'utf8'));
  }
  verifyPrintedGraph(fixture,variant,output);
  const reference=path.join(cwd,'reference.mjs');
  if(variant==='js')fs.writeFileSync(reference,fixture.referenceJs);
  else{
   fs.writeFileSync(path.join(cwd,'reference.mts'),fixture.referenceTs);
   const config=path.join(cwd,'ref.json');fs.writeFileSync(config,JSON.stringify({compilerOptions:{strict:true,
    noEmitOnError:true,target:'ES2022',module:'NodeNext',moduleResolution:'NodeNext',types:[],lib:['ES2022','DOM'],
    rootDir:cwd,outDir:path.join(cwd,'ref')},files:[path.join(cwd,'reference.mts')]}));
   run(process.execPath,[tsc,'--project',config]);fs.copyFileSync(path.join(cwd,'ref/reference.mjs'),reference);
  }
  const consumer=fixture.packages[fixture.sourceToUnit[3]];
  fs.writeFileSync(path.join(cwd,'observe.mjs'),[
   "import assert from 'node:assert/strict';",
   "const reference=process.argv[2]==='reference';",
   "const c=reference?await import('./reference.mjs'):await import("+JSON.stringify(consumer+(variant==='ts'?'/ts':''))+");",
   "const actual=[0n,1n,2n,6000n,6001n].map(n=>String(c.partitionConsumer(n)));",
   "assert.deepEqual(actual,['17','42','17','17','42']);",
   "console.log(JSON.stringify(actual));"
  ].join('\n'));
  const expected=JSON.parse(run(process.execPath,['observe.mjs','reference'],{cwd}));
  for(const runtime of [process.execPath,'bun']){
   const actual=JSON.parse(run(runtime,['observe.mjs','installed'],{cwd}));
   assert.deepEqual(actual,expected);observations.push({variant,runtime:runtime==='bun'?'bun':'node',actual});
  }
 }
 const result={schema:'psc1-partition-cycle-execution/1',status:'passed',scope:fixture.scope,
  groups:fixture.groups,sourceToUnit:fixture.sourceToUnit,observations};
 fs.writeFileSync('dist/modular/partition-cycle-execution.json',JSON.stringify(result,null,2)+'\n');
 console.log('PSC1_PARTITION_CYCLE_EXECUTED '+JSON.stringify(result));
}finally{fs.rmSync(temporary,{recursive:true,force:true});}
