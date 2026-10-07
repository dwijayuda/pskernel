import { canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';
import { decodeIrArtifact, irEncodingContract } from './ir-artifact.mjs';

export const jsAbiPlanContract = 'psc-js-scalar-abi-plan/1';
export const jsAbiPolicyContract = 'psc-js-abi-host-policy/1';

const primitiveNames = new Set(
  'nat int uint8 uint16 uint32 uint64 usize int8 int16 int32 int64 isize float float32 bool char string unit'.split(' '),
);
const fail = code => { throw new Error('PSC_JS_ABI_ARTIFACT_' + code); };
const exact = (value, fields) => {
  if (!value || typeof value !== 'object' || Array.isArray(value) ||
      Object.keys(value).sort().join(',') !== [...fields].sort().join(',')) fail('SCHEMA');
};
const nonempty = value => typeof value === 'string' && value.length > 0 && value.isWellFormed();

export function normalizeJsAbiPolicy(input = undefined) {
  const value = input ?? {
    schemaVersion: 1,
    contract: jsAbiPolicyContract,
    target: 'javascript',
    wordBits: 64,
    modules: [],
  };
  exact(value, ['schemaVersion', 'contract', 'target', 'wordBits', 'modules']);
  if (value.schemaVersion !== 1 || value.contract !== jsAbiPolicyContract ||
      value.target !== 'javascript' || ![32, 64].includes(value.wordBits) ||
      !Array.isArray(value.modules) || value.modules.length > 4096) fail('POLICY');
  let previous = '';
  const modules = value.modules.map(module => {
    exact(module, ['moduleId', 'capabilities']);
    if (!nonempty(module.moduleId) || module.moduleId <= previous ||
        !Array.isArray(module.capabilities) || module.capabilities.length > 4096) fail('POLICY');
    previous = module.moduleId;
    let priorCapability = '';
    const capabilities = module.capabilities.map(capability => {
      if (!nonempty(capability) || capability <= priorCapability) fail('POLICY');
      priorCapability = capability;
      return capability;
    });
    return { moduleId: module.moduleId, capabilities };
  });
  return Object.freeze({ schemaVersion: 1, contract: jsAbiPolicyContract,
    target: 'javascript', wordBits: value.wordBits, modules: Object.freeze(modules) });
}

function scalar(type, localName) {
  if (!Array.isArray(type) || type.length !== 2 || type[0] !== 'primitive' ||
      !primitiveNames.has(type[1])) fail('UNSUPPORTED_IMPORT:' + localName);
  return type[1];
}

function functionImport(value, modules) {
  if (!Array.isArray(value) || value.length !== 4 ||
      ![value[0], value[1], value[2]].every(nonempty)) fail('IMPORT');
  const [localName, moduleId, exportName, type] = value;
  if (!Array.isArray(type) || type.length !== 3 || type[0] !== 'function' ||
      !Array.isArray(type[1])) fail('UNSUPPORTED_IMPORT:' + localName);
  const provider = modules.get(moduleId);
  if (!provider) fail('POLICY_MODULE_REQUIRED:' + moduleId);
  return {
    capabilities: [...provider.capabilities],
    exportName,
    localName,
    moduleId,
    parameters: type[1].map(parameter => scalar(parameter, localName)),
    result: scalar(type[2], localName),
  };
}

/** Independent host-side derivation from exact archived VerifiedIR bytes.
 * The caller supplies capability policy; missing policy for any actual import
 * fails closed. The resulting plan is adapter data, never kernel authority.
 */
export function jsAbiArtifactsFromVerifiedIr(verifiedIr, inputPolicy = undefined, limits = {}) {
  verifyArtifact(verifiedIr.bytes, verifiedIr.identity);
  if (verifiedIr.identity.domain !== 'verified-ir' ||
      verifiedIr.identity.contract !== irEncodingContract) fail('INPUT_CONTRACT');
  const module = decodeIrArtifact(verifiedIr.bytes, limits);
  const policy = normalizeJsAbiPolicy(inputPolicy);
  const modulePolicies = new Map(policy.modules.map(item => [item.moduleId, item]));
  const used = new Set();
  const imports = module[1].map(value => {
    const item = functionImport(value, modulePolicies);
    used.add(item.moduleId);
    return item;
  });
  for (const item of policy.modules) {
    if (!used.has(item.moduleId)) fail('UNUSED_POLICY_MODULE:' + item.moduleId);
  }
  const policyArtifact = canonicalArtifact(policy, 'abi-policy', jsAbiPolicyContract);
  const planValue = {
    contract: jsAbiPlanContract,
    imports,
    runtimeSemantics: 'psc-runtime-semantics/1',
    target: 'javascript',
    wordBits: policy.wordBits,
  };
  const planArtifact = canonicalArtifact(planValue, 'abi-plan', jsAbiPlanContract);
  return Object.freeze({ policy: policyArtifact, plan: planArtifact,
    relation: 'psc-verified-ir-js-scalar-abi-plan/1', authority: 'adapter-data-not-kernel-authority' });
}

export function decodeJsAbiPolicy(bytes, limits = {}) {
  if (!(bytes instanceof Uint8Array) || bytes.byteLength > (limits.maxBytes ?? 1024 * 1024))
    fail('POLICY_BYTES');
  let value;
  try { value = JSON.parse(Buffer.from(bytes)); } catch { fail('POLICY_JSON'); }
  const normalized = normalizeJsAbiPolicy(value);
  if (!Buffer.from(canonicalBytes(normalized)).equals(Buffer.from(bytes))) fail('POLICY_NONCANONICAL');
  return normalized;
}
