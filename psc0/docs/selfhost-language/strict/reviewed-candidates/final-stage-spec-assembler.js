/*
Pure mechanical final27/SPEC assembler for compiled source 1fa and the reviewed
evidence-only completion. Original 380151 remains cancelled and owns N1/C1;
380216 remains failed and owns completed C2/C3. Current run 38027413274
owns corrected evidence binding, new qualification records and separate provider.
No tools, filesystem, compiler, conformance tests, commits or ref operations.
Caller authenticates actual release/final33 bytes, original generation archives,
all required receipt observations, provider decisions and exact source identities.
Inputs retain the established function signature. procedure/transport/
correspondenceProcedure/projectedRelease are the exact projections after the
evidence-completion metadata overlays; projectedRelease precedes c5/evidence fills.
ledgerText, mapText/reviewText and specText remain exact ceabd,697/f6cc and61f.
Actual release/final33 references are immutable {path,blob,sha256,bytes}.
evidence contains qualification,strictBinder,provider,resolveReceiptGroupIds,
evidenceFinishInputs,evidenceInventory,evidenceCompletion and their three *Value
parsed JSON values. All six file envelopes match the actual execution fields;
the three completion values use exact JSON.stringify(value,null,2)+LF bytes.
The receipt resolver preserves the existing wrapper and exact ordered group IDs.
Large selectors retain the authenticated file/pointer/value-hash representation;
small values must match their exact JSON value hash and byte count.
Original48 generation recipe and binder remain generation provenance; the
corrected binder/finisher are separate evidence producers. No original receipt,
producer false flag, source argument/domain, static catalog guard or selection
boundary is rewritten. Final ledger/SPEC candidates require actual completion.
This function does not publish or apply root-owned aggregate assignments.
*/
function assembleFinal27AndSpec(input) {
  "use strict";
  const {ledgerText, procedure, mapText, reviewText, transport, correspondenceProcedure,
    projectedRelease, specText, releaseText, releaseRef, correspondenceText,
    correspondenceRef, evidence:A, sha256} = input;
  const fail = message => { throw new Error("final27/SPEC: " + message); };
  const need = (condition, message) => { if (!condition) fail(message); };
  const own = (value, key) => Object.prototype.hasOwnProperty.call(value, key);
  const clone = value => JSON.parse(JSON.stringify(value));
  const json = value => JSON.stringify(value);
  const same = (actual, expected, message) => need(json(actual) === json(expected), message);
  const H = value => sha256(json(value));
  const length = text => unescape(encodeURIComponent(text)).length;
  const pretty = value => JSON.stringify(value, null, 2) + "\n";
  const hash64 = value => typeof value === "string" && /^[a-f0-9]{64}$/.test(value);
  const at = (value, pointer) => {
    need(typeof pointer === "string" && (pointer === "" || pointer[0] === "/"), "invalid JSON pointer");
    for (const part of pointer === "" ? [] : pointer.slice(1).split("/")) {
      const key = part.replace(/~1/g, "/").replace(/~0/g, "~");
      need(value !== null && typeof value === "object" && own(value, key), "missing pointer " + pointer);
      value = value[key];
    }
    return value;
  };
  const textGuard = (text, hash, bytes, name) => {
    need(typeof text === "string" && sha256(text) === hash && length(text) === bytes, name + " byte/hash guard");
  };
  const objectGuard = (value, hash, bytes, name) => {
    textGuard(pretty(value), hash, bytes, name);
    return clone(value);
  };
  const reference = (ref, text, name) => {
    need(ref && typeof ref.path === "string" && ref.path.length > 0 &&
      typeof ref.blob === "string" && /^[a-f0-9]{40}$/.test(ref.blob) &&
      hash64(ref.sha256) && Number.isSafeInteger(ref.bytes) && ref.bytes > 0, name + " immutable reference");
    textGuard(text, ref.sha256, ref.bytes, name);
    return clone(ref);
  };
  const external = (ref, jsonPointer) => ({...clone(ref), jsonPointer});
  const envelope = (actual, expected, name) => {
    need(actual && typeof actual.path === "string" && hash64(actual.sha256) &&
      Number.isSafeInteger(actual.bytes) && actual.bytes >= 0, name + " actual envelope");
    for (const key of ["path", "sha256", "bytes"]) same(actual[key], expected[key], name + "." + key);
    need(actual.retainedBlob != null || actual.receiptOrEnvelopeRef != null ||
      actual.authentication != null, name + " retained/authenticated provenance");
    return clone(actual);
  };
  const staticGroup = g => ({id:g.id, files:g.files, required:g.required, selectors:g.selectors, limit:g.limit});
  const source = "1fa5559a72b293defc56ef7e7020cf82d4b44b79";
  const closure = "46737f1e58a56cfa4cc0b575d30f531efe1dbe06ccf34002cc01e553febb1fb5";
  const recipeHash = "a631bcaf914c0913f696eaf8a138a44449c46957f5a2d7736ec9cff8bcb63eba";
  const finalPath = "psc0/docs/selfhost-language/strict/release-qualification.json";
  need(typeof sha256 === "function" && A && typeof A.resolveReceiptGroupIds === "function", "pure SHA256 and authenticated receipt resolver are required");

  textGuard(ledgerText, "532f51996168532dfaeb65502d23be90beb2109fd6844bc9a53602fa1c6bab05", 64060, "ceabd ledger");
  const L = JSON.parse(ledgerText);
  const P = objectGuard(procedure, "0c04837d06a342832a73c8b8074c0882d20a3ffc949f256a561368a9336edb95", 299923, "evidence-completion projected27 plan");
  const T = objectGuard(transport, "420a7da2573ef20f09f058eb62d33ac6d146093374b6aadc170300777f507603", 207015, "evidence-completion projected transport");
  const CP = objectGuard(correspondenceProcedure, "94e4c5c8332889ae04fcbc2e27db7b2efb93210c47b2faca145620a93acc9d60", 204356, "evidence-completion projected33 procedure");
  const B = objectGuard(projectedRelease, "9d43138c419708fda4b55e3e098a8f9565cd6a120cc98e7ac42ba60b487bc4c3", 364637, "evidence-completion projected release before final catalog/evidence");
  textGuard(mapText, P.fixedMappings.map.sha256, P.fixedMappings.map.bytes, "frozen697 map");
  textGuard(reviewText, P.fixedMappings.independentStageReview.sha256, P.fixedMappings.independentStageReview.bytes, "frozen f6cc stage review");
  const M = JSON.parse(mapText), V = JSON.parse(reviewText);
  const RR = reference(releaseRef, releaseText, "actual final release");
  const CR = reference(correspondenceRef, correspondenceText, "actual final33 ledger");
  const R = JSON.parse(releaseText), C = JSON.parse(correspondenceText);
  need(RR.path === finalPath && CR.path === "psc0/docs/selfhost-language/strict/correspondence-obligations.json", "final document paths");
  need(R.schemaVersion === 1 && R.kind === "psc0-sh1-release-qualification" &&
    R.draftOnly !== true && R.closesNoRows !== true, "completed release identity");
  need(L.rows.length === 27 && P.rowPlans.length === 27 && R.stageDispositions.length === 27 &&
    C.rows.length === 33 && CP.rowPlans.length === 33 && R.correspondenceDispositions.length === 33, "33/27 cardinalities");
  need(H(L.rows) === "9bab4ee9cdf1dc7305402ebe09d3b1e0375d0992227ebae4999e79820922eea5", "original27 row array");

  // Authentication of actual supplied material is a caller precondition.
  // These consistency checks add no compiler, provider, or observation gate.
  same(R.source.sourceRef, source, "qualified source");
  same(R.qualification.qualifiedSourceRef, source, "qualification source");
  for (const key of ["rootTree", "psc0Tree", "sourceAuthority", "sourceGrammar", "currentReviewedSourcePins"])
    same(R.source[key], B.source[key], "source." + key);
  same(R.qualification.scope, B.qualification.scope, "declared .lean/new-only/TS7 scope");
  same(R.source.sourceClosureSha256, closure, "actual source closure");
  // Pure consistency checks on already authenticated evidence; no repeated execution.
  const K = {
    "sourceRef": "1fa5559a72b293defc56ef7e7020cf82d4b44b79",
    "sourceClosureSha256": "46737f1e58a56cfa4cc0b575d30f531efe1dbe06ccf34002cc01e553febb1fb5",
    "recipeSha256": "a631bcaf914c0913f696eaf8a138a44449c46957f5a2d7736ec9cff8bcb63eba",
    "orchestrationHeadSha": "719f5ec4225baf51d1969cc3b5e4cbc6959fad4a",
    "runId": 38027413274,
    "runAttempt": 1,
    "workflowId": 380282667,
    "compilerJobId": 114141103218,
    "sourceRoot": "/home/runner/work/pskernel/pskernel/psc0",
    "authenticatedArchives": [
      {
        "runId": 38015134511,
        "artifactId": 11658430459,
        "name": "psc0-sh1-ts7.0.2-1fa5559a72b293defc56ef7e7020cf82d4b44b79",
        "sha256": "6ee7b3da60346bec004665d9bb2276ceb680a1a3d882d0aeb397398a9e1c1812",
        "bytes": 5147944,
        "fileCount": 344,
        "rawArchivePath": "dist/sh1-continuation-inputs/predecessor-verified.zip"
      },
      {
        "runId": 38021634599,
        "artifactId": 11659939542,
        "name": "psc0-sh1-continuation-ts7.0.2-38021634599",
        "sha256": "599fd5160f132d0795246bc102f8b306ae3bd8d42238201cef2d3e69dbef6f80",
        "bytes": 11739089,
        "fileCount": 444,
        "rawArchivePath": "dist/sh1-evidence-finish-inputs/predecessor-verified.zip"
      }
    ],
    "generationOwners": {
      "N1": {
        "runId": 38015134511,
        "compilerJobId": 114103608774
      },
      "C1": {
        "runId": 38015134511,
        "compilerJobId": 114103608774
      },
      "C2": {
        "runId": 38021634599,
        "compilerJobId": 114123691566
      },
      "C3": {
        "runId": 38021634599,
        "compilerJobId": 114123691566
      }
    },
    "generationLog": {
      "path": "dist/sh1-evidence-finish-inputs/source-generation-job.log",
      "blob": "6747dc056c2642f069cc1c45c37f9dea492e0b50",
      "sha256": "1ee74d4316074988052bb6e1e86f14d6ede117c03af8e46a3f469c46e6aa3548",
      "bytes": 875228
    },
    "generationReceipts": {
      "N1": {
        "path": "dist/sh1/development/N1/receipt.json",
        "sha256": "6768f5d50c376b50c6138aeacffe03553c9f860b17da965ea92acd3a36126404",
        "bytes": 15827
      },
      "C1": {
        "path": "dist/sh1/C1/receipt.json",
        "sha256": "33fa94c5f4f825133be4c07f47e8f68d447546eb8a2858193d16b305afbd9d8f",
        "bytes": 169531
      },
      "C2": {
        "path": "dist/sh1/C2/receipt.json",
        "sha256": "5da7545d89d7b28a4f296cbd1bd3b154aef5bac38af143caa836deb5c61f5a02",
        "bytes": 166707
      },
      "C3": {
        "path": "dist/sh1/C3/receipt.json",
        "sha256": "eaf6c772de3d9f27b4b1a42412746165b22be0c5cf431944827c95af7d8050d1",
        "bytes": 166709
      }
    },
    "originalQualifier": {
      "path": "scripts/sh1-qualify.mjs",
      "blob": "e2c55f900b0ba4fe29cdc7e2981160a49ef4d61d",
      "sha256": "707fedd63f01999293cf68b39f85ea6526c31216e84c2090d6ff1b8edf6fecdb",
      "bytes": 73618
    },
    "originalBinder": {
      "path": "scripts/sh1-strict-evidence.mjs",
      "blob": "b0b080eea2c353640f12d744e599737d71f9c4f6",
      "sha256": "bd18cbb77c80fb57038b7d270e468c5b029164095dad958a84c52d113d67b049",
      "bytes": 91970
    }
  };
  const hexBlob = value => typeof value === "string" && /^[a-f0-9]{40}$/.test(value);
  const checkEnvelope = (value, path, name) => envelope(value, {...value,path}, name);
  const hashText = (text, hash, name) => need(sha256(text) === hash, name);
  const digest = (value, hash, name) => need(H(value) === hash, name);
  const bytes = length;
  const expectedExecution = P.currentInput.continuationExecution;
  same(expectedExecution, T.continuationExecution, "shared evidence-completion execution contract");
  const execution = R.execution;
  need(hexBlob(K.orchestrationHeadSha) && K.orchestrationHeadSha !== K.sourceRef &&
       [K.runId, K.runAttempt, K.workflowId, K.compilerJobId].every(value =>
         Number.isSafeInteger(value) && value > 0),
       "actual evidence-completion identity is still pending");
  same(execution.expectedHeadSha, K.orchestrationHeadSha, "evidence-producer orchestration head");
  same(execution.requiredSourceRef, K.sourceRef, "unchanged compiled source");
  same(execution.expectedRunId, K.runId, "actual evidence-completion run");
  same(execution.runAttempt, K.runAttempt, "actual evidence-completion run attempt");
  same(execution.expectedWorkflowId, K.workflowId, "actual evidence-completion workflow");
  same(execution.compilerJobId, K.compilerJobId, "actual evidence-completion job");
  same(execution.compilerConclusion, "success", "actual evidence-completion job conclusion");
  same(execution.providerConclusion, "success", "actual separate provider conclusion");
  for (const field of [
    "expectedRunId", "expectedWorkflowId", "expectedHeadSha", "requiredSourceRef",
    "runAttempt", "compilerJobId", "workflowSourceBlob", "orchestration",
    "priorExecution", "continuationInputs", "continuationInputsRole",
    "generationExecution", "evidenceProducer", "evidenceProducerRepair",
    "generationOwnership", "logOnlyGateOwnership", "currentOutputOwnership"
  ]) same(execution[field], expectedExecution[field], "execution provenance " + field);
  same(execution.priorExecution.expectedRunId, 38015134511, "original generation run");
  same(execution.priorExecution.compilerJobId, 114103608774, "original generation compiler");
  same(execution.priorExecution.compilerConclusion, "cancelled", "original cancellation preserved");
  same(execution.priorExecution.providerConclusion, "skipped", "original provider skip preserved");
  same(execution.generationExecution.expectedRunId, 38021634599, "completed generation run");
  same(execution.generationExecution.compilerJobId, 114123691566, "completed generation compiler");
  same(execution.generationExecution.compilerConclusion, "failure", "generation-run failure preserved");
  same(execution.generationExecution.providerConclusion, "skipped", "generation-run provider skip preserved");
  same(execution.evidenceProducer.sourceRef, K.orchestrationHeadSha, "actual separate producer source");
  same(execution.evidenceProducer.currentExecution, {
    runId: K.runId, workflowId: K.workflowId, runAttempt: K.runAttempt,
    compilerJobId: K.compilerJobId, headSha: K.orchestrationHeadSha
  }, "actual separate producer execution");
  need(Number.isSafeInteger(execution.providerJobId) && execution.providerJobId > 0 &&
       execution.providerJobId !== execution.priorExecution.providerJobId &&
       execution.providerJobId !== execution.generationExecution.providerJobId &&
       K.compilerJobId !== execution.priorExecution.compilerJobId &&
       K.compilerJobId !== execution.generationExecution.compilerJobId &&
       K.runId !== execution.priorExecution.expectedRunId &&
       K.runId !== execution.generationExecution.expectedRunId,
       "evidence finish and provider identities must be distinct from generation origins");
  const carried = execution.evidenceCompletionInputs;
  for (const [field, value] of Object.entries(expectedExecution.evidenceCompletionInputs)) {
    if (!["inputsFile", "evidenceInventoryFile", "completionFile"].includes(field))
      same(carried[field], value, "evidence-completion input contract " + field);
  }

  same(P.currentInput.continuationExecution, CP.currentInput.continuationExecution, "stage/correspondence evidence-completion contract");
  need(Array.isArray(execution.configuredWorkflowGateOutcomes) &&
    execution.configuredWorkflowGateOutcomes.length > 0, "actual configured evidence-workflow steps");
  need(typeof execution.completedAtUtc === "string" && execution.completedAtUtc.length > 0, "actual terminal completion time");
  for (const [key, field, valueKey] of [
    ["evidenceFinishInputs", "inputsFile", "evidenceFinishInputsValue"],
    ["evidenceInventory", "evidenceInventoryFile", "evidenceInventoryValue"],
    ["evidenceCompletion", "completionFile", "evidenceCompletionValue"]
  ]) {
    const file = expectedExecution.evidenceCompletionInputs[field];
    checkEnvelope(A[key], file.path, "actual " + key + " envelope");
    same(carried[field], A[key], "actual " + key + " release-envelope binding");
    need(A[valueKey] !== null && typeof A[valueKey] === "object",
         "actual " + key + " parsed JSON absent");
    const text = pretty(A[valueKey]);
    hashText(text, A[key].sha256, "actual " + key + " producer serialization");
    same(bytes(text), A[key].bytes, "actual " + key + " producer bytes");
  }
  const imported = A.evidenceFinishInputsValue, inventory = A.evidenceInventoryValue;
  const completion = A.evidenceCompletionValue;
  for (const [field, value] of Object.entries({
    schemaVersion: 1, kind: "psc0-authenticated-retained-fixed-point-finish-inputs",
    compiledSourceRef: K.sourceRef, sourceRoot: K.sourceRoot,
    outputRoot: K.sourceRoot + "/dist/sh1", sourceClosureSha256: K.sourceClosureSha256,
    recipeSha256: K.recipeSha256, evidenceProducer: execution.evidenceProducer,
    generationOwnership: K.generationOwners, reusedGenerations: ["N1", "C1", "C2", "C3"],
    generatedThisCommand: [], archiveFileCount: 444,
    currentSourceAndAll48RecipeInputsUnchanged: true, allImportedEvidenceUnchanged: true,
    compilerExecutedByThisImport: false, strictSh1Qualified: false,
    semanticContractQualified: false, providerChecked: false
  })) same(imported[field], value, "authenticated evidence-finish input " + field);
  digest(imported.expected, carried.requiredInputExpectedConstantsSha256,
         "exact reviewed workflow import requirements");
  same(carried.requiredInputExpectedConstantsSha256,
       "6da2382a06b079e8b6469c43d721ce3753b2e2a83f74333c08bc62593f302c96",
       "pinned evidence-finish import constants");
  for (const [key, producer] of [
    ["nativeAndCandidate", execution.priorExecution],
    ["secondAndThird", execution.generationExecution]
  ]) {
    const observed = imported.generationExecutions[key];
    for (const [field, value] of Object.entries({
      id: producer.expectedRunId, workflow_id: producer.expectedWorkflowId,
      head_sha: producer.expectedHeadSha, run_attempt: producer.runAttempt,
      status: "completed", conclusion: producer.compilerConclusion
    })) same(observed.run[field], value, "actual generation-origin run " + key + "/" + field);
    for (const [field, value] of Object.entries({
      id: producer.compilerJobId, status: "completed", conclusion: producer.compilerConclusion
    })) same(observed.compilerJob[field], value, "actual generation-origin compiler " + key + "/" + field);
    for (const [field, value] of Object.entries({
      id: producer.providerJobId, status: "completed", conclusion: "skipped"
    })) same(observed.providerJob[field], value, "actual historical provider skip " + key + "/" + field);
  }
  same(imported.generationExecutions.secondAndThird.artifact.id, 11659939542,
       "actual completed-generation artifact");
  same(imported.generationExecutions.secondAndThird.artifact.digest,
       "sha256:599fd5160f132d0795246bc102f8b306ae3bd8d42238201cef2d3e69dbef6f80",
       "actual completed-generation artifact digest");
  const earlierInputs = imported.originalContinuationInputs;
  const earlierEnvelope = execution.generationExecution.importInputs;
  same(earlierInputs.path, earlierEnvelope.path, "earlier continuation input path");
  same(earlierInputs.blob, earlierEnvelope.retainedBlob, "earlier continuation input blob");
  same(earlierInputs.sha256, earlierEnvelope.sha256, "earlier continuation input digest");
  same(earlierInputs.bytes, earlierEnvelope.bytes, "earlier continuation input byte count");
  hashText(pretty(earlierInputs.value), earlierEnvelope.sha256,
           "unchanged authentic earlier continuation input bytes");
  same(bytes(pretty(earlierInputs.value)), earlierEnvelope.bytes,
       "unchanged authentic earlier continuation input length");
  need(Array.isArray(imported.authenticatedArchives) &&
       imported.authenticatedArchives.length === K.authenticatedArchives.length,
       "two authenticated source-generation archives");
  for (let index = 0; index < K.authenticatedArchives.length; index++) {
    for (const [field, value] of Object.entries(K.authenticatedArchives[index]))
      same(imported.authenticatedArchives[index][field], value,
           "pinned source-generation archive " + index + "/" + field);
  }
  for (const [field, value] of Object.entries(K.generationLog))
    same(imported.generationLog[field], value, "pinned source-generation log " + field);
  digest(imported.recipeFiles, K.recipeSha256, "unchanged original generation recipe files");
  same(imported.recipeFiles.length, 48, "original generation recipe file count");
  need(Array.isArray(imported.importedFiles) && imported.importedFiles.length >= 446 &&
       new Set(imported.importedFiles.map(file => file.path)).size === imported.importedFiles.length,
       "unique actual imported file set and retained archives/log");
  const inputManifest = {
    path: A.evidenceFinishInputs.path,
    sha256: A.evidenceFinishInputs.sha256, bytes: A.evidenceFinishInputs.bytes
  };
  for (const [field, value] of Object.entries({
    schemaVersion: 1, kind: "psc0-authenticated-retained-fixed-point-evidence-completion",
    status: "evidence-completed", compiledSourceRef: K.sourceRef,
    sourceClosureSha256: K.sourceClosureSha256, moduleCount: 64,
    originalQualifier: K.originalQualifier, originalBinder: K.originalBinder,
    evidenceProducer: execution.evidenceProducer, inputManifest,
    authenticatedArchives: imported.authenticatedArchives, generationOwnership: K.generationOwners,
    sourceGenerationLog: imported.generationLog,
    compilerGenerationsRebuilt: [], conformanceExecutionsRepeated: [],
    selectedAuthoringSeedChanged: false, generationReceiptBytesChanged: false,
    generationRecipeRelabeledAsEvidenceProducer: false, priorExecutionConclusionsChanged: false,
    strictSh1Qualified: false, semanticContractQualified: false,
    generalPreservationProven: false, provider: {status: "not-attempted", kernelChecked: false}
  })) same(completion[field], value, "authenticated evidence completion " + field);
  same(completion.markerBindingCorrection, {
    original: ".map((line) => line.slice(pass))",
    repaired: ".map((line) => line.slice(pass.length))",
    sameOrdered15NativeFixtureNamesRequired: true, otherBinderBytesUnchanged: true
  }, "bounded native-marker extraction correction");
  same(completion.preservedInputs, {
    files: imported.importedFiles.length, catalogSha256: H(imported.importedFiles),
    beforeAndAfterExact: true
  }, "all authenticated input files retained exactly");
  same(completion.generationRecipe, {
    files: imported.recipeFiles, sha256: K.recipeSha256
  }, "completion original generation recipe");
  for (const archive of K.authenticatedArchives) {
    same(imported.importedFiles.find(file => file.path === archive.rawArchivePath),
         {path: archive.rawArchivePath, sha256: archive.sha256, bytes: archive.bytes},
         "retained authenticated archive " + archive.runId);
  }
  same(imported.importedFiles.find(file => file.path === K.generationLog.path),
       {path: K.generationLog.path, sha256: K.generationLog.sha256, bytes: K.generationLog.bytes},
       "retained exact source-generation job log");
  same(Object.keys(completion.generationReceipts), ["N1", "C1", "C2", "C3"],
       "ordered four-generation receipt ownership");
  for (const [generation, pin] of Object.entries(K.generationReceipts)) {
    same(imported.importedFiles.find(file => file.path === pin.path), pin,
         "unchanged retained generation receipt " + generation);
    same(completion.generationReceipts[generation], pin,
         "completion retained generation receipt " + generation);
  }
  const gateFiles = [
    ["PSC0_SH1_GENERATION", "receipt.json"],
    ["PSC0_SH1_STRICT_SOURCE", "strict-source/receipt.json"],
    ["PSC0_SH1_STRICT_TARGET", "strict-target/receipt.json"],
    ["PSC0_SH1_STRICT_RUNTIME", "strict-runtime/receipt.json"],
    ["PSC0_SH1_IR_CHECKER", "ir-checker/receipt.json"],
    ["PSC0_SH1_CAPABILITIES", "capabilities/receipt.json"],
    ["PSC0_SH1_HELPER_RUNTIME", "helper-runtime.json"],
    ["PSC0_SH1_GENERIC_ERASURE", "generic-erasure/receipt.json"]
  ];
  const expectedGateReports = ["C2", "C3"].flatMap(generation => gateFiles.map(([marker, relative]) => {
    const path = "dist/sh1/" + generation + "/" + relative;
    const file = imported.importedFiles.find(file => file.path === path);
    need(file, "authenticated completed generation gate file absent: " + path);
    return {generation, marker, file};
  }));
  same(completion.actualCompletedGenerationGateReports, expectedGateReports,
       "actual completed C2/C3 generation and seven conformance gate kinds");
  same(Object.keys(completion.outputs),
       ["strict-enforcement-evidence.json", "qualification.json", "seed-selection.json"],
       "current evidence outputs");
  for (const key of ["qualification", "strictBinder"])
    same(completion.outputs[A[key].path], {
      path: "dist/sh1/" + A[key].path, sha256: A[key].sha256, bytes: A[key].bytes
    }, "new evidence output " + key);

  for (const [field, value] of Object.entries({
    schemaVersion: 1, kind: "psc0-exact-source-evidence-completion-inventory",
    status: "complete", complete: true, finishOutcome: "success",
    sourceRef: K.sourceRef, orchestrationHeadSha: K.orchestrationHeadSha,
    runId: K.runId, runAttempt: K.runAttempt,
    predecessorRunId: 38021634599, predecessorArtifactId: 11659939542,
    predecessorArchiveSha256: "599fd5160f132d0795246bc102f8b306ae3bd8d42238201cef2d3e69dbef6f80",
    evidenceProducer: execution.evidenceProducer, generationOwnership: K.generationOwners,
    inputManifest, completionFile: {
      path: "evidence-completion.json", sourcePath: A.evidenceCompletion.path,
      sha256: A.evidenceCompletion.sha256, bytes: A.evidenceCompletion.bytes
    },
    reusedGenerations: ["N1", "C1", "C2", "C3"], generatedThisCommand: [],
    importedEvidenceUnchanged: true, missingFiles: [], validationErrors: [],
    compilerExecutedByThisInventory: false, strictSh1Qualified: false,
    semanticContractQualified: false, providerChecked: false
  })) same(inventory[field], value, "authenticated evidence-completion inventory " + field);
  need(Array.isArray(inventory.files) && inventory.files.length === carried.requiredInventoryFileCount &&
       new Set(inventory.files.map(file => file.path)).size === inventory.files.length,
       "complete unique current catalog file inventory");
  same(carried.requiredInventoryFileCount, 135, "exact compiler catalog file count");
  same(carried.requiredReturnedJsonFileCount, 24, "required exact returned JSON file count");
  need(Array.isArray(inventory.supplementalFiles) &&
       new Set(inventory.supplementalFiles.map(file => file.path)).size === inventory.supplementalFiles.length,
       "unique supplemental input/completion/profile envelope inventory");
  for (const [key, relative] of [
    ["evidenceFinishInputs", "../sh1-evidence-finish-inputs/inputs.json"],
    ["evidenceCompletion", "evidence-completion.json"]
  ]) same(inventory.supplementalFiles.find(file => file.sourcePath === A[key].path), {
    path: relative, sourcePath: A[key].path, sha256: A[key].sha256, bytes: A[key].bytes
  }, "actual supplemental envelope " + key);
  digest(inventory.sourceClosureManifest, K.sourceClosureSha256, "inventory source closure");
  same(inventory.recipe, completion.generationRecipe, "inventory unchanged generation recipe");
  digest(inventory.recipe.files, K.recipeSha256, "inventory exact original recipe files");
  same(inventory.recipe.files.length, 48, "inventory original recipe file count");
  for (const [generation, pin] of Object.entries(K.generationReceipts)) {
    const relative = pin.path.slice("dist/sh1/".length);
    same(inventory.files.find(file => file.path === relative),
         {path: relative, sha256: pin.sha256, bytes: pin.bytes},
         "inventoried unchanged generation receipt " + generation);
  }
  for (const key of ["qualification", "strictBinder"])
    same(inventory.files.find(file => file.path === A[key].path),
         {path: A[key].path, sha256: A[key].sha256, bytes: A[key].bytes},
         "actual evidence-only output inventory " + key);
  const currentBinderGroup = R.receiptGroups.find(group => group.id === "strict-binder");
  need(currentBinderGroup, "strict-binder receipt group absent");
  same(currentBinderGroup.currentEvidenceProducer, {
    executionPointer: "/execution/evidenceProducer",
    executionValueSha256: H(execution.evidenceProducer),
    binderPointer: "/execution/evidenceProducer/binder",
    repairPointer: "/execution/evidenceProducerRepair",
    repairValueSha256: H(execution.evidenceProducerRepair),
    sourceBlobMeaning: "Original generation-recipe source retained as the reviewed base of the exact evidence-producer correction."
  }, "current strict-binder group producer correction reference");


  const X = execution;
  for (const generation of R.generations) {
    const pin = K.generationReceipts[generation.name];
    need(pin && generation.receipt.path === pin.path.slice("dist/sh1/".length) &&
      generation.receipt.sha256 === pin.sha256 && generation.receipt.bytes === pin.bytes,
      "release binds original retained generation receipt " + generation.name);
    const file = inventory.files.find(item => item.path === generation.receipt.path);
    need(file && file.sha256 === generation.receipt.sha256 && file.bytes === generation.receipt.bytes,
      "actual inventory generation receipt " + generation.name);
  }
  const qualificationEnvelope = envelope(A.qualification, X.qualificationFile, "qualification.json");
  const binderEnvelope = envelope(A.strictBinder, X.strictBinderFile, "strict-enforcement-evidence.json");
  const providerEnvelope = envelope(A.provider, X.providerFile, "kernel-admissions.json");
  envelope(A.provider, R.provider.receipt, "provider record envelope");

  need(R.recipe.sourceFileCount === 48 && R.recipe.sourceFiles.length === 48 &&
    R.recipe.exactObject && R.recipe.exactObject.files.length === 48, "actual48 recipe");
  same(R.recipe.sha256, recipeHash, "actual recipe digest");
  need(H(R.recipe.exactObject.files) === recipeHash, "ordered recipe.files digest");
  R.recipe.sourceFiles.forEach((file, i) => {
    const base = B.recipe.sourceFiles[i], actual = R.recipe.exactObject.files[i];
    for (const key of ["path", "gitBlobSha1", "bytes"]) same(file[key], base[key], "recipe source " + i + "." + key);
    same(Object.keys(actual), ["path", "sha256"], "recipe entry shape " + i);
    same(actual.path, file.path, "recipe order " + i);
    need(hash64(file.sha256) && file.sha256 === actual.sha256, "actual recipe source digest " + i);
  });
  same(R.recipe.requiredToolchain, B.recipe.requiredToolchain, "required toolchain");
  same(R.recipe.immutableInputs, B.recipe.immutableInputs, "immutable contract/psconfig inputs");
  need(R.recipe.actualToolchain != null && R.recipe.actualTypeScriptProfile != null, "actual toolchain/profile");
  same(R.protectedClaims, B.protectedClaims, "immutable produced nonclaims");
  need(R.qualification.formalPreservationProven === false && R.qualification.generalPreservationProven === false, "conservative final proof flags");
  same(R.generations.map(g => g.name), ["N1", "C1", "C2", "C3"], "four generation order");
  R.generations.forEach((g, i) => {
    for (const key of ["directory", "binderPointer", "fullCompilerIrBoundary", "builtOriginalIrBoundary"])
      same(g[key], B.generations[i][key], "generation boundary " + i + "." + key);
    need(hash64(g.actualCompilerSha256) && hash64(g.actualExecutingCompilerSha256) &&
      hash64(g.actualTypeScriptSha256) && g.actualRecipeSha256 === recipeHash, "actual generation products " + g.name);
    envelope(g.receipt, g.receipt, "actual generation receipt " + g.name);
  });
  need(R.generations[0].generatedFullCompilerIrChecked === false, "N1 generated full-IR nonclaim");

  same(R.provider.expectedSourceRef, B.provider.expectedSourceRef, "selected provider source");
  same(R.provider.runner, B.provider.runner, "frozen provider runner");
  for (const key of ["qualificationFileHashRecordedByProvider", "emissionWasGatedByThisCheck",
    "N1ProviderChecked", "allSourceRuntimeOrIrExamplesProviderChecked"])
    same(R.provider[key], false, "provider boundary " + key);
  need(R.provider.accepted === true && R.provider.identity != null &&
    R.provider.labeledInputCount === 8 && R.provider.labels.length === 8 &&
    Array.isArray(R.provider.streams) && R.provider.streams.length > 0 &&
    R.provider.uniqueStreamCount === R.provider.streams.length, "actual provider acceptance");
  const usedStreams = new Set();
  R.provider.streams.forEach((s, i) => {
    need(s.accepted === true && s.result && s.result.accepted === true &&
      hash64(s.canonicalAdmissionsSha256) && s.decisionReceiptRef != null, "actual provider stream " + i);
  });
  R.provider.labels.forEach((label, i) => {
    for (const key of ["label", "path", "digestSource"]) same(label[key], B.provider.labels[i][key], "provider label " + i + "." + key);
    const n = label.providerStreamIndex;
    need(label.accepted === true && Number.isInteger(n) && n >= 0 && n < R.provider.streams.length &&
      label.canonicalAdmissionsSha256 === R.provider.streams[n].canonicalAdmissionsSha256, "provider label-to-stream " + i);
    usedStreams.add(n);
  });
  need(usedStreams.size === R.provider.streams.length, "every actual provider stream has its specified label");
  for (const key of ["selectedByPsconfig", "selectedSeedChanged", "genericCompilerApisAreImplicitlyStrict"])
    same(R.activation[key], false, "activation boundary " + key);
  same(R.activation.qualifiedEntry, "psCompilerSh1TypeScriptSources", "explicit strict entry");
  same(R.activation.selectedSeed, "R", "unchanged selected R");
  same(R.activation.currentSeed, B.activation.currentSeed, "immutable selected seed identity");
  same(R.activation.psconfigMeaning, B.activation.psconfigMeaning, "unchanged psconfig meaning");

  const before = clone(M.receiptCatalog), effective = clone(before), delta = T.receiptCatalogDelta;
  need(before.length === 25 && R.receiptGroups.length === 25, "25 receipt groups");
  need(H(delta) === "b8196c336cd615b9fbba4c97fea9a0110ecb12b1161146e92b103cef15f92cfa", "existing c5 catalog delta");
  delta.forEach(d => {
    const i = Number(d.baseCatalogPointer.split("/").pop()), group = effective[i];
    need(group && group.id === d.id && H(group) === d.baseValueSha256, "catalog base guard " + d.id);
    for (const [key, change] of Object.entries(d.changes)) {
      if (change.expectedAbsent === true) need(!own(group, key), "catalog absent guard " + d.id + "." + key);
      else same(group[key], change.expected, "catalog field guard " + d.id + "." + key);
      group[key] = clone(change.proposed);
    }
  });
  need(H(before.map(staticGroup)) === "4b9492a8da859311e446c528d58d702b1e356a6c7d154e5907f85493194e8a87", "original static catalog");
  need(H(effective.map(staticGroup)) === "d00c507b197bb4c573f77d7ec9d2f55c7aed0d5c275f588ec42dcd49e73c2eee" &&
    H(effective) === "aab159f5d60c76d5b62c0b207615515f37a471cffd18289182935197d6a5c8a9", "effective catalog");
  const catalogDeltaReference = {
    path: P.currentInput.correspondenceTransport.path,
    blob: P.currentInput.correspondenceTransport.blob,
    jsonPointer: "/receiptCatalogDelta",
    valueSha256: H(delta),
    effectiveStaticCatalogSha256: H(effective.map(staticGroup)),
    effectiveFullCatalogSha256: H(effective)
  };
  same(R.artifactBindings.files.map(f => f.path), B.artifactBindings.files.map(f => f.path), "unchanged136 artifact slot order");
  need(R.artifactBindings.files.length === 136 && R.artifactBindings.observedComplete === true, "complete136 artifact slots");
  const files = new Map();
  R.artifactBindings.files.forEach(f => {
    need(!files.has(f.path), "duplicate artifact path " + f.path);
    envelope(f, f, "actual artifact " + f.path);
    files.set(f.path, f);
  });
  effective.forEach((g, i) => {
    const actual = R.receiptGroups[i];
    for (const [key, value] of Object.entries(g)) same(actual[key], value, "effective group " + g.id + "." + key);
    need(own(actual, "selectors") === own(g, "selectors"), "preserved absent selectors " + g.id);
    need(actual.authenticated === true && Array.isArray(actual.resolvedSelectors), "authenticated group " + g.id);
    actual.resolvedSelectors.forEach((s, j) => {
      const label = "resolved selector " + g.id + "/" + j;
      need(s.verified === true && typeof s.file === "string" && files.has(s.file) &&
        typeof s.jsonPointer === "string" && (s.jsonPointer === "" || s.jsonPointer[0] === "/") &&
        hash64(s.jsonValueSha256) && Number.isSafeInteger(s.jsonValueUtf8Bytes) &&
        s.jsonValueUtf8Bytes >= 0, label + " metadata");
      envelope(s.fileEnvelope, files.get(s.file), label + " file envelope");
      if (own(s, "value")) {
        need(s.valueRepresentation === "exact-parsed-json-value", label + " small representation");
        const valueText = json(s.value);
        need(typeof valueText === "string" && sha256(valueText) === s.jsonValueSha256 &&
          length(valueText) === s.jsonValueUtf8Bytes, label + " exact small JSON hash/bytes");
      } else {
        need(s.valueRepresentation === "authenticated-raw-file-and-exact-json-value-hash" &&
          s.valueReference && typeof s.valueReference === "object" &&
          !Array.isArray(s.valueReference), label + " large representation");
        const ref = s.valueReference;
        for (const key of ["path", "sha256", "bytes", "retainedBlob", "receiptOrEnvelopeRef"])
          same(ref[key], s.fileEnvelope[key], label + " large file reference." + key);
        same(ref.jsonPointer, s.jsonPointer, label + " large JSON pointer");
        same(ref.jsonValueSha256, s.jsonValueSha256, label + " large JSON hash");
        same(ref.jsonValueUtf8Bytes, s.jsonValueUtf8Bytes, label + " large JSON bytes");
      }
    });
    g.files.forEach(path => need(files.has(path), "group artifact " + g.id + ":" + path));
  });
  const resolve = (rowKind, rowId, rowIndex, receiptRefs, expected) => {
    need(Array.isArray(receiptRefs) && receiptRefs.length > 0, "actual receiptRefs for " + rowId);
    const ids = A.resolveReceiptGroupIds({
      rowKind, rowId, rowIndex, receiptRefs: clone(receiptRefs), releaseRef: clone(RR),
      receiptGroups: clone(R.receiptGroups), artifactFiles: clone(R.artifactBindings.files)
    });
    need(Array.isArray(ids), "synchronous receipt resolver result for " + rowId);
    same(ids, expected, "ordered authenticated receipt group coverage for " + rowId);
  };

  // Require the actual final33 ledger; aggregate counters are not its proof.
  let correspondenceGroupCount = 0;
  const completedCorrespondence = CP.rowPlans.map((p, i) => {
    const row = C.rows[i], rr = R.correspondenceDispositions[i], pointer = "/correspondenceDispositions/" + i;
    need(p.index === i && row.id === p.id && rr.id === p.id && rr.ledgerPointer === p.rowPointer, "correspondence identity " + i);
    same(rr.sourceRowSha256, p.guards.activeRowSha256, "correspondence historical source guard " + p.id);
    same(rr.sourcePreparedRowSha256, p.guards.sourcePreparedRowSha256, "correspondence prepared source guard " + p.id);
    need(H(row.sources) === p.guards.sourcesSha256 && H(row.domain) === p.sourcePreparation.domainSha256 &&
      H(row.requiredRelation) === p.relation.exactValueSha256 && H(row.ruleArgument) === p.argument.exactValueSha256, "completed correspondence source/argument guards " + p.id);
    need(H(rr.paperEvidence) === p.paperEvidence.exactValueSha256, "correspondence paper guard " + p.id);
    need(row.strictSh1Discharged === true && rr.strictSh1Discharged === true &&
      row.generalPreservationProven === false && rr.generalPreservationProven === false, "completed conservative correspondence disposition " + p.id);
    same(rr.requiredReceiptGroups, p.requiredReceiptGroups, "complete correspondence group list " + p.id);
    resolve("correspondence", p.id, i, rr.receiptRefs, p.requiredReceiptGroups);
    correspondenceGroupCount += p.requiredReceiptGroups.length;
    const de = row.dischargeEvidence;
    need(de && row.generalArgumentReview, "completed correspondence review/evidence " + p.id);
    same(de.releaseRecordReference, external(RR, pointer), "correspondence release association " + p.id);
    same(de.releaseRecordCorrespondenceRowPointer, pointer, "correspondence release pointer " + p.id);
    same(de.qualificationSourceCommit, source, "correspondence qualification source " + p.id);
    same(de.exactSourceClosureSha256, closure, "correspondence closure " + p.id);
    same(de.exactRecipeSha256, recipeHash, "correspondence recipe " + p.id);
    same(de.requiredGroupReferences, rr.receiptRefs, "unchanged correspondence receiptRefs " + p.id);
    envelope(de.qualificationArtifactReference, qualificationEnvelope, "correspondence qualification " + p.id);
    envelope(de.strictBinderArtifactReference, binderEnvelope, "correspondence binder " + p.id);
    envelope(de.providerArtifactReference, providerEnvelope, "correspondence provider " + p.id);
    return {id:p.id, releaseRecordReference:external(RR, pointer), correspondenceLedgerReference:external(CR, p.rowPointer)};
  });
  need(correspondenceGroupCount === 313, "313 correspondence group references");

  const checked = [], updateIndices = [], stageGroupCounts = [];
  const paperById = new Map(P.fixedMappings.paperPins.map(p => [p.id, p]));
  function checkStage(i) {
    const p = P.rowPlans[i], row = L.rows[i], rr = R.stageDispositions[i], pointer = "/stageDispositions/" + i;
    need(p.index === i && p.rowPointer === "/rows/" + i && H(row) === p.guards.rowSha256, "original stage row " + i);
    for (const key of ["id", "stage", "obligation", "status", "strictDischarged"]) same(row[key], p.guards[key], "original stage " + i + "." + key);
    for (const [key, guard] of [["evidence","evidenceSha256"], ["assuranceMethod","assuranceMethodSha256"], ["sources","sourcesSha256"]])
      need(H(row[key]) === p.guards[guard], "original stage " + i + "." + key);
    need(H(at(M, p.frozenMap.jsonPointer)) === p.frozenMap.rowSha256 &&
      H(at(V, p.independentReview.jsonPointer)) === p.independentReview.rowSha256, "stage map/review row " + i);
    need(H(at(M, p.frozenMap.sourceArgumentPointer)) === p.frozenMap.sourceArgumentSha256 &&
      H(at(M, p.frozenMap.paperEvidencePointer)) === p.frozenMap.paperEvidenceSha256, "stage frozen argument/paper " + i);
    need(H(at(B, p.currentReleaseProjection.jsonPointer)) === p.currentReleaseProjection.projectedRowSha256, "stage pre-completion projection " + i);
    same(rr.id, row.id, "stage release id " + i);
    same(rr.stage, row.stage, "stage release stage " + i);
    same(rr.obligation, row.obligation, "stage release obligation " + i);
    same(rr.ledgerPointer, p.rowPointer, "stage release ledger pointer " + i);
    same(rr.sourceRowSha256, p.guards.rowSha256, "stage release source guard " + i);
    same(rr.priorStatus, row.status, "stage prior status " + i);
    same(rr.priorStrictDischarged, false, "stage prior strict flag " + i);
    same(rr.sourceArgument, p.completedCurrentNarrative.text, "current completed argument " + i);
    need(H(rr.sourceArgument) === p.completedCurrentNarrative.textJsonSha256 &&
      H(rr.paperEvidence) === p.frozenMap.paperEvidenceSha256, "stage completed argument/paper hash " + i);
    same(rr.argumentReviewRef, p.independentReview.blob + "#" + p.independentReview.jsonPointer, "stage independent review association " + i);
    const correspondenceIds = p.requiredCorrespondenceRows.map(x => x.id);
    same(rr.correspondenceRows, correspondenceIds, "stage correspondence list " + i);
    const corr = correspondenceIds.map(id => {
      const found = completedCorrespondence.find(x => x.id === id);
      need(found, "completed correspondence dependency " + id);
      return clone(found);
    });
    const groupIds = p.requiredReceiptGroups.map(x => x.id);
    same(rr.requiredReceiptGroups, groupIds, "stage complete ordered groups " + i);
    resolve("stage", p.id, i, rr.receiptRefs, groupIds);
    stageGroupCounts.push(groupIds.length);
    const groupRefs = p.requiredReceiptGroups.map(pg => {
      const gi = Number(pg.releaseRecordPointer.split("/").pop());
      const old = before[gi], g = R.receiptGroups[gi];
      need(old.id === pg.id && g.id === pg.id && H(staticGroup(old)) === pg.staticCatalogSha256, "stage historical catalog guard " + p.id + "/" + pg.id);
      const item = {
        ...clone(pg),
        releaseRecordReference: external(RR, pg.releaseRecordPointer),
        effectiveCatalogSha256: H(staticGroup(g)),
        catalogDeltaReference: clone(catalogDeltaReference),
        limit: g.limit,
        actualArtifactReferences: g.files.map(path => clone(files.get(path))),
        actualResolvedSelectorReferences: g.resolvedSelectors.map((s, j) => ({
          releaseRecordReference: external(RR, pg.releaseRecordPointer + "/resolvedSelectors/" + j),
          file: s.file, jsonPointer: s.jsonPointer,
          valueSha256: s.jsonValueSha256, jsonValueUtf8Bytes: s.jsonValueUtf8Bytes,
          fileEnvelope: clone(s.fileEnvelope), valueRepresentation: s.valueRepresentation,
          ...(!own(s, "value") ? {valueReference: clone(s.valueReference)} : {}),
          verified: true
        }))
      };
      if (g.id === "host-boundary" || g.id === "name-index") {
        item.actualWorkflowLogReferences = [
          external(RR, "/execution/priorExecution/configuredWorkflowGateOutcomes"),
          external(RR, "/execution/priorExecution/compilerJobLog")
        ];
      }
      if (g.currentBoundarySelectors) item.currentBoundarySelectorsReference = external(RR, pg.releaseRecordPointer + "/currentBoundarySelectors");
      return item;
    });
    const paperReferences = rr.paperEvidence.map(e => {
      const pin = paperById.get(e.packet);
      need(pin, "resolved paper packet " + e.packet);
      return {...clone(e), sourceReference:clone(pin)};
    });
    need(rr.strictDischarged === true, "final release stage disposition " + p.id);
    if (p.implementationUpdate) {
      const u = p.implementationUpdate;
      same(row.implementationUpdate, u.current, "implementation refresh before " + p.id);
      need(H(row.implementationUpdate) === u.currentJsonSha256 &&
        H(u.valueAfterCompleteEvidence) === u.valueAfterJsonSha256, "implementation refresh hashes " + p.id);
      updateIndices.push(i);
    }
    return {i, p, row, rr, pointer, corr, groupRefs, paperReferences};
  }
  for (let i = 0; i < 26; i++) checked.push(checkStage(i));
  const deps = P.rowPlans[26].nonCircularActivationPrerequisites;
  same(deps.all33CorrespondenceRows.map(x => ({id:x.id, releaseRecordPointer:x.releaseRecordPointer})),
    completedCorrespondence.map((x,i) => ({id:x.id, releaseRecordPointer:"/correspondenceDispositions/" + i})), "activation all33 prerequisites");
  same(deps.preceding26Stages.map(x => ({id:x.id, releaseRecordPointer:x.releaseRecordPointer})),
    checked.map(x => ({id:x.p.id, releaseRecordPointer:x.pointer})), "activation preceding26 prerequisites");
  need(deps.currentStageExcludedFromItsOwnPrerequisites === true &&
    deps.exactCompilerAndProviderEvidenceAlsoRequired === true, "noncircular activation");
  const activationEvidence = {
    correspondence: clone(completedCorrespondence),
    precedingStages: checked.map(x => ({id:x.p.id, releaseRecordReference:external(RR, x.pointer)})),
    prerequisiteCount:59, currentStageExcludedFromItsOwnPrerequisites:true,
    enforcementInstalledScope:deps.enforcementInstalledScope,
    qualifiedEntry:"psCompilerSh1TypeScriptSources",
    selectedByPsconfig:false, selectedSeed:"R", selectedSeedChanged:false
  };
  checked.push(checkStage(26));
  need(stageGroupCounts.reduce((a,b) => a+b, 0) === 95, "95 stage receipt group references");
  same(updateIndices, [11,13,18,24,25], "exact five implementation refreshes");
  need(R.qualification.correspondenceRowsRequired === 33 && R.qualification.correspondenceRowsDischarged === 33 &&
    R.qualification.stageObligationsRequired === 27 && R.qualification.stageObligationsDischarged === 27, "final aggregate consistency after59 prerequisites");
  for (const key of ["compilerQualified", "sourceCheckpointQualified", "semanticContractQualified", "strictSh1Qualified", "independentProviderAccepted"])
    need(R.qualification[key] === true, "completed external qualification " + key);
  need(R.activation.enforcementInstalled === true, "completed scoped activation after59 prerequisites");

  const result = clone(L);
  result.rows = checked.map(({i,p,row,rr,pointer,corr,groupRefs,paperReferences}) => {
    const releaseRowReference = external(RR, pointer);
    const mapReference = {...clone(P.fixedMappings.map), jsonPointer:p.frozenMap.jsonPointer, valueSha256:p.frozenMap.rowSha256};
    const reviewReference = {...clone(P.fixedMappings.independentStageReview), jsonPointer:p.independentReview.jsonPointer, valueSha256:p.independentReview.rowSha256};
    const entry = {
      ...clone(P.fieldMaintenance.evidenceEntryTemplate),
      releaseRecordReference:releaseRowReference, releaseRecordStagePointer:pointer,
      frozenMapReference:mapReference, independentStageReviewReference:reviewReference,
      paperEvidence:clone(rr.paperEvidence), paperReferences,
      currentSourceTransports:clone(P.fixedMappings.currentSourceTransports),
      independentClosedUniverseReview:clone(P.fixedMappings.independentClosedUniverseReview),
      completedCorrespondenceReferences:corr,
      requiredReceiptGroupReferences:groupRefs,
      receiptRefs:clone(rr.receiptRefs)
    };
    if (i === 26) entry.activationDependencies = clone(activationEvidence);
    const de = {
      ...clone(P.fieldMaintenance.dischargeEvidenceTemplate),
      status:P.fieldMaintenance.completionStatus,
      releaseRecordReference:releaseRowReference, releaseRecordStagePointer:pointer,
      qualificationSourceCommit:source, exactSourceClosureSha256:closure, exactRecipeSha256:recipeHash,
      qualificationArtifactReference:clone(qualificationEnvelope),
      strictBinderArtifactReference:clone(binderEnvelope),
      providerArtifactReference:clone(providerEnvelope),
      requiredGroupReferences:clone(rr.receiptRefs)
    };
    const argumentReview = {
      ...clone(p.futureRowFields.sourceArgumentReview),
      releaseRecordReference:releaseRowReference,
      sourceArgumentSha256:H(rr.sourceArgument),
      frozenMapReference:mapReference, independentStageReviewReference:reviewReference,
      paperEvidence:clone(rr.paperEvidence), paperReferences:clone(paperReferences),
      currentSourceTransports:clone(P.fixedMappings.currentSourceTransports)
    };
    need(Array.isArray(row.evidence), "append-only original evidence " + p.id);
    const out = {
      ...clone(row), status:p.futureRowFields.status.valueAfterCompleteEvidence,
      evidence:[...clone(row.evidence), entry], strictDischarged:true,
      sourceArgumentReview:argumentReview, dischargeEvidence:de
    };
    if (p.implementationUpdate) out.implementationUpdate = p.implementationUpdate.valueAfterCompleteEvidence;
    const allowed = ["status","evidence","strictDischarged","sourceArgumentReview","dischargeEvidence"];
    if (p.implementationUpdate) allowed.push("implementationUpdate");
    const a = clone(row), b = clone(out);
    allowed.forEach(key => {delete a[key]; delete b[key];});
    same(b, a, "no unrelated row changes " + p.id);
    same(out.evidence.slice(0,-1), row.evidence, "preserved evidence prefix " + p.id);
    return out;
  });
  const oldTop = clone(L), newTop = clone(result);
  delete oldTop.rows; delete newTop.rows;
  same(newTop, oldTop, "root-owned aggregate/history fields remain untouched");
  const S = P.specStatusForeword;
  textGuard(specText, S.base.sha256, S.base.bytes, "SPEC61f base");
  const prefix = S.insertion.afterExactPrefix;
  textGuard(prefix, S.insertion.prefixSha256, S.insertion.prefixBytes, "SPEC exact prefix");
  need(specText.startsWith(prefix), "SPEC prefix placement");
  const suffix = specText.slice(prefix.length);
  textGuard(suffix, S.preservedSuffix.sha256, S.preservedSuffix.bytes, "SPEC whole preserved suffix");
  const anchor = S.preservedNormativeBody.startsWith.replace(/\\n/g, "\n");
  const position = specText.indexOf(anchor);
  need(position >= 0 && specText.indexOf(anchor, position + 1) === -1, "SPEC normative body boundary");
  textGuard(specText.slice(position), S.preservedNormativeBody.sha256, S.preservedNormativeBody.bytes, "SPEC unchanged normative body");
  textGuard(S.insertion.text, S.insertion.textSha256, S.insertion.bytes, "SPEC current1fa/run insertion");
  const newSpec = prefix + S.insertion.text + suffix;
  textGuard(newSpec, S.candidateIfAppliedAfterSuccess.sha256, S.candidateIfAppliedAfterSuccess.bytes, "SPEC final insertion result");
  const text = pretty(result);
  return {
    ledger:result, text, sha256:sha256(text), bytes:length(text), rowsSha256:H(result.rows),
    spec:{path:S.path, text:newSpec, sha256:sha256(newSpec), bytes:length(newSpec)},
    counts:{correspondenceRows:33, stageRows:27, stageReceiptGroupReferences:95, correspondenceReceiptGroupReferences:313,
      activationPrerequisites:59, implementationRefreshes:updateIndices},
    releaseRef:clone(RR), correspondenceRef:clone(CR), activationEvidence,
    rootOwnedAssignments:clone(P.fieldMaintenance.activeSummaryMaintenance.rootOwnedPointers),
    note:"Pure assembled candidates only. Root applies the separately reviewed aggregate/status assignments and owns publication. No source, recipe, selected seed, produced receipt or unrelated history was mutated."
  };
}
