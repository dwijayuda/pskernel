import fs from 'node:fs';

const file=process.argv[2];
if(!file)throw new Error(
  'usage: node scripts/lean434-runtime-metadata-report.mjs <metadata.json>',
);
const doc=JSON.parse(fs.readFileSync(file,'utf8'));
if(doc?.format!=='proofscript-lean434-runtime-metadata'){
  throw new Error('not a ProofScript Lean runtime metadata document');
}

function groupCount(items,key){
  const out=new Map();
  for(const item of items){
    const value=String(item?.[key]??'');
    out.set(value,(out.get(value)??0)+1);
  }
  return [...out.entries()]
    .sort((a,b)=>b[1]-a[1]||a[0].localeCompare(b[0]));
}

const exactExterns=doc.externs.filter(x=>x.module===doc.module);
const exactImplementedBy=doc.implementedBy.filter(x=>x.module===doc.module);
const exactInitializers=doc.initializers.filter(x=>x.module===doc.module);

const parserExterns=doc.externs.filter(
  x=>typeof x.module==='string'&&x.module.startsWith('Lean.Parser'),
);
const parserImplementedBy=doc.implementedBy.filter(
  x=>typeof x.module==='string'&&x.module.startsWith('Lean.Parser'),
);
const parserInitializers=doc.initializers.filter(
  x=>typeof x.module==='string'&&x.module.startsWith('Lean.Parser'),
);

const result={
  module:doc.module,
  totals:{
    externs:doc.externs.length,
    implementedBy:doc.implementedBy.length,
    initializers:doc.initializers.length,
  },
  exactTargetModule:{
    externs:exactExterns.length,
    implementedBy:exactImplementedBy.length,
    initializers:exactInitializers.length,
  },
  directLeanParser:{
    externs:parserExterns.length,
    implementedBy:parserImplementedBy.length,
    initializers:parserInitializers.length,
  },
  topExternModules:groupCount(doc.externs,'module').slice(0,20),
  topImplementedByModules:groupCount(doc.implementedBy,'module').slice(0,20),
  topInitializerModules:groupCount(doc.initializers,'module').slice(0,20),
  exactTargetExternSample:exactExterns.slice(0,40),
  exactTargetImplementedBySample:exactImplementedBy.slice(0,40),
  exactTargetInitializerSample:exactInitializers.slice(0,80),
  parserExternSample:parserExterns.slice(0,40).map(x=>({
    declaration:x.declaration,
    module:x.module,
    entries:x.entries,
  })),
  parserImplementedBySample:parserImplementedBy.slice(0,40),
  parserInitializerSample:parserInitializers.slice(0,60),
};
process.stdout.write(JSON.stringify(result,null,2)+'\n');
