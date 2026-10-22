import {pathToFileURL} from "node:url";
import path from "node:path";

if(process.argv.length!==3)throw Error("usage: scalar-hash-worker-smoke <generated-kernel>");
const k=await import(pathToFileURL(path.resolve(process.argv[2])).href);
const get=name=>{if(typeof k[name]!=="function")throw Error("missing hash function "+name);return k[name];};
let assertions=0,cases=0,stages=0;
const must=(test,label)=>{if(test!==true)throw Error("PSC1_SCALAR_HASH_FAIL "+label);assertions++;};
const scan=get("psKernelCacheStringHashScan"),worker=get("psKernelCacheStringHashWorker");
const full=get("psKernelCacheStringHash"),mix=(h,n)=>(h*31n+n)%65521n;
const encoder=new TextEncoder();
const view=value=>{
 const chars=new Map();let size=0n;
 for(const ch of value){const width=BigInt(encoder.encode(ch).length);chars.set(size,{code:BigInt(ch.codePointAt(0)),width});size+=width;}
 return {chars,size};
};
// Independent boundary map: pinned Raw.get/next use 'A' at non-boundaries.
// The native frozen-source matrix exercises the same raw positions.
const reference=(v,fuel,position,hash)=>{
 while(fuel!==0n){
  fuel--;
  if(position>=v.size)return hash;
  const ch=v.chars.get(position)??{code:65n,width:1n};
  position+=ch.width;hash=mix(hash,ch.code);
 }
 return hash;
};
const words=["","a","A","é","é","€","😀","Aé€😀","\u0000x","_private","Init.Prelude","界∀∃"];
for(const value of words){
 const v=view(value);
 for(const fuel of [0n,1n,2n,4n,8n,32n])
  for(let position=0n;position<v.size+3n;position++)
   for(const hash of [0n,65520n,65521n,1234567n,1000000000000000000000000000023n]){
    const expected=reference(v,fuel,position,hash);
    must(scan(fuel,value,position,hash)===expected,"saturated-scan");
    const byValue=worker(fuel);must(typeof byValue==="function","fuel-stage");stages++;
    const byPosition=byValue(value);must(typeof byPosition==="function","value-stage");stages++;
    const byHash=byPosition(position);must(typeof byHash==="function","position-stage");stages++;
    must(byHash(hash)===expected,"staged-worker");
    cases++;
   }
 must(full(value)===reference(v,v.size+1n,0n,0n),"unchanged-public-digest");
}
console.log("PSC1_SCALAR_HASH_WORKER_JS: PASS "+JSON.stringify({cases,strings:words.length,stages,assertions,modulus:"65521",algorithmChanged:false}));
