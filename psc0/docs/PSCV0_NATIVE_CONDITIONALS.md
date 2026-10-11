# Native conditionals and decision evidence

Ordinary conditions accept Bool or Prop with a synthesizable Decidable instance.
Named conditions, if (h : condition) { yes } else { no }, bind a proof of the
proposition in the first branch and its negation in the second. Bool conditions
use the native coercion proposition, equality to true. The body is one term;
this does not add monadic do syntax or TypeScript truthiness.

Conditional elaboration is a separate client of shared term elaboration,
instance synthesis, expected types and delayed scope abstraction. It introduces
no new Core expressions. Named proof binders use the same local identity and
hole-closing rules as lambdas. A branch result type cannot leak its proof local.

Lean RC4 changed Decidable to a structure carrying a Bool and a reflection proof.
The selected runtime ABI maps Decidable P to Bool. Imported isTrue/isFalse and
decide signatures, and ite/dite, are checked against the official pinned prelude.
Bool, Nat and String equality decisions are registered through the existing
instance index, so local decision dictionaries and user instances use the same
search machinery. The primitive runtime boundary erases the dictionary to its
Boolean payload and opens dependent branch proof binders before erasing bodies.
It never guesses a decision from the syntax of the proposition.

This replaces the former erasure shortcut that recognized only particular Eq
propositions. Both Rust and TypeScript consume ordinary shared IR conditionals;
neither backend owns proposition semantics. Boolean equality preserves lazy
branch selection and evaluates its operands once along each execution path.

Qualification extends the existing composite with local true/false decisions,
Nat and Unicode String equality, proof-dependent branches and refined holes.
Three refusals protect absent decisions, incorrect negative-branch proof use
and escaping proof names. There is no self-hosting, compiler source translation
or pskernel-core testing.

Direct Decidable record construction/projections/recursors, arbitrary deriving,
general decision procedures and the remaining do conditionals are not claimed.
Upstream reference: Init/Prelude.lean (Bool.Reflects, Decidable, ite, dite,
Bool.decEq, Nat.decEq and String.decEq), pinned to
c29b6dda4f7c20e3eeaa717c4e565663c5cfa364.
