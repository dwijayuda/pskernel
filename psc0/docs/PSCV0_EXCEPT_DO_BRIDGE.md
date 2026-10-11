# PSCV0 readable-source bridge — bounded Except do

## Scope and authority

This branch implements the first portable source bridge toward readable authoritative `.ps` compiler source. It does **not** yet replace the installed `psc`, the old qualified compiler, or its source authority. The source-language target is the user's PSCV0 reference, SHA-256 `a419955383fd3e35d873f82c939ecf3a92dc65b162cc9d0d3cadf5b853a0f4b0`, pinned semantically to Lean 4.35.0-rc4 `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.

Implementation branch: `psc0/pscv0-readable-selfhost-v1`.
Base: `b64a95e4537dade93462e0232b5da54d79f9cb25`, from `psc0/npm-modular-packages-v1`.
The original npm branch and all kernel development remain unchanged.

The bridge is ordinary portable `.lean` implementation code compiled by the retained self-hosted PSC0 JavaScript compiler. Its temporary authoring restrictions are bootstrap necessities, not a new end-user language profile. The reference's selected general `do` family is broader than this first supported capability; unimplemented constructs remain explicitly unsupported.

## High-level intent and separate lowering

```text
PSCV0 .ps / selected native .lean
                  |
        tokenized high-level source
                  |
          surface declarations
          retained do item list
          exact original source
             /           \
       pretty views       ordinary semantic lowering
       .ps or .lean       existing matches, lets, Except constructors
                              |
                      existing PSC0 elaborator / IR
                              |
                     independent checking + TS/JS
```

Printing a high-level surface must not reconstruct it heuristically from erased Core or JavaScript. The lowered syntax is a separate product. `psPscv0ReplayOriginal` returns the exact captured input. Until comments have source anchors, canonical printing of commented sources returns `PSCV0-TRIVIA-PRINT-PENDING`; it does not silently delete them.

Native smoke at source `960692ed256f88e24cc03e7c5cd2b15e8ca67362` generated this readable output from braced PSCV0:

```lean
def step (a : Except String Nat) : Except String Nat := do
  let x ← a
  return Nat.succ x
```

The corresponding input is:

```text
function step(a: Except String Nat): Except String Nat := do {
  let x ← a
  return Nat.succ(x)
}
```

Native-source success is not generated-JavaScript conformance; see the separate evidence ledger.

## Selected capability

Identifier: `declaration-except-do/1`, language identity `pscv0`.

Admitted for this slice:
- Whole ordinary definition bodies `:= do { ... }` in PS, or selected native Lean `:= do` layout.
- Explicit result type headed by builtin `Except` with its error/value type arguments.
- Identifier or wildcard bind, `let x ← action` (selected ASCII `<-` token also supported).
- Immutable `let x := value`, and typed immutable lets in supported type syntax.
- Monadic term action; intermediate actions are sequenced/discarded.
- Terminal `return value`, or a final action.
- Existing admitted leaf terms, applications, typed binders, literals, record and match subexpressions.

Not admitted by this slice:
- Arbitrary class-directed monads, implicit effect selection, `pure`/throw class elaboration beyond existing leaf terms.
- Nested do, expression-local do, loops, mutation, early return, try/catch/finally, erased state or contracts.
- Empty-call completion, nullary function lowering, full inferred lambdas, result projections, record updates or nested pattern expansion.
- Arbitrary declarations/registrations outside the implemented source capabilities.
- Source `partial`, new axioms or new kernel constructors.

The selected `Except` name must not be shadowed by the declaration or local binders. This bounded guard prevents accidental reinterpretation of the syntactically identified builtin effect. It is not a general typeclass-resolution implementation.

## Ownership and implementation

| Module | Responsibility |
| --- | --- |
| `Syntax/Pscv0/Surface.lean` | Source representation; selected application validation; paired do printers; hygienic Except lowering |
| `Syntax/Pscv0/Read.lean` | Balanced token/position handling for selected PS and native Lean do sequences |
| `Syntax/Pscv0/Commands.lean` | Definition header ownership, especially the explicit result type before top-level `:=` |
| `Syntax/Pscv0/Module.lean` | Complete source capture, do-to-declaration association, source views and semantic module lowering |

All four belong to the existing `@proofscript/syntax` source package. No package, backend, kernel rule or executable-plugin registration is added. Existing helpers such as `psListMapExcept` are reused.

The old leaf parser's named-assignment lookahead stops before an identifier followed by `:=`. A declaration's result type must own that delimiter, so the bridge captures that bounded type-token slice before calling the same expression parser. This avoids either changing `Except String Nat` examples to hide the issue or accepting a different application grammar in types.

The temporary unlexable do marker is an internal syntax node token only; every marker must correspond to an entire definition body and the count must agree with retained blocks. No string replacement or JavaScript preprocessing determines source meaning.

## Lowering invariants

A bind uses ordinary `Except.error`/`Except.ok` matches. Actions remain left-to-right, the first error is returned without entering its success continuation, and pure lets retain lexical scope and shadowing. Generated error/discard names are selected to be absent from the complete token stream. No caller-supplied success flag or parsed syntax is checking authority.

Semantic lowering success means only that a supported source form has been translated. The result still requires the existing elaborator, type checking, admission and backend pipeline. In particular, wrong return types and mismatched error types are negative compiler fixtures, not parser success claims.

## Budgets and limitations

Source size is bounded at 1 MiB, token count at 65,536, selected do-item count at 512 and do delimiter nesting at 64. Additional recursive term traversal uses fuel. Native continuation indentation is supported only within the selected bounded layout; unsupported forms decline.

These are implementation bounds, not a complete hardened parser/formatter or general semantic preservation proof. A passed round trip establishes only its exact fixture and transformation path. Full comments/docstring anchoring and general precedence-aware rich printing remain work before whole-compiler source authority can move.

## Validation layers

1. Native Lean 4.34 checks the bootstrap implementation source and executes fast source round trips. This is not a PSCV0 upstream conformance claim.
2. The exact retained PSC0 JavaScript compiler parses and compiles only the syntax/foundation bridge closure. It emits the actual bridge used by behavioral tests. There is no native-Lean fallback for this gate.
3. Generated bridge tests compare source views and lowered canonical admissions, malformed input refusal, value/error behavior and fixture admission through the retained JS kernel.
4. Windows consumes the same generated bridge, not a separately handwritten or native-generated substitute.
5. A separate pinned Lean RC4 job checks the actual emitted readable and lowered source functions with a correspondence theorem. It does not upgrade the shipping 4.34 kernel or prove the full bridge algorithm.

No complete compiler C0/C1/C2/C3 cycle, kernel regeneration, npm publication, default CLI change or main merge is performed here. Existing source-specific qualification remains attached to the unchanged old compiler; the new bridge must earn its own limited evidence.
