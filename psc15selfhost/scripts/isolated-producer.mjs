import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { randomUUID } from 'node:crypto';
import path from 'node:path';
import { runBoundedProcess } from './bounded-process.mjs';

const imagePattern = /^[a-z0-9][a-z0-9./:_-]*@sha256:[a-f0-9]{64}$/u;
export function isolatedProducerArgs({ image, command, name, policy }) {
  if (!imagePattern.test(image) || !/^pscv-[a-f0-9-]{36}$/u.test(name) || !Array.isArray(command) ||
      command.length === 0 || command.some(item => typeof item !== 'string' || item.includes('\0'))) throw new Error('PSC_ISOLATED_PRODUCER_IDENTITY');
  for (const field of ['memoryBytes', 'temporaryBytes', 'processCount', 'cpuCount']) {
    if (!Number.isSafeInteger(policy[field]) || policy[field] < 1) throw new Error('PSC_ISOLATED_PRODUCER_BUDGET');
  }
  if (!['linux/amd64', 'linux/arm64'].includes(policy.platform)) throw new Error('PSC_ISOLATED_PRODUCER_PLATFORM');
  return ['run', '--name', name, '--rm', '--interactive', '--pull=never', '--platform', policy.platform,
    '--network=none', '--read-only', '--cap-drop=ALL', '--security-opt=no-new-privileges',
    '--user=65534:65534', '--ipc=private', '--cgroupns=private', '--no-healthcheck', '--log-driver=none',
    '--pids-limit', String(policy.processCount), '--memory', String(policy.memoryBytes),
    '--memory-swap', String(policy.memoryBytes), '--cpus', String(policy.cpuCount),
    '--ulimit', 'nofile=256:256', '--ulimit', 'core=0:0', '--shm-size=1048576',
    '--tmpfs', '/tmp:rw,noexec,nosuid,nodev,size=' + policy.temporaryBytes,
    '--workdir=/tmp', image, ...command];
}

/** Linux-container adapter. Only a pinned, already-present image is allowed.
 * No host mounts, ambient credentials, network or implicit download fallback.
 * Runtime/OS hardening remains a declared assumption, not a proof or an automatic
 * upgrade of ProviderSecurityProfile. Callers must still enforce that profile.
 */
export async function runIsolatedProducer({ runtimeBinary, endpoint, image, command, policy,
  input, limits, signal, execute = runBoundedProcess }) {
  if (!path.isAbsolute(runtimeBinary) || !/^(?:unix:\/\/\/|npipe:\/\/\/\/\.\/pipe\/)/u.test(endpoint ?? '')) {
    throw new Error('PSC_ISOLATED_PRODUCER_LOCAL_RUNTIME_REQUIRED');
  }
  const name = 'pscv-' + randomUUID();
  const args = isolatedProducerArgs({ image, command, name, policy });
  const config = await mkdtemp(path.join(tmpdir(), 'pscv-runtime-config-'));
  const base = { binary: runtimeBinary, cwd: config, env: {}, input: Buffer.alloc(0) };
  const prefix = ['--host', endpoint, '--config', config];
  let attempted = false, result;
  try {
    // Image-declared volumes would introduce writable storage outside the
    // bounded scratch area. Reject them before running any producer code.
    const inspect = await execute({ ...base, args: [...prefix, 'image', 'inspect', image, '--format', '{{json .}}'],
      limits: { inputBytes: 0, stdoutBytes: 65536, stderrBytes: 16384, wallTimeMs: 10000 }, signal });
    if (inspect.kind !== 'accepted') return { kind: 'infrastructureUnavailable', code: 'sandbox-image-unavailable', detail: inspect, authority: 'none' };
    let metadata;
    try { metadata = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(inspect.value.stdout)); }
    catch { return { kind: 'infrastructureUnavailable', code: 'sandbox-image-metadata', authority: 'none' }; }
    if (metadata.Os !== 'linux' || metadata.Architecture !== policy.platform.slice(6) ||
        !Array.isArray(metadata.RepoDigests) || !metadata.RepoDigests.includes(image) ||
        (metadata.Config?.Volumes && Object.keys(metadata.Config.Volumes).length)) {
      return { kind: 'declinedUnsupported', feature: 'sandbox-image-contract', authority: 'none' };
    }
    attempted = true;
    result = await execute({ ...base, args: [...prefix, ...args], input, limits, signal });
  } finally {
    if (attempted) {
      // Killing the CLI alone does not establish container termination. Remove
      // exactly this invocation's random name and confirm absence afterwards.
      const cleanup = await execute({ ...base, args: [...prefix, 'rm', '--force', name],
        limits: { inputBytes: 0, stdoutBytes: 1024, stderrBytes: 4096, wallTimeMs: 10000 } });
      if (cleanup.kind !== 'accepted') {
        const listed = await execute({ ...base, args: [...prefix, 'container', 'ls', '--all', '--quiet',
          '--filter', 'name=^/' + name + '$'], limits: { inputBytes: 0, stdoutBytes: 1024, stderrBytes: 4096, wallTimeMs: 10000 } });
        if (listed.kind !== 'accepted' || listed.value.stdout.toString('utf8').trim() !== '') {
          result = { kind: 'infrastructureUnavailable', code: 'sandbox-termination-unconfirmed', authority: 'none' };
        }
      }
    }
    await rm(config, { recursive: true, force: true });
  }
  return { ...result, isolation: { contract: 'psc-isolated-producer/1', image, policy,
    mechanism: 'linux-container', hardeningAssurance: 'requires-runtime-security-evidence' } };
}
