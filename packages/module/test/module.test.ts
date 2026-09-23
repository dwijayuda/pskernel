import assert from 'node:assert/strict';
import {Environment,constant,levelSucc,levelZero,nameFromDotted,sort} from 'lean-ts-kernel';
import {canonicalJson,createCheckedModuleArtifact,createModuleArtifact,decodeModuleArtifact,encodeModuleArtifact,loadModuleArtifact,moduleArtifactSummary,normalizeDeclarationStream,verifyModuleArtifact,verifyModuleDependencies} from '../src/index.js';

const stream=[
  '{"meta":{"exporter":{"name":"test","version":"1"},"lean":{"githash":"test","version":"4.34.0"},"format":{"version":"3.1.0"}}}',
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
assert.equal(loaded.payloadKind,'lean4export-ndjson');
if(loaded.payloadKind!=='lean4export-ndjson')throw new Error('expected v1 replay');
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

{
  const env=new Environment();
  const A=nameFromDotted('Native.A');
  const aName=nameFromDotted('Native.a');
  const id=nameFromDotted('Native.id');
  env.add({
    kind:'axiom',
    name:A,
    levelParams:[],
    type:sort(levelSucc(levelZero)),
  });
  env.add({
    kind:'axiom',
    name:aName,
    levelParams:[],
    type:constant(A),
  });
  const artifact=createCheckedModuleArtifact({
    module:'Native.Test',
    admissions:[{
      kind:'constant',
      declaration:{
        kind:'definition',
        name:id,
        levelParams:[],
        type:constant(A),
        value:constant(aName),
        hints:{kind:'regular',height:1n},
        safety:'safe',
      },
    }],
  });
  assert.equal(artifact.version,2);
  assert.equal(
    artifact.payload.kind,
    'proofscript-checked-admissions-json',
  );
  const encoded=encodeModuleArtifact(artifact);
  const decoded=decodeModuleArtifact(encoded);
  assert.equal(decoded.version,2);
  const loaded=loadModuleArtifact(decoded,{env});
  assert.equal(
    loaded.payloadKind,
    'proofscript-checked-admissions-json',
  );
  if(loaded.payloadKind!=='proofscript-checked-admissions-json'){
    throw new Error('expected native admission replay');
  }
  assert.equal(loaded.admissions,1);
  assert.equal(loaded.env.find(id)?.kind,'definition');
  const tampered=structuredClone(artifact);
  tampered.payload.text=tampered.payload.text.replace(
    '"Native"',
    '"Tampered"',
  );
  assert.throws(
    ()=>verifyModuleArtifact(tampered),
    /payload integrity mismatch/,
  );
  const wrongKernel={
    ...artifact,
    kernel:{...artifact.kernel,apiVersion:'999'},
  };
  const body={
    ...wrongKernel,
    integrity:undefined,
  };
  void body;
  assert.equal(moduleArtifactSummary(artifact).format,'proofscript-module@2');
}
console.log('ok - @proofscript/module checked-admission artifact v2');
