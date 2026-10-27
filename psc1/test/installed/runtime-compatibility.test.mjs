import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import {spawn} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {fixture} from './cli-fixture.mjs';
const f = fixture(), cases = [];
const actual = JSON.parse(f.ok(f.runtime, [...f.flags, '-e', 'console.log(JSON.stringify(process.versions))']));
for (const name of ['psc', 'psc1', 'proofscript']) {
  const bin = path.join(f.directory, 'node_modules/.bin', name);
  assert.match(f.ok(f.runtime, [...f.flags, bin, '--help']), /--watch/);
}
if (process.env.PSC1_EXPECT_RUNTIME_REFUSAL === '1') {
  const denied = f.call(['--identity','--diagnostics=json']);
  assert.notEqual(denied.status,0);assert.match(denied.stderr,/PSC1_RUNTIME_VERSION/);
  fs.mkdirSync('dist/cli/runtime',{recursive:true});
  fs.writeFileSync('dist/cli/runtime/'+(actual.bun?'bun-'+actual.bun:'node-'+actual.node)+'-refusal.json',JSON.stringify({
    schema:'psc1-runtime-compatibility/1',status:'passed-negative',versions:actual,
    executable:f.runtime,executableSha256:crypto.createHash('sha256').update(fs.readFileSync(f.runtime)).digest('hex'),
    diagnostic:denied.stderr,testedCommit:process.env.GITHUB_SHA},null,2));
  fs.rmSync(f.directory,{recursive:true,force:true});
  console.log('PSC1_RUNTIME_MINIMUM_REFUSAL: PASS');process.exit(0);
}
const identity = JSON.parse(f.invoke(['--identity']));
assert.equal(identity.defaultKernel, 'wasm');
for (const kind of ['ps', 'lean']) {
  const source = path.join(f.directory, 'Main.' + kind);
  fs.writeFileSync(source, 'def answer : Nat := 42\n');
  for (const engine of ['js', 'ts', 'rust', 'wasm-core']) {
    const result = JSON.parse(f.invoke(['compile', source, '--engine', engine]));
    assert.equal(result.logicalAdmission, 'accepted');
    assert.deepEqual(result.kernelProviders, ['wasm']);
    const target = path.join(f.directory, 'observed-' + kind + '-' + engine + '.mjs');
    fs.writeFileSync(target, result.source);
    const answer = f.ok(f.runtime, [...f.flags, '--input-type=module', '-e',
      'const m=await import(' + JSON.stringify(pathToFileURL(target).href) + ');console.log(String(m.answer));']).trim();
    assert.equal(answer, '42');
    cases.push({kind, engine, actualOutput: answer, logicalAdmission: result.logicalAdmission,
      runtimeRequest: result.receipt.request});
  }
  const store = path.join(f.directory, 'store-' + kind);
  const built = JSON.parse(f.invoke(['build', source, '--out', store, '--publication-protocol', 'portable-file']));
  assert.equal(f.observe(built), '42');
  const pointer = fs.readFileSync(path.join(store, 'current.json'));
  fs.writeFileSync(source, 'def answer : Nat := true\n');
  const rejected = f.call(['build', source, '--out', store, '--publication-protocol', 'portable-file']);
  assert.notEqual(rejected.status, 0);
  assert.deepEqual(fs.readFileSync(path.join(store, 'current.json')), pointer);
}
const invalid = path.join(f.directory, 'invalid-admissions.json');
fs.writeFileSync(invalid, 'this is not canonical admission');
const rejected = f.call(['kernel', 'check', invalid]);
assert.notEqual(rejected.status, 0, rejected.stdout);
assert.doesNotMatch(rejected.stdout, /"accepted":true/);
const watchCases = [];
for (const kind of ['ps','lean']) {
  const dir=path.join(f.directory,'watch-'+kind);fs.mkdirSync(dir);
  const source=path.join(dir,'Main.'+kind),out=path.join(dir,'out');
  fs.writeFileSync(source,'def answer : Nat := 42\n');
  const child=spawn(f.runtime,[...f.flags,f.cli,'build',source,'--out',out,
    '--publication-protocol','portable-file','--watch','--diagnostics=json'],
    {cwd:dir,env:f.env,stdio:['ignore','pipe','pipe']});
  let stdout='',stderr='',closed=false,exit;const receipts=[];
  child.stdout.on('data',chunk=>{
    stdout+=chunk;assert.ok(stdout.length<32*1024*1024);
    for(;;){const n=stdout.indexOf('\n');if(n<0)break;const line=stdout.slice(0,n);
      stdout=stdout.slice(n+1);if(line)receipts.push(JSON.parse(line));}
  });
  child.stderr.on('data',chunk=>{stderr+=chunk;assert.ok(stderr.length<32*1024*1024);});
  child.on('close',code=>{closed=true;exit=code;});
  async function wait(predicate,limit=240000){
    const start=Date.now();while(!predicate()){
      assert.equal(closed,false,stderr);
      if(Date.now()-start>limit)throw Error('RUNTIME_WATCH_TIMEOUT '+stderr);
      await new Promise(resolve=>setTimeout(resolve,20));
    }
  }
  try{
    await wait(()=>receipts.length>=1);assert.equal(f.observe(receipts[0]),'42');
    fs.writeFileSync(source,'def answer : Nat := 43\n');
    await wait(()=>receipts.length>=2);assert.equal(f.observe(receipts[1]),'43');
    const pointer=fs.readFileSync(path.join(out,'current.json'));
    fs.writeFileSync(source,'def answer : Nat := true\n');
    await wait(()=>stderr.includes('failed; waiting for changes'));
    assert.deepEqual(fs.readFileSync(path.join(out,'current.json')),pointer);
    child.kill('SIGINT');
    await wait(()=>closed,6000);assert.equal(exit,130,stderr);
    watchCases.push({kind,initial:42,edited:43,illTypedPreservesPointer:true,signalExit:exit});
  }finally{if(!closed)child.kill('SIGTERM');}
}
const result = {schema: 'psc1-runtime-compatibility/1', status: 'passed', testedCommit: process.env.GITHUB_SHA,
  executable: f.runtime, executableSha256: crypto.createHash('sha256').update(fs.readFileSync(f.runtime)).digest('hex'), versions: actual, engines: ['js','ts','rust','wasm-core'], cases,
  watchCases, bothGrammars: true, independentWasmKernel: true, malformedAdmissionRefused: true,
  failedBuildPreservesPointer: true, performanceQualification: 'not-requested'};
fs.mkdirSync('dist/cli/runtime', {recursive:true});
fs.writeFileSync('dist/cli/runtime/' + (actual.bun ? 'bun-' + actual.bun : 'node-' + actual.node) + '.json',
  JSON.stringify(result, null, 2) + '\n');
console.log('PSC1_RUNTIME_COMPATIBILITY ' + JSON.stringify(result));
fs.rmSync(f.directory, {recursive:true, force:true});
