# M3 direct-recursive Repr — focused qualification and full-suite reconciliation

16 October 2026. **Focused cross-target qualification passed; exact reconciled full-suite qualification is pending. M3+B remains OPEN.** This note supplements the implementation design in PSCV0_M3_RECURSIVE_REPR_2026-10-16.md; it does not rewrite prior failed or pending evidence.

## Focused evidence

Compiler/test commit `f0d2237239303fd7fc82499efc0333f749c69a6c` passed run **38897206572**, job **116960429649**. Every reported step succeeded: checked source and five-target emission, direct JS, strict compiled TS, locked Rust, V8 GC core and Wasmtime components, and artifact publication. The existing generic tree fixture compares exact independently computed Lean strings for Nat and Bool, root precedences 0/1024 and width 40. It retains the checked Hashable defining law and three Hashable plus three Repr intended-rule refusals. Recursive values remain internal; exports use the existing Bool-to-UInt64 ABI.

Artifact **12044600921**, name `pscv0-m3-recursive-hash-f0d2237239303fd7fc82499efc0333f749c69a6c`, size **225317 bytes**, digest `sha256:340abb082a14e68c5d262d01d6fcb8171683ea36e38af8a6acd368cd3f1b06be`. The artifact was present and unexpired when read. Hosting retention is not permanent availability.

The initial c942112d fixture failed because it used unavailable `String.beq` instead of the selected checked equality operator. f0d22372 changes those two source expressions to `==` without changing oracle strings, inputs, expected results or compiler logic. No compiler behavior changed between c942112d and f0d22372.

## Existing native test migration

The existing `Pscv0NativeTests.lean` deriving boundary still expected `inductive Bad where { | loop(tail: Bad) } deriving Repr` to fail. Direct-recursive Repr is now an intended capability with independent positive coverage. The negative is therefore migrated to a nested-recursive field `tails: List Bad`, which remains unsupported. The rejection phase/assertion and every other native fixture remain unchanged.

Cloud preparation **38897511036/job116961438670** verified original blob `1496891ff3e665ff5e06fb367b4175c845552b35`, replaced exactly one matching line, printed the unified diff and created unreferenced blob `913c02e94f1688da595c6bad617eb8a7f8f9c83b` (326254 bytes). The returned SHA was checked against the independently computed Git blob hash. That job changed no tracked source, tree, commit, ref or PR. The connector now applies the inspected blob and removes the completed temporary preparation workflow. Preparation success is not compiler qualification.

Earlier diagnostic 38897206612 successfully located the actual source owner, but its later redirected job-log download failed HTTP 401. It is not a green qualification. Inconsistent earlier log summaries naming absent scripts or a different Hidden declaration were not used to change compiler semantics.

## Exact next gate and scope

The reconciliation changes one native-test line, the Repr attribution/scope comment, both handoffs, this receipt and removal of the temporary diagnostic workflow. No executable compiler code, logical assumption, budget or qualification command changes. The packages comment change also causes all applicable native, independent and focused workflows to run at one exact reconciliation commit. Their results must be read before full-slice acceptance; do not inherit the older focused success.

Shared recursor motive/type validation, nonrecursive formatting and proof/type/hidden-field behavior remain intact. This slice is direct uniform nonindexed Repr, not mutual/nested/indexed deriving, complete P0 execution, P1 fixedpoints, full M3+B or global compiler preservation. No performance result is claimed. Approved assumptions remain propext/Quot.sound; no pskernel-core, self-hosting or C5 execution.
