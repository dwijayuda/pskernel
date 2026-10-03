<a id="coercion-impl-details"></a>

# ProofScript — 11.5. Implementation Details

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Coercions are native elaboration mechanisms, including coercion between types, to sorts and to function types. They are not JavaScript conversions based on truthiness or object prototypes. An implementation must preserve the selected coercion or reject the unsupported case. A foreign value needs an appropriate decoder or model before it can satisfy an owned logical invariant.

**Compiler and coverage boundary.** Record inserted coercions and their dependencies. Do not replace dependent coercions with unchecked target casts.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Coercions/Implementation-Details/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Coercions/Implementation-Details/index.html). Source Git blob: `5effbd5c8ffefc9d6179221d230a0d5475f15911`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 11.5. Implementation Details

Only ordinary coercion insertion uses chaining. Inserting coercions to a [sort](../Coercing-to-Sorts/index.md#sort-coercion) or a [function](../Coercing-to-Function-Types/index.md#fun-coercion) uses ordinary instance synthesis. Similarly, [dependent coercions](../Coercing-Between-Types/index.md#--tech-term-Dependent-coercions) are not chained.

<a id="coercion-unfold-impl"></a>
### 11.5.1. Unfolding Coercions

The coercion insertion mechanism unfolds applications of coercions, which allows them to control the specific shape of the resulting term. This is important both to ensure readable proof goals and to control evaluation of the coerced term in compiled code. Unfolding coercions is controlled by the `coe_decl` attribute, which is applied to each coercion method (e.g. `Coe.coe`). This attribute should be considered part of the internals of the coercion mechanism, rather than part of the public coercion API.

<a id="coercion-chain-impl"></a>
### 11.5.2. Coercion Chaining

Coercion chaining is implemented through a collection of auxiliary type classes. Users should not write instances of these classes directly, but knowledge of their structure can be useful when diagnosing the reason why a coercion was not inserted as expected. The specific rules governing the ordering of instances in the chain (namely, that it should match `CoeHead` `?``CoeOut` `*``Coe` `*``CoeTail` `?`) are implemented by the following type classes:

- `CoeTC` is the transitive closure of `Coe` instances.
- `CoeOTC` is the middle of the chain, consisting of the transitive closure of `CoeOut` instances followed by `CoeTC`.
- `CoeHTC` is the start of the chain, consisting of at most one `CoeHead` instance followed by `CoeOTC`.
- `CoeHTCT` is the whole chain, consisting of `CoeHTC` followed by at most one `CoeTail` instance. Alternatively, it might be a `NatCast` instance.
- `CoeT` represents the entire chain: it is either a `CoeHTCT` chain or a single `CoeDep` instance.

<a id="coe-aux-classes"></a>
  Auxiliary Classes for Coercions
<a id="CoeHTCT___mk"></a>

**type class**

```text
CoeHTCT.{u, v} (α : Sort u) (β : Sort v) : Sort (max (max 1 u) v)
```

Auxiliary class implementing `CoeHead* Coe* CoeTail?`. Users should generally not implement this directly.

**Instance Constructor**

```text
CoeHTCT.mk.{u, v}
```

**Methods**

```text
coe : α → β
```

Coerces a value of type `α` to type `β`. Accessible by the notation `↑x`, or by double type ascription `((x : α) : β)`.

<a id="CoeHTC___mk"></a>

**type class**

```text
CoeHTC.{u, v} (α : Sort u) (β : Sort v) : Sort (max (max 1 u) v)
```

Auxiliary class implementing `CoeHead CoeOut* Coe*`. Users should generally not implement this directly.

**Instance Constructor**

```text
CoeHTC.mk.{u, v}
```

**Methods**

```text
coe : α → β
```

Coerces a value of type `α` to type `β`. Accessible by the notation `↑x`, or by double type ascription `((x : α) : β)`.

<a id="CoeOTC___mk"></a>

**type class**

```text
CoeOTC.{u, v} (α : Sort u) (β : Sort v) : Sort (max (max 1 u) v)
```

Auxiliary class implementing `CoeOut* Coe*`. Users should generally not implement this directly.

**Instance Constructor**

```text
CoeOTC.mk.{u, v}
```

**Methods**

```text
coe : α → β
```

Coerces a value of type `α` to type `β`. Accessible by the notation `↑x`, or by double type ascription `((x : α) : β)`.

<a id="CoeTC___mk"></a>

**type class**

```text
CoeTC.{u, v} (α : Sort u) (β : Sort v) : Sort (max (max 1 u) v)
```

Auxiliary class implementing `Coe*`. Users should generally not implement this directly.

**Instance Constructor**

```text
CoeTC.mk.{u, v}
```

**Methods**

```text
coe : α → β
```

Coerces a value of type `α` to type `β`. Accessible by the notation `↑x`, or by double type ascription `((x : α) : β)`.

## Inherited reference figures

These figures describe the native reference, not a claim about an implemented PSC runtime.

![CoeHead? CoeOut* Coe* CoeTC CoeOTC CoeHTC CoeTail? CoeHTCT CoeDep or CoeT](../../../assets/figures/figure-05.svg)

Caption labels: CoeHead? CoeOut* Coe* CoeTC CoeOTC CoeHTC CoeTail? CoeHTCT CoeDep or CoeT
