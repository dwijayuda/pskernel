// Host-owned protocol boundary. Never imported by generated portable code.
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
const digest = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const fail = code => { throw new Error(code); };
const checkerIdentity = Object.freeze({ protocol: 'pskernel-lean/1', provider: 'lean4-cpp',
  leanVersion: '4.35.0', leanCommit: 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',
  profile: 'lean4.35-core' });

export function runIndependentChecker(executable, canonicalAdmissions) {
  const result = spawnSync(executable, ['--check'], { input: canonicalAdmissions,
    encoding: 'utf8', timeout: 120000, maxBuffer: 32 * 1024 * 1024 });
  if (result.error || result.status !== 0) fail('PSC1_CHECKER_PROCESS_FAILED');
  let response;
  try { response = JSON.parse(result.stdout); } catch { fail('PSC1_CHECKER_RESPONSE_INVALID'); }
  for (const [key, value] of Object.entries(checkerIdentity)) {
    if (response[key] !== value) fail('PSC1_CHECKER_IDENTITY_MISMATCH');
  }
  if (response.accepted !== true) fail('PSC1_CHECKER_REJECTED');
  return checkerIdentity;
}

export function compilerSourceClosureDigest(sources) {
  if (!Array.isArray(sources) || sources.length === 0) fail('PSC1_HOST_SOURCE_CLOSURE_EMPTY');
  const names = new Set();
  const captured = sources.map(item => {
    if (!item || typeof item.module !== 'string' || !item.module ||
        !['lean', 'ps'].includes(item.kind) || typeof item.text !== 'string' ||
        names.has(item.module)) fail('PSC1_HOST_SOURCE_CLOSURE_INVALID');
    names.add(item.module);
    return { module: item.module, kind: item.kind, utf8Sha256: digest(item.text) };
  });
  return digest(JSON.stringify(captured));
}

/** A host creates a session from captured input and an immutable staged graph.
 * Generated wire data cannot select checker tools. The receipt claims logical
 * admission of exact graph bytes only, never source-to-Core/backend preservation.
 */
export function createCompilerHostSession({ requestId, target, sources, canonicalAdmissions, checkerExecutable }) {
  if (typeof requestId !== 'string' || !requestId || !['js', 'rust'].includes(target) ||
      typeof canonicalAdmissions !== 'string' || !canonicalAdmissions ||
      typeof checkerExecutable !== 'string' || !checkerExecutable) fail('PSC1_HOST_REQUEST_INVALID');
  const sourceClosureDigest = compilerSourceClosureDigest(sources);
  const admissions = canonicalAdmissions;
  const admissionsDigest = digest(admissions);
  let state = 'pending';
  return Object.freeze({
    request: Object.freeze({ requestId, target, sourceClosureDigest, admissionsDigest }),
    admit(encoded) {
      if (state !== 'pending') fail('PSC1_HOST_SESSION_CONSUMED');
      let wire;
      try { wire = JSON.parse(encoded); } catch { fail('PSC1_HOST_WIRE_INVALID'); }
      const keys = ['admissions', 'op', 'protocol', 'requestId', 'sourceClosureDigest', 'target'];
      if (!wire || typeof wire !== 'object' || Array.isArray(wire) ||
          Object.keys(wire).sort().join(',') !== keys.sort().join(',')) fail('PSC1_HOST_WIRE_FIELDS');
      if (wire.protocol !== 'psc1-compiler-host/1' || wire.op !== 'admit' ||
          wire.requestId !== requestId || wire.sourceClosureDigest !== sourceClosureDigest ||
          wire.target !== target || wire.admissions !== admissions) fail('PSC1_HOST_REQUEST_MISMATCH');
      state = 'checking';
      try {
        const checker = runIndependentChecker(checkerExecutable, admissions);
        state = 'admitted';
        return Object.freeze({ protocol: 'psc1-compiler-host/1', requestId, target,
          sourceClosureDigest, admissionsDigest, checkerCommit: checker.leanCommit,
          accepted: true, behaviorallyVerified: false });
      } catch (error) { state = 'rejected'; throw error; }
    }
  });
}
