import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';
const files=[];function walk(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const p=path.join(d,e.name);if(e.isDirectory())walk(p);else if(e.isFile())files.push(p);}}walk('input');
const requests=files.filter(f=>path.basename(f)==='G1-bootstrap.request.json');assert.equal(requests.length,1);
const bytes=fs.readFileSync(requests[0]);assert.ok(bytes.length<=128*1024*1024);const hash=crypto.createHash('sha256').update(bytes).digest('hex');assert.equal(hash,'ad02452b0a840c27777ceb9aebdba3a589a2b8dd3617c879a85a3d67455021f1');
const request=JSON.parse(bytes);assert.equal(request[1],'G1-bootstrap');assert.equal(request[6].length,85);
const rows=[];
for(const [module,text] of request[6]){
 const defs=[...text.matchAll(/^def ([A-Za-z0-9_]+)[\s\S]*?(?=^def |^structure |^inductive |^namespace |^end |$(?![\s\S]))/gm)];
 for(const m of defs){
  const name=m[1],def=m[0],body=def.slice(def.indexOf(':=')+2);
  for(const branch of body.matchAll(/^  \|[^\n]*?=>([\s\S]*?)(?=^  \||$(?![\s\S]))/gm)){
   const chunk=branch[1],fun=chunk.search(/\bfun\s*\(/);if(fun<0)continue;
   const before=chunk.slice(0,fun);if(!before.includes(name))continue;
   rows.push({module,name,line:text.slice(0,m.index).split('\n').length,header:def.slice(0,def.indexOf(':=')+2),prefix:before.slice(0,2500),excerpt:def.slice(0,7000)});
  }
 }
}
fs.mkdirSync('diagnosis',{recursive:true});fs.writeFileSync('diagnosis/source-prefixes.json',JSON.stringify({schema:'psc1-source-prefix-audit/1',requestSha256:hash,rows,qualification:false,scope:'syntactic candidate census of exact85-source G1 request; not reachability/performance proof'},null,2)+'\n');
console.log('PSC1_SOURCE_PREFIX_CANDIDATES: '+JSON.stringify(rows.map(({excerpt,...r})=>r)));
console.log('PSC1_SOURCE_PREFIX_EXCERPTS: '+JSON.stringify(rows));
