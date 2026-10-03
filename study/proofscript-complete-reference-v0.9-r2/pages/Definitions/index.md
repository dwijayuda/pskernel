<a id="definitions"></a>

# ProofScript — 7. Definitions

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Use def for general declarations, function for an explicitly parameterized definition, and const for a parameterless definition. Keep theorem, example, abbrev and opaque distinct. Expression bodies end through native boundary and suffix rules, not an added semicolon. Dependent binders and named/default arguments preserve native elaboration. Structural and well-founded recursion need the native evidence; partial definitions keep their opaque logical interpretation and separately accounted executable bodies.

## ProofScript way of writing it


```proofscript
function decorate(
  name: String,
  suffix: String := "!"
): String := name ++ suffix

const label: String := decorate("Ada", suffix := "?")

function incrementTwice(n: Nat): Nat :=
  helper(helper(n))
where {
  helper(x: Nat): Nat := x + 1
}
```

**Compiler and coverage boundary.** Preserve declaration kinds, safety/reducibility metadata, native termination suffixes and local capture. An abbreviation is not a fresh nominal type.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Definitions/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Definitions/index.html). Source Git blob: `74d032d82c34ae45be3521e912a0188f74e98ff2`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 7. Definitions

The following commands in Lean are definition-like:

- `def`
- `abbrev`
- `example`
- `theorem`
- `opaque`

All of these commands cause Lean to [elaborate](../Notations-and-Macros/Elaborators/index.md#--tech-term-elaborators) a term based on a [signature](Headers-and-Signatures/index.md#--tech-term-signature). With the exception of `example`, which discards the result, the resulting expression in Lean's core language is saved for future use in the environment. The `instance` command is described in the [section on instance declarations](../Type-Classes/Instance-Declarations/index.md#instance-declarations).

1. [7.1. Modifiers](Modifiers/index.md#declaration-modifiers)
2. [7.2. Headers and Signatures](Headers-and-Signatures/index.md#signature-syntax)
3. [7.3. Definitions](Definitions/index.md#The-Lean-Language-Reference--Definitions--Definitions)
4. [7.4. Theorems](Theorems/index.md#The-Lean-Language-Reference--Definitions--Theorems)
5. [7.5. Example Declarations](Example-Declarations/index.md#The-Lean-Language-Reference--Definitions--Example-Declarations)
6. [7.6. Recursive Definitions](Recursive-Definitions/index.md#recursive-definitions)
