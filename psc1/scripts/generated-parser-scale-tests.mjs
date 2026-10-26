// Optional Linux CI performance probe; separate from the frozen generation corpus.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
import {spawnSync} from 'node:child_process';
import {createGeneratedJsCompilerSession} from '../host-tools/generated-compiler-session.mjs';
assert.ok(process.env.GITHUB_SHA,'Linux CI source identity required');
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const root=path.resolve('dist/generated-parser-scale');
fs.mkdirSync(root,{recursive:true});
const read=p=>JSON.parse(fs.readFileSync(p,'utf8'));
const diagnostic=read('dist/generated-compiler/diagnostic.json');
const manifest=read('dist/generated-compiler/G1.manifest.json');
assert.equal(diagnostic.commit,process.env.GITHUB_SHA);
assert.ok(diagnostic.completedCorpusGenerations.includes(1));
const service=path.resolve('dist/generated-compiler/G1.mjs');
const checker=path.resolve('.lake/build/bin/psc1_independent_checker');
const runner=path.resolve('host-tools/execution/generated-service-runner.mjs');
assert.equal(sha(fs.readFileSync(service)),manifest.serviceSha256);
assert.equal(sha(fs.readFileSync(checker)),manifest.checkerSha256);
assert.equal(sha(fs.readFileSync(runner)),manifest.runnerSha256);
assert.equal(sha(fs.readFileSync(process.execPath)),manifest.nodeSha256);
const text=fs.readFileSync('test/applications/ParserScale/Program.lean','utf8');
const session=createGeneratedJsCompilerSession({requestId:'G1-parser-scale',grammar:'lean',
 sources:[{module:'Entry',kind:'lean',text}],entryModule:'Entry',assurance:'checked',
 serviceFile:service,serviceSha256:manifest.serviceSha256,runnerFile:runner,
 runnerSha256:manifest.runnerSha256,checkerExecutable:checker,checkerSha256:manifest.checkerSha256,
 publicationRoot:path.join(root,'publication')});
let report={schema:'psc1-generated-parser-scale/1',testedCommit:process.env.GITHUB_SHA,
 status:'failed',scope:'Lean/JS generated frontend scale probe; not fixed-point corpus or whole-language qualification',
 privateSuffixDeclarations:256,processDeadlineMs:240000,sourceSha256:sha(text),
 nativeCompilerDelegation:false,serviceSha256:manifest.serviceSha256};
try{
 const checked=session.execute(),publication=session.publish();
 const file=path.join(root,'consumer.mjs');
 fs.writeFileSync(file,"import assert from 'node:assert/strict';\nimport * as m from "+
  JSON.stringify(pathToFileURL(publication.target).href)+
  ";\nassert.equal(m.answer,42n);assert.deepEqual(Object.keys(m),['answer']);"+
  "console.log(JSON.stringify({answer:String(m.answer),exports:Object.keys(m)}));\n");
 const result=spawnSync(process.execPath,[file],{encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});
 assert.equal(result.status,0,result.stderr);
 assert.deepEqual(JSON.parse(result.stdout.trim()),{answer:'42',exports:['answer']});
 report={...report,status:'passed',checked,publication};
}finally{
 report.events=session.events;
 fs.writeFileSync(path.join(root,'results.json'),JSON.stringify(report,null,2)+'\n');
 console.log('PSC1_GENERATED_PARSER_SCALE: '+JSON.stringify(report));
}
