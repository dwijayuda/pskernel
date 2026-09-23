import {ctor,nat,natAdd,natMul,natSub,uint8} from '../src/index.js';
function equal(a:unknown,b:unknown):void{if(a!==b)throw new Error(`expected ${String(b)}, got ${String(a)}`);}
equal(natAdd(nat(2),nat(3)),5n);
equal(natMul(nat(4),nat(5)),20n);
equal(natSub(nat(2),nat(5)),0n);
equal(uint8(257),1);
equal(uint8(-1),255);
equal(ctor('Some',1).tag,'Some');
console.log('ok - @proofscript/runtime foundation');
