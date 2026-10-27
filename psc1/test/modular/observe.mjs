// Executed only after the host's genuine independent admission and npm install.
import assert from 'node:assert/strict';
import {performance} from 'node:perf_hooks';
import {pathToFileURL} from 'node:url';
const started=performance.now();
const [mode,variant,reference]=process.argv.slice(2);
let n,c,r;
if(mode==='installed'){
  const umbrella=await import('@proofscript/modular-compiler-pilot');
  assert.equal(umbrella.verifyPilot().logicalAdmission,'accepted');
  const graph=await umbrella.loadPilot({variant});({names:n,consumer:c,runtime:r}=graph);
  assert.equal(graph.variant,variant);
}else{n=c=await import(pathToFileURL(reference).href);}
const root=c.pilotSeed;
let name=n.psNameAppendStr(root,'café'),name2=n.psNameAppendNum(name,42n);
name2=n.psNameAppendStr(name2,'🌱');
assert.equal(n.psNameDepth(name2),3n);
assert.equal(c.pilotDepth(name2),3n);
assert.equal(c.pilotApply(n.psNameDepth,name2),3n);
assert.equal(n.psNameToString(name2),'café.42.🌱');
assert.equal(c.pilotDescribe(name2),'café.42.🌱!');
assert.equal(c.pilotRecursiveDescribe(name2),'root/café/42/🌱');
assert.equal(c.pilotSame(name2,name2),true);
assert.equal(c.pilotSame(name,name2),false);
assert.equal(n.psNameLastComponent(name2),'🌱');
assert.equal(n.psStringEq('é🌱','é🌱'),true);
assert.equal(n.psStringEq('é🌱','é🌿'),false);
assert.equal(n.psStringEq('é','e\u0301'),false);
let deep=root;
for(let i=0;i<6000;i++)deep=n.psNameAppendStr(deep,'x');
assert.equal(c.pilotDepth(deep),6000n);
assert.equal(c.pilotSame(deep,deep),true);
if(r){
  // If a declaration uses a generator, it must register in the imported owner.
  for(const module of [n,c]){
    const registered=Object.values(module).filter(v=>typeof v==='function'&&r.__ps$implementations.has(v));
    assert.ok(registered.length>0,'PSC1_MODULAR_REGISTRY_UNSHARED');
  }
  if(variant==='ts'){
    const tag=Object.getOwnPropertySymbols(root);
    assert.equal(tag.length,1);assert.equal(tag[0],r.__ps$tag$0);
    assert.equal(r.PsName.anonymous[r.__ps$tag$0],root[r.__ps$tag$0]);
  }else assert.equal(root.$ps$tag,'PsName.anonymous');
}
console.log(JSON.stringify({observations:['café.42.🌱','root/café/42/🌱',3,'🌱',true,false,false,6000],
 elapsedMs:performance.now()-started,runtime:process.versions.bun?'bun':'node',variant,mode}));
