// Linux Actions decision runner; this is not a checker/admission API.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
assert.equal(process.platform,'linux');assert.equal(process.env.GITHUB_ACTIONS,'true');
const dir='dist/pskernel-min/byte-cursor';
const G=await import(pathToFileURL(path.resolve(dir,'cursor.js')).href);
const rows=JSON.parse(fs.readFileSync(path.join(dir,'vectors.json')));
const byteValues=Array.from({length:256},(_,i)=>BigInt(i)),results=[];
for(const row of rows){
 const raw=fs.readFileSync(row.file),bytes=new Uint8Array(raw);
 let calls=0,next=row.command==='read'?row.offset:0;
 const at=index=>{
  if(typeof index!=='bigint'||index!==BigInt(next)||next>=row.size||next<0||next>=bytes.length)
    throw Error('BYTE_CURSOR_INDEX:'+row.label+':'+String(index));
  calls++;return row.invalid?256n:byteValues[bytes[next++]];
 };
 const start=performance.now();
 let actual;
 if(row.command==='read')actual=G.psMinByteCursorReadCode(BigInt(row.size),at,BigInt(row.offset));
 else if(row.command==='walk')actual=G.psMinByteCursorWalkCode(BigInt(row.remaining),BigInt(row.size),at);
 else actual=G.psMinByteCursorDigest(BigInt(row.size),at);
 const elapsedMs=performance.now()-start;
 assert.equal(typeof actual,'bigint');assert.equal(String(actual),row.expected,row.label);
 assert.equal(calls,row.expectedCalls,row.label+':callback-count');
 results.push({label:row.label,command:row.command,bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex'),
  actual:String(actual),callbacks:calls,elapsedMs});
}
const receipt={schema:'psc1-r9-generated-byte-traversal/1',head:process.env.GITHUB_SHA,cases:results.length,
 results,resourceUsage:process.resourceUsage(),physicalRepresentation:'private Uint8Array snapshot with internal scalar callback',
 boundary:'Traversal observations only. No parser, admission, public checker byte-adapter refinement or target-engine proof.'};
fs.writeFileSync(path.join(dir,'generated.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_R9_GENERATED_TRAVERSAL_PASS '+results.length);
