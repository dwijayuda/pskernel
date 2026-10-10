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

Latest verified public-frame proof source: `3fe5058e847d8b99242da1c087cb658079596393`,
focused run 38071399079 (321 semantic axiom targets, 153 model modules,
267 jobs, 84 companion proofs, seven native regression executables).
Newest pending candidate: `63cdc22d339f821be6bdcfa25b5f15e936aafdbf`
(run 38071595259) additionally relates accepted public empty kernel-session
construction to its empty environment and real checker frame. Check the
completed run and do not promote unverified output.

Architecture decision and full theorem gates:
`psc0/packages/pskernel-core/PROOF_GUIDED_FULL_SOUNDNESS_AND_LEAN435_COMPATIBILITY.md`.
Pin Lean 4.35.0-rc4 and preserve real Lean admission behavior; formal
relative consistency requires a modeled axiom/basis policy, not a false
unconditional claim about arbitrary Lean user axioms. The execution/model
gap requires carrying actual annotated provenance across one shared
reference checker; never substitute a disconnected paper checker.

Run 38070188607 failed overall on **full Init and Std checker timeouts**,
despite green proof/build/smaller conformance jobs; Mathlib skipped.
Do not claim full corpus acceptance or resolve resource issues by patching
soundness assumptions.

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

Latest fully validated source/audit trigger: 566d1c88dc3ac997a2f4d1f76810036529db8d2a
(code at bd32e4fcb64cc6c2b6c6555b39ad308ad9c4309a).
https://github.com/dwijayuda/pskernel/actions/runs/38066810266/job/114256009792
passed 266 build jobs, 84 companion files, 298 semantic axiom targets,
152 model dependency modules, 1,840 reference-policy definitions with zero
cached fallbacks, and seven native regression executables. Binary, Arena and
fresh 4.35 exports were skipped. The prior reserved-identifier failure at
run 38066469877 is preserved in MIGRATION_EVIDENCE.json.
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

The bounded-frame binder-entry theorem has now been implemented. Resume with
the **global graded invariant**: connect empty public context and current
`LocalFrame`/`BoundFrame` to every successful recursive
`psKernelInferCoreWithFuel`, WHNF and DefEq transition, tracking monotone
allocator and scope; then carry the same produced readings and provenance
through the shared recursive interfaces and stored declarations.
The frame theorems cannot be treated as whole-checker soundness.
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
