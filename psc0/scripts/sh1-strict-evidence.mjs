import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { sh1GrammarProfile } from './sh1-grammar-conformance.mjs';
import { strictSourceInputsFromClosure } from './sh1-strict-source.mjs';
import { sh1EmptySourceFixtures } from './sh1-strict-source-conformance.mjs';
import {
  strictRuntimeContractSha256, strictRuntimeReferenceSourceSha256,
  strictSourceEvaluationLeanSourceSha256, strictSourceEvaluationProofScriptSourceSha256,
  strictSourceEvaluationReferenceSourceSha256, strictSourceEvaluationExpectedObservationsSha256,
  strictSourceEvaluationExpectedHostProbesSha256,
} from './sh1-strict-runtime-conformance.mjs';

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


function sourceOriginObservation(evidence, generated = true) {
  assert.equal(evidence.preparationCount, 1);
  assert.equal(evidence.canonicalAdmissionEncodingCount, 1);
  assert.equal(evidence.environmentReconstructionCount, 0);
  assert.equal(evidence.portableIrCheckCount, 1);
  const value = evidence.sourceOrigins;
  const common = Object.fromEntries([
    'policy', 'actualParsedModulesRetained', 'moduleCount', 'sourceDeclarationCount',
    'coreDeclarationCount', 'normalizationCount', 'modules', 'semanticCorrespondenceDischarged',
  ].map((key) => [key, value[key]]));
  assert.equal(common.policy, 'psc0-declaration-origins/1');
  assert.equal(common.semanticCorrespondenceDischarged, false);
  for (const key of ['actualParsedModulesRetained', 'moduleCount', 'sourceDeclarationCount',
    'coreDeclarationCount', 'normalizationCount']) {
    assert(Number.isSafeInteger(common[key]) && common[key] >= 0, 'PSC0_SH1_ORIGIN_COUNT: ' + key);
  }
  assert.equal(common.actualParsedModulesRetained, common.moduleCount);
  assert.equal(common.moduleCount, evidence.sourcePolicy.moduleCount);
  assert.equal(common.sourceDeclarationCount, evidence.sourcePolicy.stats.declarationCount);
  assert.equal(common.modules.length, common.moduleCount);
  let sourceCount = 0, coreCount = 0, normalizationCount = 0;
  for (const module of common.modules) {
    assert.equal(module.coreStart, coreCount);
    module.batches.forEach((batch, sourceIndex) => {
      assert.equal(batch.sourceIndex, sourceIndex);
      assert.equal(batch.coreStart, coreCount);
      batch.members.forEach((member, index) => assert.equal(member.index, index));
      coreCount += batch.members.length;
      sourceCount++;
      if (batch.normalization !== null) normalizationCount++;
    });
  }
  assert.equal(sourceCount, common.sourceDeclarationCount);
  assert.equal(coreCount, common.coreDeclarationCount);
  assert.equal(normalizationCount, common.normalizationCount);
  const observationsSha256 = hash(JSON.stringify(common));
  if (generated) {
    assert.equal(value.observationsSha256, observationsSha256);
    assert.equal(value.observationBoundary, 'after-atomic-source-emission');
    assert.deepEqual(common.modules.map((module) => module.moduleName),
      evidence.sourceInputs.map((input) => input.moduleName));
  }
  return { common, observationsSha256 };
}

async function bindSourceEvaluationReference(outDir, parent) {
  const directory = 'development/N1/strict-runtime-reference';
  const relative = 'native-source-evaluation/receipt.json';
  assert.equal(parent.receipt.path, relative);
  const receipt = await jsonFile(outDir, directory + '/' + relative);
  assert.equal(receipt.file.sha256, parent.receipt.sha256);
  const { receipt: omitted, ...envelope } = parent;
  assert.deepEqual(receipt.value, envelope);
  assert.equal(envelope.schemaVersion, 1);
  assert.equal(envelope.kind, 'psc0-native-source-evaluation-reference-execution');
  assert.equal(envelope.status, 'reference-produced');
  assert.equal(envelope.execution.exitCode, 0);
  assert.equal(envelope.nativeExecutionCount, 1);
  assert.equal(envelope.source.path, 'native-source-evaluation/reference.lean');
  assert.equal(envelope.source.sha256, strictSourceEvaluationReferenceSourceSha256);
  assert.equal(envelope.rawSource.path, 'native-source-evaluation/fixture.lean');
  assert.equal(envelope.rawSource.sha256, strictSourceEvaluationLeanSourceSha256);
  const source = await artifact(outDir, directory + '/' + envelope.source.path, envelope.source.sha256);
  const rawSource = await artifact(outDir, directory + '/' + envelope.rawSource.path, envelope.rawSource.sha256);
  assert.equal(source.bytes, envelope.source.bytes);
  assert.equal(rawSource.bytes, envelope.rawSource.bytes);
  assert.equal(envelope.execution.stdoutPath, 'native-source-evaluation/stdout.log');
  assert.equal(envelope.execution.stderrPath, 'native-source-evaluation/stderr.log');
  const stdout = await artifact(outDir, directory + '/' + envelope.execution.stdoutPath,
    envelope.execution.stdoutSha256);
  const stderr = await artifact(outDir, directory + '/' + envelope.execution.stderrPath,
    envelope.execution.stderrSha256);
  const prefix = 'PSC0_SH1_NATIVE_SOURCE_EVALUATION: ';
  const lines = (await readFile(path.join(outDir, stdout.path), 'utf8'))
    .split(/\r?\n/u).filter((line) => line.startsWith(prefix));
  assert.equal(lines.length, 1);
  assert.deepEqual(JSON.parse(lines[0].slice(prefix.length)), envelope.reference);
  const native = envelope.reference;
  assert.equal(native.schemaVersion, 1);
  assert.equal(native.kind, 'psc0-native-source-evaluation-reference');
  assert.equal(native.status, 'reference-produced');
  assert.equal(native.rawSourceSha256, strictSourceEvaluationLeanSourceSha256);
  assert.equal(native.leanVersion, '4.34.0');
  assert.equal(native.leanGitHash, leanGitHash);
  assert.equal(native.observationCount, 24);
  assert.equal(native.observations.length, 24);
  assert.deepEqual(native.observations, envelope.observations);
  assert.equal(envelope.observationsSha256, strictSourceEvaluationExpectedObservationsSha256);
  assert.equal(hash(JSON.stringify(envelope.observations)), strictSourceEvaluationExpectedObservationsSha256);
  for (const value of [envelope, native]) {
    noStrictClaim(value, 'native source evaluation');
    assert.equal(value.semanticContractQualified, false);
    assert.equal(value.formalPreservationProven, false);
  }
  assert.equal(envelope.sourceEffectCapabilityAdded, false);
  assert.deepEqual(envelope.provider, { status: 'not-attempted', kernelChecked: false });
  return { envelope, receipt: receipt.file, source, rawSource, stdout, stderr,
    observationCount: 24, observationsSha256: envelope.observationsSha256 };
}

async function bindSourceEvaluation({ outDir, directory, compilerSha256, value, native }) {
  assert.equal(value.schemaVersion, 1);
  assert.equal(value.kind, 'psc0-source-evaluation-conformance');
  assert.equal(value.status, 'pass');
  assert.equal(value.compilerSha256, compilerSha256);
  assert.equal(value.declarationCount, 12);
  assert.equal(value.definitionCount, 11);
  assert.equal(value.structureCount, 1);
  assert.equal(value.observationCount, 24);
  assert.equal(value.hostProbeCount, 21);
  assert.equal(value.rawSourceCompilationCount, 2);
  assert.equal(value.portableIrCheckCount, 2);
  assert.equal(value.typescriptCompilationCount, 1);
  assert.equal(value.nativeReferenceReused, true);
  assert.equal(value.additionalNativeExecutions, 0);
  assert.equal(value.expectedValuesOrigin, 'independent-fixed-results-and-native-Lean-execution');
  assert.deepEqual(value.byteAgreement, { typescript: true, admissions: true });
  assert.deepEqual(value.nativeReference, {
    sourceSha256: strictSourceEvaluationReferenceSourceSha256,
    rawSourceSha256: strictSourceEvaluationLeanSourceSha256,
    receiptPath: 'native-source-evaluation/receipt.json', receiptSha256: native.receipt.sha256,
    leanVersion: '4.34.0', leanGitHash,
    observationsSha256: strictSourceEvaluationExpectedObservationsSha256,
    stdoutSha256: native.stdout.sha256,
  });
  assert.deepEqual(value.observations, native.envelope.observations);
  assert.equal(value.observations.length, 24);
  assert.equal(value.observationsSha256, strictSourceEvaluationExpectedObservationsSha256);
  assert.equal(hash(JSON.stringify(value.observations)), strictSourceEvaluationExpectedObservationsSha256);
  assert.equal(value.hostProbes.length, 21);
  assert.equal(value.hostProbesSha256, strictSourceEvaluationExpectedHostProbesSha256);
  assert.equal(hash(JSON.stringify(value.hostProbes)), strictSourceEvaluationExpectedHostProbesSha256);
  assert.equal(value.semanticContractQualified, false);
  assert.equal(value.formalPreservationProven, false);
  assert.equal(value.sourceProofProvenanceReconstructed, false);
  assert.equal(value.sourceEffectCapabilityAdded, false);
  assert.deepEqual(value.provider, { status: 'not-attempted', kernelChecked: false });
  noStrictClaim(value, 'source evaluation');
  assert.deepEqual(value.sources.map((item) => item.sourceKind), ['lean', 'ps']);
  const sources = [];
  for (const item of value.sources) {
    const sourceKind = item.sourceKind;
    const expectedHash = sourceKind === 'lean' ? strictSourceEvaluationLeanSourceSha256
      : strictSourceEvaluationProofScriptSourceSha256;
    assert.equal(item.path, 'source-evaluation/source.' + sourceKind);
    assert.equal(item.sha256, expectedHash);
    assert.equal(item.evidencePath, 'source-evaluation/' + sourceKind + '-source-receipt.json');
    const raw = await artifact(outDir, directory + '/' + item.path, expectedHash);
    assert.equal(raw.bytes, item.bytes);
    const receipt = await jsonFile(outDir, directory + '/' + item.evidencePath);
    assert.equal(receipt.file.sha256, item.evidenceSha256);
    assert.deepEqual(receipt.value, item.evidence);
    const evidence = receipt.value;
    assert.equal(evidence.evidence, 'portable-atomic-source-and-target-enforcement');
    assert.equal(evidence.compilerSha256, compilerSha256);
    assert.equal(evidence.sourceKind, sourceKind);
    assert.deepEqual(evidence.sourceInputs, [{
      moduleName: ['Ps', 'Compiler', 'StrictEvaluation'],
      sourceSha256: expectedHash, sourceBytes: item.bytes,
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
    assert.equal(policy.stats.declarationCount, 12);
    assert.equal(policy.accepted, true);
    assert.equal(policy.traversalComplete, true);
    noStrictClaim(policy, 'source evaluation policy');
    targetPolicy(evidence.targetPolicy);
    typed(evidence.originalIr);
    const origins = sourceOriginObservation(evidence);
    assert.equal(evidence.artifacts.typescriptSha256, value.artifacts.typescript.sha256);
    assert.equal(evidence.artifacts.admissionsSha256, value.artifacts.admissions.sha256);
    assert.equal(evidence.semanticContractQualified, false);
    assert.equal(evidence.providerChecked, false);
    noStrictClaim(evidence, 'source evaluation atomic result');
    sources.push({ sourceKind, raw, receipt: receipt.file, originsSha256: origins.observationsSha256 });
  }
  const products = {};
  for (const [kind, relative] of [
    ['typescript', 'source-evaluation/runtime/index.ts'],
    ['javascript', 'source-evaluation/runtime/index.js'],
    ['admissions', 'source-evaluation/admissions.jsonl'],
  ]) {
    assert.equal(value.artifacts[kind].path, relative);
    products[kind] = await artifact(outDir, directory + '/' + relative, value.artifacts[kind].sha256);
  }
  return { sources, artifacts: products, nativeReference: native.receipt,
    observationCount: 24, observationsSha256: value.observationsSha256,
    hostProbeCount: 21, hostProbesSha256: value.hostProbesSha256 };
}


async function observedFile(outDir, relative) {
  const bytes = await readFile(path.join(outDir, relative));
  return { bytes, file: { path: relative, sha256: hash(bytes), bytes: bytes.length } };
}

// These pins describe the exact small source strings in the existing grammar
// and strict-source gates. They add no parsing, preparation, or checking.
const emptyGrammarFixturePins = {
  "pairs": [
    {
      "name": "empty-type-command-boundary",
      "leanSha256": "88d628c31ceb56be0146ecf66a72f5191b6d475c402cd0c43717daac6f098238",
      "proofScriptSha256": "05e50b5461235ffd75675403624cf3a016f144f13465304292fdb2354f76637e",
      "spans": {
        "lean": {
          "start": {
            "byteOffset": "0",
            "line": "1",
            "column": "1"
          },
          "stop": {
            "byteOffset": "35",
            "line": "1",
            "column": "36"
          }
        },
        "ps": {
          "start": {
            "byteOffset": "0",
            "line": "1",
            "column": "1"
          },
          "stop": {
            "byteOffset": "38",
            "line": "1",
            "column": "39"
          }
        }
      }
    },
    {
      "name": "empty-elimination",
      "leanSha256": "a37154bfd4188544b10ef78f937158806c325912bd302335b8facdf8b3247ec3",
      "proofScriptSha256": "c37e7dccc5b227a007f2a5410a31c45f8129c4417d35118263f2520d591558f8",
      "spans": {
        "lean": {
          "start": {
            "byteOffset": "34",
            "line": "1",
            "column": "35"
          },
          "stop": {
            "byteOffset": "47",
            "line": "1",
            "column": "48"
          }
        },
        "ps": {
          "start": {
            "byteOffset": "34",
            "line": "1",
            "column": "35"
          },
          "stop": {
            "byteOffset": "53",
            "line": "1",
            "column": "54"
          }
        }
      }
    },
    {
      "name": "grouped-empty-scrutinee-consumed-span",
      "leanSha256": "24dec1809801c36864e1017fd7d5524b34af24188fdc79d29b3437bcd9688fa1",
      "proofScriptSha256": "ecf7babc3fc3f47f7c1ee8909800194e32ba4533b1a6631f7a21a19468a6a1c2",
      "spans": {
        "lean": {
          "start": {
            "byteOffset": "40",
            "line": "2",
            "column": "35"
          },
          "stop": {
            "byteOffset": "59",
            "line": "2",
            "column": "54"
          }
        },
        "ps": {
          "start": {
            "byteOffset": "40",
            "line": "2",
            "column": "35"
          },
          "stop": {
            "byteOffset": "66",
            "line": "2",
            "column": "61"
          }
        }
      }
    },
    {
      "name": "nested-empty-keeps-outer-alternatives",
      "leanSha256": "f9e2f654b1dd4b713852747593f91ac1ab5ab0da967b8ebdbb946b760c88dcb3",
      "proofScriptSha256": "acc9c590f6792603e849cb2233249c9604be55ceb8f182a34afd48be45832b4e",
      "spans": {
        "lean": {
          "start": {
            "byteOffset": "90",
            "line": "2",
            "column": "21"
          },
          "stop": {
            "byteOffset": "103",
            "line": "2",
            "column": "34"
          }
        },
        "ps": {
          "start": {
            "byteOffset": "91",
            "line": "2",
            "column": "21"
          },
          "stop": {
            "byteOffset": "110",
            "line": "2",
            "column": "40"
          }
        }
      }
    },
    {
      "name": "grouped-empty-argument",
      "leanSha256": "3283f62af99e2142e97fd755a7bdb82b84c1374475eebba795db4df243d960b4",
      "proofScriptSha256": "017ce0a1a12e72e128f31a64818bdc56e6b56f9bcc69cf420cf403f63c905dba",
      "spans": {
        "lean": {
          "start": {
            "byteOffset": "39",
            "line": "1",
            "column": "40"
          },
          "stop": {
            "byteOffset": "52",
            "line": "1",
            "column": "53"
          }
        },
        "ps": {
          "start": {
            "byteOffset": "38",
            "line": "1",
            "column": "39"
          },
          "stop": {
            "byteOffset": "57",
            "line": "1",
            "column": "58"
          }
        }
      }
    }
  ],
  "refusals": [
    {
      "name": "bare-lean-empty-match",
      "sourceKind": "lean",
      "sourceSha256": "dcf52e958df3d1fadc85791418fb45a1cbd051cd42c11d34dc4d9a3790fec28b"
    },
    {
      "name": "lean-nomatch-missing-scrutinee",
      "sourceKind": "lean",
      "sourceSha256": "f6487342be6468166527a6fb80c25fb25a7321f8cae7e577ff06beb1e9c9dc6b"
    },
    {
      "name": "lean-multiple-nomatch-scrutinees",
      "sourceKind": "lean",
      "sourceSha256": "329dcca499a05288394f8ac001c92d2790683ad507bf0b216840d47e0d0902ef"
    },
    {
      "name": "ps-empty-match-missing-close",
      "sourceKind": "ps",
      "sourceSha256": "85e1653e00dbc9973e65ba636ffec5a854af79d805bcc45bf58c3f0e85b1e50c"
    },
    {
      "name": "ps-empty-type-missing-close",
      "sourceKind": "ps",
      "sourceSha256": "b68723906145af67893fde6b69cfa5674653e0c7cf47d3c3b05b68046876bd94"
    },
    {
      "name": "ps-empty-match-orphan-bar",
      "sourceKind": "ps",
      "sourceSha256": "f69848dbb7afb6ebc303f3cad111e33ca9ff937f36c98581bf61ea355d1ba6cf"
    }
  ],
  "zeroPair": {
    "name": "inhabited-zero-field-structure-and-record",
    "leanSha256": "b1fb5f76a2512ac005c8a124e791579e3d493f4917586927f0fcd0627399ab13",
    "proofScriptSha256": "c84ef8a33c61ca91f537b449cc52db3af0da8023adc73dbd1a6c242a07b704c2",
    "spans": {
      "lean": {
        "structure": {
          "start": {
            "byteOffset": "0",
            "line": "1",
            "column": "1"
          },
          "stop": {
            "byteOffset": "26",
            "line": "1",
            "column": "27"
          }
        },
        "record": {
          "start": {
            "byteOffset": "53",
            "line": "2",
            "column": "27"
          },
          "stop": {
            "byteOffset": "55",
            "line": "2",
            "column": "29"
          }
        }
      },
      "ps": {
        "structure": {
          "start": {
            "byteOffset": "0",
            "line": "1",
            "column": "1"
          },
          "stop": {
            "byteOffset": "29",
            "line": "1",
            "column": "30"
          }
        },
        "record": {
          "start": {
            "byteOffset": "56",
            "line": "2",
            "column": "27"
          },
          "stop": {
            "byteOffset": "58",
            "line": "2",
            "column": "29"
          }
        }
      }
    }
  },
  "zeroRefusals": [
    {
      "name": "zero-field-structure-missing-close",
      "sourceSha256": "3f2f3d5963baa0b62e749fd3fb4b7b5072d751773da39d622b15a8484f63331f"
    },
    {
      "name": "zero-field-structure-semicolon",
      "sourceSha256": "1fe8d6f15c883398ddf84c48a7f6e1d3f31552582c9de57c46be6b434c090380"
    }
  ]
};

function bindEmptyGrammar(value, compilerSha256) {
  assert.equal(value.schemaVersion, 1);
  assert.equal(value.evidence, 'generated-compiler-source-grammar-api');
  assert.equal(value.compilerSha256, compilerSha256);
  assert.deepEqual(value.sourceGrammar, sh1GrammarProfile);
  assert.match(value.corpusSha256, /^[a-f0-9]{64}$/u);
  assert.equal(value.scope.finiteCorpus, true);
  for (const key of ['fullStandardConformance', 'fullPscvConformance', 'kernelChecked']) {
    assert.equal(value.scope[key], false);
  }
  const empty = value.emptyElimination, zero = value.zeroFieldRecords;
  assert.equal(value.counts.emptySyntaxPairs, 5);
  assert.equal(value.counts.emptySyntaxRefusals, 6);
  assert.equal(value.counts.zeroFieldRecordPairs, 1);
  assert.equal(value.counts.zeroFieldRecordRefusals, 2);
  assert.equal(empty.canonicalRoundTrips, 5);
  assert.equal(empty.sourceScope, 'regular empty data; one Lean nomatch scrutinee; current PS empty braces');
  assert.equal(empty.nativeMultiScrutineeNomatch, false);
  assert.equal(empty.bareLeanEmptyMatch, 'refused');
  assert.equal(zero.canonicalRoundTrips, 1);
  assert.equal(zero.inhabitedStructure, true);
  assert.equal(zero.emptyInductiveElimination, false);
  for (const item of [empty, zero]) {
    assert.equal(item.additionalPreparations, 0);
    for (const key of ['fullStandardConformance', 'fullPscvConformance', 'kernelChecked']) {
      assert.equal(item[key], false);
    }
  }
  const position = (value) => Object.fromEntries(
    ['byteOffset', 'line', 'column'].map((key) => [key, value[key]]));
  function pair(item, expected) {
    for (const key of ['name', 'leanSha256', 'proofScriptSha256']) {
      assert.equal(item[key], expected[key]);
    }
    for (const key of ['canonicalLeanSha256', 'canonicalProofScriptSha256', 'astSha256']) {
      assert.match(item[key], /^[a-f0-9]{64}$/u);
    }
  }
  assert.equal(empty.pairs.length, 5);
  empty.pairs.forEach((item, index) => {
    const expected = emptyGrammarFixturePins.pairs[index];
    pair(item, expected);
    for (const kind of ['lean', 'ps']) {
      assert.deepEqual(position(item.spans[kind].stop), expected.spans[kind].stop);
      if (index !== 0) assert.deepEqual(position(item.spans[kind].start), expected.spans[kind].start);
    }
  });
  function refusal(item, expected, sourceKind) {
    for (const key of ['name', 'sourceSha256']) assert.equal(item[key], expected[key]);
    if (expected.sourceKind !== undefined) assert.equal(item.sourceKind, sourceKind);
    assert(item.diagnosticTags.includes(sourceKind === 'lean' ? 'leanFrontend' : 'proofScriptFrontend'));
    assert(item.diagnosticTags.includes('parse'));
    assert(!item.diagnosticTags.includes('fuelExhausted'));
    assert.match(item.diagnosticSha256, /^[a-f0-9]{64}$/u);
  }
  assert.equal(empty.refusals.length, 6);
  empty.refusals.forEach((item, index) => {
    const expected = emptyGrammarFixturePins.refusals[index];
    refusal(item, expected, expected.sourceKind);
  });
  assert.equal(zero.pairs.length, 1);
  pair(zero.pairs[0], emptyGrammarFixturePins.zeroPair);
  for (const kind of ['lean', 'ps']) {
    const actual = zero.pairs[0].spans[kind], expected = emptyGrammarFixturePins.zeroPair.spans[kind];
    assert.deepEqual(position(actual.structure.stop), expected.structure.stop);
    for (const end of ['start', 'stop']) assert.deepEqual(position(actual.record[end]), expected.record[end]);
  }
  assert.equal(zero.refusals.length, 2);
  zero.refusals.forEach((item, index) =>
    refusal(item, emptyGrammarFixturePins.zeroRefusals[index], 'ps'));
  return { receiptField: 'grammar', observationsSha256: hash(JSON.stringify(value)),
    corpusSha256: value.corpusSha256,
    emptyElimination: { receiptField: 'grammar.emptyElimination', pairs: 5, refusals: 6,
      observationsSha256: hash(JSON.stringify(empty)) },
    zeroFieldRecords: { receiptField: 'grammar.zeroFieldRecords', pairs: 1, refusals: 2,
      observationsSha256: hash(JSON.stringify(zero)) },
    additionalPreparations: 0 };
}

const zeroFieldLibraryPins = {
  "lean": {
    "sourceSha256": "f05f697f9defd99c1db8288659008a6d7b14bb19b1b973b73e1d85b36661d795",
    "sourceBytes": 364
  },
  "ps": {
    "sourceSha256": "e1bb231c6e8c9aa5cfb7077567e490d5853d16509665ee2fed27abadfce3d9d8",
    "sourceBytes": 368
  }
};

function bindZeroFieldSource(conformance, emptySource) {
  const value = conformance.zeroFieldRecords;
  assert.equal(value.feature, 'inhabited-zero-field-structures');
  assert.equal(value.emittedTypeScriptEqual, true);
  assert.equal(value.typeScriptSha256, conformance.emptyElimination.typeScriptSha256);
  assert.equal(value.observationBoundary, 'actual-original-ir-after-atomic-emission');
  assert.equal(value.additionalPreparations, 0);
  assert.equal(value.additionalPortableIrChecks, 0);
  assert.equal(value.semanticContractQualified, false);
  assert.equal(value.providerChecked, false);
  noStrictClaim(value, 'zero-field source conformance');
  assert.deepEqual(value.observations.map((item) => item.sourceKind), ['lean', 'ps']);
  const observations = [];
  for (const item of value.observations) {
    const kind = item.sourceKind, pin = zeroFieldLibraryPins[kind];
    assert.equal(item.structureName, 'Sh1EmptyRecord');
    assert.equal(item.valueName, 'sh1EmptyRecordValue');
    assert.deepEqual(item.moduleName, ['Ps', 'Compiler', 'StrictLibrary']);
    assert.equal(item.sourceDeclarationCount, 2);
    assert.equal(item.coreDeclarationCount, 4);
    assert.equal(item.constructorCount, 1);
    assert.equal(item.fieldCount, 0);
    assert.equal(item.recordFieldCount, 0);
    assert.equal(item.actualRecordValueRetained, true);
    assert.equal(item.inhabited, true);
    assert.equal(item.atomicAcceptedId, kind + '-raw-imports-and-ordinary-do-spellings');
    const accepted = conformance.accepted.filter((entry) => entry.id === item.atomicAcceptedId);
    assert.equal(accepted.length, 1);
    const evidence = accepted[0];
    assert.equal(evidence.sourceKind, kind);
    assert.equal(item.atomicSourceInputsSha256, evidence.sourceInputsSha256);
    assert.deepEqual(evidence.sourceInputs[0], {
      moduleName: item.moduleName, sourceSha256: pin.sourceSha256, sourceBytes: pin.sourceBytes,
    });
    const origins = sourceOriginObservation(evidence);
    assert.equal(origins.common.sourceDeclarationCount, 11);
    assert.equal(origins.common.coreDeclarationCount, 16);
    assert.equal(origins.common.normalizationCount, 0);
    const origin = origins.common.modules[0];
    assert.deepEqual(origin.moduleName, item.moduleName);
    const batches = origin.batches.filter((batch) =>
      batch.sourceName.length === 1 && ['Sh1EmptyRecord', 'sh1EmptyRecordValue'].includes(batch.sourceName[0]));
    assert.deepEqual(batches.map((batch) => batch.sourceName), [['Sh1EmptyRecord'], ['sh1EmptyRecordValue']]);
    assert.deepEqual(batches.map((batch) => batch.members.map((member) => member.role)),
      [['structureType', 'constructor', 'recursor'], ['sourceDeclaration']]);
    assert(batches.every((batch) => batch.normalization === null));
    const bound = emptySource.observations.filter((entry) => entry.sourceKind === kind);
    assert.equal(bound.length, 1);
    assert.equal(item.typeScriptArtifact, 'accepted-' + kind + '.ts');
    assert.equal(item.typeScriptSha256, value.typeScriptSha256);
    assert.equal(item.typeScriptSha256, evidence.artifacts.typescriptSha256);
    assert.equal(item.typeScriptSha256, bound[0].typescript.sha256);
    observations.push({ sourceKind: kind, sourceInput: evidence.sourceInputs[0],
      sourceInputsSha256: evidence.sourceInputsSha256, originsSha256: origins.observationsSha256,
      originBatchesSha256: hash(JSON.stringify(batches)), typescript: bound[0].typescript,
      observationsSha256: hash(JSON.stringify(item)) });
  }
  return { receiptField: 'zeroFieldRecords', observations,
    sourceKinds: 2, sourceDeclarationsPerKind: 2, coreDeclarationsPerKind: 4,
    constructorsPerKind: 1, fieldsPerKind: 0, actualRecordValueRetained: true, inhabited: true,
    additionalPreparations: 0, additionalPortableIrChecks: 0,
    observationsSha256: hash(JSON.stringify(value)) };
}

function bindOptimizedTailIr(value, positive, typeScript, declarationText, artifacts) {
  assert.equal(value.schemaVersion, 1);
  assert.equal(value.feature, 'flat-original-ir-optimized-tail-loops');
  assert.equal(value.status, 'pass');
  assert.equal(value.originalIrBoundary, 'same-existing-accepted-fixture');
  assert.equal(value.observationCount, 12);
  assert.equal(value.valueObservations, 11);
  assert.equal(value.faultObservations, 1);
  assert.equal(value.exhaustiveForAllInputs, false);
  assert.equal(value.semanticContractQualified, false);
  assert.equal(value.providerChecked, false);
  noStrictClaim(value, 'optimized tail IR evidence');
  for (const key of ['additionalPreparations', 'additionalPortableIrChecks', 'additionalEmissions',
    'additionalTypeScriptCompilations', 'additionalNativeExecutions']) assert.equal(value[key], 0);
  assert.deepEqual(value.swapInputs, ['7', '11']);
  assert.equal(value.fuelInitialAccumulator, '11');
  assert.equal(value.reverseInput, 'descending-19999-through-0');
  assert.deepEqual(value.layout, { name: 'TailList', typeParameters: 0, constructors: [
    { name: 'nil', fields: [] },
    { name: 'cons', fields: [{ name: 'head', type: 'nat' }, { name: 'tail', type: 'TailList' }] },
  ] });
  const specifications = [
    { name: 'optimizedTailSwap', parameters: [['fuel', 'nat'], ['left', 'nat'], ['right', 'nat']], result: 'nat',
      signature: 'export declare function optimizedTailSwap(fuel: bigint, left: bigint, right: bigint): bigint;',
      exportPrefix: 'export function optimizedTailSwap(fuel: bigint, left: bigint, right: bigint): bigint { while (true) { ',
      transitions: ['[fuel, left, right] = [nextFuel, right, left]; continue;'], capturedAlias: false },
    { name: 'optimizedTailFuel', parameters: [['fuel', 'nat'], ['accumulator', 'nat']], result: 'nat',
      signature: 'export declare function optimizedTailFuel(fuel: bigint, accumulator: bigint): bigint;',
      exportPrefix: 'export function optimizedTailFuel(fuel: bigint, accumulator: bigint): bigint { while (true) { ',
      transitions: ['[fuel, accumulator] = [nextFuel, (accumulator + 1n)]; continue;'], capturedAlias: true },
    { name: 'optimizedTailReverse', parameters: [['items', 'TailList'], ['accumulator', 'TailList']], result: 'TailList',
      signature: 'export declare function optimizedTailReverse(items: TailList, accumulator: TailList): TailList;',
      exportPrefix: 'export function optimizedTailReverse(items: TailList, accumulator: TailList): TailList { while (true) { ',
      transitions: ['[items, accumulator] = [tailValue, TailList["cons"](headValue, accumulator)]; continue;'],
      capturedAlias: false },
  ];
  assert.equal(value.entries.length, specifications.length);
  for (const [index, expected] of specifications.entries()) {
    const { exportSha256, ...metadata } = value.entries[index];
    assert.deepEqual(metadata, { ...expected, runtimeArity: expected.parameters.length,
      route: 'tail-loop', implementationAbsent: true });
    const exports = typeScript.split(/\r?\n/u)
      .filter((line) => line.startsWith('export function ' + expected.name + '('));
    assert.equal(exports.length, 1);
    assert(exports[0].startsWith(expected.exportPrefix));
    assert.equal(exportSha256, hash(exports[0]));
    for (const transition of expected.transitions) assert(exports[0].includes(transition));
    assert(!typeScript.includes('__ps$impl$' + expected.name));
    if (expected.capturedAlias) assert(!/\bagain\b/u.test(exports[0]));
    const signatures = declarationText.split(/\r?\n/u)
      .filter((line) => line.startsWith('export declare function ' + expected.name + '('));
    assert.deepEqual(signatures, [expected.signature]);
  }
  const expectedObservations = [
    {
      "id": "swap-0",
      "fuel": "0",
      "value": "7"
    },
    {
      "id": "fuel-0",
      "fuel": "0",
      "value": "11"
    },
    {
      "id": "swap-1",
      "fuel": "1",
      "value": "11"
    },
    {
      "id": "fuel-1",
      "fuel": "1",
      "value": "12"
    },
    {
      "id": "swap-2",
      "fuel": "2",
      "value": "7"
    },
    {
      "id": "fuel-2",
      "fuel": "2",
      "value": "13"
    },
    {
      "id": "swap-31",
      "fuel": "31",
      "value": "11"
    },
    {
      "id": "fuel-31",
      "fuel": "31",
      "value": "42"
    },
    {
      "id": "swap-20000",
      "fuel": "20000",
      "value": "7"
    },
    {
      "id": "fuel-20000",
      "fuel": "20000",
      "value": "20011"
    },
    {
      "id": "reverse-20000",
      "length": 20000,
      "first": "0",
      "last": "19999",
      "sequenceSha256": "300d3defc1ca97bc79059e953e46726b7be58c3e3ee69f838eb19350b234f627",
      "checkedElements": 20000
    },
    {
      "id": "reverse-invalid-tag",
      "error": "Error",
      "message": "invalid ProofScript constructor tag"
    }
  ];
  assert.deepEqual(value.observations, expectedObservations);
  assert.deepEqual(value.artifacts, {
    typescript: 'accepted/index.ts', javascript: 'accepted/index.js', declarations: 'accepted/index.d.ts',
    typescriptSha256: artifacts.typescript.sha256, javascriptSha256: artifacts.javascript.sha256,
    declarationsSha256: artifacts.declarations.sha256,
  });
  return { receiptField: 'optimizedTail', observationCount: 12, valueObservations: 11, faultObservations: 1,
    entriesSha256: hash(JSON.stringify(value.entries)), layoutSha256: hash(JSON.stringify(value.layout)),
    observationsSha256: hash(JSON.stringify(expectedObservations)),
    acceptedFixtureSha256: hash(JSON.stringify(positive)), sameAcceptedArtifacts: true, artifacts,
    additionalPreparations: 0, additionalPortableIrChecks: 0, additionalEmissions: 0,
    additionalTypeScriptCompilations: 0, additionalNativeExecutions: 0 };
}

async function bindEmptyIr({ outDir, directory, compilerSha256 }) {
  const receipt = await jsonFile(outDir, directory + '/receipt.json');
  const value = receipt.value;
  assert.equal(value.schemaVersion, 1);
  assert.equal(value.evidence, 'portable-original-ir-checker-conformance');
  assert.equal(value.compilerSha256, compilerSha256);
  assert.deepEqual(value.provider, { status: 'not-attempted', kernelChecked: false });
  noStrictClaim(value, 'original IR conformance');
  const positive = value.acceptedFixture;
  assert.equal(positive.kind, 'psc0-original-ir-inventory');
  assert.equal(positive.compilerSha256, compilerSha256);
  assert.equal(positive.runtimeIrTypingAccepted, true);
  assert.equal(positive.traversalComplete, true);
  assert.equal(positive.findingCount, 0);
  assert.equal(positive.portableChecker.status, 'accepted');
  noStrictClaim(positive, 'original IR accepted fixture');
  assert.equal(value.rejected.length, 38);
  assert.equal(new Set(value.rejected.map((item) => item.name)).size, 38);
  for (const item of value.rejected) {
    assert.equal(item.checkedEmitter, 'rejected-before-emission');
    assert(Number.isSafeInteger(item.findingCount) && item.findingCount > 0);
    assert(Object.hasOwn(item.findingCounts, item.expectedCode));
  }
  for (const [name, code] of [
    ['empty-match-missing-result-hint', 'empty-match-result-type-required'],
    ['empty-match-wrong-scrutinee', 'type-mismatch'],
    ['empty-match-type-argument-arity', 'layout-type-arity'],
    ['empty-match-inhabited-layout', 'match-coverage'],
  ]) {
    const matches = value.rejected.filter((item) => item.name === name);
    assert.equal(matches.length, 1);
    assert.equal(matches[0].expectedCode, code);
  }
  const empty = value.emptyElimination, zero = value.zeroFieldRecords;
  assert.equal(empty.emptyLayoutCount, 2);
  assert.equal(empty.emptyEliminationCount, 5);
  assert.equal(empty.nativeValueOracle, false);
  assert.equal(zero.structureCount, 1);
  assert.equal(zero.fieldCount, 0);
  assert.equal(zero.valueCount, 1);
  assert.equal(zero.inhabited, true);
  for (const item of [empty, zero]) {
    assert.equal(item.declarationArtifact, 'accepted/index.d.ts');
    assert.equal(item.additionalTypeScriptCompilations, 0);
    assert.equal(item.semanticContractQualified, false);
    assert.equal(item.providerChecked, false);
    noStrictClaim(item, 'empty and zero-field IR ABI');
  }
  const typescript = await observedFile(outDir, directory + '/accepted/index.ts');
  assert.equal(typescript.file.sha256, value.artifacts.typescriptSha256);
  const javascript = await artifact(outDir, directory + '/accepted/index.js', value.artifacts.javascriptSha256);
  const declarations = await observedFile(outDir, directory + '/accepted/index.d.ts');
  assert.equal(declarations.file.sha256, empty.declarationSha256);
  assert.equal(declarations.file.sha256, zero.declarationSha256);
  const typeScript = typescript.bytes.toString('utf8'), declarationText = declarations.bytes.toString('utf8');
  const optimizedTail = bindOptimizedTailIr(value.optimizedTail, positive, typeScript, declarationText,
    { typescript: typescript.file, javascript, declarations: declarations.file });
  for (const text of [typeScript, declarationText]) {
    assert.match(text, /export type Empty = never;/u);
    assert.match(text, /export type EmptyBox<T0> = never;/u);
  }
  assert.equal(typeScript.split('__ps$Computation<never>').length - 1, 5);
  const names = ['eliminateEmptyNat', 'eliminateEmptyFunction', 'eliminateEmptyGeneric',
    'eliminateEmptyTypedCall', 'eliminateEmptyComputed'];
  assert.deepEqual(empty.signatures.map((item) => item.name), names);
  for (const item of empty.signatures) {
    const lines = declarationText.split(/\r?\n/u).filter((line) =>
      line.startsWith('export declare function ' + item.name + '(') ||
      line.startsWith('export declare function ' + item.name + '<'));
    assert.deepEqual(lines, [item.signature]);
  }
  assert.match(empty.signatures[0].signature, /\(empty: Empty\): bigint;/u);
  assert.match(empty.signatures[1].signature, /\(empty: Empty\): \([^)]*: bigint\) => bigint;/u);
  assert.match(empty.signatures[2].signature, /<T0>\(empty: EmptyBox<T0>\): T0;/u);
  assert.match(empty.signatures[3].signature, /\(empty: Empty\): bigint;/u);
  assert.match(empty.signatures[4].signature, /\(makeEmpty: \(\) => Empty\): bigint;/u);
  assert.match(declarationText, /export interface RecordUnit/u);
  assert.match(declarationText, /export declare const zeroFieldRecordValue: RecordUnit;/u);
  assert.equal(value.behavior.status, 'pass');
  assert.equal(value.behavior.observations, 61);
  assert.equal(value.behavior.exhaustiveForAllInputs, false);
  assert.deepEqual(value.behavior.emptyScrutinee, {
    callbackCalls: 1, propagatedOriginalFailure: true, noEmptyInhabitantConstructed: true,
  });
  assert.deepEqual(value.behavior.zeroFieldRecord, {
    ownStringFields: 0, ownBrandSymbols: 1, inhabited: true,
  });
  return { receipt: receipt.file,
    artifacts: { typescript: typescript.file, javascript, declarations: declarations.file },
    acceptedFixtureSha256: hash(JSON.stringify(positive)),
    rejectedCases: 38, rejectionsSha256: hash(JSON.stringify(value.rejected)),
    behaviorObservations: 61, behaviorSha256: hash(JSON.stringify(value.behavior)),
    optimizedTail,
    emptyElimination: { receiptField: 'emptyElimination', emptyLayouts: 2, emptyEliminations: 5,
      signaturesSha256: hash(JSON.stringify(empty.signatures)), observationsSha256: hash(JSON.stringify(empty)),
      scrutinee: value.behavior.emptyScrutinee, nativeValueOracle: false },
    zeroFieldRecords: { receiptField: 'zeroFieldRecords', structures: 1, fields: 0, values: 1,
      observationsSha256: hash(JSON.stringify(zero)), runtime: value.behavior.zeroFieldRecord },
    additionalTypeScriptCompilations: 0 };
}

const nativeIrFixtureNames = [
  "function-valued let has compositional type",
  "checked emitter accepts the same valid IR",
  "false let annotation is rejected",
  "checked emitter refuses invalid IR",
  "function parameter grouping is preserved",
  "expression fuel exhaustion is explicit",
  "type fuel exhaustion is explicit",
  "diagnostic cap preserves finding count",
  "empty layouts and typed empty results are accepted",
  "empty layouts emit never and typed empty generators",
  "empty match without an expected result is rejected",
  "empty match still checks its scrutinee",
  "empty match still checks layout type arity",
  "empty alternatives still refuse an inhabited datatype",
  "zero-field source record has its nullary inhabitant"
];

async function bindNativeEmptyIr({ outDir, closure, nativeReceipt, nativeSource }) {
  const directory = 'development/N1/ir-checker-native';
  const receipt = await jsonFile(outDir, directory + '/receipt.json');
  const value = receipt.value;
  assert.equal(value.schemaVersion, 1);
  assert.equal(value.evidence, 'native-portable-checker-current-source');
  assert.equal(value.sourceClosureSha256, closure.sha256);
  assert.equal(value.moduleCount, closure.moduleCount);
  assert.equal(value.fullSourcePreparedAgain, false);
  assert.equal(value.nativeSourceReceiptSha256, nativeSource.file.sha256);
  assert.equal(path.resolve(value.nativeSourceReceipt),
    path.resolve(outDir, 'development/N1/strict-source-native.json'));
  assert.deepEqual(value.fullCompilerIr, nativeSource.value.originalIr);
  assert.deepEqual(value.sourcePolicy, nativeSource.value.sourcePolicy);
  assert.deepEqual(value.targetPolicy, nativeSource.value.targetPolicy);
  assert.equal(value.typescriptSha256, nativeReceipt.artifacts.typescriptSha256);
  assert.deepEqual(value.provider, { status: 'not-attempted', kernelChecked: false });
  noStrictClaim(value, 'native original IR');
  const { report, ...nativeFullCompilerIr } = nativeReceipt.runtimeIrTyping.nativeCurrentSource;
  assert.equal(report, 'ir-checker-native/receipt.json');
  assert.deepEqual(nativeFullCompilerIr, value.fullCompilerIr);
  const inputs = await jsonFile(outDir, directory + '/execution-inputs.json');
  assert.equal(inputs.value.nativeCheckerSha256, value.nativeCheckerSha256);
  assert.match(value.nativeCheckerSha256, /^[a-f0-9]{64}$/u);
  assert.equal(inputs.value.sourceClosureSha256, closure.sha256);
  assert.equal(inputs.value.nativeSourceReceipt, value.nativeSourceReceipt);
  assert.equal(inputs.value.nativeSourceReceiptSha256, nativeSource.file.sha256);
  assert.equal(inputs.value.command.length, 1);
  assert.equal(path.basename(inputs.value.command[0]), 'psc1_ir_check_tests');
  const stdout = await observedFile(outDir, directory + '/native.stdout.log');
  const stderr = await observedFile(outDir, directory + '/native.stderr.log');
  const lines = stdout.bytes.toString('utf8').split(/\r?\n/u);
  const marker = 'PSC0_SH1_IR_NATIVE: ', pass = 'PSC0_SH1_IR_NATIVE_PASS: ';
  const summaries = lines.filter((line) => line.startsWith(marker));
  assert.equal(summaries.length, 1);
  assert.deepEqual(JSON.parse(summaries[0].slice(marker.length)), value.fixtures);
  assert.deepEqual(lines.filter((line) => line.startsWith(pass)).map((line) => line.slice(pass)),
    nativeIrFixtureNames);
  assert(!lines.some((line) => line.startsWith('PSC0_SH1_IR_NATIVE_FAIL: ')));
  const fixtures = value.fixtures;
  assert.equal(fixtures.schemaVersion, 1);
  assert.equal(fixtures.status, 'pass');
  assert.equal(fixtures.cases, 15);
  assert.equal(fixtures.checkedEmitterRejectsInvalidIr, true);
  noStrictClaim(fixtures, 'native original IR fixtures');
  assert.deepEqual(fixtures.emptyElimination, {
    nativeSourceFixturePath: sh1EmptySourceFixtures.lean.path,
    nativeSourceFixtureSha256: sh1EmptySourceFixtures.lean.sha256,
    nativeSourceDeclarations: 5, emptyLayouts: 2, emptyEliminations: 4, nativeValueOracle: false,
  });
  assert.deepEqual(fixtures.zeroFieldRecords, {
    structureCount: 1, fieldCount: 0, inhabited: true, nullaryValueMatched: true,
  });
  return { receipt: receipt.file, executionInputs: inputs.file,
    stdout: stdout.file, stderr: stderr.file, nativeSourceReceipt: nativeSource.file,
    nativeCheckerSha256: value.nativeCheckerSha256, typescriptSha256: value.typescriptSha256,
    fixtureCases: 15, fixturesSha256: hash(JSON.stringify(fixtures)),
    emptyElimination: fixtures.emptyElimination, zeroFieldRecords: fixtures.zeroFieldRecords,
    fullSourcePreparedAgain: false };
}

async function bindCapabilityOrigins(outDir, directory, compilerSha256) {
  const receipt = await jsonFile(outDir, directory + '/capabilities/receipt.json');
  const value = receipt.value;
  assert.equal(value.compilerSha256, compilerSha256);
  assert.equal(value.evidence, 'raw-source-generated-execution');
  assert.deepEqual(value.sourceKinds.map((item) => item.sourceKind), ['lean', 'ps']);
  const emptyGrammar = bindEmptyGrammar(value.grammar, compilerSha256);
  const observations = [];
  for (const item of value.sourceKinds) {
    const evidence = item.strictSourceEnforcement;
    assert.equal(evidence.compilerSha256, compilerSha256);
    assert.equal(evidence.sourceKind, item.sourceKind);
    assert.equal(evidence.evidence, 'portable-atomic-source-and-target-enforcement');
    assert.equal(evidence.sourceInputs.length, 1);
    assert.equal(evidence.sourceInputs[0].sourceSha256, item.sourceSha256);
    assert.equal(evidence.sourceInputsSha256, hash(JSON.stringify(evidence.sourceInputs)));
    assert.deepEqual(evidence.sourceGrammar, sh1GrammarProfile);
    assert.equal(evidence.sourcePolicy.accepted, true);
    assert.equal(evidence.sourcePolicy.traversalComplete, true);
    targetPolicy(evidence.targetPolicy);
    typed(evidence.originalIr);
    noStrictClaim(evidence, 'capability origins');
    assert.equal(evidence.semanticContractQualified, false);
    assert.equal(evidence.providerChecked, false);
    const origins = sourceOriginObservation(evidence);
    assert.equal(origins.common.moduleCount, 1);
    assert.equal(origins.common.sourceDeclarationCount, 35);
    assert.equal(origins.common.coreDeclarationCount, 55);
    assert.equal(origins.common.normalizationCount, 16);
    assert.deepEqual(origins.common.modules[0].moduleName, ['Ps', 'Compiler', 'StrictCapabilities']);
    assert.deepEqual(item.sourceOrigins, {
      policy: 'psc0-declaration-origins/1', sourceDeclarations: 35, coreDeclarations: 55,
      normalizationPlans: 16, unchangedDeclarations: 3, structureBatches: 2,
      positionPairs: 35, duplicateGeneralizedIdsRetained: true,
      observationsSha256: origins.observationsSha256, semanticCorrespondenceDischarged: false,
    });
    observations.push({ sourceKind: item.sourceKind, observationsSha256: origins.observationsSha256 });
  }
  assert.equal(value.negativeCases.length, 7);
  const refusals = value.negativeCases.filter((item) => item.name !== 'explicit-historical-stable-mode');
  assert.equal(refusals.length, 6);
  for (const item of refusals) {
    assert.equal(item.sourceOrigin.stage, 'source');
    assert.equal(item.sourceOrigin.code, 'source-elaboration');
    assert.equal(item.sourceOrigin.moduleName, 'Ps.Compiler.StrictNegative');
    assert.equal(item.sourceOrigin.sourceIndex, 0);
    assert.equal(typeof item.sourceOrigin.owner, 'string');
    assert(['stableDeclaration', 'normalizationPlanning', 'normalizedWorker',
      'publicWrapper', 'declarationInsertion'].includes(item.sourceOrigin.phase));
  }
  return { receipt: receipt.file, observations, emptyGrammar, sourceDeclarationsPerKind: 35,
    coreDeclarationsPerKind: 55, normalizationPlansPerKind: 16, originRefusals: 6 };
}

function bindIngressSnapshots(value, accepted) {
  assert.equal(value.boundary, 'host-ingress-before-real-portable-call');
  const sourceKeys = ['maxModules', 'maxInputBytes', 'maxSyntaxSteps', 'maxTypeSteps', 'maxTermSteps'];
  const irKeys = ['maxSteps', 'maxTypeSteps', 'maxFindings'];
  const cases = [
    ...sourceKeys.map((key) => ['negative-source-' + key, 'sourceOptions.' + key]),
    ...irKeys.map((key) => ['negative-ir-' + key, 'irOptions.' + key]),
    ['number-source-maxModules', 'sourceOptions.maxModules'],
    ['number-ir-maxTypeSteps', 'irOptions.maxTypeSteps'],
    ['missing-source-maxSyntaxSteps', 'sourceOptions.maxSyntaxSteps'],
    ['missing-ir-maxSteps', 'irOptions.maxSteps'],
    ['unsafe-source-maxInputBytes', 'sourceOptions.maxInputBytes'],
    ['unsafe-ir-maxFindings', 'irOptions.maxFindings'],
  ];
  assert.deepEqual(value.malformedOptions, cases.map(([id, option]) => ({
    id, option, refused: true, sourceGetterReads: 0, atomicInterceptions: 0,
  })));
  const probe = value.snapshotProbe;
  assert.deepEqual(probe.optionGetterReads, Object.fromEntries([
    ...sourceKeys.map((key) => ['source.' + key, 1]),
    ...irKeys.map((key) => ['ir.' + key, 1]),
  ]));
  assert.deepEqual(probe.inputReads, { length: 1, element: 1, moduleName: 1,
    moduleLength: 1, segments: [1, 1, 1], source: 1 });
  assert.equal(probe.atomicInterceptions, 1);
  assert.equal(probe.portableInputSourceSha256, hash('def sh1Literal : Nat := 7\n'));
  assert.equal(probe.zeroBudgetCarriersRetained, true);
  assert.equal(probe.irTypeBudget, '9007199254740992');
  assert.equal(probe.realPortableCompilerCalls, 0);
  assert.equal(probe.preparationCount, 0);
  assert.equal(probe.portableIrCheckCount, 0);
  assert.deepEqual(value.emittedSourceCaptures.map((item) => item.sourceKind), ['lean', 'ps']);
  for (const item of value.emittedSourceCaptures) {
    const evidence = accepted.find((entry) => entry.sourceKind === item.sourceKind);
    assert(evidence);
    assert.equal(item.sourceInputsSha256, evidence.sourceInputsSha256);
    assert.equal(item.sourceInputsSha256, hash(JSON.stringify(evidence.sourceInputs)));
    assert.equal(evidence.sourceInputs.length, 3);
    assert.deepEqual(item.inputReads, evidence.sourceInputs.map((input) => ({
      moduleName: 1, source: 1, segments: input.moduleName.map(() => 1),
    })));
    assert.equal(item.manifestMatchesCapturedSources, true);
    assert.equal(item.additionalPreparations, 0);
  }
  return { malformedOptionCases: 14, snapshotProbes: 1, emittedSourceKinds: 2,
    additionalPreparations: 0, observationsSha256: hash(JSON.stringify(value)) };
}

async function bindEmptySource({ outDir, directory, compilerSha256, conformance }) {
  const value = conformance.emptyElimination;
  assert.equal(value.feature, 'regular-empty-data-and-single-scrutinee-elimination');
  assert.equal(value.sourceEdition, 'ps-0.9-r3');
  assert.equal(value.sourceMode, 'new-only');
  assert.equal(value.emittedTypeScriptEqual, true);
  assert.equal(value.additionalPreparations, 0);
  assert.equal(value.additionalPortableIrChecks, 0);
  assert.equal(value.nativeValueOracle, false);
  assert.equal(value.semanticContractQualified, false);
  assert.equal(value.providerChecked, false);
  noStrictClaim(value, 'empty source conformance');
  assert.deepEqual(value.observations.map((item) => item.sourceKind), ['lean', 'ps']);
  const nat = { kind: 'primitive', name: 'nat' };
  const expectedResults = [
    ['sh1EmptyNat', nat],
    ['sh1EmptyFunction', { kind: 'function', parameters: [nat], result: nat }],
    ['sh1EmptyGeneric', { kind: 'typeParameter', name: 'T0' }],
    ['sh1EmptyFresh', nat],
  ];
  const observations = [];
  for (const item of value.observations) {
    const kind = item.sourceKind, pin = sh1EmptySourceFixtures[kind];
    assert.deepEqual({ path: item.path, sha256: item.sha256, bytes: item.bytes }, pin);
    assert.equal(item.sourceArtifact, 'empty.' + kind);
    assert.equal(item.typeScriptArtifact, 'accepted-' + kind + '.ts');
    assert.equal(item.capturedFixtureSha256, pin.sha256);
    assert.equal(item.atomicAcceptedId, kind + '-raw-imports-and-ordinary-do-spellings');
    const accepted = conformance.accepted.filter((entry) => entry.id === item.atomicAcceptedId);
    assert.equal(accepted.length, 1);
    const evidence = accepted[0];
    assert.equal(evidence.evidence, 'portable-atomic-source-and-target-enforcement');
    assert.equal(evidence.compilerSha256, compilerSha256);
    assert.equal(evidence.sourceKind, kind);
    assert.deepEqual(evidence.sourceGrammar, sh1GrammarProfile);
    assert.equal(evidence.sourceInputs.length, 3);
    assert.deepEqual(evidence.sourceInputs.map((entry) => entry.moduleName), [
      ['Ps', 'Compiler', 'StrictLibrary'], ['Ps', 'Compiler', 'StrictEmpty'],
      ['Ps', 'Compiler', 'StrictEntry'],
    ]);
    assert.deepEqual(evidence.sourceInputs[1], {
      moduleName: ['Ps', 'Compiler', 'StrictEmpty'],
      sourceSha256: pin.sha256, sourceBytes: pin.bytes,
    });
    assert.equal(evidence.sourceInputsSha256, hash(JSON.stringify(evidence.sourceInputs)));
    assert.equal(item.atomicSourceInputsSha256, evidence.sourceInputsSha256);
    assert.equal(evidence.sourcePolicy.sourceKind, kind);
    assert.equal(evidence.sourcePolicy.moduleCount, 3);
    assert.equal(evidence.sourcePolicy.importCount, 1);
    assert.equal(evidence.sourcePolicy.stats.declarationCount, 11);
    const origins = sourceOriginObservation(evidence);
    assert.equal(origins.common.sourceDeclarationCount, 11);
    assert.equal(origins.common.coreDeclarationCount, 16);
    assert.equal(origins.common.normalizationCount, 0);
    const origin = origins.common.modules[1];
    assert.deepEqual(item.moduleName, ['Ps', 'Compiler', 'StrictEmpty']);
    assert.deepEqual(origin.moduleName, item.moduleName);
    assert.equal(item.sourceDeclarationCount, 5);
    assert.equal(item.coreDeclarationCount, 6);
    assert.deepEqual(item.originMemberCounts, [2, 1, 1, 1, 1]);
    assert.deepEqual(origin.batches.map((batch) => batch.members.length), item.originMemberCounts);
    assert.deepEqual(origin.batches.map((batch) => batch.sourceName),
      [['Sh1Empty'], ...expectedResults.map(([name]) => [name])]);
    assert.deepEqual(origin.batches.map((batch) => batch.members.map((member) => member.role)),
      [['inductiveType', 'recursor'], ...expectedResults.map(() => ['sourceDeclaration'])]);
    assert(origin.batches.every((batch) => batch.normalization === null));
    assert.equal(item.emptyLayoutCount, 1);
    assert.equal(item.emptyEliminationCount, 4);
    assert.equal(item.typedResultCount, 4);
    assert.deepEqual(item.eliminations.map((entry) => [entry.name, entry.resultType]), expectedResults);
    for (const entry of item.eliminations) {
      assert.equal(entry.alternatives, 0);
      assert.equal(entry.typeArgumentCount, 1);
      assert.equal(entry.freshResultName, true);
      assert.equal(typeof entry.resultName, 'string');
      assert(entry.resultName.length > 0);
      assert(Array.isArray(entry.runtimeParameters));
      assert(entry.runtimeParameters.every((name) => typeof name === 'string' && name.length > 0));
      assert(!entry.runtimeParameters.includes(entry.resultName));
      if (entry.name === 'sh1EmptyFresh') assert(entry.runtimeParameters.includes('emptyResult'));
    }
    const raw = await artifact(outDir, directory + '/' + item.sourceArtifact, pin.sha256);
    assert.equal(raw.bytes, pin.bytes);
    assert.equal(item.typeScriptSha256, value.typeScriptSha256);
    assert.equal(item.typeScriptSha256, evidence.artifacts.typescriptSha256);
    const typescript = await artifact(outDir, directory + '/' + item.typeScriptArtifact, item.typeScriptSha256);
    observations.push({ sourceKind: kind, raw, typescript,
      sourceInputsSha256: evidence.sourceInputsSha256, originsSha256: origins.observationsSha256,
      eliminationsSha256: hash(JSON.stringify(item.eliminations)) });
  }
  return { observations, sourceKinds: 2, emptyLayoutsPerKind: 1, typedEliminationsPerKind: 4,
    emittedTypeScriptEqual: true, additionalPreparations: 0, additionalPortableIrChecks: 0,
    nativeValueOracle: false, observationsSha256: hash(JSON.stringify(value)) };
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
    const origins = sourceOriginObservation(evidence);
    sources.push({ sourceKind, raw, receipt: receipt.file, originsSha256: origins.observationsSha256 });
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


function genericFunctionObservations() {
  const pure = [
    ['generic-return-direct', '107'], ['generic-return-let', '107'],
    ['generic-higher-order-parameter', '37'], ['known-flat-entry-as-value', '37'],
    ['generic-record-field', '37'], ['generic-inductive-field', '37'],
    ['array-of-function-values', '37'], ['array-map-function-result', '37'],
    ['array-fold-binary-bridge', '15'], ['type-only-computed-value', '29'],
    ['type-only-function-instantiation', '107'], ['type-and-proof-only-activation', '53'],
    ['generic-lambda-body-result', '107'], ['generic-projection-computed-head', '37'],
  ].map(([id, value]) => ({ id, value, status: 'pass' }));
  const demand = [
    ...[['computed-closure-first', '35'], ['computed-closure-second', '43'],
      ['computed-closure-reuse', '35']].map(([id, value]) => ({ id, value, status: 'pass',
        diagnosticDomain: 'host-callback-demand' })),
    { id: 'computed-closure-discarded', trace: ['make', 'make'], status: 'pass',
      diagnosticDomain: 'host-callback-demand' },
    { id: 'computed-closure-original-fault', trace: ['make', 'make', 'make-failure'],
      status: 'pass', diagnosticDomain: 'host-callback-demand' },
  ];
  return { observations: [...pure, ...demand], observationCount: 19, status: 'pass',
    pureValueCases: 14, callbackDemandDiagnostics: 5,
    exhaustiveForAllInputs: false, sourceEffectCapabilityAdded: false };
}


function structuralRecursionObservations() {
  return [
    ['major-capture-two', 'sh1CoreMajorCapture', '2', '3'],
    ['major-capture-three', 'sh1CoreMajorCapture', '3', '6'],
    ['nested-outer-two', 'sh1CoreNestedOuter', '2', '3'],
    ['nested-outer-three', 'sh1CoreNestedOuter', '3', '6'],
  ].map(([id, declaration, input, value]) => ({ id, declaration, input, value, status: 'pass' }));
}

async function bindPreparedCoreRecursion(outDir, folder, source, value) {
  const reference = value.recursion.reference;
  const expected = structuralRecursionObservations();
  const behavior = { observations: expected, observationCount: 4, status: 'pass',
    exhaustiveForAllInputs: false };
  assert.deepEqual(value.recursion.behavior, behavior);
  assert.equal(reference.policy, 'prepared-core-nat-reference/1');
  assert.equal(reference.preparedObject, 'same PsCompilerAdmissionReadyModule used for original IR');
  assert.equal(reference.artifact.path, 'recursion-core.json');
  const core = await jsonFile(outDir, folder + '/recursion-core.json');
  assert.equal(core.file.sha256, reference.artifact.sha256);
  assert.equal(core.file.bytes, reference.artifact.bytes);
  assert.equal(core.value.schemaVersion, 1);
  assert.equal(core.value.evidence, 'actual-prepared-core-nat-recursion');
  assert.equal(core.value.sourceSha256, source.sha256);
  assert.equal(core.value.declarations.length, 2);
  assert.deepEqual(core.value.declarations.map((declaration) => declaration.name),
    ['sh1CoreMajorCapture', 'sh1CoreNestedOuter']);
  for (const declaration of core.value.declarations) {
    assert.equal(declaration.type.tag, 'forallE');
    assert.equal(declaration.type.binder, 'explicit');
    assert.equal(declaration.value.tag, 'lam');
    assert.equal(declaration.value.binder, 'explicit');
    for (const type of [declaration.type.type, declaration.type.body, declaration.value.type]) {
      assert.deepEqual(type, { tag: 'constE', name: [['str', 'Nat']], levels: [] });
    }
  }
  assert.deepEqual(reference.declarations, core.value.declarations.map((declaration) => ({
    name: declaration.name, sourceRuntimeArity: 1, coreSha256: hash(JSON.stringify(declaration)),
  })));
  assert.equal(reference.observationCount, 4);
  assert.equal(reference.observations.length, 4);
  let totalSteps = 0;
  for (let index = 0; index < 4; index++) {
    const { steps, recursorApplications, ...observation } = reference.observations[index];
    assert.deepEqual(observation, expected[index]);
    assert(Number.isSafeInteger(steps) && steps > 0 && steps <= 20000);
    assert(Number.isSafeInteger(recursorApplications) && recursorApplications > 0 &&
      recursorApplications <= steps);
    totalSteps += steps;
  }
  assert(totalSteps <= 20000);
  assert.deepEqual(reference.budget, { limit: 20000, used: totalSteps, remaining: 20000 - totalSteps,
    scope: 'shared across all four reference observations' });
  assert(Number.isSafeInteger(reference.snapshot.nodes) &&
    reference.snapshot.nodes > 0 && reference.snapshot.nodes <= 8192);
  assert.equal(reference.snapshot.nodeLimit, 8192);
  assert.equal(reference.snapshot.depthLimit, 128);
  assert.deepEqual(reference.supportedExecutableForms,
    ['bvar', 'lam', 'app', 'letE', 'lit.natural', 'constE']);
  assert.deepEqual(reference.runtimeConstants,
    ['Nat.zero', 'Nat.succ', 'Nat.add', 'Nat.rec', 'sh1CoreMajorCapture', 'sh1CoreNestedOuter']);
  assert.equal(reference.suppliedNatRecMinorClosures, true);
  for (const key of ['additionalPreparations', 'additionalTypeScriptCompilations',
    'additionalNativeExecutions']) assert.equal(reference[key], 0);
  assert.equal(reference.status, 'pass');
  assert.equal(reference.exhaustiveForAllInputs, false);
  assert.equal(reference.generalRecursorDemandAdequacy, false);
  if (value.native) assert.deepEqual(value.native.recursionBehavior, behavior);
  return { artifact: core.file, sourceSha256: source.sha256,
    declarations: reference.declarations, referenceObservationCount: 4,
    emittedObservationCount: 4, nativeObservationCount: value.native ? 4 : 0,
    observationsSha256: hash(JSON.stringify(expected)),
    referenceObservationsSha256: hash(JSON.stringify(reference.observations)),
    budget: reference.budget, snapshot: reference.snapshot,
    finiteEvidenceOnly: true, generalRecursorDemandAdequacy: false };
}

async function bindStructuralRecursionRefusals(outDir, directory, conformance) {
  const expected = [
    {
      "id": "nested-major-alias-lean",
      "sourceKind": "lean",
      "inputSha256": "f79fbfdbb2d0f19d74242f7c7f8395c95cf8646cf233d9588e9226a3273c6eb8",
      "code": "source-elaboration",
      "detail": "structuralRecursionNotDecreasing",
      "owner": "sh1NestedMajorAlias",
      "boundary": "structural-recursion-provenance"
    },
    {
      "id": "nested-major-alias-ps",
      "sourceKind": "ps",
      "inputSha256": "a69c438a49e2dfb519744a018d514f71270a60f3703d3fe49a286ba9a3ee5bda",
      "code": "source-elaboration",
      "detail": "structuralRecursionNotDecreasing",
      "owner": "sh1NestedMajorAlias",
      "boundary": "structural-recursion-provenance"
    },
    {
      "id": "nested-descendant-lean",
      "sourceKind": "lean",
      "inputSha256": "9a26a9d572d348f8380d547ac73779d2c85deb1aefb33cd71e654e3a51697bf8",
      "code": "source-elaboration",
      "detail": "structuralRecursionNotDecreasing",
      "owner": "sh1NestedDescendant",
      "boundary": "structural-recursion-provenance"
    },
    {
      "id": "nested-descendant-ps",
      "sourceKind": "ps",
      "inputSha256": "6e312e78fc3f13fa359ca715947ea175ddbe38e544ad2660dddd3730547fb8f4",
      "code": "source-elaboration",
      "detail": "structuralRecursionNotDecreasing",
      "owner": "sh1NestedDescendant",
      "boundary": "structural-recursion-provenance"
    },
    {
      "id": "implicit-major-dependent-proof",
      "sourceKind": "lean",
      "inputSha256": "8cb1ca86bca4886e47a11eba364c77790a49bb3cc2bdb1644aabe021c1e0948c",
      "code": "source-elaboration",
      "detail": "structuralRecursionDependentParameter",
      "owner": "sh1ImplicitMajorProof",
      "boundary": "structural-recursion-original-telescope"
    }
  ];
  const cases = await jsonFile(outDir, directory + '/strict-source/source-cases.json');
  assert.equal(cases.value.length, 38);
  assert.equal(conformance.refused.length, 38);
  assert.equal(new Set(cases.value.map((item) => item.id)).size, 38);
  assert.deepEqual(conformance.refused.map((item) => item.id), cases.value.map((item) => item.id));
  const observations = [];
  for (let index = 0; index < expected.length; index++) {
    const wanted = expected[index], test = cases.value[index + 33];
    assert.deepEqual({
      id: test.id, sourceKind: test.kind ?? 'lean', inputSha256: hash(JSON.stringify(test.inputs)),
      code: test.code, detail: test.expectedDetail, owner: test.expectedOwner, boundary: test.boundary,
    }, wanted);
    assert.deepEqual(test.limits ?? {}, {});
    const item = conformance.refused[index + 33];
    assert.deepEqual({
      id: item.id, sourceKind: item.sourceKind, inputSha256: item.inputSha256,
      code: item.failure.code, detail: item.failure.detail, owner: item.failure.owner,
      boundary: item.boundary,
    }, wanted);
    assert.equal(item.failure.stage, 'source');
    assert.equal(item.failure.compilerStage, 'elaboration');
    assert.deepEqual(item.limits, {});
    observations.push(wanted);
  }
  return { cases: cases.file, observations, observationCount: 5,
    observationBoundary: 'owned frontend structural elaboration',
    oldSourceRefusalCount: 33, totalSourceRefusalCount: 38,
    finiteEvidenceOnly: true, generalRecursorDemandAdequacy: false };
}


function bindRecursiveStructures(value, originalIr) {
  assert.equal(value.policy, 'recursive-structure-fields-and-root-hypotheses/1');
  assert.equal(value.compileOnly, true);
  assert.equal(value.structureCount, 2);
  assert.equal(value.declarationCount, 4);
  assert.equal(value.projectionCount, 6);
  assert.equal(value.usedHypothesisCount, 2);
  assert.equal(value.unusedHypothesisCount, 2);
  assert.deepEqual(value.originalIr, { ...originalIr, reusedExistingCheck: true });
  for (const key of ['runtimeInvocations', 'constructedRuntimeRecords',
    'additionalPreparations', 'additionalIrChecks', 'additionalTypeScriptCompilations',
    'additionalNativeExecutions']) assert.equal(value[key], 0);
  assert.equal(value.generalRecursorDemandAdequacyProven, false);
  assert.equal(value.semanticPreservationProven, false);
  const parameterType = { kind: 'typeParameter', name: 'T0' };
  const naturalType = { kind: 'primitive', name: 'nat' };
  const namedType = (name, parameters) => ({
    kind: 'named', name,
    arguments: parameters.map((parameter) => ({ kind: 'typeParameter', name: parameter })),
  });
  const layouts = [
    { name: 'Sh1RecursiveRecord', typeParameters: [], recursiveFieldIndex: 0,
      fields: [{ name: 'next', type: namedType('Sh1RecursiveRecord', []) }] },
    { name: 'Sh1RecursiveGenericRecord', typeParameters: ['T0'], recursiveFieldIndex: 1,
      fields: [{ name: 'item', type: parameterType },
        { name: 'next', type: namedType('Sh1RecursiveGenericRecord', ['T0']) }] },
  ];
  assert.deepEqual(value.layouts, layouts);
  const specs = [
    { name: 'sh1RecursiveRecordObserve', layout: 0, result: naturalType, outcome: 'zero' },
    { name: 'sh1RecursiveRecordStep', layout: 0, result: naturalType, outcome: 'recursive-call' },
    { name: 'sh1RecursiveGenericObserve', layout: 1, result: parameterType, outcome: 'item' },
    { name: 'sh1RecursiveGenericStep', layout: 1, result: parameterType, outcome: 'recursive-call' },
  ];
  assert.equal(value.declarations.length, specs.length);
  value.declarations.forEach((observed, index) => {
    const expected = specs[index], layout = layouts[expected.layout];
    const inputType = namedType(layout.name, layout.typeParameters);
    assert.equal(observed.parameters.length, 1);
    assert.equal(observed.projections.length, layout.fields.length);
    const parameter = observed.parameters[0].name;
    const major = observed.major.name;
    const bindings = observed.projections.map((projection) => projection.binding);
    const names = [parameter, major, ...bindings];
    assert(names.every((name) => typeof name === 'string' && name.length > 0));
    assert.equal(new Set(names).size, names.length, 'PSC0_SH1_RECURSIVE_STRUCTURE_BINDER_DISTINCT');
    assert(names.every((name) => !specs.some((item) => item.name === name) &&
      !layouts.some((item) => item.name === name)));
    let body;
    if (expected.outcome === 'recursive-call') {
      body = { kind: 'recursive-call', declaration: expected.name,
        typeArguments: inputType.arguments, arguments: [bindings[layout.recursiveFieldIndex]],
        runtimeArity: 1 };
    } else if (expected.outcome === 'zero') {
      body = { kind: 'natural', value: '0' };
    } else {
      body = { kind: 'field', field: 'item', binding: bindings[0] };
    }
    assert.deepEqual(observed, {
      name: expected.name, structure: layout.name, typeParameters: layout.typeParameters,
      parameters: [{ name: parameter, type: inputType }],
      resultType: expected.result,
      major: { name: major, sourceParameter: parameter, type: inputType, evaluations: 1, fresh: true },
      projections: layout.fields.map((field, fieldIndex) => ({
        index: fieldIndex, field: field.name, binding: bindings[fieldIndex],
        type: field.type, target: major,
      })),
      recursiveFieldIndex: layout.recursiveFieldIndex, body,
      freshNamesDistinct: true, remainingHypothesisLambdas: 0,
    });
  });
  assert.equal(value.declarations.reduce((count, item) => count + item.projections.length, 0), 6);
  assert.equal(value.declarations.filter((item) => item.body.kind === 'recursive-call').length, 2);
  return {
    policy: value.policy, compileOnly: true, structureCount: 2, declarationCount: 4,
    projectionCount: 6, usedHypothesisCount: 2, unusedHypothesisCount: 2,
    layouts: value.layouts, declarations: value.declarations,
    layoutsSha256: hash(JSON.stringify(value.layouts)),
    declarationsSha256: hash(JSON.stringify(value.declarations)),
    originalIr: value.originalIr,
    runtimeInvocations: 0, constructedRuntimeRecords: 0,
    additionalPreparations: 0, additionalIrChecks: 0,
    additionalTypeScriptCompilations: 0, additionalNativeExecutions: 0,
    finiteEvidenceOnly: true, generalRecursorDemandAdequacyProven: false,
    semanticPreservationProven: false,
  };
}

async function bindGenericFunctionValues(outDir, directory, compilerSha256, source, requireNative) {
  const folder = directory + '/generic-erasure';
  const receipt = await jsonFile(outDir, folder + '/receipt.json');
  const value = receipt.value;
  assert.equal(value.schemaVersion, 1);
  assert.equal(value.evidence, 'scoped-recursive-generic-erasure');
  assert.equal(value.compilerSha256, compilerSha256);
  assert.equal(value.sourceKind, 'raw-authoritative-lean');
  assert.equal(value.sourceSha256, source.sha256);
  noStrictClaim(value.originalIr, 'generic original IR');
  assert.deepEqual(value.behavior,
    { observations: 19, status: 'pass', exhaustiveForAllInputs: false });
  const group = value.functionValues;
  assert.equal(group.ir.policy, 'canonical-unary-values-flat-aligned-entries/1');
  assert.deepEqual(group.ir.sourceEntries, [
    ['sh1GroupIdentity', 1], ['sh1GroupDirect', 1], ['sh1GroupLet', 1],
    ['sh1GroupApply', 2], ['sh1GroupHigher', 1], ['sh1GroupWeighted', 2],
    ['sh1GroupKnown', 0], ['sh1GroupRecordUse', 1], ['sh1GroupBoxUse', 1],
    ['sh1GroupArrayUse', 1], ['sh1GroupArrayMap', 1], ['sh1GroupArrayFold', 0],
    ['sh1GroupComputed', 2], ['sh1GroupTypeOnlyUse', 1],
    ['sh1GroupTypeOnlyHigher', 1], ['sh1GroupTypeProofOnlyUse', 1],
    ['sh1GroupLambda', 1], ['sh1GroupProjection', 1],
  ].map(([name, runtimeArity]) => ({ name, runtimeArity })));
  assert.deepEqual(group.ir.typeActivationEntries,
    ['sh1GroupTypeOnly', 'sh1GroupTypeProofOnly'].map((name) => ({
      name, sourceRuntimeArity: 0, physicalRuntimeArity: 1,
      internalActivation: 'fresh-ignored-unit', typeArity: 1,
    })));
  assert(Number.isSafeInteger(group.ir.typeNodes) && group.ir.typeNodes > 0 &&
    group.ir.typeNodes <= 10000);
  assert(Number.isSafeInteger(group.ir.unaryFunctionNodes) && group.ir.unaryFunctionNodes > 0 &&
    group.ir.unaryFunctionNodes <= group.ir.typeNodes);
  const original = group.ir.originalIr;
  assert.equal(original.accepted, true);
  assert.equal(original.traversalComplete, true);
  assert.equal(original.findingCount, '0');
  assert.equal(original.checkedObjectIsEmittedObject, true);
  for (const key of ['expressionCount', 'visitedSteps']) {
    assert.equal(typeof original[key], 'string');
    assert(/^[1-9][0-9]*$/.test(original[key]));
  }
  for (const key of ['additionalPreparations', 'additionalTypeScriptCompilations',
    'additionalNativeExecutions']) assert.equal(group.ir[key], 0);
  assert.deepEqual(group.behavior, genericFunctionObservations());
  const recursion = await bindPreparedCoreRecursion(outDir, folder, source, value);
  const recursiveStructures = bindRecursiveStructures(value.recursiveStructures, original);
  assert.deepEqual(value.provider, { status: 'not-attempted', kernelChecked: false });
  const products = {
    admissions: await artifact(outDir, folder + '/admissions.json', value.artifacts.admissionsSha256),
    typescript: await artifact(outDir, folder + '/generated/index.ts', value.artifacts.typescriptSha256),
    javascript: await artifact(outDir, folder + '/generated/index.js', value.artifacts.javascriptSha256),
  };
  let native = null;
  if (requireNative) assert(value.native, 'PSC0_SH1_GENERIC_NATIVE_REFERENCE_REQUIRED');
  if (value.native) {
    assert.equal(value.native.typescriptSha256, value.artifacts.typescriptSha256);
    assert.deepEqual(value.native.behavior, value.behavior);
    assert.deepEqual(value.native.functionValueBehavior, group.behavior);
    native = {
      typescript: await artifact(outDir, folder + '/native/index.ts', value.native.typescriptSha256),
      javascript: await artifact(outDir, folder + '/native/index.js', value.native.javascriptSha256),
      oldRecursiveObservationCount: 19, pureValueCount: 14, hostDemandDiagnosticCount: 5,
    };
  }
  return { receipt: receipt.file, source, artifacts: products, native, recursion, recursiveStructures,
    originalIr: original, policy: group.ir.policy,
    sourceEntries: group.ir.sourceEntries, typeActivationEntries: group.ir.typeActivationEntries,
    oldRecursiveObservationCount: 19, pureValueCount: 14, hostDemandDiagnosticCount: 5,
    observationsSha256: hash(JSON.stringify(group.behavior.observations)),
    finiteEvidenceOnly: true, sourceEffectCapabilityAdded: false };
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
  const sourceEvaluationReference = await bindSourceEvaluationReference(outDir, reference.sourceEvaluationReference);
  const generations = [
    ['N1', 'development/N1', nativeReceipt.artifacts.javascriptSha256],
    ['C1', 'C1', firstReceipt.artifacts.javascriptSha256],
    ['C2', 'C2', secondReceipt.artifacts.javascriptSha256],
    ['C3', 'C3', thirdReceipt.artifacts.javascriptSha256],
  ];
  const genericBytes = await readFile(new URL('../test/fixtures/selfhost-sh1-generic-erasure.lean', import.meta.url));
  const genericSource = { path: 'test/fixtures/selfhost-sh1-generic-erasure.lean',
    sha256: hash(genericBytes), bytes: genericBytes.length };
  const generationEvidence = [];
  for (const [name, directory, compilerSha256] of generations) {
    const source = await jsonFile(outDir, directory + '/strict-source/receipt.json');
    assert.equal(source.value.evidence, 'portable-source-boundary-conformance');
    assert.equal(source.value.compilerSha256, compilerSha256);
    noStrictClaim(source.value, name + ' source conformance');
    assert.equal(source.value.semanticContractQualified, false);
    assert.equal(source.value.accepted.length, 2);
    assert.equal(source.value.refused.length, 38);
    assert.equal(source.value.carrierRefusals.length, 2);
    for (const item of source.value.accepted) {
      assert.equal(item.compilerSha256, compilerSha256);
      assert.equal(item.sourcePolicy.accepted, true);
      assert.equal(item.sourcePolicy.traversalComplete, true);
      assert.equal(item.sourcePolicy.profile, 'PSC0-SH/1');
      targetPolicy(item.targetPolicy);
      typed(item.originalIr);
      sourceOriginObservation(item);
      noStrictClaim(item, name + ' accepted source');
      assert.equal(item.semanticContractQualified, false);
    }
    assert(source.value.refused.every((item) => typeof item.failure.code === 'string'));
    const structuralRecursionRefusals = await bindStructuralRecursionRefusals(outDir, directory, source.value);
    assert(source.value.carrierRefusals.every((item) => item.refused === true));
    const ingressSnapshots = bindIngressSnapshots(source.value.ingressSnapshots, source.value.accepted);
    const emptySource = await bindEmptySource({ outDir, directory: directory + '/strict-source',
      compilerSha256, conformance: source.value });
    const zeroFieldSource = bindZeroFieldSource(source.value, emptySource);
    const emptyIr = await bindEmptyIr({ outDir, directory: directory + '/ir-checker', compilerSha256 });
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
    const sourceEvaluation = await bindSourceEvaluation({ outDir,
      directory: directory + '/strict-runtime', compilerSha256,
      value: runtime.value.sourceEvaluationRegression, native: sourceEvaluationReference });
    const capabilityOrigins = await bindCapabilityOrigins(outDir, directory, compilerSha256);
    const genericFunctionValues = await bindGenericFunctionValues(outDir, directory,
      compilerSha256, genericSource, name === 'N1');
    const compiler = await artifact(outDir, directory + '/index.js', compilerSha256);
    generationEvidence.push({ name, compiler, source: source.file, target: target.file, runtime: runtime.file,
      sourceEquality, sourceEvaluation, capabilityOrigins, ingressSnapshots, emptySource, zeroFieldSource, emptyIr,
      genericFunctionValues, structuralRecursionRefusals,
      operationCount: 45, observationCount: 186, sourceRefusals: 38, targetRefusals: 20 });
  }

  const nativeFile = await jsonFile(outDir, 'development/N1/strict-source-native.json');
  const native = nativeFile.value;
  assert.equal(native.evidence, 'native-atomic-source-and-target-enforcement');
  sourcePolicy(native.sourcePolicy, closure);
  targetPolicy(native.targetPolicy);
  typed(native.originalIr);
  const nativeOrigins = sourceOriginObservation(native, false);
  assert.equal(native.semanticContractQualified, false);
  assert.equal(native.providerChecked, false);
  noStrictClaim(native, 'native source');
  const nativeEmptyIr = await bindNativeEmptyIr({ outDir, closure, nativeReceipt, nativeSource: nativeFile });
  const expectedInputs = strictSourceInputsFromClosure(closure).map(({ moduleName, source }) => ({
    moduleName, sourceSha256: hash(source), sourceBytes: Buffer.byteLength(source),
  }));
  const expectedInputHash = hash(JSON.stringify(expectedInputs));
  assert.deepEqual(nativeOrigins.common.modules.map((module) => module.moduleName),
    expectedInputs.map((input) => input.moduleName));
  const atomicBuilds = [{ name: 'native produces N1', source: nativeFile.file,
    compilerBinarySha256: nativeReceipt.nativeCompiler.binarySha256,
    sourcePolicy: native.sourcePolicy, targetPolicy: native.targetPolicy,
    originsSha256: nativeOrigins.observationsSha256 }];
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
    const origins = sourceOriginObservation(value);
    assert.deepEqual(origins.common, nativeOrigins.common, 'PSC0_SH1_NATIVE_ORIGIN_PARITY');
    assert.equal(value.semanticContractQualified, false);
    assert.equal(value.providerChecked, false);
    noStrictClaim(value, name);
    assert.equal(value.artifacts.typescriptSha256, receipt.artifacts.typescriptSha256);
    assert.equal(value.artifacts.admissionsSha256, receipt.artifacts.normalizedCanonicalAdmissionsSha256);
    assert.deepEqual(value.sourcePolicy.stats, native.sourcePolicy.stats);
    assert.equal(value.targetPolicy.visitedSteps, native.targetPolicy.visitedSteps);
    atomicBuilds.push({ name, source: source.file, executingCompilerSha256: producer,
      sourceInputsSha256: expectedInputHash, sourcePolicy: value.sourcePolicy, targetPolicy: value.targetPolicy,
      originsSha256: origins.observationsSha256 });
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
    atomicBuilds, generations: generationEvidence, artifacts, nativeEmptyIr,
    sourceOrigins: { policy: nativeOrigins.common.policy,
      observationsSha256: nativeOrigins.observationsSha256,
      moduleCount: nativeOrigins.common.moduleCount,
      sourceDeclarationCount: nativeOrigins.common.sourceDeclarationCount,
      coreDeclarationCount: nativeOrigins.common.coreDeclarationCount,
      normalizationCount: nativeOrigins.common.normalizationCount,
      semanticCorrespondenceDischarged: false },
    sourceEvaluationReference: {
      receipt: sourceEvaluationReference.receipt, source: sourceEvaluationReference.source,
      rawSource: sourceEvaluationReference.rawSource, stdout: sourceEvaluationReference.stdout,
      stderr: sourceEvaluationReference.stderr, observationCount: 24,
      observationsSha256: sourceEvaluationReference.observationsSha256,
    },
    sourceEnforcementQualified: true, targetAdmissionQualified: true,
    enabledRuntimeFiniteConformanceQualified: true,
    genericFunctionValueFiniteConformanceQualified: true,
    strictSh1Qualified: false, semanticContractQualified: false,
    providerChecked: false,
  };
}
