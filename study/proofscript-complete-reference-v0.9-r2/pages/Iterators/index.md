<a id="iterators"></a>

# ProofScript — 22. Iterators

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Iterator definitions describe state and stepping; consumers observe a sequence through the permitted interfaces. Combinators such as mapping and filtering transform that process without automatically inheriting termination, productivity, effect or allocation guarantees. Preserve the distinction between finite consumers and potentially unbounded iteration. Iterator proofs belong to the native abstraction and its law dependencies.

**Compiler and coverage boundary.** Version the iterator library and its instances. A foreign async stream additionally needs backpressure, cancellation and lifetime contracts; it is not an ordinary iterator by spelling alone.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Iterators/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Iterators/index.html). Source Git blob: `554e539971750a09513dfddcf1bd789a3f2cdd23`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 22. Iterators

An 
<a id="--tech-term-iterator"></a>
*iterator* provides sequential access to each element of some source of data. Typical iterators allow the elements in a collection, such as a list, array, or `TreeMap` to be accessed one by one, but they can also provide access to data by carrying out some [monadic](../Functors___-Monads-and--do--Notation/index.md#--tech-term-Monad) effect, such as reading files. Iterators provide a common interface to all of these operations. Code that is written to the iterator API can be agnostic as to the source of the data.

Each iterator maintains an internal state that enables it to determine the next value. Because Lean is a pure functional language, consuming an iterator does not invalidate it, but instead copies it with an updated state. As usual, [reference counting](../Run-Time-Code/Reference-Counting/index.md#--tech-term-reference-counting) is used to optimize programs that use values only once into programs that destructively modify values.

To use iterators, import `Std.Data.Iterators`.

<a id="Mixing-Collections"></a>
Mixing Collections 

Combining a list and an array using `List.zip` or `Array.zip` would ordinarily require converting one of them into the other collection. Using iterators, they can be processed without conversion:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="colors-_LPAR_in-Mixing-Collections_RPAR_"></a>
<a id="codes-_LPAR_in-Mixing-Collections_RPAR_"></a>


```proofscript
const colors : Array String := #["purple", "gray", "blue"]
const codes : List String := ["aa27d1", "a0a0a0", "0000c5"]

#eval colors.iter.zip codes.iter |>.toArray
```

```lean
#[("purple", "aa27d1"), ("gray", "a0a0a0"), ("blue", "0000c5")]
```

<a id="Avoiding-Intermediate-Structures"></a>
Avoiding Intermediate Structures  

In this example, an array of colors and a list of color codes are combined. The program separates three intermediate stages:

1. The names and codes are combined into pairs.
2. The pairs are transformed into readable strings.
3. The strings are combined with newlines.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="colors-_LPAR_in-Avoiding-Intermediate-Structures_RPAR_"></a>
<a id="codes-_LPAR_in-Avoiding-Intermediate-Structures_RPAR_"></a>
<a id="go-_LPAR_in-Avoiding-Intermediate-Structures_RPAR_"></a>


```proofscript
const colors : Array String := #["purple", "gray", "blue"]

const codes : List String := ["aa27d1", "a0a0a0", "0000c5"]

const go : IO Unit := do
  let colorCodes := colors.iter.zip codes.iter
  let colorCodes := colorCodes.map fun (name, code) =>
    s!"{name} ↦ #{code}"
  let colorCodes := colorCodes.fold (init := "") fun x y =>
    if x.isEmpty then y else x ++ "\n" ++ y
  IO.println colorCodes

#eval go
```

```lean
purple ↦ #aa27d1
gray ↦ #a0a0a0
blue ↦ #0000c5
```

The intermediate stages of the computation do not allocate new data structures. Instead, all the steps of the transformation are fused into a single loop, with `Iter.fold` carrying out one step at a time. In each step, a single color and color code are combined into a pair, rewritten to a string, and added to the result string.

The Lean standard library provides three kinds of iterator operations. 
<a id="--tech-term-Producers"></a>
*Producers* create a new iterator from some source of data. They determine which data is to be returned by an iterator, and how this data is to be computed, but they are not in control of *when* the computations occur. 
<a id="--tech-term-Consumers"></a>
*Consumers* use the data in an iterator for some purpose. Consumers request the iterator's data, and the iterator computes only enough data to satisfy a consumer's requests. 
<a id="--tech-term-Combinators"></a>
*Combinators* are both consumers and producers: they create new iterators from existing iterators. Examples include `Iter.map` and `Iter.filter`. The resulting iterators produce data by consuming their underlying iterators, and do not actually iterate over the underlying collection until they themselves are consumed.

Each built-in collection for which it makes sense to do so can be iterated over. In other words, the collection libraries include iterator [producers](index.md#--tech-term-Producers). By convention, a collection type `Coll` provides a function `Coll.iter` that returns an iterator over the elements of a collection. Examples include `List.iter`, `Array.iter`, and `TreeMap.iter`. Additionally, other built-in types such as ranges support iteration using the same convention.

1. [22.1. Run-Time Considerations](Run-Time-Considerations/index.md#The-Lean-Language-Reference--Iterators--Run-Time-Considerations)
2. [22.2. Iterator Definitions](Iterator-Definitions/index.md#The-Lean-Language-Reference--Iterators--Iterator-Definitions)
3. [22.3. Consuming Iterators](Consuming-Iterators/index.md#The-Lean-Language-Reference--Iterators--Consuming-Iterators)
4. [22.4. Iterator Combinators](Iterator-Combinators/index.md#The-Lean-Language-Reference--Iterators--Iterator-Combinators)
5. [22.5. Reasoning About Iterators](Reasoning-About-Iterators/index.md#The-Lean-Language-Reference--Iterators--Reasoning-About-Iterators)

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
#[("purple", "aa27d1"), ("gray", "a0a0a0"), ("blue", "0000c5")]
```


### Display 2


```text
purple ↦ #aa27d1
gray ↦ #a0a0a0
blue ↦ #0000c5
```

