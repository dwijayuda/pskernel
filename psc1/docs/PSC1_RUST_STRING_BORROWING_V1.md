# Rust read-only String operands

Status: implemented; exact-commit Linux qualification required.

The actual streaming compiler application at 5fa88fa1842d8d8d9fa1881592ed2801d2778b37
runs 100000 statements / 500000 bytes. Focused run 39664407902 observes
104.12 seconds for Lean/Rust and 116.93 seconds for PS/Rust, with about 15 MiB
RSS. Both meet the fixed 120-second / 1-GiB limits, but leave little timing
margin. The source and performance corpus are unchanged for this correction.

The Rust emitter normally clones a variable when an owned expression is
requested. Its read-only String intrinsics then borrow that temporary clone,
copying an entire input String for each character lookup/advance/end check.
The correction prints immutable local variables directly only in the known
borrowed String operand slots of length, UTF8 size, next/get/end, extraction,
equality, append and push helpers. The helpers already take shared references.
Globals, computed expressions, other operand slots, function arguments and
stored fields retain their previous ownership/cloning rules.

Every operand still passes through the original emitter before borrowing is
selected. Existing fuel exhaustion, unsupported-expression and first-error
behavior is preserved. Native regressions require exhaustion at direct and
nested operand boundaries and malformed intrinsic arity refusal. Rust's borrow
checker still checks the actual generated consumers; no unsafe code or runtime
carrier/ABI change is introduced.

The existing independent-reference Unicode/String/runtime corpus and actual
application run in both grammars/all seven backends, minimum Python and final
qualification. Measure the same process corpus before/after; never enlarge the
input's time/memory allowance or skip a backend to declare success.
