import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import assert from 'node:assert/strict';
import { compilerSourceClosureDigest } from '../host-tools/compiler-host-protocol.mjs';
const [implementationArg, referenceArg, outputArg, label] = process.argv.slice(2);
const implementation = path.resolve(implementationArg), reference = path.resolve(referenceArg);
const directory = path.resolve(outputArg);
fs.mkdirSync(directory, { recursive: true });
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const lake = fs.readFileSync(path.join(reference, 'lakefile.lean'), 'utf8');
const index = new Map();
for (const match of lake.matchAll(/lean_lib\s+(\w+)\s+where\n([\s\S]*?)(?=\n(?:lean_|@)|$)/g)) {
  const sourceDirectory = match[2].match(/srcDir\s*:=\s*"([^"]+)"/)?.[1];
  if (!sourceDirectory) continue;
  for (const item of match[2].matchAll(/`([\w.]+)/g)) {
    const module = item[1], relative = path.join(sourceDirectory, ...module.split('.')) + '.lean';
    const text = fs.readFileSync(path.join(reference, relative), 'utf8');
    const imports = [...text.matchAll(/^import\s+(.+)$/gm)].flatMap(m => m[1].trim().split(/\s+/));
    index.set(module, { module, text, imports, relative });
  }
}
const sources = [], visiting = new Set(), visited = new Set();
function visit(name) {
  assert.ok(!visiting.has(name), 'acyclic capture');
  if (visited.has(name)) return;
  const row = index.get(name);
  assert.ok(row && row.relative.startsWith('packages/') && !name.startsWith('Ps.Host.') &&
    !name.startsWith('PsKernelLean'), 'portable source ownership');
  visiting.add(name);
  row.imports.forEach(visit);
  visiting.delete(name); visited.add(name);
  sources.push({ module: name, kind: 'lean', text: row.text });
}
visit('Ps.BackendJs.CompilerService');
const digest = compilerSourceClosureDigest(sources);
const request = JSON.stringify(['psc1-compiler-service/1','fixed-adcb-profile',digest,
  'lean','ordinary-checked','Ps.BackendJs.CompilerService',sources.map(row => [row.module,row.text])]);
const input = path.join(directory, 'request.json'), output = path.join(directory, 'profile.json');
fs.writeFileSync(input, request);
const binary = path.join(implementation, '.lake/build/bin/psc1_compiler_profile');
const start = performance.now();
const result = spawnSync(binary, [input,output],
  { encoding: 'utf8', timeout: 240000, maxBuffer: 32 * 1024 * 1024 });
process.stdout.write(result.stdout || '');
process.stderr.write(result.stderr || '');
const records = fs.existsSync(output) ? JSON.parse(fs.readFileSync(output,'utf8')) : [];
if (records.at(-1)?.phase === 'profile-complete') {
  const graph = fs.readFileSync(output + '.admissions.json', 'utf8');
  const requestModel = JSON.parse(request);
  const expected = JSON.stringify({ admissions: graph, op: 'admit', protocol:'psc1-compiler-host/1',
    requestId:requestModel[1],sourceClosureDigest:requestModel[2],target:'js' });
  assert.equal(fs.readFileSync(output + '.admission-request.json','utf8'), expected,
    'whole admission transport bytes equal independent ECMAScript JSON serializer');
  assert.equal(fs.readFileSync(output + '.source-quoted.json','utf8'),
    JSON.stringify(fs.readFileSync(output + '.source.mjs','utf8')));
  const candidate = JSON.parse(fs.readFileSync(output + '.candidate.json','utf8'));
  assert.equal(candidate.status,'candidate');
  assert.equal(candidate.admissionRequest.admissions,graph);
  assert.equal(JSON.stringify(candidate.originalIr),fs.readFileSync(output+'.original-ir.json','utf8'));
  assert.equal(JSON.stringify(candidate.specializedIr),fs.readFileSync(output+'.closed-ir.json','utf8'));
  assert.equal(candidate.source,fs.readFileSync(output+'.source.mjs','utf8'));
}
const identities = {};
for (const name of ['original-ir.json','specialized-ir.json','closed-ir.json','source.mjs','admissions.json']) {
  const file = output + '.' + name;
  if (fs.existsSync(file)) identities[name] = sha(fs.readFileSync(file));
}
const processStatus = fs.existsSync(output + '.proc-status') ?
  fs.readFileSync(output + '.proc-status','utf8') : '';
const receipt = { schema:'psc1-compiler-phase-profile/1', label,
  commit:process.env.GITHUB_SHA, referenceCommit:'adcb815733aca23d3d27e7e0ae4cbc589ba56000',
  requestSha256:sha(request), sourceClosureDigest:digest, sourceModules:sources.length, identities,
  binarySha256:sha(fs.readFileSync(binary)),
  vmHwmKiBAtLastMark:Number(processStatus.match(/VmHWM:\s*(\d+) kB/)?.[1]) || null, elapsedMs:Math.round(performance.now()-start),
  timeoutMs:240000, status:result.status, signal:result.signal,error:result.error?.message||null,
  lastRecord:records.at(-1), completed:records.at(-1)?.phase==='profile-complete',
  queueBudget:16384, authoritative:false, G1:'not-produced-by-profiler',
  scope:'same production stage functions with IO timings; no candidate admission or publication' };
fs.writeFileSync(path.join(directory,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_COMPILER_PHASE_PROFILE: '+JSON.stringify(receipt));
// An incomplete trace is useful diagnostic evidence, never a compiler pass.
assert.ok(records.length > 0, 'native profiler must actually enter the pipeline');
