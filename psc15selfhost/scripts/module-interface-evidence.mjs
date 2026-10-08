import { artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';

export const certifiedModuleInterfaceContract = 'psc-certified-module-interface/1';
export const behavioralInterfaceContract = 'psc-behavioral-module-interface/1';
export const moduleInterfaceReuseRuleContract = 'psc-module-interface-reuse-rule/1';
export const exactBehavioralReuseChecker = 'psc-exact-behavioral-interface-reuse/1';

const fail = code => { throw new Error('PSC_MODULE_INTERFACE_' + code); };
const id = value => { artifactKey(value); return JSON.parse(canonicalBytes(value)); };
const nonempty = value => typeof value === 'string' && value.length > 0;

export function certifiedModuleInterfaceArtifact({
  structuralInterface,
  behavioral = undefined,
  evidence = [],
}) {
  if (!structuralInterface || structuralInterface.domain !== 'runtime-interface' ||
      structuralInterface.contract !== 'psc-runtime-interface-json/1') fail('STRUCTURAL');
  if (!Array.isArray(evidence)) fail('EVIDENCE');
  const normalizedEvidence = evidence.map(id);
  let behavior;
  if (behavioral !== undefined) {
    const fields = ['specification', 'effects', 'resources', 'assumptions'];
    if (!behavioral || typeof behavioral !== 'object' || Array.isArray(behavioral) ||
        Object.keys(behavioral).sort().join(',') !== fields.sort().join(',')) fail('BEHAVIORAL');
    behavior = {
      contract: behavioralInterfaceContract,
      specification: id(behavioral.specification),
      effects: id(behavioral.effects),
      resources: id(behavioral.resources),
      assumptions: id(behavioral.assumptions),
    };
  }
  return canonicalArtifact({
    schemaVersion: 1,
    contract: certifiedModuleInterfaceContract,
    structuralInterface: id(structuralInterface),
    structuralSemanticKey: artifactKey(structuralInterface),
    behavioral: behavior ?? null,
    evidence: normalizedEvidence,
    authority: 'interface-evidence-only',
  }, 'certified-module-interface', certifiedModuleInterfaceContract);
}

export function moduleInterfaceReuseRuleArtifact() {
  return canonicalArtifact({
    schemaVersion: 1,
    contract: moduleInterfaceReuseRuleContract,
    consumerStage: 'target',
    dependencyStage: 'certified-behavioral',
    fingerprintContract: certifiedModuleInterfaceContract,
    checkerId: exactBehavioralReuseChecker,
    relation: 'same-structural-and-behavioral-interface/1',
    authority: 'reuse-rule-not-semantic-authority',
  }, 'query-reuse-rule', moduleInterfaceReuseRuleContract);
}

function parseInterface(record) {
  verifyArtifact(record.bytes, record.identity);
  if (record.identity.domain !== 'certified-module-interface' ||
      record.identity.contract !== certifiedModuleInterfaceContract) fail('IDENTITY');
  const value = JSON.parse(record.bytes);
  if (!canonicalBytes(value).equals(Buffer.from(record.bytes)) || value.schemaVersion !== 1 ||
      value.contract !== certifiedModuleInterfaceContract || value.authority !== 'interface-evidence-only' ||
      typeof value.structuralSemanticKey !== 'string' || !Array.isArray(value.evidence)) fail('SCHEMA');
  artifactKey(value.structuralInterface);
  if (value.structuralSemanticKey !== artifactKey(value.structuralInterface)) fail('STRUCTURAL_KEY');
  if (value.behavioral !== null) {
    if (value.behavioral?.contract !== behavioralInterfaceContract) fail('BEHAVIORAL');
    for (const field of ['specification', 'effects', 'resources', 'assumptions']) artifactKey(value.behavioral[field]);
  }
  for (const evidence of value.evidence) artifactKey(evidence);
  return value;
}

/** Fresh verification of a certified interface. Behavioral evidence is checked
 * by consumer-selected checkers; serialized interface objects never mint proof.
 */
export async function verifyCertifiedModuleInterface(record, {
  resolveArtifact,
  evidenceCheckers = new Map(),
  requireBehavioral = false,
} = {}) {
  if (typeof resolveArtifact !== 'function') fail('RESOLVER');
  const value = parseInterface(record);
  const structuralBytes = await resolveArtifact(value.structuralInterface);
  verifyArtifact(structuralBytes, value.structuralInterface);
  if (requireBehavioral && value.behavioral === null) fail('BEHAVIORAL_REQUIRED');
  const behavioralSubjects = value.behavioral === null ? [] :
    ['specification', 'effects', 'resources', 'assumptions'].map(field => value.behavioral[field]);
  for (const subject of behavioralSubjects) verifyArtifact(await resolveArtifact(subject), subject);
  const verifiedEvidence = [];
  for (const evidenceId of value.evidence) {
    const bytes = await resolveArtifact(evidenceId);
    verifyArtifact(bytes, evidenceId);
    const evidence = JSON.parse(bytes);
    if (!nonempty(evidence.checkerId)) fail('EVIDENCE_SCHEMA');
    const checker = evidenceCheckers.get(evidence.checkerId);
    if (typeof checker !== 'function') fail('EVIDENCE_CHECKER');
    const result = await checker(bytes, { interfaceId: record.identity, interfaceValue: value });
    if (!result?.verified) fail('EVIDENCE_REJECTED');
    verifiedEvidence.push({ checkerId: evidence.checkerId, evidenceId });
  }
  return Object.freeze({ value, verifiedEvidence, authority: 'validated-interface-data-not-kernel-capability' });
}

/** Exact behavioral reuse is intentionally narrow: both independently checked
 * interfaces must have the same structural projection and the same four
 * behavioral subjects. Evidence artifacts themselves may differ.
 */
export async function verifyExactBehavioralInterfaceReuse({
  previous,
  current,
  rule,
  resolveArtifact,
  evidenceCheckers = new Map(),
}) {
  verifyArtifact(rule.bytes, rule.identity);
  const ruleValue = JSON.parse(rule.bytes);
  if (!canonicalBytes(ruleValue).equals(Buffer.from(rule.bytes)) ||
      ruleValue.contract !== moduleInterfaceReuseRuleContract ||
      ruleValue.checkerId !== exactBehavioralReuseChecker ||
      ruleValue.relation !== 'same-structural-and-behavioral-interface/1') fail('RULE');
  const left = await verifyCertifiedModuleInterface(previous, { resolveArtifact, evidenceCheckers, requireBehavioral: true });
  const right = await verifyCertifiedModuleInterface(current, { resolveArtifact, evidenceCheckers, requireBehavioral: true });
  if (left.value.structuralSemanticKey !== right.value.structuralSemanticKey) fail('STRUCTURAL_CHANGED');
  for (const field of ['specification', 'effects', 'resources', 'assumptions']) {
    if (artifactKey(left.value.behavioral[field]) !== artifactKey(right.value.behavioral[field])) fail('BEHAVIORAL_CHANGED');
  }
  return Object.freeze({
    verified: true,
    kind: 'semantic-reuse-validation',
    checkerId: exactBehavioralReuseChecker,
    relation: ruleValue.relation,
    previousInterface: previous.identity,
    currentInterface: current.identity,
    authority: 'reuse-validation-only',
  });
}
