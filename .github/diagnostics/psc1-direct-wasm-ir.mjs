import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';
import {sha,boundedRun} from '../../psc1/host-tools/generated-target-tools.mjs';
import {compilerSourceClosureDigest} from '../../psc1/host-tools/compiler-host-protocol.mjs';
const request=JSON.parse(fs.readFileSync('../.github/diagnostics/psc1-direct-wasm-ir.json'));
function walk(root){return fs.readdirSync(root,{withFileTypes:true}).flatMap(e=>{const f=path.join(root,e.name);assert.equal(e.isSymbolicLink(),false);return e.isDirectory()?walk(f):[f];});}
const files=walk('../input/direct-wasm'),reports=files.filter(f=>path.basename(f)==='qualification.json');assert.equal(reports.length,1);
const directory=path.dirname(reports[0]),report=JSON.parse(fs.readFileSync(reports[0]));
assert.equal(report.testedCommit,request.requestCommit);assert.equal(report.target,'wasm-core');
assert.equal(report.status,'failed');assert.deepEqual(report.generations,[]);
const input=path.resolve(directory,'G1-bootstrap.request.json'),bytes=fs.readFileSync(input),wire=JSON.parse(bytes);
assert.equal(wire[1],'G1-bootstrap');
assert.equal(compilerSourceClosureDigest(wire[6].map(([module,text])=>({module,kind:wire[3],text}))),request.closure);
const out=path.resolve('dist/direct-wasm-ir-diagnosis');fs.mkdirSync(out,{recursive:true});
const result=boundedRun(path.resolve('.lake/build/bin/psc1_direct_wasm_ir_probe'),[input,path.join(out,'findings.json')],{timeoutMs:240000,logDirectory:path.join(out,'process')});
assert.equal(result.status,0,result.stderr);console.log(result.stdout);
const findings=JSON.parse(fs.readFileSync(path.join(out,'findings.json')));assert.equal(findings.accepted,false);
assert.equal(findings.sourceClosureDigest,request.closure);assert.ok(findings.findingCount>0);
fs.writeFileSync(path.join(out,'receipt.json'),JSON.stringify({schema:'psc1-direct-wasm-ir-diagnosis-receipt/1',
 request,requestSha256:sha(bytes),testedCommit:process.env.GITHUB_SHA,qualification:false,
 elapsedMs:result.elapsedMs,maxRssKiB:result.maxRssKiB,peakTreeRssKiB:result.peakTreeRssKiB,findings},null,2)+'\n');
