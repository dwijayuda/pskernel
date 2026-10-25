// Installed adapter and fail-closed protocol preflight against preserved G3.
// New-source IO application/package qualification is recorded separately.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { spawnSync } from 'node:child_process';
const out = path.resolve('dist/slim-universal');
const assembly = JSON.parse(fs.readFileSync(path.join(out, 'package-receipt.json')));
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'proofscript-io-preflight-'));
fs.writeFileSync(path.join(temporary, 'package.json'), '{"private":true,"type":"module"}\n');
const npm = path.resolve(path.dirname(process.execPath), '../lib/node_modules/npm/bin/npm-cli.js');
const env = { ...process.env, PATH: path.dirname(process.execPath) };
for (const key of Object.keys(env))
  if (key === 'NODE_OPTIONS' || key.startsWith('PSC1_') || key === 'LEAN_PATH' ||
      key === 'ELAN_TOOLCHAIN' || key === 'LD_LIBRARY_PATH' || key === 'DYLD_LIBRARY_PATH')
    delete env[key];
const result = spawnSync(process.execPath, [npm, 'install', '--prefix', temporary,
  '--cache', path.join(temporary, 'cache'), '--offline', '--registry', 'http://127.0.0.1:9',
  '--ignore-scripts', '--no-audit', '--no-fund', path.join(out, 'tarballs', assembly.tarball)], {
  cwd: temporary, env, encoding: 'utf8', timeout: 240000, maxBuffer: 32 * 1024 * 1024,
});
assert.equal(result.status, 0, result.stdout + result.stderr);
const consumer = path.join(temporary, 'consumer.mjs');
fs.writeFileSync(consumer,
  "import assert from 'node:assert/strict';\nimport fs from 'node:fs';\nimport path from 'node:path';\n" +
  "import {createTypedIo,withTypedIo} from 'proofscript/io';\nimport {compile,getCompilerMetadata} from 'proofscript';\n" +
  "const root=path.resolve('io');fs.mkdirSync(root);fs.writeFileSync(path.join(root,'input.txt'),'λ🙂');\n" +
  "const inputFd=fs.openSync('/dev/null','r'),outputFd=fs.openSync(path.join(root,'stdout.txt'),'w');\n" +
  "const config={abi:'psc1-node-linux-string-io/1',capabilities:['readUtf8','writeUtf8'],required:['readUtf8'],root,maxFileBytes:128,maxLineBytes:128,inputFd,outputFd};\n" +
  "const io=createTypedIo(config);assert.deepEqual(JSON.parse(io.execute(JSON.stringify({op:'readUtf8',path:'input.txt'}))),{kind:'text',text:'λ🙂'});\n" +
  "assert.deepEqual(JSON.parse(io.execute(JSON.stringify({op:'writeUtf8',path:'output.txt',text:'ok:λ🙂'}))),{kind:'unit'});assert.equal(fs.readFileSync(path.join(root,'output.txt'),'utf8'),'ok:λ🙂');\n" +
  "assert.deepEqual(JSON.parse(io.execute(JSON.stringify({op:'writeUtf8',path:'../outside.txt',text:'denied'}))),{kind:'error',error:'pathDenied'});assert.equal(fs.existsSync('outside.txt'),false);io.close();\n" +
  "assert.throws(()=>io.execute('{}'),/PSC1_IO_CLOSED/);let loaded=false;await assert.rejects(withTypedIo({...config,capabilities:[]},()=>{loaded=true;},()=>{}),/PSC1_IO_REQUIRED_CAPABILITY_DENIED/);assert.equal(loaded,false);\n" +
  "const options={entryModule:'Entry',sources:[{module:'Entry',kind:'lean',text:'def run (input : String) (dispatch : String -> String) : String := dispatch input\\n'}]};\n" +
  "assert.throws(()=>compile({...options,outputAbi:'arbitrary'}),/PSC1_UNIVERSAL_OUTPUT_ABI/);\n" +
  "if(getCompilerMetadata().compilerSourceClosureDigest==='07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af')assert.throws(()=>compile({...options,outputAbi:'io-dispatcher'}),/PSC1_SERVICE_COMPILER_REFUSED:wire/);\n" +
  "fs.closeSync(inputFd);fs.closeSync(outputFd);console.log(JSON.stringify({adapter:'installed proofscript/io',runtime:'executed',deniedLoaderNotCalled:true,unknownAbiRefused:true,compilerSourceClosureDigest:getCompilerMetadata().compilerSourceClosureDigest,newSourceIoQualification:'separate'}));\n");
const execution = spawnSync(process.execPath, [consumer], {
  cwd: temporary, env, encoding: 'utf8', timeout: 240000, maxBuffer: 32 * 1024 * 1024,
});
assert.equal(execution.status, 0, execution.stdout + execution.stderr);
const receipt = { schema: 'psc1-installed-io-adapter-preflight/1', testedCommit: process.env.GITHUB_SHA,
  status: 'passed', tarballSha256: assembly.sha256, ...JSON.parse(execution.stdout) };
fs.writeFileSync(path.join(out, 'io-adapter-preflight.json'), JSON.stringify(receipt, null, 2) + '\n');
console.log('PSC1_INSTALLED_IO_ADAPTER_PREFLIGHT: ' + JSON.stringify(receipt));
