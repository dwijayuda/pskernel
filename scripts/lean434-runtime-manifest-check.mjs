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

process.stdout.write(JSON.stringify({
  format:'proofscript-lean434-runtime-manifest-check',
  leanVersion:runtime.LEAN434_SOURCE_VERSION,
  runtimeVersion:runtime.LEAN434_JS_RUNTIME_VERSION,
  mappings:checked.length,
  entries:checked,
},null,2)+'\n');
