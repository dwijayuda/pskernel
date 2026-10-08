import { artifactId, artifactKey, canonicalBytes } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';
import { decodeIrArtifact, irEncodingContract } from './ir-artifact.mjs';

export const irLinkEncodingContract = 'psc-ir-link-json/1';
export const irLinkHostContract = 'psc-ir-link-host-json/1';
const fail = code => { throw new Error('PSC_IR_LINK_' + code); };
const tuple = (value, count) => {
  if (!Array.isArray(value) || (count !== undefined && value.length !== count)) fail('SCHEMA');
  return value;
};
const text = value => { if (typeof value !== 'string' || !value.isWellFormed()) fail('SCHEMA'); };
const texts = value => { for (const item of tuple(value)) text(item); };
const names = value => {
  texts(value);
  if (value.some(item => !item) || new Set(value).size !== value.length) fail('POLICY');
};
export const irLinkHostIdentity = (value, limits) =>
  artifactId(canonicalBytes(value, limits), 'host-interface-ir', irLinkHostContract);

/** Decode shape/canonical bytes only. The native Link validator checks types,
 * exports, layouts, capability propagation and the complete dependency graph.
 */
export function decodeIrLinkArtifact(bytes, limits = {}) {
  const root = decodeComparatorJson(bytes, limits);
  tuple(root, 4);
  if (root[0] !== irLinkEncodingContract) fail('CONTRACT');
  tuple(root[1], 2); text(root[1][0]); texts(root[1][1]);
  for (const host of tuple(root[2])) {
    tuple(host, 9); text(host[0]); text(host[1]); text(host[2]); texts(host[3]); texts(host[4]);
    tuple(host[5]);
    if (host[5][0] === 'host') { tuple(host[5], 2); text(host[5][1]); }
    else if (host[5][0] === 'linked') tuple(host[5], 1);
    else fail('ORIGIN');
    // Reuse the complete IR schema for public types and recursive layouts.
    const imports = tuple(host[8]).map(entry => {
      tuple(entry, 2); text(entry[0]); return [entry[0], host[0], entry[0], entry[1]];
    });
    decodeIrArtifact(canonicalBytes([irEncodingContract, imports, host[6], host[7], []], limits), limits);
  }
  for (const unit of tuple(root[3])) {
    tuple(unit, 4); text(unit[0]); texts(unit[1]); texts(unit[2]);
    decodeIrArtifact(canonicalBytes(unit[3], limits), limits);
  }
  return root;
}

/** The consumer chooses target/capabilities and pins exact host contracts.
 * An assumption label by itself cannot authorize arbitrary signatures/layouts.
 */
export function checkIrLinkConsumerPolicy(root, policy, limits = {}) {
  if (!policy || Object.keys(policy).sort().join(',') !== 'allowedCapabilities,hostInterfaceIds,target')
    fail('POLICY');
  text(policy.target); names(policy.allowedCapabilities);
  if (!policy.target || !Array.isArray(policy.hostInterfaceIds)) fail('POLICY');
  const permitted = new Set();
  for (const id of policy.hostInterfaceIds) {
    if (id?.domain !== 'host-interface-ir' || id?.contract !== irLinkHostContract) fail('HOST_POLICY');
    const key = artifactKey(id);
    if (permitted.has(key)) fail('HOST_POLICY');
    permitted.add(key);
  }
  if (root[1][0] !== policy.target ||
      !canonicalBytes(root[1][1], limits).equals(canonicalBytes(policy.allowedCapabilities, limits)))
    fail('POLICY_MISMATCH');
  for (const host of root[2]) {
    if (host[5][0] !== 'host' || !permitted.has(artifactKey(irLinkHostIdentity(host, limits))))
      fail('HOST_CONTRACT_NOT_PINNED');
  }
  return {
    policyId: artifactId(canonicalBytes(policy, limits), 'link-consumer-policy', 'psc-ir-link-consumer-policy/1'),
    hostInterfaceIds: root[2].map(host => irLinkHostIdentity(host, limits)),
    modules: root[3].map(unit => ({ moduleId: unit[0],
      irId: artifactId(canonicalBytes(unit[3], limits), 'runtime-ir', irEncodingContract) })),
  };
}
