# M1 collection indexing implementation design

Status: List/Fin qualified at e73ce2bb / Linux 38384869133; Array qualified at
af96aa40 / Linux 38386745772. Final M1 coherence/performance evidence is pending.

## Reference and dependency order

The reference is Lean 4.35.0-rc4, commit
`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`, especially
[Init/GetElem.lean](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/GetElem.lean).
The native selected environment already has checked order reflection,
universe-polymorphic Option and the two-law GetElem? contract.

Implement the next layer in dependency order: Fin structure and adapters;
List proof worker and optional laws; then Array's checked logical model and
indexing APIs. Keep declarations as portable Core builders in native Lean.
Do not import the host library into the portable closure.

## Representation invariant

An inductive family's uniform parameters are available to Core checking and
constructor-field substitution. Only type parameters become target generic
arguments. A numeric parameter such as Fin's bound is not a stored field.
The same family-parameter classifier drives preparation and runtime type
reification. Ordinary function parameters retain their existing classifier:
this change must not erase computational Nat arguments.

Fin stores its value; its inequality proof is erased. Nat-indexed and Fin-indexed
GetElem adapters preserve the original collection predicate. GetElem? adapters
delegate through the original optional dictionary, including its exact superclass.
LawfulGetElem is available only from evidence for that underlying dictionary.
A Fin 10 value 1 is still invalid for a singleton collection.

## List algorithms and proofs

The proof-taking worker eliminates List and then Nat. The empty case derives
False from the actual strict bound; the successor branch derives the smaller
bound with checked Nat.lt_of_succ_lt_succ. The public List.get takes Fin length.
No default element is needed for valid access.

Optional indexing uses the existing List-recursive worker and stops at the
requested cell or list end, without calculating length first. Independent
positive and negative branch theorems relate that algorithm to proof access.
A reusable checked Decidable elimination assembles the dependent optional law.
Bang access folds the same Option result through the existing outOfBounds
logical/runtime contract: default in pure logical reduction, panic in execution.
Its second law is a checked definitional equality.

The selected List element universe remains Type 0; Option and generic Fin
adapters retain their explicit universe parameters. Do not call the selected
List roster unrestricted host-library parity.

## Array logical/runtime boundary (next)

The opaque Array type and getD primitive cannot supply total proof access without
an element or a new axiom. Replace the logical model with Lean's checked
single-field List structure, and define the selected array operations over that
model. Keep the existing efficient array intrinsics as the audited runtime
representation. Explicit Array.mk/toList conversions need a shared, checked
conversion path; Array.getInternal already has an IR intrinsic on every backend.

Preserve persistent aliases and compare arbitrary-precision indices before any
machine-index conversion. Wasm stores arrays using GC; linear memory remains
restricted to explicit component ABI boundaries.

## Conversion lowering and complexity

Array's kernel catalog now defines mk/toList/size/getInternal and the selected
primitive models using checked List recursion. The executable catalog contains
the public wrappers and dictionaries; model-only structure/primitive bodies
must not become a second runtime Array representation.

A single typed IR `arrayBuild` operation accepts a count, state and two unary
selectors. Its type signature validates the state and element types. Only the
Array.mk adapter constructs this operation from the exact List.length and
prepared List constructor metadata: no backend hardcodes List tags, field
names or generated symbols. The selectors' nil arms are unreachable under
that adapter's length invariant; no Core witness is invented.

The builder allocates private storage and visits each list cell once after a
linear length pass. JS pushes into one unpublished array, Rust fills one Vec,
and Wasm fills one newly allocated GC array. Array.toList uses the existing
typed array fold and checked List.reverse, also linear time. The extra reverse
pass is explicit; later measured optimization can add reverse traversal without
changing the source contract. These paths avoid quadratic persistent pushes.

Array proof access is a checked List proof-worker application in the logical
model and the existing O(1) typed arrayGet intrinsic in execution. Its optional
dictionary specializes the already checked generic lawful default with actual
Nat.decLt(size), retaining O(1) size/access. The exact specialized optional
dictionary owns the lawful witness. The backend/model correspondence is
runtime qualification evidence, not an erasure semantics theorem.

## Qualification

Use one compact source corpus plus the independent pinned oracle. Exercise
proof/automatic/optional/bang access, empty and boundary cases, very large
indices, Fin bounds different from collection bounds, and both lawfulness
dictionaries. Reject missing or false collection bounds. Preserve all previous
runtime observations and all existing kernel, strict IR, JS/TS/Rust, V8 and
Wasmtime gates. Review and pin each intentional Standard roster digest change.
Final M1 still requires Array coverage and controlled representative performance
comparisons; green List/Fin tests alone do not satisfy M1.

## Final measurements and adverse dictionary checks

Use a host-only native Lean harness, outside the portable closure. Compare
the same compiler with direct-return and checked-index bodies under identical
Array/proof binder telescopes at 16 and 128 declarations; collect three samples
after warmup, preserving all six compilation phase timings. Prelude admission
is amortized and reported separately.

Compare generated JS and official native Lean collection operations at 256 and
8192 elements: head/tail optional lookup and both conversions. Exclude collection
setup, verify checksums, retain five timing samples after warmup. These are
different runtimes: report measured costs and scaling, not a universal performance
parity claim. Rust/Wasm retain functional matrix qualification; no claim that
these JS/Lean timings benchmark those runtimes. Do not install flaky time limits.

Explicit custom optional instances must take priority over derived defaults.
Both direct and Fin-adapted lawfulness must refuse an optional dictionary that
returns none for a valid True predicate. Independent RC4 source cases check the
same boundary.
