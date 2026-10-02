# PSC3 Lean 4 Compatibility Profile

Status: **research draft**

## 1. Compatibility rule

PSC3 treats .lean as a strict compatibility frontend.

> If PSC3 accepts a file as .lean under profile Lean-X, that source must also be valid source for the pinned official Lean-X toolchain.

ProofScript-only syntax is never added to .lean.

PSC3 may support a subset of Lean. Unsupported valid Lean is reported as unsupported rather than reinterpreted.

## 2. Initial stable baseline

Initial PSC3 research baseline:

~~~text
Lean 4.34.1
~~~

Reason:
- it is a stable Lean release at the time of this design work;
- PSC2 already targets the 4.34 semantic family;
- moving to a release candidate would make a language freeze depend on unsettled upstream behavior.

Lean 4.35 release-candidate changes are research inputs only until a stable release is intentionally adopted.

Every future Lean-profile upgrade is versioned.

## 3. What .lean compatibility means

Compatibility is reported as a matrix, not a single level.

Suggested dimensions:

| Dimension | Example |
| --- | --- |
| Lexical/parser | source form accepted |
| Declaration/elaboration | definitions elaborate consistently |
| Core semantics | canonical declarations have intended Lean meaning |
| Tactics/prover | proof script subset supported |
| Meta/macros | extension subset supported |
| Library | selected Lean/Std/library modules supported |
| Artifact/kernel | declaration/proof checking profile |
| Runtime extraction | executable subset has PSC runtime mapping |

A project should be able to state exactly which matrix cells it requires.

## 4. Required Lean-facing language foundation

PSC3's theorem profile should retain the useful Lean-compatible foundation:
- dependent Pi/functions;
- universes;
- structures;
- inductives/indexed families;
- propositions/proof terms;
- equality;
- pattern matching/elimination;
- structural and well-founded recursion;
- typeclasses/instances;
- coercions where supported;
- classical/noncomputable theorem source;
- namespaces/sections;
- ordinary theorem proof syntax;
- selected attributes/notation;
- verification syntax where a pinned Lean profile supports it.

This does not imply full Lean source compatibility.

## 5. Native .ps follows semantic meaning, not Lean grammar

Where .ps and .lean express the same program/theorem, they should lower to equivalent admitted meaning for the claimed overlap.

Example:

~~~lean
def add (x y : Nat) : Nat := x + y
~~~

Native PSC3 may write:

~~~proofscript
function add(x: Nat, y: Nat): Nat {
  x + y
}
~~~

The important compatibility target is the declaration's semantic meaning, not punctuation identity.

## 6. Deliberately separate native choices

PSC3 .ps should not inherit every Lean frontend mechanism.

### Grammar extension

Lean has powerful syntax/macro/elaborator extension facilities.

PSC3 .ps should prefer a controlled, versioned extension API.

Unrestricted parser mutation makes tooling, readability and deterministic interpretation harder.

### Instance search

PSC3 should study Lean behavior but may choose a stricter native policy for:
- deterministic ambiguity;
- bounded search;
- explicit priority;
- scoped imports;
- explanation traces.

The .lean frontend follows the compatible Lean behavior within its claimed profile.

### Coercions

Native .ps should keep coercion insertion bounded and explainable.

Long chains and surprising conversions should fail or require explicit syntax.

### Partial and unsafe computation

PSC3 should preserve the logical distinction between total definitions and runtime-only partial/unsafe behavior.

Native PSC3 may expose a cleaner application-facing spelling, but runtime-only code cannot gain theorem authority.

### Meta programming

PSC3 needs strong Meta/tactic APIs for self-hosting and theorem tooling.

It does not need exact source/API identity with all of Lean.Meta.

## 7. Lean libraries

PSC3 should distinguish three library modes.

### A. Source-compatible Lean subset

The module is valid .lean and accepted by the PSC Lean frontend.

### B. Imported checked declaration bundle

Lean source is elaborated/exported through a pinned toolchain and checked through PSC's selected kernel/profile.

This can support theorem reuse without claiming source parser compatibility.

### C. PSC-native port/wrapper

A library may expose a simpler .ps API while retaining verified relationships to imported Lean definitions where established.

The project must report which mode is used.

## 8. Theorem proof portability

A theorem accepted by Lean and PSC may rely on:
- different tactic implementations;
- different elaboration internals;
- the same or equivalent resulting proof terms.

Tactic implementation identity is not required.

The assurance target is the admitted theorem under the declared assumptions.

## 9. .lean application development

PSC3 should allow complete applications in the supported .lean subset where the required runtime/effect/FFI APIs are available.

This means Lean-compatible application authors should be able to import PSC platform libraries exposed through valid Lean source declarations.

ProofScript-specific host functionality must be represented by valid Lean declarations/externals in the supported profile rather than new .lean syntax.

## 10. Interoperability tests

For every feature claimed in both .lean and .ps:
- construct paired source examples;
- compare admitted declaration meaning;
- compare proof assumptions;
- compare erased/RuntimeIR meaning for executable code;
- check negative cases;
- record the pinned Lean toolchain.

Textual source equality is not required.

## 11. Upgrade policy

A Lean profile upgrade requires:
1. upstream stable release;
2. kernel/profile semantic diff;
3. parser/elaboration compatibility audit;
4. theorem corpus replay;
5. runtime/extraction audit where relevant;
6. documented breaking or acceptance changes.

Do not silently retarget "Lean-compatible" to whatever the newest installed Lean happens to be.

## 12. Non-goals

Initial PSC3 does not promise:
- every Lean macro;
- every syntax category;
- arbitrary environment extensions;
- exact .olean representation;
- all mathlib source;
- Lean compiler/runtime intrinsics;
- unrestricted unsafe/native proof shortcuts.

Those may be supported by explicit profiles later.

## 13. Long-term relationship

Lean should remain:
- a major semantic reference;
- an interoperability ecosystem;
- an independent oracle/checking path where useful;
- a theorem-source ecosystem PSC can increasingly consume.

ProofScript should still have its own native language/product identity.

The relationship is:

~~~text
Lean-compatible source subset ----+
                                  |
                                  v
                         canonical semantics
                                  ^
                                  |
native ProofScript ---------------+
~~~

Compatibility is a bridge, not the definition of PSC3's entire user experience.
