import assert from 'node:assert/strict';
import { test } from 'node:test';
import { isolatedProducerArgs, runIsolatedProducer } from './isolated-producer.mjs';

const image = 'example.invalid/producer@sha256:' + 'a'.repeat(64);
const policy = { memoryBytes: 67108864, temporaryBytes: 1048576, processCount: 32, cpuCount: 1, platform: 'linux/amd64' };
test('producer policy pins image and forbids implicit access to host resources', () => {
  const args = isolatedProducerArgs({ image, command: ['/producer'], name: 'pscv-00000000-0000-0000-0000-000000000000', policy });
  for (const flag of ['--pull=never', '--network=none', '--read-only', '--cap-drop=ALL', '--security-opt=no-new-privileges', '--user=65534:65534']) assert.ok(args.includes(flag));
  assert.ok(!args.includes('--volume') && !args.includes('--privileged'));
  assert.throws(() => isolatedProducerArgs({ image: 'producer:latest', command: ['/producer'], name: 'pscv-00000000-0000-0000-0000-000000000000', policy }), /IDENTITY/);
});

test('adapter rejects declared volumes and confirms cleanup after a resource failure', async () => {
  const config = { runtimeBinary: process.execPath, endpoint: 'unix:///var/run/docker.sock', image,
    command: ['/producer'], policy, input: Buffer.from('challenge') };
  const calls = [];
  const accepted = stdout => ({ kind: 'accepted', value: { stdout: Buffer.from(stdout) }, authority: 'none' });
  const execute = async options => {
    calls.push(options);
    if (options.args.includes('inspect')) return accepted(JSON.stringify({ Os: 'linux', Architecture: 'amd64', RepoDigests: [image], Config: { Volumes: null } }));
    if (options.args.includes('run')) return { kind: 'resourceExhausted', resource: 'wallTime', authority: 'none' };
    if (options.args.includes('rm')) return { kind: 'internalError', code: 'already-removed', authority: 'none' };
    return accepted('');
  };
  const result = await runIsolatedProducer({ ...config, execute });
  assert.equal(result.kind, 'resourceExhausted');
  assert.ok(calls.some(call => call.args.includes('rm')));
  assert.ok(calls.some(call => call.args.includes('ls')));
  assert.ok(calls.every(call => Object.keys(call.env).length === 0));
  const volume = await runIsolatedProducer({ ...config, execute: async () => accepted(JSON.stringify({
    Os: 'linux', Architecture: 'amd64', RepoDigests: [image], Config: { Volumes: { '/unbounded': {} } } })) });
  assert.equal(volume.kind, 'declinedUnsupported');
});
