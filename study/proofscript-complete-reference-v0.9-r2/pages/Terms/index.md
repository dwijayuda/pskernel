<a id="terms"></a>

# ProofScript — 13. Terms

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Terms keep native binding, precedence and type-directed elaboration. D-CALL is adjacency-sensitive: f(x,y) supplies two curried arguments; f((x,y)) and native f (x,y) supply one tuple. An empty call passes Unit. Lambdas use fun, records use :=, and match patterns remain native even when constructor terms use decorated calls. Braces delimit specific categories; they do not disable the native layout checks inside them.

## ProofScript way of writing it


```proofscript
function getOrElse(value: Option Nat, fallback: Nat): Nat :=
  match value with {
    | .none => fallback
    | .some n => n
  }

function bounded(n: Nat): Nat :=
  if (n <= 10) { n } else { 10 }
```

**Compiler and coverage boundary.** Preserve grouping that influences elaboration. Do not flatten nested calls, split patterns on arbitrary bars, or rewrite punctuation inside strings and quotations.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Terms/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Terms/index.html). Source Git blob: `f13ff314f1c387de84c38db29dd56eb9b24e4521`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 13. Terms

<a id="--tech-term-Terms-next"></a>
*Terms* are the principal means of writing mathematics and programs in Lean. The 
<a id="--tech-term-elaborator"></a>
elaborator translates them to Lean's minimal core language, which is then checked by the kernel and compiled for execution. The syntax of terms is [arbitrarily extensible](../Notations-and-Macros/Defining-New-Syntax/index.md#syntax-ext); this chapter documents the term syntax that Lean provides out-of-the-box.

1. [13.1. Identifiers](Identifiers/index.md#identifiers-and-resolution)
2. [13.2. Function Types](Function-Types/index.md#function-types)
3. [13.3. Functions](Functions/index.md#function-terms)
4. [13.4. Function Application](Function-Application/index.md#function-application)
5. [13.5. Numeric Literals](Numeric-Literals/index.md#The-Lean-Language-Reference--Terms--Numeric-Literals)
6. [13.6. Structures and Constructors](Structures-and-Constructors/index.md#The-Lean-Language-Reference--Terms--Structures-and-Constructors)
7. [13.7. Conditionals](Conditionals/index.md#if-then-else)
8. [13.8. Pattern Matching](Pattern-Matching/index.md#pattern-matching)
9. [13.9. Holes](Holes/index.md#The-Lean-Language-Reference--Terms--Holes)
10. [13.10. Type Ascription](Type-Ascription/index.md#The-Lean-Language-Reference--Terms--Type-Ascription)
11. [13.11. Quotation and Antiquotation](Quotation-and-Antiquotation/index.md#The-Lean-Language-Reference--Terms--Quotation-and-Antiquotation)
12. [13.12. `do`-Notation](do--Notation/index.md#The-Lean-Language-Reference--Terms--do--Notation)
13. [13.13. Proofs](Proofs/index.md#The-Lean-Language-Reference--Terms--Proofs)
