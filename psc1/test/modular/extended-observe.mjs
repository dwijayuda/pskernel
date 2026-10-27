import assert from 'node:assert/strict';
import {performance} from 'node:perf_hooks';
import {pathToFileURL} from 'node:url';
const started=performance.now();
const [mode,variant,reference]=process.argv.slice(2);
let c,n,r,graph;
if(mode==='installed'){
  const {loadPilot}=await import('@proofscript/modular-compiler-pilot');
  graph=await loadPilot({variant});({consumer:c,names:n,runtime:r}=graph);
  assert.equal(Object.keys(graph.modules).length,6);
}else n=c=await import(pathToFileURL(reference).href);
const loaded=performance.now()-started;
const large=90071992547409931234567890n;
assert.equal(c.extendedNumbers(10n),66n);
assert.equal(c.extendedNumbers(large),large*6n+6n);
assert.equal(c.extendedNameText(42n),'42/café🌱');
assert.equal(c.extendedPairs(42n),2n);
assert.equal(c.extendedCurriedUse(20n,22n),42n);
assert.equal(c.extendedGenericResult(large),large);
assert.equal(c.extendedGenericString('café🌱'),'café🌱');
const input='{"z":[1,true,null],"a":"café🌱"}',expected='{"a":"café🌱","z":[1,true,null]}';
assert.equal(c.extendedCanonical(input),expected);
assert.equal(c.extendedCanonical('{"line":"a\\nb"}'),'{"line":"a\\nb"}');
assert.equal(c.extendedCanonical('{"large":'+large+'}'),'{"large":'+large+'}');
assert.equal(c.extendedCanonical('{'),'parse-error');
let deep=c.extendedSeed;
for(let i=0;i<6000;i++)deep=n.psNameAppendStr(deep,'x');
assert.equal(c.extendedDepth(deep),6000n);
assert.equal(c.extendedSame(deep,deep),true);
if(r){
  for(const key of ['@proofscript/modular-pilot-ps-foundation-list','@proofscript/modular-pilot-names',
    '@proofscript/modular-pilot-ps-foundation-text','@proofscript/modular-pilot-ps-bridge-json','@proofscript/modular-pilot-consumer']){
    assert.ok(Object.values(graph.modules[key]).some(value=>typeof value==='function'&&r.__ps$implementations.has(value)),
      'PSC1_EXTENDED_REGISTRY:'+key);
  }
  if(variant==='ts'){
    const symbols=Object.getOwnPropertySymbols(c.extendedSeed);
    assert.equal(symbols.length,1);assert.ok(Object.values(r).includes(symbols[0]));
  }else assert.equal(c.extendedSeed.$ps$tag,'anonymous');
}
console.log(JSON.stringify({variant,mode,runtime:process.versions.bun?'bun':'node',
 observations:['66',String(large*6n+6n),'42/café🌱','2','42',String(large),'café🌱',expected,'parse-error','6000',true],
 loadedMs:loaded,elapsedMs:performance.now()-started,processMaxRssKiB:process.resourceUsage().maxRSS}));
