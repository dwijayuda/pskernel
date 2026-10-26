# PSC1 AI work state

Updated 2026-10-26 Asia/Jakarta. Active draft [PR #190](https://github.com/dwijayuda/pskernel/pull/190):
refactor/psc1-maintainability-20261026, based on PR #189 at
7fc146ef50ff5ba28bae033e334c49d1a9cd5637.
Qualified implementation/test head: e760e95b534a8b344314d87939113abfbdd948da.
Later checkpoint commits contain documentation/receipt changes only.
Fetch live HEAD and actual CI before writes. Preserve single-parent,
expected-HEAD non-force history. Use connected GitHub/Linux Actions only.
No merge or npm publication is authorized.

[One roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md),
[exact maintainability receipt](docs/PSC1_MAINTAINABILITY_QUALIFICATION_2026-10-26.json),
[walkthrough](docs/PSC1_COMPILATION_WALKTHROUGH.md),
[pass contracts](docs/PSC1_PASS_CONTRACTS.md),
[qualified package capabilities](docs/PSC1_CAPABILITIES.md),
[independent maintainer exercise](docs/PSC1_MAINTAINER_EXERCISE.md).
The [preceding checkpoint](docs/history/AI_WORK_STATE_BEFORE_MAINTAINABILITY_2026-10-26.md)
preserves PR #189 verbatim; resolve its original relative links at 7fc146ef.

## Implemented and automatically qualified

Current guides now distinguish the qualified installed .7 package from later
development source. Stale JS-only checked-output and pending-provider labels
are reconciled with actual seven-target Linux qualification. The native legacy
publisher's possible postcommit flush error is distinguished from early source
refusal and from the generated publisher's explicit committedPublication result.

The source-linked walkthrough follows a tiny Bool program through native host
wrappers and shared semantic API landmarks, canonical admission, erasure,
strict IR, target emission, actual consumption and immutable output inspection.
It also locates the installed generated host separately. Pass contracts explain
input/output invariants, refusal/resource behavior and assurance boundaries.

Wasm Lower now imports Lower/RuntimeNeeds.lean for Nat/Int/String runtime
dependency analysis. **30 definitions / 640 lines moved with exact bodies,
names, order and fuel retained**. Lower is 4,898 lines under newline counting,
down from 5,537; the added import accounts for the one-line difference.
The leaf module imports only IR models and foundation lists. Type fuel 64 and
expression fuel 4096 retain their false-on-exhaustion behavior; this is a
selection hint, not a proof of runtime absence.

All52 recursive-prefix guards remain. The historical TypeInventory extraction
is checked against immutable 3089cbc3→446a0f21, while the new move and every
remaining Lower byte are checked against 7fc146ef. These are scoped structural
correspondence checks, not a whole-compiler preservation proof.

## Actual Linux evidence

Maintainer/G1 run **40272793607 /121409056260** passes at e760e95b:
- Documentation/capability/source-link checks; historical/current body extraction;
  seven host AST/format checks and all 52 prefix assertions.
- Four actual checked builds: invert and identity, each under .lean/.ps.
  Public exports/runtime results, exact captured sources, manifest inventories,
  actual independent graph replay and malformed checker-input refusal pass.
- Two ill-typed replacements preserve the prior generation and artifact bytes.
- The reference focused Lean regression is accepted; a deliberately wrong
  expected value is rejected. This is an automated exercise rehearsal.
- Both complete source grammar censuses accept all123 modules.
- Genuine unified Wasm G1 executes after native compiler executables are removed:
  **20 actual runtime cases +20 semantic refusals across four output targets,
  plus9 envelope refusals**. No G2/G3/fixed point is requested in this slice.

Artifact **12629405533**, ZIP SHA256
ac6bb27d654026a765b18bdc8d7f919185bd0e54052d1bcca62cd17615d25516,
6,487,076 bytes, contains actual walkthrough stores/graphs/manifests,
reference-exercise evidence, correspondence reports and G1 artifacts.
The failed first harness attempt40272480824 remains recorded; it incorrectly
used .mjs where native JS output requires .js. The guard was preserved.

Ordinary source **40272797072** passes all selected dependencies, full
**121412886837**, gate **121420619466**, **37/37 finite Practical Core criteria,
zero blocked**. Tested merge: 489aa897b170cd0ae65cbcf7e97585af942ab56b; its tree equals the qualified
head tree. The optional benchmark remains skipped/unqualified.
This qualifies the finite source contract, not a final universal release.

## Source and package identities remain distinct

Current development source: **123 modules**, Lean closure
e698ddecca4f57308472e261be880edded425d9ddae58c9ead43ed1973647c0f.
Actual integrated source members: 4742.
PS closure: 37b5dfa292376274a3b5ebe3f3bdb29c3e61327889743cd8eeff65737dbdb013.

The qualified .7 npm payload remains attached to the previous 122-module
closure 073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9,
not the refactored source. Root SHA256
d4a0e963375366ac9b417dd1e9eb5372168c25c5230d3ce69f694274daa87043,
3,811,703 bytes. Original package replay40250645368 and source40250678016 remain
qualified at their own identities. Four genuine G3 fixed points remain
JS/TS/Wasm40223062370 and Rust40223086966.
No frozen compiler/kernel executable or scripts/slim-universal-input.json changed.
Promotion of a new compiler payload requires its own generation/release evidence.

## Independent human trial is not qualified

The executable protocol, source-owner questions, small regression/change tasks,
reference solution and evidence rubric are ready. CI passes the command/reference
rehearsal, including a negative assertion. It is AI-authored engineering work.
No independent fresh human participant has completed the unassisted trial here.
**humanQualified:false** remains explicit; no timing, automated checkbox or
successful CI may be used to invent a human result. Retain anonymous participant
experience, exact commit/runs/diff, answers, help used, time and ambiguities in a
separate dated receipt when an actual trial occurs.

## Continue

Start with live HEAD, this receipt and actual CI. Obtain the unassisted human
exercise result when a participant is available; fix observed documentation
ambiguities. Further readability work should extract one responsibility at a
time, retaining bodies before naming/algorithm changes. Use the roadmap for
component String/IO, provider application coverage, automatic bounded source
package resolution, native legacy committed-outcome classification, additional
platforms, final clean release reproduction and authorization.

Official Lean 4.35.0 /eb6cafb7290e8bd5f2937522d8d804f58f02bafc, trust 0,
independent admission, strict original/transformed IR, source/body pairing,
semantic fuel, negatives and memory/stack/lifetime policies are unchanged.
Compiler/tools/G1/corpus requests 240 seconds; checker 120 seconds; existing manual G2/G3
correctness and original 240-second performance profiles remain separate.
Default kernel stays genuine official C++/Emscripten linear-memory Wasm;
compiler-Wasm stays GC. Runtime observations, hashes, admission and fixed points
are distinct evidence and do not establish whole-compiler semantic preservation.
