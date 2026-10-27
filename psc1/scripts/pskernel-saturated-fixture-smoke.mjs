import * as k from './saturated-fixture.mjs';
let assertions=0;
for(const fuel of [0n,1n,2n,3n,16n,17n,33n,100n])for(const x of [0n,1n,2n,2n**128n+17n])for(const y of [0n,1n,19n,2n**129n]){
 const original=k.genericCurried(fuel)(x)(y),optimized=k.genericFlat(fuel,x,y);
 if(original!==x+y+fuel||optimized!==original)throw Error('saturated recurrence mismatch');
 assertions++;
}
if(k.genericFlat(1000000n,1n,2n)!==1000003n)throw Error('constant-stack tail loop failed');
assertions++;
console.log('PSC1_SATURATED_TAIL_JS: PASS '+JSON.stringify({assertions,actualGenericCurriedReference:true,parallelArgumentUpdates:true,constantStackMillionSteps:true}));
