// Generate IO candidates without compiler SDKs on the executor path, then use
// separate pinned target consumers. Candidate APIs themselves grant no admission.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { spawnSync } from 'node:child_process';
import { consumeIoCandidates } from './io-candidate-consumers.mjs';
const out = path.resolve('dist/slim-universal');
const assembly = JSON.parse(fs.readFileSync(path.join(out, 'package-receipt.json')));
assert.ok(assembly.input.qualifiedCompilerGenerations);
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'proofscript-io-mappings-'));
fs.writeFileSync(path.join(work, 'package.json'), '{"private":true,"type":"module"}\n');
const npm = path.resolve(path.dirname(process.execPath), '../lib/node_modules/npm/bin/npm-cli.js');
const env = { ...process.env, PATH: path.dirname(process.execPath) };
for (const key of Object.keys(env))
  if (key === 'NODE_OPTIONS' || key.startsWith('PSC1_') || key === 'LEAN_PATH' ||
      key === 'ELAN_TOOLCHAIN' || key === 'LD_LIBRARY_PATH' || key === 'DYLD_LIBRARY_PATH' ||
      key === 'PSC_LEAN_KERNEL_PROVIDER_BIN') delete env[key];
function run(args) {
  const result = spawnSync(process.execPath, args, { cwd: work, env, encoding: 'utf8',
    timeout: 240000, maxBuffer: 32 * 1024 * 1024 });
  assert.equal(result.error, undefined, String(result.error));
  assert.equal(result.status, 0, result.stdout + result.stderr);
  return result.stdout;
}
const packages = [path.join(out, 'tarballs', assembly.tarball),
  ...['rust', 'wasm-core', 'nativeKernel'].map(key =>
    path.join(out, 'tarballs', assembly.input.packages[key].tarball))];
run([npm, 'install', '--prefix', work, '--cache', path.join(work, 'empty-cache'),
  '--offline', '--registry', 'http://127.0.0.1:9', '--ignore-scripts', '--no-audit', '--no-fund', ...packages]);
const resultsFile = path.join(work, 'candidates.json'), program = path.join(work, 'produce.mjs');
fs.writeFileSync(program,
  "import assert from 'node:assert/strict';\nimport fs from 'node:fs';\nimport {compileCandidate,checkCanonicalAdmissions} from 'proofscript';\n" +
  "const rows=[];for(const engine of ['js','ts','rust','wasm-core'])for(const kind of ['lean','ps']){" +
  "const text=kind==='lean'?'def run (input : String) (dispatch : String -> String) : String := dispatch input\\n':'def run(input : String, dispatch : String -> String) : String := dispatch(input)\\n';" +
  "const options={engine,entryModule:'Entry',sources:[{module:'Entry',kind,text}],outputAbi:'io-dispatcher'};" +
  "for(const target of ['js','ts','rust','wasm-core']){const result=compileCandidate({...options,target}),candidate=result.candidate;" +
  "assert.equal(result.publicationAuthority,false);assert.equal(result.logicalAdmission,'not-run');" +
  "if(target==='wasm-core'){assert.equal(candidate.status,'refused');assert.equal(candidate.code,'PSC1_IO_DISPATCHER_ABI_TARGET_UNSUPPORTED');assert.equal(candidate.source,undefined);rows.push({engine,kind,target,refused:true});continue;}" +
  "assert.equal(candidate.status,'candidate');assert.equal(candidate.protocol,'psc1-compiler-service/2');assert.equal(candidate.outputAbi,'io-dispatcher');assert.equal(candidate.target,target);assert.equal(candidate.admission,'not-run');" +
  "assert.deepEqual(candidate.publicNames,['run']);const admitted=await checkCanonicalAdmissions(candidate.admissionRequest.admissions,{provider:'both'});assert.equal(admitted.accepted,true);assert.equal(admitted.agreement,true);" +
  "rows.push({engine,kind,target,source:candidate.source,publicNames:candidate.publicNames,admissionsSha256:admitted.admissionsSha256,kernels:['wasm','native']});}}" +
  "fs.writeFileSync(" + JSON.stringify(resultsFile) + ",JSON.stringify(rows));\n");
run([program]);
const rows = JSON.parse(fs.readFileSync(resultsFile));
const records = consumeIoCandidates(rows, path.join(out, 'io-candidate-consumers'));
assert.equal(records.filter(row => row.runtime === 'executed').length, 24);
assert.equal(records.filter(row => row.refused).length, 8);
fs.writeFileSync(path.join(out, 'io-candidate-qualification.json'), JSON.stringify({
  schema: 'psc1-installed-io-candidates/1', testedCommit: process.env.GITHUB_SHA,
  compilerSourceClosureDigest: assembly.compilerSourceClosureDigest, status: 'passed',
  tarballSha256: assembly.sha256, records, checkedNonJsPublication: false,
  executorSdkRequirement: false, pinnedTargetConsumers: true, npmPublication: false,
}, null, 2) + '\n');
console.log('PSC1_INSTALLED_IO_CANDIDATES: PASS ' + JSON.stringify({ executed: 24, refused: 8 }));
