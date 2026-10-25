// Host boundary fixtures replay native-prepared data; this is NOT a generated
// compiler semantics test. Actual G1 is exercised by generated-compiler-diagnostic.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { createGeneratedJsCompilerSession } from '../host-tools/generated-compiler-session.mjs';
import { compilerSourceClosureDigest } from '../host-tools/compiler-host-protocol.mjs';

const root = process.cwd();
const directory = path.join(root, 'dist/generated-session-boundary');
fs.mkdirSync(directory, { recursive: true });
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const source = [{ module: 'Entry', kind: 'lean', text: 'def answer : Nat := 42\n' }];
const digest = compilerSourceClosureDigest(source);
const input = path.join(directory, 'fixture.request.json');
const output = path.join(directory, 'fixture.candidate.json');
fs.writeFileSync(input, JSON.stringify(['psc1-compiler-service/1', 'fixture', digest,
  'lean', 'checked', 'Entry', source.map(row => [row.module, row.text])]));
const seeded = spawnSync(path.join(root, '.lake/build/bin/psc1_js_service_seed'), [input, output],
  { encoding: 'utf8', timeout: 240000, maxBuffer: 32 * 1024 * 1024 });
assert.equal(seeded.error, undefined);
assert.equal(seeded.status, 0, seeded.stderr);
const base = JSON.parse(fs.readFileSync(output, 'utf8'));
assert.equal(base.status, 'candidate');
const checker = path.join(directory, 'checker');
fs.copyFileSync(path.join(root, '.lake/build/bin/psc1_independent_checker'), checker);
fs.chmodSync(checker, 0o755);
const checkerHash = sha(fs.readFileSync(checker));
const runnerSource = path.join(root, 'scripts/generated-compiler-runner.mjs');
const runner = path.join(directory, 'runner.mjs');
fs.copyFileSync(runnerSource, runner);
const runnerHash = sha(fs.readFileSync(runner));
const publicationRoot = path.join(directory, 'publication');
let serial = 0;
const records = [];
function fixtureSession(mutate = '', capture = source, serviceDependencies = [], additionalCheckers = []) {
  const id = 'host-fixture-' + serial++;
  const file = path.join(directory, id + '.mjs');
  fs.writeFileSync(file, 'const template=' + JSON.stringify(base) + ';\n' +
    'export function psCompilerJsServiceCandidate(input){' +
    'const request=JSON.parse(input); const value=structuredClone(template);' +
    'value.requestId=request[1];value.sourceClosureDigest=request[2];' +
    'value.grammar=request[3];value.assurance=request[4];' +
    'value.admissionRequest.requestId=request[1];' +
    'value.admissionRequest.sourceClosureDigest=request[2];' +
    mutate + ';return JSON.stringify(value);}\n');
  const session = createGeneratedJsCompilerSession({ requestId: id, sources: capture,
    entryModule: 'Entry', assurance: 'checked', serviceFile: file,
    serviceSha256: sha(fs.readFileSync(file)), runnerFile: runner, runnerSha256: runnerHash,
    checkerExecutable: checker, checkerSha256: checkerHash, publicationRoot, serviceDependencies, additionalCheckers });
  return { session, file };
}
function pointer() {
  const file = path.join(publicationRoot, 'current');
  return fs.existsSync(file) ? fs.readlinkSync(file) : null;
}
function failClosed(name, action) {
  const prior = pointer();
  action();
  assert.equal(pointer(), prior, name + ' preserves prior publication');
  records.push({ name, status: 'passed', previousPublication: 'preserved' });
}
const originalSources = structuredClone(source);
const good = fixtureSession('', originalSources);
originalSources[0].text = 'def answer : Nat := 0\n';
assert.throws(() => good.session.publish(), /PSC1_SERVICE_NOT_ADMITTED/);
const prepared = good.session.execute();
assert.equal(prepared.logicalAdmission, 'accepted');
assert.equal(prepared.sourceClosureDigest, digest, 'host source snapshot is immutable');
assert.throws(() => good.session.execute(), /PSC1_SERVICE_SESSION_CONSUMED/);
const published = good.session.publish();
assert.equal(good.session.state, 'published');
assert.equal(pointer(), 'generations/' + published.generation);
const runTarget = spawnSync(process.execPath, ['--input-type=module', '-e',
  'import {pathToFileURL} from "node:url"; const m=await import(pathToFileURL(process.argv[1]).href);' +
  'if(m.answer!==42n)throw Error("wrong answer");', published.target], { encoding: 'utf8' });
assert.equal(runTarget.status, 0, runTarget.stderr);
assert.throws(() => good.session.publish(), /PSC1_SERVICE_NOT_ADMITTED/);
records.push({ name: 'actual official admission, target check and atomic publication', status: 'passed' });

for (const [name, mutate, expected] of [
  ['stale request', 'value.requestId="stale"', /PSC1_SERVICE_RESPONSE_MISMATCH/],
  ['stale source capture', 'value.sourceClosureDigest="stale"', /PSC1_SERVICE_RESPONSE_MISMATCH/],
  ['wrong assurance', 'value.assurance="ordinary-checked"', /PSC1_SERVICE_RESPONSE_MISMATCH/],
  ['injected checker selector', 'value.checkerExecutable="/bin/true"', /PSC1_SERVICE_RESPONSE_FIELDS/],
  ['fabricated acceptance', 'value.accepted=true', /PSC1_SERVICE_RESPONSE_FIELDS/],
  ['invalid exact graph', 'value.admissionRequest.admissions="{\\"schema\\":\\"invalid-admissions\\"}"', /PSC1_CHECKER_REJECTED/],
  ['invalid target syntax', 'value.source="export const = ;"', /PSC1_SERVICE_PROCESS_FAILED:target-syntax/],
  ['extra target export', 'value.source+="\\nexport const unplanned=0n;\\n"', /PSC1_SERVICE_PROCESS_FAILED:target-public-api/]
]) {
  failClosed(name, () => {
    const { session } = fixtureSession(mutate);
    assert.throws(() => session.execute(), expected);
    assert.equal(session.state, 'rejected');
    assert.throws(() => session.publish(), /PSC1_SERVICE_NOT_ADMITTED/);
  });
}
for (const [name, change] of [
  ['candidate bytes changed', stage => fs.appendFileSync(path.join(stage, 'candidate.json'), '\n')],
  ['target bytes changed', stage => fs.appendFileSync(path.join(stage, 'target.mjs'), '\n')],
  ['original IR bytes changed', stage => fs.appendFileSync(path.join(stage, 'original-ir.json'), '\n')],
  ['logical graph bytes changed', stage => fs.appendFileSync(path.join(stage, 'admissions.json'), '\n')],
  ['missing IR artifact', stage => fs.unlinkSync(path.join(stage, 'original-ir.json'))],
  ['extra artifact', stage => fs.writeFileSync(path.join(stage, 'extra.json'), '{}')],
  ['symlinked artifact', stage => {
    fs.unlinkSync(path.join(stage, 'target.mjs'));
    fs.symlinkSync(published.target, path.join(stage, 'target.mjs'));
  }]
]) {
  failClosed(name, () => {
    const { session } = fixtureSession();
    session.execute();
    change(session.stagingDirectory);
    assert.throws(() => session.publish(), /PSC1_SERVICE_ARTIFACT_CHANGED|PSC1_SERVICE_STAGED_FILE_INVALID/);
    assert.equal(session.state, 'rejected');
  });
}
failClosed('service changed before execution', () => {
  const { session, file } = fixtureSession();
  fs.appendFileSync(file, '\n');
  assert.throws(() => session.execute(), /PSC1_SERVICE_TOOL_IDENTITY_CHANGED/);
  assert.throws(() => session.publish(), /PSC1_SERVICE_NOT_ADMITTED/);
});
failClosed('runner changed before execution', () => {
  const { session } = fixtureSession();
  fs.appendFileSync(runner, '\n');
  assert.throws(() => session.execute(), /PSC1_SERVICE_TOOL_IDENTITY_CHANGED/);
  fs.copyFileSync(runnerSource, runner);
});
failClosed('service changed after admission', () => {
  const { session, file } = fixtureSession();
  session.execute();
  fs.appendFileSync(file, '\n');
  assert.throws(() => session.publish(), /PSC1_SERVICE_TOOL_IDENTITY_CHANGED/);
});
failClosed('checker changed after admission', () => {
  const { session } = fixtureSession();
  session.execute();
  fs.appendFileSync(checker, '\n');
  assert.throws(() => session.publish(), /PSC1_SERVICE_TOOL_IDENTITY_CHANGED/);
  fs.copyFileSync(path.join(root, '.lake/build/bin/psc1_independent_checker'), checker);
});
for (const phase of ['before-seal', 'after-seal', 'before-commit']) {
  failClosed('publication fault ' + phase, () => {
    const { session } = fixtureSession();
    session.execute();
    process.env.PSC1_TEST_SERVICE_PUBLICATION_FAIL_AT = phase;
    try { assert.throws(() => session.publish(), /PSC1_SERVICE_INJECTED_PUBLICATION_FAILURE/); }
    finally { delete process.env.PSC1_TEST_SERVICE_PUBLICATION_FAIL_AT; }
  });
}
const first = fixtureSession(), stale = fixtureSession();
first.session.execute(); stale.session.execute();
const next = first.session.publish();
assert.notEqual(next.generation, published.generation);
failClosed('stale prior-publication session', () =>
  assert.throws(() => stale.session.publish(), /PSC1_SERVICE_PRIOR_PUBLICATION_CHANGED/));
assert.ok(fs.existsSync(path.join(published.directory, 'target.mjs')), 'old immutable generation retained');
assert.equal(fs.existsSync(path.join(publicationRoot, '.publish.lock')), false);
// Imported engine files are host-pinned resources, never wire-selected tools.
const dependency=path.join(directory,'engine-dependency.mjs');
fs.writeFileSync(dependency,'export const value=42;\n');
const dependencyPin={path:dependency,sha256:sha(fs.readFileSync(dependency))};
failClosed('imported engine changed before execution',()=>{
 const {session}=fixtureSession('',source,[dependencyPin]);
 fs.appendFileSync(dependency,' ');
 assert.throws(()=>session.execute(),/PSC1_SERVICE_TOOL_IDENTITY_CHANGED/);
 fs.writeFileSync(dependency,'export const value=42;\n');
});
failClosed('imported engine changed after admission',()=>{
 const {session}=fixtureSession('',source,[dependencyPin]);
 session.execute();fs.appendFileSync(dependency,' ');
 assert.throws(()=>session.publish(),/PSC1_SERVICE_TOOL_IDENTITY_CHANGED/);
 fs.writeFileSync(dependency,'export const value=42;\n');
});
assert.throws(()=>fixtureSession('',source,{}),/PSC1_SERVICE_DEPENDENCIES_INVALID/);
assert.throws(()=>fixtureSession('',source,[{path:dependency,sha256:'0'.repeat(64)}]),/PSC1_SERVICE_TOOL_IDENTITY_CHANGED/);
// Additional providers are trusted host-selected tools, never generated selectors.
const extraScript=path.join(directory,'additional-real-checker.mjs');
const realExtra="import fs from 'node:fs';import {spawnSync} from 'node:child_process';"+
 "const r=spawnSync("+JSON.stringify(checker)+",['--check'],{input:fs.readFileSync(0),encoding:'utf8',timeout:120000,maxBuffer:32*1024*1024});"+
 "if(r.error||r.status!==0)process.exit(1);process.stdout.write(r.stdout);";
fs.writeFileSync(extraScript,realExtra);
const extraDescriptor=()=>[{name:'second-native-reference',scriptFile:extraScript,scriptSha256:sha(fs.readFileSync(extraScript))}];
const additionalGood=fixtureSession('',source,[],extraDescriptor()),additionalPrepared=additionalGood.session.execute();
assert.equal(additionalPrepared.additionalAdmissions.length,1);
assert.equal(additionalPrepared.additionalAdmissions[0].admissionsSha256,additionalPrepared.admissionsSha256);
additionalGood.session.publish();
records.push({name:'additional real native checker receives identical captured admissions',status:'passed',wasmAcceptanceClaim:false});
for(const [name,program,error] of [
 ['additional checker rejects',"console.log(JSON.stringify({protocol:'pskernel-lean/1',provider:'lean4-cpp',leanVersion:'4.35.0',leanCommit:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',profile:'lean4.35-core',accepted:false}));",/PSC1_SERVICE_ADDITIONAL_CHECKER_REFUSED/],
 ['additional checker wrong identity',"console.log(JSON.stringify({accepted:true,leanCommit:'wrong'}));",/PSC1_SERVICE_ADDITIONAL_CHECKER_REFUSED/],
 ['additional checker malformed response',"console.log('{');",/PSC1_SERVICE_ADDITIONAL_CHECKER_JSON/],
 ['additional checker process failure',"process.exit(1);",/PSC1_SERVICE_ADDITIONAL_CHECKER_PROCESS/]
]){
 fs.writeFileSync(extraScript,program);
 failClosed(name,()=>{const {session}=fixtureSession('',source,[],extraDescriptor());assert.throws(()=>session.execute(),error);assert.throws(()=>session.publish(),/PSC1_SERVICE_NOT_ADMITTED/);});
}
fs.writeFileSync(extraScript,realExtra);
failClosed('additional checker changed after admission',()=>{const {session}=fixtureSession('',source,[],extraDescriptor());session.execute();fs.appendFileSync(extraScript,' ');assert.throws(()=>session.publish(),/PSC1_SERVICE_TOOL_IDENTITY_CHANGED/);fs.writeFileSync(extraScript,realExtra);});
assert.throws(()=>fixtureSession('',source,[],{}),/PSC1_SERVICE_ADDITIONAL_CHECKERS_INVALID/);

fs.unlinkSync(checker); // retain the exact binary hash, not a duplicate checker executable
fs.writeFileSync(path.join(directory, 'results.json'), JSON.stringify({
  schema: 'psc1-generated-session-boundary/1', commit: process.env.GITHUB_SHA,
  scope: 'host boundary; native-prepared fixture replay service, not actual G1',
  checkerCommit: 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',
  records, generations: [published.generation, next.generation]
}, null, 2) + '\n');
console.log('PSC1_GENERATED_SESSION_BOUNDARY: ' + JSON.stringify({ checks: records.length,
  status: 'passed', actualGeneratedCompilerSemantics: 'separate-diagnostic' }));
