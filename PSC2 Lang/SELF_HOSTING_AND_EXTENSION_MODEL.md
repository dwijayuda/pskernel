# PSC2 Self-Hosting and Extension Model

Status: **draft bootstrap architecture**

PSC2 must grow beyond PSC1 without creating a circular bootstrap dependency and
without requiring the small PSC1 kernel/compiler to be rewritten for every new
surface feature.

## 1. Core observation

A compiler does not need to use a feature in order to implement that feature.

A compiler written entirely in PSC1 can implement:

```text
method notation
structure updates
rich patterns
for/while/let mut
calc/have/suffices
simp
deriving
contracts/VC generation
async syntax
```

because those features can be recognized and lowered using functions,
structures, inductives, recursion, effects and dependent terms already available
in PSC1.

## 2. Preferred bootstrap rule

> A PSC2 feature SHOULD be implemented in the previous stable bootstrap profile
> whenever practical.

For PSC2, the preferred implementation profile is PSC1.

```text
Compiler2 source uses PSC1
        |
        | compiled by PSC1
        v
Compiler2 understands PSC2
```

This is the cleanest form of language bootstrapping.

## 3. Lean as an external bootstrap anchor

Official Lean remains valuable even when the current ProofScript compiler has
not yet caught up with the next planned source subset.

A future compiler may be authored as a deliberately constrained Lean program:

```text
Compiler2.lean
  ∈ documented PSC2-compatible Lean subset
```

and built by official Lean first:

```text
official Lean
     |
     v
Compiler2 executable
     |
     v
understands/generates PSC2
```

This permits PSC2 implementation work to begin before every PSC1 self-host gate
is closed, provided it does not destabilize the PSC1 critical path.

## 4. Development vs self-hosting claims

These are different milestones.

### Lean-bootstrapped PSC2

```text
Lean -> Compiler2.lean -> working PSC2 compiler
```

This proves the next compiler can be implemented and executed.

It is **not yet** the PSC2 self-host claim.

### PSC2 self-host

The compiler must become ordinary ProofScript source and compile itself:

```text
Compiler2.ps --Compiler2--> Compiler3
Compiler2.ps --Compiler3--> Compiler4
```

with stable checked-core/IR semantics and an appropriate fixed-point criterion.

## 5. Source transition

Recommended sequence:

```text
1. author Compiler2.lean under a documented portable subset
2. official Lean checks/builds it
3. Compiler2 produces canonical Compiler2.ps
4. compare .lean and .ps CheckedCore/IR fingerprints
5. make Compiler2.ps authoritative after parity closes
6. compile Compiler2.ps with Compiler2
7. compile it again with the generated compiler
8. require fixed-point semantic agreement
```

Do not hand-maintain divergent `.lean` and `.ps` compiler implementations.

## 6. Bootstrap profiles

Treat the implementation subset as an explicit profile rather than as an
informal promise.

Example:

```text
Bootstrap.PSC1
  functions
  structures/inductives
  basic match
  dependent Pi/Prop
  structural recursion
  concrete effects
  modules/names
  basic Meta/Elab

Bootstrap.PSC2
  Bootstrap.PSC1
  + richer patterns
  + namespace ergonomics
  + method notation
  + practical local/mutual recursion
  + structured proof terms
```

A compiler generation records both:

```text
implementationProfile
acceptedLanguageProfile
```

Example:

```text
feature: rich patterns
implementationProfile: PSC1
acceptedLanguageProfile: PSC2
```

This prevents accidental circularity.

## 7. Feature implementation classes

### 7.1 Library-only

Examples:

- new collections;
- parser combinators;
- Task combinators;
- math libraries;
- theorem libraries.

Bootstrap:

```text
newLibrary.ps --PSC1/PSC2--> ordinary artifact
```

No compiler/kernel change.

### 7.2 Source/desugaring

Examples:

- method notation;
- structure update;
- named/default arguments;
- `for`/`while`/`let mut`;
- equation-style definitions;
- `async`/`await` syntax.

Implementation:

```text
new source AST
    -> PSC-written lowering
    -> existing core constructs
```

No kernel change.

### 7.3 Meta/tactic

Examples:

- `calc`;
- `have`/`suffices` helpers;
- mature `simp`;
- `rcases`;
- `by_cases`;
- arithmetic tactics;
- contract VC generation.

Implementation:

```text
goal/program
  -> PSC-written Meta/tactic/VC engine
  -> candidate proof terms
  -> existing kernel
```

No proof authority added.

### 7.4 Controlled plugins

Examples:

- syntax expanders;
- deriving handlers;
- tactics;
- verification extensions;
- backend plugins;
- tooling integrations.

Plugin APIs SHOULD themselves be describable/implementable in ProofScript.

Example conceptual interfaces:

```proofscript
structure TacticPlugin where {
  name: Name;
  run: Goal -> MetaM GoalState;
}

structure DerivePlugin where {
  name: Name;
  derive: Declaration -> MetaM (List Declaration);
}
```

A plugin produces ordinary syntax/declarations/proofs/IR. It cannot override
kernel acceptance.

### 7.5 Genuine semantic/kernel extension

This is exceptional.

Examples could include a genuinely new foundational type-theory rule or a new
trusted primitive computation rule.

Such a change requires:

- versioned new core/profile;
- compatibility story;
- bootstrap story;
- independent checker/differential evidence;
- formal reasoning where practical;
- explicit TCB impact.

Do not use kernel extensions to implement convenience syntax.

## 8. Example: method notation

Compiler implementation, written in PSC1:

```text
parse MethodCall(receiver, name, args)
  -> inspect static receiver type
  -> deterministic declaration lookup
  -> emit ordinary application
```

Then:

```proofscript
xs.map(f)
```

lowers to an ordinary function application.

After Compiler2 exists, its own source may be refactored to use method notation,
but that is dogfooding, not a bootstrap prerequisite.

## 9. Example: rich patterns

PSC1-written pattern compiler:

```text
rich pattern tree
   -> decision tree / nested basic matches
   -> ordinary core eliminators
```

Compiler2 can therefore accept patterns more convenient than those used to
implement Compiler2.

## 10. Example: `for` and `let mut`

PSC1 already has enough functional/effect machinery to define a translation:

```text
let mut x := init
for a in xs { body }
```

into state-threading/iteration/recursion.

The compiler implementation itself can use explicit recursion until the new
syntax is available.

## 11. Example: `simp`

A large simplifier can be entirely self-hosted:

```text
simp library written in PSC1/PSC2
   -> indexes registered lemmas
   -> rewrites target/hypotheses
   -> constructs equality/congruence proof
   -> kernel checks proof
```

The simplifier may become much larger than the kernel without expanding the TCB.

## 12. Example: contracts

A PSC1-written VC generator can implement PSC2 contracts:

```text
requires/ensures/invariant AST
   -> specification model
   -> verification conditions : Prop
   -> tactic/manual proofs
   -> kernel
```

The compiler implementing the VC generator does not need `requires`/`ensures`
on its own functions.

Later generations may dogfood the contract syntax on the compiler itself.

## 13. Parallel development rule

PSC2 research/implementation MAY proceed before PSC1 is completely self-hosted,
provided:

1. PSC1 release/self-host gates remain authoritative;
2. PSC2 work lives on separate branches/packages/docs until integration;
3. PSC1 semantics are not broadened merely to make PSC2 development easier;
4. the future implementation subset is documented;
5. official Lean is used as bootstrap host where current PSC cannot yet compile
   the next subset;
6. no PSC2 completion claim is made until its own fixed-point gates close.

This allows progress without scope drift.

## 14. Kernel strategy

PSC2 should target the same stable canonical kernel contract whenever possible.

Long-term checking may support interchangeable providers:

```text
canonical core
    |
    +-> PSC small kernel
    +-> Lean-compat kernel
    +-> dual checker
```

Multiple validators are acceptable; multiple incompatible semantic languages
are not.

PSC2 syntax/tactics/contracts should normally produce core accepted by the small
kernel profile. Lean-specific artifacts that cannot be faithfully canonicalized
may explicitly require the compatibility profile.

## 15. Backends remain downstream

PSC2 growth must not create separate semantics for TS/Rust/Wasm.

```text
PSC2 source
  -> same CheckedCore
  -> same erasure
  -> same target-neutral IR
     /      |      \
   TS      Rust    Wasm
```

A syntax/plugin feature is incomplete if it works only by bypassing the shared
IR for one target.

## 16. Long-term self-host target

The desirable endpoint is:

```text
ProofScript bootstrap/core compiler written in small PSC subset
ProofScript Meta/tactic/plugin libraries written in ProofScript
ProofScript TS/Rust/Wasm backends written in ProofScript-compatible source
ProofScript small kernel written in a small auditable subset
Lean-compatible checker retained independently as oracle/compatibility path
```

The ecosystem can grow dramatically while the bootstrap/compiler/kernel
foundation remains understandable.

## 17. Anti-circularity acceptance gate

For every PSC2 feature, document:

```text
featureName
implementationProfile
acceptedProfile
loweringTarget
kernelRequirements
backendRequirements
```

A feature cannot be a mandatory dependency of the compiler generation that is
supposed to create the first implementation of that feature unless an explicit
external bootstrap host (such as official Lean) is recorded.

That one rule keeps PSC2 self-hosting honest.