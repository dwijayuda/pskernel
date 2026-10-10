# Continuation prompt for a new regular chat

Copy the text below into the new chat.

---

Continue the PSKernel Core correctness project autonomously. Correctness is the
priority over performance. Work toward full-kernel successful-checking soundness,
metatheory and an end-to-end relative model/consistency proof. Repair bugs and
change architecture when necessary, with a recoverable checkpoint first. Do not
add custom axioms, sorry, hidden stronger assumptions or a fallback checker.
Do not report fragment theorems or conditional lemmas as full-kernel completion.

First read the current work state from this exact active branch:
https://github.com/dwijayuda/pskernel/blob/psc0/pskernel-core-lean435-arena-v1/psc0/packages/pskernel-core/AI_WORK_STATE.md

Repository: dwijayuda/pskernel.
Branch: psc0/pskernel-core-lean435-arena-v1.
Package: psc0/packages/pskernel-core.
Draft PR: https://github.com/dwijayuda/pskernel/pull/89.
Lean target: 4.35.0-rc4 at c29b6dda4f7c20e3eeaa717c4e565663c5cfa364.

GitHub/cloud only: use repository APIs and GitHub Actions; do not use a local
filesystem, shell, checkout or local execution. Read the live head before work
and before every update; use expected_sha and preserve concurrent changes.
Keep the PR draft. Do not merge, promote the default provider, change PSC0's
compiler seed, create recurring automations or open a new task.

Read applicable AGENTS files, GITHUB_FIRST_WORKFLOW.md,
psc0/docs/selfhost-language/CURRENT.md, REFERENCE_CORRECTNESS_PLAN.md and the
current evidence before edits. PSC0 has a newer self-host profile than the old
PSC1 profiles, but generated kernel qualification remains unproved.

Resume the exact pending step recorded in AI_WORK_STATE.md. Verify completed
cloud logs rather than assuming the latest branch is green. If the document is
older than the branch, inspect the intervening commits and reconcile the state.
The last validated stage established one runtime annotated representation,
guarded structural coherence, syntax/validity transport and a concrete checked
application reading under explicit local premises. The next architectural step
is to carry and validate actual readings throughout the shared recursive
checker, local context and admission. Checkpoint before that migration. Global public annotation
provenance, joint infer/WHNF/defeq soundness, full admission models and public
consistency are still open unless later verified evidence establishes them.

The explicit [ConLeche.SetTheory V] foundation is a relative assumption, not a
constructed instance. Only pinned pure set mathematics is imported from
Con Leche. Never import its checker theorem as a PSKernel proof. Preserve the
recorded Int64 reference timeout and full-corpus gaps; passing small Arena tests
does not establish soundness or Mathlib compatibility.

Continue useful implementation/proof work and run appropriate cloud checks.
Keep AI_WORK_STATE.md and this prompt current for the next handoff. Report exact
proved scope, validation evidence and remaining internal hypotheses honestly.
If this chat lacks the required GitHub write/Actions capabilities, explain that
specific limitation; do not silently switch to local work or pretend edits ran.
