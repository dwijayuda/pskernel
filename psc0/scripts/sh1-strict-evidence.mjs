import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { sh1GrammarProfile } from './sh1-grammar-conformance.mjs';
import { strictSourceInputsFromClosure } from './sh1-strict-source.mjs';
import { strictRuntimeContractSha256, strictRuntimeReferenceSourceSha256 } from './sh1-strict-runtime-conformance.mjs';

const hash = (bytes) => createHash('sha256').update(bytes).digest('hex');
const leanGitHash = '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b';

async function jsonFile(outDir, relative) {
  const bytes = await readFile(path.join(outDir, relative));
  return { value: JSON.parse(bytes.toString('utf8')),
    file: { path: relative, sha256: hash(bytes), bytes: bytes.length } };
}

async function artifact(outDir, relative, expected) {
  const bytes = await readFile(path.join(outDir, relative));
  assert.equal(hash(bytes), expected, 'PSC0_SH1_STRICT_ARTIFACT_BINDING: ' + relative);
  return { path: relative, sha256: expected, bytes: bytes.length };
}

function noStrictClaim(value, label) {
  assert.equal(value.strictSh1Qualified, false, 'PSC0_SH1_STRICT_UNEARNED_CLAIM: ' + label);
}

function sourcePolicy(policy, closure) {
  assert.equal(policy.profile, 'PSC0-SH/1');
  assert.equal(policy.enforcementVersion, 1);
  assert.equal(policy.accepted, true);
  assert.equal(policy.traversalComplete, true);
  assert.equal(policy.sourceKind, 'lean');
  assert.equal(policy.moduleCount, closure.moduleCount);
  assert.equal(policy.sourceBytes, closure.bytes);
  for (const key of ['visitedSteps', 'typeSteps', 'termSteps', 'declarationCount', 'theoremCount']) {
    assert(Number.isSafeInteger(policy.stats[key]) && policy.stats[key] >= 0);
  }
}

function targetPolicy(policy) {
  assert.equal(policy.policy, 'psc0-sh1-ts-target/1');
  assert.equal(policy.accepted, true);
  assert.equal(policy.traversalComplete, true);
  assert(Number.isSafeInteger(policy.visitedSteps) && policy.visitedSteps >= 0);
}

function typed(report) {
  assert.equal(report.accepted, true);
  assert.equal(report.traversalComplete, true);
  assert.equal(report.findingCount, 0);
  assert.equal(report.sameOriginalIrCheckedBeforeEmission, true);
}


async function bindSourceEquality({ outDir, directory, compilerSha256, value }) {
  assert.equal(value.schemaVersion, 1);
  assert.equal(value.kind, 'psc0-source-nat-equality-conformance');
  assert.equal(value.status, 'pass');
  assert.equal(value.compilerSha256, compilerSha256);
  assert.equal(value.sourceOperation, 'Nat.beq');
  assert.equal(value.irOperation, 'natEq');
  assert.equal(value.declarationCount, 6);
  assert.equal(value.expectedValuesOrigin, 'independent-fixed-results');
  assert.equal(value.rawSourceCompilationCount, 2);
  assert.equal(value.portableIrCheckCount, 2);
  assert.equal(value.typescriptCompilationCount, 1);
  assert.deepEqual(value.byteAgreement, { typescript: true, admissions: true });
  assert.equal(value.semanticContractQualified, false);
  assert.equal(value.formalPreservationProven, false);
  assert.equal(value.sourceProofProvenanceReconstructed, false);
  assert.deepEqual(value.provider, { status: 'not-attempted', kernelChecked: false });
  noStrictClaim(value, 'source equality');
  const expected = [
    ['equal', 'strictSourceNatEqEqual', true],
    ['disjoint', 'strictSourceNatEqDisjoint', false],
    ['reversed', 'strictSourceNatEqReversed', false],
    ['zero', 'strictSourceNatEqZero', true],
    ['large', 'strictSourceNatEqLarge', false],
    ['computed', 'strictSourceNatEqComputed', true],
  ].map(([id, declaration, result]) => ({ id, declaration, expected: result, value: result }));
  assert.deepEqual(value.observations, expected);
  assert.equal(value.observationsSha256, hash(JSON.stringify(expected)));
  assert.deepEqual(value.sources.map((item) => item.sourceKind), ['lean', 'ps']);
  const sources = [];
  for (const item of value.sources) {
    const sourceKind = item.sourceKind;
    assert.equal(item.path, 'source-equality/source.' + sourceKind);
    assert.equal(item.evidencePath, 'source-equality/' + sourceKind + '-source-receipt.json');
    const raw = await artifact(outDir, directory + '/' + item.path, item.sha256);
    assert.equal(raw.bytes, item.bytes);
    const receipt = await jsonFile(outDir, directory + '/' + item.evidencePath);
    assert.equal(receipt.file.sha256, item.evidenceSha256);
    assert.deepEqual(receipt.value, item.evidence);
    const evidence = receipt.value;
    assert.equal(evidence.evidence, 'portable-atomic-source-and-target-enforcement');
    assert.equal(evidence.compilerSha256, compilerSha256);
    assert.equal(evidence.sourceKind, sourceKind);
    assert.deepEqual(evidence.sourceInputs, [{
      moduleName: ['Ps', 'Compiler', 'StrictRuntimeEquality'],
      sourceSha256: item.sha256, sourceBytes: item.bytes,
    }]);
    assert.equal(evidence.sourceInputsSha256, hash(JSON.stringify(evidence.sourceInputs)));
    assert.deepEqual(evidence.sourceGrammar, sh1GrammarProfile);
    const policy = evidence.sourcePolicy;
    assert.equal(policy.profile, 'PSC0-SH/1');
    assert.equal(policy.enforcementVersion, 1);
    assert.equal(policy.sourceKind, sourceKind);
    assert.equal(policy.moduleCount, 1);
    assert.equal(policy.sourceBytes, item.bytes);
    assert.equal(policy.importCount, 0);
    assert.equal(policy.stats.declarationCount, 6);
    assert.equal(policy.accepted, true);
    assert.equal(policy.traversalComplete, true);
    noStrictClaim(policy, 'source equality policy');
    targetPolicy(evidence.targetPolicy);
    typed(evidence.originalIr);
    assert.equal(evidence.preparationCount, 1);
    assert.equal(evidence.portableIrCheckCount, 1);
    assert.equal(evidence.artifacts.typescriptSha256, value.artifacts.typescript.sha256);
    assert.equal(evidence.artifacts.admissionsSha256, value.artifacts.admissions.sha256);
    assert.equal(evidence.semanticContractQualified, false);
    assert.equal(evidence.providerChecked, false);
    noStrictClaim(evidence, 'source equality atomic result');
    sources.push({ sourceKind, raw, receipt: receipt.file });
  }
  const products = {};
  for (const [kind, relative] of [
    ['typescript', 'source-equality/runtime/index.ts'],
    ['javascript', 'source-equality/runtime/index.js'],
    ['admissions', 'source-equality/admissions.jsonl'],
  ]) {
    assert.equal(value.artifacts[kind].path, relative);
    products[kind] = await artifact(outDir, directory + '/' + relative, value.artifacts[kind].sha256);
  }
  return { sources, artifacts: products, observationCount: 6,
    observationsSha256: value.observationsSha256 };
}

// Authenticate the actual existing receipt bytes. This never prepares source,
// rechecks IR, executes a compiler, or substitutes a finite pass for preservation.
export async function bindStrictQualificationEvidence({
  outDir, closure, nativeReceipt, firstReceipt, secondReceipt, thirdReceipt,
}) {
  const referenceFile = await jsonFile(outDir, 'development/N1/strict-runtime-reference/reference.json');
  const reference = referenceFile.value;
  assert.equal(reference.kind, 'psc0-native-strict-runtime-reference-execution');
  assert.equal(reference.status, 'reference-produced');
  assert.equal(reference.sourceSha256, strictRuntimeReferenceSourceSha256);
  assert.equal(reference.contractSha256, strictRuntimeContractSha256);
  assert.equal(reference.execution.exitCode, 0);
  assert.equal(reference.versionExecution.exitCode, 0);
  assert.equal(reference.reference.leanVersion, '4.34.0');
  assert.equal(reference.reference.leanGitHash, leanGitHash);
  assert.equal(reference.reference.observationCount, 186);
  assert.equal(reference.reference.operationCount, 45);
  assert.equal(reference.reference.observations.length, 186);
  assert.equal(reference.observationsSha256, hash(JSON.stringify(reference.reference.observations)));
  noStrictClaim(reference, 'native reference');
  noStrictClaim(reference.reference, 'native observations');
  const generations = [
    ['N1', 'development/N1', nativeReceipt.artifacts.javascriptSha256],
    ['C1', 'C1', firstReceipt.artifacts.javascriptSha256],
    ['C2', 'C2', secondReceipt.artifacts.javascriptSha256],
    ['C3', 'C3', thirdReceipt.artifacts.javascriptSha256],
  ];
  const generationEvidence = [];
  for (const [name, directory, compilerSha256] of generations) {
    const source = await jsonFile(outDir, directory + '/strict-source/receipt.json');
    assert.equal(source.value.evidence, 'portable-source-boundary-conformance');
    assert.equal(source.value.compilerSha256, compilerSha256);
    noStrictClaim(source.value, name + ' source conformance');
    assert.equal(source.value.semanticContractQualified, false);
    assert.equal(source.value.accepted.length, 2);
    assert.equal(source.value.refused.length, 33);
    assert.equal(source.value.carrierRefusals.length, 2);
    for (const item of source.value.accepted) {
      assert.equal(item.compilerSha256, compilerSha256);
      assert.equal(item.sourcePolicy.accepted, true);
      assert.equal(item.sourcePolicy.traversalComplete, true);
      assert.equal(item.sourcePolicy.profile, 'PSC0-SH/1');
      targetPolicy(item.targetPolicy);
      typed(item.originalIr);
      assert.equal(item.preparationCount, 1);
      assert.equal(item.portableIrCheckCount, 1);
      noStrictClaim(item, name + ' accepted source');
      assert.equal(item.semanticContractQualified, false);
    }
    assert(source.value.refused.every((item) => typeof item.failure.code === 'string'));
    assert(source.value.carrierRefusals.every((item) => item.refused === true));
    const target = await jsonFile(outDir, directory + '/strict-target/receipt.json');
    assert.equal(target.value.evidence, 'portable-target-admission-conformance');
    assert.equal(target.value.compilerSha256, compilerSha256);
    assert.equal(target.value.policy, 'psc0-sh1-ts-target/1');
    assert.equal(target.value.observations.length, 29);
    assert.equal(target.value.acceptedCases, 9);
    assert.equal(target.value.refusedCases, 20);
    assert.equal(target.value.semanticPreservationProven, false);
    assert.equal(target.value.arbitraryTypedIrIsStrictSource, false);
    noStrictClaim(target.value, name + ' target conformance');
    const runtime = await jsonFile(outDir, directory + '/strict-runtime/receipt.json');
    assert.equal(runtime.value.kind, 'psc0-enabled-runtime-conformance');
    assert.equal(runtime.value.status, 'pass');
    assert.equal(runtime.value.compilerSha256, compilerSha256);
    assert.equal(runtime.value.contractSha256, strictRuntimeContractSha256);
    assert.equal(runtime.value.nativeReference.sourceSha256, strictRuntimeReferenceSourceSha256);
    assert.equal(runtime.value.nativeReference.leanVersion, '4.34.0');
    assert.equal(runtime.value.nativeReference.leanGitHash, leanGitHash);
    assert.equal(runtime.value.nativeReference.observationsSha256, reference.observationsSha256);
    assert.equal(runtime.value.nativeReference.stdoutSha256, reference.execution.stdoutSha256);
    assert.deepEqual(runtime.value.observations, reference.reference.observations);
    assert.equal(runtime.value.observationsSha256, reference.observationsSha256);
    assert.equal(runtime.value.operationCoverage.length, 45);
    assert.equal(new Set(runtime.value.operationCoverage.map((item) => item.operation)).size, 45);
    assert(runtime.value.operationCoverage.every((item) => item.cases.length > 0));
    assert.equal(runtime.value.defensiveBounds.length, 8);
    assert.equal(runtime.value.operandEvaluation.length, 9);
    assert.equal(runtime.value.carrier.rejected.length, 5);
    assert.equal(runtime.value.textPositions.length, 2);
    assert.equal(runtime.value.checkedOriginalIr.runtimeIrTypingAccepted, true);
    assert.equal(runtime.value.checkedOriginalIr.traversalComplete, true);
    assert.equal(runtime.value.portableIrCheckCount, 1);
    assert.equal(runtime.value.formalPreservationProven, false);
    assert.equal(runtime.value.sourceProofProvenanceReconstructed, false);
    noStrictClaim(runtime.value, name + ' runtime conformance');
    const sourceEquality = await bindSourceEquality({ outDir,
      directory: directory + '/strict-runtime', compilerSha256,
      value: runtime.value.sourceEqualityRegression });
    const compiler = await artifact(outDir, directory + '/index.js', compilerSha256);
    generationEvidence.push({ name, compiler, source: source.file, target: target.file, runtime: runtime.file,
      sourceEquality, operationCount: 45, observationCount: 186, sourceRefusals: 33, targetRefusals: 20 });
  }

  const nativeFile = await jsonFile(outDir, 'development/N1/strict-source-native.json');
  const native = nativeFile.value;
  assert.equal(native.evidence, 'native-atomic-source-and-target-enforcement');
  sourcePolicy(native.sourcePolicy, closure);
  targetPolicy(native.targetPolicy);
  typed(native.originalIr);
  assert.equal(native.preparationCount, 1);
  assert.equal(native.portableIrCheckCount, 1);
  assert.equal(native.semanticContractQualified, false);
  assert.equal(native.providerChecked, false);
  noStrictClaim(native, 'native source');
  const expectedInputs = strictSourceInputsFromClosure(closure).map(({ moduleName, source }) => ({
    moduleName, sourceSha256: hash(source), sourceBytes: Buffer.byteLength(source),
  }));
  const expectedInputHash = hash(JSON.stringify(expectedInputs));
  const atomicBuilds = [{ name: 'native produces N1', source: nativeFile.file,
    compilerBinarySha256: nativeReceipt.nativeCompiler.binarySha256,
    sourcePolicy: native.sourcePolicy, targetPolicy: native.targetPolicy }];
  for (const [name, directory, receipt, producer] of [
    ['C1 produces C2', 'C2', secondReceipt, firstReceipt.artifacts.javascriptSha256],
    ['C2 produces C3', 'C3', thirdReceipt, secondReceipt.artifacts.javascriptSha256],
  ]) {
    const source = await jsonFile(outDir, directory + '/strict-source.json');
    const value = source.value;
    assert.equal(value.evidence, 'portable-atomic-source-and-target-enforcement');
    assert.equal(value.compilerSha256, producer);
    assert.equal(value.sourceInputsSha256, expectedInputHash);
    assert.deepEqual(value.sourceInputs, expectedInputs);
    assert.deepEqual(value.sourceGrammar, sh1GrammarProfile);
    sourcePolicy(value.sourcePolicy, closure);
    targetPolicy(value.targetPolicy);
    typed(value.originalIr);
    assert.equal(value.preparationCount, 1);
    assert.equal(value.portableIrCheckCount, 1);
    assert.equal(value.semanticContractQualified, false);
    assert.equal(value.providerChecked, false);
    noStrictClaim(value, name);
    assert.equal(value.artifacts.typescriptSha256, receipt.artifacts.typescriptSha256);
    assert.equal(value.artifacts.admissionsSha256, receipt.artifacts.normalizedCanonicalAdmissionsSha256);
    assert.deepEqual(value.sourcePolicy.stats, native.sourcePolicy.stats);
    assert.equal(value.targetPolicy.visitedSteps, native.targetPolicy.visitedSteps);
    atomicBuilds.push({ name, source: source.file, executingCompilerSha256: producer,
      sourceInputsSha256: expectedInputHash, sourcePolicy: value.sourcePolicy, targetPolicy: value.targetPolicy });
  }
  assert.equal(nativeReceipt.artifacts.typescriptSha256, secondReceipt.artifacts.typescriptSha256,
    'PSC0_SH1_STRICT_NATIVE_TYPESCRIPT_PARITY');
  assert.equal(nativeReceipt.artifacts.javascriptSha256, secondReceipt.artifacts.javascriptSha256,
    'PSC0_SH1_STRICT_NATIVE_JAVASCRIPT_PARITY');
  const artifacts = [
    await artifact(outDir, 'development/N1/index.ts', secondReceipt.artifacts.typescriptSha256),
    await artifact(outDir, 'C2/index.ts', secondReceipt.artifacts.typescriptSha256),
    await artifact(outDir, 'C3/index.ts', thirdReceipt.artifacts.typescriptSha256),
  ];
  return {
    schemaVersion: 1, kind: 'psc0-strict-enforcement-qualified-evidence',
    sourceClosureSha256: closure.sha256, sourceInputsSha256: expectedInputHash,
    reference: referenceFile.file, contractSha256: strictRuntimeContractSha256,
    referenceSourceSha256: strictRuntimeReferenceSourceSha256, leanGitHash,
    atomicBuilds, generations: generationEvidence, artifacts,
    sourceEnforcementQualified: true, targetAdmissionQualified: true,
    enabledRuntimeFiniteConformanceQualified: true,
    strictSh1Qualified: false, semanticContractQualified: false,
    providerChecked: false,
  };
}
