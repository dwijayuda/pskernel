# M3 direct-recursive BEq — qualification reconciliation

16 October 2026. **Focused candidate qualification passed; the reconciled compiler/test commit requires full exact qualification. M3+B remains OPEN.** See PSCV0_M3_RECURSIVE_BEQ_2026-10-16.md for the source design. This is not recursive DecidableEq, broader nested/indexed/mutual deriving, or production-performance acceptance.

## Candidate and qualification boundary

Compiler candidate **34426e22d9038fc8383722f047e39d93997e898c** adds checked direct uniform nonindexed recursive BEq to the existing induction machinery. Left-child hypotheses compare against right children; right constructor analysis ignores its own hypotheses. Field plans distinguish erased proofs, independent dictionaries and recursive evidence. No assumed self instance, partial helper, LawfulBEq assumption, source-name fast path or backend-specific equality is introduced.

Focused run **38902937385**, job116979372349, completed SUCCESS, including independently checked source/five-target generation, direct JS, strict compiled TS, locked Rust, V8 GC core and Wasmtime components. Independent F1 38902937331, F2 38902937315 and F3/F4/platform38902937137 passed this candidate.

Full native38902937355/job116979372269 failed in existing native checks with `bounded deriving unexpectedly accepted unsupported declaration`. Its suite still classified newly implemented direct-recursive BEq as unsupported. Later native stages were skipped. That failed run is not final qualification.

## Exact two-line fixture migration

Cloud preparation **38903969917**, job **116982807103**, succeeded at preparation-only074caffcf2238970ba079273d234311e9f749fc5. The fresh completed log prints original native-test blob913c02e94f1688da595c6bad617eb8a7f8f9c83b and prepared blob **44338bb06e8f633d8b27c6413cbd3c9b5c684979**, with independently calculated Git blob SHA and exact two-line diff. These observed values, not intermediate chat summaries, are authoritative.

`RecursiveCell` now uses `next: List RecursiveCell`, and generic `Chain` uses `tail: List(Chain A)`. These remain unsupported nested families. Original elaboration phase, rejection assertions and diagnostic expectations remain unchanged. All other tests, benchmark operations, checksums and budgets are unchanged. Positive direct-recursive capability is independently exercised by the expanded native-oracle tree fixture.

The connector applies that exact blob using fresh expected-HEAD/non-force update, and removes the completed temporary preparation workflow. The preparation job created only an unreferenced blob; it did not move a branch, edit a tracked file, create a commit or change a PR. The earlier single-replacement preparation failed during artifact download and is not this successful preparation.

## Actual candidate artifact and generated lowering

The completed log identifies focused artifact **12046737336**, size **238568 bytes**, named `pscv0-m3-recursive-hash-34426e22d9038fc8383722f047e39d93997e898c`. GitHub and independently downloaded archive SHA256 both equal **24dd67525fca27a4c08a12f164c30218f219cc890124009dca44f779e91f23be**. This artifact belongs to the compiler candidate, not the future reconciled commit.

Extracted expected.json records Nat/Bool comparison masks1/7 for false and7/1 for true; the non-reflexive field-dictionary test returns1 for both. Existing Hashable results and exact Repr strings remain. check.log records Hashable/Repr/BEq source/defining-law/phase-correct refusal success.

The actual generated `M3HashTree_instBEq__rec_0` inspects the left constructor and returns a right-value comparator. Its right constructor switch does not eagerly recurse on the right tree. Matching leaves call the actual `BEq_beq` dictionary; matching forks invoke the left-child recursive comparator on the corresponding right child, in conjunction order. Both direct-JS and compiled-TS output were inspected. This is fixture-specific lowering evidence, not a general complexity/preservation theorem or measured speedup.

## Remaining gate

Native, F1, F2, F3/F4/platform and focused deriving must all pass the exact reconciled compiler/test commit before BEq acceptance. Record its own actual artifacts and results rather than inheriting the candidate or Repr parent's success. v7.2 remains sole reference, blob694115223777599ba28ee175e14bb642b7b6aa4b; official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc; approved assumptions propext/Quot.sound only.

Recursive DecidableEq, broader data/elimination/motives/patterns, total recursion, P0 executable assurance and selected P1 fixedpoints remain open. Preserve shared partial-execution refusal; never execute an inhabitant as the program or manufacture body equations/totality. M2+A, Hashable and Repr acceptance remain unchanged. No pskernel-core, self-hosting, compiler-source migration or immediate C5. PR109 stays draft/open on its existing base and unmerged.
