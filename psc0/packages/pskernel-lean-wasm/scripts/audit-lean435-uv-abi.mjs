// Static ABI preflight for Lean 4.35.0's native and no-libuv runtime
// interfaces. Header-vs-definition arity/type/return mismatches can produce
// late Emscripten errors after expensive bootstrap work. This is a source
// contract test, NOT a substitute for compiling or checking proofs.
import {readFile} from 'node:fs/promises';
import path from 'node:path';

const root=process.argv[2];
if(!root)throw Error('usage: node audit-lean435-uv-abi.mjs <pinned-patched-lean4-root>');
const cases=['event_loop','system','net_addr','timer','signal','tcp','udp','dns'];
const expression=/extern\s+"C"\s+LEAN_EXPORT\s+([A-Za-z_][\w:<> *&]*?)\s+(lean_[A-Za-z0-9_]+)\s*\(([^()]*)\)\s*([;{])/g;
function signatures(source,expectedPunctuation){
  const result=[];
  for(const m of source.matchAll(expression)){
    if(m[4]!==expectedPunctuation)continue;
    result.push({name:m[2],returnType:m[1].trim().replace(/\s+/g,' '),
      params:m[3].trim()});
  }
  return result;
}
function parameterType(parameter){
  const clean=parameter.replace(/\/\*[\s\S]*?\*\//g,'').trim().replace(/\s+/g,' ');
  if(!clean||clean==='void')return null;
  // A C++ parameter name is optional. Remove it only when a type remains;
  // pointer/ref declarations may put their declarator next to the name.
  const match=/^(.+?)(?:\s+|\s*([*&])\s*)([A-Za-z_]\w*)$/.exec(clean);
  if(!match)return clean;
  const before=match[1].trim();
  if(!before)return clean;
  return (before+(match[2]||'')).replace(/\s+/g,' ');
}
function argumentTypes(text){
  if(!text||text==='void')return [];
  return text.split(',').map(parameterType);
}
let compared=0;
for(const file of cases){
  const prefix=path.join(root,'src/runtime/uv',file);
  const header=await readFile(prefix+'.h','utf8');
  const impl=await readFile(prefix+'.cpp','utf8');
  const publicFunctions=signatures(header,';');
  const h=new Map();
  for(const signature of publicFunctions){
    if(h.has(signature.name))throw Error(file+': duplicated public ABI '+signature.name);
    h.set(signature.name,signature);
  }
  if(h.size<2)throw Error(file+': missing expected public exported ABI');
  let checked=0;
  for(const implementation of signatures(impl,'{')){
    const declared=h.get(implementation.name);
    if(!declared)continue; // Exported implementation may be owned elsewhere.
    const expected=argumentTypes(declared.params),actual=argumentTypes(implementation.params);
    if(implementation.returnType!==declared.returnType ||
       JSON.stringify(actual)!==JSON.stringify(expected)){
      throw Error(file+': '+implementation.name+' C++ ABI differs: '+
        JSON.stringify({declared,implementation,expected,actual}));
    }
    checked++;compared++;
  }
  if(checked<h.size)throw Error(file+': some header declarations lack a checked implementation');
  console.log('PSC0_LEAN435_UV_ABI '+file+': '+checked+' definitions, '+h.size+' header signatures');
}
if(compared<120)throw Error('Lean 4.35.0 UV ABI audit unexpectedly incomplete: '+compared);
console.log('PSC0_LEAN435_UV_ABI_PASS checked '+compared+' official definitions');
