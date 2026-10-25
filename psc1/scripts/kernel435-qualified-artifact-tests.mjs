// Read-only network fixtures plus actual Linux ZIP extraction.
// Retries must never turn a failed identity/admission boundary into acceptance.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { readQualifiedArtifact, sha256 } from './kernel435-qualified-artifact.mjs';
fs.mkdirSync('dist', { recursive: true });
const work = fs.mkdtempSync(path.resolve('dist/artifact-transport-'));
const originalFetch = globalThis.fetch, originalToken = process.env.GH_TOKEN;
process.env.GH_TOKEN = 'transport-fixture';
const zip = (name, mode = 'normal') => {
  const file = path.join(work, name + '.zip');
  const python = 'import zipfile,sys\nwith zipfile.ZipFile(sys.argv[1],"w") as z:\n' +
    ' if sys.argv[2]=="symlink":\n  i=zipfile.ZipInfo("link");i.create_system=3;i.external_attr=0o120777<<16;z.writestr(i,"../outside")\n' +
    ' else:z.writestr("../outside" if sys.argv[2]=="traversal" else "receipt.txt","qualified fixture")\n';
  const result = spawnSync('python3', ['-c', python, file, mode], {
    encoding: 'utf8', timeout: 10000, maxBuffer: 1024 * 1024,
  });
  assert.equal(result.status, 0, result.stderr);
  return fs.readFileSync(file);
};
const bytes = zip('normal'), input = {
  run: 1, job: 2, artifact: 3, commit: 'a'.repeat(40), zipSha256: sha256(bytes),
};
const jobs = { jobs: [{ id: input.job, conclusion: 'success' }] };
const metadata = hash => ({ expired: false, workflow_run: { id: input.run, head_sha: input.commit },
  digest: 'sha256:' + hash });
const response = value => new Response(JSON.stringify(value), { status: 200 });
const pipe = () => Object.assign(new TypeError('fetch failed'), { cause: { code: 'EPIPE' } });
const cases = [];
try {
  let jobsCalls = 0, zipCalls = 0;
  globalThis.fetch = async url => {
    if (url.includes('/jobs?')) {
      if (++jobsCalls <= 2) throw pipe();
      return response(jobs);
    }
    if (url.endsWith('/zip')) {
      if (++zipCalls === 1) return { ok: true, arrayBuffer: async () => { throw pipe(); } };
      return new Response(bytes);
    }
    return response(metadata(input.zipSha256));
  };
  const accepted = await readQualifiedArtifact(input, path.join(work, 'accepted'));
  assert.equal(fs.readFileSync(path.join(accepted, 'receipt.txt'), 'utf8'), 'qualified fixture');
  assert.equal(jobsCalls, 3); assert.equal(zipCalls, 2);
  cases.push('connection/header/body retry preserves exact job source and ZIP identity');

  let fatalCalls = 0;
  globalThis.fetch = async () => { fatalCalls++; return new Response('{}', { status: 401 }); };
  await assert.rejects(readQualifiedArtifact(input, path.join(work, 'unauthorized')), /GitHub request failed 401/);
  assert.equal(fatalCalls, 1); assert.equal(fs.existsSync(path.join(work, 'unauthorized')), false);
  cases.push('authorization failure is not retried or accepted');

  let exhaustedCalls = 0;
  globalThis.fetch = async () => { exhaustedCalls++; throw pipe(); };
  await assert.rejects(readQualifiedArtifact(input, path.join(work, 'exhausted')),
    error => error.cause?.code === 'EPIPE');
  assert.equal(exhaustedCalls, 4);
  cases.push('bounded retry exhaustion remains a failure');

  for (const kind of ['changed-commit', 'changed-digest', 'changed-zip', 'traversal', 'symlink']) {
    const selected = ['traversal', 'symlink'].includes(kind) ? zip(kind, kind) : bytes;
    const request = { ...input, zipSha256: sha256(selected) };
    let downloads = 0;
    globalThis.fetch = async url => {
      if (url.includes('/jobs?')) return response(jobs);
      if (url.endsWith('/zip')) {
        downloads++;
        return new Response(kind === 'changed-zip' ? Buffer.from('changed bytes') : selected);
      }
      const value = metadata(request.zipSha256);
      if (kind === 'changed-commit') value.workflow_run.head_sha = 'b'.repeat(40);
      if (kind === 'changed-digest') value.digest = 'sha256:' + '0'.repeat(64);
      return response(value);
    };
    await assert.rejects(readQualifiedArtifact(request, path.join(work, kind)));
    assert.equal(downloads, ['changed-commit', 'changed-digest'].includes(kind) ? 0 : 1);
    assert.equal(fs.existsSync(path.join(work, 'outside')), false);
    cases.push(kind + ' refuses without retrying an identity or extraction failure');
  }
  fs.writeFileSync(path.join(work, 'qualification.json'), JSON.stringify({
    schema: 'psc1-qualified-artifact-transport-tests/1', testedCommit: process.env.GITHUB_SHA,
    status: 'passed', cases,
  }, null, 2) + '\n');
  console.log('PSC1_QUALIFIED_ARTIFACT_TRANSPORT: PASS ' + JSON.stringify({ cases: cases.length }));
} finally {
  globalThis.fetch = originalFetch;
  if (originalToken === undefined) delete process.env.GH_TOKEN;
  else process.env.GH_TOKEN = originalToken;
}
