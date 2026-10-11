// Diagnostic-only: independently inspect the generated PSCV0 and retained
// compiler ADT ABIs. No source-code rewriting, checker bypass or trust claims.
import assert from 'node:assert/strict';
import { readFile, readdir, stat } from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const sourceRoot=process.argv[2];
const retained=process.argv[3];
assert(sourceRoot&&retained,'Require cloud artifact and retained toolchain');
const walk=async (root,depth=0)=>{
  if(depth>5)return [];
  const found=[];
  for(const entry of await readdir(root,{withFileTypes:true})){
    const p=path.join(root,entry.name);
    if(entry.isDirectory())found.push(...await walk(p,depth+1));
    else if(entry.isFile()&&(entry.name==='index.js'||entry.name==='index.ts'))found.push(p);
  }
  return found;
};
const files=await walk(sourceRoot);
const js=files.find(f=>f.endsWith(path.join('bootstrap','index.js')));
const ts=files.find(f=>f.endsWith(path.join('bootstrap','index.ts')));
assert(js&&ts,'No successful surface-bootstrap source in failed-run retained artifact: '+files.join(', '));
const C=await import(pathToFileURL(path.join(retained,'node_modules/@proofscript/compiler/dist/index.js')).href);
const B=await import(pathToFileURL(js).href);
const declared=(await readFile(ts,'utf8'));
const types=['List','Option','Prod','PsSourcePos','PsSourceSpan','PsSyntaxName','PsSyntaxBinderKind','PsSyntaxTerm','PsSyntaxPattern','PsSyntaxDeclaration','PsSyntaxModule'];
function schema(name){
 const f=new RegExp('export (?:type|interface|const|class) '+name+'\\b','g'),hits=[];
 for(const match of declared.matchAll(f)){
  const at=match.index;
  hits.push(declared.slice(at,Math.min(declared.length,at+1650)));
  if(hits.length>=3)break;
 }
 return hits;
}
const tag=x=>x&&typeof x==='object'?Object.getOwnPropertySymbols(x).map(s=>({name:s.description,value:x[s]})):null;
const shape=(x,depth=0)=>{
 if(x===null||typeof x!=='object')return typeof x==='bigint'?(x.toString()+'n'):x;
 if(depth>=7)return '[depth-limit]';
 const out={symbols:tag(x)};
 for(const k of Object.keys(x).slice(0,18))out[k]=shape(x[k],depth+1);
 if(Object.keys(x).length>18)out._truncated='object-properties';
 return out;
};
const s='function add(x: Nat, y: Nat): Nat := Nat.add(x, y)\nconst grouped: Nat := (add(1))(2)\n';
const result=B.psPscv0ParseSource(true,s);
assert(tag(result)?.some(t=>t.value==='ok'),'generated PSCV0 reader must accept ownership source');
const lower=B.psPscv0LowerModule(result.value);
assert(tag(lower)?.some(t=>t.value==='ok'),'generated source lowering must succeed');
const report={
 generatedBootstrapTs:ts,
 generatedBootstrapJs:js,
 classes:Object.fromEntries(types.map(t=>[t,{
  bootstrap:Object.keys(B[t]||{}).slice(0,32),
  retained:Object.keys(C[t]||{}).slice(0,32),
  bootstrapIsRetained:B[t]===C[t]}])),
 module:shape(lower.value),
 sourceReader:shape(result.value),
 representativeSchemas:Object.fromEntries(types.map(t=>[t,schema(t)]))
};
const summary=JSON.stringify(report,null,2);
process.stdout.write('PSCV0_ABI_PROBE_BEGIN\n'+summary.slice(0,42000)+'\nPSCV0_ABI_PROBE_END\n');
