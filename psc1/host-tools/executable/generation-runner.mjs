// Generated compiler execution only; all semantic work belongs to its modules.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {loadExecutableCompiler} from './loader.mjs';
import {quarantineCandidate} from './quarantine.mjs';
const config=JSON.parse(fs.readFileSync(process.argv[2],'utf8'));
const request=fs.readFileSync(config.requestFile,'utf8');
assert.ok(Buffer.byteLength(request)<=33554432);
const compiler=await loadExecutableCompiler(config.engine);
const candidate=compiler.candidate(request);
const report=quarantineCandidate(candidate,config.directory);
compiler.verify();
console.log('PSC1_MODULAR_GENERATED_CANDIDATE '+JSON.stringify({...report,identity:compiler.identity}));

