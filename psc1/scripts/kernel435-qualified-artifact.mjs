// Linux CI artifact transport. Exact job/commit/ZIP identities are required.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
export const sha256 = bytes => crypto.createHash('sha256').update(bytes).digest('hex');

async function requestArtifactData(resource, token, binary = false) {
  const transientStatuses = new Set([429, 502, 503, 504]);
  const transientCodes = new Set(['EPIPE', 'ECONNRESET', 'ETIMEDOUT', 'UND_ERR_SOCKET',
    'UND_ERR_CONNECT_TIMEOUT', 'UND_ERR_HEADERS_TIMEOUT', 'UND_ERR_BODY_TIMEOUT']);
  for (let attempt = 0; ; attempt++) {
    try {
      const response = await fetch('https://api.github.com/repos/dwijayuda/pskernel/' + resource, {
        headers: { Authorization: 'Bearer ' + token, 'X-GitHub-Api-Version': '2022-11-28' },
        signal: AbortSignal.timeout(120000),
      });
      if (!response.ok) {
        const failure = new Error('GitHub request failed ' + response.status + ' ' + resource);
        failure.retryableArtifactTransport = transientStatuses.has(response.status);
        await response.body?.cancel();
        throw failure;
      }
      // Read the body inside the retry boundary: a successful header can still
      // be followed by a connection reset while streaming the pinned archive.
      return binary ? Buffer.from(await response.arrayBuffer()) : await response.json();
    } catch (error) {
      const retryable = error.retryableArtifactTransport === true ||
        transientCodes.has(error.cause?.code) || transientCodes.has(error.code) ||
        error.name === 'TimeoutError';
      if (!retryable || attempt >= 3) throw error;
      console.log('PSC1_ARTIFACT_TRANSPORT_RETRY: ' + JSON.stringify({
        resource, attempt: attempt + 1, reason: error.cause?.code || error.code || error.name,
      }));
      await new Promise(resolve => setTimeout(resolve, 250 * 2 ** attempt));
    }
  }
}

export async function readQualifiedArtifact(input, destination) {
  assert.ok(input && Number.isSafeInteger(input.run) &&
    Number.isSafeInteger(input.job) && Number.isSafeInteger(input.artifact));
  assert.match(input.commit, /^[0-9a-f]{40}$/);
  assert.match(input.zipSha256, /^[0-9a-f]{64}$/);
  const token = process.env.GH_TOKEN;
  assert.ok(token, 'read-only Actions token required');
  const jobs = await requestArtifactData('actions/runs/' + input.run + '/jobs?per_page=100', token);
  assert.equal(jobs.jobs.find(job => job.id === input.job)?.conclusion, 'success');
  const artifact = await requestArtifactData('actions/artifacts/' + input.artifact, token);
  assert.equal(artifact.expired, false);
  assert.equal(artifact.workflow_run.id, input.run);
  assert.equal(artifact.workflow_run.head_sha, input.commit);
  assert.equal(artifact.digest, 'sha256:' + input.zipSha256);
  const bytes = await requestArtifactData('actions/artifacts/' + input.artifact + '/zip', token, true);
  assert.ok(bytes.length < 512 * 1024 * 1024);
  assert.equal(sha256(bytes), input.zipSha256);
  destination = path.resolve(destination);
  assert.ok(destination.startsWith(path.resolve('dist') + path.sep));
  fs.mkdirSync(destination, { recursive: true });
  assert.equal(fs.readdirSync(destination).length, 0, 'artifact destination must be fresh');
  const zip = path.join(destination, 'input.zip');
  fs.writeFileSync(zip, bytes);
  const python = 'import zipfile,sys,pathlib\nroot=pathlib.Path(sys.argv[2]).resolve()\n' +
    'with zipfile.ZipFile(sys.argv[1]) as archive:\n' +
    ' assert sum(item.file_size for item in archive.infolist())<2147483648\n' +
    ' for item in archive.infolist():\n' +
    '  target=(root/item.filename).resolve()\n' +
    '  assert target.is_relative_to(root) and not ((item.external_attr>>16)&0o170000)==0o120000\n' +
    ' archive.extractall(root)\n';
  const result = spawnSync('python3', ['-c', python, zip, destination], {
    encoding: 'utf8', timeout: 120000, maxBuffer: 16 * 1024 * 1024,
  });
  assert.equal(result.error, undefined);
  assert.equal(result.status, 0, result.stderr);
  return destination;
}
