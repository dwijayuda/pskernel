import {BuildCache,createBuildPlan} from '../src/index.js';
function equal(a:unknown,b:unknown):void{if(a!==b)throw new Error(`expected ${String(b)}, got ${String(a)}`);}
equal(createBuildPlan([{name:'app',dependencies:['core']},{name:'core',dependencies:[]}]).order.join(','),'core,app');
let cycle=false;try{createBuildPlan([{name:'a',dependencies:['b']},{name:'b',dependencies:['a']}]);}catch{cycle=true;}
equal(cycle,true);
const cache=new BuildCache<number>();cache.set('x',1);equal(cache.get('x'),1);
console.log('ok - @proofscript/project foundation');
