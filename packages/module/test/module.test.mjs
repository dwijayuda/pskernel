import assert from 'node:assert/strict';
import {
  canonicalJson,
  createModuleArtifact,
  decodeModuleArtifact,
  encodeModuleArtifact,
  loadModuleArtifact,
  normalizeDeclarationStream,
  verifyModuleArtifact,
  verifyModuleDependencies
} from '../src/index.mjs';

const stream=[
  '{"meta":{"exporter":{"name":"test","version":"1"},"lean":{"githash":"test","version":"4.34.0"},"format":{"version":"3.1.0"}}}',
  '{"in":1,"str":{"pre":0,"str":"A"}}',
  '{"il":1,"succ":0}',
  '{"ie":0,"sort":1}',
  '{"axiom":{"name":1,"levelParams":[],"type":0,"isUnsafe":false}}'
].join('\r\n');

const a=createModuleArtifact({module:'Test.A',declarations:stream});
const b=createModuleArtifact({module:'Test.A',declarations:stream.replace(/\r\n/g,'\n')});
assert.equal(a.integrity,b.integrity,'line endings must not affect module integrity');
assert.equal(a.payload.integrity,b.payload.integrity,'line endings must not affect payload integrity');
assert.equal(normalizeDeclarationStream(stream).endsWith('\n'),true);

const encoded=encodeModuleArtifact(a);
assert.equal(encoded,canonicalJson(JSON.parse(encoded))+'\n','encoding must be canonical');
const decoded=decodeModuleArtifact(encoded);
assert.deepEqual(decoded,a);
assert.equal(verifyModuleArtifact(decoded),true);

const loaded=loadModuleArtifact(decoded);
assert.equal(loaded.stats.declarations,1);
assert.equal(loaded.env.size,1);

const dep=createModuleArtifact({module:'Dep',declarations:stream});
const withDep=createModuleArtifact({
  module:'Uses.Dep',
  declarations:stream,
  dependencies:[{module:'Dep',integrity:dep.integrity}]
});
assert.equal(verifyModuleDependencies(withDep,new Map([['Dep',dep.integrity]])),true);
assert.throws(()=>verifyModuleDependencies(withDep,new Map()),/missing dependency/);
assert.throws(()=>loadModuleArtifact(withDep),/missing dependency/);

const tampered=structuredClone(a);
tampered.payload.text=tampered.payload.text.replace('"A"','"B"');
assert.throws(()=>verifyModuleArtifact(tampered),/payload integrity mismatch/);

const reordered=structuredClone(withDep);
reordered.dependencies=[
  {module:'Z',integrity:dep.integrity},
  {module:'A',integrity:dep.integrity}
];
reordered.integrity='sha256:'+'0'.repeat(64);
assert.throws(()=>verifyModuleArtifact(reordered),/canonical order|integrity mismatch/);

assert.equal(canonicalJson({b:1,a:2}), '{"a":2,"b":1}');
console.log('ok - @proofscript/module MVP');
