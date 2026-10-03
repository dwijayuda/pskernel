<a id="basic-types"></a>

# ProofScript — 20. Basic Types

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Nat, Int, machine integers, floats, characters, strings, bytes, options, products, sums, lists, arrays, maps, ranges, subtypes and lazy computations retain their distinct native contracts. A target representation is not their meaning. Nat subtraction saturates at zero; the selected Int quotient differs from JavaScript BigInt truncation for some negative inputs. String offsets and Unicode conversions require explicit mappings.

## ProofScript way of writing it


```proofscript
structure User where {
  name: String
  active: Bool
}

function activate(user: User): User :=
  { user with active := true }

function decoratedNames(users: List User): List String :=
  users.map(fun user => user.name ++ "!")
```

**Compiler and coverage boundary.** The full API entries below retain exact names and signature metadata. Distinguish a signature display from executable source. Unknown reachable primitives reject the requested executable profile.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Types/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Types/index.html). Source Git blob: `e571f3422076bf6f0446c89a8ad346a51c47a4ab`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 20. Basic Types

Lean includes a number of built-in types that are specially supported by the compiler. Some, such as `Nat`, additionally have special support in the kernel. Other types don't have special compiler support *per se*, but rely in important ways on the internal representation of types for performance reasons.

1. [20.1. Natural Numbers](Natural-Numbers/index.md#Nat)
2. [20.2. Integers](Integers/index.md#Int)
3. [20.3. Finite Natural Numbers](Finite-Natural-Numbers/index.md#Fin)
4. [20.4. Fixed-Precision Integers](Fixed-Precision-Integers/index.md#fixed-ints)
5. [20.5. Bitvectors](Bitvectors/index.md#BitVec)
6. [20.6. Floating-Point Numbers](Floating-Point-Numbers/index.md#Float)
7. [20.7. Characters](Characters/index.md#Char)
8. [20.8. Strings](Strings/index.md#String)
9. [20.9. The Unit Type](The-Unit-Type/index.md#The-Lean-Language-Reference--Basic-Types--The-Unit-Type)
10. [20.10. The Empty Type](The-Empty-Type/index.md#empty)
11. [20.11. Booleans](Booleans/index.md#The-Lean-Language-Reference--Basic-Types--Booleans)
12. [20.12. Optional Values](Optional-Values/index.md#option)
13. [20.13. Tuples](Tuples/index.md#tuples)
14. [20.14. Sum Types](Sum-Types/index.md#sum-types)
15. [20.15. Linked Lists](Linked-Lists/index.md#List)
16. [20.16. Arrays](Arrays/index.md#Array)
17. [20.17. Byte Arrays](Byte-Arrays/index.md#ByteArray)
18. [20.18. Ranges](Ranges/index.md#ranges)
19. [20.19. Maps and Sets](Maps-and-Sets/index.md#maps)
20. [20.20. Subtypes](Subtypes/index.md#Subtype)
21. [20.21. Lazy Computations](Lazy-Computations/index.md#Thunk)
