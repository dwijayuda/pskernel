// Read-only evidence extraction. Artifact contents are data, never executed.
import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const files=[];function scan(dir){for(const e of fs.readdirSync(dir,{withFileTypes:true})){const p=path.join(dir,e.name);if(e.isDirectory())scan(p);else if(e.isFile())files.push(p);}}scan('input');
for(const file of files){
 const name=path.basename(file),bytes=fs.readFileSync(file);
 if(name==='tool.stderr.txt'||name==='tool.stdout.txt'){
  const text=bytes.toString('utf8'),lines=text.split('\n'),errors=lines.filter(l=>/^error(?:\[|:)/.test(l));
  console.log('PSC1_RUST_TOOL_LOG: '+JSON.stringify({file,bytes:bytes.length,sha256:sha(bytes),
   errors:errors.slice(0,30).map(l=>l.slice(0,500)),errorCount:errors.length,
   warningCount:lines.filter(l=>/^warning:/.test(l)).length,
   head:lines.slice(0,65).map(l=>l.slice(0,400))}));
 }
 if(name==='Cargo.lock')console.log('PSC1_RUST_RECORDED_LOCK: '+JSON.stringify({file,sha256:sha(bytes),text:bytes.toString('utf8')}));
 if(name==='qualification.json'){
  const q=JSON.parse(bytes);console.log('PSC1_RUST_BOOTSTRAP_IDENTITY: '+JSON.stringify({
   testedCommit:q.testedCommit,sourceClosureDigest:q.sourceClosureDigest,sourceModules:q.sourceModules,
   bootstrap:q.bootstrap,status:q.status,generations:q.generations,events:q.events,
   failure:q.failure?.slice(0,500)}));
 }
 if(name==='module.rs'||name==='main.rs')console.log('PSC1_RUST_GENERATED_SOURCE: '+JSON.stringify({file,bytes:bytes.length,sha256:sha(bytes),lines:bytes.toString('utf8').split('\n').length}));
}
