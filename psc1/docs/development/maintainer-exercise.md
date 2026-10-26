# Fresh-maintainer exercise

Status: the human trial remains pending. CI is an automated rehearsal of the
instructions and a reference small change. Passing CI does not mean a fresh
maintainer understood the compiler. No simulated person or AI-written account
may be recorded as a completed human trial.

## Participant protocol

Use a clean Linux GitHub Actions checkout of the exact tested commit.
Work without AI chat assistance, this chat history or the reference solution
until you finish. Published repository documentation and source are allowed,
including material authored with AI; the trial measures independence from
interactive AI explanations. Normal source navigation and tool errors are allowed.
No local builds/tests or external messaging are needed.

Read [the compilation walkthrough](../guides/compilation-walkthrough.md),
[capabilities](../PSC1_CAPABILITIES.md) and [pass contracts](../reference/pass-contracts.md).
Run the walkthrough command in that workflow. Then:
1. Name the capture/parser/elaborator/erasure/IR-validation/emitter/publication owners.
2. Identify the exact admissions graph, output hash and immutable generation.
3. Explain what logical acceptance, strict IR, a runtime observation and a file hash
   each establish. Identify the first point checked publication becomes authorized.
4. Explain why a package manifest or PsValidatedIrModule value alone cannot authorize output.
5. Locate the Wasm runtime-dependency analysis, its caller and its fuel behavior.
6. Add one focused Lean regression: String.length needs both Nat and String
   runtime support. Put your test in a new test/RuntimeNeedsMaintainer.lean.
   Run lake env lean test/RuntimeNeedsMaintainer.lean after the normal build.
   Do not edit production analysis, fuel, the checker or acceptance criteria.
7. Make one tiny source change: change invert to identity in a separate example.
   Compile it and demonstrate false→false and true→true under both grammars.
8. Explain how an ill-typed replacement preserves the previous generation and
   how that differs from committed-but-durability-uncertain publication.

## Evidence and acceptance

Retain exact commit, workflow/job URLs, test diff, observed output/admission
hashes, source-owner answers, elapsed time, failed commands and every unclear
instruction. State prior Lean/compiler experience, AI/help used and whether you
consulted the solution. A reviewer must verify the answers against source and CI.

A human pass requires correct ownership/assurance answers, an actual passing
focused regression and changed-program results, no weakened gate, and no interactive AI
assistance. Any unassisted failure or ambiguity is useful usability evidence.
Do not convert time elapsed, an automated test or a self-declared checkbox into
a human-qualified result. Record human outcomes in a separate dated receipt;
never edit the immutable compiler qualification receipts to invent a participant.

## Automated rehearsal

scripts/compilation-walkthrough.mjs runs actual builds/consumers/negative
publication checks. It compiles the reference focused regression with official
Lean and requires a deliberately wrong assertion to fail. It writes:
- dist/maintainability/walkthrough.json: actual program/manifest/checker evidence;
- dist/maintainability/exercise.json: command reproducibility, not human comprehension;
- dist/maintainability/walkthrough-evidence.tar.gz: complete source/generation evidence.

The reference solution is available separately in
[PSC1_MAINTAINER_REFERENCE.md](./maintainer-reference.md). Read it after submitting
the independent attempt. It describes a small test addition, not a new language
feature or a proof of compiler preservation.

## Running your own regression in Actions

Use an isolated trial branch or fork through GitHub. Retain every existing gate
and adjust only the workflow branch filter if your trial branch needs it.
Add your test file and insert this step after the native build and **before**
the G1 step removes native executables:

~~~yaml
- name: Participant runtime dependency regression
  working-directory: psc1
  run: timeout 240s lake env lean test/RuntimeNeedsMaintainer.lean
~~~

Use actual assertions about the existing runtime-dependency functions; do not
use sorry, add axioms, change production behavior or bypass a checker to get a
green result. Retain the workflow URL and test diff for review. This task tests
a small compiler-maintenance regression, not a new language feature.

## Navigation and ownership trial

Without AI assistance, locate installed `psc build`, trace a program through
elaboration/admission/strict IR/publication, and identify the owner, negative test
and resource limit for a small backend change. Record elapsed time, incorrect
paths followed, confusing names, assistance and the exact commit using
[the participant report](maintainer-trial-report.md). Actual human observations
are required; automated rehearsal cannot qualify human understanding.
