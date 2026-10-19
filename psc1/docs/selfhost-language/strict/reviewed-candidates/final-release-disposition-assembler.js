/*
Pure final release assignments after authenticated evidence-only completion.
Caller first binds all 136 core files, 223 selectors, 25 actual groups, equalities,
all three execution origins, original generation recipe, corrected evidence
producer and actual provider. Original 380151 stays cancelled; 380216 stays failed.
The current evidence-only job must succeed and supplies new qualification/binder.
Exact pending R/P/CP inputs below contain all unchanged source and proof guards.
The final33 and final27 helpers validate the completed record afterward.
Do not invoke on pending evidence. Store this release first; then use its immutable
reference for final33 and final27/SPEC. Actual receipt groups must stay immutable
after references are assigned. No external writes occur in this function.
*/
function finalizeBoundReleaseDispositions({release, projectedRelease:B, stagePlan:P,
  correspondencePlan:CP, sha256}) {
  const copy = x => JSON.parse(JSON.stringify(x));
  const J = x => JSON.stringify(x);
  const pretty = x => JSON.stringify(x,null,2) + "\n";
  const H = x => sha256(J(x));
  const need = (x,m) => { if (!x) throw new Error("final release: " + m); };
  const same = (a,b,m) => need(J(a) === J(b),m);
  need(sha256(pretty(B)) === "9d43138c419708fda4b55e3e098a8f9565cd6a120cc98e7ac42ba60b487bc4c3", "projected release guard");
  need(sha256(pretty(P)) === "0c04837d06a342832a73c8b8074c0882d20a3ffc949f256a561368a9336edb95", "current27 plan guard");
  need(sha256(pretty(CP)) === "94e4c5c8332889ae04fcbc2e27db7b2efb93210c47b2faca145620a93acc9d60", "current33 plan guard");
  const r = copy(release), X = r.execution, q = r.qualification;
  need(!Object.hasOwn(r,"finalCompletion"), "not already finalized");
  for (const k of ["sourceRef","rootTree","psc0Tree","sourceAuthority","sourceGrammar","currentReviewedSourcePins"])
    same(r.source[k],B.source[k],"unchanged qualified source " + k);
  same(q.scope,B.qualification.scope,"declared qualification scope");
  same(r.arguments,B.arguments,"frozen source/proof arguments");
  same(r.protectedClaims,B.protectedClaims,"protected producer claims");
  for (const k of ["expectedRunId","expectedWorkflowId","expectedHeadSha","requiredSourceRef","runAttempt","compilerJobId"])
    same(X[k],B.execution[k],"execution identity " + k);
  need(X.compilerConclusion === "success" && X.providerConclusion === "success" &&
    Number.isSafeInteger(X.providerJobId) && X.providerJobId > 0 &&
    typeof X.completedAtUtc === "string" && X.completedAtUtc.length > 0, "actual terminal compiler/provider completion");
  for (const k of ["workflowSourceBlob","orchestration","priorExecution","continuationInputs",
    "continuationInputsRole","generationExecution","evidenceProducer","evidenceProducerRepair",
    "generationOwnership","logOnlyGateOwnership","currentOutputOwnership"])
    same(X[k],B.execution[k],"preserved execution/producer provenance "+k);
  need(X.priorExecution.compilerConclusion === "cancelled" &&
    X.priorExecution.providerConclusion === "skipped" &&
    X.generationExecution.compilerConclusion === "failure" &&
    X.generationExecution.providerConclusion === "skipped","original failed outcomes retained");
  same(r.receiptGroups.find(g=>g.id === "strict-binder").currentEvidenceProducer,{
    executionPointer:"/execution/evidenceProducer",executionValueSha256:H(X.evidenceProducer),
    binderPointer:"/execution/evidenceProducer/binder",repairPointer:"/execution/evidenceProducerRepair",
    repairValueSha256:H(X.evidenceProducerRepair),
    sourceBlobMeaning:"Original generation-recipe source retained as the reviewed base of the exact evidence-producer correction."
  },"separate corrected binder producer");
  need(r.artifactBindings.observedComplete === true && r.artifactBindings.files.length === 136 &&
    r.equalityBindings.verified === true && r.provider.accepted === true, "completed artifact binder precondition");
  need(r.receiptGroups.length === 25 && r.receiptGroups.every(g => g.authenticated === true), "authenticated25 groups");
  const selectors = r.receiptGroups.flatMap(g => [...g.resolvedSelectors,...(g.currentSelectors ?? [])]);
  need(selectors.length === 223 && selectors.every(s => s.verified === true), "bound223 selectors");
  need(q.formalPreservationProven === false && q.generalPreservationProven === false &&
    r.activation.selectedByPsconfig === false && r.activation.selectedSeed === "R" &&
    r.activation.selectedSeedChanged === false && r.activation.genericCompilerApisAreImplicitlyStrict === false,
    "retained proof and selection limits");
  same(r.activation.qualifiedEntry,"psCompilerSh1TypeScriptSources","explicit strict entry");
  const priorPlanningState = {
    kind:r.kind,status:r.status,draftOnly:r.draftOnly,closesNoRows:r.closesNoRows,
    qualification:copy(q),activationStatus:r.activation.status,
    enforcementInstalled:r.activation.enforcementInstalled
  };
  const groupsBefore = H(r.receiptGroups);
  same(r.receiptGroups.map(g=>g.id),B.receiptGroups.map(g=>g.id),"original25 group order");
  const groupRefs = r.receiptGroups.map((g,i)=>({
    groupId:g.id,releaseGroupPointer:"/receiptGroups/"+i,receiptGroupSha256:H(g)
  }));
  const byId = new Map(groupRefs.map(ref=>[ref.groupId,ref]));
  const refs = ids => ids.map(id=>{ need(byId.has(id),"receipt group "+id); return copy(byId.get(id)); });
  need(r.correspondenceDispositions.length === 33 && r.stageDispositions.length === 27,
    "33/27 disposition cardinalities");
  let correspondenceReferenceCount = 0, stageReferenceCount = 0;
  CP.rowPlans.forEach((p,i)=>{
    const rr = r.correspondenceDispositions[i], old = B.correspondenceDispositions[i];
    same([rr.id,rr.ledgerPointer,rr.sourceRowSha256,rr.sourcePreparedRowSha256],
      [p.id,p.rowPointer,p.guards.activeRowSha256,p.guards.sourcePreparedRowSha256],"correspondence source guards "+i);
    same(rr.requiredReceiptGroups,p.requiredReceiptGroups,"complete ordered correspondence groups "+i);
    need(H(rr.paperEvidence) === p.paperEvidence.exactValueSha256,"correspondence paper guard "+i);
    same(rr.mappingRef,"697c94b2722a6191537b714f71f629713637b30a#"+p.reviewedArgument.mapRowPointer,"correspondence map "+i);
    same(rr.currentSourceTransportRefs,old.currentSourceTransportRefs,"frozen source transports "+i);
    need(rr.generalPreservationProven === false && rr.strictSh1Discharged === false,"pending conservative correspondence row "+i);
    rr.receiptRefs = refs(p.requiredReceiptGroups);
    rr.status = P.fieldMaintenance.completionStatus;
    rr.strictSh1Discharged = true;
    correspondenceReferenceCount += rr.receiptRefs.length;
  });
  function completeStage(i) {
    const p=P.rowPlans[i], rr=r.stageDispositions[i], old=B.stageDispositions[i];
    same([rr.id,rr.stage,rr.obligation,rr.ledgerPointer,rr.sourceRowSha256,rr.priorStatus,rr.priorStrictDischarged],
      [p.id,p.guards.stage,p.guards.obligation,p.rowPointer,p.guards.rowSha256,p.guards.status,false],"stage identity/source guards "+i);
    same(rr.sourceArgument,old.sourceArgument,"guarded pending stage argument "+i);
    need(H(rr.paperEvidence) === p.frozenMap.paperEvidenceSha256 &&
      H(p.completedCurrentNarrative.text) === p.completedCurrentNarrative.textJsonSha256,"exact stage argument/paper hashes "+i);
    same(rr.argumentReviewRef,p.independentReview.blob+"#"+p.independentReview.jsonPointer,"stage independent review "+i);
    same(rr.correspondenceRows,p.requiredCorrespondenceRows.map(x=>x.id),"stage correspondence prerequisites "+i);
    const ids=p.requiredReceiptGroups.map(x=>x.id);
    same(rr.requiredReceiptGroups,ids,"ordered stage groups "+i);
    need(rr.strictDischarged === false,"pending stage "+i);
    rr.sourceArgument=p.completedCurrentNarrative.text;
    rr.receiptRefs=refs(ids);
    rr.status=p.futureRowFields.status.valueAfterCompleteEvidence;
    rr.strictDischarged=true;
    stageReferenceCount += rr.receiptRefs.length;
  }
  for(let i=0;i<26;i++) completeStage(i);
  const d=P.rowPlans[26].nonCircularActivationPrerequisites;
  same(d.all33CorrespondenceRows,r.correspondenceDispositions.map((x,i)=>({
    id:x.id,releaseRecordPointer:"/correspondenceDispositions/"+i
  })),"activation33 prerequisites");
  same(d.preceding26Stages,r.stageDispositions.slice(0,26).map((x,i)=>({
    id:x.id,releaseRecordPointer:"/stageDispositions/"+i
  })),"activation26 prerequisites");
  need(d.currentStageExcludedFromItsOwnPrerequisites === true &&
    d.exactCompilerAndProviderEvidenceAlsoRequired === true,"noncircular activation");
  const activationPrerequisites = {
    correspondence:d.all33CorrespondenceRows.map((x,i)=>({...copy(x),dispositionSha256:H(r.correspondenceDispositions[i])})),
    precedingStages:d.preceding26Stages.map((x,i)=>({...copy(x),dispositionSha256:H(r.stageDispositions[i])})),
    prerequisiteCount:59,currentStageExcludedFromItsOwnPrerequisites:true,
    enforcementInstalledScope:d.enforcementInstalledScope,
    qualifiedEntry:"psCompilerSh1TypeScriptSources",selectedByPsconfig:false,selectedSeed:"R",selectedSeedChanged:false
  };
  completeStage(26);
  need(correspondenceReferenceCount === 313 && stageReferenceCount === 95,"complete ordered313/95 receipt coverage");
  r.kind="psc0-sh1-release-qualification";
  r.status="qualified-for-declared-strict-sh1-scope-by-reviewed-arguments-and-authenticated-evidence-completion";
  r.draftOnly=false;
  r.closesNoRows=false;
  for(const k of ["compilerQualified","sourceCheckpointQualified","semanticContractQualified","strictSh1Qualified","independentProviderAccepted"])
    q[k]=true;
  q.correspondenceRowsDischarged=33;
  q.stageObligationsDischarged=27;
  r.activation.status="qualified-for-explicit-strict-entry-and-recorded-lane";
  r.activation.enforcementInstalled=true;
  r.finalCompletion={
    status:"complete",completedAtUtc:X.completedAtUtc,compiledSourceRef:r.source.sourceRef,
    orchestrationHeadSha:X.expectedHeadSha,evidenceCompletionRunId:X.expectedRunId,
    predecessorExecutionPointer:"/execution/priorExecution",
    generationExecutionPointer:"/execution/generationExecution",
    historicalContinuationInputsPointer:"/execution/continuationInputs",
    evidenceCompletionInputsPointer:"/execution/evidenceCompletionInputs",
    evidenceProducerPointer:"/execution/evidenceProducer",
    evidenceProducerRepairPointer:"/execution/evidenceProducerRepair",
    generationOwnershipPointer:"/execution/generationOwnership",
    sourceClosureSha256:r.source.sourceClosureSha256,recipeSha256:r.recipe.sha256,
    basis:"Reviewed source arguments on the declared domain, authenticated exact compiler/runtime evidence, and separately scoped provider acceptance.",
    planInputs:{
      projectedReleaseSha256:sha256(pretty(B)),stagePlanSha256:sha256(pretty(P)),
      correspondencePlanSha256:sha256(pretty(CP))
    },
    priorPlanningState,
    historicalPlanningMetadata:{
      meaning:"The following retained preparation fields are historical planning descriptions; finalCompletion and the completed disposition records define current status.",
      pointers:["/proposedPath","/preparationScope","/qualification/pending","/freezeReason","/readbackAndStaticReview",
        "/integrationPlan","/execution/lastRootReportedProgress","/execution/actualRunIdentitySource"]
    },
    receiptGroups:groupRefs,receiptGroupsSha256:groupsBefore,receiptGroupsImmutableAfterFinalization:true,
    correspondenceDispositionsSha256:H(r.correspondenceDispositions),
    stageDispositionsSha256:H(r.stageDispositions),
    stageSourceArgumentHashes:r.stageDispositions.map((x,i)=>({
      id:x.id,jsonPointer:"/stageDispositions/"+i+"/sourceArgument",sha256:H(x.sourceArgument)
    })),
    activationPrerequisites,
    counts:{correspondence:33,stages:27,correspondenceReceiptReferences:313,stageReceiptReferences:95,activationPrerequisites:59},
    formalPreservationProven:false,generalPreservationProven:false,selectedByPsconfig:false,selectedSeed:"R",selectedSeedChanged:false,
    publicationOrder:["Store this exact release first","Assemble final33 using its immutable release reference","Assemble final27/SPEC using that release and the final33 reference"]
  };
  need(H(r.receiptGroups) === groupsBefore,"receipt groups unchanged after reference construction");
  const text=pretty(r);
  return {release:r,text,sha256:sha256(text),bytes:unescape(encodeURIComponent(text)).length,
    counts:copy(r.finalCompletion.counts),receiptGroupRefs:groupRefs};
}
