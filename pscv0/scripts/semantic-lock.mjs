import { artifactKey, assertArtifactId, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';

const fail = code => { throw new Error('PSC_SEMANTIC_LOCK_' + code); };
const copy = value => JSON.parse(canonicalBytes(value));
const same = (left, right) => artifactKey(left) === artifactKey(right);
const defaults = { maxLockBytes: 8 * 1024 * 1024, maxArtifactBytes: 16 * 1024 * 1024,
  maxTotalBytes: 128 * 1024 * 1024, maxArtifacts: 16384, maxPackages: 4096, maxSourceFiles: 16384 };
const contextFields = ['semanticProfileId', 'theoryManifestId', 'runtimeSemanticsId', 'verifiedIrId', 'targetAbiId', 'evidencePolicyId'];
const packageFields = ['name', 'version', 'sourceManifestId', 'structuralInterfaceId', 'behavioralInterfaceId',
  ...contextFields, 'assumptions', 'capabilities', 'toolchains', 'dependencies'];
function exact(value, fields) {
  if (!value || typeof value !== 'object' || Array.isArray(value) ||
      Object.keys(value).sort().join(',') !== [...fields].sort().join(',')) fail('SCHEMA');
}
function text(value) { if (typeof value !== 'string' || !value || value.length > 4096) fail('TEXT'); }
function sequence(value) { if (!Array.isArray(value)) fail('ARRAY'); return value; }
function unique(values, key = value => value) {
  sequence(values); const seen = new Set();
  for (const value of values) { const id = key(value); if (seen.has(id)) fail('DUPLICATE'); seen.add(id); }
}
function identity(value) {
  exact(value, ['algorithm', 'schemaVersion', 'domain', 'contract', 'byteLength', 'digest']);
  assertArtifactId(value); return value;
}
function identities(values) { unique(values, value => artifactKey(identity(value))); }
function named(values) { unique(values, value => { text(value); return value; }); }
function bounds(values) {
  const result = { ...defaults, ...values };
  if (Object.keys(result).some(key => !Object.hasOwn(defaults, key)) ||
      Object.values(result).some(n => !Number.isSafeInteger(n) || n < 0)) fail('LIMIT_POLICY');
  return result;
}

function validateShape(value, bound) {
  exact(value, ['contract', 'semanticIdentityId', 'trustManifestId', 'roots', 'packages']);
  if (value.contract !== 'psc-semantic-lock/1') fail('UNSUPPORTED_CONTRACT');
  identity(value.semanticIdentityId); identity(value.trustManifestId);
  named(value.roots); sequence(value.packages);
  if (!value.roots.length || !value.packages.length) fail('EMPTY');
  if (value.packages.length > bound.maxPackages) fail('RESOURCE_EXHAUSTED');
  unique(value.packages, item => { text(item.name); return item.name; });
  for (const item of value.packages) {
    exact(item, packageFields); text(item.version);
    for (const field of ['sourceManifestId', 'structuralInterfaceId', 'behavioralInterfaceId', ...contextFields]) identity(item[field]);
    if (item.sourceManifestId.domain !== 'source-manifest' || item.sourceManifestId.contract !== 'psc-source-manifest/1') fail('SOURCE_MANIFEST_ID');
    identities(item.assumptions); named(item.capabilities);
    unique(item.toolchains, tool => { exact(tool, ['role', 'artifact']); text(tool.role); identity(tool.artifact); return tool.role; });
    unique(item.dependencies, dependency => {
      exact(dependency, ['package', 'structuralInterfaceId', 'behavioralInterfaceId']);
      text(dependency.package); identity(dependency.structuralInterfaceId); identity(dependency.behavioralInterfaceId);
      return dependency.package;
    });
  }
  return value;
}

/** A deterministic proposal constructor, never a semantic acceptance operation. */
export function semanticLock(fields, resourceLimits) {
  const bound = bounds(resourceLimits), value = copy(fields);
  validateShape(value, bound);
  const result = canonicalArtifact(value, 'semantic-lock', 'psc-semantic-lock/1');
  if (result.bytes.length > bound.maxLockBytes) fail('RESOURCE_EXHAUSTED');
  return result;
}

export function sourceManifest(files) {
  // Paths are logical source identities, never extraction destinations.
  const value = { contract: 'psc-source-manifest/1', files: copy(files) };
  validateSources(value, defaults);
  return canonicalArtifact(value, 'source-manifest', 'psc-source-manifest/1');
}
function validateSources(value, bound) {
  exact(value, ['contract', 'files']); sequence(value.files);
  if (value.contract !== 'psc-source-manifest/1') fail('SOURCE_MANIFEST');
  if (value.files.length > bound.maxSourceFiles) fail('RESOURCE_EXHAUSTED');
  unique(value.files, file => {
    exact(file, ['path', 'artifact']); text(file.path); identity(file.artifact);
    if (!/^[A-Za-z0-9_.-]+(?:\/[A-Za-z0-9_.-]+)*$/u.test(file.path) ||
        file.path.split('/').some(part => part === '.' || part === '..')) fail('SOURCE_PATH');
    return file.path.toLowerCase();
  });
}

/** Rehash the entire declared closure, bind dependencies to exact structural
 * AND behavioral interfaces, and enforce independently supplied consumer policy.
 * This checks the lock's integrity/consistency, not truth of its specifications,
 * completeness of producer-discovered imports, or compiler preservation.
 */
export async function verifySemanticLock(lock, { resolveArtifact, expectedLockId,
  expectedSemanticIdentityId, allowedAssumptions = [], allowedCapabilities = [], requiredToolchainRoles = [], resourceLimits } = {}) {
  const bound = bounds(resourceLimits), policyIdentity = copy(expectedSemanticIdentityId);
  const expected = copy(expectedLockId), assumptions = new Set(copy(allowedAssumptions).map(value => artifactKey(identity(value))));
  const capabilities = copy(allowedCapabilities), toolRoles = copy(requiredToolchainRoles);
  named(capabilities); named(toolRoles); identity(expected); identity(policyIdentity);
  if (!same(lock.identity, expected) || expected.domain !== 'semantic-lock' || expected.contract !== 'psc-semantic-lock/1') fail('EXPECTED_ID');
  if (!(lock.bytes instanceof Uint8Array) || lock.bytes.byteLength > bound.maxLockBytes) fail('RESOURCE_EXHAUSTED');
  const bytes = Buffer.from(lock.bytes); verifyArtifact(bytes, expected);
  const value = validateShape(decodeComparatorJson(bytes, { maxBytes: bound.maxLockBytes }), bound);
  if (!same(value.semanticIdentityId, policyIdentity)) fail('SEMANTIC_IDENTITY');
  const blobs = new Map(); let total = 0, fileCount = 0;
  async function resolve(id) {
    const key = artifactKey(id);
    if (!blobs.has(key)) {
      if (blobs.size >= bound.maxArtifacts || id.byteLength > bound.maxArtifactBytes || total + id.byteLength > bound.maxTotalBytes) fail('RESOURCE_EXHAUSTED');
      const proposed = await resolveArtifact(copy(id));
      if (!(proposed instanceof Uint8Array) || proposed.byteLength !== id.byteLength) fail('ARTIFACT_BYTES');
      const snapshot = Buffer.from(proposed); verifyArtifact(snapshot, id);
      blobs.set(key, snapshot); total += snapshot.length;
    }
    return blobs.get(key);
  }
  await resolve(value.semanticIdentityId); await resolve(value.trustManifestId);
  const packages = new Map(value.packages.map(item => [item.name, item]));
  for (const root of value.roots) if (!packages.has(root)) fail('ROOT_UNRESOLVED');
  for (const item of value.packages) {
    for (const assumption of item.assumptions) {
      if (!assumptions.has(artifactKey(assumption))) fail('ASSUMPTION_DENIED');
      await resolve(assumption);
    }
    if (item.capabilities.some(capability => !capabilities.includes(capability))) fail('CAPABILITY_DENIED');
    const roles = new Set(item.toolchains.map(tool => tool.role));
    if (toolRoles.some(role => !roles.has(role))) fail('TOOLCHAIN_REQUIRED');
    for (const tool of item.toolchains) await resolve(tool.artifact);
    for (const field of ['structuralInterfaceId', 'behavioralInterfaceId', ...contextFields]) await resolve(item[field]);
    const sources = decodeComparatorJson(await resolve(item.sourceManifestId), { maxBytes: bound.maxArtifactBytes });
    validateSources(sources, bound); fileCount += sources.files.length;
    if (fileCount > bound.maxSourceFiles) fail('RESOURCE_EXHAUSTED');
    for (const file of sources.files) await resolve(file.artifact);
    for (const dependency of item.dependencies) {
      const provider = packages.get(dependency.package);
      if (!provider) fail('DEPENDENCY_UNRESOLVED');
      if (!same(dependency.structuralInterfaceId, provider.structuralInterfaceId) ||
          !same(dependency.behavioralInterfaceId, provider.behavioralInterfaceId)) fail('DEPENDENCY_INTERFACE');
      // Cross-context linkage requires an explicit bridge contract. This first
      // lock profile declines it instead of inferring equivalence from names.
      for (const field of ['semanticProfileId', 'theoryManifestId', 'runtimeSemanticsId', 'verifiedIrId', 'targetAbiId']) {
        if (!same(item[field], provider[field])) fail('DEPENDENCY_CONTEXT_UNSUPPORTED');
      }
      if (provider.capabilities.some(capability => !item.capabilities.includes(capability)) ||
          provider.assumptions.some(assumption => !item.assumptions.some(own => same(own, assumption)))) fail('DEPENDENCY_POLICY_LAUNDERING');
    }
  }
  // Iterative DFS with separate visiting/completed states rejects cycles even
  // when another branch has already discovered the node.
  const state = new Map(), order = [];
  for (const root of value.roots) {
    const stack = [{ name: root, exit: false }];
    while (stack.length) {
      const entry = stack.pop(), mark = state.get(entry.name);
      if (entry.exit) { state.set(entry.name, 2); order.push(entry.name); continue; }
      if (mark === 1) fail('DEPENDENCY_CYCLE');
      if (mark === 2) continue;
      state.set(entry.name, 1); stack.push({ name: entry.name, exit: true });
      const dependencies = packages.get(entry.name).dependencies;
      for (let i = dependencies.length - 1; i >= 0; i--) stack.push({ name: dependencies[i].package, exit: false });
    }
  }
  if (state.size !== packages.size) fail('UNREACHABLE_PACKAGE');
  return Object.freeze({ contract: 'psc-semantic-lock-check/1', lockId: expected,
    semanticIdentityId: value.semanticIdentityId, trustManifestId: value.trustManifestId,
    packageOrder: order, sourceFiles: fileCount, artifactCount: blobs.size, artifactBytes: total,
    integrityVerified: true, semanticClaimsVerified: false, closureCompleteness: 'declared-inputs-only',
    authority: 'audit-record-only', releaseAccepted: false });
}

/** Exact structural difference for audit. No changed byte is labeled a safe
 * representation-only migration without separate preservation evidence. */
export function compareSemanticLocks(left, right) {
  for (const lock of [left, right]) {
    verifyArtifact(lock.bytes, lock.identity);
    if (lock.identity.domain !== 'semantic-lock' || lock.identity.contract !== 'psc-semantic-lock/1') fail('EXPECTED_ID');
  }
  const before = validateShape(decodeComparatorJson(left.bytes), defaults);
  const after = validateShape(decodeComparatorJson(right.bytes), defaults);
  const a = new Map(before.packages.map(item => [item.name, item])), b = new Map(after.packages.map(item => [item.name, item]));
  const names = [...new Set([...a.keys(), ...b.keys()])].sort();
  const packages = names.map(name => {
    if (!a.has(name)) return { name, kind: 'added', changedFields: packageFields };
    if (!b.has(name)) return { name, kind: 'removed', changedFields: packageFields };
    const changedFields = packageFields.filter(field => !canonicalBytes(a.get(name)[field]).equals(canonicalBytes(b.get(name)[field])));
    return { name, kind: changedFields.length ? 'changed' : 'unchanged', changedFields };
  });
  return { contract: 'psc-semantic-lock-diff/1', sourceLockId: left.identity, destinationLockId: right.identity,
    semanticIdentityChanged: !same(before.semanticIdentityId, after.semanticIdentityId),
    declaredTrustChanged: !same(before.trustManifestId, after.trustManifestId),
    rootsChanged: !canonicalBytes(before.roots).equals(canonicalBytes(after.roots)), packages,
    semanticEquivalence: 'not-established', preservation: 'requires-independent-evidence', authority: 'audit-record-only' };
}
