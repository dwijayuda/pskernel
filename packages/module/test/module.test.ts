import assert from 'node:assert/strict';
import {canonicalJson,createModuleArtifact,decodeModuleArtifact,encodeModuleArtifact,loadModuleArtifact,moduleArtifactSummary,normalizeDeclarationStream,verifyModuleArtifact,verifyModuleDependencies} from '../src/index.js';

const stream=[
  '{"meta":{"exporter":{"name":"test","version":"1"},"lean":{"githash":"293d5d0c0c3f3dded4688b3ccd6a33939ac5102b","version":"4.34.0"},"format":{"version":"3.1.0"}}}',
  '{"in":1,"str":{"pre":0,"str":"A"}}',
  '{"il":1,"succ":0}',
  '{"ie":0,"sort":1}',
  '{"axiom":{"name":1,"levelParams":[],"type":0,"isUnsafe":false}}'
].join('\r\n');
const a=createModuleArtifact({module:'Test.A',declarations:stream});
const b=createModuleArtifact({module:'Test.A',declarations:stream.replace(/\r\n/g,'\n')});
assert.equal(a.integrity,b.integrity);
assert.equal(a.payload.integrity,b.payload.integrity);
assert.equal(normalizeDeclarationStream(stream).endsWith('\n'),true);
const encoded=encodeModuleArtifact(a);
assert.equal(encoded,canonicalJson(JSON.parse(encoded))+'\n');
const decoded=decodeModuleArtifact(encoded);
assert.deepEqual(decoded,a);
assert.equal(verifyModuleArtifact(decoded),true);
const loaded=loadModuleArtifact(decoded);
assert.equal(loaded.stats.declarations,1);
assert.equal(loaded.env.size,1);
const dep=createModuleArtifact({module:'Dep',declarations:stream});
const withDep=createModuleArtifact({module:'Uses.Dep',declarations:stream,dependencies:[{module:'Dep',integrity:dep.integrity}]});
assert.equal(verifyModuleDependencies(withDep,new Map([['Dep',dep.integrity]])),true);
assert.throws(()=>verifyModuleDependencies(withDep,new Map()),/missing dependency/);
assert.throws(()=>loadModuleArtifact(withDep),/missing dependency/);
const tampered=structuredClone(a) as typeof a & {payload:{text:string}};
tampered.payload.text=tampered.payload.text.replace('"A"','"B"');
assert.throws(()=>verifyModuleArtifact(tampered),/payload integrity mismatch/);
assert.equal(canonicalJson({b:1,a:2}),'{"a":2,"b":1}');
const summary=moduleArtifactSummary(a);
assert.equal(summary.module,'Test.A');
assert.equal(summary.dependencies,0);
const cyc:unknown[]=[];cyc.push(cyc);
assert.throws(()=>canonicalJson(cyc),/cycle/);
console.log('ok - @proofscript/module TypeScript MVP');
