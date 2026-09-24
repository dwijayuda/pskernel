import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';

const repoRoot=process.cwd();
const runtimePath=path.join(
  repoRoot,'packages','runtime','dist','src','lean4.js',
);
if(!fs.existsSync(runtimePath)){
  throw new Error(
    'Lean JS runtime is not built; run npm --workspace @proofscript/runtime run build first',
  );
}

const runtime=await import(pathToFileURL(runtimePath).href);
if(runtime.LEAN434_SOURCE_VERSION!=='4.34.0'){
  throw new Error(
    'runtime source version mismatch: '+String(runtime.LEAN434_SOURCE_VERSION),
  );
}
if(!Array.isArray(runtime.LEAN434_JS_EXTERN_MANIFEST)){
  throw new Error('missing LEAN434_JS_EXTERN_MANIFEST');
}
if(!Array.isArray(runtime.LEAN434_JS_DECL_EXTERN_BINDINGS)){
  throw new Error('missing LEAN434_JS_DECL_EXTERN_BINDINGS');
}
if(!Array.isArray(runtime.LEAN434_JS_IMPLEMENTED_BY_BINDINGS)){
  throw new Error('missing LEAN434_JS_IMPLEMENTED_BY_BINDINGS');
}

const seen=new Set();
const checked=[];
for(const entry of runtime.LEAN434_JS_EXTERN_MANIFEST){
  if(seen.has(entry.leanSymbol)){
    throw new Error('duplicate Lean extern mapping: '+entry.leanSymbol);
  }
  seen.add(entry.leanSymbol);

  if(!(entry.jsExport in runtime)){
    throw new Error(
      'mapped JS export does not exist: '+entry.leanSymbol+
      ' -> '+entry.jsExport,
    );
  }

  const upstream=path.join(
    repoRoot,
    'study','lean4-4.34.0','src',
    ...entry.upstreamSource.split('/'),
  );
  if(!fs.existsSync(upstream)){
    throw new Error(
      'mapped upstream source does not exist: '+entry.upstreamSource,
    );
  }
  const text=fs.readFileSync(upstream,'utf8');
  const quoted='"'+entry.leanSymbol+'"';
  if(!text.includes(quoted)||!text.includes('@[extern')){
    throw new Error(
      'mapped Lean extern symbol not found in declared upstream source: '+
      entry.leanSymbol+' @ '+entry.upstreamSource,
    );
  }

  checked.push({
    leanSymbol:entry.leanSymbol,
    jsExport:entry.jsExport,
    category:entry.category,
    upstreamSource:entry.upstreamSource,
  });
}

const manifestBySymbol=new Map(
  runtime.LEAN434_JS_EXTERN_MANIFEST.map((entry)=>[entry.leanSymbol,entry]),
);
const seenDeclarations=new Set();
const declarationBindings=[];
for(const binding of runtime.LEAN434_JS_DECL_EXTERN_BINDINGS){
  if(seenDeclarations.has(binding.leanDeclaration)){
    throw new Error(
      'duplicate Lean declaration extern binding: '+binding.leanDeclaration,
    );
  }
  seenDeclarations.add(binding.leanDeclaration);
  const descriptor=manifestBySymbol.get(binding.leanSymbol);
  if(descriptor===undefined){
    throw new Error(
      'declaration binding references unknown extern symbol: '+
      binding.leanDeclaration+' -> '+binding.leanSymbol,
    );
  }
  if(descriptor.upstreamSource!==binding.upstreamSource){
    throw new Error(
      'declaration binding source mismatch for '+binding.leanDeclaration,
    );
  }
  if(!Number.isInteger(binding.arity)||binding.arity<0){
    throw new Error(
      'invalid declaration binding arity for '+binding.leanDeclaration,
    );
  }
  if(
    binding.effect!==undefined
    &&binding.effect!=='pure'
    &&binding.effect!=='st-action'
  ){
    throw new Error(
      'invalid extern effect for '+binding.leanDeclaration+
      ': '+String(binding.effect),
    );
  }
  if(binding.runtimeArgs!==undefined){
    const seenRuntimeArgs=new Set();
    for(const index of binding.runtimeArgs){
      if(
        !Number.isInteger(index)
        ||index<0
        ||index>=binding.arity
      ){
        throw new Error(
          'invalid runtime argument index for '+
          binding.leanDeclaration+': '+String(index),
        );
      }
      if(seenRuntimeArgs.has(index)){
        throw new Error(
          'duplicate runtime argument index for '+
          binding.leanDeclaration+': '+String(index),
        );
      }
      seenRuntimeArgs.add(index);
    }
  }

  const upstream=path.join(
    repoRoot,
    'study','lean4-4.34.0','src',
    ...binding.upstreamSource.split('/'),
  );
  const text=fs.readFileSync(upstream,'utf8');
  if(!text.includes('"'+binding.leanSymbol+'"')){
    throw new Error(
      'bound extern symbol missing from upstream source: '+
      binding.leanDeclaration+' -> '+binding.leanSymbol,
    );
  }
  const parts=binding.leanDeclaration.split('.');
  const sourceSpellings=[
    binding.leanDeclaration,
    parts.slice(-2).join('.'),
    parts.at(-1),
  ].filter((value,index,self)=>
    typeof value==='string'
    &&value.length>0
    &&self.indexOf(value)===index
  );
  const declarationPattern=new RegExp(
    String.raw`\\b(?:def|opaque|abbrev|instance|protected\\s+def)\\s+(?:`+
    sourceSpellings.map(
      (value)=>value.replace(/[.*+?^$\\{\}()|[\\]\\]/g,'\\\\  if(!text.includes(binding.leanDeclaration)){
    throw new Error(
      'bound Lean declaration missing from upstream source: '+
      binding.leanDeclaration+' @ '+binding.upstreamSource,
    );
  }

  declarationBindings.push({'),
    ).join('|')+
    String.raw`)\\b`,
    'u',
  );
  if(!declarationPattern.test(text)){
    throw new Error(
      'bound Lean declaration missing from upstream source: '+
      binding.leanDeclaration+' @ '+binding.upstreamSource+
      ' (checked source spellings: '+sourceSpellings.join(', ')+')',
    );
  }

  declarationBindings.push({
    leanDeclaration:binding.leanDeclaration,
    leanSymbol:binding.leanSymbol,
    arity:binding.arity,
    runtimeArgs:binding.runtimeArgs??null,
    effect:binding.effect??'pure',
    upstreamSource:binding.upstreamSource,
  });
}

const seenImplementedBy=new Set();
const implementedByBindings=[];
for(const binding of runtime.LEAN434_JS_IMPLEMENTED_BY_BINDINGS){
  if(seenImplementedBy.has(binding.leanDeclaration)){
    throw new Error(
      'duplicate Lean implemented_by binding: '+binding.leanDeclaration,
    );
  }
  seenImplementedBy.add(binding.leanDeclaration);
  if(!Number.isInteger(binding.arity)||binding.arity<0){
    throw new Error(
      'invalid implemented_by arity for '+binding.leanDeclaration,
    );
  }
  const upstream=path.join(
    repoRoot,
    'study','lean4-4.34.0','src',
    ...binding.upstreamSource.split('/'),
  );
  if(!fs.existsSync(upstream)){
    throw new Error(
      'implemented_by upstream source missing: '+binding.upstreamSource,
    );
  }
  const text=fs.readFileSync(upstream,'utf8');
  if(!text.includes('@[implemented_by '+binding.implementation)){
    throw new Error(
      'implemented_by attribute missing from upstream source: '+
      binding.leanDeclaration+' -> '+binding.implementation,
    );
  }
  if(!text.includes(binding.leanDeclaration)){
    throw new Error(
      'implemented_by declaration missing from upstream source: '+
      binding.leanDeclaration,
    );
  }
  implementedByBindings.push({
    leanDeclaration:binding.leanDeclaration,
    implementation:binding.implementation,
    arity:binding.arity,
    adapter:binding.adapter,
    upstreamSource:binding.upstreamSource,
  });
}

process.stdout.write(JSON.stringify({
  format:'proofscript-lean434-runtime-manifest-check',
  leanVersion:runtime.LEAN434_SOURCE_VERSION,
  runtimeVersion:runtime.LEAN434_JS_RUNTIME_VERSION,
  mappings:checked.length,
  declarationBindings:declarationBindings.length,
  implementedByBindings:implementedByBindings.length,
  entries:checked,
  bindings:declarationBindings,
  implementedBy:implementedByBindings,
},null,2)+'\n');
