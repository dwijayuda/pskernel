// Conservative private-value equality; no admission decision is cached.
import assert from 'node:assert/strict';
import {createCompilerDataEquality} from '../../psc1/host-tools/compiler-data-equality.mjs';
const equal=createCompilerDataEquality({maxMillis:1000});
assert.equal(equal({a:1n,b:['x']},{a:1n,b:['x']}),true);
assert.equal(equal({a:1n},{a:1}),false);
assert.equal(equal('\ud800','\ufffd'),false);
assert.equal(equal(-0,0),false);assert.equal(equal([,],[undefined]),false);
const a=Symbol('constructor'),b=Symbol('constructor');
assert.equal(equal({[a]:'same'},{[b]:'same'}),false);
assert.equal(equal({[a]:'same'},{[a]:'same'}),true);
const shared={value:1};assert.equal(equal([shared,shared],[{value:1},{value:1}]),true);
assert.equal(equal({a:1,b:2},{a:2,b:1}),false);
assert.equal(equal({get x(){throw Error('getter must not execute');}},{x:1}),false);
const x={},y={};x.self=x;y.self=y;assert.equal(equal(x,y),false);
assert.equal(equal(new Map(),new Map()),false);assert.equal(equal(()=>0,()=>0),false);
assert.equal(createCompilerDataEquality({maxNodes:2})({a:{b:1}},{a:{b:1}}),false);
assert.equal(equal(Object.defineProperty({},'x',{value:1}),{x:1}),false);
let deepA=0,deepB=0;for(let i=0;i<12000;i++){deepA={next:deepA};deepB={next:deepB};}
assert.equal(equal(deepA,deepB),true);
const big={};for(let i=0;i<10000;i++)big[i]={n:i};
assert.equal(createCompilerDataEquality({maxNodes:10})({shared:big,leaf:1},{shared:big,leaf:1}),true);
assert.equal(equal({shared:big,leaf:1},{shared:big,leaf:2}),false);
console.log('PSC1_COMPILER_DATA_EQUALITY '+JSON.stringify({status:'passed',sharedEntries:10000,deepNodes:12000}));
