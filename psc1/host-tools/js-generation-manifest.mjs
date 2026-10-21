// Data verification only. Publication still requires private live host session state.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const fail = code => { throw new Error(code); };

export function verifyGeneratedBundle(directory, expectedManifestSha256, expectedRequest) {
  if (!fs.lstatSync(path.join(directory,'manifest.json')).isFile())
    fail('PSC1_GENERATION_MANIFEST_CHANGED');
  const bytes = fs.readFileSync(path.join(directory, 'manifest.json'));
  if (sha(bytes) !== expectedManifestSha256) fail('PSC1_GENERATION_MANIFEST_CHANGED');
  const manifest = JSON.parse(bytes.toString('utf8'));
  if (manifest.schema !== 'psc1-generated-service-bundle/1' ||
      JSON.stringify(manifest.request) !== JSON.stringify(expectedRequest))
    fail('PSC1_GENERATION_CONTEXT_CHANGED');
  const names = ['admissions.json','candidate.json','original-ir.json','request.json',
    'session.json','sources.json','specialized-ir.json','target.mjs'].sort();
  if (JSON.stringify(manifest.files.map(row => row.path).sort()) !== JSON.stringify(names) ||
      JSON.stringify(fs.readdirSync(directory).sort()) !== JSON.stringify([...names,'manifest.json'].sort()))
    fail('PSC1_GENERATION_INVENTORY_CHANGED');
  for (const row of manifest.files) {
    const file = path.join(directory, row.path), stat = fs.lstatSync(file);
    if (!stat.isFile() || stat.size !== row.bytes || sha(fs.readFileSync(file)) !== row.sha256)
      fail('PSC1_GENERATION_ARTIFACT_CHANGED');
  }
  return manifest; // This return value has no publication/admission capability.
}

export function assertJsGeneration(manifest, expected) {
  const legacyCases=['lean-modules','ps-integer-unicode','lean-handler-pattern','lean-ordinary-loop',
    'wrong-body','missing-import','checked-partial','verified'];
  const schemas={
    'psc1-js-generation/4.35.0-v1':legacyCases,
    'psc1-js-generation/4.35.0-v2':[...legacyCases,'ps-list-literal','malformed-list']
  };
  const schema=Object.hasOwn(expected,'generationSchema')?expected.generationSchema:'psc1-js-generation/4.35.0-v1';
  if (typeof schema !== 'string' || !Object.hasOwn(schemas,schema) || manifest.schema !== schema ||
      manifest.logicalCheckerCommit !== 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc' ||
      manifest.target !== 'js' || manifest.grammar !== 'lean' ||
      manifest.assurance !== 'ordinary-checked' || manifest.behaviorallyVerified !== false ||
      !Number.isInteger(manifest.generation) || manifest.generation < 1 || manifest.generation > 3)
    fail('PSC1_GENERATION_SCHEMA');
  for (const field of ['sourceClosureDigest','sourceInventorySha256','serviceSha256',
      'admissionsSha256','originalIrSha256','specializedIrSha256','checkerSha256','runnerSha256',
      'nodeSha256','corpusObservationsSha256','hostControllerSha256','nativeSeedSha256']) {
    if (!/^[0-9a-f]{64}$/.test(manifest[field] || '') || manifest[field] !== expected[field])
      fail('PSC1_GENERATION_IDENTITY_CHANGED:' + field);
  }
  if (sha(JSON.stringify(manifest.sourceInventory)) !== manifest.sourceInventorySha256 ||
      sha(JSON.stringify(manifest.observations)) !== manifest.corpusObservationsSha256 ||
      sha(JSON.stringify(manifest.hostModuleInventory)) !== manifest.hostControllerSha256)
    fail('PSC1_GENERATION_CONTENT_CHANGED');
  const requiredCases=[...schemas[schema]].sort();
  if (JSON.stringify(manifest.observations.map(row=>row.id).sort()) !== JSON.stringify(requiredCases))
    fail('PSC1_GENERATION_CORPUS_CHANGED');
  const producer=manifest.producer;
  if (!producer || (manifest.generation === 1 ?
      producer.kind !== 'native-stage0' || producer.sha256 !== expected.nativeSeedSha256 :
      producer.kind !== 'generated-js' || producer.generation !== manifest.generation-1 ||
        producer.sha256 !== expected.serviceSha256))
    fail('PSC1_GENERATION_PRODUCER_CHANGED');
  if (JSON.stringify(manifest.publicNames) !== '["psCompilerJsServiceCandidate"]')
    fail('PSC1_GENERATION_API');
  return true; // Identity/corpus data, never a formal preservation certificate.
}

export function checkGenerationRefusals({ directory, publication, request, manifest, expected, work }) {
  const initial = sha(fs.readFileSync(path.join(directory, 'target.mjs')));
  for (const field of ['sourceClosureDigest','admissionsSha256','originalIrSha256',
      'specializedIrSha256','serviceSha256','checkerSha256','runnerSha256','nodeSha256',
      'corpusObservationsSha256']) {
    assert.throws(() => assertJsGeneration({ ...manifest, [field]:'0'.repeat(64) }, expected),
      /PSC1_GENERATION_IDENTITY_CHANGED/);
  }
  assert.throws(() => assertJsGeneration({ ...manifest, schema:'historical-lean434-wasm' }, expected),
    /PSC1_GENERATION_SCHEMA/);
  const mutations = [
    ['missing', copy => fs.unlinkSync(path.join(copy,'original-ir.json'))],
    ['extra', copy => fs.writeFileSync(path.join(copy,'unplanned.txt'),'unplanned')],
    ['graph', copy => fs.appendFileSync(path.join(copy,'admissions.json'),'\n')],
    ['artifact', copy => fs.appendFileSync(path.join(copy,'target.mjs'),'\n')],
    ['manifest', copy => fs.appendFileSync(path.join(copy,'manifest.json'),'\n')]
  ];
  fs.mkdirSync(work, { recursive:true });
  for (const [name, mutate] of mutations) {
    const copy = path.join(work,name);
    fs.cpSync(directory,copy,{recursive:true,errorOnExist:true,force:false});
    mutate(copy);
    assert.throws(() => verifyGeneratedBundle(copy, publication.manifestSha256, request),
      /PSC1_GENERATION_(INVENTORY|ARTIFACT|MANIFEST)_CHANGED/);
  }
  assert.throws(() => verifyGeneratedBundle(directory,publication.manifestSha256,
    {...request,checkerSha256:'0'.repeat(64)}), /PSC1_GENERATION_CONTEXT_CHANGED/);
  assert.equal(sha(fs.readFileSync(path.join(directory,'target.mjs'))),initial);
  verifyGeneratedBundle(directory,publication.manifestSha256,request);
  return { staleIdentityCases:9, staleSchemaCases:1, actualFileMutationCases:5,
    checkerContextCases:1, originalPublishedArtifact:'preserved' };
}
