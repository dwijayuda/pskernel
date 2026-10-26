# Compiler pass contracts

These are explanations of existing obligations, not new runtime authority.
Use [the source-linked walkthrough](PSC1_COMPILATION_WALKTHROUGH.md) to locate
each owner. The current supported subset and exact qualification remain separate
from unrestricted Lean or a whole-compiler preservation proof.

| Pass | Required invariants | Failure behavior | Resource contract |
| --- | --- | --- | --- |
| Capture/import ordering | Exact fatal-UTF8 source bytes, stable module/source identities, dependency order and original snapshots | Missing, cyclic, stale or malformed input refuses; metadata cannot grant tools/checker/output authority | Existing source/transport limits; enclosing240s compiler request |
| Lex/parse | Both surfaces construct shared syntax; positions retain established byte/scalar convention; generated anchors remain distinct | Grammar/unsupported-source diagnostics; successful parse grants no admission | Existing parser fuel and source bounds; no new unbounded recursion |
| Resolve/elaborate | Scoped identities, checked types, implicit choices and actual source origins; ordinary logical/body pairing retained | Ambiguous/unbound/ill-typed/unsupported constructs refuse | Existing semantic fuel; no change to configured heartbeat/recursion policies |
| Canonical admission | Encode exact prepared logical declarations and official Lean identity | A failed/refusing/mismatched checker stops checked output; no silent fallback | Actual checker120s; fixed canonical protocol and capture limits |
| Erasure | Consume the same prepared input, preserve runtime names/ordinary body pairing and reject unsupported erasure | Typed erasure failure; verified wrappers are not proof certificates | Existing traversal/fuel/stack policies |
| Strict IR | Validate original IR and transformed/specialized IR; wrappers alone grant no validity | Any invalid type/structure/reference refuses before checked publication | Existing IR size/fuel limits and compiler request supervisor |
| Closed plan/specialization | Stable public names, closed runtime dependencies and target-specific ABI; shared semantics before backend mappings | Unsupported ABI or failed specialization refuses; no other-backend fallback | Existing specialization limits; no increased fuel or resource budget |
| Wasm RuntimeNeeds | Read-only Nat/Int/String selection hints over existing IR; intrinsic cross-dependencies and short-circuit order unchanged | Exhausted type/expression fuel returns false, not a proof of absence; downstream strict/backend checks remain mandatory | Type fuel64, expression fuel4096; parenthesized worker/input order unchanged |
| Lower/emit/target consumer | Preserve representation/call/evaluation conventions; revalidate target form and exact advertised API | Unsupported lowering, target validation or consumer failure refuses | Existing request240s and target-specific memory/stack/transport limits |
| Publication | Private staging, exact source/tool hashes, sealed immutable generation and one current-pointer commit | Precommit failure retains prior output; generated host reports committed uncertainty; native legacy final-flush errors can occur after pointer commitment | Existing locks/fsync/lifetime policies; only qualified platform commits enabled |

RuntimeNeeds now owns30 existing declarations moved unchanged from Lower.lean.
It imports only IR models and foundation lists. It does not select host tools,
admit code, validate IR or lower instructions. Its outer caller,
psWasmLowerSpecializedModule, retains runtime injection decisions. These helpers
are intentionally explicit/fuelled; do not simplify their shape without measuring
actual compiler behavior and preserving the operational guards.

The module extraction check compares every moved declaration byte and every
remaining Lower byte with7fc146ef. It separately retains the original
3089cbc3→446a0f21 TypeInventory proof against immutable history. A structural
correspondence check plus Lean/CI/G1 evidence is not a formal proof of all
compiler semantics. Frozen packaged G3 compilers are unchanged; current-source
generation evidence must carry its own identity.

For a new pass, document input/output types, preserved invariants, refusal order,
traversal/effect order, fuel/size/lifetime behavior, and the relevant tests/proofs
before changing behavior. Formatting, movement, renaming and algorithms belong
in separate reviewable changes.
