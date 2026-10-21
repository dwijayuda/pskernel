// Actual generated compiler semantics with host-session publication into a CI store.
// Native stage0 is called exactly once. Afterwards only generated services,
// the independent Core checker, and target tools may execute.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';
import { createCompilerHostSession, compilerSourceClosureDigest } from '../host-tools/compiler-host-protocol.mjs';
import { createGeneratedJsCompilerSession } from '../host-tools/generated-compiler-session.mjs';
import { verifyGeneratedBundle, assertJsGeneration, checkGenerationRefusals } from '../host-tools/js-generation-manifest.mjs';
import { validateClosureCounts } from './compiler-closure-contract.mjs';

const mode = process.argv[2] || '--g1-only';
assert.ok(['--g1-only','--self-host'].includes(mode), 'PSC1_UNKNOWN_GENERATION_MODE');
const selfHost = mode === '--self-host';
const root = process.cwd();
assert.ok(process.env.GITHUB_SHA, 'PSC1_GENERATED_REQUIRES_CLOUD_COMMIT');
const directory = path.join(root, 'dist/generated-compiler');
fs.mkdirSync(directory, { recursive: true });
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const events = [];
let nativeAllowed = true, seedCalls = 0;
const checker = path.join(root, '.lake/build/bin/psc1_independent_checker');
const checkerHash = sha(fs.readFileSync(checker));
const seed = path.join(root, '.lake/build/bin/psc1_js_service_seed');
const seedHash = sha(fs.readFileSync(seed));
const runner = path.join(root, 'scripts/generated-compiler-runner.mjs');
const runnerHash = sha(fs.readFileSync(runner));
const nodeHash = sha(fs.readFileSync(process.execPath));
const hostModuleInventory = ['scripts/generated-compiler-diagnostic.mjs',
  'host-tools/generated-compiler-session.mjs','host-tools/js-generation-manifest.mjs',
  'host-tools/compiler-host-protocol.mjs','scripts/compiler-closure-contract.mjs'].map(file =>
    ({path:file,sha256:sha(fs.readFileSync(path.join(root,file)))}));
const hostControllerHash = sha(JSON.stringify(hostModuleInventory));
function verifyFixedTools() {
  assert.equal(sha(fs.readFileSync(checker)),checkerHash,'checker unchanged');
  assert.equal(sha(fs.readFileSync(runner)),runnerHash,'runner unchanged');
  assert.equal(sha(fs.readFileSync(process.execPath)),nodeHash,'Node unchanged');
  for (const file of hostModuleInventory)
    assert.equal(sha(fs.readFileSync(path.join(root,file.path))),file.sha256,'host controller unchanged');
}
function run(role, executable, args) {
  if (!['stage0-seed', 'generated-service', 'target-check', 'target-execution'].includes(role) ||
      (role === 'stage0-seed' && (!nativeAllowed || seedCalls !== 0)))
    throw new Error('PSC1_NATIVE_COMPILER_DELEGATION_FORBIDDEN');
  if (role === 'stage0-seed') {
    assert.equal(sha(fs.readFileSync(seed)),seedHash);
    seedCalls++;
  }
  if (role !== 'stage0-seed' && executable !== process.execPath)
    throw new Error('PSC1_GENERATED_TOOL_NOT_ALLOWED');
  verifyFixedTools();
  const started = Date.now();
  const result = spawnSync(executable, args, { cwd: root, encoding: 'utf8',
    timeout: 240000, maxBuffer: 32 * 1024 * 1024 });
  verifyFixedTools();
  events.push({ role, executable, args, status: result.status, signal: result.signal,
    elapsedMs: Date.now() - started, error: result.error?.message || null });
  return result;
}
function successful(result, code) {
  if (result.error || result.status !== 0)
    throw new Error(code + ': ' + (result.error?.message || result.stderr || result.stdout));
}
function encodeRequest(id, grammar, assurance, entry, sources) {
  const captured = sources.map(source => ({ module: source.module, kind: grammar, text: source.text }));
  const digest = compilerSourceClosureDigest(captured);
  return { id, grammar, assurance, entry, sources: captured, digest,
    text: JSON.stringify(['psc1-compiler-service/1', id, digest, grammar, assurance, entry,
      sources.map(source => [source.module, source.text])]) };
}
function readCandidate(file) {
  const stat = fs.statSync(file);
  assert.ok(stat.size > 0 && stat.size <= 128 * 1024 * 1024, 'bounded staged candidate file');
  const bytes = fs.readFileSync(file);
  return { text: bytes.toString('utf8'), digest: sha(bytes), value: JSON.parse(bytes.toString('utf8')) };
}
function checkCandidate(candidate, request, serviceIdentity) {
  const value = candidate.value;
  console.log('PSC1_COMPILER_CANDIDATE_STAGE: ' + JSON.stringify({ requestId: request.id,
    status: value.status, phase: value.phase, code: value.code, module: value.module,
    declaration: value.declaration, line: value.line, column: value.column }));
  assert.equal(value.status, 'candidate', JSON.stringify({ status: value.status,
    phase: value.phase, code: value.code, module: value.module, declaration: value.declaration }));
  assert.equal(value.protocol, 'psc1-compiler-service/1');
  assert.equal(value.requestId, request.id);
  assert.equal(value.sourceClosureDigest, request.digest);
  assert.equal(value.target, 'js');
  assert.equal(value.grammar, request.grammar);
  assert.equal(value.assurance, request.assurance);
  assert.equal(value.candidateOnly, true);
  assert.equal(value.admission, 'not-run');
  assert.equal(value.origins.length, request.sources.length);
  let sourceCount = 0;
  value.origins.forEach((row, index) => {
    assert.equal(row[0], request.sources[index].module);
    assert.equal(row[1], Buffer.byteLength(request.sources[index].text));
    row[3].forEach((origin, sourceIndex) => {
      assert.equal(origin[0], sourceIndex);
      assert.equal(typeof origin[1], 'string');
      origin[4].forEach((member, memberIndex) => {
        assert.equal(member[0], memberIndex);
        assert.equal(typeof member[1], 'string');
        sourceCount++;
      });
    });
  });
  validateClosureCounts({ assurance: value.assurance,
    sourceCoreDeclarations: value.sourceDeclarations,
    coreDeclarations: value.logicalDeclarations, partialNames: value.partialNames },
    sourceCount, value.assurance);
  for (const graph of [value.originalIr, value.specializedIr]) {
    assert.ok(Array.isArray(graph) && graph.length === 5 && graph[0] === 'psc1-ir/1');
    assert.ok(graph.slice(1).every(Array.isArray));
  }
  assert.equal(typeof value.source, 'string');
  assert.ok(value.source.length > 0);
  assert.ok(Array.isArray(value.publicNames) && new Set(value.publicNames).size === value.publicNames.length);
  assert.equal(sha(fs.readFileSync(checker)), checkerHash);
  const session = createCompilerHostSession({ requestId: request.id, target: 'js',
    sources: request.sources, canonicalAdmissions: value.admissionRequest.admissions,
    checkerExecutable: checker });
  events.push({ role: 'independent-checker', executable: checker, args: ['--check'],
    checkerSha256: checkerHash, requestId: request.id, graphSha256: sha(value.admissionRequest.admissions),
    serviceIdentity, stage: 'before' });
  const receipt = session.admit(JSON.stringify(value.admissionRequest));
  assert.equal(receipt.accepted, true);
  assert.equal(sha(fs.readFileSync(checker)), checkerHash);
  events.push({ role: 'independent-checker', executable: checker, args: ['--check'],
    requestId: request.id, stage: 'accepted', checkerCommit: receipt.checkerCommit });
  return { requestId: request.id, sourceClosureDigest: request.digest, serviceIdentity,
    candidateSha256: candidate.digest, admissionsSha256: receipt.admissionsDigest,
    originalIrSha256: sha(JSON.stringify(value.originalIr)),
    specializedIrSha256: sha(JSON.stringify(value.specializedIr)),
    sourceSha256: sha(value.source), originalDeclarations: value.originalIr[4].length,
    specializedDeclarations: value.specializedIr[4].length, publicNames: value.publicNames,
    runtimeRequirements: value.runtimeRequirements, assurance: value.assurance,
    logicalAdmission: 'accepted', originalIr: 'validated-by-qualified-compiler-service',
    specializedIr: 'validated-by-qualified-compiler-service',
    behaviorallyVerified: false, productionPublication: 'not-run' };
}
function writeTarget(value, destination) {
  fs.writeFileSync(destination, value.source);
  successful(run('target-check', process.execPath, ['--check', destination]), 'PSC1_TARGET_SYNTAX_REFUSED');
  assert.equal(sha(fs.readFileSync(destination)), sha(value.source));
}
function generated(request, id, servicePath = g1Path, serviceHash = g1Hash) {
  const requestPath = path.join(directory, id + '.request.json');
  const responsePath = path.join(directory, id + '.candidate.json');
  fs.writeFileSync(requestPath, request.text);
  const result = run('generated-service', process.execPath,
    [runner, servicePath, serviceHash, requestPath, responsePath]);
  successful(result, 'PSC1_GENERATED_COMPILER_PROCESS_FAILED');
  const execution = JSON.parse(result.stdout.trim());
  const candidate = readCandidate(responsePath);
  assert.equal(execution.protocol, 'psc1-generated-service-run/1');
  assert.equal(execution.serviceSha256, serviceHash);
  assert.equal(execution.requestSha256, sha(request.text));
  assert.equal(execution.responseSha256, candidate.digest);
  return { candidate, execution };
}

let report = { schema: 'psc1-generated-compiler-diagnostic/1', commit: process.env.GITHUB_SHA,
  qualificationMode: mode, authoritative: false, generatedCompilerExecution: 'not-run', selfCompilation: 'not-run',
  fixedPoint: 'not-run', productionPublication: 'not-run', formalPreservation: 'not-provided',
  nativeSeedSha256: seedHash, checkerSha256: checkerHash, events, cases: [] };
let g1Path, g1Hash;
try {
  const census = JSON.parse(fs.readFileSync(path.join(root,
    'dist/scoped-correctness/compiler-source-census/inventory.json'), 'utf8'));
  assert.equal(census.commit, process.env.GITHUB_SHA);
  const phase = census.phases.find(phase => phase.name === 'directjs-compiler');
  assert.deepEqual(phase.roots, ['Ps.BackendJs.CompilerService']);
  const index = new Map(census.modules.map(row => [row.name, row]));
  const sources = phase.modules.map(name => {
    assert.ok(!name.startsWith('Ps.Host.') && !name.startsWith('PsKernelLean') &&
      !name.startsWith('Ps.Bootstrap') && name !== 'Main', 'no native frontend/service import');
    const entry = index.get(name);
    assert.ok(entry && entry.path.startsWith('packages/') &&
      !entry.path.includes('/pskernel-lean/') && !entry.path.includes('/cli/'));
    const bytes = fs.readFileSync(path.join(root, entry.path));
    assert.equal(bytes.length, entry.utf8Bytes);
    assert.equal(sha(bytes), entry.sha256);
    return { module: name, text: bytes.toString('utf8') };
  });
  const bootstrap = encodeRequest('G1-bootstrap', 'lean', 'ordinary-checked',
    'Ps.BackendJs.CompilerService', sources);
  const input = path.join(directory, 'G1-bootstrap.request.json');
  const output = path.join(directory, 'G1-bootstrap.candidate.json');
  fs.writeFileSync(input, bootstrap.text);
  successful(run('stage0-seed', seed, [input, output]), 'PSC1_STAGE0_SERVICE_SEED_FAILED');
  const initial = readCandidate(output);
  report.bootstrap = checkCandidate(initial, bootstrap, { kind: 'native-stage0', sha256: seedHash });
  g1Path = path.join(directory, 'G1.mjs');
  writeTarget(initial.value, g1Path);
  g1Hash = sha(fs.readFileSync(g1Path));
  report.service = { generation: 1, sha256: g1Hash, export: 'psCompilerJsServiceCandidate',
    sourceClosureDigest: bootstrap.digest, sourceModules: sources.length,
    candidateAdmission: report.bootstrap.admissionsSha256,
    canonicalOriginalIr: report.bootstrap.originalIrSha256,
    canonicalSpecializedIr: report.bootstrap.specializedIrSha256 };
  assert.deepEqual(initial.value.publicNames, ['psCompilerJsServiceCandidate']);
  nativeAllowed = false;
  const disabled = path.join(root, '.lake/build/disabled-native-compiler-tools');
  fs.mkdirSync(disabled, { recursive: true });
  for (const name of fs.readdirSync(path.join(root, '.lake/build/bin'))) {
    if (name === 'psc1_independent_checker') continue;
    const from = path.join(root, '.lake/build/bin', name);
    if (fs.statSync(from).isFile()) fs.renameSync(from, path.join(disabled, name));
  }
  assert.equal(fs.existsSync(seed), false);
  assert.throws(() => run('stage0-seed', seed, [input, output]),
    /PSC1_NATIVE_COMPILER_DELEGATION_FORBIDDEN/);
  assert.throws(() => run('native-frontend', 'lean', []),
    /PSC1_NATIVE_COMPILER_DELEGATION_FORBIDDEN/);
  report.nativeDelegationBoundary = 'seed-once; native tools disabled; frontend role refused';
  const corpus = [
    { id: 'lean-modules', grammar: 'lean', assurance: 'checked', entry: 'Entry',
      sources: [{ module: 'Lib', text: 'namespace Lib\ndef base : Nat := 40\nend Lib\n' },
        { module: 'Entry', text: 'import Lib\ndef Ps.Internal.Corpus.hidden : Nat := Lib.base\ndef answer : Nat := Ps.Internal.Corpus.hidden + 2\n' }],
      consumer: "if (m.answer !== 42n || Object.keys(m).join(',') !== 'answer') throw Error('module/private ownership');" },
    { id: 'ps-integer-unicode', grammar: 'ps', assurance: 'checked', entry: 'Entry',
      sources: [{ module: 'Entry', text: 'def huge : Int := -9007199254740993123456789\ndef text : String := "λ🙂"\n' }],
      consumer: "if (m.huge !== -9007199254740993123456789n || m.text !== 'λ🙂') throw Error('integer/unicode');" },
    { id: 'ps-list-literal', grammar: 'ps', assurance: 'checked', entry: 'Entry',
      sources: [{ module: 'Entry', text: 'def answer(flag : Bool) : Nat :=\n let values : List(Nat) := if (flag) { [7, 11] } else { [] }\n match values with { | List.nil => 0 | List.cons head rest => head }\n' }],
      consumer: "if (m.answer(false) !== 0n || m.answer(true) !== 7n) throw Error('PS list literal');" },
    { id: 'lean-handler-pattern', grammar: 'lean', assurance: 'checked', entry: 'Entry',
      sources: [{ module: 'Entry', text: 'def Ps.Internal.Corpus.guarded (fail : Bool) : Except Nat Nat := do\n  try\n    if fail then throw 7 else pure 3\n  catch error =>\n    pure (error + 1)\ndef observe (fail : Bool) : Nat :=\n  match Ps.Internal.Corpus.guarded fail with\n  | Except.ok value => value\n  | Except.error error => error\n' }],
      consumer: "if (m.observe(false) !== 3n || m.observe(true) !== 8n) throw Error('handler/pattern');" },
    { id: 'lean-ordinary-loop', grammar: 'lean', assurance: 'ordinary-checked', entry: 'Entry',
      sources: [{ module: 'Entry', text: 'partial def answer (limit : Nat) : Id Nat := do\n  let mut value : Nat := 0\n  while Nat.blt value limit do\n    value := Nat.succ value\n  return value\n' }],
      consumer: "if (m.answer(5n) !== 5n) throw Error('ordinary loop');" }
  ];
  const observedExpressions = {
    'lean-modules':'({answer:String(m.answer),exports:Object.keys(m)})',
    'ps-integer-unicode':'({huge:String(m.huge),text:m.text})',
    'ps-list-literal':'({empty:String(m.answer(false)),first:String(m.answer(true))})',
    'lean-handler-pattern':'({normal:String(m.observe(false)),caught:String(m.observe(true))})',
    'lean-ordinary-loop':'({zero:String(m.answer(0n)),five:String(m.answer(5n))})'
  };
  const expectedObservations = {
    'lean-modules':{answer:'42',exports:['answer']},
    'ps-integer-unicode':{huge:'-9007199254740993123456789',text:'λ🙂'},
    'ps-list-literal':{empty:'0',first:'7'},
    'lean-handler-pattern':{normal:'3',caught:'8'},
    'lean-ordinary-loop':{zero:'0',five:'5'}
  };
  function exercise(servicePath, serviceIdentity, label) {
    const observations=[];
  for (const item of corpus) {
    const request = encodeRequest(label + '-' + item.id, item.grammar, item.assurance, item.entry, item.sources);
    verifyFixedTools();
    const session = createGeneratedJsCompilerSession({ requestId: request.id,
      sources: request.sources, entryModule: request.entry, assurance: request.assurance,
      serviceFile: servicePath, serviceSha256: serviceIdentity.sha256, runnerFile: runner,
      runnerSha256: runnerHash, checkerExecutable: checker,
      checkerSha256: checkerHash, publicationRoot: path.join(directory, 'publication', label + '-' + item.id) });
    let checked, publication;
    try { checked = session.execute(); publication = session.publish(); }
    finally { events.push(...session.events); }
    verifyFixedTools();
    const target = publication.target;
    const consumer = path.join(directory, label + '-' + item.id + '-consumer.mjs');
    fs.writeFileSync(consumer, "import * as m from " + JSON.stringify(
      pathToFileURL(target).href) + ";\n" + item.consumer + '\nconsole.log(JSON.stringify(' + observedExpressions[item.id] + '));\n');
    const observationRun = run('target-execution', process.execPath, [consumer]);
    successful(observationRun, 'PSC1_GENERATED_CORPUS_OBSERVATION_FAILED');
    const observation = JSON.parse(observationRun.stdout.trim());
    assert.deepEqual(observation,expectedObservations[item.id]);
    observations.push({id:item.id,grammar:item.grammar,assurance:item.assurance,
      sourceClosureDigest:checked.sourceClosureDigest,admissionsSha256:checked.admissionsSha256,
      originalIrSha256:checked.originalIrSha256,specializedIrSha256:checked.specializedIrSha256,
      sourceSha256:checked.sourceSha256,observation});
    report.generatedCompilerExecution = 'partial-selected-corpus';
    report.cases.push({ generation:label, ...checked, publication, observation, targetExecution: 'passed',
      productionPublication: 'host-session-published-ci-store' });
    console.log('PSC1_REAL_GENERATED_COMPILER_CASE: ' + JSON.stringify({ generation:label,id: item.id,
      elapsedMs: checked.execution.elapsedMs, maxRssKiB: checked.execution.maxRssKiB,
      sourceSha256: checked.sourceSha256, publicationGeneration: publication.generation }));
  }
  for (const item of [
    { id: 'malformed-list', grammar: 'ps', assurance: 'checked', source: 'def value : List(Nat) := [1,,2]\n', phase: 'parse' },
    { id: 'wrong-body', grammar: 'lean', assurance: 'checked', source: 'def bad : Nat := true\n', phase: 'elaboration' },
    { id: 'missing-import', grammar: 'ps', assurance: 'checked', source: 'import Missing\ndef value : Nat := 1\n', phase: 'capture' },
    { id: 'checked-partial', grammar: 'lean', assurance: 'checked', source: 'partial def spin (n : Nat) : Nat := spin n\n', phase: 'preparation' },
    { id: 'verified', grammar: 'ps', assurance: 'verified', source: 'def value : Nat := 1\n', phase: 'wire' }
  ]) {
    const request = encodeRequest(item.id, item.grammar, item.assurance, 'Entry', [{ module: 'Entry', text: item.source }]);
    const { candidate, execution } = generated(request, label + '-' + item.id, servicePath, serviceIdentity.sha256);
    assert.equal(candidate.value.status, 'refused');
    assert.equal(candidate.value.phase, item.phase);
    assert.equal(candidate.value.admission, 'not-run');
    assert.equal(candidate.value.source, undefined);
    observations.push({id:item.id,grammar:item.grammar,refused:true,phase:item.phase,code:candidate.value.code});
    report.cases.push({ generation:label,requestId: request.id, generatedRefusal: 'passed', phase: item.phase, execution });
  }

    return observations;
  }
  const sourceInventory = sources.map(row => ({module:row.module,grammar:'lean',
    bytes:Buffer.byteLength(row.text),sha256:sha(row.text)}));
  const sourceInventoryHash = sha(JSON.stringify(sourceInventory));
  const firstObservations = exercise(g1Path,report.service,'G1');
  report.generatedCompilerExecution='passed-G1-selected-corpus';
  report.completedCorpusGenerations=[1];
  const observationsHash = sha(JSON.stringify(firstObservations));
  const expectedIdentity = {
    sourceClosureDigest:bootstrap.digest,sourceInventorySha256:sourceInventoryHash,
    serviceSha256:g1Hash,admissionsSha256:report.bootstrap.admissionsSha256,
    originalIrSha256:report.bootstrap.originalIrSha256,
    specializedIrSha256:report.bootstrap.specializedIrSha256,
    checkerSha256:checkerHash,runnerSha256:runnerHash,nodeSha256:nodeHash,
    corpusObservationsSha256:observationsHash,hostControllerSha256:hostControllerHash,
    nativeSeedSha256:seedHash
  };
  function saveGeneration(generation, producer, identity, publication, observations) {
    const manifest={schema:'psc1-js-generation/4.35.0-v1',generation,
      testedCommit:process.env.GITHUB_SHA,branchHead:process.env.PSC1_BRANCH_HEAD||null,
      logicalCheckerCommit:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',
      target:'js',grammar:'lean',assurance:'ordinary-checked',behaviorallyVerified:false,
      ...expectedIdentity,...identity,producer,publicNames:['psCompilerJsServiceCandidate'],
      sourceInventory,hostModuleInventory,publication,observations,claim:'bounded JS identities and actual corpus; no preservation theorem'};
    assertJsGeneration(manifest,expectedIdentity);
    const file=path.join(directory,'G'+generation+'.manifest.json');
    fs.writeFileSync(file,JSON.stringify(manifest,null,2)+'\n');
    return manifest;
  }
  const firstManifest=saveGeneration(1,{kind:'native-stage0',sha256:seedHash},{},
    {kind:'checked-native-bootstrap-ci-staging',file:g1Path},firstObservations);
  report.generations=[firstManifest];
  let servicePath=g1Path,serviceIdentity=report.service;
  const generationRoot=path.join(directory,'compiler-generations');
  for (const generation of (selfHost ? [2,3] : [])) {
    const request=encodeRequest('G'+generation+'-self','lean','ordinary-checked',
      'Ps.BackendJs.CompilerService',sources);
    verifyFixedTools();
    const session=createGeneratedJsCompilerSession({requestId:request.id,sources:request.sources,
      entryModule:request.entry,assurance:request.assurance,serviceFile:servicePath,
      serviceSha256:serviceIdentity.sha256,runnerFile:runner,runnerSha256:runnerHash,
      checkerExecutable:checker,checkerSha256:checkerHash,publicationRoot:generationRoot});
    const attempt={generation,producer:serviceIdentity.sha256,sourceClosureDigest:bootstrap.digest,
      requestSha256:sha(request.text),status:'started'};
    (report.generationAttempts ||= []).push(attempt);
    report.selfCompilation='attempting-G'+generation;
    let compiled,publication;
    try {
      compiled=session.execute();
      for (const [field,value] of Object.entries({sourceClosureDigest:bootstrap.digest,
        sourceSha256:g1Hash,admissionsSha256:expectedIdentity.admissionsSha256,
        originalIrSha256:expectedIdentity.originalIrSha256,
        specializedIrSha256:expectedIdentity.specializedIrSha256}))
        assert.equal(compiled[field],value,'PSC1_GENERATION_BEFORE_PUBLICATION:'+field);
      assert.deepEqual(compiled.publicNames,['psCompilerJsServiceCandidate']);
      publication=session.publish();
      verifyGeneratedBundle(publication.directory,publication.manifestSha256,session.request);
    } finally {
      events.push(...session.events);
      attempt.events=session.events;
      attempt.failureDirectory=session.failureDirectory;
      if (!publication) attempt.status='failed-before-publication';
    }
    attempt.status='published-identities-matched-pending-corpus';
    attempt.execution=compiled.execution;
    const nextService={generation,sha256:compiled.sourceSha256,
      export:'psCompilerJsServiceCandidate',sourceClosureDigest:bootstrap.digest,sourceModules:sources.length};
    const nextPath=path.join(publication.directory,'target.mjs');
    const observations=exercise(nextPath,nextService,'G'+generation);
    assert.deepEqual(observations,firstObservations,'identical actual corpus observations/graphs/artifacts');
    const manifest=saveGeneration(generation,{kind:'generated-js',generation:generation-1,
      sha256:serviceIdentity.sha256},{serviceSha256:compiled.sourceSha256},
      publication,observations);
    manifest.negativeBoundaries=checkGenerationRefusals({directory:publication.directory,publication,
      request:session.request,manifest,expected:expectedIdentity,
      work:path.join(directory,'generation-refusals','G'+generation)});
    fs.writeFileSync(path.join(directory,'G'+generation+'.manifest.json'),
      JSON.stringify(manifest,null,2)+'\n');
    report.generations.push(manifest);
    report.completedCorpusGenerations.push(generation);
    report.generatedCompilerExecution='passed-through-G'+generation+'-selected-corpus';
    attempt.status='passed';attempt.execution=compiled.execution;
    report.selfCompilation='passed-through-G'+generation;
    console.log('PSC1_ACTUAL_JS_GENERATION: '+JSON.stringify({generation,
      serviceSha256:compiled.sourceSha256,elapsedMs:compiled.execution.elapsedMs,
      maxRssKiB:compiled.execution.maxRssKiB,admissionsSha256:compiled.admissionsSha256,
      originalIrSha256:compiled.originalIrSha256,specializedIrSha256:compiled.specializedIrSha256,
      corpusCases:observations.length,negativeBoundaries:manifest.negativeBoundaries}));
    servicePath=nextPath;serviceIdentity=nextService;
  }
  if (selfHost) report.fixedPoint='passed-G1-G2-G3-exact-graphs-IR-source-and-selected-observations';
  assert.equal(seedCalls, 1);
  report.generatedCompilerExecution = selfHost ? 'passed-G1-G2-G3-selected-corpus' : 'passed-G1-selected-corpus';
  report.selfCompilation = selfHost ? 'passed-G1-to-G2-to-G3' : 'deferred-manual-qualification';
  if (!selfHost) report.fixedPoint = 'deferred-feature-freeze';
  report.productionPublication = 'host-session-published-selected-corpus-ci-store';
  report.status = 'passed-diagnostic';
} catch (error) {
  report.status = 'failed';
  report.failure = error.message;
  throw error;
} finally {
  report.completedAt = new Date().toISOString();
  fs.writeFileSync(path.join(directory, 'diagnostic.json'), JSON.stringify(report, null, 2) + '\n');
  console.log('PSC1_GENERATED_COMPILER_DIAGNOSTIC: ' + JSON.stringify({ status: report.status,
    generatedCompilerExecution: report.generatedCompilerExecution, selfCompilation: report.selfCompilation,
    fixedPoint: report.fixedPoint, failure: report.failure, service: report.service, cases: report.cases.length,
    completedCorpusGenerations:report.completedCorpusGenerations,generationAttempts:report.generationAttempts }));
}
