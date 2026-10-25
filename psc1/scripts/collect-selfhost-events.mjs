// Bounded, read-only CI log extraction. A snapshot grants no qualification.
import assert from 'node:assert/strict';
import fs from 'node:fs';
const request = JSON.parse(fs.readFileSync('../.github/qualification-requests/psc1-selfhost-events.json'));
assert.equal(request.schema, 'psc1-selfhost-event-request/1');
assert.match(request.sourceClosureDigest, /^[a-f0-9]{64}$/);
const token = process.env.GH_TOKEN; assert.ok(token);
async function read(resource, text = false) {
  const response = await fetch('https://api.github.com/repos/dwijayuda/pskernel/' + resource, {
    headers: { Authorization: 'Bearer ' + token, 'X-GitHub-Api-Version': '2022-11-28' },
    signal: AbortSignal.timeout(120000),
  });
  if (response.status === 404 && text) return null;
  assert.equal(response.ok, true, 'GitHub read ' + response.status + ':' + resource);
  if (!text) return response.json();
  const chunks = []; let bytes = 0;
  for await (const chunk of response.body) {
    bytes += chunk.length; assert.ok(bytes <= 64 * 1024 * 1024, 'bounded log snapshot');
    chunks.push(Buffer.from(chunk));
  }
  return Buffer.concat(chunks).toString('utf8');
}
const rows = [];
for (const input of request.jobs) {
  assert.ok(['js', 'ts', 'rust', 'wasm-core'].includes(input.target));
  assert.ok(Number.isSafeInteger(input.run) && Number.isSafeInteger(input.job));
  assert.match(input.commit, /^[a-f0-9]{40}$/);
  const run = await read('actions/runs/' + input.run);
  assert.equal(run.head_sha, input.commit);
  const job = await read('actions/jobs/' + input.job);
  assert.equal(job.run_id, input.run);
  const log = await read('actions/jobs/' + input.job + '/logs', true);
  const events = [];
  for (const line of (log || '').split('\n')) {
    const match = line.match(/PSC1_(TARGET_REQUEST_STARTED|TARGET_REQUEST_EXECUTION|TARGET_GENERATED_WORKLOAD|GENERATED_TARGET_QUALIFICATION|OUTPUT_ABI_GENERATED): (\{.*\})/);
    if (!match) continue;
    const value = JSON.parse(match[2]);
    if (['GENERATED_TARGET_QUALIFICATION', 'OUTPUT_ABI_GENERATED'].includes(match[1])) {
      assert.equal(value.sourceClosureDigest, request.sourceClosureDigest);
      events.push({ kind: match[1], value }); continue;
    }
    if (['G2-self', 'G3-self'].includes(value.id)) events.push({ kind: match[1], value });
  }
  const row = { target: input.target, run: input.run, job: input.job, commit: input.commit,
    status: job.status, conclusion: job.conclusion, startedAt: job.started_at,
    completedAt: job.completed_at, logAvailable: log !== null,
    logBytes: log === null ? null : Buffer.byteLength(log), events };
  rows.push(row);
  console.log('PSC1_SELFHOST_EVENT_SNAPSHOT: ' + JSON.stringify(row));
}
fs.mkdirSync('dist/selfhost-events', { recursive: true });
fs.writeFileSync('dist/selfhost-events/snapshot.json', JSON.stringify({
  schema: 'psc1-selfhost-event-snapshot/1', observedAt: new Date().toISOString(),
  request, rows, authority: 'read-only diagnostics; terminal qualification remains separate',
}, null, 2) + '\n');
