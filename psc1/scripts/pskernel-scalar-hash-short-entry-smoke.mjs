import {pathToFileURL} from "node:url";
import path from "node:path";

if(process.argv.length!==3)throw Error("usage: scalar-hash-short-entry-smoke <generated-kernel>");
const k=await import(pathToFileURL(path.resolve(process.argv[2])).href);
const full=k.psKernelCacheStringHash,worker=k.psKernelCacheStringHashWorker;
if(typeof full!=="function"||typeof worker!=="function")throw Error("missing public hash functions");
const values=[...Array.from({length:11},(_,n)=>"A".repeat(n)),
 "é","é","€","😀","Aé","é€","Aé€","\u0000abcd"];
const encoder=new TextEncoder();
let assertions=0;
for(const value of values){
 let expected=0n;
 for(const character of value)expected=(expected*31n+BigInt(character.codePointAt(0)))%65521n;
 if(full(value)!==expected)throw Error("short full entry digest mismatch");
 assertions++;
 if(worker(BigInt(encoder.encode(value).length)+1n)(value)(0n)(0n)!==expected)
  throw Error("general staged worker digest mismatch");
 assertions++;
}
console.log("PSC1_SCALAR_HASH_SHORT_ENTRY_JS: PASS "+JSON.stringify({
 cases:values.length,assertions,shortMaxPairs:4,genericFallback:true}));
