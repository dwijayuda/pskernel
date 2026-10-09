# Source evaluation corrections: Nat majors, runtime operands, and partial applications

## Status and scope

This is a source-reviewed candidate for a separate semantic qualification after the immediate TypeScript equality correction. It has not been executed or qualified by the preparing agent. The implementation and regression must be integrated with the root-owned evidence binder before cloud qualification.

The candidate corrects four concrete lowering classes:

1. A computed Nat match major is used twice on the successor path.
2. The `stringAtEnd` template evaluates the position before the text.
3. The `arrayEmptyWithCapacity` template places a computed capacity inside an ordinary arrow body, although an emitted function call contains `yield*`.
4. Partial-application completion places computed callee/supplied operand expressions inside the returned lambda, delaying or repeating their evaluation instead of capturing their values when the partial application is formed.

This does not add language syntax, operations, source effects, or an FFI. It does not change the kernel, provider, definitional equality, preparation cache, selected R seed, or existing metatheory. Lean remains pinned to 4.34.0 / `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`; Node remains 22.23.3 and TypeScript remains 7.0.2. Current PS grammar remains `ps-0.9-r3/new-only/bounded-selfhost-subset`.

`strictSh1Qualified`, `semanticContractQualified`, `formalPreservationProven`, `sourceProofProvenanceReconstructed`, and `sourceEffectCapabilityAdded` remain false. This candidate does not discharge all correspondence obligations.

## Immutable implementation bases

| Component | Base blob | Candidate blob |
|---|---|---|
| Erasure/Expr | `28e14f991df68c4a7d49f09120a42c85c919d6a8` | `3e11222a620cd044c9a5d48243c9b33421b5d5dc` |
| BackendTs/Expr | `9628e3c9def09c487abb5b8859a79c7be735acf9` | `dfd58154826c892d18b97b84303abbce6a622d7b` |
| Runtime conformance gate | `8838155fb80ef28f7bf5c3916c207c6c94451634` | `2b25f896d25689b6a432ad0d8a60d23aec47063c` |
| Existing application sequencing source guard | `a8c352d39fbfccc3b477e7d693407cf9513c8a8f` | `852240e14ed49ce01b1f835133492fd117db4327` |

The backend base already includes the six TypeScript equality operand widenings. The runtime gate base already includes the six-declaration raw Nat equality regression. Those changes are preserved.

The Erasure/Expr candidate combines the Nat-major correction with application operand capture and fresh completion parameters. Its intermediate Nat-only blob was `3153b38e9a85e00932cac7cad59440dede218899`; the final candidate supersedes the initially reviewed partial-application blob `0476a750353a72d7bf565f13e6621da87a5914db` by preserving computed callees with erased proof binders. The exact four-region refinement is `35ab1d9ef8faca77d919af2e8c4a52f270710add`.

The backend candidate changes only the `stringAtEnd` and `arrayEmptyWithCapacity` case blocks. Its guarded two-case manifest is `16a90c66221140855458e19aeacb5d065a7f5994`. The source sequencing guard now protects nine sequenced locals instead of eight: separating the parameter's base spelling from its checked fresh output name adds one let. Its other existing syntax requirements and mutation checks are preserved.

## 1. Computed Nat match majors

The existing Nat recursor lowering constructs a zero test and, for the successor alternative, a predecessor expression. Reusing an arbitrary erased major in those two positions re-evaluates it on the successor path. Variables and natural literals already denote values; a call or another compound expression can perform substantial work.

The correction first erases the major in the original scope. For a Nat major other than a variable or natural literal, it introduces one fresh IR `letE` of type Nat, then passes its variable to the existing Nat alternatives lowering. The zero test and predecessor therefore read the same value. The let is outside the branch choice, so it evaluates before either branch.

The temporary is reserved in the output-name index before minor erasure. Core lookup entries and Core locals are unchanged; the temporary has no invented source declaration or Core identity. The name count increases with the output-only reservation so the existing bounded fresh-name search has the correct bound. A failed freshness check refuses instead of emitting a captured name.

The local argument is conditional on the existing erasure and emitter semantics: the major returns a canonical Nat, the let evaluates its value once, and the conditional selects one branch. It is not a whole-compiler preservation theorem. The existing Nat predecessor operation, recursive-parameter calculation, minor erasure algorithm, and non-Nat match handling are retained. Variable/literal majors take the old value path.

Two naming fixtures have separate purposes. One supplies an existing parameter named `_psNatMajor` and shadows it in the successor pattern. The other uses that pattern name while the preferred temporary name is initially available. Together they exercise occupied-name selection and reservation against a later branch binder. A nested computed match exercises an outer temporary surviving while another is introduced.

## 2. String operand order

The old output has the shape:

```typescript
(position >= __ps$utf8(text).size)
```

That evaluates position before text, despite the source operation's text-then-position argument order. The value comparison is otherwise unchanged.

The corrected output evaluates the original expressions as two arguments:

```typescript
((__ps_s: string, __ps_p: bigint) =>
  (__ps_p >= __ps$utf8(__ps_s).size))(text, position)
```

Text and position each occur once in the outer call arguments. The helper body only refers to its parameters and the existing UTF-8 helper. Thus caller expressions cannot be captured by those parameter names, and the UTF-8 size computation runs after both arguments have produced values. No text normalization, offset policy, UTF-8 cache algorithm, or scalar law is changed.

## 3. Computed array capacity

The old empty-array template inserts the capacity expression into an ordinary arrow body:

```typescript
(() => { void (capacity); return []; })()
```

The ordinary-call emitter emits `yield* __ps$invoke(...)`. If capacity contains such a call, nesting it in the ordinary arrow is not a legal generator context. A literal-capacity fixture cannot expose this class.

The corrected template keeps the capacity expression in the surrounding context:

```typescript
((__ps_capacity: bigint) => {
  void __ps_capacity;
  return [];
})(capacity)
```

The capacity expression is evaluated once before the arrow body. The body contains only a parameter read and empty-array construction. The type annotation does not convert the value. Capacity remains an allocation hint; this does not claim equal physical capacity, equal allocation failures, or representation of arbitrarily large host arrays.

## 4. Partial-application operand capture

The application worker consumes the prepared function telescope, erases type/proof arguments, and collects retained runtime arguments. When runtime arguments are missing, `psEraseFinishApplicationWithFuelWorker` creates a completion lambda. The old completion body embeds the already supplied expressions directly. A local binding such as `let saved := f (make value)` therefore delays `make value` until `saved` is called, and repeats it if `saved` is called twice. A computed callee has the same problem.

The correction wraps the completion lambda in ordered IR lets for the computed operands: callee first, then supplied runtime arguments from left to right. The lambda refers to the resulting values. Consequently these computations occur when the partial application is formed, including when the closure is unused. A failure stops the prefix before later operands or the following source expression can run.

### Runtime types and omission

`PsErasureAppliedArguments.runtimeArgumentTypesRev` records the original Core domain beside each supplied runtime operand, before the next telescope substitution. Its final reversal matches the existing runtime-argument reversal. Type and proof operands add neither a runtime argument nor a runtime-domain entry. This stores type expressions; it does not introduce an extra runtime-type erasure pass on fully saturated calls.

For a computed supplied argument, its retained Core domain supplies its let annotation. For a computed callee, the annotation is the monomorphic runtime arrow built from the ordered supplied runtime-domain types, the already completed runtime parameter types, and the leaf result type. Ordered domain erasure uses the existing first-error-preserving `psListMapExcept`.

The full original Core Pi type is deliberately not used as a computed-callee annotation. That type may contain a proof binder which the ordinary runtime type eraser turns into `unknown`, even though the callee term erases to a typed ordinary lambda. Reconstructing the retained arrow from the actual telescope classification preserves this accepted case. It does not fabricate a type for an unsupported domain: original strict IR checking still validates every resulting annotation and call.

A direct generic callee remains its original IR variable with the same ordered type arguments on the call. It is never stored as an uninstantiated polymorphic scheme in a monomorphic let. Missing required type instantiation retains the existing refusal. Proof expressions are never emitted as runtime captures.

### Values, names, and nested groups

Only IR variables and literals skip capture. This relies on immutable source locals, available immutable declaration values, and typed canonical literals. A direct generic variable must keep that representation. The source does not admit host mutation of lexical bindings.

Completion parameter names now use `psErasureLocalName`, with a fail-closed check, instead of relying only on a fresh-looking `name$id` spelling. At the completion leaf, the scope already contains every generated runtime parameter. Capture names are selected against that completed scope and all emitted declaration names; each capture then reserves its output name and increments the existing freshness count before the next capture is chosen. Only `declarationNames.byOutput` and `count` are extended. Core local identities, `byCore`, type-local maps, erased-local maps, and substitution targets are unchanged.

The argument-list invariant holds for any supplied prefix: the accumulator contains the same ordered operand values, and the reverse binding list wraps lets in evaluation order. A nested partial application applies that same rule to its own supplied prefix, preserving values already captured by the previous closure. No extra target call is invented at closure construction.

Backend capture assumptions remain explicit. General generator functions and emitted lets use ordinary lexical bindings. Count-loop optimization returns Nat and does not produce closures. The tail-loop recognizer rejects arbitrary lambda-valued locals and only removes its guarded self-tail aliases whose captured prefix is already variables. These source-inspected guards are relevant to the immutable-variable assumption; a general backend simulation remains a separate obligation (Module blob `fa6491f4861ddc59caba51c03a29790fc6e8653b`).

The local rule argument is compositional: assume preservation for the callee/operand subexpressions and eager ordered let/call semantics. Induction over the supplied operand list then gives the same values and first-failure prefix before the same completion closure is built; each closure call uses those values. This is a rule argument for computed operand capture, not a checked universal theorem for all source application groups, function-result eta expansion, or the entire compiler.

### Existing entry points

The source callsite audit found `PsErasureAppliedArguments` only in Expr.lean, including its four record constructions; there were no external constructor/pattern sites in indexed PSC0 source. All returned executable search hits were read and the actual original/next Expr sources were inspected. Root integration must still guard against concurrent source additions.

The general source application path uses `psEraseFinishTypedApplication` with the retained runtime-domain witness. The remaining production caller of the old value-only `psEraseFinishApplication` is `psOpenMatchMinorHypotheses`: its callee is `var current.name` and `psErasureRecursiveCallArguments` constructs only variables. The only external executable `WithFuel` caller is the native diagnostic `psAuditFinish` in SelfhostReplayAudit blob `5d7bf2e1df15f47c4531272ea61b5c2db1332beb`; its listed cases use a variable callee and empty/variable argument lists. Their public wrapper signatures and value-only result shapes stay unchanged.

The untyped low-level entry refuses a computed partial operand when no type witness is available. No identified ordinary source path is redirected to that limitation. The fully saturated leaf never consults capture metadata and retains its original body exactly. Source-marker guards and documentation contain the other indexed name occurrences.

## Raw source regression

The single module is `Ps.Compiler.StrictEvaluation`. It contains eleven definitions, one structure, and no imports. Both raw Lean and new-only PS are fed to the source-owned atomic API. The gate checks equal emitted TypeScript and canonical admissions, then compiles that one shared TypeScript module once.

The twelve source declarations exercise:

| Definition | Purpose |
|---|---|
| `strictNatComputed` | Zero/successor behavior for a computed arithmetic major |
| `strictNatNested` | Two nested computed Nat matches |
| `strictNatCollision` | Existing preferred temporary name and shadowing pattern |
| `strictNatBranchBinder` | Pattern name colliding with a newly reserved temporary |
| `strictNatProbe` | Pure higher-order major `major (start seed)` |
| `sh1RuntimeAtEndCalls` | Computed text and raw byte-position arguments |
| `sh1RuntimeEmptyCalls` | Computed capacity with an emitted ordinary call |
| `StrictPartialFn` | A supported structure field containing a monomorphic function |
| `strictPartialCalls` | Computed callee, two supplied computations, reused or unused closure, and occupied capture names |
| `strictPartialNested` | Two incomplete application groups with successive captured operands |
| `strictPartialKeep` | Rank-1 generic helper with erased proposition/proof parameters |
| `strictPartialGeneric` | Generic partial closure called twice, instantiated at Nat, Bool, and String |

The raw Lean source is:

```lean
def strictNatComputed (value : Nat) : Nat :=
  match Nat.add value 0 with
  | Nat.zero => 97
  | Nat.succ predecessor => Nat.add predecessor 3

def strictNatNested (value : Nat) : Nat :=
  match Nat.add value 1 with
  | Nat.zero => 101
  | Nat.succ outer =>
      match Nat.add outer 2 with
      | Nat.zero => 103
      | Nat.succ inner => Nat.add inner 7

def strictNatCollision (_psNatMajor : Nat) : Nat :=
  match Nat.add _psNatMajor 1 with
  | Nat.zero => _psNatMajor
  | Nat.succ _psNatMajor => Nat.add _psNatMajor 13

def strictNatBranchBinder (value : Nat) : Nat :=
  match Nat.add value 0 with
  | Nat.zero => 23
  | Nat.succ _psNatMajor => Nat.add _psNatMajor 31

def strictNatProbe (major : Nat -> Nat) (start : Nat -> Nat)
    (zero : Nat -> Nat) (successor : Nat -> Nat) (seed : Nat) : Nat :=
  match major (start seed) with
  | Nat.zero => zero 17
  | Nat.succ predecessor => successor predecessor

def sh1RuntimeAtEndCalls (getText : Unit -> String) (getPosition : Unit -> Nat) : Bool :=
  String.Internal.atEnd (getText Unit.unit) (String.Pos.Raw.mk (getPosition Unit.unit))

def sh1RuntimeEmptyCalls (getCapacity : Unit -> Nat) : Array Nat :=
  Array.emptyWithCapacity (getCapacity Unit.unit)

structure StrictPartialFn where
  apply : Nat -> Nat -> Nat -> Nat

def strictPartialCalls (_psAppFn : StrictPartialFn) (_psAppArg : Unit -> Nat)
    (getSecond : Unit -> Nat) (after : Nat -> Nat) (seed : Nat) (useSaved : Bool) : Nat :=
  let saved : Nat -> Nat := _psAppFn.apply (_psAppArg Unit.unit) (getSecond Unit.unit);
  let next : Nat := after seed;
  if useSaved then Nat.add (saved next) (saved next) else next

def strictPartialNested (_psAppFn : StrictPartialFn) (_psAppArg : Unit -> Nat)
    (getSecond : Unit -> Nat) (after : Nat -> Nat) (seed : Nat) : Nat :=
  let first : Nat -> Nat -> Nat := _psAppFn.apply (_psAppArg Unit.unit);
  let saved : Nat -> Nat := first (getSecond Unit.unit);
  let next : Nat := after seed;
  Nat.add (saved next) (saved next)

def strictPartialKeep {p : Prop} (Alpha : Type) (h : p)
    (chosen : Alpha) (ignored : Nat) : Alpha := chosen

def strictPartialGeneric {p : Prop} (Alpha : Type) (h : p)
    (make : Unit -> Alpha) (after : Nat -> Nat) (seed : Nat) : Alpha :=
  let saved : Nat -> Alpha := strictPartialKeep Alpha h (make Unit.unit);
  let next : Nat := after seed;
  let prior : Alpha := saved next;
  saved next
```

The PS fixture uses typed comma-separated parameter groups, adjacent calls, newlines for lets, and braced match/structure bodies. In particular the array result is `Array(Nat)`. It contains no legacy syntax or compatibility fallback.

The computed callee is a function-valued structure projection, a form supported by both existing frontends. The bounded Lean parser cannot apply an arbitrary grouped expression as a callee, so the shared fixture does not rely on that syntax. Current PS grouped lambdas can also contain erased proof binders; the retained-arrow construction above addresses that general type-erasure case without changing the frozen shared fixture.

## Native pure-value reference

A single small native Lean module contains those exact raw Lean declarations plus a native-only `import Lean`, JSON helpers, and an IO entrypoint. It is executed once from the existing `runNativeStrictRuntimeReference` lifecycle. It does not prepare the full compiler or import PSC0.

The original `test/StrictRuntimeReference.lean` bytes, 45-operation contract, and 186 native observation rows remain unchanged. The extra native result is a separate `sourceEvaluationReference` field and standalone receipt. N1/C1/C2/C3 all reuse it; no generation reruns the new native module.

Twenty-four independent fixed expected values are checked against the actual native observations and then against generated execution:

| Cases | Expected values |
|---|---|
| Computed major at 0, 5, and 900719925474099312345678901234567890 | 97, 7, 900719925474099312345678901234567892 |
| Nested match at 0 and 5 | 8, 13 |
| Occupied-name collision at 0 and 7 | 13, 20 |
| Branch-name collision at 0 and 7 | 23, 37 |
| Pure major/start identity callbacks at 0 and 5 | 117, 204 |
| At-end for `é😀` at byte offsets 0, 2, 6, 7 | false, false, true, true |
| At-end for empty text at offset 0 | true |
| Empty-array capacities 0 and 17 | [], [] |
| Weighted partial target with first=2, second=4, seed=3, successor after-step, closure called twice | 488 |
| Same partial closure formed but unused | 4 |
| Nested partial groups with seed=5 and closure called twice | 492 |
| Generic/proof-erased partial at Nat, Bool, String | 23, true, `é😀` |

The native wrapper reports its actual Lean version and Git hash. Its source, raw fixture, stdout, stderr, and standalone receipt are retained and hashed. The complete native JSON receipt is preserved. Only the separately recorded observation objects use a fixed key order for a stable digest; this is evidence serialization, not source or IR normalization.

## Separate diagnostic host probes

Twenty-one host observations are deliberately separate from the native pure-value result. The original eleven rows remain unchanged:

- Nat successor and zero paths check `start → major → selected branch`, exactly once.
- Nat failures at start, major, zero, and successor check the first error and the executed prefix. An unselected branch throws if called.
- String success checks text before position; text-fault and position-fault cases check the correct prefix. In the text-fault case both callbacks can throw, so reversed evaluation cannot accidentally pass.
- Array capacity success and failure each check one capacity callback invocation. The raw-source compilation also exposes illegal generator placement before runtime observations can be produced.

The ten additional rows cover partial applications. Seven use a diagnostic host accessor for the function-valued field, together with callbacks: ordinary formation order, unused closure demand, first faults at callee/first argument/second argument/following step, and nested partial formation. Their successful trace is `callee → first → second → after`, with callee and supplied operands observed once even when the closure is later called twice. Three generic/proof-erased rows use callbacks only and require `first → after`, with first-fault checks at each step. Every later phase can also fail, so the earliest demanded error must win.

Each new row explicitly labels `diagnosticDomain` as `host-accessor-and-callbacks` or `host-callbacks-only`. Totals are fourteen callback-only observations and seven accessor/callback observations. Accessors are noncanonical host values, not an admitted mutable source record feature. The pure generated-value comparisons use plain immutable host records with related pure function fields, without accessors; they do not claim reconstruction of the generated structure's private branded carrier.

These callbacks and accessors are diagnostic host values passed through existing interfaces. Their effects and exceptions are outside admitted pure source semantics. No source FFI, mutable source state, or exception feature is installed. These finite probes support the concrete evaluation fixes; they do not establish arbitrary source-effect equivalence.

## Receipt and binder contract

The new runtime field is `sourceEvaluationRegression`, with kind `psc0-source-evaluation-conformance` and these scoped counts:

- Twelve declarations (eleven definitions and one structure), twenty-four pure observations, twenty-one host probes.
- Two raw atomic source compilations and two associated portable IR checks.
- One shared TypeScript 7 compilation.
- Reused native reference, with zero additional native executions per generation.

Each generation retains `source-evaluation/source.lean`, `source.ps`, two standalone atomic source evidence receipts, shared admissions, and `runtime/index.ts` / `runtime/index.js`. The fields follow the existing equality regression shape. Both source receipts must bind the same TypeScript/admissions hashes. The regression separately records `definitionCount: 11` and `structureCount: 1`; actual atomic source-policy evidence records `declarationCount: 12`. Additional diagnostic-domain labels are part of the pinned host observation digest.

The extra native artifacts live below the N1 `strict-runtime-reference/native-source-evaluation/` directory: `fixture.lean`, `reference.lean`, `stdout.log`, `stderr.log`, and `receipt.json`. The standalone receipt excludes its own path/hash metadata. The original parent reference embeds the same envelope plus that metadata. Every runtime regression records the shared standalone receipt hash.

The root-owned evidence binder must read the actual files, verify these identities and hashes, check source/target/IR admission and false qualification flags, and retain the bindings in generation evidence. A self-reported pass alone is insufficient. The binder extension is a dependency of integration, not something this guide declares completed.

| Exported pin | SHA-256 |
|---|---|
| Lean raw source | `aa068f731e363494a42127e33fc8fc292de66de62075593f5c29ffb2af45748e` |
| PS raw source | `2a9ffece8b7dbbec066e0f540c074d6d88b9bf6aecdd6974c70ca1fa119f07f2` |
| New native wrapper | `75486abeb314702a573b84c473e8fc8c4659b29ae8793f0ee7f89539e4c4a131` |
| Twenty-four canonical observations | `9aa5567a82c7789778037e145d35d20f310329632da36c7758c8be45431ecb6f` |
| Twenty-one diagnostic host observations | `76dba00fb02adff5cc8bd76d52f178b95cd6b9886542e8b5cf5e0efc314aae91` |

## Validation and remaining limits

Before a cloud run, independent source review has checked the exact production diffs and the raw fixture design. No local execution, shell, checkout, workflow, or ref update was performed by the preparing agent. This source-only state is not a green qualification.

A successful cloud qualification must bind all four compiler generations to the exact source commit and retain failures honestly. The new targeted fixture supplements the existing gates; it does not remove, relax, or relabel them. The existing 45/186/8/9/5/2 runtime fixture counts and the six-case source equality regression remain unchanged.

General erasure correspondence, proof/binder origin obligations, application grouping and function-result eta relations, arbitrary callbacks, resource behavior, the full runtime representation domain, and the other strict SH/1 obligations remain separate work. Empty regular data and empty elimination need a separate source/type/roundtrip fixture: there is no canonical empty-data inhabitant to add to this executable value oracle. A finite pass here does not permit either strict qualification flag to become true.
