# ProofScript PSC2 Language Profile

Status: **draft extension profile over PSC1**

PSC2 inherits PSC1 unless this document explicitly adds or strengthens a
capability. PSC2 is intended to remain source-compatible with valid PSC1 code.

## 1. Architectural rule

PSC2 does not introduce a second semantic compiler.

```text
.ps / supported .lean
        |
        v
source frontend + syntax extensions
        |
        v
Meta / elaboration / tactics / VC generation
        |
        v
canonical dependent core
        |
        v
kernel admission
        |
        v
CheckedCore
        |
        v
erasure -> target-neutral IR -> TS / Rust / Wasm
```

A PSC2 source feature is preferred when it can lower to PSC1 core semantics.
A new syntax form does not justify a new kernel node.

## 2. Feature classes

PSC2 documentation should classify every addition as one of:

- **L** — library-only capability;
- **S** — source syntax/desugaring;
- **E** — elaborator/Meta capability;
- **T** — tactic/proof-construction capability;
- **P** — controlled plugin capability;
- **V** — verification/specification capability;
- **K** — genuine kernel/semantic extension.

`K` additions require exceptional justification and a separate compatibility,
bootstrap and assurance plan.

## 3. Generalized field/method notation [E]

PSC2 supports static generalized field notation:

```proofscript
xs.map(f)
user.name
builder.append(text)
```

Resolution MUST be deterministic and type-directed. It MUST NOT use JavaScript
prototype lookup or runtime dynamic dispatch unless the program explicitly
crosses an FFI boundary.

Conceptually:

```text
x.f(a)
  -> resolve f for the static type/namespace of x
  -> f(x, a)
```

Ordinary structure projection remains the simplest case.

## 4. Structure updates [S/E]

PSC2 supports immutable copy-with-update:

```proofscript
const next := { state with count := state.count + 1 };
```

Multiple fields MAY be updated in one expression. The feature lowers to
constructor/projection operations and has no independent runtime identity
semantics.

## 5. Named and default arguments [E]

PSC2 supports named arguments when declaration parameter names are stable in the
public source API:

```proofscript
connect(host, timeout := 5000, retries := 3)
```

Default parameter values are elaboration conveniences:

```proofscript
function connect(host: String, timeout: Nat := 5000): Result Error Connection :=
  ...;
```

Defaults do not create a second function type. Canonical lowering supplies the
omitted argument before core admission.

## 6. Rich pattern language [S/E]

PSC2 requires a practical pattern compiler over the existing inductive/match
semantics.

Supported profile SHOULD include:

- nested constructor patterns;
- tuple/product patterns;
- literal patterns where semantically owned;
- alternatives when motives remain unambiguous;
- multi-scrutinee matches;
- let-patterns;
- do-patterns;
- `if let`-style convenience;
- equation-style function definitions.

Example:

```proofscript
function headOr(xs: List Nat, fallback: Nat): Nat :=
  match xs with {
    | .nil => fallback;
    | .cons x _ => x;
  };
```

A richer example may be written without manually nesting matches:

```proofscript
function valueOr(x: Option (Result Error Nat), fallback: Nat): Nat :=
  match x with {
    | .some (.ok n) => n;
    | _ => fallback;
  };
```

The pattern compiler MUST lower into ordinary eliminators/matches and MUST fail
closed when dependent motives are not supported.

## 7. Namespace and scope ergonomics [S/E]

PSC2 requires scalable source organization:

```proofscript
namespace Http {
  ...
}
```

and equivalents of the useful parts of:

- `namespace`;
- `open` / import aliasing;
- local `section` scope;
- shared theorem variables;
- explicit public/private behavior;
- deterministic re-export.

These conveniences may alter name resolution/scoping, but never declaration
meaning after resolution.

## 8. Local and mutual recursion [E]

PSC2 supports practical local recursive helpers and mutual recursion when their
termination/runtime status is accepted by the ordinary recursion rules.

The language still distinguishes:

```text
verified total recursion
partial/runtime-only recursion
```

A runtime-only `partial` implementation does not acquire definitional or proof
authority.

## 9. Well-founded recursion [E/T]

PSC2 Standard supports recursion whose termination is established by a
well-founded relation or explicit measure.

A source form analogous to Lean's `termination_by` is recommended for `.lean`
compatibility and may also be accepted in `.ps` where it remains clear.

The elaborator should generate termination obligations that are proved through
ordinary kernel-checked propositions. Avoid a new trusted recursion oracle.

## 10. Imperative-looking `do` ergonomics [S/L]

PSC2 supports familiar local control flow in an owned effect/sequencing context:

```proofscript
do {
  let mut total := 0;
  for x in xs {
    total := total + x;
  }
  return total;
}
```

PSC2 SHOULD support:

- `let mut`;
- reassignment;
- `for`;
- `while`;
- `break`;
- `continue`;
- typed `try`/recovery over owned effect semantics.

These forms MUST lower to state/effect/iteration/recursion mechanisms. They do
not import JavaScript mutation semantics into the portable language.

## 11. Transparent aliases and opacity [E/K-interface]

PSC2 SHOULD support `abbrev`-like transparent aliases and explicit declaration
opacity/transparency where this can reuse the existing core/kernel declaration
model.

Opacity is semantically important to theorem proving and reduction behavior, so
it must not be implemented as pretty-printer metadata alone.

## 12. Controlled notation [S/P]

PSC2 Standard supports the mathematical notation required to build readable
libraries without requiring Lean's unrestricted syntax ecosystem.

Initial profile:

- prefix notation;
- postfix notation;
- infix/infixl/infixr;
- precedence;
- scoped notation;
- deterministic expansion into owned syntax.

More powerful syntax plugins are a separate controlled plugin capability.

## 13. Standardized attributes/registries [E/P]

PSC2 introduces typed registries for commonly needed compile-time metadata,
such as:

- simplification lemmas/procedures;
- extensionality lemmas;
- instances;
- specification lemmas for VC generation;
- deriving handlers;
- deprecation/documentation metadata.

The architecture SHOULD prefer named/versioned registries over arbitrary hidden
mutable environment extensions.

Metadata may guide proof construction but may never grant proof acceptance.

## 14. Deriving [P]

PSC2 defines a controlled derive API that generates declarations/proofs and
passes them through ordinary elaboration/kernel admission.

Potential standard derives:

- equality/decidable equality where valid;
- ordering where valid;
- representation/debug output;
- serialization schemas where the semantics are fully specified;
- selected proof lemmas.

## 15. Typeclass and coercion maturity [E]

PSC2 strengthens PSC1's bounded machinery into a practical library-scale layer:

- recursive instance search with depth/cycle control;
- priorities;
- imported/scoped/local instances;
- deterministic ambiguity reporting;
- output-parameter behavior where required for Lean compatibility;
- practical coercion insertion/chaining;
- transactional rollback for failed candidates.

This is elaborator functionality, not kernel authority.

## 16. Structured proof terms [E/T]

PSC2 Standard requires:

```text
have
show
suffices
calc
```

These should elaborate to ordinary proof terms.

Example:

```proofscript
theorem addTwo(n: Nat): n + 2 = n + 1 + 1 := by {
  calc
    n + 2 = n + (1 + 1) := by simp
    _ = n + 1 + 1 := by simp
}
```

## 17. Standard tactic layer [T]

PSC2 should provide a stable standard tactic vocabulary including at least:

- existing PSC1 tactics;
- `by_cases`;
- `by_contra`;
- `exfalso`;
- `subst`;
- `generalize`;
- `change`;
- `unfold`;
- `dsimp`;
- structured destructuring equivalent to `rcases`/`rintro`/`obtain`/`use`;
- stronger dependent `cases`/`induction` support.

These tactics remain untrusted proof constructors.

## 18. Simplifier [T/P]

PSC2 Standard requires a mature simplification subsystem:

```text
simp
simpa
simp only
simp at ...
simp? (tooling/suggestion capability)
```

The simplifier may use indexes, procedures and registered rewrite lemmas, but it
must construct a replayable proof term/certificate checked by the kernel.

## 19. Advanced automation [L/T/P]

Arithmetic/algebra/general search automation SHOULD be distributable as
libraries/plugins rather than language semantics. A standard distribution may
include equivalents of:

- `omega`/Presburger reasoning;
- `lia`/linear arithmetic;
- `ring`/ring normalization;
- `norm_num`;
- general proof search (`aesop`/`grind`-class tools);
- SMT integration with proof reconstruction/certificates.

## 20. Contracts [V]

PSC2 Standard Verification adds:

```text
requires
ensures
assert
invariant
decreasing
```

The exact contract model is defined in
[CONTRACTS_AND_VERIFICATION.md](./CONTRACTS_AND_VERIFICATION.md).

The important invariant is:

> contracts generate propositions and proof obligations; they do not add a
> second unchecked verification authority.

## 21. Task/async profile [L/S]

PSC2 Platform should define a backend-neutral asynchronous computation type,
conceptually:

```proofscript
Task A
```

with structured operations such as:

```text
spawn
join
cancel
race
timeout
```

If `async`/`await` syntax is provided, it lowers to Task operations.

The TS backend may map Task to Promise/AbortController/event-loop mechanisms;
Rust may map it to a runtime/future model; Wasm may map it to host/component
capabilities. None of those target choices define PSC semantics.

## 22. Compatibility frontends

PSC2 should continue distinguishing:

```text
.ps     native small/clean ProofScript surface
.lean   Lean-compatible source frontend
```

The `.lean` frontend may support more Lean syntax than `.ps` when doing so is
valuable for migration, provided both lower to the same canonical semantics for
the claimed overlap.

## 23. Kernel impact budget

Expected PSC2 impact:

| Feature family | Kernel change expected? |
| --- | --- |
| method notation / updates / defaults | no |
| richer patterns | no |
| namespace/sections | no |
| loops / let mut | no |
| structured proof syntax | no |
| simp/tactics/automation | no |
| deriving / notation / attributes | no proof authority; normally no |
| contracts / VC generation | normally no; proof obligations use existing Prop/core |
| stronger instance/coercion search | no |
| well-founded recursion UX | preferably no new foundational rule |
| genuinely new type theory | yes, separate proposal required |

PSC2 succeeds if its capability surface grows dramatically while this table
continues to be mostly `no`.

## 24. PSC2 acceptance principle

A feature is ready for PSC2 Standard only when:

1. syntax/meaning is documented;
2. lowering or semantic authority is explicit;
3. unsupported cases fail closed;
4. `.ps` and supported `.lean` agree where both claim the feature;
5. generated core is admitted by the selected kernel profile;
6. executable behavior is target-neutral before backend lowering;
7. TS/Rust/Wasm differential tests cover executable behavior when applicable;
8. the feature has a self-host/bootstrap path;
9. it does not expand the TCB merely for convenience.