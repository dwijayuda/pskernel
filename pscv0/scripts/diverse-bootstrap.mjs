import { artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';

export const ddcCampaignContract = 'psc-diverse-bootstrap-campaign/1';
const fail = code => { throw new Error('PSC_DDC_' + code); };
const copy = value => JSON.parse(canonicalBytes(value));
const same = (left, right) => artifactKey(left) === artifactKey(right);

function checkedAdapter(value, name) {
  if (!value || typeof value.run !== 'function' || !value.identity) fail(name + '_ADAPTER');
  artifactKey(value.identity);
  return { identity: copy(value.identity), run: value.run };
}
function checkedArtifact(value, name) {
  if (!(value?.bytes instanceof Uint8Array) || !value.identity) fail(name + '_ARTIFACT');
  const result = { bytes: Buffer.from(value.bytes), identity: copy(value.identity) };
  verifyArtifact(result.bytes, result.identity);
  return result;
}
function independent(independence, requiredAxes) {
  if (!independence || typeof independence !== 'object' || !Array.isArray(requiredAxes) || !requiredAxes.length)
    fail('INDEPENDENCE');
  for (const axis of requiredAxes) {
    const values = independence[axis];
    if (!Array.isArray(values) || values.length !== 2 || values.some(value => value === 'unknown') ||
        canonicalBytes(values[0]).equals(canonicalBytes(values[1]))) fail('DIVERSITY_' + axis);
  }
}

/** Implementation-level DDC runner.
 * It does not claim compiler correctness. The selected relation is explicit:
 * exact-bytes compares the stage-2 diverse rebuild to the compiler-under-test;
 * other relations require a caller checker that binds both exact artifacts.
 */
export async function runDiverseBootstrapCampaign({
  sourceClosure,
  compilerUnderTest,
  trustedDiverseCompiler,
  executeCompiler,
  independence,
  requiredDiversityAxes = ['sourceDerivation', 'compilerToolchain'],
  relation = 'exact-bytes',
  relationChecker,
  resourcePolicy,
}) {
  const source = checkedArtifact(sourceClosure, 'SOURCE');
  const subject = checkedArtifact(compilerUnderTest, 'SUBJECT');
  const trusted = checkedAdapter(trustedDiverseCompiler, 'TRUSTED');
  const execute = checkedAdapter(executeCompiler, 'EXECUTE');
  independent(independence, requiredDiversityAxes);
  if (!resourcePolicy || typeof resourcePolicy !== 'object') fail('RESOURCE_POLICY');
  const first = checkedArtifact(await trusted.run({
    source: { bytes: Buffer.from(source.bytes), identity: copy(source.identity) },
    targetContract: subject.identity.contract,
    resourcePolicy: copy(resourcePolicy),
  }), 'DIVERSE_STAGE1');
  const second = checkedArtifact(await execute.run({
    compiler: { bytes: Buffer.from(first.bytes), identity: copy(first.identity) },
    source: { bytes: Buffer.from(source.bytes), identity: copy(source.identity) },
    targetContract: subject.identity.contract,
    resourcePolicy: copy(resourcePolicy),
  }), 'DIVERSE_STAGE2');
  if (first.identity.contract !== subject.identity.contract ||
      second.identity.contract !== subject.identity.contract) fail('TARGET_CONTRACT');
  let relationEvidence;
  if (relation === 'exact-bytes') {
    relationEvidence = { verified: Buffer.from(second.bytes).equals(Buffer.from(subject.bytes)),
      checkerId: 'psc-exact-bytes-ddc/1' };
  } else {
    if (typeof relationChecker !== 'function') fail('RELATION_CHECKER');
    relationEvidence = await relationChecker({
      expected: subject,
      actual: second,
      relation,
      sourceClosureId: source.identity,
    });
  }
  if (relationEvidence?.verified !== true) {
    return Object.freeze({ kind: 'rejectedMismatch', relation, sourceClosureId: copy(source.identity),
      subjectId: copy(subject.identity), stage1Id: copy(first.identity), stage2Id: copy(second.identity),
      authority: 'audit-record-only', compilerCorrectness: 'not-established' });
  }
  const value = {
    schemaVersion: 1,
    contract: ddcCampaignContract,
    sourceClosureId: copy(source.identity),
    compilerUnderTestId: copy(subject.identity),
    trustedDiverseCompilerId: copy(trusted.identity),
    executeCompilerId: copy(execute.identity),
    diverseStage1Id: copy(first.identity),
    diverseStage2Id: copy(second.identity),
    targetContract: subject.identity.contract,
    relation,
    relationEvidence: copy(relationEvidence),
    independence: copy(independence),
    requiredDiversityAxes: [...requiredDiversityAxes],
    resourcePolicy: copy(resourcePolicy),
    sourceIdentityStable: same(source.identity, sourceClosure.identity),
    result: 'correspondence-observed',
    compilerCorrectness: 'not-established',
    trustingTrustScope: 'relative-to-selected-diverse-compiler-independence-and-relation',
    authority: 'audit-record-only',
    releaseAccepted: false,
  };
  const evidence = canonicalArtifact(value, 'diverse-bootstrap-evidence', ddcCampaignContract);
  return Object.freeze({ kind: 'accepted', evidence, stage1: first, stage2: second,
    authority: 'audit-record-only', compilerCorrectness: 'not-established' });
}
