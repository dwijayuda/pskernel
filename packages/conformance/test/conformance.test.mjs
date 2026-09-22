import assert from 'node:assert/strict';
import {mkdtempSync,mkdirSync,writeFileSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {discoverArenaCases,runArenaSuite} from '../src/index.mjs';

const root=mkdtempSync(join(tmpdir(),'pskernel-conformance-'));
try{
  mkdirSync(join(root,'good','tutorial'),{recursive:true});
  mkdirSync(join(root,'bad','other'),{recursive:true});
  const good=[
    '{"meta":{"exporter":{"name":"test","version":"1"},"lean":{"githash":"test","version":"4.34.0"},"format":{"version":"3.1.0"}}}',
    '{"in":1,"str":{"pre":0,"str":"A"}}',
    '{"il":1,"succ":0}',
    '{"ie":0,"sort":1}',
    '{"axiom":{"name":1,"levelParams":[],"type":0,"isUnsafe":false}}'
  ].join('\n')+'\n';
  const bad='{"meta":{"exporter":{"name":"test","version":"1"},"lean":{"githash":"test","version":"4.33.0"},"format":{"version":"3.1.0"}}}\n';
  writeFileSync(join(root,'good','tutorial','good.ndjson'),good);
  writeFileSync(join(root,'bad','other','bad.ndjson'),bad);

  const cases=discoverArenaCases(root);
  assert.equal(cases.length,2);
  const result=await runArenaSuite(root,{workers:2,timeoutMs:10000});
  assert.equal(result.ok,true);
  assert.equal(result.total,2);
  assert.equal(result.accept,1);
  assert.equal(result.reject,1);
  console.log('ok - @proofscript/conformance MVP');
}finally{rmSync(root,{recursive:true,force:true});}
