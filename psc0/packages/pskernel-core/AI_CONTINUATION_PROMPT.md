# Continuation prompt for a new regular chat

Copy the text below into the new chat.

---

Continue the PSKernel Core correctness project autonomously on the second
route: a PSKernel-owned reference checker and semantic model, reusing only
pinned Con Leche pure mathematics. Correctness has priority over performance.
Work toward full-kernel successful-checking soundness and an end-to-end
relative model/consistency theorem. Repair code and proofs when necessary,
with a recoverable checkpoint before architecture changes. Do not add custom
axioms, sorry, hidden stronger assumptions or a fallback checker. Do not call
fragment or conditional theorems full-kernel completion.

First read the live work state:
https://github.com/dwijayuda/pskernel/blob/psc0/pskernel-core-lean435-arena-v1/psc0/packages/pskernel-core/AI_WORK_STATE.md

Repository: dwijayuda/pskernel.
Branch: psc0/pskernel-core-lean435-arena-v1.
Package: psc0/packages/pskernel-core.
Draft PR: https://github.com/dwijayuda/pskernel/pull/89.
Lean target: 4.35.0-rc4 at c29b6dda4f7c20e3eeaa717c4e565663c5cfa364.

GitHub/cloud only: use repository APIs and GitHub Actions; do not use a local
filesystem, shell, checkout or local execution. Read the live head before work
and immediately before each update; use expected_sha and preserve concurrent
changes. Keep the PR draft. Do not merge, promote the default provider, change
PSC0's compiler seed, or create a recurring automation or new task.

Read applicable AGENTS files, GITHUB_FIRST_WORKFLOW.md,
psc0/docs/selfhost-language/CURRENT.md, REFERENCE_CORRECTNESS_PLAN.md and the
current evidence before edits. Generated PSC0 kernel qualification is open.

Last fully validated source/audit trigger: 35cef8c29358ecac8a3e89df540e0fdce72fcbca.
Later documentation commits may follow it. Verify completed logs and inspect
any intervening source changes before assuming the current branch is green.
Recovery checkpoint before this architecture slice:
checkpoint/pskernel-core-before-owned-acceptance-20261010
at 4a162b2056658155001828d0c17a426b000a3a2d.

The completed milestone shares raw/annotated local storage and fixed result/view
constructors, proves exact erasure and actual reference fvar retrieval, and
constructs binder/let context models under explicit parent, checked-reading,
freshness and scope premises. Actual checked-lambda/forall sort helpers retain
the real inferred type and symbolic level. Infer-only lambda is explicitly
unchecked. SortVisitSelected fixes same-visit provenance outside semantic
valuations and rules out conflicting zero/positive selections for that call.
Same-visit provenance does not establish cross-visit coherence.

The public recursive result, checker context and admitted declarations still
use raw specializations; lambda's observed carrier is projected at return.
Global annotation transport/guards, joint infer/WHNF/defeq soundness, allocator
and scope preservation, full admission and public consistency remain open.

Resume the smallest concrete slice in AI_WORK_STATE.md: derive binder-entry
freshness from a maintained syntactic local-frame invariant using existing
NamesBelow/allocator/opening lemmas, then carry the same produced readings and
provenance through the shared recursive interfaces and stored declarations.
Do not select an arbitrary annotation from a vacuous semantic predicate.

[ConLeche.SetTheory V] is an explicit relative assumption, not a constructed
instance. Only pure set mathematics at
65e74db49e89ad2bbd1e90aa4f784954db41fa3a is imported. Its checker/acceptance
theorem is not a PSKernel proof. Preserve the reference Int64 180-second
timeout and the intermediate df830e7 Init/Std/profile timeouts; a green
profiling job is not checker acceptance. The latest focused audit does not
supply a current Arena binary hash or full-corpus qualification.

Continue useful implementation and cloud validation. Source commits use
[skip ci], followed by a meaningful workflow-only audit trigger. Run full
proof/axiom/import/companion gates and native regressions; keep failures tied
to their actual source. Update AI_WORK_STATE.md, this prompt, the plan,
architecture/TCB/evidence and draft PR after the next validated stage. Report
exact proved scope and remaining theorem hypotheses. If required GitHub
capabilities are absent, explain the specific limitation instead of silently
switching to local work or claiming the proof is complete.
