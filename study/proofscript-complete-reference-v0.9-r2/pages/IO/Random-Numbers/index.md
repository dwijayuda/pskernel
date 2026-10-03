<a id="The-Lean-Language-Reference--IO--Random-Numbers"></a>

# ProofScript — 21.10. Random Numbers

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Native IO separates a logical description from execution in a runtime environment. Console operations, mutable references, files, processes, clocks, randomness and tasks have exact APIs and effects. A file handle is a resource with identity and lifetime, not an immutable DTO. Browser, Node and Wasm hosts require explicit adapters; the existence of a Lean API does not establish that every target can implement it.

**Compiler and coverage boundary.** Retain native Task behavior rather than renaming Promise. Resource cleanup, cancellation, process termination and foreign failures need exact declared models; no undocumented async/await keyword is introduced.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [IO/Random-Numbers/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/IO/Random-Numbers/index.html). Source Git blob: `c50f9b6ea316ab2e84bd555500323a036dac2f0e`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 21.10. Random Numbers

<a id="IO___setRandSeed"></a>

**def**

```text
IO.setRandSeed (n : Nat) : BaseIO Unit
```

Seeds the random number generator state used by `IO.rand`.

<a id="IO___rand"></a>

**def**

```text
IO.rand (lo hi : Nat) : BaseIO Nat
```

Returns a pseudorandom number between `lo` and `hi`, using and updating a saved random generator state.

This state can be seeded using `IO.setRandSeed`.

<a id="randBool"></a>

**def**

```text
randBool.{u} {gen : Type u} [RandomGen gen] (g : gen) : Bool × gen
```

Generates a random Boolean.

<a id="randNat"></a>

**def**

```text
randNat.{u} {gen : Type u} [RandomGen gen] (g : gen) (lo hi : Nat) :
  Nat × gen
```

Generates a random natural number in the interval [lo, hi].

<a id="The-Lean-Language-Reference--IO--Random-Numbers--Random-Generators"></a>
### 21.10.1. Random Generators

<a id="RandomGen___mk"></a>

**type class**

```text
RandomGen.{u} (g : Type u) : Type u
```

Interface for random number generators.

**Instance Constructor**

```text
RandomGen.mk.{u}
```

**Methods**

```text
range : g → Nat × Nat
```

`range` returns the range of values returned by the generator.

```text
next : g → Nat × g
```

`next` operation returns a natural number that is uniformly distributed the range returned by `range` (including both end points), and a new generator.

```text
split : g → g × g
```

The 'split' operation allows one to obtain two distinct random number generators. This is very useful in functional programs (for example, when passing a random number generator down to recursive calls).

<a id="StdGen"></a>

**structure**

```text
StdGen : Type
```

"Standard" random number generator.

<a id="stdRange"></a>

**def**

```text
stdRange : Nat × Nat
```

The range of values returned by `StdGen`

<a id="stdNext"></a>

**def**

```text
stdNext : StdGen → Nat × StdGen
```

The next value from a `StdGen`, paired with an updated generator state.

<a id="stdSplit"></a>

**def**

```text
stdSplit : StdGen → StdGen × StdGen
```

Splits a `StdGen` into two separate states.

<a id="mkStdGen"></a>

**def**

```text
mkStdGen (s : Nat := 0) : StdGen
```

Returns a standard number generator.

<a id="The-Lean-Language-Reference--IO--Random-Numbers--System-Randomness"></a>
### 21.10.2. System Randomness

<a id="IO___getRandomBytes"></a>

**opaque**

```text
IO.getRandomBytes (nBytes : USize) : IO ByteArray
```

Reads bytes from a system entropy source. It is not guaranteed to be cryptographically secure.

If `nBytes` is `0`, returns immediately with an empty buffer.
