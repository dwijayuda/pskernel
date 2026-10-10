/**
 * Pure final33 correspondence assembler. No I/O, publication or compiler work.
 *
 * PRECONDITION: root has independently authenticated the completed actual release,
 * source-rule reviews/transports, all 25 receipt groups and source-empty boundary
 * assertions, actual retained generation/evidence/provider results and all 33/27 dispositions. Neither
 * a supplied Boolean nor this data-transcription helper performs that review.
 *
 * evidence = {
 *   qualification, strictBinder, provider: exact release.execution file envelopes,
 *   evidenceFinishInputs, evidenceInventory, evidenceCompletion: exact finish file envelopes,
 *   evidenceFinishInputsValue, evidenceInventoryValue, evidenceCompletionValue:
 *     their authenticated parsed JSON;
 *     the pinned workflow writes each using JSON.stringify(value, null, 2) + LF,
 *   resolveReceiptGroupIds(context): synchronous pure resolver over authenticated
 *     existing receiptRefs; returns their ordered group-ID vector, not a new
 *     stored receipt wrapper. context has rowKind,rowId,rowIndex,receiptRefs,
 *     releaseRef,receiptGroups,artifactFiles. All context values are copies.
 * }
 *
 * sha256 is the already-reviewed synchronous UTF-8 string SHA256 helper.
 * transport/procedure are the exact projections after overlay91ff and the execution-only
 * correspondence-continuation-execution-overlay.json and the subsequent evidence-completion
 * execution overlay. Original source/proof/catalog/row guards stay pinned.
 * mapText is the exact authenticated697c map text. releaseRef is the separately
 * stored/read-back release {path,blob,sha256,bytes}; it is never put into itself.
 * Only invoke after actual completed evidence. This source was prepared without
 * invoking the assembler or producing a promoted row candidate.
 */
function assembleFinal33({
  ledgerText, transport, procedure, mapText,
  releaseText, releaseRef, evidence: A, sha256
}) {
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
    },
    "ledger": {
      "path": "psc0/docs/selfhost-language/strict/correspondence-obligations.json",
      "blob": "df1d39c6067b5233af770c798bca6e3247f7f813",
      "sha256": "6af29f4bffe9bc0f1ad9c0a5ac2c855080b1bcbef5b75f606f0dc7490cc53478",
      "bytes": 143472
    },
    "transportSha256": "420a7da2573ef20f09f058eb62d33ac6d146093374b6aadc170300777f507603",
    "procedureSha256": "94e4c5c8332889ae04fcbc2e27db7b2efb93210c47b2faca145620a93acc9d60",
    "map": {
      "blob": "697c94b2722a6191537b714f71f629713637b30a",
      "sha256": "474236ad91ccec5a0b0f612d4bee74accd499329a08a93e1c743bf11923a6c07"
    },
    "sourcePatchSha256": "ab6db5609bd2567f195ca152f9ceb356c35fdc329337bfcfe5ff89a51997d6f0",
    "activeRowsSha256": "39e543c14cef2a14b44ebee7480b179197648c5096c45138152bdb74d3009a55",
    "preparedRowsSha256": "aa3ba3f1e47f0f5ee08cc368fb3e16a0d1cb8291523745b70ad5a5439d52a72c",
    "preparedLedgerSha256": "219ac9a7bd825f4ece3aa270404d89ee0a01c1545d204f71d6a462a84e808108",
    "deltaSha256": "b8196c336cd615b9fbba4c97fea9a0110ecb12b1161146e92b103cef15f92cfa",
    "effectiveStaticCatalogSha256": "d00c507b197bb4c573f77d7ec9d2f55c7aed0d5c275f588ec42dcd49e73c2eee",
    "fullEffectiveCatalogSha256": "aab159f5d60c76d5b62c0b207615515f37a471cffd18289182935197d6a5c8a9",
    "overlay": {
      "path": "psc0/docs/selfhost-language/strict/reviewed-candidates/correspondence-current-host-run-overlay.json",
      "blob": "91ff1c5495c46de2a00ab71899024110cad992a6",
      "sha256": "a8aa1f0bf54627d9930a2ff95c45333b741ba1feea2cf881111f194538d402bc",
      "bytes": 34478
    },
    "procedureBase": {
      "path": "psc0/docs/selfhost-language/strict/reviewed-candidates/correspondence-final-assembly-procedure.json",
      "blob": "1e590688c1d6c87970caa4e22388310a2664b234",
      "sha256": "fb0439106ef5b6e6afc39e9e63bb29e888260fd2ecd3ca6ff83c387126f0a9c1",
      "bytes": 148777
    },
    "finalStatus": "strict-sh1-discharged-with-reviewed-source-arguments-and-exact-qualification"
  };

  const fail = label => { throw new Error("FINAL33_ASSEMBLY: " + label); };
  const need = (condition, label) => { if (!condition) fail(label); };
  const own = (object, key) => Object.prototype.hasOwnProperty.call(object, key);
  const J = value => JSON.stringify(value);
  const copy = value => JSON.parse(J(value));
  const equal = (left, right) => J(left) === J(right);
  const bytes = text => unescape(encodeURIComponent(text)).length;
  need(typeof sha256 === "function", "missing synchronous SHA256 helper");
  const H = value => sha256(J(value));
  const pretty = value => JSON.stringify(value, null, 2) + "\n";
  const hex256 = value => typeof value === "string" && /^[0-9a-f]{64}$/.test(value);
  const hexBlob = value => typeof value === "string" && /^[0-9a-f]{40}$/.test(value);
  const same = (left, right, label) => need(equal(left, right), label);
  const digest = (value, expected, label) => need(H(value) === expected, label);
  const hashText = (text, expected, label) => {
    need(typeof text === "string", label + ": text absent");
    need(sha256(text) === expected, label + ": SHA256 mismatch");
  };
  const parts = pointer => {
    need(typeof pointer === "string" && (pointer === "" || pointer[0] === "/"),
         "invalid JSON pointer");
    if (pointer === "") return [];
    return pointer.slice(1).split("/").map(part => {
      need(!/~(?:[^01]|$)/.test(part), "invalid pointer escape");
      return part.replace(/~1/g, "/").replace(/~0/g, "~");
    });
  };
  const get = (root, pointer) => {
    let value = root;
    for (const key of parts(pointer)) {
      need(value !== null && typeof value === "object" && own(value, key),
           "missing pointer " + pointer);
      value = value[key];
    }
    return value;
  };
  const sourcePatch = (root, operations) => {
    const result = copy(root);
    for (const operation of operations) {
      const path = parts(operation.path);
      need(path.length > 0, "source patch may not replace root");
      const key = path.pop();
      let owner = result;
      for (const segment of path) {
        need(owner !== null && typeof owner === "object" && own(owner, segment),
             "source patch parent absent: " + operation.path);
        owner = owner[segment];
      }
      need(owner !== null && typeof owner === "object", "source patch parent type");
      need(own(operation, "value"), "source patch value absent");
      if (operation.op === "test") {
        need(own(owner, key), "source patch test missing: " + operation.path);
        same(owner[key], operation.value, "source patch test: " + operation.path);
      } else if (operation.op === "replace") {
        need(own(owner, key), "source patch replace missing: " + operation.path);
        owner[key] = copy(operation.value);
      } else if (operation.op === "add") {
        if (Array.isArray(owner)) {
          need(key === "-" || /^(0|[1-9][0-9]*)$/.test(key),
               "source patch array index");
          const index = key === "-" ? owner.length : Number(key);
          need(Number.isSafeInteger(index) && index >= 0 && index <= owner.length,
               "source patch array add range");
          owner.splice(index, 0, copy(operation.value));
        } else {
          need(key !== "__proto__", "invalid source patch object key");
          Object.defineProperty(owner, key, {
            value: copy(operation.value), enumerable: true,
            writable: true, configurable: true
          });
        }
      } else {
        fail("unsupported source patch operation " + operation.op);
      }
    }
    return result;
  };
  const external = (reference, pointer) => ({
    path: reference.path, blob: reference.blob, sha256: reference.sha256,
    bytes: reference.bytes, ...(pointer === undefined ? {} : {jsonPointer: pointer})
  });
  const checkExternal = (reference, label) => {
    need(reference && typeof reference.path === "string" && reference.path.length > 0,
         label + ": path absent");
    need(hexBlob(reference.blob) && hex256(reference.sha256),
         label + ": invalid blob/hash");
    need(Number.isSafeInteger(reference.bytes) && reference.bytes > 0,
         label + ": bytes absent");
  };
  const checkEnvelope = (envelope, path, label) => {
    need(envelope && envelope.path === path && hex256(envelope.sha256),
         label + ": invalid path/hash");
    need(Number.isSafeInteger(envelope.bytes) && envelope.bytes >= 0,
         label + ": invalid byte count");
    const reconstruction = envelope.receiptOrEnvelopeRef;
    const hasReconstruction =
      (typeof reconstruction === "string" && reconstruction.length > 0) ||
      (reconstruction !== null && typeof reconstruction === "object" &&
       Object.keys(reconstruction).length > 0);
    need(hexBlob(envelope.retainedBlob) || hasReconstruction,
         label + ": neither retained bytes nor authenticated reconstruction reference");
  };
  const freeze = value => {
    if (value !== null && typeof value === "object" && !Object.isFrozen(value)) {
      for (const child of Object.values(value)) freeze(child);
      Object.freeze(value);
    }
    return value;
  };

  hashText(ledgerText, K.ledger.sha256, "current ledger");
  need(bytes(ledgerText) === K.ledger.bytes, "current ledger bytes");
  hashText(mapText, K.map.sha256, "frozen map");
  const L = JSON.parse(ledgerText), M = JSON.parse(mapText);
  const T = copy(transport), P = copy(procedure);
  hashText(pretty(T), K.transportSha256, "projected transport");
  hashText(pretty(P), K.procedureSha256, "projected procedure");
  checkExternal(releaseRef, "actual release reference");
  hashText(releaseText, releaseRef.sha256, "actual release");
  need(bytes(releaseText) === releaseRef.bytes, "actual release bytes");
  const R = JSON.parse(releaseText), releasePin = external(releaseRef);

  same(P.currentInput.ledger.blob, K.ledger.blob, "current procedure ledger pin");
  same(T.base.ledger.blob, K.ledger.blob, "current transport ledger pin");
  same(R.source.sourceRef, K.sourceRef, "qualified source");
  same(R.qualification.qualifiedSourceRef, K.sourceRef, "qualified source summary");
  same(R.source.sourceClosureSha256, K.sourceClosureSha256, "actual source closure");
  same(R.recipe.sha256, K.recipeSha256, "actual recipe");
  same(releasePin.path, P.currentInput.futureFinalReleaseRecord.path, "release path");
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
  const qualification = R.qualification;
  for (const field of [
    "compilerQualified", "sourceCheckpointQualified", "semanticContractQualified",
    "strictSh1Qualified", "independentProviderAccepted"
  ]) need(qualification[field] === true, "incomplete release qualification: " + field);
  same(qualification.correspondenceRowsRequired, 33, "required correspondence count");
  same(qualification.correspondenceRowsDischarged, 33, "released correspondence count");
  same(qualification.stageObligationsRequired, 27, "required stage count");
  same(qualification.stageObligationsDischarged, 27, "released stage count");
  need(Array.isArray(R.correspondenceDispositions) &&
       R.correspondenceDispositions.length === 33, "release correspondence array");
  need(Array.isArray(R.stageDispositions) && R.stageDispositions.length === 27,
       "release stage array");
  need(R.provider.accepted === true, "provider acceptance absent");
  need(qualification.generalPreservationProven === false &&
       qualification.formalPreservationProven === false, "legacy proof nonclaims");
  need(R.provider.emissionWasGatedByThisCheck === false, "provider emission nonclaim");
  need(R.activation.selectedByPsconfig === false, "psconfig selection changed");
  const metadataLedger = R.metadataBase.correspondence;
  for (const key of ["path", "blob", "sha256"])
    same(metadataLedger[key], K.ledger[key], "release pre-disposition ledger " + key);
  same(R.metadataBase.correspondenceRowsSha256, K.activeRowsSha256,
       "release active-row guard");
  need(A && typeof A.resolveReceiptGroupIds === "function",
       "missing pure resolver for authenticated receipt references");
  for (const [key, path, field] of [
    ["qualification", "qualification.json", "qualificationFile"],
    ["strictBinder", "strict-enforcement-evidence.json", "strictBinderFile"],
    ["provider", "kernel-admissions.json", "providerFile"]
  ]) {
    checkEnvelope(A[key], path, "actual " + key + " envelope");
    same(execution[field], A[key], "actual " + key + " release-envelope binding");
  }
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

  digest(T.receiptCatalogDelta, K.deltaSha256, "reviewed receipt catalog deltas");
  const C = copy(M.receiptCatalog);
  for (const delta of T.receiptCatalogDelta) {
    const catalogEntry = get({receiptCatalog: C}, delta.baseCatalogPointer);
    same(catalogEntry.id, delta.id, "catalog delta group identity");
    digest(catalogEntry, delta.baseValueSha256, "catalog delta base " + delta.id);
    for (const [key, change] of Object.entries(delta.changes)) {
      if (change.expectedAbsent === true) {
        need(!own(catalogEntry, key), "catalog delta expected absent " + delta.id + "." + key);
      } else {
        need(own(change, "expected") && own(catalogEntry, key), "catalog delta expected value");
        same(catalogEntry[key], change.expected, "catalog delta guard " + delta.id + "." + key);
      }
      catalogEntry[key] = copy(change.proposed);
    }
  }
  const staticCatalog = catalog => catalog.map(group => ({
    id: group.id, files: group.files, required: group.required,
    selectors: group.selectors, limit: group.limit
  }));
  digest(C, K.fullEffectiveCatalogSha256, "full effective receipt catalog");
  digest(staticCatalog(C), K.effectiveStaticCatalogSha256, "effective static catalog");
  need(Array.isArray(R.receiptGroups) && R.receiptGroups.length === 25,
       "actual receipt group count");
  same(R.receiptGroups.map(group => group.id), P.fixedMappings.allReceiptGroupIds,
       "actual ordered receipt groups");
  need(new Set(R.receiptGroups.map(group => group.id)).size === 25,
       "duplicate actual receipt groups");
  same(staticCatalog(R.receiptGroups), staticCatalog(C), "release effective catalog");
  for (const delta of T.receiptCatalogDelta) {
    const index = C.findIndex(group => group.id === delta.id);
    for (const key of Object.keys(delta.changes))
      same(R.receiptGroups[index][key], C[index][key],
           "release effective catalog metadata " + delta.id + "." + key);
  }
  const selectorPairs = selectors => (selectors || []).flatMap(selector =>
    (selector.jsonPointers || [selector.jsonPointer]).map(jsonPointer => ({
      file: selector.file, jsonPointer
    }))
  );
  for (let i = 0; i < C.length; i++) {
    const group = R.receiptGroups[i];
    need(group.authenticated === true, "unauthenticated receipt group " + group.id);
    need(Array.isArray(group.resolvedSelectors), "resolved selectors absent " + group.id);
    same(group.resolvedSelectors.map(({file, jsonPointer}) => ({file, jsonPointer})),
         selectorPairs(C[i].selectors), "resolved selector coverage " + group.id);
    need(group.resolvedSelectors.every(selector => selector.verified === true),
         "unverified resolved selector " + group.id);
    if (own(group, "currentSelectors")) {
      need(Array.isArray(group.currentSelectors) &&
           group.currentSelectors.every(selector => selector.verified === true),
           "unverified existing current selector " + group.id);
    }
  }
  need(R.artifactBindings && Array.isArray(R.artifactBindings.files),
       "authenticated artifact file bindings absent");
  const resolverCommon = freeze(copy({
    releaseRef: releasePin,
    receiptGroups: R.receiptGroups,
    artifactFiles: R.artifactBindings.files
  }));

  need(Array.isArray(L.rows) && L.rows.length === 33, "active row count");
  same(L.rows.map(row => row.id), P.fixedMappings.correspondenceRowIds, "active row IDs");
  digest(L.rows, K.activeRowsSha256, "active row-array guard");
  digest(T.sourcePatch.operations, K.sourcePatchSha256, "source patch guard");
  need(T.sourcePatch.operations.length === 151 &&
       T.sourcePatch.operations.filter(operation => operation.op === "test").length === 92,
       "source patch operation counts");
  const prepared = sourcePatch(L, T.sourcePatch.operations);
  digest(prepared.rows, K.preparedRowsSha256, "prepared row-array guard");
  hashText(pretty(prepared), K.preparedLedgerSha256, "prepared current full ledger");
  need(prepared.rows.every(row =>
    row.strictSh1Discharged === false && row.generalPreservationProven === false),
    "source preparation promoted a row");
  need(Array.isArray(P.rowPlans) && P.rowPlans.length === 33, "plan row count");
  const valueFromMap = spec => {
    same(spec.source.blob, K.map.blob, "mapped field source blob");
    const value = get(M, spec.source.jsonPointer);
    digest(value, spec.exactValueSha256, "mapped field " + spec.source.jsonPointer);
    return copy(value);
  };
  const stripDisposition = row => {
    const result = copy(row);
    for (const key of [
      "requiredRelation", "ruleArgument", "paperEvidence",
      "generalArgumentReview", "dischargeEvidence", "assuranceStatus", "strictSh1Discharged"
    ]) delete result[key];
    delete result.perCompilation.notEstablished;
    delete result.perCompilation.receiptLimitReferences;
    return result;
  };
  let retainedOriginalCount = 0, availableStringCount = 0, groupReferenceCount = 0;
  const pendingRows = [];
  const rowBindings = [];
  for (let index = 0; index < 33; index++) {
    const q = P.rowPlans[index], old = L.rows[index], base = prepared.rows[index];
    const row = copy(base), rr = R.correspondenceDispositions[index];
    const m = q.perCompilationMaintenance;
    same(q.index, index, "plan row index");
    same([old.id, row.id, rr.id], [q.id, q.id, q.id], "row identity " + q.id);
    same(q.rowPointer, "/rows/" + index, "plan row pointer " + q.id);
    same(rr.ledgerPointer, q.rowPointer, "release row pointer " + q.id);
    digest(old, q.guards.activeRowSha256, "active row " + q.id);
    digest(base, q.guards.sourcePreparedRowSha256, "prepared row " + q.id);
    digest(row.sources, q.guards.sourcesSha256, "source vector " + q.id);
    digest(row.domain, q.sourcePreparation.domainSha256, "source domain " + q.id);
    digest(old.perCompilation, q.guards.perCompilationSha256, "old evidence " + q.id);
    same(rr.sourceRowSha256, q.guards.activeRowSha256, "release active source guard " + q.id);
    same(rr.sourcePreparedRowSha256, q.guards.sourcePreparedRowSha256,
         "release prepared source guard " + q.id);
    need(rr.strictSh1Discharged === true && rr.generalPreservationProven === false,
         "release row disposition absent " + q.id);
    need(typeof rr.status === "string" && rr.status.length > 0, "release row status " + q.id);
    same(rr.requiredReceiptGroups, q.requiredReceiptGroups, "complete ordered groups " + q.id);
    need(new Set(q.requiredReceiptGroups).size === q.requiredReceiptGroups.length,
         "duplicate required row group " + q.id);
    same(rr.mappingRef, K.map.blob + "#" + q.reviewedArgument.mapRowPointer,
         "release map association " + q.id);
    need(Array.isArray(rr.receiptRefs) && rr.receiptRefs.length > 0,
         "actual row receipt references absent " + q.id);
    const resolvedGroupIds = A.resolveReceiptGroupIds(freeze({
      rowKind: "correspondence", rowId: q.id, rowIndex: index,
      receiptRefs: copy(rr.receiptRefs), ...resolverCommon
    }));
    need(Array.isArray(resolvedGroupIds) &&
         resolvedGroupIds.every(id => typeof id === "string"),
         "resolver must return a synchronous ordered group-ID vector " + q.id);
    same(resolvedGroupIds, q.requiredReceiptGroups, "actual reference coverage " + q.id);

    const relation = valueFromMap(q.relation);
    const argument = valueFromMap(q.argument);
    const papers = valueFromMap(q.paperEvidence);
    same(rr.paperEvidence, papers, "release paper evidence " + q.id);
    need(Array.isArray(papers), "paper evidence array " + q.id);
    const paperPins = [];
    for (const evidence of papers) {
      const matches = P.fixedMappings.paperPins.filter(pin => pin.id === evidence.packet);
      need(matches.length === 1, "unique paper pin " + q.id + "/" + evidence.packet);
      if (!paperPins.some(pin => pin.id === evidence.packet)) paperPins.push(copy(matches[0]));
    }
    const historicalLimits = old.perCompilation.notEstablished;
    need(Array.isArray(historicalLimits), "historical limits array " + q.id);
    digest(historicalLimits, m.historicalNotEstablished.sha256, "historical limits " + q.id);
    const kept = m.retainExactOriginalIndices.map(i => {
      need(Number.isInteger(i) && i >= 0 && i < historicalLimits.length,
           "retained historical limit index " + q.id);
      need(typeof historicalLimits[i] === "string", "retained historical limit string " + q.id);
      return historicalLimits[i];
    });
    digest(kept, m.retainedStatementsSha256, "retained historical limits " + q.id);
    const limits = [
      ...copy(P.fieldMaintenance.commonPerCompilationLimits),
      ...kept, ...copy(m.appendScopedLimits)
    ];
    digest(limits, m.resultingNotEstablishedSha256, "resulting limits " + q.id);
    need(Array.isArray(old.perCompilation.availableOrCandidate) &&
         old.perCompilation.availableOrCandidate.every(value => typeof value === "string"),
         "available evidence strings " + q.id);
    row.requiredRelation = relation;
    row.ruleArgument = argument;
    row.paperEvidence = papers;
    row.perCompilation.notEstablished = limits;
    row.perCompilation.receiptLimitReferences = q.requiredReceiptGroups.map(id => {
      const groupIndex = R.receiptGroups.findIndex(group => group.id === id);
      need(groupIndex >= 0, "release group missing " + id);
      return {
        id, limit: copy(R.receiptGroups[groupIndex].limit),
        releaseRecordReference: external(releasePin, "/receiptGroups/" + groupIndex)
      };
    });

    const general = copy(P.fieldMaintenance.generalArgumentReviewTemplate);
    general.mapRowPointer = q.reviewedArgument.mapRowPointer;
    general.independentMapReviewRowPointer = q.reviewedArgument.independentMapReviewRowPointer;
    general.paperEvidence = copy(papers);
    general.paperPins = paperPins;
    general.currentSourceTransport.metadataOverlay =
      external(K.overlay, "/projections/transport");
    general.finalAssemblyProcedure = {
      ...copy(K.procedureBase), jsonPointer: "/rowPlans/" + index,
      metadataOverlay: external(K.overlay, "/projections/procedure")
    };
    general.supplementalClosedUniverse = copy(q.reviewedArgument.supplementalClosedUniverse);
    general.historicalNotEstablished = copy(m.historicalNotEstablished);
    row.generalArgumentReview = general;

    const discharge = copy(P.fieldMaintenance.dischargeEvidenceTemplate);
    const rowPointer = q.deferredDischarge.releaseRecordCorrespondenceRowPointer;
    same(rowPointer, "/correspondenceDispositions/" + index, "discharge row pointer");
    discharge.status = rr.status;
    discharge.releaseRecordPath = releasePin.path;
    discharge.releaseRecordReference = external(releasePin, rowPointer);
    discharge.releaseRecordCorrespondenceRowPointer = rowPointer;
    discharge.qualificationSourceCommit = R.source.sourceRef;
    discharge.exactSourceClosureSha256 = R.source.sourceClosureSha256;
    discharge.exactRecipeSha256 = R.recipe.sha256;
    discharge.qualificationArtifactReference = copy(A.qualification);
    discharge.strictBinderArtifactReference = copy(A.strictBinder);
    discharge.providerArtifactReference = copy(A.provider);
    discharge.requiredGroupReferences = copy(rr.receiptRefs);
    row.dischargeEvidence = discharge;

    same(row.perCompilation.availableOrCandidate, old.perCompilation.availableOrCandidate,
         "preserved available evidence " + q.id);
    same(stripDisposition(row), stripDisposition(base), "unrelated row fields " + q.id);
    need(row.strictSh1Discharged === false && row.generalPreservationProven === false,
         "premature row promotion " + q.id);
    retainedOriginalCount += kept.length;
    availableStringCount += old.perCompilation.availableOrCandidate.length;
    groupReferenceCount += q.requiredReceiptGroups.length;
    pendingRows.push(row);
    rowBindings.push({
      id: q.id, activeRowSha256: q.guards.activeRowSha256,
      preparedRowSha256: q.guards.sourcePreparedRowSha256,
      releaseRowPointer: rowPointer
    });
  }

  need(pendingRows.length === 33 && new Set(pendingRows.map(row => row.id)).size === 33,
       "complete unique row set");
  need(retainedOriginalCount === 37, "preserved historical-limit count");
  need(availableStringCount === 72, "preserved available-evidence count");
  need(groupReferenceCount === 313, "complete ordered group-reference count");
  same(pendingRows.map(row => row.id), P.fixedMappings.correspondenceRowIds, "final row order");

  // Every required input, row, source, reference and limit check has succeeded.
  // Promotion is local to the returned clone; inputs and aggregate flags stay unchanged.
  for (const row of pendingRows) {
    row.assuranceStatus = K.finalStatus;
    row.strictSh1Discharged = true;
  }
  const result = copy(prepared);
  result.rows = pendingRows;
  const withoutRows = object => {
    const value = copy(object);
    delete value.rows;
    return value;
  };
  same(withoutRows(result), withoutRows(prepared), "top-level metadata changed");
  same(result.rows.map(row => row.perCompilation.availableOrCandidate),
       L.rows.map(row => row.perCompilation.availableOrCandidate),
       "complete preserved available evidence");
  need(result.rows.every(row =>
    row.strictSh1Discharged === true && row.generalPreservationProven === false),
    "final row flag consistency");
  const text = pretty(result);
  return {
    ledger: result, text, sha256: sha256(text), bytes: bytes(text),
    rowsSha256: H(result.rows), releaseRef: copy(releasePin),
    effectiveCatalogSha256: K.effectiveStaticCatalogSha256,
    counts: {
      rows: 33, strictDischarged: 33, generalPreservationProven: 0,
      sourcePatchOperations: 151, sourcePatchTests: 92,
      requiredGroupReferences: 313, preservedAvailableStrings: 72,
      retainedHistoricalLimitStrings: 37
    },
    rowBindings,
    topLevelActivationChanged: false,
    releaseModified: false
  };
}
