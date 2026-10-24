import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {buildTarget,sha} from '../host-tools/generated-target-tools.mjs';
import {loadWasmArtifact} from '../host-tools/generated-wasm-transport.mjs';
const root=path.resolve('dist/wasm-nat-divmod'),api={};
for(const kind of ['legacy','current']){
 const source=fs.readFileSync(path.join(root,kind+'.wasm.hex'),'utf8');
 const built=buildTarget({target:'wasm-core',source,directory:path.join(root,kind),publicNames:['quotient','remainder'],
  publicTypes:['quotient','remainder'].map(name=>({name,parameters:[['primitive','nat'],['primitive','nat']],result:['primitive','nat']}))});
 api[kind]=loadWasmArtifact(built.file);
}
const values=[0n,1n,2n,3n,5n,7n,15n,16n,17n,127n,128n,129n,255n,256n,257n,
 (1n<<32n)-1n,1n<<32n,(1n<<64n)+1n,(1n<<128n)-1n,(1n<<256n)+12345n,(1n<<512n)+19n];
const pairs=values.flatMap(a=>values.map(b=>[a,b]));
for(const b of values)for(const delta of [-1n,0n,1n])if(b+delta>=0n)pairs.push([b+delta,b]);
let seed=123456789n;
for(let i=0;i<200;i++){seed=(seed*1103515245n+12345n)%((1n<<96n)-1n);const a=seed;seed=(seed*1103515245n+12345n)%((1n<<48n)-1n);pairs.push([a,seed]);}
for(const [a,b]of pairs){
 const expected=b===0n?[0n,a]:[a/b,a%b];
 for(const kind of ['legacy','current']){
  const actual=[api[kind].quotient(a,b),api[kind].remainder(a,b)];
  assert.deepEqual(actual,expected,kind+':'+a+'/'+b);
  if(b!==0n){assert.equal(actual[0]*b+actual[1],a);assert.ok(actual[1]<b);}
 }
}
const times={};
for(const kind of ['legacy','current']){
 const started=performance.now();let sum=0n;
 for(let i=0;i<10000;i++){const a=(1n<<128n)+BigInt(i);sum+=api[kind].quotient(a,128n)+api[kind].remainder(a,128n);}
 times[kind]={elapsedMs:Math.round(performance.now()-started),checksum:String(sum)};
}
assert.equal(times.current.checksum,times.legacy.checksum);
const receipt={schema:'psc1-wasm-nat-divmod/1',testedCommit:process.env.GITHUB_SHA,pairs:pairs.length,actualResults:pairs.length*4,
 maxInputBits:513,divisorZero:'unchanged',oddAndEvenDivisors:true,arbitraryPrecision:'preserved',sampledWorkload:times,
 originalFunctionSha256:sha(fs.readFileSync('test/WasmNatDivModReference.lean')),qualification:false};
fs.writeFileSync(path.join(root,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_WASM_NAT_DIVMOD: '+JSON.stringify(receipt));
