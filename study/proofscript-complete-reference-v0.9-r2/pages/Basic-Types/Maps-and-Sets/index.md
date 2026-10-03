<a id="maps"></a>

# ProofScript — 20.19. Maps and Sets

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Nat, Int, machine integers, floats, characters, strings, bytes, options, products, sums, lists, arrays, maps, ranges, subtypes and lazy computations retain their distinct native contracts. A target representation is not their meaning. Nat subtraction saturates at zero; the selected Int quotient differs from JavaScript BigInt truncation for some negative inputs. String offsets and Unicode conversions require explicit mappings.

**Compiler and coverage boundary.** The full API entries below retain exact names and signature metadata. Distinguish a signature display from executable source. Unknown reachable primitives reject the requested executable profile.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Types/Maps-and-Sets/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Types/Maps-and-Sets/index.html). Source Git blob: `5576275e5a80873480e546aae8a06b284cef7972`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 20.19. Maps and Sets

A 
<a id="--tech-term-map"></a>
*map* is a data structure that associates keys with values. They are also referred to as 
<a id="--tech-term-dictionaries"></a>
*dictionaries*, 
<a id="--tech-term-associative-arrays"></a>
*associative arrays*, or simply as hash tables.

In Lean, maps may have the following properties:

  Representation

The in-memory representation of a map may be either a tree or a hash table. Tree-based representations are better when the [reference](../../Run-Time-Code/Reference-Counting/index.md#reference-counting) to the data structure is shared, because hash tables are based on [arrays](../Arrays/index.md#Array). Arrays are copied in full on modification when the reference is not unique, while only the path from the root of the tree to the modified nodes must be copied on modification of a tree. Hash tables, on the other hand, can be more efficient when references are not shared, because non-shared arrays can be modified in constant time. Furthermore, tree-based maps store data in order and thus support ordered traversals of the data.

  Extensionality

Maps can be viewed as partial functions from keys to values. 
<a id="--tech-term-Extensional-maps"></a>
*Extensional maps*
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
 are maps for which propositional equality matches this interpretation. This can be convenient for reasoning, but it also rules out some useful operations that would be able to distinguish between them. In general, extensional maps should be used only when needed for verification.

  Dependent or Not

A 
<a id="--tech-term-dependent-map"></a>
*dependent map*
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
 is one in which the type of each value is determined by its corresponding key, rather than being constant. Dependent maps have more expressive power, but are also more difficult to use. They impose more requirements on their users. For example, many operations on `DHashMap` require `LawfulBEq` instances rather than `BEq`.

| Map | Representation | Extensional? | Dependent? |
| --- | --- | --- | --- |
| `TreeMap` | Tree | No | No |
| `DTreeMap` | Tree | No | Yes |
| `HashMap` | Hash Table | No | No |
| `DHashMap` | Hash Table | No | Yes |
| `ExtHashMap` | Hash Table | Yes | No |
| `ExtDHashMap` | Hash Table | Yes | Yes |

A map can always be used as a set by setting its type of values to `Unit`. The following set types are provided:

- `Std.HashSet` is a set based on hash tables. Its performance characteristics are like those of `Std.HashMap`: it is based on arrays and can be efficiently updated, but only when not shared.
- `Std.TreeSet` is a set based on balanced trees. Its performance characteristics are like those of `Std.TreeMap`.
- `Std.ExtHashSet` is an extensional hash set type that matches the mathematical notion of finite sets: two sets are equal if they contain the same elements.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Library-Design"></a>
### 20.19.1. Library Design

All the basic operations on maps and sets are fully verified. They are proven correct with respect to simpler models implemented with lists. At the same time, maps and sets have predictable performance.

Some types include additional operations that are not yet fully verified. These operations are useful, and not all programs need full verification. Examples include `HashMap.partition` and `TreeMap.filterMap`.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Library-Design--Fused-Operations"></a>
#### 20.19.1.1. Fused Operations

It is common to modify a table based on its pre-existing contents. To avoid having to traverse a data structure twice, many query/modification pairs are provided in “fused” variants that perform a query while modifying a map or set. In some cases, the result of the query affects the modification.

For example, `Std.HashMap` provides `containsThenInsert`, which inserts a key-value pair into a map while signalling whether it was previously found, and `containsThenInsertIfNew`, which inserts the new mapping only if it was not previously present. The `alter` function modifies the value for a given key without having to search for the key multiple times; the alternation is performed by a function in which missing values are represented by `none`.

<a id="raw-data"></a>
#### 20.19.1.2. Raw Data and Invariants

Both hash-based and tree-based maps rely on certain internal well-formedness invariants, such as that trees are balanced and ordered. In Lean's standard library, these data structures are represented as a pair of the underlying data with a proof that it is well formed. This fact is mostly an internal implementation detail; however, it is relevant to users in one situation: this representation prevents them from being used in [nested inductive types](../../The-Type-System/Inductive-Types/index.md#--tech-term-Nested-inductive-types).

To enable their use in nested inductive types, the standard library provides “
<a id="--tech-term-raw"></a>
raw” variants of each container along with separate “unbundled” versions of their invariants. These use the following naming convention:

- `T.Raw` is the version of type `T` without its invariants. For example, `Std.HashMap.Raw` is a version of `Std.HashMap` without the embedded proofs.
- `T.Raw.WF` is the corresponding well-formedness predicate. For example, `Std.HashMap.Raw.WF` asserts that a `Std.HashMap.Raw` is well-formed.
- Each operation on `T`, called `T.f`, has a corresponding operation on `T.Raw` called `T.Raw.f`. For example, `Std.HashMap.Raw.insert` is the version of `Std.HashMap.insert` to be used with raw hash maps.
- Each operation `T.Raw.f` has an associated well-formedness lemma `T.Raw.WF.f`. For example, `Std.HashMap.Raw.WF.insert` asserts that inserting a new key-value pair into a well-formed raw hash map results in a well-formed raw hash map.

Because the vast majority of use cases do not require them, not all lemmas about raw types are imported by default with the data structures. It is usually necessary to import `Std.Data.T.RawLemmas` (where `T` is the data structure in question).

A nested inductive type that occurs inside a map or set should be defined in three stages:

1. First, define a raw version of the nested inductive type that uses the raw version of the map or set type. Define any necessary operations.
2. Next, define an inductive predicate that asserts that all maps or sets in the raw nested type are well formed. Show that the operations on the raw type preserve well-formedness.
3. Construct an appropriate interface to the nested inductive type by defining an API that proves well-formedness properties as needed, hiding them from users.

<a id="Nested-Inductive-Types-with--Std___HashMap"></a>
Nested Inductive Types with `Std.HashMap` 

This example requires that `Std.Data.HashMap.RawLemmas` is imported. To keep the code shorter, the `Std` namespace is opened:

```proofscript
open Std
```

The map of an adventure game may consist of a series of rooms, connected by passages. Each room has a description, and each passage faces in a particular direction. This can be represented as a recursive structure.

```proofscript
structure Maze where
  description : String
  passages : HashMap String Maze
```

This definition is rejected:

```lean
(kernel) application type mismatch
  DHashMap.Raw.WF inner
argument has type
  _nested.Std.DHashMap.Raw_3
but function has type
  (DHashMap.Raw String fun x => Maze) → Prop
```

Making this work requires separating the well-formedness predicates from the structure. The first step is to redefine the type without embedded hash map invariants:
<a id="RawMaze-_LPAR_in-Nested-Inductive-Types-with--Std___HashMap_RPAR_"></a>
<a id="RawMaze___description-_LPAR_in-Nested-Inductive-Types-with--Std___HashMap_RPAR_"></a>
<a id="RawMaze___passages-_LPAR_in-Nested-Inductive-Types-with--Std___HashMap_RPAR_"></a>


```proofscript
structure RawMaze where
  description : String
  passages : Std.HashMap.Raw String RawMaze
```

The most basic raw maze has no passages:
<a id="RawMaze___base-_LPAR_in-Nested-Inductive-Types-with--Std___HashMap_RPAR_"></a>


```proofscript
def RawMaze.base (description : String) : RawMaze where
  description := description
  passages := ∅
```

A passage to a further maze can be added to a raw maze using `RawMaze.insert`:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="RawMaze___insert-_LPAR_in-Nested-Inductive-Types-with--Std___HashMap_RPAR_"></a>


```proofscript
function RawMaze.insert (maze : RawMaze)
    (direction : String) (next : RawMaze) : RawMaze :=
  { maze with
    passages := maze.passages.insert direction next
  }
```

The second step is to define a well-formedness predicate for `RawMaze` that ensures that each included hash map is well-formed. If the `passages` field itself is well-formed, and all raw mazes included in it are well-formed, then a raw maze is well-formed.
<a id="RawMaze___WF-_LPAR_in-Nested-Inductive-Types-with--Std___HashMap_RPAR_"></a>
<a id="RawMaze___WF___mk-_LPAR_in-Nested-Inductive-Types-with--Std___HashMap_RPAR_"></a>


```proofscript
inductive RawMaze.WF : RawMaze → Prop
  | mk {description passages} :
    (∀ (dir : String) v, passages[dir]? = some v → WF v) →
    passages.WF →
    WF { description, passages := passages }
```

Base mazes are well-formed, and inserting a passage to a well-formed maze into some other well-formed maze produces a well-formed maze:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="RawMaze___base_wf-_LPAR_in-Nested-Inductive-Types-with--Std___HashMap_RPAR_"></a>
<a id="RawMaze___insert_wf-_LPAR_in-Nested-Inductive-Types-with--Std___HashMap_RPAR_"></a>


```proofscript
theorem RawMaze.base_wf (description : String) :
    RawMaze.WF (.base description) := by
  constructor
  . intro v h h'
    simp [Std.HashMap.Raw.getElem?_empty] at *
  . exact HashMap.Raw.WF.empty

function RawMaze.insert_wf (maze : RawMaze) :
    WF maze → WF next → WF (maze.insert dir next) := by
  let ⟨desc, passages⟩ := maze
  intro ⟨wfMore, wfPassages⟩ wfNext
  constructor
  . intro dir' v
    rw [HashMap.Raw.getElem?_insert wfPassages]
    split <;> intros <;> simp_all [wfMore dir']
  . simp_all [HashMap.Raw.WF.insert]
```

Finally, a more friendly interface can be defined that frees users from worrying about well-formedness. A `Maze` bundles up a `RawMaze` with a proof that it is well-formed:
<a id="Maze___raw-_LPAR_in-Nested-Inductive-Types-with--Std___HashMap_RPAR_"></a>
<a id="Maze___wf-_LPAR_in-Nested-Inductive-Types-with--Std___HashMap_RPAR_"></a>


```proofscript
structure Maze where
  raw : RawMaze
  wf : raw.WF
```

The `base` and `insert` operators take care of the well-formedness proof obligations:
<a id="Maze___base-_LPAR_in-Nested-Inductive-Types-with--Std___HashMap_RPAR_"></a>
<a id="Maze___insert-_LPAR_in-Nested-Inductive-Types-with--Std___HashMap_RPAR_"></a>


```proofscript
def Maze.base (description : String) : Maze where
  raw := .base description
  wf := by apply RawMaze.base_wf

def Maze.insert (maze : Maze)
    (dir : String) (next : Maze) : Maze where
  raw := maze.raw.insert dir next.raw
  wf := RawMaze.insert_wf maze.raw maze.wf next.wf
```

Users of the `Maze` API may either check the description of the current maze or attempt to go in a direction to a new maze:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Maze___description-_LPAR_in-Nested-Inductive-Types-with--Std___HashMap_RPAR_"></a>
<a id="Maze___go___-_LPAR_in-Nested-Inductive-Types-with--Std___HashMap_RPAR_"></a>


```proofscript
function Maze.description (maze : Maze) : String :=
  maze.raw.description

def Maze.go? (maze : Maze) (dir : String) : Option Maze :=
  match h : maze.raw.passages[dir]? with
  | none => none
  | some m' =>
    Maze.mk m' <| by
      let ⟨r, wf⟩ := maze
      let ⟨wfAll, _⟩ := wf
      apply wfAll dir
      apply h
```

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Library-Design--Suitable-Operators-for-Uniqueness"></a>
#### 20.19.1.3. Suitable Operators for Uniqueness

Care should be taken when working with data structures to ensure that as many references are unique as possible, which enables Lean to use destructive mutation behind the scenes while maintaining a pure functional interface. The map and set library provides operators that can be used to maintain uniqueness of references. In particular, when possible, operations such as `alter` or `modify` should be preferred over explicitly retrieving a value, modifying it, and reinserting it. These operations avoid creating a second reference to the value during modification.

<a id="Modifying-Values-in-Maps"></a>
Modifying Values in Maps 

```proofscript
open Std
```

The function `addAlias` is used to track aliases of a string in some data set. One way to add an alias is to first look up the existing aliases, defaulting to the empty array, then insert the new alias, and finally save the resulting array in the map:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="addAlias-_LPAR_in-Modifying-Values-in-Maps_RPAR_"></a>


```proofscript
function addAlias (aliases : HashMap String (Array String))
    (key value : String) :
    HashMap String (Array String) :=
  let prior := aliases.getD key #[]
  aliases.insert key (prior.push value)
```

This implementation has poor performance characteristics. Because the map retains a reference to the prior values, the array must be copied rather than mutated. A better implementation explicitly erases the prior value from the map before modifying it:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="addAlias___-_LPAR_in-Modifying-Values-in-Maps_RPAR_"></a>


```proofscript
function addAlias' (aliases : HashMap String (Array String))
    (key value : String) :
    HashMap String (Array String) :=
  let prior := aliases.getD key #[]
  let aliases := aliases.erase key
  aliases.insert key (prior.push value)
```

Using `HashMap.alter` is even better. It removes the need to explicitly delete and re-insert the value:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="addAlias______-_LPAR_in-Modifying-Values-in-Maps_RPAR_"></a>


```proofscript
function addAlias'' (aliases : HashMap String (Array String))
    (key value : String) :
    HashMap String (Array String) :=
  aliases.alter key fun prior? =>
    some ((prior?.getD #[]).push value)
```

<a id="HashMap"></a>
### 20.19.2. Hash Maps

The declarations in this section should be imported using `import Std.HashMap`.

<a id="Std___HashMap"></a>

**structure**

```text
Std.HashMap.{u, v} (α : Type u) (β : Type v) [BEq α] [Hashable α] :
  Type (max u v)
```

Hash maps.

This is a simple separate-chaining hash table. The data of the hash map consists of a cached size and an array of buckets, where each bucket is a linked list of key-value pairs. The number of buckets is always a power of two. The hash map doubles its size upon inserting an element such that the number of elements is more than 75% of the number of buckets.

The hash table is backed by an `Array`. Users should make sure that the hash map is used linearly to avoid expensive copies.

The hash map uses `==` (provided by the `BEq` typeclass) to compare keys and `hash` (provided by the `Hashable` typeclass) to hash them. To ensure that the operations behave as expected, `==` should be an equivalence relation and `a == b` should imply `hash a = hash b` (see also the `EquivBEq` and `LawfulHashable` typeclasses). Both of these conditions are automatic if the BEq instance is lawful, i.e., if `a == b` implies `a = b`.

These hash maps contain a bundled well-formedness invariant, which means that they cannot be used in nested inductive types. For these use cases, `Std.Data.HashMap.Raw` and `Std.Data.HashMap.Raw.WF` unbundle the invariant from the hash map. When in doubt, prefer `HashMap` over `HashMap.Raw`.

Dependent hash maps, in which keys may occur in their values' types, are available as `Std.Data.DHashMap`.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Hash-Maps--Creation"></a>
#### 20.19.2.1. Creation

<a id="Std___HashMap___emptyWithCapacity"></a>

**def**

```text
Std.HashMap.emptyWithCapacity.{u, v} {α : Type u} {β : Type v} [BEq α]
  [Hashable α] (capacity : Nat := 8) : Std.HashMap α β
```

Creates a new empty hash map. The optional parameter `capacity` can be supplied to presize the map so that it can hold the given number of mappings without reallocating. It is also possible to use the empty collection notations `∅` and `{}` to create an empty hash map with the default capacity.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Hash-Maps--Properties"></a>
#### 20.19.2.2. Properties

<a id="Std___HashMap___size"></a>

**def**

```text
Std.HashMap.size.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.HashMap α β) : Nat
```

The number of mappings present in the hash map

<a id="Std___HashMap___isEmpty"></a>

**def**

```text
Std.HashMap.isEmpty.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.HashMap α β) : Bool
```

Returns `true` if the hash map contains no mappings.

Note that if your `BEq` instance is not reflexive or your `Hashable` instance is not lawful, then it is possible that this function returns `false` even though is not possible to get anything out of the hash map.

<a id="Std___HashMap___Equiv___mk"></a>

**structure**

```text
Std.HashMap.Equiv.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m₁ m₂ : Std.HashMap α β) : Prop
```

Two hash maps are equivalent in the sense of `Equiv` iff all the keys and values are equal.

**Constructor**

```text
Std.HashMap.Equiv.mk.{u, v}
```

**Fields**

```text
inner : m₁.inner.Equiv m₂.inner
```

Internal implementation detail of the hash map

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Equivalence**

The relation `HashMap.Equiv` can also be written with an infix operator, which is scoped to its namespace:

<a id="Std___HashMap____FLQQ_term____m__FLQQ_"></a>

```ebnf
term ::= ...
    | term ~m term
```

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Hash-Maps--Queries"></a>
#### 20.19.2.3. Queries

<a id="Std___HashMap___contains"></a>

**def**

```text
Std.HashMap.contains.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) : Bool
```

Returns `true` if there is a mapping for the given key. There is also a `Prop`-valued version of this: `a ∈ m` is equivalent to `m.contains a = true`.

Observe that this is different behavior than for lists: for lists, `∈` uses `=` and `contains` uses `==` for comparisons, while for hash maps, both use `==`.

<a id="Std___HashMap___get"></a>

**def**

```text
Std.HashMap.get.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) (h : a ∈ m) : β
```

The notation `m[a]` or `m[a]'h` is preferred over calling this function directly.

Retrieves the mapping for the given key. Ensures that such a mapping exists by requiring a proof of `a ∈ m`.

<a id="Std___HashMap___get___"></a>

**def**

```text
Std.HashMap.get!.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [Inhabited β] (m : Std.HashMap α β) (a : α) : β
```

The notation `m[a]!` is preferred over calling this function directly.

Tries to retrieve the mapping for the given key, panicking if no such mapping is present.

<a id="Std___HashMap___get___-next"></a>

**def**

```text
Std.HashMap.get?.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) : Option β
```

The notation `m[a]?` is preferred over calling this function directly.

Tries to retrieve the mapping for the given key, returning `none` if no such mapping is present.

<a id="Std___HashMap___getD"></a>

**def**

```text
Std.HashMap.getD.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) (fallback : β) : β
```

Tries to retrieve the mapping for the given key, returning `fallback` if no such mapping is present.

<a id="Std___HashMap___getKey"></a>

**def**

```text
Std.HashMap.getKey.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) (h : a ∈ m) : α
```

Retrieves the key from the mapping that matches `a`. Ensures that such a mapping exists by requiring a proof of `a ∈ m`. The result is guaranteed to be pointer equal to the key in the map.

<a id="Std___HashMap___getKey___"></a>

**def**

```text
Std.HashMap.getKey!.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [Inhabited α] (m : Std.HashMap α β) (a : α) : α
```

Checks if a mapping for the given key exists and returns the key if it does, otherwise panics. If no panic occurs the result is guaranteed to be pointer equal to the key in the map.

<a id="Std___HashMap___getKey___-next"></a>

**def**

```text
Std.HashMap.getKey?.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) : Option α
```

Checks if a mapping for the given key exists and returns the key if it does, otherwise `none`. The result in the `some` case is guaranteed to be pointer equal to the key in the map.

<a id="Std___HashMap___getKeyD"></a>

**def**

```text
Std.HashMap.getKeyD.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.HashMap α β) (a fallback : α) : α
```

Checks if a mapping for the given key exists and returns the key if it does, otherwise `fallback`. If a mapping exists the result is guaranteed to be pointer equal to the key in the map.

<a id="Std___HashMap___keys"></a>

**def**

```text
Std.HashMap.keys.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.HashMap α β) : List α
```

Returns a list of all keys present in the hash map in some order.

<a id="Std___HashMap___keysArray"></a>

**def**

```text
Std.HashMap.keysArray.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.HashMap α β) : Array α
```

Returns an array of all keys present in the hash map in some order.

<a id="Std___HashMap___values"></a>

**def**

```text
Std.HashMap.values.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.HashMap α β) : List β
```

Returns a list of all values present in the hash map in some order.

<a id="Std___HashMap___valuesArray"></a>

**def**

```text
Std.HashMap.valuesArray.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.HashMap α β) : Array β
```

Returns an array of all values present in the hash map in some order.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Hash-Maps--Modification"></a>
#### 20.19.2.4. Modification

<a id="Std___HashMap___alter"></a>

**def**

```text
Std.HashMap.alter.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α)
  (f : Option β → Option β) : Std.HashMap α β
```

Modifies in place the value associated with a given key, allowing creating new values and deleting values via an `Option` valued replacement function.

This function ensures that the value is used linearly.

<a id="Std___HashMap___modify"></a>

**def**

```text
Std.HashMap.modify.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) (f : β → β) :
  Std.HashMap α β
```

Modifies in place the value associated with a given key.

This function ensures that the value is used linearly.

<a id="Std___HashMap___containsThenInsert"></a>

**def**

```text
Std.HashMap.containsThenInsert.{u, v} {α : Type u} {β : Type v}
  {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α)
  (b : β) : Bool × Std.HashMap α β
```

Checks whether a key is present in a map, and unconditionally inserts a value for the key.

Equivalent to (but potentially faster than) calling `contains` followed by `insert`.

<a id="Std___HashMap___containsThenInsertIfNew"></a>

**def**

```text
Std.HashMap.containsThenInsertIfNew.{u, v} {α : Type u} {β : Type v}
  {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α)
  (b : β) : Bool × Std.HashMap α β
```

Checks whether a key is present in a map and inserts a value for the key if it was not found.

If the returned `Bool` is `true`, then the returned map is unaltered. If the `Bool` is `false`, then the returned map has a new value inserted.

Equivalent to (but potentially faster than) calling `contains` followed by `insertIfNew`.

<a id="Std___HashMap___erase"></a>

**def**

```text
Std.HashMap.erase.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) : Std.HashMap α β
```

Removes the mapping for the given key if it exists.

<a id="Std___HashMap___filter"></a>

**def**

```text
Std.HashMap.filter.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (f : α → β → Bool) (m : Std.HashMap α β) :
  Std.HashMap α β
```

Removes all mappings of the hash map for which the given function returns `false`.

<a id="Std___HashMap___filterMap"></a>

**def**

```text
Std.HashMap.filterMap.{u, v, w} {α : Type u} {β : Type v} {γ : Type w}
  [BEq α] [Hashable α] (f : α → β → Option γ) (m : Std.HashMap α β) :
  Std.HashMap α γ
```

Updates the values of the hash map by applying the given function to all mappings, keeping only those mappings where the function returns `some` value.

<a id="Std___HashMap___insert"></a>

**def**

```text
Std.HashMap.insert.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) (b : β) :
  Std.HashMap α β
```

Inserts the given mapping into the map. If there is already a mapping for the given key, then both key and value will be replaced.

Note: this replacement behavior is true for `HashMap`, `DHashMap`, `HashMap.Raw` and `DHashMap.Raw`. The `insert` function on `HashSet` and `HashSet.Raw` behaves differently: it will return the set unchanged if a matching key is already present.

<a id="Std___HashMap___insertIfNew"></a>

**def**

```text
Std.HashMap.insertIfNew.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α) (b : β) :
  Std.HashMap α β
```

If there is no mapping for the given key, inserts the given mapping into the map. Otherwise, returns the map unaltered.

<a id="Std___HashMap___getThenInsertIfNew___"></a>

**def**

```text
Std.HashMap.getThenInsertIfNew?.{u, v} {α : Type u} {β : Type v}
  {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.HashMap α β) (a : α)
  (b : β) : Option β × Std.HashMap α β
```

Checks whether a key is present in a map, returning the associated value, and inserts a value for the key if it was not found.

If the returned value is `some v`, then the returned map is unaltered. If it is `none`, then the returned map has a new value inserted.

Equivalent to (but potentially faster than) calling `get?` followed by `insertIfNew`.

<a id="Std___HashMap___insertMany"></a>

**def**

```text
Std.HashMap.insertMany.{u, v, w} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} {ρ : Type w} [ForIn Id ρ (α × β)]
  (m : Std.HashMap α β) (l : ρ) : Std.HashMap α β
```

Inserts multiple mappings into the hash map by iterating over the given collection and calling `insert`. If the same key appears multiple times, the last occurrence takes precedence.

Note: this precedence behavior is true for `HashMap`, `DHashMap`, `HashMap.Raw` and `DHashMap.Raw`. The `insertMany` function on `HashSet` and `HashSet.Raw` behaves differently: it will prefer the first appearance.

<a id="Std___HashMap___insertManyIfNewUnit"></a>

**def**

```text
Std.HashMap.insertManyIfNewUnit.{u, w} {α : Type u} {x✝ : BEq α}
  {x✝¹ : Hashable α} {ρ : Type w} [ForIn Id ρ α]
  (m : Std.HashMap α Unit) (l : ρ) : Std.HashMap α Unit
```

Inserts multiple keys with the value `()` into the hash map by iterating over the given collection and calling `insertIfNew`. If the same key appears multiple times, the first occurrence takes precedence.

This is mainly useful to implement `HashSet.insertMany`, so if you are considering using this, `HashSet` or `HashSet.Raw` might be a better fit for you.

<a id="Std___HashMap___partition"></a>

**def**

```text
Std.HashMap.partition.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (f : α → β → Bool) (m : Std.HashMap α β) :
  Std.HashMap α β × Std.HashMap α β
```

Partition a hash map into two hash map based on a predicate.

<a id="Std___HashMap___union"></a>

**def**

```text
Std.HashMap.union.{u, v} {α : Type u} {β : Type v} [BEq α] [Hashable α]
  (m₁ m₂ : Std.HashMap α β) : Std.HashMap α β
```

Computes the union of the given hash maps. If a key appears in both maps, the entry contained in the second argument will appear in the result.

This function always merges the smaller map into the larger map, so the expected runtime is `O(min(m₁.size, m₂.size))`.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Hash-Maps--Iteration"></a>
#### 20.19.2.5. Iteration

<a id="Std___HashMap___iter"></a>

**def**

```text
Std.HashMap.iter.{u, v} {α : Type u} {β : Type v} [BEq α] [Hashable α]
  (m : Std.HashMap α β) : Std.Iter (α × β)
```

Returns a finite iterator over the entries of a hash map. The iterator yields the elements of the map in order and then terminates.

**Termination properties:**

- `Finite` instance: always
- `Productive` instance: always

<a id="Std___HashMap___keysIter"></a>

**def**

```text
Std.HashMap.keysIter.{u} {α β : Type u} [BEq α] [Hashable α]
  (m : Std.HashMap α β) : Std.Iter α
```

Returns a finite iterator over the entries of a hash map. The iterator yields the elements of the map in order and then terminates.

**Termination properties:**

- `Finite` instance: always
- `Productive` instance: always

<a id="Std___HashMap___valuesIter"></a>

**def**

```text
Std.HashMap.valuesIter.{u} {α β : Type u} [BEq α] [Hashable α]
  (m : Std.HashMap α β) : Std.Iter β
```

Returns a finite iterator over the entries of a hash map. The iterator yields the elements of the map in order and then terminates.

**Termination properties:**

- `Finite` instance: always
- `Productive` instance: always

<a id="Std___HashMap___map"></a>

**def**

```text
Std.HashMap.map.{u, v, w} {α : Type u} {β : Type v} {γ : Type w} [BEq α]
  [Hashable α] (f : α → β → γ) (m : Std.HashMap α β) : Std.HashMap α γ
```

Updates the values of the hash map by applying the given function to all mappings.

<a id="Std___HashMap___fold"></a>

**def**

```text
Std.HashMap.fold.{u, v, w} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} {γ : Type w} (f : γ → α → β → γ) (init : γ)
  (b : Std.HashMap α β) : γ
```

Folds the given function over the mappings in the hash map in some order.

<a id="Std___HashMap___foldM"></a>

**def**

```text
Std.HashMap.foldM.{u, v, w, w'} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} {m : Type w → Type w'} [Monad m] {γ : Type w}
  (f : γ → α → β → m γ) (init : γ) (b : Std.HashMap α β) : m γ
```

Monadically computes a value by folding the given function over the mappings in the hash map in some order.

<a id="Std___HashMap___forIn"></a>

**def**

```text
Std.HashMap.forIn.{u, v, w, w'} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} {m : Type w → Type w'} [Monad m] {γ : Type w}
  (f : α → β → γ → m (ForInStep γ)) (init : γ) (b : Std.HashMap α β) :
  m γ
```

Support for the `for` loop construct in `do` blocks.

<a id="Std___HashMap___forM"></a>

**def**

```text
Std.HashMap.forM.{u, v, w, w'} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} {m : Type w → Type w'} [Monad m]
  (f : α → β → m PUnit) (b : Std.HashMap α β) : m PUnit
```

Carries out a monadic action on each mapping in the hash map in some order.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Hash-Maps--Conversion"></a>
#### 20.19.2.6. Conversion

<a id="Std___HashMap___ofList"></a>

**def**

```text
Std.HashMap.ofList.{u, v} {α : Type u} {β : Type v} [BEq α] [Hashable α]
  (l : List (α × β)) : Std.HashMap α β
```

Creates a hash map from a list of mappings. If the same key appears multiple times, the last occurrence takes precedence.

<a id="Std___HashMap___toArray"></a>

**def**

```text
Std.HashMap.toArray.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.HashMap α β) : Array (α × β)
```

Transforms the hash map into an array of mappings in some order.

<a id="Std___HashMap___toList"></a>

**def**

```text
Std.HashMap.toList.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.HashMap α β) : List (α × β)
```

Transforms the hash map into a list of mappings in some order.

<a id="Std___HashMap___unitOfArray"></a>

**def**

```text
Std.HashMap.unitOfArray.{u} {α : Type u} [BEq α] [Hashable α]
  (l : Array α) : Std.HashMap α Unit
```

Creates a hash map from an array of keys, associating the value `()` with each key.

This is mainly useful to implement `HashSet.ofArray`, so if you are considering using this, `HashSet` or `HashSet.Raw` might be a better fit for you.

<a id="Std___HashMap___unitOfList"></a>

**def**

```text
Std.HashMap.unitOfList.{u} {α : Type u} [BEq α] [Hashable α]
  (l : List α) : Std.HashMap α Unit
```

Creates a hash map from a list of keys, associating the value `()` with each key.

This is mainly useful to implement `HashSet.ofList`, so if you are considering using this, `HashSet` or `HashSet.Raw` might be a better fit for you.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Hash-Maps--Unbundled-Variants"></a>
#### 20.19.2.7. Unbundled Variants

Unbundled maps separate well-formedness proofs from data. This is primarily useful when defining [nested inductive types](index.md#raw-data). To use these variants, import the modules `Std.HashMap.Raw` and `Std.HashMap.RawLemmas`.

<a id="Std___HashMap___Raw___mk"></a>

**structure**

```text
Std.HashMap.Raw.{u, v} (α : Type u) (β : Type v) : Type (max u v)
```

Hash maps without a bundled well-formedness invariant, suitable for use in nested inductive types. The well-formedness invariant is called `Raw.WF`. When in doubt, prefer `HashMap` over `HashMap.Raw`. Lemmas about the operations on `Std.Data.HashMap.Raw` are available in the module `Std.Data.HashMap.RawLemmas`.

This is a simple separate-chaining hash table. The data of the hash map consists of a cached size and an array of buckets, where each bucket is a linked list of key-value pairs. The number of buckets is always a power of two. The hash map doubles its size upon inserting an element such that the number of elements is more than 75% of the number of buckets.

The hash table is backed by an `Array`. Users should make sure that the hash map is used linearly to avoid expensive copies.

The hash map uses `==` (provided by the `BEq` typeclass) to compare keys and `hash` (provided by the `Hashable` typeclass) to hash them. To ensure that the operations behave as expected, `==` should be an equivalence relation and `a == b` should imply `hash a = hash b` (see also the `EquivBEq` and `LawfulHashable` typeclasses). Both of these conditions are automatic if the BEq instance is lawful, i.e., if `a == b` implies `a = b`.

Dependent hash maps, in which keys may occur in their values' types, are available as `Std.Data.Raw.DHashMap`.

**Constructor**

```text
Std.HashMap.Raw.mk.{u, v}
```

**Fields**

```text
inner : Std.DHashMap.Raw α fun x => β
```

Internal implementation detail of the hash map

<a id="Std___HashMap___Raw___WF___mk"></a>

**structure**

```text
Std.HashMap.Raw.WF.{u, v} {α : Type u} {β : Type v} [BEq α] [Hashable α]
  (m : Std.HashMap.Raw α β) : Prop
```

Well-formedness predicate for hash maps. Users of `HashMap` will not need to interact with this. Users of `HashMap.Raw` will need to provide proofs of `WF` to lemmas and should use lemmas `WF.empty` and `WF.insert` (which are always named exactly like the operations they are about) to show that map operations preserve well-formedness.

**Constructor**

```text
Std.HashMap.Raw.WF.mk.{u, v}
```

**Fields**

```text
out : m.inner.WF
```

Internal implementation detail of the hash map

<a id="DHashMap"></a>
### 20.19.3. Dependent Hash Maps

The declarations in this section should be imported using `import Std.DHashMap`.

<a id="Std___DHashMap"></a>

**structure**

```text
Std.DHashMap.{u, v} (α : Type u) (β : α → Type v) [BEq α] [Hashable α] :
  Type (max u v)
```

Dependent hash maps.

This is a simple separate-chaining hash table. The data of the hash map consists of a cached size and an array of buckets, where each bucket is a linked list of key-value pairs. The number of buckets is always a power of two. The hash map doubles its size upon inserting an element such that the number of elements is more than 75% of the number of buckets.

The hash table is backed by an `Array`. Users should make sure that the hash map is used linearly to avoid expensive copies.

The hash map uses `==` (provided by the `BEq` typeclass) to compare keys and `hash` (provided by the `Hashable` typeclass) to hash them. To ensure that the operations behave as expected, `==` should be an equivalence relation and `a == b` should imply `hash a = hash b` (see also the `EquivBEq` and `LawfulHashable` typeclasses). Both of these conditions are automatic if the BEq instance is lawful, i.e., if `a == b` implies `a = b`.

These hash maps contain a bundled well-formedness invariant, which means that they cannot be used in nested inductive types. For these use cases, `Std.DHashMap.Raw` and `Std.DHashMap.Raw.WF` unbundle the invariant from the hash map. When in doubt, prefer `DHashMap` over `DHashMap.Raw`.

For a variant that is more convenient for use in proofs because of extensionalities, see `Std.ExtDHashMap` which is defined in the module `Std.Data.ExtDHashMap`.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Dependent-Hash-Maps--Creation"></a>
#### 20.19.3.1. Creation

<a id="Std___DHashMap___emptyWithCapacity"></a>

**def**

```text
Std.DHashMap.emptyWithCapacity.{u, v} {α : Type u} {β : α → Type v}
  [BEq α] [Hashable α] (capacity : Nat := 8) : Std.DHashMap α β
```

Creates a new empty hash map. The optional parameter `capacity` can be supplied to presize the map so that it can hold the given number of mappings without reallocating. It is also possible to use the empty collection notations `∅` and `{}` to create an empty hash map with the default capacity.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Dependent-Hash-Maps--Properties"></a>
#### 20.19.3.2. Properties

<a id="Std___DHashMap___size"></a>

**def**

```text
Std.DHashMap.size.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.DHashMap α β) : Nat
```

The number of mappings present in the hash map

<a id="Std___DHashMap___isEmpty"></a>

**def**

```text
Std.DHashMap.isEmpty.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.DHashMap α β) : Bool
```

Returns `true` if the hash map contains no mappings.

Note that if your `BEq` instance is not reflexive or your `Hashable` instance is not lawful, then it is possible that this function returns `false` even though is not possible to get anything out of the hash map.

<a id="Std___DHashMap___Equiv___mk"></a>

**structure**

```text
Std.DHashMap.Equiv.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m₁ m₂ : Std.DHashMap α β) : Prop
```

Two hash maps are equivalent in the sense of `Equiv` iff all the keys and values are equal.

**Constructor**

```text
Std.DHashMap.Equiv.mk.{u, v}
```

**Fields**

```text
inner : m₁.inner.Equiv m₂.inner
```

Internal implementation detail of the hash map

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Equivalence**

The relation `DHashMap.Equiv` can also be written with an infix operator, which is scoped to its namespace:

<a id="Std___DHashMap____FLQQ_term____m__FLQQ_"></a>

```ebnf
term ::= ...
    | term ~m term
```

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Dependent-Hash-Maps--Queries"></a>
#### 20.19.3.3. Queries

<a id="Std___DHashMap___contains"></a>

**def**

```text
Std.DHashMap.contains.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.DHashMap α β) (a : α) : Bool
```

Returns `true` if there is a mapping for the given key. There is also a `Prop`-valued version of this: `a ∈ m` is equivalent to `m.contains a = true`.

Observe that this is different behavior than for lists: for lists, `∈` uses `=` and `contains` uses `==` for comparisons, while for hash maps, both use `==`.

<a id="Std___DHashMap___get"></a>

**def**

```text
Std.DHashMap.get.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.DHashMap α β) (a : α)
  (h : a ∈ m) : β a
```

Retrieves the mapping for the given key. Ensures that such a mapping exists by requiring a proof of `a ∈ m`.

Uses the `LawfulBEq` instance to cast the retrieved value to the correct type.

<a id="Std___DHashMap___get___"></a>

**def**

```text
Std.DHashMap.get!.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.DHashMap α β) (a : α)
  [Inhabited (β a)] : β a
```

Tries to retrieve the mapping for the given key, panicking if no such mapping is present.

Uses the `LawfulBEq` instance to cast the retrieved value to the correct type.

<a id="Std___DHashMap___get___-next"></a>

**def**

```text
Std.DHashMap.get?.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.DHashMap α β) (a : α) :
  Option (β a)
```

Tries to retrieve the mapping for the given key, returning `none` if no such mapping is present.

Uses the `LawfulBEq` instance to cast the retrieved value to the correct type.

<a id="Std___DHashMap___getD"></a>

**def**

```text
Std.DHashMap.getD.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.DHashMap α β) (a : α)
  (fallback : β a) : β a
```

Tries to retrieve the mapping for the given key, returning `fallback` if no such mapping is present.

Uses the `LawfulBEq` instance to cast the retrieved value to the correct type.

<a id="Std___DHashMap___getKey"></a>

**def**

```text
Std.DHashMap.getKey.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.DHashMap α β) (a : α) (h : a ∈ m) : α
```

Retrieves the key from the mapping that matches `a`. Ensures that such a mapping exists by requiring a proof of `a ∈ m`. The result is guaranteed to be pointer equal to the key in the map.

<a id="Std___DHashMap___getKey___"></a>

**def**

```text
Std.DHashMap.getKey!.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [Inhabited α] (m : Std.DHashMap α β) (a : α) : α
```

Checks if a mapping for the given key exists and returns the key if it does, otherwise panics. If no panic occurs the result is guaranteed to be pointer equal to the key in the map.

<a id="Std___DHashMap___getKey___-next"></a>

**def**

```text
Std.DHashMap.getKey?.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.DHashMap α β) (a : α) : Option α
```

Checks if a mapping for the given key exists and returns the key if it does, otherwise `none`. The result in the `some` case is guaranteed to be pointer equal to the key in the map.

<a id="Std___DHashMap___getKeyD"></a>

**def**

```text
Std.DHashMap.getKeyD.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.DHashMap α β) (a fallback : α) : α
```

Checks if a mapping for the given key exists and returns the key if it does, otherwise `fallback`. If a mapping exists the result is guaranteed to be pointer equal to the key in the map.

<a id="Std___DHashMap___keys"></a>

**def**

```text
Std.DHashMap.keys.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.DHashMap α β) : List α
```

Returns a list of all keys present in the hash map in some order.

<a id="Std___DHashMap___keysArray"></a>

**def**

```text
Std.DHashMap.keysArray.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.DHashMap α β) : Array α
```

Returns an array of all keys present in the hash map in some order.

<a id="Std___DHashMap___values"></a>

**def**

```text
Std.DHashMap.values.{u, v} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  {β : Type v} (m : Std.DHashMap α fun x => β) : List β
```

Returns a list of all values present in the hash map in some order.

<a id="Std___DHashMap___valuesArray"></a>

**def**

```text
Std.DHashMap.valuesArray.{u, v} {α : Type u} {x✝ : BEq α}
  {x✝¹ : Hashable α} {β : Type v} (m : Std.DHashMap α fun x => β) :
  Array β
```

Returns an array of all values present in the hash map in some order.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Dependent-Hash-Maps--Modification"></a>
#### 20.19.3.4. Modification

<a id="Std___DHashMap___alter"></a>

**def**

```text
Std.DHashMap.alter.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.DHashMap α β) (a : α)
  (f : Option (β a) → Option (β a)) : Std.DHashMap α β
```

Modifies in place the value associated with a given key, allowing creating new values and deleting values via an `Option` valued replacement function.

This function ensures that the value is used linearly.

<a id="Std___DHashMap___modify"></a>

**def**

```text
Std.DHashMap.modify.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.DHashMap α β) (a : α)
  (f : β a → β a) : Std.DHashMap α β
```

Modifies in place the value associated with a given key.

This function ensures that the value is used linearly.

<a id="Std___DHashMap___containsThenInsert"></a>

**def**

```text
Std.DHashMap.containsThenInsert.{u, v} {α : Type u} {β : α → Type v}
  {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.DHashMap α β) (a : α)
  (b : β a) : Bool × Std.DHashMap α β
```

Checks whether a key is present in a map, and unconditionally inserts a value for the key.

Equivalent to (but potentially faster than) calling `contains` followed by `insert`.

<a id="Std___DHashMap___containsThenInsertIfNew"></a>

**def**

```text
Std.DHashMap.containsThenInsertIfNew.{u, v} {α : Type u}
  {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α}
  (m : Std.DHashMap α β) (a : α) (b : β a) : Bool × Std.DHashMap α β
```

Checks whether a key is present in a map and inserts a value for the key if it was not found.

If the returned `Bool` is `true`, then the returned map is unaltered. If the `Bool` is `false`, then the returned map has a new value inserted.

Equivalent to (but potentially faster than) calling `contains` followed by `insertIfNew`.

<a id="Std___DHashMap___erase"></a>

**def**

```text
Std.DHashMap.erase.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.DHashMap α β) (a : α) : Std.DHashMap α β
```

Removes the mapping for the given key if it exists.

<a id="Std___DHashMap___filter"></a>

**def**

```text
Std.DHashMap.filter.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (f : (a : α) → β a → Bool) (m : Std.DHashMap α β) :
  Std.DHashMap α β
```

Removes all mappings of the hash map for which the given function returns `false`.

<a id="Std___DHashMap___filterMap"></a>

**def**

```text
Std.DHashMap.filterMap.{u, v, w} {α : Type u} {β : α → Type v}
  {δ : α → Type w} [BEq α] [Hashable α]
  (f : (a : α) → β a → Option (δ a)) (m : Std.DHashMap α β) :
  Std.DHashMap α δ
```

Updates the values of the hash map by applying the given function to all mappings, keeping only those mappings where the function returns `some` value.

<a id="Std___DHashMap___insert"></a>

**def**

```text
Std.DHashMap.insert.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.DHashMap α β) (a : α) (b : β a) :
  Std.DHashMap α β
```

Inserts the given mapping into the map. If there is already a mapping for the given key, then both key and value will be replaced.

Note: this replacement behavior is true for `HashMap`, `DHashMap`, `HashMap.Raw` and `DHashMap.Raw`. The `insert` function on `HashSet` and `HashSet.Raw` behaves differently: it will return the set unchanged if a matching key is already present.

<a id="Std___DHashMap___insertIfNew"></a>

**def**

```text
Std.DHashMap.insertIfNew.{u, v} {α : Type u} {β : α → Type v}
  {x✝ : BEq α} {x✝¹ : Hashable α} (m : Std.DHashMap α β) (a : α)
  (b : β a) : Std.DHashMap α β
```

If there is no mapping for the given key, inserts the given mapping into the map. Otherwise, returns the map unaltered.

<a id="Std___DHashMap___getThenInsertIfNew___"></a>

**def**

```text
Std.DHashMap.getThenInsertIfNew?.{u, v} {α : Type u} {β : α → Type v}
  {x✝ : BEq α} {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.DHashMap α β)
  (a : α) (b : β a) : Option (β a) × Std.DHashMap α β
```

Checks whether a key is present in a map, returning the associated value, and inserts a value for the key if it was not found.

If the returned value is `some v`, then the returned map is unaltered. If it is `none`, then the returned map has a new value inserted.

Equivalent to (but potentially faster than) calling `get?` followed by `insertIfNew`.

Uses the `LawfulBEq` instance to cast the retrieved value to the correct type.

<a id="Std___DHashMap___insertMany"></a>

**def**

```text
Std.DHashMap.insertMany.{u, v, w} {α : Type u} {β : α → Type v}
  {x✝ : BEq α} {x✝¹ : Hashable α} {ρ : Type w}
  [ForIn Id ρ ((a : α) × β a)] (m : Std.DHashMap α β) (l : ρ) :
  Std.DHashMap α β
```

Inserts multiple mappings into the hash map by iterating over the given collection and calling `insert`. If the same key appears multiple times, the last occurrence takes precedence.

Note: this precedence behavior is true for `HashMap`, `DHashMap`, `HashMap.Raw` and `DHashMap.Raw`. The `insertMany` function on `HashSet` and `HashSet.Raw` behaves differently: it will prefer the first appearance.

<a id="Std___DHashMap___partition"></a>

**def**

```text
Std.DHashMap.partition.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (f : (a : α) → β a → Bool) (m : Std.DHashMap α β) :
  Std.DHashMap α β × Std.DHashMap α β
```

Partition a hash map into two hash map based on a predicate.

<a id="Std___DHashMap___union"></a>

**def**

```text
Std.DHashMap.union.{u, v} {α : Type u} {β : α → Type v} [BEq α]
  [Hashable α] (m₁ m₂ : Std.DHashMap α β) : Std.DHashMap α β
```

Computes the union of the given hash maps. If a key appears in both maps, the entry contained in the second argument will appear in the result.

This function always merges the smaller map into the larger map, so the expected runtime is `O(min(m₁.size, m₂.size))`.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Dependent-Hash-Maps--Iteration"></a>
#### 20.19.3.5. Iteration

<a id="Std___DHashMap___iter"></a>

**def**

```text
Std.DHashMap.iter.{u, v} {α : Type u} {β : α → Type v} [BEq α]
  [Hashable α] (m : Std.DHashMap α β) : Std.Iter ((a : α) × β a)
```

Returns a finite iterator over the entries of a dependent hash map. The iterator yields the elements of the map in order and then terminates.

**Termination properties:**

- `Finite` instance: always
- `Productive` instance: always

<a id="Std___DHashMap___keysIter"></a>

**def**

```text
Std.DHashMap.keysIter.{u} {α : Type u} {β : α → Type u} [BEq α]
  [Hashable α] (m : Std.DHashMap α β) : Std.Iter α
```

Returns a finite iterator over the keys of a dependent hash map. The iterator yields the keys in order and then terminates.

The key and value types must live in the same universe.

**Termination properties:**

- `Finite` instance: always
- `Productive` instance: always

<a id="Std___DHashMap___valuesIter"></a>

**def**

```text
Std.DHashMap.valuesIter.{u} {α β : Type u} [BEq α] [Hashable α]
  (m : Std.DHashMap α fun x => β) : Std.Iter β
```

Returns a finite iterator over the values of a hash map. The iterator yields the values in order and then terminates.

The key and value types must live in the same universe.

**Termination properties:**

- `Finite` instance: always
- `Productive` instance: always

<a id="Std___DHashMap___map"></a>

**def**

```text
Std.DHashMap.map.{u, v, w} {α : Type u} {β : α → Type v}
  {δ : α → Type w} [BEq α] [Hashable α] (f : (a : α) → β a → δ a)
  (m : Std.DHashMap α β) : Std.DHashMap α δ
```

Updates the values of the hash map by applying the given function to all mappings.

<a id="Std___DHashMap___fold"></a>

**def**

```text
Std.DHashMap.fold.{u, v, w} {α : Type u} {β : α → Type v} {δ : Type w}
  {x✝ : BEq α} {x✝¹ : Hashable α} (f : δ → (a : α) → β a → δ) (init : δ)
  (b : Std.DHashMap α β) : δ
```

Folds the given function over the mappings in the hash map in some order.

<a id="Std___DHashMap___foldM"></a>

**def**

```text
Std.DHashMap.foldM.{u, v, w, w'} {α : Type u} {β : α → Type v}
  {δ : Type w} {m : Type w → Type w'} [Monad m] {x✝ : BEq α}
  {x✝¹ : Hashable α} (f : δ → (a : α) → β a → m δ) (init : δ)
  (b : Std.DHashMap α β) : m δ
```

Monadically computes a value by folding the given function over the mappings in the hash map in some order.

<a id="Std___DHashMap___forIn"></a>

**def**

```text
Std.DHashMap.forIn.{u, v, w, w'} {α : Type u} {β : α → Type v}
  {δ : Type w} {m : Type w → Type w'} [Monad m] {x✝ : BEq α}
  {x✝¹ : Hashable α} (f : (a : α) → β a → δ → m (ForInStep δ))
  (init : δ) (b : Std.DHashMap α β) : m δ
```

Support for the `for` loop construct in `do` blocks.

<a id="Std___DHashMap___forM"></a>

**def**

```text
Std.DHashMap.forM.{u, v, w, w'} {α : Type u} {β : α → Type v}
  {m : Type w → Type w'} [Monad m] {x✝ : BEq α} {x✝¹ : Hashable α}
  (f : (a : α) → β a → m PUnit) (b : Std.DHashMap α β) : m PUnit
```

Carries out a monadic action on each mapping in the hash map in some order.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Dependent-Hash-Maps--Conversion"></a>
#### 20.19.3.6. Conversion

<a id="Std___DHashMap___ofList"></a>

**def**

```text
Std.DHashMap.ofList.{u, v} {α : Type u} {β : α → Type v} [BEq α]
  [Hashable α] (l : List ((a : α) × β a)) : Std.DHashMap α β
```

Creates a hash map from a list of mappings. If the same key appears multiple times, the last occurrence takes precedence.

<a id="Std___DHashMap___toArray"></a>

**def**

```text
Std.DHashMap.toArray.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.DHashMap α β) : Array ((a : α) × β a)
```

Transforms the hash map into an array of mappings in some order.

<a id="Std___DHashMap___toList"></a>

**def**

```text
Std.DHashMap.toList.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.DHashMap α β) : List ((a : α) × β a)
```

Transforms the hash map into a list of mappings in some order.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Dependent-Hash-Maps--Unbundled-Variants"></a>
#### 20.19.3.7. Unbundled Variants

Unbundled maps separate well-formedness proofs from data. This is primarily useful when defining [nested inductive types](index.md#raw-data). To use these variants, import the modules `Std.DHashMap.Raw` and `Std.DHashMap.RawLemmas`.

<a id="Std___DHashMap___Raw___mk"></a>

**structure**

```text
Std.DHashMap.Raw.{u, v} (α : Type u) (β : α → Type v) : Type (max u v)
```

Dependent hash maps without a bundled well-formedness invariant, suitable for use in nested inductive types. The well-formedness invariant is called `Raw.WF`. When in doubt, prefer `DHashMap` over `DHashMap.Raw`. Lemmas about the operations on `Std.Data.DHashMap.Raw` are available in the module `Std.Data.DHashMap.RawLemmas`.

The hash table is backed by an `Array`. Users should make sure that the hash map is used linearly to avoid expensive copies.

This is a simple separate-chaining hash table. The data of the hash map consists of a cached size and an array of buckets, where each bucket is a linked list of key-value pairs. The number of buckets is always a power of two. The hash map doubles its size upon inserting an element such that the number of elements is more than 75% of the number of buckets.

The hash map uses `==` (provided by the `BEq` typeclass) to compare keys and `hash` (provided by the `Hashable` typeclass) to hash them. To ensure that the operations behave as expected, `==` should be an equivalence relation and `a == b` should imply `hash a = hash b` (see also the `EquivBEq` and `LawfulHashable` typeclasses). Both of these conditions are automatic if the BEq instance is lawful, i.e., if `a == b` implies `a = b`.

**Constructor**

```text
Std.DHashMap.Raw.mk.{u, v}
```

**Fields**

```text
size : Nat
```

The number of mappings present in the hash map

```text
buckets : Array (Std.DHashMap.Internal.AssocList α β)
```

Internal implementation detail of the hash map

<a id="Std___DHashMap___Raw___WF___wf"></a>

**inductive predicate**

```text
Std.DHashMap.Raw.WF.{u, v} {α : Type u} {β : α → Type v} [BEq α]
  [Hashable α] : Std.DHashMap.Raw α β → Prop
```

Well-formedness predicate for hash maps. Users of `DHashMap` will not need to interact with this. Users of `DHashMap.Raw` will need to provide proofs of `WF` to lemmas and should use lemmas like `WF.empty` and `WF.insert` (which are always named exactly like the operations they are about) to show that map operations preserve well-formedness. The constructors of this type are internal implementation details and should not be accessed by users.

**Constructors**

```text
Std.DHashMap.Raw.WF.wf.{u, v} {α : Type u} {β : α → Type v}
  [BEq α] [Hashable α] {m : Std.DHashMap.Raw α β} :
  0 < m.buckets.size →
    (∀ [EquivBEq α] [LawfulHashable α],
        Std.DHashMap.Internal.Raw.WFImp m) →
      m.WF
```

Internal implementation detail of the hash map

```text
Std.DHashMap.Raw.WF.emptyWithCapacity₀.{u, v} {α : Type u}
  {β : α → Type v} [BEq α] [Hashable α] {c : Nat} :
  (Std.DHashMap.Internal.Raw₀.emptyWithCapacity c).val.WF
```

Internal implementation detail of the hash map

```text
Std.DHashMap.Raw.WF.insert₀.{u, v} {α : Type u}
  {β : α → Type v} [BEq α] [Hashable α]
  {m : Std.DHashMap.Raw α β} {h : 0 < m.buckets.size}
  {a : α} {b : β a} :
  m.WF →
    (Std.DHashMap.Internal.Raw₀.insert ⟨m, h⟩ a b).val.WF
```

Internal implementation detail of the hash map

```text
Std.DHashMap.Raw.WF.containsThenInsert₀.{u, v} {α : Type u}
  {β : α → Type v} [BEq α] [Hashable α]
  {m : Std.DHashMap.Raw α β} {h : 0 < m.buckets.size}
  {a : α} {b : β a} :
  m.WF →
    (Std.DHashMap.Internal.Raw₀.containsThenInsert ⟨m, h⟩ a
            b).snd.val.WF
```

Internal implementation detail of the hash map

```text
Std.DHashMap.Raw.WF.containsThenInsertIfNew₀.{u, v}
  {α : Type u} {β : α → Type v} [BEq α] [Hashable α]
  {m : Std.DHashMap.Raw α β} {h : 0 < m.buckets.size}
  {a : α} {b : β a} :
  m.WF →
    (Std.DHashMap.Internal.Raw₀.containsThenInsertIfNew
            ⟨m, h⟩ a b).snd.val.WF
```

Internal implementation detail of the hash map

```text
Std.DHashMap.Raw.WF.erase₀.{u, v} {α : Type u}
  {β : α → Type v} [BEq α] [Hashable α]
  {m : Std.DHashMap.Raw α β} {h : 0 < m.buckets.size}
  {a : α} :
  m.WF → (Std.DHashMap.Internal.Raw₀.erase ⟨m, h⟩ a).val.WF
```

Internal implementation detail of the hash map

```text
Std.DHashMap.Raw.WF.insertIfNew₀.{u, v} {α : Type u}
  {β : α → Type v} [BEq α] [Hashable α]
  {m : Std.DHashMap.Raw α β} {h : 0 < m.buckets.size}
  {a : α} {b : β a} :
  m.WF →
    (Std.DHashMap.Internal.Raw₀.insertIfNew ⟨m, h⟩ a
          b).val.WF
```

Internal implementation detail of the hash map

```text
Std.DHashMap.Raw.WF.getThenInsertIfNew?₀.{u, v} {α : Type u}
  {β : α → Type v} [BEq α] [Hashable α] [LawfulBEq α]
  {m : Std.DHashMap.Raw α β} {h : 0 < m.buckets.size}
  {a : α} {b : β a} :
  m.WF →
    (Std.DHashMap.Internal.Raw₀.getThenInsertIfNew? ⟨m, h⟩ a
            b).snd.val.WF
```

Internal implementation detail of the hash map

```text
Std.DHashMap.Raw.WF.filter₀.{u, v} {α : Type u}
  {β : α → Type v} [BEq α] [Hashable α]
  {m : Std.DHashMap.Raw α β} {h : 0 < m.buckets.size}
  {f : (a : α) → β a → Bool} :
  m.WF → (Std.DHashMap.Internal.Raw₀.filter f ⟨m, h⟩).val.WF
```

Internal implementation detail of the hash map

```text
Std.DHashMap.Raw.WF.constGetThenInsertIfNew?₀.{u, v}
  {α : Type u} {β : Type v} [BEq α] [Hashable α]
  {m : Std.DHashMap.Raw α fun x => β}
  {h : 0 < m.buckets.size} {a : α} {b : β} :
  m.WF →
    (Std.DHashMap.Internal.Raw₀.Const.getThenInsertIfNew?
            ⟨m, h⟩ a b).snd.val.WF
```

Internal implementation detail of the hash map

```text
Std.DHashMap.Raw.WF.modify₀.{u, v} {α : Type u}
  {β : α → Type v} [BEq α] [Hashable α] [LawfulBEq α]
  {m : Std.DHashMap.Raw α β} {h : 0 < m.buckets.size}
  {a : α} {f : β a → β a} :
  m.WF →
    (Std.DHashMap.Internal.Raw₀.modify ⟨m, h⟩ a f).val.WF
```

Internal implementation detail of the hash map

```text
Std.DHashMap.Raw.WF.constModify₀.{u, v} {α : Type u}
  {β : Type v} [BEq α] [Hashable α]
  {m : Std.DHashMap.Raw α fun x => β}
  {h : 0 < m.buckets.size} {a : α} {f : β → β} :
  m.WF →
    (Std.DHashMap.Internal.Raw₀.Const.modify ⟨m, h⟩ a
          f).val.WF
```

Internal implementation detail of the hash map

```text
Std.DHashMap.Raw.WF.alter₀.{u, v} {α : Type u}
  {β : α → Type v} [BEq α] [Hashable α] [LawfulBEq α]
  {m : Std.DHashMap.Raw α β} {h : 0 < m.buckets.size}
  {a : α} {f : Option (β a) → Option (β a)} :
  m.WF →
    (Std.DHashMap.Internal.Raw₀.alter ⟨m, h⟩ a f).val.WF
```

Internal implementation detail of the hash map

```text
Std.DHashMap.Raw.WF.constAlter₀.{u, v} {α : Type u}
  {β : Type v} [BEq α] [Hashable α]
  {m : Std.DHashMap.Raw α fun x => β}
  {h : 0 < m.buckets.size} {a : α}
  {f : Option β → Option β} :
  m.WF →
    (Std.DHashMap.Internal.Raw₀.Const.alter ⟨m, h⟩ a
          f).val.WF
```

Internal implementation detail of the hash map

```text
Std.DHashMap.Raw.WF.inter₀.{u, v} {α : Type u}
  {β : α → Type v} [BEq α] [Hashable α]
  {m₁ m₂ : Std.DHashMap.Raw α β} {h₁ : 0 < m₁.buckets.size}
  {h₂ : 0 < m₂.buckets.size} :
  m₁.WF →
    m₂.WF →
      (Std.DHashMap.Internal.Raw₀.inter ⟨m₁, h₁⟩
            ⟨m₂, h₂⟩).val.WF
```

Internal implementation detail of the hash map

<a id="ExtHashMap"></a>
### 20.19.4. Extensional Hash Maps

The declarations in this section should be imported using `import Std.ExtHashMap`.

<a id="Std___ExtHashMap"></a>

**structure**

```text
Std.ExtHashMap.{u, v} (α : Type u) (β : Type v) [BEq α] [Hashable α] :
  Type (max u v)
```

Hash maps.

This is a simple separate-chaining hash table. The data of the hash map consists of a cached size and an array of buckets, where each bucket is a linked list of key-value pairs. The number of buckets is always a power of two. The hash map doubles its size upon inserting an element such that the number of elements is more than 75% of the number of buckets.

The hash table is backed by an `Array`. Users should make sure that the hash map is used linearly to avoid expensive copies.

The hash map uses `==` (provided by the `BEq` typeclass) to compare keys and `hash` (provided by the `Hashable` typeclass) to hash them. To ensure that the operations behave as expected, `==` should be an equivalence relation and `a == b` should imply `hash a = hash b` (see also the `EquivBEq` and `LawfulHashable` typeclasses). Both of these conditions are automatic if the BEq instance is lawful, i.e., if `a == b` implies `a = b`.

In contrast to regular hash maps, `Std.ExtHashMap` offers several extensionality lemmas and therefore has more lemmas about equality of hash maps. This however also makes it lose the ability to iterate freely over hash maps.

These hash maps contain a bundled well-formedness invariant, which means that they cannot be used in nested inductive types. For these use cases, `Std.HashMap.Raw` and `Std.HashMap.Raw.WF` unbundle the invariant from the hash map. When in doubt, prefer `HashMap` or `ExtHashMap` over `HashMap.Raw`.

Dependent hash maps, in which keys may occur in their values' types, are available as `Std.ExtDHashMap` in the module `Std.Data.ExtDHashMap`.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Extensional-Hash-Maps--Creation"></a>
#### 20.19.4.1. Creation

<a id="Std___ExtHashMap___emptyWithCapacity"></a>

**def**

```text
Std.ExtHashMap.emptyWithCapacity.{u, v} {α : Type u} {β : Type v}
  [BEq α] [Hashable α] (capacity : Nat := 8) : Std.ExtHashMap α β
```

Creates a new empty hash map. The optional parameter `capacity` can be supplied to presize the map so that it can hold the given number of mappings without reallocating. It is also possible to use the empty collection notations `∅` and `{}` to create an empty hash map with the default capacity.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Extensional-Hash-Maps--Properties"></a>
#### 20.19.4.2. Properties

<a id="Std___ExtHashMap___size"></a>

**def**

```text
Std.ExtHashMap.size.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtHashMap α β) : Nat
```

The number of mappings present in the hash map

<a id="Std___ExtHashMap___isEmpty"></a>

**def**

```text
Std.ExtHashMap.isEmpty.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtHashMap α β) : Bool
```

Returns `true` if the hash map contains no mappings.

Note that if your `BEq` instance is not reflexive or your `Hashable` instance is not lawful, then it is possible that this function returns `false` even though is not possible to get anything out of the hash map.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Extensional-Hash-Maps--Queries"></a>
#### 20.19.4.3. Queries

<a id="Std___ExtHashMap___contains"></a>

**def**

```text
Std.ExtHashMap.contains.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtHashMap α β) (a : α) : Bool
```

Returns `true` if there is a mapping for the given key. There is also a `Prop`-valued version of this: `a ∈ m` is equivalent to `m.contains a = true`.

Observe that this is different behavior than for lists: for lists, `∈` uses `=` and `contains` uses `==` for comparisons, while for hash maps, both use `==`.

<a id="Std___ExtHashMap___get"></a>

**def**

```text
Std.ExtHashMap.get.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtHashMap α β) (a : α) (h : a ∈ m) : β
```

The notation `m[a]` or `m[a]'h` is preferred over calling this function directly.

Retrieves the mapping for the given key. Ensures that such a mapping exists by requiring a proof of `a ∈ m`.

<a id="Std___ExtHashMap___get___"></a>

**def**

```text
Std.ExtHashMap.get!.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] [Inhabited β]
  (m : Std.ExtHashMap α β) (a : α) : β
```

The notation `m[a]!` is preferred over calling this function directly.

Tries to retrieve the mapping for the given key, panicking if no such mapping is present.

<a id="Std___ExtHashMap___get___-next"></a>

**def**

```text
Std.ExtHashMap.get?.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtHashMap α β) (a : α) : Option β
```

The notation `m[a]?` is preferred over calling this function directly.

Tries to retrieve the mapping for the given key, returning `none` if no such mapping is present.

<a id="Std___ExtHashMap___getD"></a>

**def**

```text
Std.ExtHashMap.getD.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtHashMap α β) (a : α) (fallback : β) : β
```

Tries to retrieve the mapping for the given key, returning `fallback` if no such mapping is present.

<a id="Std___ExtHashMap___getKey"></a>

**def**

```text
Std.ExtHashMap.getKey.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtHashMap α β) (a : α) (h : a ∈ m) : α
```

Retrieves the key from the mapping that matches `a`. Ensures that such a mapping exists by requiring a proof of `a ∈ m`. The result is guaranteed to be pointer equal to the key in the map.

<a id="Std___ExtHashMap___getKey___"></a>

**def**

```text
Std.ExtHashMap.getKey!.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] [Inhabited α]
  (m : Std.ExtHashMap α β) (a : α) : α
```

Checks if a mapping for the given key exists and returns the key if it does, otherwise panics. If no panic occurs the result is guaranteed to be pointer equal to the key in the map.

<a id="Std___ExtHashMap___getKey___-next"></a>

**def**

```text
Std.ExtHashMap.getKey?.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtHashMap α β) (a : α) : Option α
```

Checks if a mapping for the given key exists and returns the key if it does, otherwise `none`. The result in the `some` case is guaranteed to be pointer equal to the key in the map.

<a id="Std___ExtHashMap___getKeyD"></a>

**def**

```text
Std.ExtHashMap.getKeyD.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtHashMap α β) (a fallback : α) : α
```

Checks if a mapping for the given key exists and returns the key if it does, otherwise `fallback`. If a mapping exists the result is guaranteed to be pointer equal to the key in the map.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Extensional-Hash-Maps--Modification"></a>
#### 20.19.4.4. Modification

<a id="Std___ExtHashMap___alter"></a>

**def**

```text
Std.ExtHashMap.alter.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtHashMap α β) (a : α) (f : Option β → Option β) :
  Std.ExtHashMap α β
```

Modifies in place the value associated with a given key, allowing creating new values and deleting values via an `Option` valued replacement function.

This function ensures that the value is used linearly.

<a id="Std___ExtHashMap___modify"></a>

**def**

```text
Std.ExtHashMap.modify.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtHashMap α β) (a : α) (f : β → β) : Std.ExtHashMap α β
```

Modifies in place the value associated with a given key.

This function ensures that the value is used linearly.

<a id="Std___ExtHashMap___containsThenInsert"></a>

**def**

```text
Std.ExtHashMap.containsThenInsert.{u, v} {α : Type u} {β : Type v}
  {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtHashMap α β) (a : α) (b : β) : Bool × Std.ExtHashMap α β
```

Checks whether a key is present in a map, and unconditionally inserts a value for the key.

Equivalent to (but potentially faster than) calling `contains` followed by `insert`.

<a id="Std___ExtHashMap___containsThenInsertIfNew"></a>

**def**

```text
Std.ExtHashMap.containsThenInsertIfNew.{u, v} {α : Type u} {β : Type v}
  {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtHashMap α β) (a : α) (b : β) : Bool × Std.ExtHashMap α β
```

Checks whether a key is present in a map and inserts a value for the key if it was not found.

If the returned `Bool` is `true`, then the returned map is unaltered. If the `Bool` is `false`, then the returned map has a new value inserted.

Equivalent to (but potentially faster than) calling `contains` followed by `insertIfNew`.

<a id="Std___ExtHashMap___erase"></a>

**def**

```text
Std.ExtHashMap.erase.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtHashMap α β) (a : α) : Std.ExtHashMap α β
```

Removes the mapping for the given key if it exists.

<a id="Std___ExtHashMap___filter"></a>

**def**

```text
Std.ExtHashMap.filter.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] (f : α → β → Bool)
  (m : Std.ExtHashMap α β) : Std.ExtHashMap α β
```

Removes all mappings of the hash map for which the given function returns `false`.

<a id="Std___ExtHashMap___filterMap"></a>

**def**

```text
Std.ExtHashMap.filterMap.{u, v, w} {α : Type u} {β : Type v}
  {γ : Type w} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α]
  [LawfulHashable α] (f : α → β → Option γ) (m : Std.ExtHashMap α β) :
  Std.ExtHashMap α γ
```

Updates the values of the hash map by applying the given function to all mappings, keeping only those mappings where the function returns `some` value.

<a id="Std___ExtHashMap___insert"></a>

**def**

```text
Std.ExtHashMap.insert.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtHashMap α β) (a : α) (b : β) : Std.ExtHashMap α β
```

Inserts the given mapping into the map. If there is already a mapping for the given key, then both key and value will be replaced.

Note: this replacement behavior is true for `HashMap`, `DHashMap`, `HashMap.Raw` and `DHashMap.Raw`. The `insert` function on `HashSet` and `HashSet.Raw` behaves differently: it will return the set unchanged if a matching key is already present.

<a id="Std___ExtHashMap___insertIfNew"></a>

**def**

```text
Std.ExtHashMap.insertIfNew.{u, v} {α : Type u} {β : Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtHashMap α β) (a : α) (b : β) : Std.ExtHashMap α β
```

If there is no mapping for the given key, inserts the given mapping into the map. Otherwise, returns the map unaltered.

<a id="Std___ExtHashMap___getThenInsertIfNew___"></a>

**def**

```text
Std.ExtHashMap.getThenInsertIfNew?.{u, v} {α : Type u} {β : Type v}
  {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtHashMap α β) (a : α) (b : β) :
  Option β × Std.ExtHashMap α β
```

Checks whether a key is present in a map, returning the associated value, and inserts a value for the key if it was not found.

If the returned value is `some v`, then the returned map is unaltered. If it is `none`, then the returned map has a new value inserted.

Equivalent to (but potentially faster than) calling `get?` followed by `insertIfNew`.

<a id="Std___ExtHashMap___insertMany"></a>

**def**

```text
Std.ExtHashMap.insertMany.{u, v, w} {α : Type u} {β : Type v}
  {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  {ρ : Type w} [ForIn Id ρ (α × β)] (m : Std.ExtHashMap α β) (l : ρ) :
  Std.ExtHashMap α β
```

Inserts multiple mappings into the hash map by iterating over the given collection and calling `insert`. If the same key appears multiple times, the last occurrence takes precedence.

Note: this precedence behavior is true for `HashMap`, `DHashMap`, `HashMap.Raw` and `DHashMap.Raw`. The `insertMany` function on `HashSet` and `HashSet.Raw` behaves differently: it will prefer the first appearance.

<a id="Std___ExtHashMap___insertManyIfNewUnit"></a>

**def**

```text
Std.ExtHashMap.insertManyIfNewUnit.{u, w} {α : Type u} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] {ρ : Type w}
  [ForIn Id ρ α] (m : Std.ExtHashMap α Unit) (l : ρ) :
  Std.ExtHashMap α Unit
```

Inserts multiple keys with the value `()` into the hash map by iterating over the given collection and calling `insertIfNew`. If the same key appears multiple times, the first occurrence takes precedence.

This is mainly useful to implement `HashSet.insertMany`, so if you are considering using this, `HashSet` or `HashSet.Raw` might be a better fit for you.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Extensional-Hash-Maps--Iteration"></a>
#### 20.19.4.5. Iteration

<a id="Std___ExtHashMap___map"></a>

**def**

```text
Std.ExtHashMap.map.{u, v, w} {α : Type u} {β : Type v} {γ : Type w}
  {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (f : α → β → γ) (m : Std.ExtHashMap α β) : Std.ExtHashMap α γ
```

Updates the values of the hash map by applying the given function to all mappings.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Extensional-Hash-Maps--Conversion"></a>
#### 20.19.4.6. Conversion

<a id="Std___ExtHashMap___ofList"></a>

**def**

```text
Std.ExtHashMap.ofList.{u, v} {α : Type u} {β : Type v} [BEq α]
  [Hashable α] (l : List (α × β)) : Std.ExtHashMap α β
```

Creates a hash map from a list of mappings. If the same key appears multiple times, the last occurrence takes precedence.

<a id="Std___ExtHashMap___unitOfArray"></a>

**def**

```text
Std.ExtHashMap.unitOfArray.{u} {α : Type u} [BEq α] [Hashable α]
  (l : Array α) : Std.ExtHashMap α Unit
```

Creates a hash map from an array of keys, associating the value `()` with each key.

This is mainly useful to implement `HashSet.ofArray`, so if you are considering using this, `HashSet` or `HashSet.Raw` might be a better fit for you.

<a id="Std___ExtHashMap___unitOfList"></a>

**def**

```text
Std.ExtHashMap.unitOfList.{u} {α : Type u} [BEq α] [Hashable α]
  (l : List α) : Std.ExtHashMap α Unit
```

Creates a hash map from a list of keys, associating the value `()` with each key.

This is mainly useful to implement `HashSet.ofList`, so if you are considering using this, `HashSet` or `HashSet.Raw` might be a better fit for you.

<a id="ExtDHashMap"></a>
### 20.19.5. Extensional Dependent Hash Maps

The declarations in this section should be imported using `import Std.ExtDHashMap`.

<a id="Std___ExtDHashMap"></a>

**structure**

```text
Std.ExtDHashMap.{u, v} (α : Type u) (β : α → Type v) [BEq α]
  [Hashable α] : Type (max u v)
```

Extensional dependent hash maps.

This is a simple separate-chaining hash table. The data of the hash map consists of a cached size and an array of buckets, where each bucket is a linked list of key-value pairs. The number of buckets is always a power of two. The hash map doubles its size upon inserting an element such that the number of elements is more than 75% of the number of buckets.

The hash table is backed by an `Array`. Users should make sure that the hash map is used linearly to avoid expensive copies.

The hash map uses `==` (provided by the `BEq` typeclass) to compare keys and `hash` (provided by the `Hashable` typeclass) to hash them. To ensure that the operations behave as expected, `==` must be an equivalence relation and `a == b` must imply `hash a = hash b` (see also the `EquivBEq` and `LawfulHashable` typeclasses). Both of these conditions are automatic if the BEq instance is lawful, i.e., if `a == b` implies `a = b`.

In contrast to regular dependent hash maps, `Std.ExtDHashMap` offers several extensionality lemmas and therefore has more lemmas about equality of hash maps. This however also makes it lose the ability to iterate freely over the hash map.

These hash maps contain a bundled well-formedness invariant, which means that they cannot be used in nested inductive types. For these use cases, `Std.DHashMap.Raw` and `Std.DHashMap.Raw.WF` unbundle the invariant from the hash map. When in doubt, prefer `DHashMap` over `DHashMap.Raw`.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Extensional-Dependent-Hash-Maps--Creation"></a>
#### 20.19.5.1. Creation

<a id="Std___ExtDHashMap___emptyWithCapacity"></a>

**def**

```text
Std.ExtDHashMap.emptyWithCapacity.{u, v} {α : Type u} {β : α → Type v}
  [BEq α] [Hashable α] (capacity : Nat := 8) : Std.ExtDHashMap α β
```

Creates a new empty hash map. The optional parameter `capacity` can be supplied to presize the map so that it can hold the given number of mappings without reallocating. It is also possible to use the empty collection notations `∅` and `{}` to create an empty hash map with the default capacity.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Extensional-Dependent-Hash-Maps--Properties"></a>
#### 20.19.5.2. Properties

<a id="Std___ExtDHashMap___size"></a>

**def**

```text
Std.ExtDHashMap.size.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtDHashMap α β) : Nat
```

The number of mappings present in the hash map

<a id="Std___ExtDHashMap___isEmpty"></a>

**def**

```text
Std.ExtDHashMap.isEmpty.{u, v} {α : Type u} {β : α → Type v}
  {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtDHashMap α β) : Bool
```

Returns `true` if the hash map contains no mappings.

Note that if your `BEq` instance is not reflexive or your `Hashable` instance is not lawful, then it is possible that this function returns `false` even though is not possible to get anything out of the hash map.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Extensional-Dependent-Hash-Maps--Queries"></a>
#### 20.19.5.3. Queries

<a id="Std___ExtDHashMap___contains"></a>

**def**

```text
Std.ExtDHashMap.contains.{u, v} {α : Type u} {β : α → Type v}
  {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtDHashMap α β) (a : α) : Bool
```

Returns `true` if there is a mapping for the given key. There is also a `Prop`-valued version of this: `a ∈ m` is equivalent to `m.contains a = true`.

Observe that this is different behavior than for lists: for lists, `∈` uses `=` and `contains` uses `==` for comparisons, while for hash maps, both use `==`.

<a id="Std___ExtDHashMap___get"></a>

**def**

```text
Std.ExtDHashMap.get.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.ExtDHashMap α β) (a : α)
  (h : a ∈ m) : β a
```

Retrieves the mapping for the given key. Ensures that such a mapping exists by requiring a proof of `a ∈ m`.

Uses the `LawfulBEq` instance to cast the retrieved value to the correct type.

<a id="Std___ExtDHashMap___get___"></a>

**def**

```text
Std.ExtDHashMap.get!.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.ExtDHashMap α β) (a : α)
  [Inhabited (β a)] : β a
```

Tries to retrieve the mapping for the given key, panicking if no such mapping is present.

Uses the `LawfulBEq` instance to cast the retrieved value to the correct type.

<a id="Std___ExtDHashMap___get___-next"></a>

**def**

```text
Std.ExtDHashMap.get?.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.ExtDHashMap α β) (a : α) :
  Option (β a)
```

Tries to retrieve the mapping for the given key, returning `none` if no such mapping is present.

Uses the `LawfulBEq` instance to cast the retrieved value to the correct type.

<a id="Std___ExtDHashMap___getD"></a>

**def**

```text
Std.ExtDHashMap.getD.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.ExtDHashMap α β) (a : α)
  (fallback : β a) : β a
```

Tries to retrieve the mapping for the given key, returning `fallback` if no such mapping is present.

Uses the `LawfulBEq` instance to cast the retrieved value to the correct type.

<a id="Std___ExtDHashMap___getKey"></a>

**def**

```text
Std.ExtDHashMap.getKey.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtDHashMap α β) (a : α) (h : a ∈ m) : α
```

Retrieves the key from the mapping that matches `a`. Ensures that such a mapping exists by requiring a proof of `a ∈ m`. The result is guaranteed to be pointer equal to the key in the map.

<a id="Std___ExtDHashMap___getKey___"></a>

**def**

```text
Std.ExtDHashMap.getKey!.{u, v} {α : Type u} {β : α → Type v}
  {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  [Inhabited α] (m : Std.ExtDHashMap α β) (a : α) : α
```

Checks if a mapping for the given key exists and returns the key if it does, otherwise panics. If no panic occurs the result is guaranteed to be pointer equal to the key in the map.

<a id="Std___ExtDHashMap___getKey___-next"></a>

**def**

```text
Std.ExtDHashMap.getKey?.{u, v} {α : Type u} {β : α → Type v}
  {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtDHashMap α β) (a : α) : Option α
```

Checks if a mapping for the given key exists and returns the key if it does, otherwise `none`. The result in the `some` case is guaranteed to be pointer equal to the key in the map.

<a id="Std___ExtDHashMap___getKeyD"></a>

**def**

```text
Std.ExtDHashMap.getKeyD.{u, v} {α : Type u} {β : α → Type v}
  {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtDHashMap α β) (a fallback : α) : α
```

Checks if a mapping for the given key exists and returns the key if it does, otherwise `fallback`. If a mapping exists the result is guaranteed to be pointer equal to the key in the map.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Extensional-Dependent-Hash-Maps--Modification"></a>
#### 20.19.5.4. Modification

<a id="Std___ExtDHashMap___alter"></a>

**def**

```text
Std.ExtDHashMap.alter.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.ExtDHashMap α β) (a : α)
  (f : Option (β a) → Option (β a)) : Std.ExtDHashMap α β
```

Modifies in place the value associated with a given key, allowing creating new values and deleting values via an `Option` valued replacement function.

This function ensures that the value is used linearly.

<a id="Std___ExtDHashMap___modify"></a>

**def**

```text
Std.ExtDHashMap.modify.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [LawfulBEq α] (m : Std.ExtDHashMap α β) (a : α)
  (f : β a → β a) : Std.ExtDHashMap α β
```

Modifies in place the value associated with a given key.

This function ensures that the value is used linearly.

<a id="Std___ExtDHashMap___containsThenInsert"></a>

**def**

```text
Std.ExtDHashMap.containsThenInsert.{u, v} {α : Type u} {β : α → Type v}
  {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtDHashMap α β) (a : α) (b : β a) :
  Bool × Std.ExtDHashMap α β
```

Checks whether a key is present in a map, and unconditionally inserts a value for the key.

Equivalent to (but potentially faster than) calling `contains` followed by `insert`.

<a id="Std___ExtDHashMap___containsThenInsertIfNew"></a>

**def**

```text
Std.ExtDHashMap.containsThenInsertIfNew.{u, v} {α : Type u}
  {β : α → Type v} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α]
  [LawfulHashable α] (m : Std.ExtDHashMap α β) (a : α) (b : β a) :
  Bool × Std.ExtDHashMap α β
```

Checks whether a key is present in a map and inserts a value for the key if it was not found.

If the returned `Bool` is `true`, then the returned map is unaltered. If the `Bool` is `false`, then the returned map has a new value inserted.

Equivalent to (but potentially faster than) calling `contains` followed by `insertIfNew`.

<a id="Std___ExtDHashMap___erase"></a>

**def**

```text
Std.ExtDHashMap.erase.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtDHashMap α β) (a : α) : Std.ExtDHashMap α β
```

Removes the mapping for the given key if it exists.

<a id="Std___ExtDHashMap___filter"></a>

**def**

```text
Std.ExtDHashMap.filter.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (f : (a : α) → β a → Bool) (m : Std.ExtDHashMap α β) :
  Std.ExtDHashMap α β
```

Removes all mappings of the hash map for which the given function returns `false`.

<a id="Std___ExtDHashMap___filterMap"></a>

**def**

```text
Std.ExtDHashMap.filterMap.{u, v, w} {α : Type u} {β : α → Type v}
  {γ : α → Type w} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α]
  [LawfulHashable α] (f : (a : α) → β a → Option (γ a))
  (m : Std.ExtDHashMap α β) : Std.ExtDHashMap α γ
```

Updates the values of the hash map by applying the given function to all mappings, keeping only those mappings where the function returns `some` value.

<a id="Std___ExtDHashMap___insert"></a>

**def**

```text
Std.ExtDHashMap.insert.{u, v} {α : Type u} {β : α → Type v} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtDHashMap α β) (a : α) (b : β a) : Std.ExtDHashMap α β
```

Inserts the given mapping into the map. If there is already a mapping for the given key, then both key and value will be replaced.

Note: this replacement behavior is true for `HashMap`, `DHashMap`, `HashMap.Raw` and `DHashMap.Raw`. The `insert` function on `HashSet` and `HashSet.Raw` behaves differently: it will return the set unchanged if a matching key is already present.

<a id="Std___ExtDHashMap___insertIfNew"></a>

**def**

```text
Std.ExtDHashMap.insertIfNew.{u, v} {α : Type u} {β : α → Type v}
  {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtDHashMap α β) (a : α) (b : β a) : Std.ExtDHashMap α β
```

If there is no mapping for the given key, inserts the given mapping into the map. Otherwise, returns the map unaltered.

<a id="Std___ExtDHashMap___getThenInsertIfNew___"></a>

**def**

```text
Std.ExtDHashMap.getThenInsertIfNew?.{u, v} {α : Type u} {β : α → Type v}
  {x✝ : BEq α} {x✝¹ : Hashable α} [LawfulBEq α]
  (m : Std.ExtDHashMap α β) (a : α) (b : β a) :
  Option (β a) × Std.ExtDHashMap α β
```

Checks whether a key is present in a map, returning the associated value, and inserts a value for the key if it was not found.

If the returned value is `some v`, then the returned map is unaltered. If it is `none`, then the returned map has a new value inserted.

Equivalent to (but potentially faster than) calling `get?` followed by `insertIfNew`.

Uses the `LawfulBEq` instance to cast the retrieved value to the correct type.

<a id="Std___ExtDHashMap___insertMany"></a>

**def**

```text
Std.ExtDHashMap.insertMany.{u, v, w} {α : Type u} {β : α → Type v}
  {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  {ρ : Type w} [ForIn Id ρ ((a : α) × β a)] (m : Std.ExtDHashMap α β)
  (l : ρ) : Std.ExtDHashMap α β
```

Inserts multiple mappings into the hash map by iterating over the given collection and calling `insert`. If the same key appears multiple times, the last occurrence takes precedence.

Note: this precedence behavior is true for `HashMap`, `DHashMap`, `HashMap.Raw` and `DHashMap.Raw`. The `insertMany` function on `HashSet` and `HashSet.Raw` behaves differently: it will prefer the first appearance.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Extensional-Dependent-Hash-Maps--Iteration"></a>
#### 20.19.5.5. Iteration

<a id="Std___ExtDHashMap___map"></a>

**def**

```text
Std.ExtDHashMap.map.{u, v, w} {α : Type u} {β : α → Type v}
  {γ : α → Type w} {x✝ : BEq α} {x✝¹ : Hashable α} [EquivBEq α]
  [LawfulHashable α] (f : (a : α) → β a → γ a)
  (m : Std.ExtDHashMap α β) : Std.ExtDHashMap α γ
```

Updates the values of the hash map by applying the given function to all mappings.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Extensional-Dependent-Hash-Maps--Conversion"></a>
#### 20.19.5.6. Conversion

<a id="Std___ExtDHashMap___ofList"></a>

**def**

```text
Std.ExtDHashMap.ofList.{u, v} {α : Type u} {β : α → Type v} [BEq α]
  [Hashable α] (l : List ((a : α) × β a)) : Std.ExtDHashMap α β
```

Creates a hash map from a list of mappings. If the same key appears multiple times, the last occurrence takes precedence.

<a id="HashSet"></a>
### 20.19.6. Hash Sets

<a id="Std___HashSet___mk"></a>

**structure**

```text
Std.HashSet.{u} (α : Type u) [BEq α] [Hashable α] : Type u
```

Hash sets.

This is a simple separate-chaining hash table. The data of the hash set consists of a cached size and an array of buckets, where each bucket is a linked list of keys. The number of buckets is always a power of two. The hash set doubles its size upon inserting an element such that the number of elements is more than 75% of the number of buckets.

The hash table is backed by an `Array`. Users should make sure that the hash set is used linearly to avoid expensive copies.

The hash set uses `==` (provided by the `BEq` typeclass) to compare elements and `hash` (provided by the `Hashable` typeclass) to hash them. To ensure that the operations behave as expected, `==` should be an equivalence relation and `a == b` should imply `hash a = hash b` (see also the `EquivBEq` and `LawfulHashable` typeclasses). Both of these conditions are automatic if the BEq instance is lawful, i.e., if `a == b` implies `a = b`.

These hash sets contain a bundled well-formedness invariant, which means that they cannot be used in nested inductive types. For these use cases, `Std.Data.HashSet.Raw` and `Std.Data.HashSet.Raw.WF` unbundle the invariant from the hash set. When in doubt, prefer `HashSet` over `HashSet.Raw`.

**Constructor**

```text
Std.HashSet.mk.{u}
```

**Fields**

```text
inner : Std.HashMap α Unit
```

Internal implementation detail of the hash set.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Hash-Sets--Creation"></a>
#### 20.19.6.1. Creation

<a id="Std___HashSet___emptyWithCapacity"></a>

**def**

```text
Std.HashSet.emptyWithCapacity.{u} {α : Type u} [BEq α] [Hashable α]
  (capacity : Nat := 8) : Std.HashSet α
```

Creates a new empty hash set. The optional parameter `capacity` can be supplied to presize the set so that it can hold the given number of elements without reallocating. It is also possible to use the empty collection notations `∅` and `{}` to create an empty hash set with the default capacity.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Hash-Sets--Properties"></a>
#### 20.19.6.2. Properties

<a id="Std___HashSet___isEmpty"></a>

**def**

```text
Std.HashSet.isEmpty.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  (m : Std.HashSet α) : Bool
```

Returns `true` if the hash set contains no elements.

Note that if your `BEq` instance is not reflexive or your `Hashable` instance is not lawful, then it is possible that this function returns `false` even though `m.contains a = false` for all `a`.

<a id="Std___HashSet___size"></a>

**def**

```text
Std.HashSet.size.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  (m : Std.HashSet α) : Nat
```

The number of elements present in the set

<a id="Std___HashSet___Equiv___mk"></a>

**structure**

```text
Std.HashSet.Equiv.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  (m₁ m₂ : Std.HashSet α) : Prop
```

Two hash sets are equivalent in the sense of `Equiv` iff all their values are equal.

**Constructor**

```text
Std.HashSet.Equiv.mk.{u}
```

**Fields**

```text
inner : m₁.inner.Equiv m₂.inner
```

Internal implementation detail of the hash map

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Equivalence**

The relation `HashSet.Equiv` can also be written with an infix operator, which is scoped to its namespace:

<a id="Std___HashMap____FLQQ_term____m__FLQQ_-next"></a>

```ebnf
term ::= ...
    | term ~m term
```

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Hash-Sets--Queries"></a>
#### 20.19.6.3. Queries

<a id="Std___HashSet___contains"></a>

**def**

```text
Std.HashSet.contains.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  (m : Std.HashSet α) (a : α) : Bool
```

Returns `true` if the given key is present in the set. There is also a `Prop`-valued version of this: `a ∈ m` is equivalent to `m.contains a = true`.

Observe that this is different behavior than for lists: for lists, `∈` uses `=` and `contains` use `==` for comparisons, while for hash sets, both use `==`.

<a id="Std___HashSet___get"></a>

**def**

```text
Std.HashSet.get.{u} {α : Type u} [BEq α] [Hashable α]
  (m : Std.HashSet α) (a : α) (h : a ∈ m) : α
```

Retrieves the key from the set that matches `a`. Ensures that such a key exists by requiring a proof of `a ∈ m`. The result is guaranteed to be pointer equal to the key in the set.

<a id="Std___HashSet___get___"></a>

**def**

```text
Std.HashSet.get!.{u} {α : Type u} [BEq α] [Hashable α] [Inhabited α]
  (m : Std.HashSet α) (a : α) : α
```

Checks if given key is contained and returns the key if it is, otherwise panics. If no panic occurs the result is guaranteed to be pointer equal to the key in the set.

<a id="Std___HashSet___get___-next"></a>

**def**

```text
Std.HashSet.get?.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  (m : Std.HashSet α) (a : α) : Option α
```

Checks if given key is contained and returns the key if it is, otherwise `none`. The result in the `some` case is guaranteed to be pointer equal to the key in the set.

<a id="Std___HashSet___getD"></a>

**def**

```text
Std.HashSet.getD.{u} {α : Type u} [BEq α] [Hashable α]
  (m : Std.HashSet α) (a fallback : α) : α
```

Checks if given key is contained and returns the key if it is, otherwise `fallback`. If they key is contained the result is guaranteed to be pointer equal to the key in the set.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Hash-Sets--Modification"></a>
#### 20.19.6.4. Modification

<a id="Std___HashSet___insert"></a>

**def**

```text
Std.HashSet.insert.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  (m : Std.HashSet α) (a : α) : Std.HashSet α
```

Inserts the given element into the set. If the hash set already contains an element that is equal (with regard to `==`) to the given element, then the hash set is returned unchanged.

Note: this non-replacement behavior is true for `HashSet` and `HashSet.Raw`. The `insert` function on `HashMap`, `DHashMap`, `HashMap.Raw` and `DHashMap.Raw` behaves differently: it will overwrite an existing mapping.

<a id="Std___HashSet___insertMany"></a>

**def**

```text
Std.HashSet.insertMany.{u, v} {α : Type u} {x✝ : BEq α}
  {x✝¹ : Hashable α} {ρ : Type v} [ForIn Id ρ α] (m : Std.HashSet α)
  (l : ρ) : Std.HashSet α
```

Inserts multiple mappings into the hash set by iterating over the given collection and calling `insert`. If the same key appears multiple times, the first occurrence takes precedence.

Note: this precedence behavior is true for `HashSet` and `HashSet.Raw`. The `insertMany` function on `HashMap`, `DHashMap`, `HashMap.Raw` and `DHashMap.Raw` behaves differently: it will prefer the last appearance.

<a id="Std___HashSet___erase"></a>

**def**

```text
Std.HashSet.erase.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  (m : Std.HashSet α) (a : α) : Std.HashSet α
```

Removes the element if it exists.

<a id="Std___HashSet___filter"></a>

**def**

```text
Std.HashSet.filter.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  (f : α → Bool) (m : Std.HashSet α) : Std.HashSet α
```

Removes all elements from the hash set for which the given function returns `false`.

<a id="Std___HashSet___containsThenInsert"></a>

**def**

```text
Std.HashSet.containsThenInsert.{u} {α : Type u} {x✝ : BEq α}
  {x✝¹ : Hashable α} (m : Std.HashSet α) (a : α) : Bool × Std.HashSet α
```

Checks whether an element is present in a set and inserts the element if it was not found. If the hash set already contains an element that is equal (with regard to `==`) to the given element, then the hash set is returned unchanged.

Equivalent to (but potentially faster than) calling `contains` followed by `insert`.

<a id="Std___HashSet___partition"></a>

**def**

```text
Std.HashSet.partition.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  (f : α → Bool) (m : Std.HashSet α) : Std.HashSet α × Std.HashSet α
```

Partition a hashset into two hashsets based on a predicate.

<a id="Std___HashSet___union"></a>

**def**

```text
Std.HashSet.union.{u} {α : Type u} [BEq α] [Hashable α]
  (m₁ m₂ : Std.HashSet α) : Std.HashSet α
```

Computes the union of the given hash sets.

This function always merges the smaller set into the larger set, so the expected runtime is `O(min(m₁.size, m₂.size))`.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Hash-Sets--Iteration"></a>
#### 20.19.6.5. Iteration

<a id="Std___HashSet___iter"></a>

**def**

```text
Std.HashSet.iter.{u} {α : Type u} [BEq α] [Hashable α]
  (m : Std.HashSet α) : Std.Iter α
```

Returns a finite iterator over the elements of a hash set. The iterator yields the elements of the set in order and then terminates.

**Termination properties:**

- `Finite` instance: always
- `Productive` instance: always

<a id="Std___HashSet___all"></a>

**def**

```text
Std.HashSet.all.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  (m : Std.HashSet α) (p : α → Bool) : Bool
```

Check if all elements satisfy the predicate, short-circuiting if a predicate fails.

<a id="Std___HashSet___any"></a>

**def**

```text
Std.HashSet.any.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  (m : Std.HashSet α) (p : α → Bool) : Bool
```

Check if any element satisfies the predicate, short-circuiting if a predicate succeeds.

<a id="Std___HashSet___fold"></a>

**def**

```text
Std.HashSet.fold.{u, v} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  {β : Type v} (f : β → α → β) (init : β) (m : Std.HashSet α) : β
```

Folds the given function over the elements of the hash set in some order.

<a id="Std___HashSet___foldM"></a>

**def**

```text
Std.HashSet.foldM.{u, v, w} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  {m : Type v → Type w} [Monad m] {β : Type v} (f : β → α → m β)
  (init : β) (b : Std.HashSet α) : m β
```

Monadically computes a value by folding the given function over the elements in the hash set in some order.

<a id="Std___HashSet___forIn"></a>

**def**

```text
Std.HashSet.forIn.{u, v, w} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  {m : Type v → Type w} [Monad m] {β : Type v}
  (f : α → β → m (ForInStep β)) (init : β) (b : Std.HashSet α) : m β
```

Support for the `for` loop construct in `do` blocks.

<a id="Std___HashSet___forM"></a>

**def**

```text
Std.HashSet.forM.{u, v, w} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  {m : Type v → Type w} [Monad m] (f : α → m PUnit)
  (b : Std.HashSet α) : m PUnit
```

Carries out a monadic action on each element in the hash set in some order.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Hash-Sets--Conversion"></a>
#### 20.19.6.6. Conversion

<a id="Std___HashSet___ofList"></a>

**def**

```text
Std.HashSet.ofList.{u} {α : Type u} [BEq α] [Hashable α] (l : List α) :
  Std.HashSet α
```

Creates a hash set from a list of elements. Note that unlike repeatedly calling `insert`, if the collection contains multiple elements that are equal (with regard to `==`), then the last element in the collection will be present in the returned hash set.

<a id="Std___HashSet___toList"></a>

**def**

```text
Std.HashSet.toList.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  (m : Std.HashSet α) : List α
```

Transforms the hash set into a list of elements in some order.

<a id="Std___HashSet___ofArray"></a>

**def**

```text
Std.HashSet.ofArray.{u} {α : Type u} [BEq α] [Hashable α]
  (l : Array α) : Std.HashSet α
```

Creates a hash set from an array of elements. Note that unlike repeatedly calling `insert`, if the collection contains multiple elements that are equal (with regard to `==`), then the last element in the collection will be present in the returned hash set.

<a id="Std___HashSet___toArray"></a>

**def**

```text
Std.HashSet.toArray.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  (m : Std.HashSet α) : Array α
```

Transforms the hash set into an array of elements in some order.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Hash-Sets--Unbundled-Variants"></a>
#### 20.19.6.7. Unbundled Variants

Unbundled maps separate well-formedness proofs from data. This is primarily useful when defining [nested inductive types](index.md#raw-data). To use these variants, import the modules `Std.HashSet.Raw` and `Std.HashSet.RawLemmas`.

<a id="Std___HashSet___Raw___mk"></a>

**structure**

```text
Std.HashSet.Raw.{u} (α : Type u) : Type u
```

Hash sets without a bundled well-formedness invariant, suitable for use in nested inductive types. The well-formedness invariant is called `Raw.WF`. When in doubt, prefer `HashSet` over `HashSet.Raw`. Lemmas about the operations on `Std.Data.HashSet.Raw` are available in the module `Std.Data.HashSet.RawLemmas`.

This is a simple separate-chaining hash table. The data of the hash set consists of a cached size and an array of buckets, where each bucket is a linked list of keys. The number of buckets is always a power of two. The hash set doubles its size upon inserting an element such that the number of elements is more than 75% of the number of buckets.

The hash table is backed by an `Array`. Users should make sure that the hash set is used linearly to avoid expensive copies.

The hash set uses `==` (provided by the `BEq` typeclass) to compare elements and `hash` (provided by the `Hashable` typeclass) to hash them. To ensure that the operations behave as expected, `==` should be an equivalence relation and `a == b` should imply `hash a = hash b` (see also the `EquivBEq` and `LawfulHashable` typeclasses). Both of these conditions are automatic if the BEq instance is lawful, i.e., if `a == b` implies `a = b`.

**Constructor**

```text
Std.HashSet.Raw.mk.{u}
```

**Fields**

```text
inner : Std.HashMap.Raw α Unit
```

Internal implementation detail of the hash set.

<a id="Std___HashSet___Raw___WF___mk"></a>

**structure**

```text
Std.HashSet.Raw.WF.{u} {α : Type u} [BEq α] [Hashable α]
  (m : Std.HashSet.Raw α) : Prop
```

Well-formedness predicate for hash sets. Users of `HashSet` will not need to interact with this. Users of `HashSet.Raw` will need to provide proofs of `WF` to lemmas and should use lemmas like `WF.empty` and `WF.insert` (which are always named exactly like the operations they are about) to show that set operations preserve well-formedness.

**Constructor**

```text
Std.HashSet.Raw.WF.mk.{u}
```

**Fields**

```text
out : m.inner.WF
```

Internal implementation detail of the hash set

<a id="ExtHashSet"></a>
### 20.19.7. Extensional Hash Sets

<a id="Std___ExtHashSet___mk"></a>

**structure**

```text
Std.ExtHashSet.{u} (α : Type u) [BEq α] [Hashable α] : Type u
```

Hash sets.

This is a simple separate-chaining hash table. The data of the hash set consists of a cached size and an array of buckets, where each bucket is a linked list of keys. The number of buckets is always a power of two. The hash set doubles its size upon inserting an element such that the number of elements is more than 75% of the number of buckets.

The hash table is backed by an `Array`. Users should make sure that the hash set is used linearly to avoid expensive copies.

The hash set uses `==` (provided by the `BEq` typeclass) to compare elements and `hash` (provided by the `Hashable` typeclass) to hash them. To ensure that the operations behave as expected, `==` should be an equivalence relation and `a == b` should imply `hash a = hash b` (see also the `EquivBEq` and `LawfulHashable` typeclasses). Both of these conditions are automatic if the BEq instance is lawful, i.e., if `a == b` implies `a = b`.

In contrast to regular hash sets, `Std.ExtHashSet` offers several extensionality lemmas and therefore has more lemmas about equality of hash maps. This however also makes it lose the ability to iterate freely over hash sets.

These hash sets contain a bundled well-formedness invariant, which means that they cannot be used in nested inductive types. For these use cases, `Std.HashSet.Raw` and `Std.HashSet.Raw.WF` unbundle the invariant from the hash set. When in doubt, prefer `HashSet` or `ExtHashSet` over `HashSet.Raw`.

**Constructor**

```text
Std.ExtHashSet.mk.{u}
```

**Fields**

```text
inner : Std.ExtHashMap α Unit
```

Internal implementation detail of the hash set.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Extensional-Hash-Sets--Creation"></a>
#### 20.19.7.1. Creation

<a id="Std___ExtHashSet___emptyWithCapacity"></a>

**def**

```text
Std.ExtHashSet.emptyWithCapacity.{u} {α : Type u} [BEq α] [Hashable α]
  (capacity : Nat := 8) : Std.ExtHashSet α
```

Creates a new empty hash set. The optional parameter `capacity` can be supplied to presize the set so that it can hold the given number of elements without reallocating. It is also possible to use the empty collection notations `∅` and `{}` to create an empty hash set with the default capacity.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Extensional-Hash-Sets--Properties"></a>
#### 20.19.7.2. Properties

<a id="Std___ExtHashSet___isEmpty"></a>

**def**

```text
Std.ExtHashSet.isEmpty.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashSet α) : Bool
```

Returns `true` if the hash set contains no elements.

Note that if your `BEq` instance is not reflexive or your `Hashable` instance is not lawful, then it is possible that this function returns `false` even though `m.contains a = false` for all `a`.

<a id="Std___ExtHashSet___size"></a>

**def**

```text
Std.ExtHashSet.size.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashSet α) : Nat
```

The number of elements present in the set

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Extensional-Hash-Sets--Queries"></a>
#### 20.19.7.3. Queries

<a id="Std___ExtHashSet___contains"></a>

**def**

```text
Std.ExtHashSet.contains.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashSet α) (a : α) : Bool
```

Returns `true` if the given key is present in the set. There is also a `Prop`-valued version of this: `a ∈ m` is equivalent to `m.contains a = true`.

Observe that this is different behavior than for lists: for lists, `∈` uses `=` and `contains` use `==` for comparisons, while for hash sets, both use `==`.

<a id="Std___ExtHashSet___get"></a>

**def**

```text
Std.ExtHashSet.get.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashSet α) (a : α)
  (h : a ∈ m) : α
```

Retrieves the key from the set that matches `a`. Ensures that such a key exists by requiring a proof of `a ∈ m`. The result is guaranteed to be pointer equal to the key in the set.

<a id="Std___ExtHashSet___get___"></a>

**def**

```text
Std.ExtHashSet.get!.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  [EquivBEq α] [LawfulHashable α] [Inhabited α] (m : Std.ExtHashSet α)
  (a : α) : α
```

Checks if given key is contained and returns the key if it is, otherwise panics. If no panic occurs the result is guaranteed to be pointer equal to the key in the set.

<a id="Std___ExtHashSet___get___-next"></a>

**def**

```text
Std.ExtHashSet.get?.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashSet α) (a : α) :
  Option α
```

Checks if given key is contained and returns the key if it is, otherwise `none`. The result in the `some` case is guaranteed to be pointer equal to the key in the set.

<a id="Std___ExtHashSet___getD"></a>

**def**

```text
Std.ExtHashSet.getD.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashSet α)
  (a fallback : α) : α
```

Checks if given key is contained and returns the key if it is, otherwise `fallback`. If they key is contained the result is guaranteed to be pointer equal to the key in the set.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Extensional-Hash-Sets--Modification"></a>
#### 20.19.7.4. Modification

<a id="Std___ExtHashSet___insert"></a>

**def**

```text
Std.ExtHashSet.insert.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashSet α) (a : α) :
  Std.ExtHashSet α
```

Inserts the given element into the set. If the hash set already contains an element that is equal (with regard to `==`) to the given element, then the hash set is returned unchanged.

Note: this non-replacement behavior is true for `ExtHashSet` and `ExtHashSet.Raw`. The `insert` function on `ExtHashMap`, `DExtHashMap`, `ExtHashMap.Raw` and `DExtHashMap.Raw` behaves differently: it will overwrite an existing mapping.

<a id="Std___ExtHashSet___insertMany"></a>

**def**

```text
Std.ExtHashSet.insertMany.{u, v} {α : Type u} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α] {ρ : Type v}
  [ForIn Id ρ α] (m : Std.ExtHashSet α) (l : ρ) : Std.ExtHashSet α
```

Inserts multiple mappings into the hash set by iterating over the given collection and calling `insert`. If the same key appears multiple times, the first occurrence takes precedence.

Note: this precedence behavior is true for `ExtHashSet` and `ExtHashSet.Raw`. The `insertMany` function on `ExtHashMap`, `DExtHashMap`, `ExtHashMap.Raw` and `DExtHashMap.Raw` behaves differently: it will prefer the last appearance.

<a id="Std___ExtHashSet___erase"></a>

**def**

```text
Std.ExtHashSet.erase.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  [EquivBEq α] [LawfulHashable α] (m : Std.ExtHashSet α) (a : α) :
  Std.ExtHashSet α
```

Removes the element if it exists.

<a id="Std___ExtHashSet___filter"></a>

**def**

```text
Std.ExtHashSet.filter.{u} {α : Type u} {x✝ : BEq α} {x✝¹ : Hashable α}
  [EquivBEq α] [LawfulHashable α] (f : α → Bool)
  (m : Std.ExtHashSet α) : Std.ExtHashSet α
```

Removes all elements from the hash set for which the given function returns `false`.

<a id="Std___ExtHashSet___containsThenInsert"></a>

**def**

```text
Std.ExtHashSet.containsThenInsert.{u} {α : Type u} {x✝ : BEq α}
  {x✝¹ : Hashable α} [EquivBEq α] [LawfulHashable α]
  (m : Std.ExtHashSet α) (a : α) : Bool × Std.ExtHashSet α
```

Checks whether an element is present in a set and inserts the element if it was not found. If the hash set already contains an element that is equal (with regard to `==`) to the given element, then the hash set is returned unchanged.

Equivalent to (but potentially faster than) calling `contains` followed by `insert`.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Extensional-Hash-Sets--Conversion"></a>
#### 20.19.7.5. Conversion

<a id="Std___ExtHashSet___ofList"></a>

**def**

```text
Std.ExtHashSet.ofList.{u} {α : Type u} [BEq α] [Hashable α]
  (l : List α) : Std.ExtHashSet α
```

Creates a hash set from a list of elements. Note that unlike repeatedly calling `insert`, if the collection contains multiple elements that are equal (with regard to `==`), then the last element in the collection will be present in the returned hash set.

<a id="Std___ExtHashSet___ofArray"></a>

**def**

```text
Std.ExtHashSet.ofArray.{u} {α : Type u} [BEq α] [Hashable α]
  (l : Array α) : Std.ExtHashSet α
```

Creates a hash set from an array of elements. Note that unlike repeatedly calling `insert`, if the collection contains multiple elements that are equal (with regard to `==`), then the last element in the collection will be present in the returned hash set.

<a id="TreeMap"></a>
### 20.19.8. Tree-Based Maps

The declarations in this section should be imported using `import Std.TreeMap`.

<a id="Std___TreeMap"></a>

**structure**

```text
Std.TreeMap.{u, v} (α : Type u) (β : Type v)
  (cmp : α → α → Ordering := by exact compare) : Type (max u v)
```

Tree maps.

A tree map stores an assignment of keys to values. It depends on a comparator function that defines an ordering on the keys and provides efficient order-dependent queries, such as retrieval of the minimum or maximum.

To ensure that the operations behave as expected, the comparator function `cmp` should satisfy certain laws that ensure a consistent ordering:

- If `a` is less than (or equal) to `b`, then `b` is greater than (or equal) to `a` and vice versa (see the `OrientedCmp` typeclass).
- If `a` is less than or equal to `b` and `b` is, in turn, less than or equal to `c`, then `a` is less than or equal to `c` (see the `TransCmp` typeclass).

Keys for which `cmp a b = Ordering.eq` are considered the same, i.e., there can be only one entry with key either `a` or `b` in a tree map. Looking up either `a` or `b` always yields the same entry, if any is present.

To avoid expensive copies, users should make sure that the tree map is used linearly.

Internally, the tree maps are represented as size-bounded trees, a type of self-balancing binary search tree with efficient order statistic lookups.

For use in proofs, the type `Std.ExtTreeMap` of extensional tree maps should be preferred. This type comes with several extensionality lemmas and provides the same functions but requires a `TransCmp` instance to work with.

These tree maps contain a bundled well-formedness invariant, which means that they cannot be used in nested inductive types. For these use cases, `Std.TreeMap.Raw` and `Std.TreeMap.Raw.WF` unbundle the invariant from the tree map. When in doubt, prefer `TreeMap` over `TreeMap.Raw`.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Tree-Based-Maps--Creation"></a>
#### 20.19.8.1. Creation

<a id="Std___TreeMap___empty"></a>

**def**

```text
Std.TreeMap.empty.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} : Std.TreeMap α β cmp
```

Creates a new empty tree map. It is also possible and recommended to use the empty collection notations `∅` and `{}` to create an empty tree map. `simp` replaces `empty` with `∅`.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Tree-Based-Maps--Properties"></a>
#### 20.19.8.2. Properties

<a id="Std___TreeMap___size"></a>

**def**

```text
Std.TreeMap.size.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : Nat
```

Returns the number of mappings present in the map.

<a id="Std___TreeMap___isEmpty"></a>

**def**

```text
Std.TreeMap.isEmpty.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : Bool
```

Returns `true` if the tree map contains no mappings.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Tree-Based-Maps--Queries"></a>
#### 20.19.8.3. Queries

<a id="Std___TreeMap___contains"></a>

**def**

```text
Std.TreeMap.contains.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (l : Std.TreeMap α β cmp) (a : α) : Bool
```

Returns `true` if there is a mapping for the given key `a` or a key that is equal to `a` according to the comparator `cmp`. There is also a `Prop`-valued version of this: `a ∈ t` is equivalent to `t.contains a = true`.

Observe that this is different behavior than for lists: for lists, `∈` uses `=` and `contains` uses `==` for equality checks, while for tree maps, both use the given comparator `cmp`.

<a id="Std___TreeMap___get"></a>

**def**

```text
Std.TreeMap.get.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α)
  (h : a ∈ t) : β
```

Given a proof that a mapping for the given key is present, retrieves the mapping for the given key.

Uses the `LawfulEqCmp` instance to cast the retrieved value to the correct type.

<a id="Std___TreeMap___get___"></a>

**def**

```text
Std.TreeMap.get!.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Inhabited β] (t : Std.TreeMap α β cmp)
  (a : α) : β
```

Tries to retrieve the mapping for the given key, panicking if no such mapping is present.

Uses the `LawfulEqCmp` instance to cast the retrieved value to the correct type.

<a id="Std___TreeMap___get___-next"></a>

**def**

```text
Std.TreeMap.get?.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α) : Option β
```

Tries to retrieve the mapping for the given key, returning `none` if no such mapping is present.

Uses the `LawfulEqCmp` instance to cast the retrieved value to the correct type.

<a id="Std___TreeMap___getD"></a>

**def**

```text
Std.TreeMap.getD.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α)
  (fallback : β) : β
```

Tries to retrieve the mapping for the given key, returning `fallback` if no such mapping is present.

Uses the `LawfulEqCmp` instance to cast the retrieved value to the correct type.

<a id="Std___TreeMap___getKey"></a>

**def**

```text
Std.TreeMap.getKey.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α)
  (h : a ∈ t) : α
```

Retrieves the key from the mapping that matches `a`. Ensures that such a mapping exists by requiring a proof of `a ∈ m`. The result is guaranteed to be pointer equal to the key in the map.

<a id="Std___TreeMap___getKey___"></a>

**def**

```text
Std.TreeMap.getKey!.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeMap α β cmp)
  (a : α) : α
```

Checks if a mapping for the given key exists and returns the key if it does, otherwise panics. If no panic occurs the result is guaranteed to be pointer equal to the key in the map.

<a id="Std___TreeMap___getKey___-next"></a>

**def**

```text
Std.TreeMap.getKey?.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α) : Option α
```

Checks if a mapping for the given key exists and returns the key if it does, otherwise `none`. The result in the `some` case is guaranteed to be pointer equal to the key in the map.

<a id="Std___TreeMap___getKeyD"></a>

**def**

```text
Std.TreeMap.getKeyD.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a fallback : α) :
  α
```

Checks if a mapping for the given key exists and returns the key if it does, otherwise `fallback`. If a mapping exists the result is guaranteed to be pointer equal to the key in the map.

<a id="Std___TreeMap___keys"></a>

**def**

```text
Std.TreeMap.keys.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : List α
```

Returns a list of all keys present in the tree map in ascending order.

<a id="Std___TreeMap___keysArray"></a>

**def**

```text
Std.TreeMap.keysArray.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : Array α
```

Returns an array of all keys present in the tree map in ascending order.

<a id="Std___TreeMap___values"></a>

**def**

```text
Std.TreeMap.values.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : List β
```

Returns a list of all values present in the tree map in ascending order.

<a id="Std___TreeMap___valuesArray"></a>

**def**

```text
Std.TreeMap.valuesArray.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : Array β
```

Returns an array of all values present in the tree map in ascending order.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Tree-Based-Maps--Queries--Ordering-Based-Queries"></a>
##### 20.19.8.3.1. Ordering-Based Queries

<a id="Std___TreeMap___entryAtIdx"></a>

**def**

```text
Std.TreeMap.entryAtIdx.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (n : Nat)
  (h : n < t.size) : α × β
```

Returns the key-value pair with the `n`-th smallest key.

<a id="Std___TreeMap___entryAtIdx___"></a>

**def**

```text
Std.TreeMap.entryAtIdx!.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Inhabited (α × β)] (t : Std.TreeMap α β cmp)
  (n : Nat) : α × β
```

Returns the key-value pair with the `n`-th smallest key, or panics if `n` is at least `t.size`.

<a id="Std___TreeMap___entryAtIdx___-next"></a>

**def**

```text
Std.TreeMap.entryAtIdx?.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (n : Nat) :
  Option (α × β)
```

Returns the key-value pair with the `n`-th smallest key, or `none` if `n` is at least `t.size`.

<a id="Std___TreeMap___entryAtIdxD"></a>

**def**

```text
Std.TreeMap.entryAtIdxD.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (n : Nat)
  (fallback : α × β) : α × β
```

Returns the key-value pair with the `n`-th smallest key, or `fallback` if `n` is at least `t.size`.

<a id="Std___TreeMap___getEntryGE"></a>

**def**

```text
Std.TreeMap.getEntryGE.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Std.TransCmp cmp] (t : Std.TreeMap α β cmp)
  (k : α) (h : ∃ a, a ∈ t ∧ (cmp a k).isGE = true) : α × β
```

Given a proof that such a mapping exists, retrieves the key-value pair with the smallest key that is greater than or equal to the given key.

<a id="Std___TreeMap___getEntryGE___"></a>

**def**

```text
Std.TreeMap.getEntryGE!.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Inhabited (α × β)] (t : Std.TreeMap α β cmp)
  (k : α) : α × β
```

Tries to retrieve the key-value pair with the smallest key that is greater than or equal to the given key, panicking if no such pair exists.

<a id="Std___TreeMap___getEntryGE___-next"></a>

**def**

```text
Std.TreeMap.getEntryGE?.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α) :
  Option (α × β)
```

Tries to retrieve the key-value pair with the smallest key that is greater than or equal to the given key, returning `none` if no such pair exists.

<a id="Std___TreeMap___getEntryGED"></a>

**def**

```text
Std.TreeMap.getEntryGED.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α)
  (fallback : α × β) : α × β
```

Tries to retrieve the key-value pair with the smallest key that is greater than or equal to the given key, returning `fallback` if no such pair exists.

<a id="Std___TreeMap___getEntryGT"></a>

**def**

```text
Std.TreeMap.getEntryGT.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Std.TransCmp cmp] (t : Std.TreeMap α β cmp)
  (k : α) (h : ∃ a, a ∈ t ∧ cmp a k = Ordering.gt) : α × β
```

Given a proof that such a mapping exists, retrieves the key-value pair with the smallest key that is greater than the given key.

<a id="Std___TreeMap___getEntryGT___"></a>

**def**

```text
Std.TreeMap.getEntryGT!.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Inhabited (α × β)] (t : Std.TreeMap α β cmp)
  (k : α) : α × β
```

Tries to retrieve the key-value pair with the smallest key that is greater than the given key, panicking if no such pair exists.

<a id="Std___TreeMap___getEntryGT___-next"></a>

**def**

```text
Std.TreeMap.getEntryGT?.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α) :
  Option (α × β)
```

Tries to retrieve the key-value pair with the smallest key that is greater than the given key, returning `none` if no such pair exists.

<a id="Std___TreeMap___getEntryGTD"></a>

**def**

```text
Std.TreeMap.getEntryGTD.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α)
  (fallback : α × β) : α × β
```

Tries to retrieve the key-value pair with the smallest key that is greater than the given key, returning `fallback` if no such pair exists.

<a id="Std___TreeMap___getEntryLE"></a>

**def**

```text
Std.TreeMap.getEntryLE.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Std.TransCmp cmp] (t : Std.TreeMap α β cmp)
  (k : α) (h : ∃ a, a ∈ t ∧ (cmp a k).isLE = true) : α × β
```

Given a proof that such a mapping exists, retrieves the key-value pair with the largest key that is less than or equal to the given key.

<a id="Std___TreeMap___getEntryLE___"></a>

**def**

```text
Std.TreeMap.getEntryLE!.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Inhabited (α × β)] (t : Std.TreeMap α β cmp)
  (k : α) : α × β
```

Tries to retrieve the key-value pair with the largest key that is less than or equal to the given key, panicking if no such pair exists.

<a id="Std___TreeMap___getEntryLE___-next"></a>

**def**

```text
Std.TreeMap.getEntryLE?.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α) :
  Option (α × β)
```

Tries to retrieve the key-value pair with the largest key that is less than or equal to the given key, returning `none` if no such pair exists.

<a id="Std___TreeMap___getEntryLED"></a>

**def**

```text
Std.TreeMap.getEntryLED.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α)
  (fallback : α × β) : α × β
```

Tries to retrieve the key-value pair with the largest key that is less than or equal to the given key, returning `fallback` if no such pair exists.

<a id="Std___TreeMap___getEntryLT"></a>

**def**

```text
Std.TreeMap.getEntryLT.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Std.TransCmp cmp] (t : Std.TreeMap α β cmp)
  (k : α) (h : ∃ a, a ∈ t ∧ cmp a k = Ordering.lt) : α × β
```

Given a proof that such a mapping exists, retrieves the key-value pair with the largest key that is less than the given key.

<a id="Std___TreeMap___getEntryLT___"></a>

**def**

```text
Std.TreeMap.getEntryLT!.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Inhabited (α × β)] (t : Std.TreeMap α β cmp)
  (k : α) : α × β
```

Tries to retrieve the key-value pair with the largest key that is less than the given key, panicking if no such pair exists.

<a id="Std___TreeMap___getEntryLT___-next"></a>

**def**

```text
Std.TreeMap.getEntryLT?.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α) :
  Option (α × β)
```

Tries to retrieve the key-value pair with the largest key that is less than the given key, returning `none` if no such pair exists.

<a id="Std___TreeMap___getEntryLTD"></a>

**def**

```text
Std.TreeMap.getEntryLTD.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α)
  (fallback : α × β) : α × β
```

Tries to retrieve the key-value pair with the largest key that is less than the given key, returning `fallback` if no such pair exists.

<a id="Std___TreeMap___getKeyGE"></a>

**def**

```text
Std.TreeMap.getKeyGE.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Std.TransCmp cmp] (t : Std.TreeMap α β cmp)
  (k : α) (h : ∃ a, a ∈ t ∧ (cmp a k).isGE = true) : α
```

Given a proof that such a mapping exists, retrieves the smallest key that is greater than or equal to the given key.

<a id="Std___TreeMap___getKeyGE___"></a>

**def**

```text
Std.TreeMap.getKeyGE!.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeMap α β cmp)
  (k : α) : α
```

Tries to retrieve the smallest key that is greater than or equal to the given key, panicking if no such key exists.

<a id="Std___TreeMap___getKeyGE___-next"></a>

**def**

```text
Std.TreeMap.getKeyGE?.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α) : Option α
```

Tries to retrieve the smallest key that is greater than or equal to the given key, returning `none` if no such key exists.

<a id="Std___TreeMap___getKeyGED"></a>

**def**

```text
Std.TreeMap.getKeyGED.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k fallback : α) :
  α
```

Tries to retrieve the smallest key that is greater than or equal to the given key, returning `fallback` if no such key exists.

<a id="Std___TreeMap___getKeyGT"></a>

**def**

```text
Std.TreeMap.getKeyGT.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Std.TransCmp cmp] (t : Std.TreeMap α β cmp)
  (k : α) (h : ∃ a, a ∈ t ∧ cmp a k = Ordering.gt) : α
```

Given a proof that such a mapping exists, retrieves the smallest key that is greater than the given key.

<a id="Std___TreeMap___getKeyGT___"></a>

**def**

```text
Std.TreeMap.getKeyGT!.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeMap α β cmp)
  (k : α) : α
```

Tries to retrieve the smallest key that is greater than the given key, panicking if no such key exists.

<a id="Std___TreeMap___getKeyGT___-next"></a>

**def**

```text
Std.TreeMap.getKeyGT?.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α) : Option α
```

Tries to retrieve the smallest key that is greater than the given key, returning `none` if no such key exists.

<a id="Std___TreeMap___getKeyGTD"></a>

**def**

```text
Std.TreeMap.getKeyGTD.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k fallback : α) :
  α
```

Tries to retrieve the smallest key that is greater than the given key, returning `fallback` if no such key exists.

<a id="Std___TreeMap___getKeyLE"></a>

**def**

```text
Std.TreeMap.getKeyLE.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Std.TransCmp cmp] (t : Std.TreeMap α β cmp)
  (k : α) (h : ∃ a, a ∈ t ∧ (cmp a k).isLE = true) : α
```

Given a proof that such a mapping exists, retrieves the largest key that is less than or equal to the given key.

<a id="Std___TreeMap___getKeyLE___"></a>

**def**

```text
Std.TreeMap.getKeyLE!.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeMap α β cmp)
  (k : α) : α
```

Tries to retrieve the largest key that is less than or equal to the given key, panicking if no such key exists.

<a id="Std___TreeMap___getKeyLE___-next"></a>

**def**

```text
Std.TreeMap.getKeyLE?.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α) : Option α
```

Tries to retrieve the largest key that is less than or equal to the given key, returning `none` if no such key exists.

<a id="Std___TreeMap___getKeyLED"></a>

**def**

```text
Std.TreeMap.getKeyLED.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k fallback : α) :
  α
```

Tries to retrieve the largest key that is less than or equal to the given key, returning `fallback` if no such key exists.

<a id="Std___TreeMap___getKeyLT"></a>

**def**

```text
Std.TreeMap.getKeyLT.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Std.TransCmp cmp] (t : Std.TreeMap α β cmp)
  (k : α) (h : ∃ a, a ∈ t ∧ cmp a k = Ordering.lt) : α
```

Given a proof that such a mapping exists, retrieves the largest key that is less than the given key.

<a id="Std___TreeMap___getKeyLT___"></a>

**def**

```text
Std.TreeMap.getKeyLT!.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeMap α β cmp)
  (k : α) : α
```

Tries to retrieve the largest key that is less than the given key, panicking if no such key exists.

<a id="Std___TreeMap___getKeyLT___-next"></a>

**def**

```text
Std.TreeMap.getKeyLT?.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k : α) : Option α
```

Tries to retrieve the largest key that is less than the given key, returning `none` if no such key exists.

<a id="Std___TreeMap___getKeyLTD"></a>

**def**

```text
Std.TreeMap.getKeyLTD.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (k fallback : α) :
  α
```

Tries to retrieve the largest key that is less than the given key, returning `fallback` if no such key exists.

<a id="Std___TreeMap___keyAtIdx"></a>

**def**

```text
Std.TreeMap.keyAtIdx.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (n : Nat)
  (h : n < t.size) : α
```

Returns the `n`-th smallest key.

<a id="Std___TreeMap___keyAtIdx___"></a>

**def**

```text
Std.TreeMap.keyAtIdx!.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeMap α β cmp)
  (n : Nat) : α
```

Returns the `n`-th smallest key, or panics if `n` is at least `t.size`.

<a id="Std___TreeMap___keyAtIdx___-next"></a>

**def**

```text
Std.TreeMap.keyAtIdx?.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (n : Nat) :
  Option α
```

Returns the `n`-th smallest key, or `none` if `n` is at least `t.size`.

<a id="Std___TreeMap___keyAtIdxD"></a>

**def**

```text
Std.TreeMap.keyAtIdxD.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (n : Nat)
  (fallback : α) : α
```

Returns the `n`-th smallest key, or `fallback` if `n` is at least `t.size`.

<a id="Std___TreeMap___minEntry"></a>

**def**

```text
Std.TreeMap.minEntry.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp)
  (h : t.isEmpty = false) : α × β
```

Given a proof that the tree map is not empty, retrieves the key-value pair with the smallest key.

<a id="Std___TreeMap___minEntry___"></a>

**def**

```text
Std.TreeMap.minEntry!.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Inhabited (α × β)]
  (t : Std.TreeMap α β cmp) : α × β
```

Tries to retrieve the key-value pair with the smallest key in the tree map, panicking if the map is empty.

<a id="Std___TreeMap___minEntry___-next"></a>

**def**

```text
Std.TreeMap.minEntry?.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : Option (α × β)
```

Tries to retrieve the key-value pair with the smallest key in the tree map, returning `none` if the map is empty.

<a id="Std___TreeMap___minEntryD"></a>

**def**

```text
Std.TreeMap.minEntryD.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp)
  (fallback : α × β) : α × β
```

Tries to retrieve the key-value pair with the smallest key in the tree map, returning `fallback` if the tree map is empty.

<a id="Std___TreeMap___minKey"></a>

**def**

```text
Std.TreeMap.minKey.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp)
  (h : t.isEmpty = false) : α
```

Given a proof that the tree map is not empty, retrieves the smallest key.

<a id="Std___TreeMap___minKey___"></a>

**def**

```text
Std.TreeMap.minKey!.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeMap α β cmp) : α
```

Tries to retrieve the smallest key in the tree map, panicking if the map is empty.

<a id="Std___TreeMap___minKey___-next"></a>

**def**

```text
Std.TreeMap.minKey?.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : Option α
```

Tries to retrieve the smallest key in the tree map, returning `none` if the map is empty.

<a id="Std___TreeMap___minKeyD"></a>

**def**

```text
Std.TreeMap.minKeyD.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (fallback : α) : α
```

Tries to retrieve the smallest key in the tree map, returning `fallback` if the tree map is empty.

<a id="Std___TreeMap___maxEntry"></a>

**def**

```text
Std.TreeMap.maxEntry.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp)
  (h : t.isEmpty = false) : α × β
```

Given a proof that the tree map is not empty, retrieves the key-value pair with the largest key.

<a id="Std___TreeMap___maxEntry___"></a>

**def**

```text
Std.TreeMap.maxEntry!.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Inhabited (α × β)]
  (t : Std.TreeMap α β cmp) : α × β
```

Tries to retrieve the key-value pair with the largest key in the tree map, panicking if the map is empty.

<a id="Std___TreeMap___maxEntry___-next"></a>

**def**

```text
Std.TreeMap.maxEntry?.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : Option (α × β)
```

Tries to retrieve the key-value pair with the largest key in the tree map, returning `none` if the map is empty.

<a id="Std___TreeMap___maxEntryD"></a>

**def**

```text
Std.TreeMap.maxEntryD.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp)
  (fallback : α × β) : α × β
```

Tries to retrieve the key-value pair with the largest key in the tree map, returning `fallback` if the tree map is empty.

<a id="Std___TreeMap___maxKey"></a>

**def**

```text
Std.TreeMap.maxKey.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp)
  (h : t.isEmpty = false) : α
```

Given a proof that the tree map is not empty, retrieves the largest key.

<a id="Std___TreeMap___maxKey___"></a>

**def**

```text
Std.TreeMap.maxKey!.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} [Inhabited α] (t : Std.TreeMap α β cmp) : α
```

Tries to retrieve the largest key in the tree map, panicking if the map is empty.

<a id="Std___TreeMap___maxKey___-next"></a>

**def**

```text
Std.TreeMap.maxKey?.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : Option α
```

Tries to retrieve the largest key in the tree map, returning `none` if the map is empty.

<a id="Std___TreeMap___maxKeyD"></a>

**def**

```text
Std.TreeMap.maxKeyD.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (fallback : α) : α
```

Tries to retrieve the largest key in the tree map, returning `fallback` if the tree map is empty.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Tree-Based-Maps--Modification"></a>
#### 20.19.8.4. Modification

<a id="Std___TreeMap___alter"></a>

**def**

```text
Std.TreeMap.alter.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α)
  (f : Option β → Option β) : Std.TreeMap α β cmp
```

Modifies in place the value associated with a given key, allowing creating new values and deleting values via an `Option` valued replacement function.

This function ensures that the value is used linearly.

<a id="Std___TreeMap___modify"></a>

**def**

```text
Std.TreeMap.modify.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α)
  (f : β → β) : Std.TreeMap α β cmp
```

Modifies in place the value associated with a given key.

This function ensures that the value is used linearly.

<a id="Std___TreeMap___containsThenInsert"></a>

**def**

```text
Std.TreeMap.containsThenInsert.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α) (b : β) :
  Bool × Std.TreeMap α β cmp
```

Checks whether a key is present in a map and unconditionally inserts a value for the key.

Equivalent to (but potentially faster than) calling `contains` followed by `insert`.

<a id="Std___TreeMap___containsThenInsertIfNew"></a>

**def**

```text
Std.TreeMap.containsThenInsertIfNew.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α) (b : β) :
  Bool × Std.TreeMap α β cmp
```

Checks whether a key is present in a map and inserts a value for the key if it was not found. If the returned `Bool` is `true`, then the returned map is unaltered. If the `Bool` is `false`, then the returned map has a new value inserted.

Equivalent to (but potentially faster than) calling `contains` followed by `insertIfNew`.

<a id="Std___TreeMap___erase"></a>

**def**

```text
Std.TreeMap.erase.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α) :
  Std.TreeMap α β cmp
```

Removes the mapping for the given key if it exists.

<a id="Std___TreeMap___eraseMany"></a>

**def**

```text
Std.TreeMap.eraseMany.{u, v, u_1} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} {ρ : Type u_1} [ForIn Id ρ α]
  (t : Std.TreeMap α β cmp) (l : ρ) : Std.TreeMap α β cmp
```

Erases multiple mappings from the tree map by iterating over the given collection and calling `erase`.

<a id="Std___TreeMap___filter"></a>

**def**

```text
Std.TreeMap.filter.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (f : α → β → Bool)
  (m : Std.TreeMap α β cmp) : Std.TreeMap α β cmp
```

Removes all mappings of the map for which the given function returns `false`.

<a id="Std___TreeMap___filterMap"></a>

**def**

```text
Std.TreeMap.filterMap.{u, v, w} {α : Type u} {β : Type v} {γ : Type w}
  {cmp : α → α → Ordering} (f : α → β → Option γ)
  (m : Std.TreeMap α β cmp) : Std.TreeMap α γ cmp
```

Updates the values of the map by applying the given function to all mappings, keeping only those mappings where the function returns `some` value.

<a id="Std___TreeMap___insert"></a>

**def**

```text
Std.TreeMap.insert.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (l : Std.TreeMap α β cmp) (a : α) (b : β) :
  Std.TreeMap α β cmp
```

Inserts the given mapping into the map. If there is already a mapping for the given key, then both key and value will be replaced.

<a id="Std___TreeMap___insertIfNew"></a>

**def**

```text
Std.TreeMap.insertIfNew.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α) (b : β) :
  Std.TreeMap α β cmp
```

If there is no mapping for the given key, inserts the given mapping into the map. Otherwise, returns the map unaltered.

<a id="Std___TreeMap___getThenInsertIfNew___"></a>

**def**

```text
Std.TreeMap.getThenInsertIfNew?.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) (a : α) (b : β) :
  Option β × Std.TreeMap α β cmp
```

Checks whether a key is present in a map, returning the associated value, and inserts a value for the key if it was not found.

If the returned value is `some v`, then the returned map is unaltered. If it is `none`, then the returned map has a new value inserted.

Equivalent to (but potentially faster than) calling `get?` followed by `insertIfNew`.

Uses the `LawfulEqCmp` instance to cast the retrieved value to the correct type.

<a id="Std___TreeMap___insertMany"></a>

**def**

```text
Std.TreeMap.insertMany.{u, v, u_1} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} {ρ : Type u_1} [ForIn Id ρ (α × β)]
  (t : Std.TreeMap α β cmp) (l : ρ) : Std.TreeMap α β cmp
```

Inserts multiple mappings into the tree map by iterating over the given collection and calling `insert`. If the same key appears multiple times, the last occurrence takes precedence.

Note: this precedence behavior is true for `TreeMap`, `DTreeMap`, `TreeMap.Raw` and `DTreeMap.Raw`. The `insertMany` function on `TreeSet` and `TreeSet.Raw` behaves differently: it will prefer the first appearance.

<a id="Std___TreeMap___insertManyIfNewUnit"></a>

**def**

```text
Std.TreeMap.insertManyIfNewUnit.{u, u_1} {α : Type u}
  {cmp : α → α → Ordering} {ρ : Type u_1} [ForIn Id ρ α]
  (t : Std.TreeMap α Unit cmp) (l : ρ) : Std.TreeMap α Unit cmp
```

Inserts multiple elements into the tree map by iterating over the given collection and calling `insertIfNew`. If the same key appears multiple times, the first occurrence takes precedence.

<a id="Std___TreeMap___mergeWith"></a>

**def**

```text
Std.TreeMap.mergeWith.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (mergeFn : α → β → β → β)
  (t₁ t₂ : Std.TreeMap α β cmp) : Std.TreeMap α β cmp
```

Returns a map that contains all mappings of `t₁` and `t₂`. In case that both maps contain the same key `k` with respect to `cmp`, the provided function is used to determine the new value from the respective values in `t₁` and `t₂`.

This function ensures that `t₁` is used linearly. It also uses the individual values in `t₁` linearly if the merge function uses the second argument (i.e. the first of type `β a`) linearly. Hence, as long as `t₁` is unshared, the performance characteristics follow the following imperative description: Iterate over all mappings in `t₂`, inserting them into `t₁` if `t₁` does not contain a conflicting mapping yet. If `t₁` does contain a conflicting mapping, use the given merge function to merge the mapping in `t₂` into the mapping in `t₁`. Then return `t₁`.

Hence, the runtime of this method scales logarithmically in the size of `t₁` and linearly in the size of `t₂` as long as `t₁` is unshared.

<a id="Std___TreeMap___partition"></a>

**def**

```text
Std.TreeMap.partition.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (f : α → β → Bool)
  (t : Std.TreeMap α β cmp) : Std.TreeMap α β cmp × Std.TreeMap α β cmp
```

Partitions a tree map into two tree maps based on a predicate.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Tree-Based-Maps--Iteration"></a>
#### 20.19.8.5. Iteration

<a id="Std___TreeMap___iter"></a>

**def**

```text
Std.TreeMap.iter.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (m : Std.TreeMap α β cmp) : Std.Iter (α × β)
```

Returns a finite iterator over the entries of a tree map. The iterator yields the elements of the map in order and then terminates.

**Termination properties:**

- `Finite` instance: always
- `Productive` instance: always

<a id="Std___TreeMap___keysIter"></a>

**def**

```text
Std.TreeMap.keysIter.{u} {α β : Type u} {cmp : α → α → Ordering}
  (m : Std.TreeMap α β cmp) : Std.Iter α
```

Returns a finite iterator over the keys of a tree map. The iterator yields the keys in order and then terminates.

The key and value types must live in the same universe.

**Termination properties:**

- `Finite` instance: always
- `Productive` instance: always

<a id="Std___TreeMap___valuesIter"></a>

**def**

```text
Std.TreeMap.valuesIter.{u} {α β : Type u} {cmp : α → α → Ordering}
  (m : Std.TreeMap α β cmp) : Std.Iter β
```

Returns a finite iterator over the values of a tree map. The iterator yields the values in order and then terminates.

The key and value types must live in the same universe.

**Termination properties:**

- `Finite` instance: always
- `Productive` instance: always

<a id="Std___TreeMap___map"></a>

**def**

```text
Std.TreeMap.map.{u, v, w} {α : Type u} {β : Type v} {γ : Type w}
  {cmp : α → α → Ordering} (f : α → β → γ) (t : Std.TreeMap α β cmp) :
  Std.TreeMap α γ cmp
```

Updates the values of the map by applying the given function to all mappings.

<a id="Std___TreeMap___all"></a>

**def**

```text
Std.TreeMap.all.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp)
  (p : α → β → Bool) : Bool
```

Check if all elements satisfy the predicate, short-circuiting if a predicate fails.

<a id="Std___TreeMap___any"></a>

**def**

```text
Std.TreeMap.any.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp)
  (p : α → β → Bool) : Bool
```

Check if any element satisfies the predicate, short-circuiting if a predicate fails.

<a id="Std___TreeMap___foldl"></a>

**def**

```text
Std.TreeMap.foldl.{u, v, w} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} {δ : Type w} (f : δ → α → β → δ) (init : δ)
  (t : Std.TreeMap α β cmp) : δ
```

Folds the given function over the mappings in the map in ascending order.

<a id="Std___TreeMap___foldlM"></a>

**def**

```text
Std.TreeMap.foldlM.{u, v, w, w₂} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} {δ : Type w} {m : Type w → Type w₂} [Monad m]
  (f : δ → α → β → m δ) (init : δ) (t : Std.TreeMap α β cmp) : m δ
```

Folds the given monadic function over the mappings in the map in ascending order.

<a id="Std___TreeMap___foldr"></a>

**def**

```text
Std.TreeMap.foldr.{u, v, w} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} {δ : Type w} (f : α → β → δ → δ) (init : δ)
  (t : Std.TreeMap α β cmp) : δ
```

Folds the given function over the mappings in the map in descending order.

<a id="Std___TreeMap___foldrM"></a>

**def**

```text
Std.TreeMap.foldrM.{u, v, w, w₂} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} {δ : Type w} {m : Type w → Type w₂} [Monad m]
  (f : α → β → δ → m δ) (init : δ) (t : Std.TreeMap α β cmp) : m δ
```

Folds the given monadic function over the mappings in the map in descending order.

<a id="Std___TreeMap___forIn"></a>

**def**

```text
Std.TreeMap.forIn.{u, v, w, w₂} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} {δ : Type w} {m : Type w → Type w₂} [Monad m]
  (f : α → β → δ → m (ForInStep δ)) (init : δ)
  (t : Std.TreeMap α β cmp) : m δ
```

Support for the `for` loop construct in `do` blocks. Iteration happens in ascending order.

<a id="Std___TreeMap___forM"></a>

**def**

```text
Std.TreeMap.forM.{u, v, w, w₂} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} {m : Type w → Type w₂} [Monad m]
  (f : α → β → m PUnit) (t : Std.TreeMap α β cmp) : m PUnit
```

Carries out a monadic action on each mapping in the tree map in ascending order.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Tree-Based-Maps--Conversion"></a>
#### 20.19.8.6. Conversion

<a id="Std___TreeMap___ofList"></a>

**def**

```text
Std.TreeMap.ofList.{u, v} {α : Type u} {β : Type v} (l : List (α × β))
  (cmp : α → α → Ordering := by exact compare) : Std.TreeMap α β cmp
```

Transforms a list of mappings into a tree map.

<a id="Std___TreeMap___toList"></a>

**def**

```text
Std.TreeMap.toList.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : List (α × β)
```

Transforms the tree map into a list of mappings in ascending order.

<a id="Std___TreeMap___ofArray"></a>

**def**

```text
Std.TreeMap.ofArray.{u, v} {α : Type u} {β : Type v} (a : Array (α × β))
  (cmp : α → α → Ordering := by exact compare) : Std.TreeMap α β cmp
```

Transforms a list of mappings into a tree map.

<a id="Std___TreeMap___toArray"></a>

**def**

```text
Std.TreeMap.toArray.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap α β cmp) : Array (α × β)
```

Transforms the tree map into a list of mappings in ascending order.

<a id="Std___TreeMap___unitOfArray"></a>

**def**

```text
Std.TreeMap.unitOfArray.{u} {α : Type u} (a : Array α)
  (cmp : α → α → Ordering := by exact compare) : Std.TreeMap α Unit cmp
```

Transforms an array of keys into a tree map.

<a id="Std___TreeMap___unitOfList"></a>

**def**

```text
Std.TreeMap.unitOfList.{u} {α : Type u} (l : List α)
  (cmp : α → α → Ordering := by exact compare) : Std.TreeMap α Unit cmp
```

Transforms a list of keys into a tree map.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Tree-Based-Maps--Conversion--Unbundled-Variants"></a>
##### 20.19.8.6.1. Unbundled Variants

Unbundled maps separate well-formedness proofs from data. This is primarily useful when defining [nested inductive types](index.md#raw-data). To use these variants, import the module `Std.TreeMap.Raw`.

<a id="Std___TreeMap___Raw___mk"></a>

**structure**

```text
Std.TreeMap.Raw.{u, v} (α : Type u) (β : Type v)
  (cmp : α → α → Ordering := by exact compare) : Type (max u v)
```

Tree maps without a bundled well-formedness invariant, suitable for use in nested inductive types. The well-formedness invariant is called `Raw.WF`. When in doubt, prefer `TreeMap` over `TreeMap.Raw`. Lemmas about the operations on `Std.TreeMap.Raw` are available in the module `Std.Data.TreeMap.Raw.Lemmas`.

A tree map stores an assignment of keys to values. It depends on a comparator function that defines an ordering on the keys and provides efficient order-dependent queries, such as retrieval of the minimum or maximum.

To ensure that the operations behave as expected, the comparator function `cmp` should satisfy certain laws that ensure a consistent ordering:

- If `a` is less than (or equal) to `b`, then `b` is greater than (or equal) to `a` and vice versa (see the `OrientedCmp` typeclass).
- If `a` is less than or equal to `b` and `b` is, in turn, less than or equal to `c`, then `a` is less than or equal to `c` (see the `TransCmp` typeclass).

Keys for which `cmp a b = Ordering.eq` are considered the same, i.e., there can be only one entry with key either `a` or `b` in a tree map. Looking up either `a` or `b` always yields the same entry, if any is present.

To avoid expensive copies, users should make sure that the tree map is used linearly.

Internally, the tree maps are represented as size-bounded trees, a type of self-balancing binary search tree with efficient order statistic lookups.

**Constructor**

```text
Std.TreeMap.Raw.mk.{u, v}
```

**Fields**

```text
inner : Std.DTreeMap.Raw α (fun x => β) cmp
```

Internal implementation detail of the tree map.

<a id="Std___TreeMap___Raw___WF___mk"></a>

**structure**

```text
Std.TreeMap.Raw.WF.{u, v} {α : Type u} {β : Type v}
  {cmp : α → α → Ordering} (t : Std.TreeMap.Raw α β cmp) : Prop
```

Well-formedness predicate for tree maps. Users of `TreeMap` will not need to interact with this. Users of `TreeMap.Raw` will need to provide proofs of `WF` to lemmas and should use lemmas like `WF.empty` and `WF.insert` (which are always named exactly like the operations they are about) to show that map operations preserve well-formedness. The constructors of this type are internal implementation details and should not be accessed by users.

**Constructor**

```text
Std.TreeMap.Raw.WF.mk.{u, v}
```

**Fields**

```text
out : t.inner.WF
```

Internal implementation detail of the tree map.

<a id="DTreeMap"></a>
### 20.19.9. Dependent Tree-Based Maps

The declarations in this section should be imported using `import Std.DTreeMap`.

<a id="Std___DTreeMap"></a>

**structure**

```text
Std.DTreeMap.{u, v} (α : Type u) (β : α → Type v)
  (cmp : α → α → Ordering := by exact compare) : Type (max u v)
```

Dependent tree maps.

A tree map stores an assignment of keys to values. It depends on a comparator function that defines an ordering on the keys and provides efficient order-dependent queries, such as retrieval of the minimum or maximum.

To ensure that the operations behave as expected, the comparator function `cmp` should satisfy certain laws that ensure a consistent ordering:

- If `a` is less than (or equal) to `b`, then `b` is greater than (or equal) to `a` and vice versa (see the `OrientedCmp` typeclass).
- If `a` is less than or equal to `b` and `b` is, in turn, less than or equal to `c`, then `a` is less than or equal to `c` (see the `TransCmp` typeclass).

Keys for which `cmp a b = Ordering.eq` are considered the same, i.e., there can be only one entry with key either `a` or `b` in a tree map. Looking up either `a` or `b` always yields the same entry, if any is present. The `get` operations of the *dependent* tree map additionally require a `LawfulEqCmp` instance to ensure that `cmp a b = .eq` always implies `a = b`, so that their respective value types are equal.

To avoid expensive copies, users should make sure that the tree map is used linearly.

Internally, the tree maps are represented as size-bounded trees, a type of self-balancing binary search tree with efficient order statistic lookups.

For use in proofs, the type `Std.ExtDTreeMap` of extensional dependent tree maps should be preferred. This type comes with several extensionality lemmas and provides the same functions but requires a `TransCmp` instance to work with.

These tree maps contain a bundled well-formedness invariant, which means that they cannot be used in nested inductive types. For these use cases, `Std.DTreeMap.Raw` and `Std.DTreeMap.Raw.WF` unbundle the invariant from the tree map. When in doubt, prefer `DTreeMap` over `DTreeMap.Raw`.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Dependent-Tree-Based-Maps--Creation"></a>
#### 20.19.9.1. Creation

<a id="Std___DTreeMap___empty"></a>

**def**

```text
Std.DTreeMap.empty.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} : Std.DTreeMap α β cmp
```

Creates a new empty tree map. It is also possible and recommended to use the empty collection notations `∅` and `{}` to create an empty tree map. `simp` replaces `empty` with `∅`.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Dependent-Tree-Based-Maps--Properties"></a>
#### 20.19.9.2. Properties

<a id="Std___DTreeMap___size"></a>

**def**

```text
Std.DTreeMap.size.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) : Nat
```

Returns the number of mappings present in the map.

<a id="Std___DTreeMap___isEmpty"></a>

**def**

```text
Std.DTreeMap.isEmpty.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) : Bool
```

Returns `true` if the tree map contains no mappings.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Dependent-Tree-Based-Maps--Queries"></a>
#### 20.19.9.3. Queries

<a id="Std___DTreeMap___contains"></a>

**def**

```text
Std.DTreeMap.contains.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) (a : α) : Bool
```

Returns `true` if there is a mapping for the given key `a` or a key that is equal to `a` according to the comparator `cmp`. There is also a `Prop`-valued version of this: `a ∈ t` is equivalent to `t.contains a = true`.

Observe that this is different behavior than for lists: for lists, `∈` uses `=` and `contains` uses `==` for equality checks, while for tree maps, both use the given comparator `cmp`.

<a id="Std___DTreeMap___get"></a>

**def**

```text
Std.DTreeMap.get.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} [Std.LawfulEqCmp cmp]
  (t : Std.DTreeMap α β cmp) (a : α) (h : a ∈ t) : β a
```

Given a proof that a mapping for the given key is present, retrieves the mapping for the given key.

Uses the `LawfulEqCmp` instance to cast the retrieved value to the correct type.

<a id="Std___DTreeMap___get___"></a>

**def**

```text
Std.DTreeMap.get!.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} [Std.LawfulEqCmp cmp]
  (t : Std.DTreeMap α β cmp) (a : α) [Inhabited (β a)] : β a
```

Tries to retrieve the mapping for the given key, panicking if no such mapping is present.

Uses the `LawfulEqCmp` instance to cast the retrieved value to the correct type.

<a id="Std___DTreeMap___get___-next"></a>

**def**

```text
Std.DTreeMap.get?.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} [Std.LawfulEqCmp cmp]
  (t : Std.DTreeMap α β cmp) (a : α) : Option (β a)
```

Tries to retrieve the mapping for the given key, returning `none` if no such mapping is present.

Uses the `LawfulEqCmp` instance to cast the retrieved value to the correct type.

<a id="Std___DTreeMap___getD"></a>

**def**

```text
Std.DTreeMap.getD.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} [Std.LawfulEqCmp cmp]
  (t : Std.DTreeMap α β cmp) (a : α) (fallback : β a) : β a
```

Tries to retrieve the mapping for the given key, returning `fallback` if no such mapping is present.

Uses the `LawfulEqCmp` instance to cast the retrieved value to the correct type.

<a id="Std___DTreeMap___getKey"></a>

**def**

```text
Std.DTreeMap.getKey.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) (a : α)
  (h : a ∈ t) : α
```

Retrieves the key from the mapping that matches `a`. Ensures that such a mapping exists by requiring a proof of `a ∈ m`. The result is guaranteed to be pointer equal to the key in the map.

<a id="Std___DTreeMap___getKey___"></a>

**def**

```text
Std.DTreeMap.getKey!.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} [Inhabited α] (t : Std.DTreeMap α β cmp)
  (a : α) : α
```

Checks if a mapping for the given key exists and returns the key if it does, otherwise panics. If no panic occurs the result is guaranteed to be pointer equal to the key in the map.

<a id="Std___DTreeMap___getKey___-next"></a>

**def**

```text
Std.DTreeMap.getKey?.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) (a : α) : Option α
```

Checks if a mapping for the given key exists and returns the key if it does, otherwise `none`. The result in the `some` case is guaranteed to be pointer equal to the key in the map.

<a id="Std___DTreeMap___getKeyD"></a>

**def**

```text
Std.DTreeMap.getKeyD.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) (a fallback : α) :
  α
```

Checks if a mapping for the given key exists and returns the key if it does, otherwise `fallback`. If a mapping exists the result is guaranteed to be pointer equal to the key in the map.

<a id="Std___DTreeMap___keys"></a>

**def**

```text
Std.DTreeMap.keys.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) : List α
```

Returns a list of all keys present in the tree map in ascending order.

<a id="Std___DTreeMap___keysArray"></a>

**def**

```text
Std.DTreeMap.keysArray.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) : Array α
```

Returns an array of all keys present in the tree map in ascending order.

<a id="Std___DTreeMap___values"></a>

**def**

```text
Std.DTreeMap.values.{u, v} {α : Type u} {cmp : α → α → Ordering}
  {β : Type v} (t : Std.DTreeMap α (fun x => β) cmp) : List β
```

Returns a list of all values present in the tree map in ascending order.

<a id="Std___DTreeMap___valuesArray"></a>

**def**

```text
Std.DTreeMap.valuesArray.{u, v} {α : Type u} {cmp : α → α → Ordering}
  {β : Type v} (t : Std.DTreeMap α (fun x => β) cmp) : Array β
```

Returns an array of all values present in the tree map in ascending order.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Dependent-Tree-Based-Maps--Modification"></a>
#### 20.19.9.4. Modification

<a id="Std___DTreeMap___alter"></a>

**def**

```text
Std.DTreeMap.alter.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} [Std.LawfulEqCmp cmp]
  (t : Std.DTreeMap α β cmp) (a : α) (f : Option (β a) → Option (β a)) :
  Std.DTreeMap α β cmp
```

Modifies in place the value associated with a given key, allowing creating new values and deleting values via an `Option` valued replacement function.

This function ensures that the value is used linearly.

<a id="Std___DTreeMap___modify"></a>

**def**

```text
Std.DTreeMap.modify.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} [Std.LawfulEqCmp cmp]
  (t : Std.DTreeMap α β cmp) (a : α) (f : β a → β a) :
  Std.DTreeMap α β cmp
```

Modifies in place the value associated with a given key.

This function ensures that the value is used linearly.

<a id="Std___DTreeMap___containsThenInsert"></a>

**def**

```text
Std.DTreeMap.containsThenInsert.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) (a : α)
  (b : β a) : Bool × Std.DTreeMap α β cmp
```

Checks whether a key is present in a map and unconditionally inserts a value for the key.

Equivalent to (but potentially faster than) calling `contains` followed by `insert`.

<a id="Std___DTreeMap___containsThenInsertIfNew"></a>

**def**

```text
Std.DTreeMap.containsThenInsertIfNew.{u, v} {α : Type u}
  {β : α → Type v} {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp)
  (a : α) (b : β a) : Bool × Std.DTreeMap α β cmp
```

Checks whether a key is present in a map and inserts a value for the key if it was not found. If the returned `Bool` is `true`, then the returned map is unaltered. If the `Bool` is `false`, then the returned map has a new value inserted.

Equivalent to (but potentially faster than) calling `contains` followed by `insertIfNew`.

<a id="Std___DTreeMap___erase"></a>

**def**

```text
Std.DTreeMap.erase.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) (a : α) :
  Std.DTreeMap α β cmp
```

Removes the mapping for the given key if it exists.

<a id="Std___DTreeMap___filter"></a>

**def**

```text
Std.DTreeMap.filter.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} (f : (a : α) → β a → Bool)
  (t : Std.DTreeMap α β cmp) : Std.DTreeMap α β cmp
```

Removes all mappings of the map for which the given function returns `false`.

<a id="Std___DTreeMap___filterMap"></a>

**def**

```text
Std.DTreeMap.filterMap.{u, v, w} {α : Type u} {β : α → Type v}
  {γ : α → Type w} {cmp : α → α → Ordering}
  (f : (a : α) → β a → Option (γ a)) (t : Std.DTreeMap α β cmp) :
  Std.DTreeMap α γ cmp
```

Updates the values of the map by applying the given function to all mappings, keeping only those mappings where the function returns `some` value.

<a id="Std___DTreeMap___insert"></a>

**def**

```text
Std.DTreeMap.insert.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) (a : α)
  (b : β a) : Std.DTreeMap α β cmp
```

Inserts the given mapping into the map. If there is already a mapping for the given key, then both key and value will be replaced.

<a id="Std___DTreeMap___insertIfNew"></a>

**def**

```text
Std.DTreeMap.insertIfNew.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) (a : α)
  (b : β a) : Std.DTreeMap α β cmp
```

If there is no mapping for the given key, inserts the given mapping into the map. Otherwise, returns the map unaltered.

<a id="Std___DTreeMap___getThenInsertIfNew___"></a>

**def**

```text
Std.DTreeMap.getThenInsertIfNew?.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} [Std.LawfulEqCmp cmp]
  (t : Std.DTreeMap α β cmp) (a : α) (b : β a) :
  Option (β a) × Std.DTreeMap α β cmp
```

Checks whether a key is present in a map, returning the associated value, and inserts a value for the key if it was not found.

If the returned value is `some v`, then the returned map is unaltered. If it is `none`, then the returned map has a new value inserted.

Equivalent to (but potentially faster than) calling `get?` followed by `insertIfNew`.

Uses the `LawfulEqCmp` instance to cast the retrieved value to the correct type.

<a id="Std___DTreeMap___insertMany"></a>

**def**

```text
Std.DTreeMap.insertMany.{u, v, u_1} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} {ρ : Type u_1} [ForIn Id ρ ((a : α) × β a)]
  (t : Std.DTreeMap α β cmp) (l : ρ) : Std.DTreeMap α β cmp
```

Inserts multiple mappings into the tree map by iterating over the given collection and calling `insert`. If the same key appears multiple times, the last occurrence takes precedence.

Note: this precedence behavior is true for `TreeMap`, `DTreeMap`, `TreeMap.Raw` and `DTreeMap.Raw`. The `insertMany` function on `TreeSet` and `TreeSet.Raw` behaves differently: it will prefer the first appearance.

<a id="Std___DTreeMap___partition"></a>

**def**

```text
Std.DTreeMap.partition.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} (f : (a : α) → β a → Bool)
  (t : Std.DTreeMap α β cmp) :
  Std.DTreeMap α β cmp × Std.DTreeMap α β cmp
```

Partitions a tree map into two tree maps based on a predicate.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Dependent-Tree-Based-Maps--Iteration"></a>
#### 20.19.9.5. Iteration

<a id="Std___DTreeMap___iter"></a>

**def**

```text
Std.DTreeMap.iter.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} (m : Std.DTreeMap α β cmp) :
  Std.Iter ((a : α) × β a)
```

Returns a finite iterator over the entries of a dependent tree map. The iterator yields the elements of the map in order and then terminates.

**Termination properties:**

- `Finite` instance: always
- `Productive` instance: always

<a id="Std___DTreeMap___keysIter"></a>

**def**

```text
Std.DTreeMap.keysIter.{u} {α : Type u} {β : α → Type u}
  {cmp : α → α → Ordering} (m : Std.DTreeMap α β cmp) : Std.Iter α
```

Returns a finite iterator over the keys of a dependent tree map. The iterator yields the keys in order and then terminates.

The key and value types must live in the same universe.

**Termination properties:**

- `Finite` instance: always
- `Productive` instance: always

<a id="Std___DTreeMap___valuesIter"></a>

**def**

```text
Std.DTreeMap.valuesIter.{u} {α β : Type u} {cmp : α → α → Ordering}
  (m : Std.DTreeMap α (fun x => β) cmp) : Std.Iter β
```

Returns a finite iterator over the values of a tree map. The iterator yields the values in order and then terminates.

The key and value types must live in the same universe.

**Termination properties:**

- `Finite` instance: always
- `Productive` instance: always

<a id="Std___DTreeMap___map"></a>

**def**

```text
Std.DTreeMap.map.{u, v, w} {α : Type u} {β : α → Type v}
  {γ : α → Type w} {cmp : α → α → Ordering} (f : (a : α) → β a → γ a)
  (t : Std.DTreeMap α β cmp) : Std.DTreeMap α γ cmp
```

Updates the values of the map by applying the given function to all mappings.

<a id="Std___DTreeMap___foldl"></a>

**def**

```text
Std.DTreeMap.foldl.{u, v, w} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} {δ : Type w} (f : δ → (a : α) → β a → δ)
  (init : δ) (t : Std.DTreeMap α β cmp) : δ
```

Folds the given function over the mappings in the map in ascending order.

<a id="Std___DTreeMap___foldlM"></a>

**def**

```text
Std.DTreeMap.foldlM.{u, v, w, w₂} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} {δ : Type w} {m : Type w → Type w₂} [Monad m]
  (f : δ → (a : α) → β a → m δ) (init : δ) (t : Std.DTreeMap α β cmp) :
  m δ
```

Folds the given monadic function over the mappings in the map in ascending order.

<a id="Std___DTreeMap___forIn"></a>

**def**

```text
Std.DTreeMap.forIn.{u, v, w, w₂} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} {δ : Type w} {m : Type w → Type w₂} [Monad m]
  (f : (a : α) → β a → δ → m (ForInStep δ)) (init : δ)
  (t : Std.DTreeMap α β cmp) : m δ
```

Support for the `for` loop construct in `do` blocks. Iteration happens in ascending order.

<a id="Std___DTreeMap___forM"></a>

**def**

```text
Std.DTreeMap.forM.{u, v, w, w₂} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} {m : Type w → Type w₂} [Monad m]
  (f : (a : α) → β a → m PUnit) (t : Std.DTreeMap α β cmp) : m PUnit
```

Carries out a monadic action on each mapping in the tree map in ascending order.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Dependent-Tree-Based-Maps--Conversion"></a>
#### 20.19.9.6. Conversion

<a id="Std___DTreeMap___ofList"></a>

**def**

```text
Std.DTreeMap.ofList.{u, v} {α : Type u} {β : α → Type v}
  (l : List ((a : α) × β a))
  (cmp : α → α → Ordering := by exact compare) : Std.DTreeMap α β cmp
```

Transforms a list of mappings into a tree map.

<a id="Std___DTreeMap___toArray"></a>

**def**

```text
Std.DTreeMap.toArray.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) :
  Array ((a : α) × β a)
```

Transforms the tree map into a list of mappings in ascending order.

<a id="Std___DTreeMap___toList"></a>

**def**

```text
Std.DTreeMap.toList.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} (t : Std.DTreeMap α β cmp) :
  List ((a : α) × β a)
```

Transforms the tree map into a list of mappings in ascending order.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Dependent-Tree-Based-Maps--Unbundled-Variants"></a>
#### 20.19.9.7. Unbundled Variants

Unbundled maps separate well-formedness proofs from data. This is primarily useful when defining [nested inductive types](index.md#raw-data). To use these variants, import the module `Std.DTreeMap.Raw`.

<a id="Std___DTreeMap___Raw___mk"></a>

**structure**

```text
Std.DTreeMap.Raw.{u, v} (α : Type u) (β : α → Type v)
  (_cmp : α → α → Ordering := by exact compare) : Type (max u v)
```

Dependent tree maps without a bundled well-formedness invariant, suitable for use in nested inductive types. The well-formedness invariant is called `Raw.WF`. When in doubt, prefer `DTreeMap` over `DTreeMap.Raw`. Lemmas about the operations on `Std.DTreeMap.Raw` are available in the module `Std.Data.DTreeMap.Raw.Lemmas`.

A tree map stores an assignment of keys to values. It depends on a comparator function that defines an ordering on the keys and provides efficient order-dependent queries, such as retrieval of the minimum or maximum.

To ensure that the operations behave as expected, the comparator function `cmp` should satisfy certain laws that ensure a consistent ordering:

- If `a` is less than (or equal) to `b`, then `b` is greater than (or equal) to `a` and vice versa (see the `OrientedCmp` typeclass).
- If `a` is less than or equal to `b` and `b` is, in turn, less than or equal to `c`, then `a` is less than or equal to `c` (see the `TransCmp` typeclass).

Keys for which `cmp a b = Ordering.eq` are considered the same, i.e., there can be only one entry with key either `a` or `b` in a tree map. Looking up either `a` or `b` always yields the same entry, if any is present. The `get` operations of the *dependent* tree map additionally require a `LawfulEqCmp` instance to ensure that `cmp a b = .eq` always implies `a = b`, so that their respective value types are equal.

To avoid expensive copies, users should make sure that the tree map is used linearly.

Internally, the tree maps are represented as size-bounded trees, a type of self-balancing binary search tree with efficient order statistic lookups.

**Constructor**

```text
Std.DTreeMap.Raw.mk.{u, v}
```

**Fields**

```text
inner : Std.DTreeMap.Internal.Impl α β
```

Internal implementation detail of the tree map.

<a id="Std___DTreeMap___Raw___WF___mk"></a>

**structure**

```text
Std.DTreeMap.Raw.WF.{u, v} {α : Type u} {β : α → Type v}
  {cmp : α → α → Ordering} (t : Std.DTreeMap.Raw α β cmp) : Prop
```

Well-formedness predicate for tree maps. Users of `DTreeMap` will not need to interact with this. Users of `DTreeMap.Raw` will need to provide proofs of `WF` to lemmas and should use lemmas like `WF.empty` and `WF.insert` (which are always named exactly like the operations they are about) to show that map operations preserve well-formedness. The constructors of this type are internal implementation details and should not be accessed by users.

**Constructor**

```text
Std.DTreeMap.Raw.WF.mk.{u, v}
```

**Fields**

```text
out : t.inner.WF
```

Internal implementation detail of the tree map.

<a id="TreeSet"></a>
### 20.19.10. Tree-Based Sets

<a id="Std___TreeSet"></a>

**structure**

```text
Std.TreeSet.{u} (α : Type u)
  (cmp : α → α → Ordering := by exact compare) : Type u
```

Tree sets.

A tree set stores elements of a certain type in a certain order. It depends on a comparator function that defines an ordering on the keys and provides efficient order-dependent queries, such as retrieval of the minimum or maximum.

To ensure that the operations behave as expected, the comparator function `cmp` should satisfy certain laws that ensure a consistent ordering:

- If `a` is less than (or equal) to `b`, then `b` is greater than (or equal) to `a` and vice versa (see the `OrientedCmp` typeclass).
- If `a` is less than or equal to `b` and `b` is, in turn, less than or equal to `c`, then `a` is less than or equal to `c` (see the `TransCmp` typeclass).

Keys for which `cmp a b = Ordering.eq` are considered the same, i.e., there can be only one of them be contained in a single tree set at the same time.

To avoid expensive copies, users should make sure that the tree set is used linearly.

Internally, the tree sets are represented as size-bounded trees, a type of self-balancing binary search tree with efficient order statistic lookups.

For use in proofs, the type `Std.ExtTreeSet` of extensional tree sets should be preferred. This type comes with several extensionality lemmas and provides the same functions but requires a `TransCmp` instance to work with.

These tree sets contain a bundled well-formedness invariant, which means that they cannot be used in nested inductive types. For these use cases, `Std.TreeSet.Raw` and `Std.TreeSet.Raw.WF` unbundle the invariant from the tree set. When in doubt, prefer `TreeSet` over `TreeSet.Raw`.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Tree-Based-Sets--Creation"></a>
#### 20.19.10.1. Creation

<a id="Std___TreeSet___empty"></a>

**def**

```text
Std.TreeSet.empty.{u} {α : Type u} {cmp : α → α → Ordering} :
  Std.TreeSet α cmp
```

Creates a new empty tree set. It is also possible and recommended to use the empty collection notations `∅` and `{}` to create an empty tree set. `simp` replaces `empty` with `∅`.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Tree-Based-Sets--Properties"></a>
#### 20.19.10.2. Properties

<a id="Std___TreeSet___isEmpty"></a>

**def**

```text
Std.TreeSet.isEmpty.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) : Bool
```

Returns `true` if the tree set contains no mappings.

<a id="Std___TreeSet___size"></a>

**def**

```text
Std.TreeSet.size.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) : Nat
```

Returns the number of mappings present in the map.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Tree-Based-Sets--Queries"></a>
#### 20.19.10.3. Queries

<a id="Std___TreeSet___contains"></a>

**def**

```text
Std.TreeSet.contains.{u} {α : Type u} {cmp : α → α → Ordering}
  (l : Std.TreeSet α cmp) (a : α) : Bool
```

Returns `true` if `a`, or an element equal to `a` according to the comparator `cmp`, is contained in the set. There is also a `Prop`-valued version of this: `a ∈ t` is equivalent to `t.contains a = true`.

Observe that this is different behavior than for lists: for lists, `∈` uses `=` and `contains` uses `==` for equality checks, while for tree sets, both use the given comparator `cmp`.

<a id="Std___TreeSet___get"></a>

**def**

```text
Std.TreeSet.get.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) (a : α) (h : a ∈ t) : α
```

Retrieves the key from the set that matches `a`. Ensures that such a key exists by requiring a proof of `a ∈ m`. The result is guaranteed to be pointer equal to the key in the set.

<a id="Std___TreeSet___get___"></a>

**def**

```text
Std.TreeSet.get!.{u} {α : Type u} {cmp : α → α → Ordering} [Inhabited α]
  (t : Std.TreeSet α cmp) (a : α) : α
```

Checks if given key is contained and returns the key if it is, otherwise panics. If no panic occurs the result is guaranteed to be pointer equal to the key in the set.

<a id="Std___TreeSet___get___-next"></a>

**def**

```text
Std.TreeSet.get?.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) (a : α) : Option α
```

Checks if given key is contained and returns the key if it is, otherwise `none`. The result in the `some` case is guaranteed to be pointer equal to the key in the map.

<a id="Std___TreeSet___getD"></a>

**def**

```text
Std.TreeSet.getD.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) (a fallback : α) : α
```

Checks if given key is contained and returns the key if it is, otherwise `fallback`. If they key is contained the result is guaranteed to be pointer equal to the key in the set.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Tree-Based-Sets--Queries--Ordering-Based-Queries"></a>
##### 20.19.10.3.1. Ordering-Based Queries

<a id="Std___TreeSet___atIdx"></a>

**def**

```text
Std.TreeSet.atIdx.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) (n : Nat) (h : n < t.size) : α
```

Returns the `n`-th smallest element.

<a id="Std___TreeSet___atIdx___"></a>

**def**

```text
Std.TreeSet.atIdx!.{u} {α : Type u} {cmp : α → α → Ordering}
  [Inhabited α] (t : Std.TreeSet α cmp) (n : Nat) : α
```

Returns the `n`-th smallest element, or panics if `n` is at least `t.size`.

<a id="Std___TreeSet___atIdx___-next"></a>

**def**

```text
Std.TreeSet.atIdx?.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) (n : Nat) : Option α
```

Returns the `n`-th smallest element, or `none` if `n` is at least `t.size`.

<a id="Std___TreeSet___atIdxD"></a>

**def**

```text
Std.TreeSet.atIdxD.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) (n : Nat) (fallback : α) : α
```

Returns the `n`-th smallest element, or `fallback` if `n` is at least `t.size`.

<a id="Std___TreeSet___getGE"></a>

**def**

```text
Std.TreeSet.getGE.{u} {α : Type u} {cmp : α → α → Ordering}
  [Std.TransCmp cmp] (t : Std.TreeSet α cmp) (k : α)
  (h : ∃ a, a ∈ t ∧ (cmp a k).isGE = true) : α
```

Given a proof that such an element exists, retrieves the smallest element that is greater than or equal to the given element.

<a id="Std___TreeSet___getGE___"></a>

**def**

```text
Std.TreeSet.getGE!.{u} {α : Type u} {cmp : α → α → Ordering}
  [Inhabited α] (t : Std.TreeSet α cmp) (k : α) : α
```

Tries to retrieve the smallest element that is greater than or equal to the given element, panicking if no such element exists.

<a id="Std___TreeSet___getGE___-next"></a>

**def**

```text
Std.TreeSet.getGE?.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) (k : α) : Option α
```

Tries to retrieve the smallest element that is greater than or equal to the given element, returning `none` if no such element exists.

<a id="Std___TreeSet___getGED"></a>

**def**

```text
Std.TreeSet.getGED.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) (k fallback : α) : α
```

Tries to retrieve the smallest element that is greater than or equal to the given element, returning `fallback` if no such element exists.

<a id="Std___TreeSet___getGT"></a>

**def**

```text
Std.TreeSet.getGT.{u} {α : Type u} {cmp : α → α → Ordering}
  [Std.TransCmp cmp] (t : Std.TreeSet α cmp) (k : α)
  (h : ∃ a, a ∈ t ∧ cmp a k = Ordering.gt) : α
```

Given a proof that such an element exists, retrieves the smallest element that is greater than the given element.

<a id="Std___TreeSet___getGT___"></a>

**def**

```text
Std.TreeSet.getGT!.{u} {α : Type u} {cmp : α → α → Ordering}
  [Inhabited α] (t : Std.TreeSet α cmp) (k : α) : α
```

Tries to retrieve the smallest element that is greater than the given element, panicking if no such element exists.

<a id="Std___TreeSet___getGT___-next"></a>

**def**

```text
Std.TreeSet.getGT?.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) (k : α) : Option α
```

Tries to retrieve the smallest element that is greater than the given element, returning `none` if no such element exists.

<a id="Std___TreeSet___getGTD"></a>

**def**

```text
Std.TreeSet.getGTD.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) (k fallback : α) : α
```

Tries to retrieve the smallest element that is greater than the given element, returning `fallback` if no such element exists.

<a id="Std___TreeSet___getLE"></a>

**def**

```text
Std.TreeSet.getLE.{u} {α : Type u} {cmp : α → α → Ordering}
  [Std.TransCmp cmp] (t : Std.TreeSet α cmp) (k : α)
  (h : ∃ a, a ∈ t ∧ (cmp a k).isLE = true) : α
```

Given a proof that such an element exists, retrieves the largest element that is less than or equal to the given element.

<a id="Std___TreeSet___getLE___"></a>

**def**

```text
Std.TreeSet.getLE!.{u} {α : Type u} {cmp : α → α → Ordering}
  [Inhabited α] (t : Std.TreeSet α cmp) (k : α) : α
```

Tries to retrieve the largest element that is less than or equal to the given element, panicking if no such element exists.

<a id="Std___TreeSet___getLE___-next"></a>

**def**

```text
Std.TreeSet.getLE?.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) (k : α) : Option α
```

Tries to retrieve the largest element that is less than or equal to the given element, returning `none` if no such element exists.

<a id="Std___TreeSet___getLED"></a>

**def**

```text
Std.TreeSet.getLED.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) (k fallback : α) : α
```

Tries to retrieve the largest element that is less than or equal to the given element, returning `fallback` if no such element exists.

<a id="Std___TreeSet___getLT"></a>

**def**

```text
Std.TreeSet.getLT.{u} {α : Type u} {cmp : α → α → Ordering}
  [Std.TransCmp cmp] (t : Std.TreeSet α cmp) (k : α)
  (h : ∃ a, a ∈ t ∧ cmp a k = Ordering.lt) : α
```

Given a proof that such an element exists, retrieves the smallest element that is less than the given element.

<a id="Std___TreeSet___getLT___"></a>

**def**

```text
Std.TreeSet.getLT!.{u} {α : Type u} {cmp : α → α → Ordering}
  [Inhabited α] (t : Std.TreeSet α cmp) (k : α) : α
```

Tries to retrieve the smallest element that is less than the given element, panicking if no such element exists.

<a id="Std___TreeSet___getLT___-next"></a>

**def**

```text
Std.TreeSet.getLT?.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) (k : α) : Option α
```

Tries to retrieve the smallest element that is less than the given element, returning `none` if no such element exists.

<a id="Std___TreeSet___getLTD"></a>

**def**

```text
Std.TreeSet.getLTD.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) (k fallback : α) : α
```

Tries to retrieve the smallest element that is less than the given element, returning `fallback` if no such element exists.

<a id="Std___TreeSet___min"></a>

**def**

```text
Std.TreeSet.min.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) (h : t.isEmpty = false) : α
```

Given a proof that the tree set is not empty, retrieves the smallest element.

<a id="Std___TreeSet___min___"></a>

**def**

```text
Std.TreeSet.min!.{u} {α : Type u} {cmp : α → α → Ordering} [Inhabited α]
  (t : Std.TreeSet α cmp) : α
```

Tries to retrieve the smallest element of the tree set, panicking if the set is empty.

<a id="Std___TreeSet___min___-next"></a>

**def**

```text
Std.TreeSet.min?.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) : Option α
```

Tries to retrieve the smallest element of the tree set, returning `none` if the set is empty.

<a id="Std___TreeSet___minD"></a>

**def**

```text
Std.TreeSet.minD.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) (fallback : α) : α
```

Tries to retrieve the smallest element of the tree set, returning `fallback` if the tree set is empty.

<a id="Std___TreeSet___max"></a>

**def**

```text
Std.TreeSet.max.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) (h : t.isEmpty = false) : α
```

Given a proof that the tree set is not empty, retrieves the largest element.

<a id="Std___TreeSet___max___"></a>

**def**

```text
Std.TreeSet.max!.{u} {α : Type u} {cmp : α → α → Ordering} [Inhabited α]
  (t : Std.TreeSet α cmp) : α
```

Tries to retrieve the largest element of the tree set, panicking if the set is empty.

<a id="Std___TreeSet___max___-next"></a>

**def**

```text
Std.TreeSet.max?.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) : Option α
```

Tries to retrieve the largest element of the tree set, returning `none` if the set is empty.

<a id="Std___TreeSet___maxD"></a>

**def**

```text
Std.TreeSet.maxD.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) (fallback : α) : α
```

Tries to retrieve the largest element of the tree set, returning `fallback` if the tree set is empty.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Tree-Based-Sets--Modification"></a>
#### 20.19.10.4. Modification

<a id="Std___TreeSet___insert"></a>

**def**

```text
Std.TreeSet.insert.{u} {α : Type u} {cmp : α → α → Ordering}
  (l : Std.TreeSet α cmp) (a : α) : Std.TreeSet α cmp
```

Inserts the given element into the set. If the tree set already contains an element that is equal (with regard to `cmp`) to the given element, then the tree set is returned unchanged.

Note: this non-replacement behavior is true for `TreeSet` and `TreeSet.Raw`. The `insert` function on `TreeMap`, `DTreeMap`, `TreeMap.Raw` and `DTreeMap.Raw` behaves differently: it will overwrite an existing mapping.

<a id="Std___TreeSet___insertMany"></a>

**def**

```text
Std.TreeSet.insertMany.{u, u_1} {α : Type u} {cmp : α → α → Ordering}
  {ρ : Type u_1} [ForIn Id ρ α] (t : Std.TreeSet α cmp) (l : ρ) :
  Std.TreeSet α cmp
```

Inserts multiple elements into the tree set by iterating over the given collection and calling `insert`. If the same element (with respect to `cmp`) appears multiple times, the first occurrence takes precedence.

Note: this precedence behavior is true for `TreeSet` and `TreeSet.Raw`. The `insertMany` function on `TreeMap`, `DTreeMap`, `TreeMap.Raw` and `DTreeMap.Raw` behaves differently: it will prefer the last appearance.

<a id="Std___TreeSet___containsThenInsert"></a>

**def**

```text
Std.TreeSet.containsThenInsert.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) (a : α) : Bool × Std.TreeSet α cmp
```

Checks whether an element is present in a set and inserts the element if it was not found. If the tree set already contains an element that is equal (with regard to `cmp` to the given element, then the tree set is returned unchanged.

Equivalent to (but potentially faster than) calling `contains` followed by `insert`.

<a id="Std___TreeSet___erase"></a>

**def**

```text
Std.TreeSet.erase.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) (a : α) : Std.TreeSet α cmp
```

Removes the given key if it exists.

<a id="Std___TreeSet___eraseMany"></a>

**def**

```text
Std.TreeSet.eraseMany.{u, u_1} {α : Type u} {cmp : α → α → Ordering}
  {ρ : Type u_1} [ForIn Id ρ α] (t : Std.TreeSet α cmp) (l : ρ) :
  Std.TreeSet α cmp
```

Erases multiple items from the tree set by iterating over the given collection and calling erase.

<a id="Std___TreeSet___filter"></a>

**def**

```text
Std.TreeSet.filter.{u} {α : Type u} {cmp : α → α → Ordering}
  (f : α → Bool) (m : Std.TreeSet α cmp) : Std.TreeSet α cmp
```

Removes all elements from the tree set for which the given function returns `false`.

<a id="Std___TreeSet___merge"></a>

**def**

```text
Std.TreeSet.merge.{u} {α : Type u} {cmp : α → α → Ordering}
  (t₁ t₂ : Std.TreeSet α cmp) : Std.TreeSet α cmp
```

Returns a set that contains all mappings of `t₁` and `t₂.

This function ensures that `t₁` is used linearly. Hence, as long as `t₁` is unshared, the performance characteristics follow the following imperative description: Iterate over all mappings in `t₂`, inserting them into `t₁`.

Hence, the runtime of this method scales logarithmically in the size of `t₁` and linearly in the size of `t₂` as long as `t₁` is unshared.

<a id="Std___TreeSet___partition"></a>

**def**

```text
Std.TreeSet.partition.{u} {α : Type u} {cmp : α → α → Ordering}
  (f : α → Bool) (t : Std.TreeSet α cmp) :
  Std.TreeSet α cmp × Std.TreeSet α cmp
```

Partitions a tree set into two tree sets based on a predicate.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Tree-Based-Sets--Iteration"></a>
#### 20.19.10.5. Iteration

<a id="Std___TreeSet___iter"></a>

**def**

```text
Std.TreeSet.iter.{u} {α : Type u} {cmp : α → α → Ordering}
  (m : Std.TreeSet α cmp) : Std.Iter α
```

Returns a finite iterator over the entries of a tree set. The iterator yields the elements of the set in order and then terminates.

**Termination properties:**

- `Finite` instance: always
- `Productive` instance: always

<a id="Std___TreeSet___all"></a>

**def**

```text
Std.TreeSet.all.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) (p : α → Bool) : Bool
```

Check if any element satisfies the predicate, short-circuiting if a predicate succeeds.

<a id="Std___TreeSet___any"></a>

**def**

```text
Std.TreeSet.any.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) (p : α → Bool) : Bool
```

Check if all elements satisfy the predicate, short-circuiting if a predicate fails.

<a id="Std___TreeSet___foldl"></a>

**def**

```text
Std.TreeSet.foldl.{u, w} {α : Type u} {cmp : α → α → Ordering}
  {δ : Type w} (f : δ → α → δ) (init : δ) (t : Std.TreeSet α cmp) : δ
```

Folds the given function over the elements of the tree set in ascending order.

<a id="Std___TreeSet___foldlM"></a>

**def**

```text
Std.TreeSet.foldlM.{u, u_1, u_2} {α : Type u} {cmp : α → α → Ordering}
  {m : Type u_1 → Type u_2} {δ : Type u_1} [Monad m] (f : δ → α → m δ)
  (init : δ) (t : Std.TreeSet α cmp) : m δ
```

Monadically computes a value by folding the given function over the elements in the tree set in ascending order.

<a id="Std___TreeSet___foldr"></a>

**def**

```text
Std.TreeSet.foldr.{u, w} {α : Type u} {cmp : α → α → Ordering}
  {δ : Type w} (f : α → δ → δ) (init : δ) (t : Std.TreeSet α cmp) : δ
```

Folds the given function over the elements of the tree set in descending order.

<a id="Std___TreeSet___foldrM"></a>

**def**

```text
Std.TreeSet.foldrM.{u, u_1, u_2} {α : Type u} {cmp : α → α → Ordering}
  {m : Type u_1 → Type u_2} {δ : Type u_1} [Monad m] (f : α → δ → m δ)
  (init : δ) (t : Std.TreeSet α cmp) : m δ
```

Monadically computes a value by folding the given function over the elements in the tree set in descending order.

<a id="Std___TreeSet___forIn"></a>

**def**

```text
Std.TreeSet.forIn.{u, w, w₂} {α : Type u} {cmp : α → α → Ordering}
  {δ : Type w} {m : Type w → Type w₂} [Monad m]
  (f : α → δ → m (ForInStep δ)) (init : δ) (t : Std.TreeSet α cmp) : m δ
```

Support for the `for` loop construct in `do` blocks. The iteration happens in ascending order.

<a id="Std___TreeSet___forM"></a>

**def**

```text
Std.TreeSet.forM.{u, w, w₂} {α : Type u} {cmp : α → α → Ordering}
  {m : Type w → Type w₂} [Monad m] (f : α → m PUnit)
  (t : Std.TreeSet α cmp) : m PUnit
```

Carries out a monadic action on each element in the tree set in ascending order.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Tree-Based-Sets--Conversion"></a>
#### 20.19.10.6. Conversion

<a id="Std___TreeSet___toList"></a>

**def**

```text
Std.TreeSet.toList.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) : List α
```

Transforms the tree set into a list of elements in ascending order.

<a id="Std___TreeSet___ofList"></a>

**def**

```text
Std.TreeSet.ofList.{u} {α : Type u} (l : List α)
  (cmp : α → α → Ordering := by exact compare) : Std.TreeSet α cmp
```

Transforms a list into a tree set.

<a id="Std___TreeSet___toArray"></a>

**def**

```text
Std.TreeSet.toArray.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet α cmp) : Array α
```

Transforms the tree set into an array of elements in ascending order.

<a id="Std___TreeSet___ofArray"></a>

**def**

```text
Std.TreeSet.ofArray.{u} {α : Type u} (a : Array α)
  (cmp : α → α → Ordering := by exact compare) : Std.TreeSet α cmp
```

Transforms an array into a tree set.

<a id="The-Lean-Language-Reference--Basic-Types--Maps-and-Sets--Tree-Based-Sets--Conversion--Unbundled-Variants"></a>
##### 20.19.10.6.1. Unbundled Variants

Unbundled sets separate well-formedness proofs from data. This is primarily useful when defining [nested inductive types](index.md#raw-data). To use these variants, import the module `Std.TreeSet.Raw`.

<a id="Std___TreeSet___Raw___mk"></a>

**structure**

```text
Std.TreeSet.Raw.{u} (α : Type u)
  (cmp : α → α → Ordering := by exact compare) : Type u
```

Tree sets without a bundled well-formedness invariant, suitable for use in nested inductive types. The well-formedness invariant is called `Raw.WF`. When in doubt, prefer `TreeSet` over `TreeSet.Raw`. Lemmas about the operations on `Std.TreeSet.Raw` are available in the module `Std.Data.TreeSet.Raw.Lemmas`.

A tree set stores elements of a certain type in a certain order. It depends on a comparator function that defines an ordering on the keys and provides efficient order-dependent queries, such as retrieval of the minimum or maximum.

To ensure that the operations behave as expected, the comparator function `cmp` should satisfy certain laws that ensure a consistent ordering:

- If `a` is less than (or equal) to `b`, then `b` is greater than (or equal) to `a` and vice versa (see the `OrientedCmp` typeclass).
- If `a` is less than or equal to `b` and `b` is, in turn, less than or equal to `c`, then `a` is less than or equal to `c` (see the `TransCmp` typeclass).

Keys for which `cmp a b = Ordering.eq` are considered the same, i.e only one of them can be contained in a single tree set at the same time.

To avoid expensive copies, users should make sure that the tree set is used linearly.

Internally, the tree sets are represented as size-bounded trees, a type of self-balancing binary search tree with efficient order statistic lookups.

**Constructor**

```text
Std.TreeSet.Raw.mk.{u}
```

**Fields**

```text
inner : Std.TreeMap.Raw α Unit cmp
```

Internal implementation detail of the tree set.

<a id="Std___TreeSet___Raw___WF___mk"></a>

**structure**

```text
Std.TreeSet.Raw.WF.{u} {α : Type u} {cmp : α → α → Ordering}
  (t : Std.TreeSet.Raw α cmp) : Prop
```

Well-formedness predicate for tree sets. Users of `TreeSet` will not need to interact with this. Users of `TreeSet.Raw` will need to provide proofs of `WF` to lemmas and should use lemmas like `WF.empty` and `WF.insert` (which are always named exactly like the operations they are about) to show that set operations preserve well-formedness. The constructors of this type are internal implementation details and should not be accessed by users.

**Constructor**

```text
Std.TreeSet.Raw.WF.mk.{u}
```

**Fields**

```text
out : t.inner.WF
```

Internal implementation detail of the tree map.

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Two hash maps are equivalent in the sense of `Equiv` iff
all the keys and values are equal.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
(kernel) application type mismatch
  DHashMap.Raw.WF inner
argument has type
  _nested.Std.DHashMap.Raw_3
but function has type
  (DHashMap.Raw String fun x => Maze) → Prop
```


### Display 2


```text
Definition `RawMaze.insert_wf` is a proposition; use `theorem` instead of `def`

Note: This linter can be disabled with `set_option linter.defProp false`
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
description:String⊢ (base description).WF
```


### Display 2


```text
adescription:String⊢ ∀ (dir : String) (v : RawMaze), ∅[dir]? = some v → v.WFadescription:String⊢ ∅.WF
```


### Display 3


```text
adescription:String⊢ ∀ (dir : String) (v : RawMaze), ∅[dir]? = some v → v.WF
```


### Display 4


```text
adescription:Stringv:Stringh:RawMazeh':∅[v]? = some h⊢ h.WF
```


### Display 5


```text
All goals completed! 🐙
```


### Display 6


```text
adescription:String⊢ ∅.WF
```


### Display 7


```text
next:RawMazedir:Stringmaze:RawMaze⊢ maze.WF → next.WF → (maze.insert dir next).WF
```


### Display 8


```text
next:RawMazedir:Stringmaze:RawMazedesc:Stringpassages:HashMap.Raw String RawMaze⊢ { description := desc, passages := passages }.WF →
  next.WF → ({ description := desc, passages := passages }.insert dir next).WF
```


### Display 9


```text
next:RawMazedir:Stringmaze:RawMazedesc:Stringpassages:HashMap.Raw String RawMazewfMore:∀ (dir : String) (v : RawMaze), passages[dir]? = some v → v.WFwfPassages:passages.WFwfNext:next.WF⊢ ({ description := desc, passages := passages }.insert dir next).WF
```


### Display 10


```text
anext:RawMazedir:Stringmaze:RawMazedesc:Stringpassages:HashMap.Raw String RawMazewfMore:∀ (dir : String) (v : RawMaze), passages[dir]? = some v → v.WFwfPassages:passages.WFwfNext:next.WF⊢ ∀ (dir_1 : String) (v : RawMaze),
  ({ description := desc, passages := passages }.passages.insert dir next)[dir_1]? = some v → v.WFanext:RawMazedir:Stringmaze:RawMazedesc:Stringpassages:HashMap.Raw String RawMazewfMore:∀ (dir : String) (v : RawMaze), passages[dir]? = some v → v.WFwfPassages:passages.WFwfNext:next.WF⊢ ({ description := desc, passages := passages }.passages.insert dir next).WF
```


### Display 11


```text
anext:RawMazedir:Stringmaze:RawMazedesc:Stringpassages:HashMap.Raw String RawMazewfMore:∀ (dir : String) (v : RawMaze), passages[dir]? = some v → v.WFwfPassages:passages.WFwfNext:next.WF⊢ ∀ (dir_1 : String) (v : RawMaze),
  ({ description := desc, passages := passages }.passages.insert dir next)[dir_1]? = some v → v.WF
```


### Display 12


```text
anext:RawMazedir:Stringmaze:RawMazedesc:Stringpassages:HashMap.Raw String RawMazewfMore:∀ (dir : String) (v : RawMaze), passages[dir]? = some v → v.WFwfPassages:passages.WFwfNext:next.WFdir':Stringv:RawMaze⊢ ({ description := desc, passages := passages }.passages.insert dir next)[dir']? = some v → v.WF
```


### Display 13


```text
anext:RawMazedir:Stringmaze:RawMazedesc:Stringpassages:HashMap.Raw String RawMazewfMore:∀ (dir : String) (v : RawMaze), passages[dir]? = some v → v.WFwfPassages:passages.WFwfNext:next.WFdir':Stringv:RawMaze⊢ (if (dir == dir') = true then some next else passages[dir']?) = some v → v.WF
```


### Display 14


```text
a.isTruenext:RawMazedir:Stringmaze:RawMazedesc:Stringpassages:HashMap.Raw String RawMazewfMore:∀ (dir : String) (v : RawMaze), passages[dir]? = some v → v.WFwfPassages:passages.WFwfNext:next.WFdir':Stringv:RawMazeh✝:(dir == dir') = true⊢ some next = some v → v.WFa.isFalsenext:RawMazedir:Stringmaze:RawMazedesc:Stringpassages:HashMap.Raw String RawMazewfMore:∀ (dir : String) (v : RawMaze), passages[dir]? = some v → v.WFwfPassages:passages.WFwfNext:next.WFdir':Stringv:RawMazeh✝:¬(dir == dir') = true⊢ passages[dir']? = some v → v.WF
```


### Display 15


```text
a.isFalsenext:RawMazedir:Stringmaze:RawMazedesc:Stringpassages:HashMap.Raw String RawMazewfMore:∀ (dir : String) (v : RawMaze), passages[dir]? = some v → v.WFwfPassages:passages.WFwfNext:next.WFdir':Stringv:RawMazeh✝:¬(dir == dir') = truea✝:passages[dir']? = some v⊢ v.WF
```


### Display 16


```text
a.isTruenext:RawMazedir:Stringmaze:RawMazedesc:Stringpassages:HashMap.Raw String RawMazewfMore:∀ (dir : String) (v : RawMaze), passages[dir]? = some v → v.WFwfPassages:passages.WFwfNext:next.WFdir':Stringv:RawMazeh✝:(dir == dir') = truea✝:some next = some v⊢ v.WFa.isFalsenext:RawMazedir:Stringmaze:RawMazedesc:Stringpassages:HashMap.Raw String RawMazewfMore:∀ (dir : String) (v : RawMaze), passages[dir]? = some v → v.WFwfPassages:passages.WFwfNext:next.WFdir':Stringv:RawMazeh✝:¬(dir == dir') = truea✝:passages[dir']? = some v⊢ v.WF
```


### Display 17


```text
anext:RawMazedir:Stringmaze:RawMazedesc:Stringpassages:HashMap.Raw String RawMazewfMore:∀ (dir : String) (v : RawMaze), passages[dir]? = some v → v.WFwfPassages:passages.WFwfNext:next.WF⊢ ({ description := desc, passages := passages }.passages.insert dir next).WF
```


### Display 18


```text
description:String⊢ (RawMaze.base description).WF
```


### Display 19


```text
maze:Mazedir:Stringm':RawMazeh:maze.raw.passages[dir]? = some m'⊢ m'.WF
```


### Display 20


```text
maze:Mazedir:Stringm':RawMazer:RawMazewf:r.WFh:{ raw := r, wf := wf }.raw.passages[dir]? = some m'⊢ m'.WF
```


### Display 21


```text
maze:Mazedir:Stringm':RawMazer:RawMazewf:r.WFdescription✝:Stringpassages✝:HashMap.Raw String RawMazewfAll:∀ (dir : String) (v : RawMaze), passages✝[dir]? = some v → v.WFa✝:passages✝.WFh:{ raw := { description := description✝, passages := passages✝ }, wf := ⋯ }.raw.passages[dir]? = some m'⊢ m'.WF
```


### Display 22


```text
maze:Mazedir:Stringm':RawMazer:RawMazewf:r.WFdescription✝:Stringpassages✝:HashMap.Raw String RawMazewfAll:∀ (dir : String) (v : RawMaze), passages✝[dir]? = some v → v.WFa✝:passages✝.WFh:{ raw := { description := description✝, passages := passages✝ }, wf := ⋯ }.raw.passages[dir]? = some m'⊢ passages✝[dir]? = some m'
```

