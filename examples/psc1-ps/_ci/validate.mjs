import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {fork} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..');
const catalog = JSON.parse(fs.readFileSync(path.join(root, 'examples.json')));
const results = [];
async function check(example) {
  const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-example-'));
  return await new Promise(resolve => {
    let child, timer, done = false, stderr = '';
    const finish = value => {
      if (done) return;
      done = true;
      clearTimeout(timer);
      try {if (child?.pid) process.kill(-child.pid, 'SIGKILL');} catch {}
      fs.rmSync(temporary, {recursive: true, force: true});
      resolve(value);
    };
    child = fork(path.join(here, 'example-worker.mjs'), [], {
      cwd: root, detached: true, execArgv: ['--max-old-space-size=1024'],
      env: {...process.env, NODE_OPTIONS: '', TMPDIR: temporary, TMP: temporary, TEMP: temporary},
      stdio: ['ignore', 'ignore', 'pipe', 'ipc'],
    });
    child.stderr.on('data', bytes => {stderr = (stderr + bytes).slice(-8192);});
    child.once('message', finish);
    child.once('error', error => finish({id: example.id, status: 'failed', error: error.message}));
    child.once('exit', (code, signal) => finish({id: example.id, status: 'failed',
      error: `Worker exited (${signal || code}): ${stderr}`}));
    timer = setTimeout(() => finish({id: example.id, status: 'failed', error: 'Example exceeded 60-second qualification deadline'}), 60000);
    child.send({root, example});
  });
}
for (const example of catalog.examples) {
  const result = await check(example);
  results.push(result);
  console.log('PSC1_EXAMPLE ' + JSON.stringify(result));
}
const failures = results.filter(result => result.status !== 'passed');
const report = {schema: 'psc1-example-qualification/1', status: failures.length ? 'failed' : 'passed',
  createdAt: new Date().toISOString(), commit: process.env.GITHUB_SHA,
  runId: process.env.GITHUB_RUN_ID, runUrl: `https://github.com/dwijayuda/pskernel/actions/runs/${process.env.GITHUB_RUN_ID}`,
  compiler: 'proofscript@0.1.0-psc1.12',
  compilerTarballSha256: '9a66dcd0f92aaa60f600674fb91b31bc0d67b211d1e9e004146baa8e96502fcc',
  kernel: 'official Lean 4.35.0 linear-memory Wasm', node: process.version, platform: process.platform,
  projects: results.length, sourceFiles: catalog.examples.reduce((sum, row) => sum + row.files.length, 0),
  positiveProjects: catalog.examples.filter(row => row.expected === 'checked').length,
  intentionalDiagnosticProjects: catalog.examples.filter(row => row.expected === 'rejected').length,
  runtimeAssertions: results.reduce((sum, row) => sum + Object.keys(row.runtimeAssertions || {}).length, 0),
  failures: failures.length, compilerMocks: false, compilerRebuilt: false, results};
fs.writeFileSync(path.join(root, 'validation-results.json'), JSON.stringify(report, null, 2) + '\n');
console.log('PSC1_EXAMPLE_SUMMARY ' + JSON.stringify({...report, results: undefined}));
if (failures.length) process.exitCode = 1;
