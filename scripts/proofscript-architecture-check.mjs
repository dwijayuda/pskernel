import {
  existsSync,
  readFileSync,
  readdirSync,
  statSync,
} from 'node:fs';
import {join} from 'node:path';
import {fileURLToPath} from 'node:url';

const root=fileURLToPath(new URL('..',import.meta.url));
const map=JSON.parse(
  readFileSync(join(root,'packages','package-map.json'),'utf8'),
);
const byName=new Map(map.packages.map((pkg)=>[pkg.name,pkg]));

function entry(name){
  const value=byName.get(name);
  if(value===undefined)throw new Error('architecture: missing '+name);
  return value;
}
function requireDeps(name,required){
  const deps=new Set(entry(name).dependsOn);
  for(const dep of required){
    if(!deps.has(dep)){
      throw new Error('architecture: '+name+' must depend on '+dep);
    }
  }
}
function forbidDeps(name,forbidden){
  const deps=new Set(entry(name).dependsOn);
  for(const dep of forbidden){
    if(deps.has(dep)){
      throw new Error(
        'architecture: '+name+' must not depend on '+dep,
      );
    }
  }
}

if(entry('kernel').dependsOn.length!==0){
  throw new Error('architecture: kernel must remain dependency root');
}
requireDeps('environment',['kernel']);
requireDeps('cli',['environment','project','checked-core']);
requireDeps('lsp',['environment','project']);
requireDeps('language-service',['checked-core','project']);
requireDeps('checked-core',['kernel']);
requireDeps('elab',['tactic']);
forbidDeps('tactic',['elab']);
forbidDeps('checked-core',[
  'syntax','meta','elab','language','erasure','compiler-ir','backend-ts',
  'wasm-ir','wasm-lowering','backend-wasm',
]);
requireDeps('erasure',['checked-core','compiler-ir','kernel']);
forbidDeps('erasure',[
  'syntax','meta','elab','language','backend-ts','wasm-ir',
  'wasm-lowering','backend-wasm','cli',
]);
requireDeps('compiler',[
  'checked-core','erasure','compiler-ir','backend-ts','kernel',
  'wasm-lowering','backend-wasm',
]);
forbidDeps('compiler',['syntax','meta','elab','language','cli']);
forbidDeps('backend-ts',['syntax','meta','elab','language','checked-core']);
forbidDeps('compiler-ir',['wasm-ir','wasm-lowering','backend-wasm']);
if(entry('wasm-ir').dependsOn.length!==0){
  throw new Error('architecture: wasm-ir must remain backend-neutral');
}
requireDeps('wasm-lowering',['compiler-ir','wasm-ir']);
forbidDeps('wasm-lowering',[
  'kernel','checked-core','erasure','backend-ts','backend-wasm',
  'syntax','meta','elab','language',
]);
requireDeps('backend-wasm',['wasm-ir']);
forbidDeps('backend-wasm',[
  'kernel','checked-core','erasure','compiler-ir','wasm-lowering',
  'backend-ts','syntax','meta','elab','language',
]);

function sourceFiles(dir){
  if(!existsSync(dir))return [];
  const out=[];
  for(const name of readdirSync(dir)){
    const full=join(dir,name);
    const stat=statSync(full);
    if(stat.isDirectory())out.push(...sourceFiles(full));
    else if(full.endsWith('.ts'))out.push(full);
  }
  return out;
}
function forbidImports(dir,patterns){
  for(const file of sourceFiles(dir)){
    const source=readFileSync(file,'utf8');
    for(const pattern of patterns){
      if(source.includes(pattern)){
        throw new Error(
          'architecture: forbidden import '+pattern+' in '+
          file.slice(root.length),
        );
      }
    }
  }
}

forbidImports(join(root,'packages','erasure','src'),[
  "from '@proofscript/compiler-ir';",
  "@proofscript/syntax",
  "@proofscript/meta",
  "@proofscript/elab",
  "@proofscript/language",
  "@proofscript/backend-ts",
]);
forbidImports(join(root,'packages','compiler','src'),[
  "from '@proofscript/compiler-ir';",
  "from '@proofscript/backend-ts';",
  "@proofscript/syntax",
  "@proofscript/meta",
  "@proofscript/elab",
  "@proofscript/language",
]);

for(const pkg of [
  'wasm-ir','wasm-lowering','checked-core','erasure','compiler-ir',
  'backend-ts','compiler',
]){
  forbidImports(join(root,'packages',pkg,'src'),[
    "from 'binaryen'",
    'from "binaryen"',
  ]);
}

const expectedPipeline=[
  'syntax','environment','meta','elab','checked-core',
  'erasure','compiler-ir','backend-ts','typescript',
];
if(
  JSON.stringify(map.preferredPipeline)!==JSON.stringify(expectedPipeline)
){
  throw new Error(
    'architecture: preferredPipeline drift; expected '+
    expectedPipeline.join(' -> '),
  );
}

const expectedWasmPipeline=[
  'syntax','environment','meta','elab','checked-core','erasure',
  'compiler-ir','wasm-lowering','wasm-ir','backend-wasm',
  'binaryen','webassembly',
];
if(
  JSON.stringify(map.wasmPipeline)!==JSON.stringify(expectedWasmPipeline)
){
  throw new Error(
    'architecture: wasmPipeline drift; expected '+
    expectedWasmPipeline.join(' -> '),
  );
}

const verifiedPipeline=readFileSync(
  join(root,'packages','cli','src','verified-pipeline.ts'),
  'utf8',
);
for(const required of [
  'createDefaultSourceFrontendRegistry',
  'elaborateV061Declarations',
  'compileCheckedCore',
]){
  if(!verifiedPipeline.includes(required)){
    throw new Error(
      'architecture: verified CLI pipeline missing '+required,
    );
  }
}
for(const forbidden of [
  'checkV061SoftwareModule',
  'compileSource(',
  '@proofscript/language',
]){
  if(verifiedPipeline.includes(forbidden)){
    throw new Error(
      'architecture: verified CLI pipeline contains legacy dependency '+
      forbidden,
    );
  }
}

const verifiedEmitter=readFileSync(
  join(root,'packages','backend-ts','src','verified-emitter.ts'),
  'utf8',
);
if(verifiedEmitter.includes("from '@proofscript/compiler-ir';")){
  throw new Error(
    'architecture: verified backend must import compiler-ir/verified subpath',
  );
}


console.log(
  'proofscript-architecture: PASS '+
  '(verified IR -> TS/JS and verified IR -> WasmIR -> Binaryen/Wasm)',
);
