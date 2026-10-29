// Reuse the admitted native G1 oracle; generate/check portable G1 once.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';
import{readQualifiedArtifact}from'../../psc1/scripts/kernel435-qualified-artifact.mjs';
import{readOwnedCompilerSources}from'../../psc1/host-tools/compiler-source-inputs.mjs';
const q=JSON.parse(fs.readFileSync('docs/PSC1_WIRE_TRANSPORT_QUALIFICATION_2026-10-29.json'));
const archive=await readQualifiedArtifact(q.generatedQualification,'dist/wire-selfhost-native-input');
const input=path.join(archive,'executable-packages/compiler');
assert.deepEqual(JSON.parse(fs.readFileSync(path.join(input,'build-receipt.json'))),q.generatedBuild);
const sources=readOwnedCompilerSources('Ps.CompilerUnified.Service').map(row=>({module:row.module,kind:'lean',text:row.text}));
assert.deepEqual(JSON.parse(fs.readFileSync(path.join(input,'sources.json'))),sources);
fs.mkdirSync('dist/executable-packages',{recursive:true});assert.ok(!fs.existsSync('dist/executable-packages/compiler'));
fs.cpSync(input,'dist/executable-packages/compiler',{recursive:true});
console.log('PSC1_WIRE_GENERATION_ORACLE '+JSON.stringify({sourceDigest:q.generatedBuild.sourceClosureDigest,nativeOracleCommit:q.generatedQualification.commit,currentSourceCommit:process.env.GITHUB_SHA,nativeOracleNotExecuted:true}));
