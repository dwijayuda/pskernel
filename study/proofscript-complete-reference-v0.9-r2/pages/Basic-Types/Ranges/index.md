<a id="ranges"></a>

# ProofScript — 20.18. Ranges

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Nat, Int, machine integers, floats, characters, strings, bytes, options, products, sums, lists, arrays, maps, ranges, subtypes and lazy computations retain their distinct native contracts. A target representation is not their meaning. Nat subtraction saturates at zero; the selected Int quotient differs from JavaScript BigInt truncation for some negative inputs. String offsets and Unicode conversions require explicit mappings.

**Compiler and coverage boundary.** The full API entries below retain exact names and signature metadata. Distinguish a signature display from executable source. Unknown reachable primitives reject the requested executable profile.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Types/Ranges/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Types/Ranges/index.html). Source Git blob: `4121448366602757c815f496386d3fdb1378c55e`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 20.18. Ranges

A 
<a id="--tech-term-range"></a>
*range* represents a series of consecutive elements of some type, from a lower bound to an upper bound. The bounds may be open, in which case the bound value is not part of the range, or closed, in which case the bound value is part of the range. Either bound may be omitted, in which case the range extends infinitely in the corresponding direction.

Ranges have dedicated syntax that consists of a starting point, `...`, and an ending point. The starting point may be either `*`, which denotes a range that continues infinitely downwards, or a term, which denotes a range with a specific starting value. By default, ranges are left-closed: they contain their starting points. A trailing `<` indicates that the range is left-open and does not contain its starting point. The ending point may be `*`, in which case the range continues infinitely upwards, or a term, which denotes a range with a specific ending value. By default, ranges are right-open: they do not contain their ending points. The ending point may be prefixed with `<` to indicate that it is right-open; this is the default and does not change the meaning, but may be easier to read. It may also be prefixed with `=` to indicate that the range is right-closed and contains its ending point.

<a id="Ranges-of-Natural-Numbers"></a>
Ranges of Natural Numbers 

The range that contains the numbers `3` through `6` can be written in a variety of ways:

```proofscript
#eval (3...7).toList
```

```lean
[3, 4, 5, 6]
```

```proofscript
#eval (3...=6).toList
```

```lean
[3, 4, 5, 6]
```

```proofscript
#eval (2<...=6).toList
```

```lean
[3, 4, 5, 6]
```

<a id="Finite-and-Infinite-Ranges"></a>
Finite and Infinite Ranges 

This range cannot be converted to a list, because it is infinite:

```proofscript
#eval (3...*).toList
```

Finiteness of a left-closed, right-unbounded range is indicated by the presence of an instance of `Std.Rxi.IsAlwaysFinite`, which does not exist for `Nat`. `Std.Rco` is the type of these ranges, and the name `Std.Rxi.IsAlwaysFinite` indicates that it determines finiteness for all right-unbounded ranges.

```lean
failed to synthesize instance of type class
  Std.Rxi.IsAlwaysFinite Nat

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

Attempting to enumerate the negative integers leads to a similar error, this time because there is no way to determine the least element:

```proofscript
#eval (*...(0 : Int)).toList
```

```lean
failed to synthesize instance of type class
  Std.PRange.Least? Int

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

Unbounded ranges in finite types indicate that the range extends to the greatest element of the type. Because `UInt8` has 256 elements, this range contains 253 elements:

```proofscript
#eval ((3 : UInt8)...*).toArray.size
```

```lean
253
```

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Range Syntax**

This range is left-closed, right-open, and indicates `Std.Rco`:

<a id="Std____FLQQ_term____________FLQQ_"></a>

```ebnf
term ::= ...
    | term...term
```

This range is left-closed, right-open, and indicates `Std.Rco`:

<a id="Std____FLQQ_term___________LT___FLQQ_"></a>

```ebnf
term ::= ...
    | term...<term
```

This range is left-closed, right-closed, and indicates `Std.Rcc`:

<a id="Std____FLQQ_term_______________FLQQ_"></a>

```ebnf
term ::= ...
    | term...=term
```

This range is left-closed, right-infinite, and indicates `Std.Rci`:

<a id="Std____FLQQ_term______________FLQQ_"></a>

```ebnf
term ::= ...
    | term...*
```

This range is left-open, right-open, and indicates `Std.Roo`:

<a id="Std____FLQQ_term__LT____________FLQQ_"></a>

```ebnf
term ::= ...
    | term<...term
```

This range is left-open, right-open, and indicates `Std.Roo`:

<a id="Std____FLQQ_term__LT___________LT___FLQQ_"></a>

```ebnf
term ::= ...
    | term<...<term
```

This range is left-open, right-closed, and indicates `Std.Roc`:

<a id="Std____FLQQ_term__LT_______________FLQQ_"></a>

```ebnf
term ::= ...
    | term<...=term
```

This range is left-open, right-infinite, and indicates `Std.Roi`:

<a id="Std____FLQQ_term__LT______________FLQQ_"></a>

```ebnf
term ::= ...
    | term<...*
```

This range is left-infinite, right-open, and indicates `Std.Rio`:

<a id="Std____FLQQ_term______________FLQQ_-next"></a>

```ebnf
term ::= ...
    | *...term
```

This range is left-infinite, right-open, and indicates `Std.Ric`:

<a id="Std____FLQQ_term_____________LT___FLQQ_"></a>

```ebnf
term ::= ...
    | *...<term
```

This range is left-infinite, right-closed, and indicates `Std.Ric`:

<a id="Std____FLQQ_term_________________FLQQ_"></a>

```ebnf
term ::= ...
    | *...=term
```

This range is infinite on both sides, and indicates `Std.Rii`:

<a id="Std____FLQQ_term________________FLQQ_"></a>

```ebnf
term ::= ...
    | *...*
```

<a id="The-Lean-Language-Reference--Basic-Types--Ranges--Range-Types"></a>
### 20.18.1. Range Types

<a id="Std___Rco___mk"></a>

**structure**

```text
Std.Rco.{u} (α : Type u) : Type u
```

A range of elements of `α` with a closed lower bound and an open upper bound.

`a...b` or `a...<b` is the range of all values greater than or equal to `a : α` and less than `b : α`. This is notation for `Rco.mk a b`.

**Constructor**

```text
Std.Rco.mk.{u}
```

**Fields**

```text
lower : α
```

The lower bound of the range. `lower` is included in the range.

```text
upper : α
```

The upper bound of the range. `upper` is not included in the range.

<a id="Std___Rco___iter"></a>

**def**

```text
Std.Rco.iter.{u_1} {α : Type u_1} (r : Std.Rco α) : Std.Iter α
```

Returns an iterator over the given range. This iterator will emit the elements of the range in increasing order.

<a id="Std___Rco___toArray"></a>

**def**

```text
Std.Rco.toArray.{u} {α : Type u} [LT α] [DecidableLT α]
  [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α]
  [Std.Rxo.IsAlwaysFinite α] (r : Std.Rco α) : Array α
```

Returns the elements of the given left-closed right-open range as an array in ascending order.

<a id="Std___Rco___toList"></a>

**def**

```text
Std.Rco.toList.{u} {α : Type u} [LT α] [DecidableLT α]
  [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α]
  [Std.Rxo.IsAlwaysFinite α] (r : Std.Rco α) : List α
```

Returns the elements of the given left-closed right-open range as a list in ascending order.

<a id="Std___Rco___size"></a>

**def**

```text
Std.Rco.size.{u} {α : Type u} [Std.Rxo.HasSize α] (r : Std.Rco α) : Nat
```

Returns the number of elements contained in the given left-closed right-open range.

<a id="Std___Rco___isEmpty"></a>

**def**

```text
Std.Rco.isEmpty.{u} {α : Type u} [LT α] [DecidableLT α]
  [Std.PRange.UpwardEnumerable α] (r : Std.Rco α) : Bool
```

Checks whether the range contains any value.

This function returns a meaningful value given `LawfulUpwardEnumerable` and `LawfulUpwardEnumerableLT` instances.

<a id="Std___Rcc___mk"></a>

**structure**

```text
Std.Rcc.{u} (α : Type u) : Type u
```

A range of elements of `α` with closed lower and upper bounds.

`a...=b` is the range of all values greater than or equal to `a : α` and less than or equal to `b : α`. This is notation for `Rcc.mk a b`.

**Constructor**

```text
Std.Rcc.mk.{u}
```

**Fields**

```text
lower : α
```

The lower bound of the range. `lower` is included in the range.

```text
upper : α
```

The upper bound of the range. `upper` is included in the range.

<a id="Std___Rcc___iter"></a>

**def**

```text
Std.Rcc.iter.{u_1} {α : Type u_1} (r : Std.Rcc α) : Std.Iter α
```

Returns an iterator over the given range. This iterator will emit the elements of the range in increasing order.

<a id="Std___Rcc___toArray"></a>

**def**

```text
Std.Rcc.toArray.{u} {α : Type u} [LE α] [DecidableLE α]
  [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α]
  [Std.Rxc.IsAlwaysFinite α] (r : Std.Rcc α) : Array α
```

Returns the elements of the given closed range as an array in ascending order.

<a id="Std___Rcc___toList"></a>

**def**

```text
Std.Rcc.toList.{u} {α : Type u} [LE α] [DecidableLE α]
  [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α]
  [Std.Rxc.IsAlwaysFinite α] (r : Std.Rcc α) : List α
```

Returns the elements of the given closed range as a list in ascending order.

<a id="Std___Rcc___size"></a>

**def**

```text
Std.Rcc.size.{u} {α : Type u} [Std.Rxc.HasSize α] (r : Std.Rcc α) : Nat
```

Returns the number of elements contained in the given closed range.

<a id="Std___Rcc___isEmpty"></a>

**def**

```text
Std.Rcc.isEmpty.{u} {α : Type u} [LE α] [DecidableLE α]
  [Std.PRange.UpwardEnumerable α] (r : Std.Rcc α) : Bool
```

Checks whether the range contains any value.

This function returns a meaningful value given `LawfulUpwardEnumerable` and `LawfulUpwardEnumerableLE` instances.

<a id="Std___Rci___mk"></a>

**structure**

```text
Std.Rci.{u} (α : Type u) : Type u
```

An upward-unbounded range of elements of `α` with a closed lower bound.

`a...*` is the range of all values greater than or equal to `a : α`. This is notation for `Rci.mk a`.

**Constructor**

```text
Std.Rci.mk.{u}
```

**Fields**

```text
lower : α
```

The lower bound of the range. `lower` is included in the range.

<a id="Std___Rci___iter"></a>

**def**

```text
Std.Rci.iter.{u_1} {α : Type u_1} (r : Std.Rci α) : Std.Iter α
```

Returns an iterator over the given range. This iterator will emit the elements of the range in increasing order.

<a id="Std___Rci___toArray"></a>

**def**

```text
Std.Rci.toArray.{u} {α : Type u} [Std.PRange.UpwardEnumerable α]
  [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxi.IsAlwaysFinite α]
  (r : Std.Rci α) : Array α
```

Returns the elements of the given left-closed right-unbounded range as an array in ascending order.

<a id="Std___Rci___toList"></a>

**def**

```text
Std.Rci.toList.{u} {α : Type u} [Std.PRange.UpwardEnumerable α]
  [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxi.IsAlwaysFinite α]
  (r : Std.Rci α) : List α
```

Returns the elements of the given left-closed right-unbounded range as a list in ascending order.

<a id="Std___Rci___size"></a>

**def**

```text
Std.Rci.size.{u} {α : Type u} [Std.Rxi.HasSize α] (r : Std.Rci α) : Nat
```

Returns the number of elements contained in the given left-closed right-unbounded range.

<a id="Std___Rci___isEmpty"></a>

**def**

```text
Std.Rci.isEmpty.{u} {α : Type u} [Std.PRange.UpwardEnumerable α] :
  Std.Rci α → Bool
```

Checks whether the range contains any value. This function exists for completeness and always returns false: The closed lower bound is contained in the range, so left-closed right-unbounded ranges are never empty.

<a id="Std___Roo___mk"></a>

**structure**

```text
Std.Roo.{u} (α : Type u) : Type u
```

A range of elements of `α` with an open lower and upper bounds.

`a<...b` or `a<...<b` is the range of all values greater than `a : α` and less than `b : α`. This is notation for `Roo.mk a b`.

**Constructor**

```text
Std.Roo.mk.{u}
```

**Fields**

```text
lower : α
```

The lower bound of the range. `lower` is not included in the range.

```text
upper : α
```

The upper bound of the range. `upper` is not included in the range.

<a id="Std___Roo___iter"></a>

**def**

```text
Std.Roo.iter.{u_1} {α : Type u_1} [Std.PRange.UpwardEnumerable α]
  (r : Std.Roo α) : Std.Iter α
```

Returns an iterator over the given range. This iterator will emit the elements of the range in increasing order.

<a id="Std___Roo___toArray"></a>

**def**

```text
Std.Roo.toArray.{u} {α : Type u} [LT α] [DecidableLT α]
  [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α]
  [Std.Rxo.IsAlwaysFinite α] (r : Std.Roo α) : Array α
```

Returns the elements of the given open range as an array in ascending order.

<a id="Std___Roo___toList"></a>

**def**

```text
Std.Roo.toList.{u} {α : Type u} [LT α] [DecidableLT α]
  [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α]
  [Std.Rxo.IsAlwaysFinite α] (r : Std.Roo α) : List α
```

Returns the elements of the given open range as a list in ascending order.

<a id="Std___Roo___size"></a>

**def**

```text
Std.Roo.size.{u} {α : Type u} [Std.Rxo.HasSize α]
  [Std.PRange.UpwardEnumerable α] (r : Std.Roo α) : Nat
```

Returns the number of elements contained in the given open range.

<a id="Std___Roo___isEmpty"></a>

**def**

```text
Std.Roo.isEmpty.{u} {α : Type u} [LT α] [DecidableLT α]
  [Std.PRange.UpwardEnumerable α] (r : Std.Roo α) : Bool
```

Checks whether the range contains any value.

This function returns a meaningful value given `LawfulUpwardEnumerable` and `LawfulUpwardEnumerableLT` instances.

<a id="Std___Roc___mk"></a>

**structure**

```text
Std.Roc.{u} (α : Type u) : Type u
```

A range of elements of `α` with an open lower bound and a closed upper bound.

`a<...=b` is the range of all values greater than `a : α` and less than or equal to `b : α`. This is notation for `Roc.mk a b`.

**Constructor**

```text
Std.Roc.mk.{u}
```

**Fields**

```text
lower : α
```

The lower bound of the range. `lower` is not included in the range.

```text
upper : α
```

The upper bound of the range. `upper` is included in the range.

<a id="Std___Roc___iter"></a>

**def**

```text
Std.Roc.iter.{u_1} {α : Type u_1} [Std.PRange.UpwardEnumerable α]
  (r : Std.Roc α) : Std.Iter α
```

Returns an iterator over the given range. This iterator will emit the elements of the range in increasing order.

<a id="Std___Roc___toArray"></a>

**def**

```text
Std.Roc.toArray.{u} {α : Type u} [LE α] [DecidableLE α]
  [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α]
  [Std.Rxc.IsAlwaysFinite α] (r : Std.Roc α) : Array α
```

Returns the elements of the given left-open right-closed range as an array in ascending order.

<a id="Std___Roc___toList"></a>

**def**

```text
Std.Roc.toList.{u} {α : Type u} [LE α] [DecidableLE α]
  [Std.PRange.UpwardEnumerable α] [Std.PRange.LawfulUpwardEnumerable α]
  [Std.Rxc.IsAlwaysFinite α] (r : Std.Roc α) : List α
```

Returns the elements of the given left-open right-closed range as a list in ascending order.

<a id="Std___Roc___size"></a>

**def**

```text
Std.Roc.size.{u} {α : Type u} [Std.Rxc.HasSize α]
  [Std.PRange.UpwardEnumerable α] (r : Std.Roc α) : Nat
```

Returns the number of elements contained in the given left-open right-closed range.

<a id="Std___Roc___isEmpty"></a>

**def**

```text
Std.Roc.isEmpty.{u} {α : Type u} [LT α] [DecidableLT α]
  [Std.PRange.UpwardEnumerable α] (r : Std.Roc α) : Bool
```

Checks whether the range contains any value.

This function returns a meaningful value given `LawfulUpwardEnumerable` and `LawfulUpwardEnumerableLT` instances.

<a id="Std___Roi___mk"></a>

**structure**

```text
Std.Roi.{u} (α : Type u) : Type u
```

An upward-unbounded range of elements of `α` with an open lower bound.

`a<...*` is the range of all values greater than `a : α`. This is notation for `Roi.mk a`.

**Constructor**

```text
Std.Roi.mk.{u}
```

**Fields**

```text
lower : α
```

The lower bound of the range. `lower` is not included in the range.

<a id="Std___Roi___iter"></a>

**def**

```text
Std.Roi.iter.{u_1} {α : Type u_1} [Std.PRange.UpwardEnumerable α]
  (r : Std.Roi α) : Std.Iter α
```

Returns an iterator over the given range. This iterator will emit the elements of the range in increasing order.

<a id="Std___Roi___toArray"></a>

**def**

```text
Std.Roi.toArray.{u} {α : Type u} [Std.PRange.UpwardEnumerable α]
  [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxi.IsAlwaysFinite α]
  (r : Std.Roi α) : Array α
```

Returns the elements of the given left-open right-unbounded range as an array in ascending order.

<a id="Std___Roi___toList"></a>

**def**

```text
Std.Roi.toList.{u} {α : Type u} [Std.PRange.UpwardEnumerable α]
  [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxi.IsAlwaysFinite α]
  (r : Std.Roi α) : List α
```

Returns the elements of the given left-open right-unbounded range as a list in ascending order.

<a id="Std___Roi___size"></a>

**def**

```text
Std.Roi.size.{u} {α : Type u} [Std.Rxi.HasSize α]
  [Std.PRange.UpwardEnumerable α] (r : Std.Roi α) : Nat
```

Returns the number of elements contained in the given left-open right-unbounded range.

<a id="Std___Roi___isEmpty"></a>

**def**

```text
Std.Roi.isEmpty.{u} {α : Type u} [Std.PRange.UpwardEnumerable α]
  (r : Std.Roi α) : Bool
```

Checks whether the range contains any value.

This function returns a meaningful value given a `LawfulUpwardEnumerable` instance.

<a id="Std___Rio___mk"></a>

**structure**

```text
Std.Rio.{u} (α : Type u) : Type u
```

A downward-unbounded range of elements of `α` with an open upper bound.

`*...b` or `*...<b` is the range of all values less than `b : α`. This is notation for `Rio.mk b`.

**Constructor**

```text
Std.Rio.mk.{u}
```

**Fields**

```text
upper : α
```

The upper bound of the range. `upper` is not included in the range.

<a id="Std___Rio___iter"></a>

**def**

```text
Std.Rio.iter.{u_1} {α : Type u_1} [Std.PRange.Least? α]
  (r : Std.Rio α) : Std.Iter α
```

Returns an iterator over the given range. This iterator will emit the elements of the range in increasing order.

<a id="Std___Rio___toArray"></a>

**def**

```text
Std.Rio.toArray.{u} {α : Type u} [Std.PRange.Least? α] [LT α]
  [DecidableLT α] [Std.PRange.UpwardEnumerable α]
  [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxo.IsAlwaysFinite α]
  (r : Std.Rio α) : Array α
```

Returns the elements of the given closed range as an array in ascending order.

<a id="Std___Rio___toList"></a>

**def**

```text
Std.Rio.toList.{u} {α : Type u} [Std.PRange.Least? α] [LT α]
  [DecidableLT α] [Std.PRange.UpwardEnumerable α]
  [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxo.IsAlwaysFinite α]
  (r : Std.Rio α) : List α
```

Returns the elements of the given closed range as a list in ascending order.

<a id="Std___Rio___size"></a>

**def**

```text
Std.Rio.size.{u} {α : Type u} [Std.Rxo.HasSize α] [Std.PRange.Least? α]
  (r : Std.Rio α) : Nat
```

Returns the number of elements contained in the given closed range.

<a id="Std___Rio___isEmpty"></a>

**def**

```text
Std.Rio.isEmpty.{u} {α : Type u} [LT α] [DecidableLT α]
  [Std.PRange.UpwardEnumerable α] [Std.PRange.Least? α]
  (r : Std.Rio α) : Bool
```

Checks whether the range contains any value.

This function returns a meaningful value given `LawfulUpwardEnumerable`, `LawfulUpwardEnumerableLT` and `LawfulUpwardEnumerableLeast?` instances.

<a id="Std___Ric___mk"></a>

**structure**

```text
Std.Ric.{u} (α : Type u) : Type u
```

A downward-unbounded range of elements of `α` with a closed upper bound.

`*...=b` is the range of all values less than or equal to `b : α`. This is notation for `Ric.mk b`.

**Constructor**

```text
Std.Ric.mk.{u}
```

**Fields**

```text
upper : α
```

The upper bound of the range. `upper` is included in the range.

<a id="Std___Ric___iter"></a>

**def**

```text
Std.Ric.iter.{u_1} {α : Type u_1} [Std.PRange.Least? α]
  (r : Std.Ric α) : Std.Iter α
```

Returns an iterator over the given range. This iterator will emit the elements of the range in increasing order.

<a id="Std___Ric___toArray"></a>

**def**

```text
Std.Ric.toArray.{u} {α : Type u} [Std.PRange.Least? α] [LE α]
  [DecidableLE α] [Std.PRange.UpwardEnumerable α]
  [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxc.IsAlwaysFinite α]
  (r : Std.Ric α) : Array α
```

Returns the elements of the given closed range as an array in ascending order.

<a id="Std___Ric___toList"></a>

**def**

```text
Std.Ric.toList.{u} {α : Type u} [Std.PRange.Least? α] [LE α]
  [DecidableLE α] [Std.PRange.UpwardEnumerable α]
  [Std.PRange.LawfulUpwardEnumerable α] [Std.Rxc.IsAlwaysFinite α]
  (r : Std.Ric α) : List α
```

Returns the elements of the given closed range as a list in ascending order.

<a id="Std___Ric___size"></a>

**def**

```text
Std.Ric.size.{u} {α : Type u} [Std.Rxc.HasSize α] [Std.PRange.Least? α]
  (r : Std.Ric α) : Nat
```

Returns the number of elements contained in the given closed range.

<a id="Std___Ric___isEmpty"></a>

**def**

```text
Std.Ric.isEmpty.{u} {α : Type u} [Std.PRange.UpwardEnumerable α] :
  Std.Ric α → Bool
```

Checks whether the range contains any value. This function exists for completeness and always returns false: The closed upper bound is contained in the range, so left-unbounded right-closed ranges are never empty.

<a id="Std___Rii___mk"></a>

**structure**

```text
Std.Rii.{u} (α : Type u) : Type
```

A full range of all elements of `α`. Its only inhabitant is the range `*...*`, which is notation for `Rii.mk`.

**Constructor**

```text
Std.Rii.mk.{u}
```

<a id="Std___Rii___iter"></a>

**def**

```text
Std.Rii.iter.{u_1} {α : Type u_1} [Std.PRange.Least? α] :
  Std.Rii α → Std.Iter α
```

Returns an iterator over the given range. This iterator will emit the elements of the range in increasing order.

<a id="Std___Rii___toArray"></a>

**def**

```text
Std.Rii.toArray.{u_1} {α : Type u_1} [Std.PRange.UpwardEnumerable α]
  [Std.PRange.Least? α] (r : Std.Rii α)
  [Std.Iterator (Std.Rxi.Iterator α) Id α]
  [Std.Iterators.Finite (Std.Rxi.Iterator α) Id] : Array α
```

Returns the elements of the given full range as an array in ascending order.

<a id="Std___Rii___toList"></a>

**def**

```text
Std.Rii.toList.{u} {α : Type u} [Std.PRange.UpwardEnumerable α]
  [Std.PRange.Least? α] (r : Std.Rii α)
  [Std.Iterator (Std.Rxi.Iterator α) Id α]
  [Std.Iterators.Finite (Std.Rxi.Iterator α) Id] : List α
```

Returns the elements of the given full range as a list in ascending order.

<a id="Std___Rii___size"></a>

**def**

```text
Std.Rii.size.{u} {α : Type u} :
  Std.Rii α → [Std.PRange.Least? α] → [Std.Rxi.HasSize α] → Nat
```

Returns the number of elements contained in the full range.

<a id="Std___Rii___isEmpty"></a>

**def**

```text
Std.Rii.isEmpty.{u} {α : Type u} [Std.PRange.Least? α] :
  Std.Rii α → Bool
```

Checks whether the range contains any value.

This function returns a meaningful value given `LawfulUpwardEnumerable` and `LawfulUpwardEnumerableLeast?` instances.

<a id="The-Lean-Language-Reference--Basic-Types--Ranges--Range-Related-Type-Classes"></a>
### 20.18.2. Range-Related Type Classes

<a id="Std___PRange___UpwardEnumerable___mk"></a>

**type class**

```text
Std.PRange.UpwardEnumerable.{u} (α : Type u) : Type u
```

This typeclass provides the function `succ? : α → Option α` that computes the successor of elements of `α`, or none if no successor exists. It also provides the function `succMany?`, which computes `n`-th successors.

`succ?` is expected to be acyclic: No element is its own transitive successor. If `α` is ordered, then every element larger than `a : α` should be a transitive successor of `a`. These properties and the compatibility of `succ?` with `succMany?` are encoded in the typeclasses `LawfulUpwardEnumerable`, `LawfulUpwardEnumerableLE` and `LawfulUpwardEnumerableLT`.

**Instance Constructor**

```text
Std.PRange.UpwardEnumerable.mk.{u}
```

**Methods**

```text
succ? : α → Option α
```

Maps elements of `α` to their successor, or none if no successor exists.

```text
succMany? : Nat → α → Option α
```

Maps elements of `α` to their `n`-th successor, or none if no successor exists. This should semantically behave like repeatedly applying `succ?`, but it might be more efficient.

`LawfulUpwardEnumerable` ensures the compatibility with `succ?`.

If no other implementation is provided in `UpwardEnumerable` instance, `succMany?` repeatedly applies `succ?`.

<a id="Std___PRange___UpwardEnumerable___LE"></a>

**def**

```text
Std.PRange.UpwardEnumerable.LE.{u} {α : Type u}
  [Std.PRange.UpwardEnumerable α] (a b : α) : Prop
```

According to `UpwardEnumerable.LE`, `a` is less than or equal to `b` if `b` is `a` or a transitive successor of `a`.

<a id="Std___PRange___UpwardEnumerable___LT"></a>

**def**

```text
Std.PRange.UpwardEnumerable.LT.{u} {α : Type u}
  [Std.PRange.UpwardEnumerable α] (a b : α) : Prop
```

According to `UpwardEnumerable.LT`, `a` is less than `b` if `b` is a proper transitive successor of `a`. 'Proper' means that `b` is the `n`-th successor of `a`, where `n > 0`.

Given `LawfulUpwardEnumerable α`, no element of `α` is less than itself.

<a id="Std___PRange___LawfulUpwardEnumerable___mk"></a>

**type class**

```text
Std.PRange.LawfulUpwardEnumerable.{u} (α : Type u)
  [Std.PRange.UpwardEnumerable α] : Prop
```

This typeclass ensures that an `UpwardEnumerable α` instance is well-behaved.

**Instance Constructor**

```text
Std.PRange.LawfulUpwardEnumerable.mk.{u}
```

**Methods**

```text
ne_of_lt : ∀ (a b : α), Std.PRange.UpwardEnumerable.LT a b → a ≠ b
```

There is no cyclic chain of successors.

```text
succMany?_zero : ∀ (a : α), Std.PRange.succMany? 0 a = some a
```

The `0`-th successor of `a` is `a` itself.

```text
succMany?_add_one : ∀ (n : Nat) (a : α), Std.PRange.succMany? (n + 1) a = (Std.PRange.succMany? n a).bind Std.PRange.succ?
```

The `n + 1`-th successor of `a` is the successor of the `n`-th successor, given that said successors actually exist.

<a id="Std___PRange___Least______mk"></a>

**type class**

```text
Std.PRange.Least?.{u} (α : Type u) : Type u
```

The typeclass `Least? α` optionally provides a smallest element of `α`, `least? : Option α`.

The main use case of this typeclass is to use it in combination with `UpwardEnumerable` to obtain a (possibly infinite) ascending enumeration of all elements of `α`.

**Instance Constructor**

```text
Std.PRange.Least?.mk.{u}
```

**Methods**

```text
least? : Option α
```

Returns the smallest element of `α`, or none if `α` is empty.

Only empty types are allowed to define `least? := none`. If `α` is ordered and nonempty, then the value of `least?` should be the smallest element according to the order on `α`.

<a id="Std___PRange___InfinitelyUpwardEnumerable___mk"></a>

**type class**

```text
Std.PRange.InfinitelyUpwardEnumerable.{u} (α : Type u)
  [Std.PRange.UpwardEnumerable α] : Prop
```

This propositional typeclass ensures that `UpwardEnumerable.succ?` will never return `none`. In other words, it ensures that there will always be a successor.

**Instance Constructor**

```text
Std.PRange.InfinitelyUpwardEnumerable.mk.{u}
```

**Methods**

```text
isSome_succ? : ∀ (a : α), (Std.PRange.succ? a).isSome = true
```

Every element of `α` has a successor.

<a id="Std___PRange___LinearlyUpwardEnumerable___mk"></a>

**type class**

```text
Std.PRange.LinearlyUpwardEnumerable.{u} (α : Type u)
  [Std.PRange.UpwardEnumerable α] : Prop
```

This propositional typeclass ensures that `UpwardEnumerable.succ?` is injective.

**Instance Constructor**

```text
Std.PRange.LinearlyUpwardEnumerable.mk.{u}
```

**Methods**

```text
eq_of_succ?_eq : ∀ (a b : α), Std.PRange.succ? a = Std.PRange.succ? b → a = b
```

The implementation of `UpwardEnumerable.succ?` for `α` is injective.

<a id="Std___Rxi___IsAlwaysFinite___mk"></a>

**type class**

```text
Std.Rxi.IsAlwaysFinite.{u} (α : Type u)
  [Std.PRange.UpwardEnumerable α] : Prop
```

This type class ensures that right-unbounded ranges (i.e., for a bound `a`, `a...*`, `a<...*` and `*...*`) are always finite. This is a prerequisite for many functions and instances, such as `Rci.toList` or `ForIn'`.

**Instance Constructor**

```text
Std.Rxi.IsAlwaysFinite.mk.{u}
```

**Methods**

```text
finite : ∀ (init : α), ∃ n, Std.PRange.succMany? n init = none
```

For every elements `init`, there exists a chain of successors that results in an element that has no successors.

<a id="Std___Rxi___HasSize___mk"></a>

**type class**

```text
Std.Rxi.HasSize.{u} (α : Type u) : Type u
```

This typeclass provides support for the size function for ranges with closed lower bound (`Ric.size`, `Rio.size` and `Rii.size`).

The returned size should be equal to the number of elements returned by `toList`. This condition is captured by the typeclass `LawfulHasSize`.

**Instance Constructor**

```text
Std.Rxi.HasSize.mk.{u}
```

**Methods**

```text
size : α → Nat
```

Returns the number of elements starting from `lo` that satisfy the given upper bound.

<a id="Std___Rxc___IsAlwaysFinite___mk"></a>

**type class**

```text
Std.Rxc.IsAlwaysFinite.{u} (α : Type u) [Std.PRange.UpwardEnumerable α]
  [LE α] : Prop
```

This type class ensures that right-closed ranges (i.e., for bounds `a` and `b`, `a...=b`, `a<...=b` and `*...=b`) are always finite. This is a prerequisite for many functions and instances, such as `Rcc.toList` or `ForIn'`.

**Instance Constructor**

```text
Std.Rxc.IsAlwaysFinite.mk.{u}
```

**Methods**

```text
finite : ∀ (init hi : α), ∃ n, (Std.PRange.succMany? n init).elim True fun x => ¬x ≤ hi
```

For every pair of elements `init` and `hi`, there exists a chain of successors that results in an element that either has no successors or is greater than `hi`.

<a id="Std___Rxc___HasSize___mk"></a>

**type class**

```text
Std.Rxc.HasSize.{u} (α : Type u) : Type u
```

This typeclass provides support for the size function for ranges with closed lower bound (`Rcc.size`, `Rco.size` and `Rci.size`).

The returned size should be equal to the number of elements returned by `toList`. This condition is captured by the typeclass `LawfulHasSize`.

**Instance Constructor**

```text
Std.Rxc.HasSize.mk.{u}
```

**Methods**

```text
size : α → α → Nat
```

Returns the number of elements starting from `lo` that satisfy the given upper bound.

<a id="The-Lean-Language-Reference--Basic-Types--Ranges--Implementing-Ranges"></a>
### 20.18.3. Implementing Ranges

The built-in range types may be used with any type, but their usefulness depends on the presence of certain type class instances. Generally speaking, ranges are either checked for membership, enumerated or iterated over. To check whether an value is contained in a range, `DecidableLT` and `DecidableLE` instances are used to compare the value to the range's respective open and closed endpoints. To get an iterator for a range, instances of `Std.PRange.UpwardEnumerable` and `Std.PRange.LawfulUpwardEnumerable` are all that's needed. To iterate directly over it in a `for` loop, `Std.PRange.LawfulUpwardEnumerableLE` and `Std.PRange.LawfulUpwardEnumerableLT` are required as well. To enumerate a range (e.g. by calling `toList`), it must be proven finite. This is done by supplying instances of `Std.Rxi.IsAlwaysFinite`, `Std.Rxc.IsAlwaysFinite`, or `Std.Rxo.IsAlwaysFinite`.

<a id="Implementing-Ranges"></a>
Implementing Ranges 

The enumeration type `Day` represents the days of the week:
<a id="Day-_LPAR_in-Implementing-Ranges_RPAR_"></a>
<a id="Day___mo-_LPAR_in-Implementing-Ranges_RPAR_"></a>
<a id="Day___tu-_LPAR_in-Implementing-Ranges_RPAR_"></a>
<a id="Day___we-_LPAR_in-Implementing-Ranges_RPAR_"></a>
<a id="Day___th-_LPAR_in-Implementing-Ranges_RPAR_"></a>
<a id="Day___fr-_LPAR_in-Implementing-Ranges_RPAR_"></a>
<a id="Day___sa-_LPAR_in-Implementing-Ranges_RPAR_"></a>
<a id="Day___su-_LPAR_in-Implementing-Ranges_RPAR_"></a>


```proofscript
inductive Day where
  | mo | tu | we | th | fr | sa | su
deriving Repr
```

While it's already possible to use this type in ranges, they're not particularly useful. There's no membership instance:

```proofscript
#eval Day.we ∈ (Day.mo...=Day.fr)
```

```lean
failed to synthesize instance of type class
  Membership Day (Std.Rcc Day)

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

Ranges can't be iterated over:

```proofscript
#eval show IO Unit from
  for d in Day.mo...=Day.fr do
    IO.println s!"It's {repr d}"
```

```lean
failed to synthesize instance of type class
  ForIn IO (Std.Rcc Day) ?α

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

Nor can they be enumerated, even though the type is finite:

```proofscript
#eval (Day.sa...*).toList
```

```lean
failed to synthesize instance of type class
  Std.PRange.UpwardEnumerable Day

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

Membership tests require `DecidableLT` and `DecidableLE` instances. An easy way to get these is to number each day, and compare the numbers:
<a id="Day___toNat-_LPAR_in-Implementing-Ranges_RPAR_"></a>


```proofscript
def Day.toNat : Day → Nat
  | mo => 0
  | tu => 1
  | we => 2
  | th => 3
  | fr => 4
  | sa => 5
  | su => 6

instance : LT Day where
  lt d1 d2 := d1.toNat < d2.toNat

instance : LE Day where
  le d1 d2 := d1.toNat ≤ d2.toNat

instance : DecidableLT Day :=
  fun d1 d2 => inferInstanceAs (Decidable (d1.toNat < d2.toNat))

instance : DecidableLE Day :=
  fun d1 d2 => inferInstanceAs (Decidable (d1.toNat ≤ d2.toNat))
```

With these instances available, membership tests work as expected:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Day___isWeekday-_LPAR_in-Implementing-Ranges_RPAR_"></a>


```proofscript
function Day.isWeekday (d : Day) : Bool := d ∈ Day.mo...Day.sa
```

```proofscript
#eval Day.th.isWeekday
```

```lean
true
```

```proofscript
#eval Day.sa.isWeekday
```

```lean
false
```

Iteration and enumeration are both variants on repeatedly applying a successor function until either the upper bound of the range or the largest element of the type is reached. This successor function is `Std.PRange.UpwardEnumerable.succ?`. It's also convenient to have a definition of the function in `Day`'s namespace for use with generalized field notation:
<a id="Day___succ___-_LPAR_in-Implementing-Ranges_RPAR_"></a>


```proofscript
def Day.succ? : Day → Option Day
  | mo => some tu
  | tu => some we
  | we => some th
  | th => some fr
  | fr => some sa
  | sa => some su
  | su => none

instance : Std.PRange.UpwardEnumerable Day where
  succ? := Day.succ?
```

Iteration also requires a proof that the implementation of `succ?` is sensible. Its properties are expressed in terms of `Std.PRange.UpwardEnumerable.succMany?`, which iterates the application of `succ?` a certain number of times and has a default implementation in terms of `Nat.repeat` and `succ?`. In particular, an instance of `LawfulUpwardEnumerable` requires proofs that `Std.PRange.UpwardEnumerable.succMany?` corresponds to the default implementation along with a proof that repeatedly applying the successor never yields the same element again.

The first step is to write two helper lemmas for the two proofs about `succMany?`. While they could be written inline in the instance declaration, it's convenient for them to have the `@[simp]` attribute.
<a id="Day___succMany____zero-_LPAR_in-Implementing-Ranges_RPAR_"></a>
<a id="Day___succMany____add_one-_LPAR_in-Implementing-Ranges_RPAR_"></a>


```proofscript
@[simp]
theorem Day.succMany?_zero (d : Day) :
  Std.PRange.succMany? 0 d = some d := by
  simp [Std.PRange.succMany?, Nat.repeat]

@[simp]
theorem Day.succMany?_add_one (n : Nat) (d : Day) :
    Std.PRange.succMany? (n + 1) d =
    (Std.PRange.succMany? n d).bind Std.PRange.succ? := by
  simp [Std.PRange.succMany?, Nat.repeat, Std.PRange.succ?]
```

Proving that there are no cycles in successor uses a convenient helper lemma that calculates the number of successor steps between any two days. It is marked `@[grind →]` because when assumptions that match its premises are present, it adds a great deal of new information:
<a id="Day___succMany____steps-_LPAR_in-Implementing-Ranges_RPAR_"></a>


```proofscript
@[grind →]
theorem Day.succMany?_steps {d d' : Day} {steps} :
    Std.PRange.succMany? steps d = some d' →
    if d ≤ d' then steps = d'.toNat - d.toNat
    else False := by
  intro h
  match steps with
  | 0 | 1 | 2 | 3 | 4 | 5 | 6 =>
    cases d <;> cases d' <;>
    simp_all +decide [Std.PRange.succMany?, Nat.repeat, Day.succ?]
  | n + 7 =>
    simp at h
    cases h' : (Std.PRange.succMany? n d) with
    | none =>
      simp_all
    | some d'' =>
      rw [h'] at h
      cases d'' <;> contradiction
```

With that helper, the proof is quite short:

```proofscript
instance : Std.PRange.LawfulUpwardEnumerable Day where
  ne_of_lt d1 d2 h := by grind [Std.PRange.UpwardEnumerable.LT]
  succMany?_zero := Day.succMany?_zero
  succMany?_add_one := Day.succMany?_add_one
```

Proving the three kinds of enumerable ranges to be finite makes it possible to enumerate ranges of days:

```proofscript
instance : Std.Rxo.IsAlwaysFinite Day where
  finite init hi :=
    ⟨7, by cases init <;> simp [Std.PRange.succ?, Day.succ?]⟩

instance : Std.Rxc.IsAlwaysFinite Day where
  finite init hi :=
    ⟨7, by cases init <;> simp [Std.PRange.succ?, Day.succ?]⟩

instance : Std.Rxi.IsAlwaysFinite Day where
  finite init := ⟨7, by cases init <;> rfl⟩
```

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="allWeekdays-_LPAR_in-Implementing-Ranges_RPAR_"></a>


```proofscript
const allWeekdays : List Day := (Day.mo...Day.sa).toList
#eval allWeekdays
```

```lean
[Day.mo, Day.tu, Day.we, Day.th, Day.fr]
```

Adding a `Std.PRange.Least?` instance allows enumeration of left-unbounded ranges:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="allWeekdays___-_LPAR_in-Implementing-Ranges_RPAR_"></a>


```proofscript
instance : Std.PRange.Least? Day where
  least? := some .mo

const allWeekdays' : List Day := (*...Day.sa).toList
#eval allWeekdays'
```

```lean
[Day.mo, Day.tu, Day.we, Day.th, Day.fr]
```

It's also possible to create an iterator that can be enumerated, but it can't yet be used with `for`:

```proofscript
#eval (Day.we...Day.fr).iter.toList
```

```lean
[Day.we, Day.th]
```

```proofscript
#eval show IO Unit from do
  for d in (Day.mo...Day.th).iter do
    IO.println s!"It's {repr d}."
```

```lean
failed to synthesize instance of type class
  ForIn IO (Std.Iter Day) ?α

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

The last step to enable iteration, thus making ranges of days fully-featured, is to prove that the less-than and less-than-or-equal-to relations on `Day` correspond to the notions of inequality that are derived from iterating the successor function. This is captured in the classes `Std.PRange.LawfulUpwardEnumerableLT` and `Std.PRange.LawfulUpwardEnumerableLE`, which require that the two notions are logically equivalent:

```proofscript
instance : Std.PRange.LawfulUpwardEnumerableLT Day where
  lt_iff d1 d2 := by
    constructor
    . intro lt
      simp only [Std.PRange.UpwardEnumerable.LT, Day.succMany?_add_one]
      exists d2.toNat - d1.toNat.succ
      cases d1 <;> cases d2 <;>
      simp_all [Day.toNat, Std.PRange.succ?, Day.succ?] <;>
      contradiction
    . intro ⟨steps, eq⟩
      have := Day.succMany?_steps eq
      cases d1 <;> cases d2 <;>
      simp only [if_false_right] at this <;>
      cases this <;> first | decide | contradiction

instance : Std.PRange.LawfulUpwardEnumerableLE Day where
  le_iff d1 d2 := by
    constructor
    . intro le
      simp only [Std.PRange.UpwardEnumerable.LE]
      exists d2.toNat - d1.toNat
      cases d1 <;> cases d2 <;>
      simp_all [Day.toNat, Std.PRange.succ?, Day.succ?] <;>
      contradiction
    . intro ⟨steps, eq⟩
      have := Day.succMany?_steps eq
      cases d1 <;> cases d2 <;>
      simp only [if_false_right] at this <;>
      cases this <;> grind
```

It is now possible to iterate over ranges of days:

```proofscript
#eval show IO Unit from do
  for x in (Day.mo...Day.th).iter do
    IO.println s!"It's {repr x}"
```

```lean
It's Day.mo
It's Day.tu
It's Day.we
```

<a id="The-Lean-Language-Reference--Basic-Types--Ranges--Ranges-and-Slices"></a>
### 20.18.4. Ranges and Slices

Range syntax can be used with data structures that support slicing to select a slice of the structure.

<a id="Slicing-Lists"></a>
Slicing Lists 

Lists may be sliced with any of the interval types:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="groceries-_LPAR_in-Slicing-Lists_RPAR_"></a>


```proofscript
const groceries :=
  ["apples", "bananas", "coffee", "dates", "endive", "fennel"]
```

```proofscript
#eval groceries[1...4] |>.toList
```

```lean
["bananas", "coffee", "dates"]
```

```proofscript
#eval groceries[1...=4] |>.toList
```

```lean
["bananas", "coffee", "dates", "endive"]
```

```proofscript
#eval groceries[1...*] |>.toList
```

```lean
["bananas", "coffee", "dates", "endive", "fennel"]
```

```proofscript
#eval groceries[1<...4] |>.toList
```

```lean
["coffee", "dates"]
```

```proofscript
#eval groceries[1<...=4] |>.toList
```

```lean
["coffee", "dates", "endive"]
```

```proofscript
#eval groceries[*...=4] |>.toList
```

```lean
["apples", "bananas", "coffee", "dates", "endive"]
```

```proofscript
#eval groceries[*...4] |>.toList
```

```lean
["apples", "bananas", "coffee", "dates"]
```

```proofscript
#eval groceries[*...*] |>.toList
```

```lean
["apples", "bananas", "coffee", "dates", "endive", "fennel"]
```

<a id="Custom-Slices"></a>
Custom Slices 

A `Triple` contains three values of the same type:
<a id="Triple-_LPAR_in-Custom-Slices_RPAR_"></a>
<a id="Triple___fst-_LPAR_in-Custom-Slices_RPAR_"></a>
<a id="Triple___snd-_LPAR_in-Custom-Slices_RPAR_"></a>
<a id="Triple___thd-_LPAR_in-Custom-Slices_RPAR_"></a>


```proofscript
structure Triple (α : Type u) where
  fst : α
  snd : α
  thd : α
deriving Repr
```

Positions in a triple may be any of the fields, or just after `thd`:
<a id="TriplePos-_LPAR_in-Custom-Slices_RPAR_"></a>
<a id="TriplePos___fst-_LPAR_in-Custom-Slices_RPAR_"></a>
<a id="TriplePos___snd-_LPAR_in-Custom-Slices_RPAR_"></a>
<a id="TriplePos___thd-_LPAR_in-Custom-Slices_RPAR_"></a>
<a id="TriplePos___done-_LPAR_in-Custom-Slices_RPAR_"></a>


```proofscript
inductive TriplePos where
  | fst | snd | thd | done
deriving Repr
```

A slice of a triple consists of a triple, a starting position, and a stopping position. The starting position is inclusive, and the stopping position exclusive:
<a id="TripleSlice-_LPAR_in-Custom-Slices_RPAR_"></a>
<a id="TripleSlice___triple-_LPAR_in-Custom-Slices_RPAR_"></a>
<a id="TripleSlice___start-_LPAR_in-Custom-Slices_RPAR_"></a>
<a id="TripleSlice___stop-_LPAR_in-Custom-Slices_RPAR_"></a>


```proofscript
structure TripleSlice (α : Type u) where
  triple : Triple α
  start : TriplePos
  stop : TriplePos
deriving Repr
```

Ranges of `TriplePos` can be used to select a slice from a triple by implementing instances of each supported range type's `Sliceable` class. For example, `Std.Rco.Sliceable` allows left-closed, right-open ranges to be used to slice `Triple`s:

```proofscript
instance : Std.Rco.Sliceable (Triple α) TriplePos (TripleSlice α) where
  mkSlice triple range :=
    { triple, start := range.lower, stop := range.upper }
```

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="abc-_LPAR_in-Custom-Slices_RPAR_"></a>


```proofscript
const abc : Triple Char := ⟨'a', 'b', 'c'⟩

open TriplePos in
#eval abc[snd...thd]
```

```lean
{ triple := { fst := 'a', snd := 'b', thd := 'c' }, start := TriplePos.snd, stop := TriplePos.thd }
```

Infinite ranges have only a lower bound:

```proofscript
instance : Std.Rci.Sliceable (Triple α) TriplePos (TripleSlice α) where
  mkSlice triple range :=
    { triple, start := range.lower, stop := .done }

open TriplePos in
#eval abc[snd...*]
```

```lean
{ triple := { fst := 'a', snd := 'b', thd := 'c' }, start := TriplePos.snd, stop := TriplePos.done }
```

<a id="Std___Rco___Sliceable___mk"></a>

**type class**

```text
Std.Rco.Sliceable.{u, v, w} (α : Type u) (β : outParam (Type v))
  (γ : outParam (Type w)) : Type (max (max u v) w)
```

This typeclass indicates how to obtain slices of elements of `α` over ranges in the index type `β`, the ranges being left-closed right-open.

The type of the resulting slices is `γ`.

**Instance Constructor**

```text
Std.Rco.Sliceable.mk.{u, v, w}
```

**Methods**

```text
mkSlice : α → Std.Rco β → γ
```

Slices `carrier` from `range.lower` (inclusive) to `range.upper` (exclusive).

<a id="Std___Rcc___Sliceable___mk"></a>

**type class**

```text
Std.Rcc.Sliceable.{u, v, w} (α : Type u) (β : outParam (Type v))
  (γ : outParam (Type w)) : Type (max (max u v) w)
```

This typeclass indicates how to obtain slices of elements of `α` over ranges in the index type `β`, the ranges being closed.

The type of the resulting slices is `γ`.

**Instance Constructor**

```text
Std.Rcc.Sliceable.mk.{u, v, w}
```

**Methods**

```text
mkSlice : α → Std.Rcc β → γ
```

Slices `carrier` from `range.lower` to `range.upper`, both inclusive.

<a id="Std___Rci___Sliceable___mk"></a>

**type class**

```text
Std.Rci.Sliceable.{u, v, w} (α : Type u) (β : outParam (Type v))
  (γ : outParam (Type w)) : Type (max (max u v) w)
```

This typeclass indicates how to obtain slices of elements of `α` over ranges in the index type `β`, the ranges being left-closed right-unbounded.

The type of the resulting slices is `γ`.

**Instance Constructor**

```text
Std.Rci.Sliceable.mk.{u, v, w}
```

**Methods**

```text
mkSlice : α → Std.Rci β → γ
```

Slices `carrier` from `range.lower` (inclusive).

<a id="Std___Roo___Sliceable___mk"></a>

**type class**

```text
Std.Roo.Sliceable.{u, v, w} (α : Type u) (β : outParam (Type v))
  (γ : outParam (Type w)) : Type (max (max u v) w)
```

This typeclass indicates how to obtain slices of elements of `α` over ranges in the index type `β`, the ranges being open.

The type of the resulting slices is `γ`.

**Instance Constructor**

```text
Std.Roo.Sliceable.mk.{u, v, w}
```

**Methods**

```text
mkSlice : α → Std.Roo β → γ
```

Slices `carrier` from `range.lower` to `range.upper`, both exclusive.

<a id="Std___Roc___Sliceable___mk"></a>

**type class**

```text
Std.Roc.Sliceable.{u, v, w} (α : Type u) (β : outParam (Type v))
  (γ : outParam (Type w)) : Type (max (max u v) w)
```

This typeclass indicates how to obtain slices of elements of `α` over ranges in the index type `β`, the ranges being left-open right-closed.

The type of the resulting slices is `γ`.

**Instance Constructor**

```text
Std.Roc.Sliceable.mk.{u, v, w}
```

**Methods**

```text
mkSlice : α → Std.Roc β → γ
```

Slices `carrier` from `range.lower` (exclusive) to `range.upper` (inclusive).

<a id="Std___Roi___Sliceable___mk"></a>

**type class**

```text
Std.Roi.Sliceable.{u, v, w} (α : Type u) (β : outParam (Type v))
  (γ : outParam (Type w)) : Type (max (max u v) w)
```

This typeclass indicates how to obtain slices of elements of `α` over ranges in the index type `β`, the ranges being left-open right-unbounded.

The type of the resulting slices is `γ`.

**Instance Constructor**

```text
Std.Roi.Sliceable.mk.{u, v, w}
```

**Methods**

```text
mkSlice : α → Std.Roi β → γ
```

Slices `carrier` from `range.lower` (exclusive).

<a id="Std___Rio___Sliceable___mk"></a>

**type class**

```text
Std.Rio.Sliceable.{u, v, w} (α : Type u) (β : outParam (Type v))
  (γ : outParam (Type w)) : Type (max (max u v) w)
```

This typeclass indicates how to obtain slices of elements of `α` over ranges in the index type `β`, the ranges being left-unbounded right-open.

The type of the resulting slices is `γ`.

**Instance Constructor**

```text
Std.Rio.Sliceable.mk.{u, v, w}
```

**Methods**

```text
mkSlice : α → Std.Rio β → γ
```

Slices `carrier` up to `range.upper` (exclusive).

<a id="Std___Ric___Sliceable___mk"></a>

**type class**

```text
Std.Ric.Sliceable.{u, v, w} (α : Type u) (β : outParam (Type v))
  (γ : outParam (Type w)) : Type (max (max u v) w)
```

This typeclass indicates how to obtain slices of elements of `α` over ranges in the index type `β`, the ranges being left-unbounded right-closed.

The type of the resulting slices is `γ`.

**Instance Constructor**

```text
Std.Ric.Sliceable.mk.{u, v, w}
```

**Methods**

```text
mkSlice : α → Std.Ric β → γ
```

Slices `carrier` up to `range.upper` (inclusive).

<a id="Std___Rii___Sliceable___mk"></a>

**type class**

```text
Std.Rii.Sliceable.{u, v, w} (α : Type u) (β : outParam (Type v))
  (γ : outParam (Type w)) : Type (max u w)
```

This typeclass indicates how to obtain slices of elements of `α` over the full range in the index type `β`.

The type of the resulting slices is `γ`.

**Instance Constructor**

```text
Std.Rii.Sliceable.mk.{u, v, w}
```

**Methods**

```text
mkSlice : α → Std.Rii β → γ
```

Slices `carrier` with no bounds.

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`a...b` is the range of elements greater than or equal to `a` and less than `b`.
See also `Std.Rco`.
```


### Display 2


```text
`a...<b` is the range of elements greater than or equal to `a` and less than `b`.
See also `Std.Rco`.
```


### Display 3


```text
`a...=b` is the range of elements greater than or equal to `a` and less than or equal to
`b`. See also `Std.Rcc`.
```


### Display 4


```text
`a...*` is the range of elements greater than or equal to `a`. See also `Std.Rci`.
```


### Display 5


```text
`a<...b` is the range of elements greater than `a` and less than `b`.
See also `Std.Roo`.
```


### Display 6


```text
`a<...<b` is the range of elements greater than `a` and less than `b`.
See also `Std.Roo`.
```


### Display 7


```text
`a<...=b` is the range of elements greater than `a` and less than or equal to `b`.
See also `Std.Roc`.
```


### Display 8


```text
`a<...*` is the range of elements greater than `a`. See also `Std.Roi`.
```


### Display 9


```text
`*...b` is the range of elements less than `b`. See also `Std.Rio`.
```


### Display 10


```text
`*...<b` is the range of elements less than `b`. See also `Std.Rio`.
```


### Display 11


```text
`*...=b` is the range of elements less than or equal to `b`. See also `Std.Ric`.
```


### Display 12


```text
`*...*` is the range that is unbounded in both directions. See also `Std.Rii`.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
[3, 4, 5, 6]
```


### Display 2


```text
failed to synthesize instance of type class
  Std.Rxi.IsAlwaysFinite Nat

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


### Display 3


```text
failed to synthesize instance of type class
  Std.PRange.Least? Int

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


### Display 4


```text
253
```


### Display 5


```text
failed to synthesize instance of type class
  Membership Day (Std.Rcc Day)

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


### Display 6


```text
failed to synthesize instance of type class
  ForIn IO (Std.Rcc Day) ?α

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


### Display 7


```text
failed to synthesize instance of type class
  Std.PRange.UpwardEnumerable Day

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


### Display 8


```text
true
```


### Display 9


```text
false
```


### Display 10


```text
[Day.mo, Day.tu, Day.we, Day.th, Day.fr]
```


### Display 11


```text
[Day.we, Day.th]
```


### Display 12


```text
failed to synthesize instance of type class
  ForIn IO (Std.Iter Day) ?α

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


### Display 13


```text
`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead`if_false_right` has been deprecated: Use `ite_false_right` instead
```


### Display 14


```text
It's Day.mo
It's Day.tu
It's Day.we
```


### Display 15


```text
["bananas", "coffee", "dates"]
```


### Display 16


```text
["bananas", "coffee", "dates", "endive"]
```


### Display 17


```text
["bananas", "coffee", "dates", "endive", "fennel"]
```


### Display 18


```text
["coffee", "dates"]
```


### Display 19


```text
["coffee", "dates", "endive"]
```


### Display 20


```text
["apples", "bananas", "coffee", "dates", "endive"]
```


### Display 21


```text
["apples", "bananas", "coffee", "dates"]
```


### Display 22


```text
["apples", "bananas", "coffee", "dates", "endive", "fennel"]
```


### Display 23


```text
{ triple := { fst := 'a', snd := 'b', thd := 'c' }, start := TriplePos.snd, stop := TriplePos.thd }
```


### Display 24


```text
{ triple := { fst := 'a', snd := 'b', thd := 'c' }, start := TriplePos.snd, stop := TriplePos.done }
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
d:Day⊢ Std.PRange.succMany? 0 d = some d
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
n:Natd:Day⊢ Std.PRange.succMany? (n + 1) d = (Std.PRange.succMany? n d).bind Std.PRange.succ?
```


### Display 4


```text
d:Dayd':Daysteps:Nat⊢ Std.PRange.succMany? steps d = some d' → if d ≤ d' then steps = d'.toNat - d.toNat else False
```


### Display 5


```text
d:Dayd':Daysteps:Nath:Std.PRange.succMany? steps d = some d'⊢ if d ≤ d' then steps = d'.toNat - d.toNat else False
```


### Display 6


```text
d:Dayd':Daysteps:Nath:Std.PRange.succMany? 6 d = some d'⊢ if d ≤ d' then 6 = d'.toNat - d.toNat else Falsed:Dayd':Daysteps:Nath:Std.PRange.succMany? 5 d = some d'⊢ if d ≤ d' then 5 = d'.toNat - d.toNat else Falsed:Dayd':Daysteps:Nath:Std.PRange.succMany? 4 d = some d'⊢ if d ≤ d' then 4 = d'.toNat - d.toNat else Falsed:Dayd':Daysteps:Nath:Std.PRange.succMany? 3 d = some d'⊢ if d ≤ d' then 3 = d'.toNat - d.toNat else Falsed:Dayd':Daysteps:Nath:Std.PRange.succMany? 2 d = some d'⊢ if d ≤ d' then 2 = d'.toNat - d.toNat else Falsed:Dayd':Daysteps:Nath:Std.PRange.succMany? 1 d = some d'⊢ if d ≤ d' then 1 = d'.toNat - d.toNat else Falsed:Dayd':Daysteps:Nath:Std.PRange.succMany? 0 d = some d'⊢ if d ≤ d' then 0 = d'.toNat - d.toNat else False
```


### Display 7


```text
mod':Daysteps:Nath:Std.PRange.succMany? 6 mo = some d'⊢ if mo ≤ d' then 6 = d'.toNat - mo.toNat else Falsetud':Daysteps:Nath:Std.PRange.succMany? 6 tu = some d'⊢ if tu ≤ d' then 6 = d'.toNat - tu.toNat else Falsewed':Daysteps:Nath:Std.PRange.succMany? 6 we = some d'⊢ if we ≤ d' then 6 = d'.toNat - we.toNat else Falsethd':Daysteps:Nath:Std.PRange.succMany? 6 th = some d'⊢ if th ≤ d' then 6 = d'.toNat - th.toNat else Falsefrd':Daysteps:Nath:Std.PRange.succMany? 6 fr = some d'⊢ if fr ≤ d' then 6 = d'.toNat - fr.toNat else Falsesad':Daysteps:Nath:Std.PRange.succMany? 6 sa = some d'⊢ if sa ≤ d' then 6 = d'.toNat - sa.toNat else Falsesud':Daysteps:Nath:Std.PRange.succMany? 6 su = some d'⊢ if su ≤ d' then 6 = d'.toNat - su.toNat else False
```


### Display 8


```text
su.mosteps:Nath:Std.PRange.succMany? 6 su = some mo⊢ if su ≤ mo then 6 = mo.toNat - su.toNat else Falsesu.tusteps:Nath:Std.PRange.succMany? 6 su = some tu⊢ if su ≤ tu then 6 = tu.toNat - su.toNat else Falsesu.westeps:Nath:Std.PRange.succMany? 6 su = some we⊢ if su ≤ we then 6 = we.toNat - su.toNat else Falsesu.thsteps:Nath:Std.PRange.succMany? 6 su = some th⊢ if su ≤ th then 6 = th.toNat - su.toNat else Falsesu.frsteps:Nath:Std.PRange.succMany? 6 su = some fr⊢ if su ≤ fr then 6 = fr.toNat - su.toNat else Falsesu.sasteps:Nath:Std.PRange.succMany? 6 su = some sa⊢ if su ≤ sa then 6 = sa.toNat - su.toNat else Falsesu.susteps:Nath:Std.PRange.succMany? 6 su = some su⊢ if su ≤ su then 6 = su.toNat - su.toNat else False
```


### Display 9


```text
mo.mosteps:Nath:Std.PRange.succMany? 6 mo = some mo⊢ if mo ≤ mo then 6 = mo.toNat - mo.toNat else Falsemo.tusteps:Nath:Std.PRange.succMany? 6 mo = some tu⊢ if mo ≤ tu then 6 = tu.toNat - mo.toNat else Falsemo.westeps:Nath:Std.PRange.succMany? 6 mo = some we⊢ if mo ≤ we then 6 = we.toNat - mo.toNat else Falsemo.thsteps:Nath:Std.PRange.succMany? 6 mo = some th⊢ if mo ≤ th then 6 = th.toNat - mo.toNat else Falsemo.frsteps:Nath:Std.PRange.succMany? 6 mo = some fr⊢ if mo ≤ fr then 6 = fr.toNat - mo.toNat else Falsemo.sasteps:Nath:Std.PRange.succMany? 6 mo = some sa⊢ if mo ≤ sa then 6 = sa.toNat - mo.toNat else Falsemo.susteps:Nath:Std.PRange.succMany? 6 mo = some su⊢ if mo ≤ su then 6 = su.toNat - mo.toNat else Falsetu.mosteps:Nath:Std.PRange.succMany? 6 tu = some mo⊢ if tu ≤ mo then 6 = mo.toNat - tu.toNat else Falsetu.tusteps:Nath:Std.PRange.succMany? 6 tu = some tu⊢ if tu ≤ tu then 6 = tu.toNat - tu.toNat else Falsetu.westeps:Nath:Std.PRange.succMany? 6 tu = some we⊢ if tu ≤ we then 6 = we.toNat - tu.toNat else Falsetu.thsteps:Nath:Std.PRange.succMany? 6 tu = some th⊢ if tu ≤ th then 6 = th.toNat - tu.toNat else Falsetu.frsteps:Nath:Std.PRange.succMany? 6 tu = some fr⊢ if tu ≤ fr then 6 = fr.toNat - tu.toNat else Falsetu.sasteps:Nath:Std.PRange.succMany? 6 tu = some sa⊢ if tu ≤ sa then 6 = sa.toNat - tu.toNat else Falsetu.susteps:Nath:Std.PRange.succMany? 6 tu = some su⊢ if tu ≤ su then 6 = su.toNat - tu.toNat else Falsewe.mosteps:Nath:Std.PRange.succMany? 6 we = some mo⊢ if we ≤ mo then 6 = mo.toNat - we.toNat else Falsewe.tusteps:Nath:Std.PRange.succMany? 6 we = some tu⊢ if we ≤ tu then 6 = tu.toNat - we.toNat else Falsewe.westeps:Nath:Std.PRange.succMany? 6 we = some we⊢ if we ≤ we then 6 = we.toNat - we.toNat else Falsewe.thsteps:Nath:Std.PRange.succMany? 6 we = some th⊢ if we ≤ th then 6 = th.toNat - we.toNat else Falsewe.frsteps:Nath:Std.PRange.succMany? 6 we = some fr⊢ if we ≤ fr then 6 = fr.toNat - we.toNat else Falsewe.sasteps:Nath:Std.PRange.succMany? 6 we = some sa⊢ if we ≤ sa then 6 = sa.toNat - we.toNat else Falsewe.susteps:Nath:Std.PRange.succMany? 6 we = some su⊢ if we ≤ su then 6 = su.toNat - we.toNat else Falseth.mosteps:Nath:Std.PRange.succMany? 6 th = some mo⊢ if th ≤ mo then 6 = mo.toNat - th.toNat else Falseth.tusteps:Nath:Std.PRange.succMany? 6 th = some tu⊢ if th ≤ tu then 6 = tu.toNat - th.toNat else Falseth.westeps:Nath:Std.PRange.succMany? 6 th = some we⊢ if th ≤ we then 6 = we.toNat - th.toNat else Falseth.thsteps:Nath:Std.PRange.succMany? 6 th = some th⊢ if th ≤ th then 6 = th.toNat - th.toNat else Falseth.frsteps:Nath:Std.PRange.succMany? 6 th = some fr⊢ if th ≤ fr then 6 = fr.toNat - th.toNat else Falseth.sasteps:Nath:Std.PRange.succMany? 6 th = some sa⊢ if th ≤ sa then 6 = sa.toNat - th.toNat else Falseth.susteps:Nath:Std.PRange.succMany? 6 th = some su⊢ if th ≤ su then 6 = su.toNat - th.toNat else Falsefr.mosteps:Nath:Std.PRange.succMany? 6 fr = some mo⊢ if fr ≤ mo then 6 = mo.toNat - fr.toNat else Falsefr.tusteps:Nath:Std.PRange.succMany? 6 fr = some tu⊢ if fr ≤ tu then 6 = tu.toNat - fr.toNat else Falsefr.westeps:Nath:Std.PRange.succMany? 6 fr = some we⊢ if fr ≤ we then 6 = we.toNat - fr.toNat else Falsefr.thsteps:Nath:Std.PRange.succMany? 6 fr = some th⊢ if fr ≤ th then 6 = th.toNat - fr.toNat else Falsefr.frsteps:Nath:Std.PRange.succMany? 6 fr = some fr⊢ if fr ≤ fr then 6 = fr.toNat - fr.toNat else Falsefr.sasteps:Nath:Std.PRange.succMany? 6 fr = some sa⊢ if fr ≤ sa then 6 = sa.toNat - fr.toNat else Falsefr.susteps:Nath:Std.PRange.succMany? 6 fr = some su⊢ if fr ≤ su then 6 = su.toNat - fr.toNat else Falsesa.mosteps:Nath:Std.PRange.succMany? 6 sa = some mo⊢ if sa ≤ mo then 6 = mo.toNat - sa.toNat else Falsesa.tusteps:Nath:Std.PRange.succMany? 6 sa = some tu⊢ if sa ≤ tu then 6 = tu.toNat - sa.toNat else Falsesa.westeps:Nath:Std.PRange.succMany? 6 sa = some we⊢ if sa ≤ we then 6 = we.toNat - sa.toNat else Falsesa.thsteps:Nath:Std.PRange.succMany? 6 sa = some th⊢ if sa ≤ th then 6 = th.toNat - sa.toNat else Falsesa.frsteps:Nath:Std.PRange.succMany? 6 sa = some fr⊢ if sa ≤ fr then 6 = fr.toNat - sa.toNat else Falsesa.sasteps:Nath:Std.PRange.succMany? 6 sa = some sa⊢ if sa ≤ sa then 6 = sa.toNat - sa.toNat else Falsesa.susteps:Nath:Std.PRange.succMany? 6 sa = some su⊢ if sa ≤ su then 6 = su.toNat - sa.toNat else Falsesu.mosteps:Nath:Std.PRange.succMany? 6 su = some mo⊢ if su ≤ mo then 6 = mo.toNat - su.toNat else Falsesu.tusteps:Nath:Std.PRange.succMany? 6 su = some tu⊢ if su ≤ tu then 6 = tu.toNat - su.toNat else Falsesu.westeps:Nath:Std.PRange.succMany? 6 su = some we⊢ if su ≤ we then 6 = we.toNat - su.toNat else Falsesu.thsteps:Nath:Std.PRange.succMany? 6 su = some th⊢ if su ≤ th then 6 = th.toNat - su.toNat else Falsesu.frsteps:Nath:Std.PRange.succMany? 6 su = some fr⊢ if su ≤ fr then 6 = fr.toNat - su.toNat else Falsesu.sasteps:Nath:Std.PRange.succMany? 6 su = some sa⊢ if su ≤ sa then 6 = sa.toNat - su.toNat else Falsesu.susteps:Nath:Std.PRange.succMany? 6 su = some su⊢ if su ≤ su then 6 = su.toNat - su.toNat else False
```


### Display 10


```text
d:Dayd':Daysteps:Natn:Nath:Std.PRange.succMany? (n + 7) d = some d'⊢ if d ≤ d' then n + 7 = d'.toNat - d.toNat else False
```


### Display 11


```text
d:Dayd':Daysteps:Natn:Nath:(((((((Std.PRange.succMany? n d).bind Std.PRange.succ?).bind Std.PRange.succ?).bind Std.PRange.succ?).bind
                Std.PRange.succ?).bind
            Std.PRange.succ?).bind
        Std.PRange.succ?).bind
    Std.PRange.succ? =
  some d'⊢ if d ≤ d' then n + 7 = d'.toNat - d.toNat else False
```


### Display 12


```text
noned:Dayd':Daysteps:Natn:Nath:(((((((Std.PRange.succMany? n d).bind Std.PRange.succ?).bind Std.PRange.succ?).bind Std.PRange.succ?).bind
                Std.PRange.succ?).bind
            Std.PRange.succ?).bind
        Std.PRange.succ?).bind
    Std.PRange.succ? =
  some d'h':Std.PRange.succMany? n d = none⊢ if d ≤ d' then n + 7 = d'.toNat - d.toNat else False
```


### Display 13


```text
somed:Dayd':Daysteps:Natn:Nath:(((((((Std.PRange.succMany? n d).bind Std.PRange.succ?).bind Std.PRange.succ?).bind Std.PRange.succ?).bind
                Std.PRange.succ?).bind
            Std.PRange.succ?).bind
        Std.PRange.succ?).bind
    Std.PRange.succ? =
  some d'd'':Dayh':Std.PRange.succMany? n d = some d''⊢ if d ≤ d' then n + 7 = d'.toNat - d.toNat else False
```


### Display 14


```text
somed:Dayd':Daysteps:Natn:Natd'':Dayh:(((((((some d'').bind Std.PRange.succ?).bind Std.PRange.succ?).bind Std.PRange.succ?).bind Std.PRange.succ?).bind
            Std.PRange.succ?).bind
        Std.PRange.succ?).bind
    Std.PRange.succ? =
  some d'h':Std.PRange.succMany? n d = some d''⊢ if d ≤ d' then n + 7 = d'.toNat - d.toNat else False
```


### Display 15


```text
some.mod:Dayd':Daysteps:Natn:Nath:(((((((some mo).bind Std.PRange.succ?).bind Std.PRange.succ?).bind Std.PRange.succ?).bind Std.PRange.succ?).bind
            Std.PRange.succ?).bind
        Std.PRange.succ?).bind
    Std.PRange.succ? =
  some d'h':Std.PRange.succMany? n d = some mo⊢ if d ≤ d' then n + 7 = d'.toNat - d.toNat else Falsesome.tud:Dayd':Daysteps:Natn:Nath:(((((((some tu).bind Std.PRange.succ?).bind Std.PRange.succ?).bind Std.PRange.succ?).bind Std.PRange.succ?).bind
            Std.PRange.succ?).bind
        Std.PRange.succ?).bind
    Std.PRange.succ? =
  some d'h':Std.PRange.succMany? n d = some tu⊢ if d ≤ d' then n + 7 = d'.toNat - d.toNat else Falsesome.wed:Dayd':Daysteps:Natn:Nath:(((((((some we).bind Std.PRange.succ?).bind Std.PRange.succ?).bind Std.PRange.succ?).bind Std.PRange.succ?).bind
            Std.PRange.succ?).bind
        Std.PRange.succ?).bind
    Std.PRange.succ? =
  some d'h':Std.PRange.succMany? n d = some we⊢ if d ≤ d' then n + 7 = d'.toNat - d.toNat else Falsesome.thd:Dayd':Daysteps:Natn:Nath:(((((((some th).bind Std.PRange.succ?).bind Std.PRange.succ?).bind Std.PRange.succ?).bind Std.PRange.succ?).bind
            Std.PRange.succ?).bind
        Std.PRange.succ?).bind
    Std.PRange.succ? =
  some d'h':Std.PRange.succMany? n d = some th⊢ if d ≤ d' then n + 7 = d'.toNat - d.toNat else Falsesome.frd:Dayd':Daysteps:Natn:Nath:(((((((some fr).bind Std.PRange.succ?).bind Std.PRange.succ?).bind Std.PRange.succ?).bind Std.PRange.succ?).bind
            Std.PRange.succ?).bind
        Std.PRange.succ?).bind
    Std.PRange.succ? =
  some d'h':Std.PRange.succMany? n d = some fr⊢ if d ≤ d' then n + 7 = d'.toNat - d.toNat else Falsesome.sad:Dayd':Daysteps:Natn:Nath:(((((((some sa).bind Std.PRange.succ?).bind Std.PRange.succ?).bind Std.PRange.succ?).bind Std.PRange.succ?).bind
            Std.PRange.succ?).bind
        Std.PRange.succ?).bind
    Std.PRange.succ? =
  some d'h':Std.PRange.succMany? n d = some sa⊢ if d ≤ d' then n + 7 = d'.toNat - d.toNat else Falsesome.sud:Dayd':Daysteps:Natn:Nath:(((((((some su).bind Std.PRange.succ?).bind Std.PRange.succ?).bind Std.PRange.succ?).bind Std.PRange.succ?).bind
            Std.PRange.succ?).bind
        Std.PRange.succ?).bind
    Std.PRange.succ? =
  some d'h':Std.PRange.succMany? n d = some su⊢ if d ≤ d' then n + 7 = d'.toNat - d.toNat else False
```


### Display 16


```text
d1:Dayd2:Dayh:Std.PRange.UpwardEnumerable.LT d1 d2⊢ d1 ≠ d2
```


### Display 17


```text
init:Dayhi:Day⊢ (Std.PRange.succMany? 7 init).elim True fun x => ¬x < hi
```


### Display 18


```text
mohi:Day⊢ (Std.PRange.succMany? 7 Day.mo).elim True fun x => ¬x < hituhi:Day⊢ (Std.PRange.succMany? 7 Day.tu).elim True fun x => ¬x < hiwehi:Day⊢ (Std.PRange.succMany? 7 Day.we).elim True fun x => ¬x < hithhi:Day⊢ (Std.PRange.succMany? 7 Day.th).elim True fun x => ¬x < hifrhi:Day⊢ (Std.PRange.succMany? 7 Day.fr).elim True fun x => ¬x < hisahi:Day⊢ (Std.PRange.succMany? 7 Day.sa).elim True fun x => ¬x < hisuhi:Day⊢ (Std.PRange.succMany? 7 Day.su).elim True fun x => ¬x < hi
```


### Display 19


```text
init:Dayhi:Day⊢ (Std.PRange.succMany? 7 init).elim True fun x => ¬x ≤ hi
```


### Display 20


```text
mohi:Day⊢ (Std.PRange.succMany? 7 Day.mo).elim True fun x => ¬x ≤ hituhi:Day⊢ (Std.PRange.succMany? 7 Day.tu).elim True fun x => ¬x ≤ hiwehi:Day⊢ (Std.PRange.succMany? 7 Day.we).elim True fun x => ¬x ≤ hithhi:Day⊢ (Std.PRange.succMany? 7 Day.th).elim True fun x => ¬x ≤ hifrhi:Day⊢ (Std.PRange.succMany? 7 Day.fr).elim True fun x => ¬x ≤ hisahi:Day⊢ (Std.PRange.succMany? 7 Day.sa).elim True fun x => ¬x ≤ hisuhi:Day⊢ (Std.PRange.succMany? 7 Day.su).elim True fun x => ¬x ≤ hi
```


### Display 21


```text
init:Day⊢ Std.PRange.succMany? 7 init = none
```


### Display 22


```text
mo⊢ Std.PRange.succMany? 7 Day.mo = nonetu⊢ Std.PRange.succMany? 7 Day.tu = nonewe⊢ Std.PRange.succMany? 7 Day.we = noneth⊢ Std.PRange.succMany? 7 Day.th = nonefr⊢ Std.PRange.succMany? 7 Day.fr = nonesa⊢ Std.PRange.succMany? 7 Day.sa = nonesu⊢ Std.PRange.succMany? 7 Day.su = none
```


### Display 23


```text
d1:Dayd2:Day⊢ d1 < d2 ↔ Std.PRange.UpwardEnumerable.LT d1 d2
```


### Display 24


```text
mpd1:Dayd2:Day⊢ d1 < d2 → Std.PRange.UpwardEnumerable.LT d1 d2mprd1:Dayd2:Day⊢ Std.PRange.UpwardEnumerable.LT d1 d2 → d1 < d2
```


### Display 25


```text
mpd1:Dayd2:Day⊢ d1 < d2 → Std.PRange.UpwardEnumerable.LT d1 d2
```


### Display 26


```text
mpd1:Dayd2:Daylt:d1 < d2⊢ Std.PRange.UpwardEnumerable.LT d1 d2
```


### Display 27


```text
mpd1:Dayd2:Daylt:d1 < d2⊢ ∃ n, (Std.PRange.succMany? n d1).bind Std.PRange.succ? = some d2
```


### Display 28


```text
mpd1:Dayd2:Daylt:d1 < d2⊢ (Std.PRange.succMany? (d2.toNat - d1.toNat.succ) d1).bind Std.PRange.succ? = some d2
```


### Display 29


```text
mp.mod2:Daylt:Day.mo < d2⊢ (Std.PRange.succMany? (d2.toNat - Day.mo.toNat.succ) Day.mo).bind Std.PRange.succ? = some d2mp.tud2:Daylt:Day.tu < d2⊢ (Std.PRange.succMany? (d2.toNat - Day.tu.toNat.succ) Day.tu).bind Std.PRange.succ? = some d2mp.wed2:Daylt:Day.we < d2⊢ (Std.PRange.succMany? (d2.toNat - Day.we.toNat.succ) Day.we).bind Std.PRange.succ? = some d2mp.thd2:Daylt:Day.th < d2⊢ (Std.PRange.succMany? (d2.toNat - Day.th.toNat.succ) Day.th).bind Std.PRange.succ? = some d2mp.frd2:Daylt:Day.fr < d2⊢ (Std.PRange.succMany? (d2.toNat - Day.fr.toNat.succ) Day.fr).bind Std.PRange.succ? = some d2mp.sad2:Daylt:Day.sa < d2⊢ (Std.PRange.succMany? (d2.toNat - Day.sa.toNat.succ) Day.sa).bind Std.PRange.succ? = some d2mp.sud2:Daylt:Day.su < d2⊢ (Std.PRange.succMany? (d2.toNat - Day.su.toNat.succ) Day.su).bind Std.PRange.succ? = some d2
```


### Display 30


```text
mp.su.molt:Day.su < Day.mo⊢ (Std.PRange.succMany? (Day.mo.toNat - Day.su.toNat.succ) Day.su).bind Std.PRange.succ? = some Day.momp.su.tult:Day.su < Day.tu⊢ (Std.PRange.succMany? (Day.tu.toNat - Day.su.toNat.succ) Day.su).bind Std.PRange.succ? = some Day.tump.su.welt:Day.su < Day.we⊢ (Std.PRange.succMany? (Day.we.toNat - Day.su.toNat.succ) Day.su).bind Std.PRange.succ? = some Day.wemp.su.thlt:Day.su < Day.th⊢ (Std.PRange.succMany? (Day.th.toNat - Day.su.toNat.succ) Day.su).bind Std.PRange.succ? = some Day.thmp.su.frlt:Day.su < Day.fr⊢ (Std.PRange.succMany? (Day.fr.toNat - Day.su.toNat.succ) Day.su).bind Std.PRange.succ? = some Day.frmp.su.salt:Day.su < Day.sa⊢ (Std.PRange.succMany? (Day.sa.toNat - Day.su.toNat.succ) Day.su).bind Std.PRange.succ? = some Day.samp.su.sult:Day.su < Day.su⊢ (Std.PRange.succMany? (Day.su.toNat - Day.su.toNat.succ) Day.su).bind Std.PRange.succ? = some Day.su
```


### Display 31


```text
mp.mo.molt:Day.mo < Day.mo⊢ (Std.PRange.succMany? (Day.mo.toNat - Day.mo.toNat.succ) Day.mo).bind Std.PRange.succ? = some Day.momp.mo.tult:Day.mo < Day.tu⊢ (Std.PRange.succMany? (Day.tu.toNat - Day.mo.toNat.succ) Day.mo).bind Std.PRange.succ? = some Day.tump.mo.welt:Day.mo < Day.we⊢ (Std.PRange.succMany? (Day.we.toNat - Day.mo.toNat.succ) Day.mo).bind Std.PRange.succ? = some Day.wemp.mo.thlt:Day.mo < Day.th⊢ (Std.PRange.succMany? (Day.th.toNat - Day.mo.toNat.succ) Day.mo).bind Std.PRange.succ? = some Day.thmp.mo.frlt:Day.mo < Day.fr⊢ (Std.PRange.succMany? (Day.fr.toNat - Day.mo.toNat.succ) Day.mo).bind Std.PRange.succ? = some Day.frmp.mo.salt:Day.mo < Day.sa⊢ (Std.PRange.succMany? (Day.sa.toNat - Day.mo.toNat.succ) Day.mo).bind Std.PRange.succ? = some Day.samp.mo.sult:Day.mo < Day.su⊢ (Std.PRange.succMany? (Day.su.toNat - Day.mo.toNat.succ) Day.mo).bind Std.PRange.succ? = some Day.sump.tu.molt:Day.tu < Day.mo⊢ (Std.PRange.succMany? (Day.mo.toNat - Day.tu.toNat.succ) Day.tu).bind Std.PRange.succ? = some Day.momp.tu.tult:Day.tu < Day.tu⊢ (Std.PRange.succMany? (Day.tu.toNat - Day.tu.toNat.succ) Day.tu).bind Std.PRange.succ? = some Day.tump.tu.welt:Day.tu < Day.we⊢ (Std.PRange.succMany? (Day.we.toNat - Day.tu.toNat.succ) Day.tu).bind Std.PRange.succ? = some Day.wemp.tu.thlt:Day.tu < Day.th⊢ (Std.PRange.succMany? (Day.th.toNat - Day.tu.toNat.succ) Day.tu).bind Std.PRange.succ? = some Day.thmp.tu.frlt:Day.tu < Day.fr⊢ (Std.PRange.succMany? (Day.fr.toNat - Day.tu.toNat.succ) Day.tu).bind Std.PRange.succ? = some Day.frmp.tu.salt:Day.tu < Day.sa⊢ (Std.PRange.succMany? (Day.sa.toNat - Day.tu.toNat.succ) Day.tu).bind Std.PRange.succ? = some Day.samp.tu.sult:Day.tu < Day.su⊢ (Std.PRange.succMany? (Day.su.toNat - Day.tu.toNat.succ) Day.tu).bind Std.PRange.succ? = some Day.sump.we.molt:Day.we < Day.mo⊢ (Std.PRange.succMany? (Day.mo.toNat - Day.we.toNat.succ) Day.we).bind Std.PRange.succ? = some Day.momp.we.tult:Day.we < Day.tu⊢ (Std.PRange.succMany? (Day.tu.toNat - Day.we.toNat.succ) Day.we).bind Std.PRange.succ? = some Day.tump.we.welt:Day.we < Day.we⊢ (Std.PRange.succMany? (Day.we.toNat - Day.we.toNat.succ) Day.we).bind Std.PRange.succ? = some Day.wemp.we.thlt:Day.we < Day.th⊢ (Std.PRange.succMany? (Day.th.toNat - Day.we.toNat.succ) Day.we).bind Std.PRange.succ? = some Day.thmp.we.frlt:Day.we < Day.fr⊢ (Std.PRange.succMany? (Day.fr.toNat - Day.we.toNat.succ) Day.we).bind Std.PRange.succ? = some Day.frmp.we.salt:Day.we < Day.sa⊢ (Std.PRange.succMany? (Day.sa.toNat - Day.we.toNat.succ) Day.we).bind Std.PRange.succ? = some Day.samp.we.sult:Day.we < Day.su⊢ (Std.PRange.succMany? (Day.su.toNat - Day.we.toNat.succ) Day.we).bind Std.PRange.succ? = some Day.sump.th.molt:Day.th < Day.mo⊢ (Std.PRange.succMany? (Day.mo.toNat - Day.th.toNat.succ) Day.th).bind Std.PRange.succ? = some Day.momp.th.tult:Day.th < Day.tu⊢ (Std.PRange.succMany? (Day.tu.toNat - Day.th.toNat.succ) Day.th).bind Std.PRange.succ? = some Day.tump.th.welt:Day.th < Day.we⊢ (Std.PRange.succMany? (Day.we.toNat - Day.th.toNat.succ) Day.th).bind Std.PRange.succ? = some Day.wemp.th.thlt:Day.th < Day.th⊢ (Std.PRange.succMany? (Day.th.toNat - Day.th.toNat.succ) Day.th).bind Std.PRange.succ? = some Day.thmp.th.frlt:Day.th < Day.fr⊢ (Std.PRange.succMany? (Day.fr.toNat - Day.th.toNat.succ) Day.th).bind Std.PRange.succ? = some Day.frmp.th.salt:Day.th < Day.sa⊢ (Std.PRange.succMany? (Day.sa.toNat - Day.th.toNat.succ) Day.th).bind Std.PRange.succ? = some Day.samp.th.sult:Day.th < Day.su⊢ (Std.PRange.succMany? (Day.su.toNat - Day.th.toNat.succ) Day.th).bind Std.PRange.succ? = some Day.sump.fr.molt:Day.fr < Day.mo⊢ (Std.PRange.succMany? (Day.mo.toNat - Day.fr.toNat.succ) Day.fr).bind Std.PRange.succ? = some Day.momp.fr.tult:Day.fr < Day.tu⊢ (Std.PRange.succMany? (Day.tu.toNat - Day.fr.toNat.succ) Day.fr).bind Std.PRange.succ? = some Day.tump.fr.welt:Day.fr < Day.we⊢ (Std.PRange.succMany? (Day.we.toNat - Day.fr.toNat.succ) Day.fr).bind Std.PRange.succ? = some Day.wemp.fr.thlt:Day.fr < Day.th⊢ (Std.PRange.succMany? (Day.th.toNat - Day.fr.toNat.succ) Day.fr).bind Std.PRange.succ? = some Day.thmp.fr.frlt:Day.fr < Day.fr⊢ (Std.PRange.succMany? (Day.fr.toNat - Day.fr.toNat.succ) Day.fr).bind Std.PRange.succ? = some Day.frmp.fr.salt:Day.fr < Day.sa⊢ (Std.PRange.succMany? (Day.sa.toNat - Day.fr.toNat.succ) Day.fr).bind Std.PRange.succ? = some Day.samp.fr.sult:Day.fr < Day.su⊢ (Std.PRange.succMany? (Day.su.toNat - Day.fr.toNat.succ) Day.fr).bind Std.PRange.succ? = some Day.sump.sa.molt:Day.sa < Day.mo⊢ (Std.PRange.succMany? (Day.mo.toNat - Day.sa.toNat.succ) Day.sa).bind Std.PRange.succ? = some Day.momp.sa.tult:Day.sa < Day.tu⊢ (Std.PRange.succMany? (Day.tu.toNat - Day.sa.toNat.succ) Day.sa).bind Std.PRange.succ? = some Day.tump.sa.welt:Day.sa < Day.we⊢ (Std.PRange.succMany? (Day.we.toNat - Day.sa.toNat.succ) Day.sa).bind Std.PRange.succ? = some Day.wemp.sa.thlt:Day.sa < Day.th⊢ (Std.PRange.succMany? (Day.th.toNat - Day.sa.toNat.succ) Day.sa).bind Std.PRange.succ? = some Day.thmp.sa.frlt:Day.sa < Day.fr⊢ (Std.PRange.succMany? (Day.fr.toNat - Day.sa.toNat.succ) Day.sa).bind Std.PRange.succ? = some Day.frmp.sa.salt:Day.sa < Day.sa⊢ (Std.PRange.succMany? (Day.sa.toNat - Day.sa.toNat.succ) Day.sa).bind Std.PRange.succ? = some Day.samp.sa.sult:Day.sa < Day.su⊢ (Std.PRange.succMany? (Day.su.toNat - Day.sa.toNat.succ) Day.sa).bind Std.PRange.succ? = some Day.sump.su.molt:Day.su < Day.mo⊢ (Std.PRange.succMany? (Day.mo.toNat - Day.su.toNat.succ) Day.su).bind Std.PRange.succ? = some Day.momp.su.tult:Day.su < Day.tu⊢ (Std.PRange.succMany? (Day.tu.toNat - Day.su.toNat.succ) Day.su).bind Std.PRange.succ? = some Day.tump.su.welt:Day.su < Day.we⊢ (Std.PRange.succMany? (Day.we.toNat - Day.su.toNat.succ) Day.su).bind Std.PRange.succ? = some Day.wemp.su.thlt:Day.su < Day.th⊢ (Std.PRange.succMany? (Day.th.toNat - Day.su.toNat.succ) Day.su).bind Std.PRange.succ? = some Day.thmp.su.frlt:Day.su < Day.fr⊢ (Std.PRange.succMany? (Day.fr.toNat - Day.su.toNat.succ) Day.su).bind Std.PRange.succ? = some Day.frmp.su.salt:Day.su < Day.sa⊢ (Std.PRange.succMany? (Day.sa.toNat - Day.su.toNat.succ) Day.su).bind Std.PRange.succ? = some Day.samp.su.sult:Day.su < Day.su⊢ (Std.PRange.succMany? (Day.su.toNat - Day.su.toNat.succ) Day.su).bind Std.PRange.succ? = some Day.su
```


### Display 32


```text
mp.su.sult:Day.su < Day.su⊢ False
```


### Display 33


```text
mp.mo.molt:Day.mo < Day.mo⊢ Falsemp.tu.molt:Day.tu < Day.mo⊢ Falsemp.tu.tult:Day.tu < Day.tu⊢ Falsemp.we.molt:Day.we < Day.mo⊢ Falsemp.we.tult:Day.we < Day.tu⊢ Falsemp.we.welt:Day.we < Day.we⊢ Falsemp.th.molt:Day.th < Day.mo⊢ Falsemp.th.tult:Day.th < Day.tu⊢ Falsemp.th.welt:Day.th < Day.we⊢ Falsemp.th.thlt:Day.th < Day.th⊢ Falsemp.fr.molt:Day.fr < Day.mo⊢ Falsemp.fr.tult:Day.fr < Day.tu⊢ Falsemp.fr.welt:Day.fr < Day.we⊢ Falsemp.fr.thlt:Day.fr < Day.th⊢ Falsemp.fr.frlt:Day.fr < Day.fr⊢ Falsemp.sa.molt:Day.sa < Day.mo⊢ Falsemp.sa.tult:Day.sa < Day.tu⊢ Falsemp.sa.welt:Day.sa < Day.we⊢ Falsemp.sa.thlt:Day.sa < Day.th⊢ Falsemp.sa.frlt:Day.sa < Day.fr⊢ Falsemp.sa.salt:Day.sa < Day.sa⊢ Falsemp.su.molt:Day.su < Day.mo⊢ Falsemp.su.tult:Day.su < Day.tu⊢ Falsemp.su.welt:Day.su < Day.we⊢ Falsemp.su.thlt:Day.su < Day.th⊢ Falsemp.su.frlt:Day.su < Day.fr⊢ Falsemp.su.salt:Day.su < Day.sa⊢ Falsemp.su.sult:Day.su < Day.su⊢ False
```


### Display 34


```text
mprd1:Dayd2:Day⊢ Std.PRange.UpwardEnumerable.LT d1 d2 → d1 < d2
```


### Display 35


```text
mprd1:Dayd2:Daysteps:Nateq:Std.PRange.succMany? (steps + 1) d1 = some d2⊢ d1 < d2
```


### Display 36


```text
mprd1:Dayd2:Daysteps:Nateq:Std.PRange.succMany? (steps + 1) d1 = some d2this:if d1 ≤ d2 then steps + 1 = d2.toNat - d1.toNat else False⊢ d1 < d2
```


### Display 37


```text
mpr.mod2:Daysteps:Nateq:Std.PRange.succMany? (steps + 1) Day.mo = some d2this:if Day.mo ≤ d2 then steps + 1 = d2.toNat - Day.mo.toNat else False⊢ Day.mo < d2mpr.tud2:Daysteps:Nateq:Std.PRange.succMany? (steps + 1) Day.tu = some d2this:if Day.tu ≤ d2 then steps + 1 = d2.toNat - Day.tu.toNat else False⊢ Day.tu < d2mpr.wed2:Daysteps:Nateq:Std.PRange.succMany? (steps + 1) Day.we = some d2this:if Day.we ≤ d2 then steps + 1 = d2.toNat - Day.we.toNat else False⊢ Day.we < d2mpr.thd2:Daysteps:Nateq:Std.PRange.succMany? (steps + 1) Day.th = some d2this:if Day.th ≤ d2 then steps + 1 = d2.toNat - Day.th.toNat else False⊢ Day.th < d2mpr.frd2:Daysteps:Nateq:Std.PRange.succMany? (steps + 1) Day.fr = some d2this:if Day.fr ≤ d2 then steps + 1 = d2.toNat - Day.fr.toNat else False⊢ Day.fr < d2mpr.sad2:Daysteps:Nateq:Std.PRange.succMany? (steps + 1) Day.sa = some d2this:if Day.sa ≤ d2 then steps + 1 = d2.toNat - Day.sa.toNat else False⊢ Day.sa < d2mpr.sud2:Daysteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some d2this:if Day.su ≤ d2 then steps + 1 = d2.toNat - Day.su.toNat else False⊢ Day.su < d2
```


### Display 38


```text
mpr.su.mosteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.mothis:if Day.su ≤ Day.mo then steps + 1 = Day.mo.toNat - Day.su.toNat else False⊢ Day.su < Day.mompr.su.tusteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.tuthis:if Day.su ≤ Day.tu then steps + 1 = Day.tu.toNat - Day.su.toNat else False⊢ Day.su < Day.tumpr.su.westeps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.wethis:if Day.su ≤ Day.we then steps + 1 = Day.we.toNat - Day.su.toNat else False⊢ Day.su < Day.wempr.su.thsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.ththis:if Day.su ≤ Day.th then steps + 1 = Day.th.toNat - Day.su.toNat else False⊢ Day.su < Day.thmpr.su.frsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.frthis:if Day.su ≤ Day.fr then steps + 1 = Day.fr.toNat - Day.su.toNat else False⊢ Day.su < Day.frmpr.su.sasteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.sathis:if Day.su ≤ Day.sa then steps + 1 = Day.sa.toNat - Day.su.toNat else False⊢ Day.su < Day.sampr.su.susteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.suthis:if Day.su ≤ Day.su then steps + 1 = Day.su.toNat - Day.su.toNat else False⊢ Day.su < Day.su
```


### Display 39


```text
mpr.mo.mosteps:Nateq:Std.PRange.succMany? (steps + 1) Day.mo = some Day.mothis:if Day.mo ≤ Day.mo then steps + 1 = Day.mo.toNat - Day.mo.toNat else False⊢ Day.mo < Day.mompr.mo.tusteps:Nateq:Std.PRange.succMany? (steps + 1) Day.mo = some Day.tuthis:if Day.mo ≤ Day.tu then steps + 1 = Day.tu.toNat - Day.mo.toNat else False⊢ Day.mo < Day.tumpr.mo.westeps:Nateq:Std.PRange.succMany? (steps + 1) Day.mo = some Day.wethis:if Day.mo ≤ Day.we then steps + 1 = Day.we.toNat - Day.mo.toNat else False⊢ Day.mo < Day.wempr.mo.thsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.mo = some Day.ththis:if Day.mo ≤ Day.th then steps + 1 = Day.th.toNat - Day.mo.toNat else False⊢ Day.mo < Day.thmpr.mo.frsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.mo = some Day.frthis:if Day.mo ≤ Day.fr then steps + 1 = Day.fr.toNat - Day.mo.toNat else False⊢ Day.mo < Day.frmpr.mo.sasteps:Nateq:Std.PRange.succMany? (steps + 1) Day.mo = some Day.sathis:if Day.mo ≤ Day.sa then steps + 1 = Day.sa.toNat - Day.mo.toNat else False⊢ Day.mo < Day.sampr.mo.susteps:Nateq:Std.PRange.succMany? (steps + 1) Day.mo = some Day.suthis:if Day.mo ≤ Day.su then steps + 1 = Day.su.toNat - Day.mo.toNat else False⊢ Day.mo < Day.sumpr.tu.mosteps:Nateq:Std.PRange.succMany? (steps + 1) Day.tu = some Day.mothis:if Day.tu ≤ Day.mo then steps + 1 = Day.mo.toNat - Day.tu.toNat else False⊢ Day.tu < Day.mompr.tu.tusteps:Nateq:Std.PRange.succMany? (steps + 1) Day.tu = some Day.tuthis:if Day.tu ≤ Day.tu then steps + 1 = Day.tu.toNat - Day.tu.toNat else False⊢ Day.tu < Day.tumpr.tu.westeps:Nateq:Std.PRange.succMany? (steps + 1) Day.tu = some Day.wethis:if Day.tu ≤ Day.we then steps + 1 = Day.we.toNat - Day.tu.toNat else False⊢ Day.tu < Day.wempr.tu.thsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.tu = some Day.ththis:if Day.tu ≤ Day.th then steps + 1 = Day.th.toNat - Day.tu.toNat else False⊢ Day.tu < Day.thmpr.tu.frsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.tu = some Day.frthis:if Day.tu ≤ Day.fr then steps + 1 = Day.fr.toNat - Day.tu.toNat else False⊢ Day.tu < Day.frmpr.tu.sasteps:Nateq:Std.PRange.succMany? (steps + 1) Day.tu = some Day.sathis:if Day.tu ≤ Day.sa then steps + 1 = Day.sa.toNat - Day.tu.toNat else False⊢ Day.tu < Day.sampr.tu.susteps:Nateq:Std.PRange.succMany? (steps + 1) Day.tu = some Day.suthis:if Day.tu ≤ Day.su then steps + 1 = Day.su.toNat - Day.tu.toNat else False⊢ Day.tu < Day.sumpr.we.mosteps:Nateq:Std.PRange.succMany? (steps + 1) Day.we = some Day.mothis:if Day.we ≤ Day.mo then steps + 1 = Day.mo.toNat - Day.we.toNat else False⊢ Day.we < Day.mompr.we.tusteps:Nateq:Std.PRange.succMany? (steps + 1) Day.we = some Day.tuthis:if Day.we ≤ Day.tu then steps + 1 = Day.tu.toNat - Day.we.toNat else False⊢ Day.we < Day.tumpr.we.westeps:Nateq:Std.PRange.succMany? (steps + 1) Day.we = some Day.wethis:if Day.we ≤ Day.we then steps + 1 = Day.we.toNat - Day.we.toNat else False⊢ Day.we < Day.wempr.we.thsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.we = some Day.ththis:if Day.we ≤ Day.th then steps + 1 = Day.th.toNat - Day.we.toNat else False⊢ Day.we < Day.thmpr.we.frsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.we = some Day.frthis:if Day.we ≤ Day.fr then steps + 1 = Day.fr.toNat - Day.we.toNat else False⊢ Day.we < Day.frmpr.we.sasteps:Nateq:Std.PRange.succMany? (steps + 1) Day.we = some Day.sathis:if Day.we ≤ Day.sa then steps + 1 = Day.sa.toNat - Day.we.toNat else False⊢ Day.we < Day.sampr.we.susteps:Nateq:Std.PRange.succMany? (steps + 1) Day.we = some Day.suthis:if Day.we ≤ Day.su then steps + 1 = Day.su.toNat - Day.we.toNat else False⊢ Day.we < Day.sumpr.th.mosteps:Nateq:Std.PRange.succMany? (steps + 1) Day.th = some Day.mothis:if Day.th ≤ Day.mo then steps + 1 = Day.mo.toNat - Day.th.toNat else False⊢ Day.th < Day.mompr.th.tusteps:Nateq:Std.PRange.succMany? (steps + 1) Day.th = some Day.tuthis:if Day.th ≤ Day.tu then steps + 1 = Day.tu.toNat - Day.th.toNat else False⊢ Day.th < Day.tumpr.th.westeps:Nateq:Std.PRange.succMany? (steps + 1) Day.th = some Day.wethis:if Day.th ≤ Day.we then steps + 1 = Day.we.toNat - Day.th.toNat else False⊢ Day.th < Day.wempr.th.thsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.th = some Day.ththis:if Day.th ≤ Day.th then steps + 1 = Day.th.toNat - Day.th.toNat else False⊢ Day.th < Day.thmpr.th.frsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.th = some Day.frthis:if Day.th ≤ Day.fr then steps + 1 = Day.fr.toNat - Day.th.toNat else False⊢ Day.th < Day.frmpr.th.sasteps:Nateq:Std.PRange.succMany? (steps + 1) Day.th = some Day.sathis:if Day.th ≤ Day.sa then steps + 1 = Day.sa.toNat - Day.th.toNat else False⊢ Day.th < Day.sampr.th.susteps:Nateq:Std.PRange.succMany? (steps + 1) Day.th = some Day.suthis:if Day.th ≤ Day.su then steps + 1 = Day.su.toNat - Day.th.toNat else False⊢ Day.th < Day.sumpr.fr.mosteps:Nateq:Std.PRange.succMany? (steps + 1) Day.fr = some Day.mothis:if Day.fr ≤ Day.mo then steps + 1 = Day.mo.toNat - Day.fr.toNat else False⊢ Day.fr < Day.mompr.fr.tusteps:Nateq:Std.PRange.succMany? (steps + 1) Day.fr = some Day.tuthis:if Day.fr ≤ Day.tu then steps + 1 = Day.tu.toNat - Day.fr.toNat else False⊢ Day.fr < Day.tumpr.fr.westeps:Nateq:Std.PRange.succMany? (steps + 1) Day.fr = some Day.wethis:if Day.fr ≤ Day.we then steps + 1 = Day.we.toNat - Day.fr.toNat else False⊢ Day.fr < Day.wempr.fr.thsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.fr = some Day.ththis:if Day.fr ≤ Day.th then steps + 1 = Day.th.toNat - Day.fr.toNat else False⊢ Day.fr < Day.thmpr.fr.frsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.fr = some Day.frthis:if Day.fr ≤ Day.fr then steps + 1 = Day.fr.toNat - Day.fr.toNat else False⊢ Day.fr < Day.frmpr.fr.sasteps:Nateq:Std.PRange.succMany? (steps + 1) Day.fr = some Day.sathis:if Day.fr ≤ Day.sa then steps + 1 = Day.sa.toNat - Day.fr.toNat else False⊢ Day.fr < Day.sampr.fr.susteps:Nateq:Std.PRange.succMany? (steps + 1) Day.fr = some Day.suthis:if Day.fr ≤ Day.su then steps + 1 = Day.su.toNat - Day.fr.toNat else False⊢ Day.fr < Day.sumpr.sa.mosteps:Nateq:Std.PRange.succMany? (steps + 1) Day.sa = some Day.mothis:if Day.sa ≤ Day.mo then steps + 1 = Day.mo.toNat - Day.sa.toNat else False⊢ Day.sa < Day.mompr.sa.tusteps:Nateq:Std.PRange.succMany? (steps + 1) Day.sa = some Day.tuthis:if Day.sa ≤ Day.tu then steps + 1 = Day.tu.toNat - Day.sa.toNat else False⊢ Day.sa < Day.tumpr.sa.westeps:Nateq:Std.PRange.succMany? (steps + 1) Day.sa = some Day.wethis:if Day.sa ≤ Day.we then steps + 1 = Day.we.toNat - Day.sa.toNat else False⊢ Day.sa < Day.wempr.sa.thsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.sa = some Day.ththis:if Day.sa ≤ Day.th then steps + 1 = Day.th.toNat - Day.sa.toNat else False⊢ Day.sa < Day.thmpr.sa.frsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.sa = some Day.frthis:if Day.sa ≤ Day.fr then steps + 1 = Day.fr.toNat - Day.sa.toNat else False⊢ Day.sa < Day.frmpr.sa.sasteps:Nateq:Std.PRange.succMany? (steps + 1) Day.sa = some Day.sathis:if Day.sa ≤ Day.sa then steps + 1 = Day.sa.toNat - Day.sa.toNat else False⊢ Day.sa < Day.sampr.sa.susteps:Nateq:Std.PRange.succMany? (steps + 1) Day.sa = some Day.suthis:if Day.sa ≤ Day.su then steps + 1 = Day.su.toNat - Day.sa.toNat else False⊢ Day.sa < Day.sumpr.su.mosteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.mothis:if Day.su ≤ Day.mo then steps + 1 = Day.mo.toNat - Day.su.toNat else False⊢ Day.su < Day.mompr.su.tusteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.tuthis:if Day.su ≤ Day.tu then steps + 1 = Day.tu.toNat - Day.su.toNat else False⊢ Day.su < Day.tumpr.su.westeps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.wethis:if Day.su ≤ Day.we then steps + 1 = Day.we.toNat - Day.su.toNat else False⊢ Day.su < Day.wempr.su.thsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.ththis:if Day.su ≤ Day.th then steps + 1 = Day.th.toNat - Day.su.toNat else False⊢ Day.su < Day.thmpr.su.frsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.frthis:if Day.su ≤ Day.fr then steps + 1 = Day.fr.toNat - Day.su.toNat else False⊢ Day.su < Day.frmpr.su.sasteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.sathis:if Day.su ≤ Day.sa then steps + 1 = Day.sa.toNat - Day.su.toNat else False⊢ Day.su < Day.sampr.su.susteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.suthis:if Day.su ≤ Day.su then steps + 1 = Day.su.toNat - Day.su.toNat else False⊢ Day.su < Day.su
```


### Display 40


```text
mpr.su.susteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.suthis:Day.su ≤ Day.su ∧ steps + 1 = Day.su.toNat - Day.su.toNat⊢ Day.su < Day.su
```


### Display 41


```text
mpr.mo.mosteps:Nateq:Std.PRange.succMany? (steps + 1) Day.mo = some Day.mothis:Day.mo ≤ Day.mo ∧ steps + 1 = Day.mo.toNat - Day.mo.toNat⊢ Day.mo < Day.mompr.mo.tusteps:Nateq:Std.PRange.succMany? (steps + 1) Day.mo = some Day.tuthis:Day.mo ≤ Day.tu ∧ steps + 1 = Day.tu.toNat - Day.mo.toNat⊢ Day.mo < Day.tumpr.mo.westeps:Nateq:Std.PRange.succMany? (steps + 1) Day.mo = some Day.wethis:Day.mo ≤ Day.we ∧ steps + 1 = Day.we.toNat - Day.mo.toNat⊢ Day.mo < Day.wempr.mo.thsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.mo = some Day.ththis:Day.mo ≤ Day.th ∧ steps + 1 = Day.th.toNat - Day.mo.toNat⊢ Day.mo < Day.thmpr.mo.frsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.mo = some Day.frthis:Day.mo ≤ Day.fr ∧ steps + 1 = Day.fr.toNat - Day.mo.toNat⊢ Day.mo < Day.frmpr.mo.sasteps:Nateq:Std.PRange.succMany? (steps + 1) Day.mo = some Day.sathis:Day.mo ≤ Day.sa ∧ steps + 1 = Day.sa.toNat - Day.mo.toNat⊢ Day.mo < Day.sampr.mo.susteps:Nateq:Std.PRange.succMany? (steps + 1) Day.mo = some Day.suthis:Day.mo ≤ Day.su ∧ steps + 1 = Day.su.toNat - Day.mo.toNat⊢ Day.mo < Day.sumpr.tu.mosteps:Nateq:Std.PRange.succMany? (steps + 1) Day.tu = some Day.mothis:Day.tu ≤ Day.mo ∧ steps + 1 = Day.mo.toNat - Day.tu.toNat⊢ Day.tu < Day.mompr.tu.tusteps:Nateq:Std.PRange.succMany? (steps + 1) Day.tu = some Day.tuthis:Day.tu ≤ Day.tu ∧ steps + 1 = Day.tu.toNat - Day.tu.toNat⊢ Day.tu < Day.tumpr.tu.westeps:Nateq:Std.PRange.succMany? (steps + 1) Day.tu = some Day.wethis:Day.tu ≤ Day.we ∧ steps + 1 = Day.we.toNat - Day.tu.toNat⊢ Day.tu < Day.wempr.tu.thsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.tu = some Day.ththis:Day.tu ≤ Day.th ∧ steps + 1 = Day.th.toNat - Day.tu.toNat⊢ Day.tu < Day.thmpr.tu.frsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.tu = some Day.frthis:Day.tu ≤ Day.fr ∧ steps + 1 = Day.fr.toNat - Day.tu.toNat⊢ Day.tu < Day.frmpr.tu.sasteps:Nateq:Std.PRange.succMany? (steps + 1) Day.tu = some Day.sathis:Day.tu ≤ Day.sa ∧ steps + 1 = Day.sa.toNat - Day.tu.toNat⊢ Day.tu < Day.sampr.tu.susteps:Nateq:Std.PRange.succMany? (steps + 1) Day.tu = some Day.suthis:Day.tu ≤ Day.su ∧ steps + 1 = Day.su.toNat - Day.tu.toNat⊢ Day.tu < Day.sumpr.we.mosteps:Nateq:Std.PRange.succMany? (steps + 1) Day.we = some Day.mothis:Day.we ≤ Day.mo ∧ steps + 1 = Day.mo.toNat - Day.we.toNat⊢ Day.we < Day.mompr.we.tusteps:Nateq:Std.PRange.succMany? (steps + 1) Day.we = some Day.tuthis:Day.we ≤ Day.tu ∧ steps + 1 = Day.tu.toNat - Day.we.toNat⊢ Day.we < Day.tumpr.we.westeps:Nateq:Std.PRange.succMany? (steps + 1) Day.we = some Day.wethis:Day.we ≤ Day.we ∧ steps + 1 = Day.we.toNat - Day.we.toNat⊢ Day.we < Day.wempr.we.thsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.we = some Day.ththis:Day.we ≤ Day.th ∧ steps + 1 = Day.th.toNat - Day.we.toNat⊢ Day.we < Day.thmpr.we.frsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.we = some Day.frthis:Day.we ≤ Day.fr ∧ steps + 1 = Day.fr.toNat - Day.we.toNat⊢ Day.we < Day.frmpr.we.sasteps:Nateq:Std.PRange.succMany? (steps + 1) Day.we = some Day.sathis:Day.we ≤ Day.sa ∧ steps + 1 = Day.sa.toNat - Day.we.toNat⊢ Day.we < Day.sampr.we.susteps:Nateq:Std.PRange.succMany? (steps + 1) Day.we = some Day.suthis:Day.we ≤ Day.su ∧ steps + 1 = Day.su.toNat - Day.we.toNat⊢ Day.we < Day.sumpr.th.mosteps:Nateq:Std.PRange.succMany? (steps + 1) Day.th = some Day.mothis:Day.th ≤ Day.mo ∧ steps + 1 = Day.mo.toNat - Day.th.toNat⊢ Day.th < Day.mompr.th.tusteps:Nateq:Std.PRange.succMany? (steps + 1) Day.th = some Day.tuthis:Day.th ≤ Day.tu ∧ steps + 1 = Day.tu.toNat - Day.th.toNat⊢ Day.th < Day.tumpr.th.westeps:Nateq:Std.PRange.succMany? (steps + 1) Day.th = some Day.wethis:Day.th ≤ Day.we ∧ steps + 1 = Day.we.toNat - Day.th.toNat⊢ Day.th < Day.wempr.th.thsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.th = some Day.ththis:Day.th ≤ Day.th ∧ steps + 1 = Day.th.toNat - Day.th.toNat⊢ Day.th < Day.thmpr.th.frsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.th = some Day.frthis:Day.th ≤ Day.fr ∧ steps + 1 = Day.fr.toNat - Day.th.toNat⊢ Day.th < Day.frmpr.th.sasteps:Nateq:Std.PRange.succMany? (steps + 1) Day.th = some Day.sathis:Day.th ≤ Day.sa ∧ steps + 1 = Day.sa.toNat - Day.th.toNat⊢ Day.th < Day.sampr.th.susteps:Nateq:Std.PRange.succMany? (steps + 1) Day.th = some Day.suthis:Day.th ≤ Day.su ∧ steps + 1 = Day.su.toNat - Day.th.toNat⊢ Day.th < Day.sumpr.fr.mosteps:Nateq:Std.PRange.succMany? (steps + 1) Day.fr = some Day.mothis:Day.fr ≤ Day.mo ∧ steps + 1 = Day.mo.toNat - Day.fr.toNat⊢ Day.fr < Day.mompr.fr.tusteps:Nateq:Std.PRange.succMany? (steps + 1) Day.fr = some Day.tuthis:Day.fr ≤ Day.tu ∧ steps + 1 = Day.tu.toNat - Day.fr.toNat⊢ Day.fr < Day.tumpr.fr.westeps:Nateq:Std.PRange.succMany? (steps + 1) Day.fr = some Day.wethis:Day.fr ≤ Day.we ∧ steps + 1 = Day.we.toNat - Day.fr.toNat⊢ Day.fr < Day.wempr.fr.thsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.fr = some Day.ththis:Day.fr ≤ Day.th ∧ steps + 1 = Day.th.toNat - Day.fr.toNat⊢ Day.fr < Day.thmpr.fr.frsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.fr = some Day.frthis:Day.fr ≤ Day.fr ∧ steps + 1 = Day.fr.toNat - Day.fr.toNat⊢ Day.fr < Day.frmpr.fr.sasteps:Nateq:Std.PRange.succMany? (steps + 1) Day.fr = some Day.sathis:Day.fr ≤ Day.sa ∧ steps + 1 = Day.sa.toNat - Day.fr.toNat⊢ Day.fr < Day.sampr.fr.susteps:Nateq:Std.PRange.succMany? (steps + 1) Day.fr = some Day.suthis:Day.fr ≤ Day.su ∧ steps + 1 = Day.su.toNat - Day.fr.toNat⊢ Day.fr < Day.sumpr.sa.mosteps:Nateq:Std.PRange.succMany? (steps + 1) Day.sa = some Day.mothis:Day.sa ≤ Day.mo ∧ steps + 1 = Day.mo.toNat - Day.sa.toNat⊢ Day.sa < Day.mompr.sa.tusteps:Nateq:Std.PRange.succMany? (steps + 1) Day.sa = some Day.tuthis:Day.sa ≤ Day.tu ∧ steps + 1 = Day.tu.toNat - Day.sa.toNat⊢ Day.sa < Day.tumpr.sa.westeps:Nateq:Std.PRange.succMany? (steps + 1) Day.sa = some Day.wethis:Day.sa ≤ Day.we ∧ steps + 1 = Day.we.toNat - Day.sa.toNat⊢ Day.sa < Day.wempr.sa.thsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.sa = some Day.ththis:Day.sa ≤ Day.th ∧ steps + 1 = Day.th.toNat - Day.sa.toNat⊢ Day.sa < Day.thmpr.sa.frsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.sa = some Day.frthis:Day.sa ≤ Day.fr ∧ steps + 1 = Day.fr.toNat - Day.sa.toNat⊢ Day.sa < Day.frmpr.sa.sasteps:Nateq:Std.PRange.succMany? (steps + 1) Day.sa = some Day.sathis:Day.sa ≤ Day.sa ∧ steps + 1 = Day.sa.toNat - Day.sa.toNat⊢ Day.sa < Day.sampr.sa.susteps:Nateq:Std.PRange.succMany? (steps + 1) Day.sa = some Day.suthis:Day.sa ≤ Day.su ∧ steps + 1 = Day.su.toNat - Day.sa.toNat⊢ Day.sa < Day.sumpr.su.mosteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.mothis:Day.su ≤ Day.mo ∧ steps + 1 = Day.mo.toNat - Day.su.toNat⊢ Day.su < Day.mompr.su.tusteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.tuthis:Day.su ≤ Day.tu ∧ steps + 1 = Day.tu.toNat - Day.su.toNat⊢ Day.su < Day.tumpr.su.westeps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.wethis:Day.su ≤ Day.we ∧ steps + 1 = Day.we.toNat - Day.su.toNat⊢ Day.su < Day.wempr.su.thsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.ththis:Day.su ≤ Day.th ∧ steps + 1 = Day.th.toNat - Day.su.toNat⊢ Day.su < Day.thmpr.su.frsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.frthis:Day.su ≤ Day.fr ∧ steps + 1 = Day.fr.toNat - Day.su.toNat⊢ Day.su < Day.frmpr.su.sasteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.sathis:Day.su ≤ Day.sa ∧ steps + 1 = Day.sa.toNat - Day.su.toNat⊢ Day.su < Day.sampr.su.susteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.suthis:Day.su ≤ Day.su ∧ steps + 1 = Day.su.toNat - Day.su.toNat⊢ Day.su < Day.su
```


### Display 42


```text
mpr.su.su.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.suleft✝:Day.su ≤ Day.suright✝:steps + 1 = Day.su.toNat - Day.su.toNat⊢ Day.su < Day.su
```


### Display 43


```text
mpr.mo.mo.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.mo = some Day.moleft✝:Day.mo ≤ Day.moright✝:steps + 1 = Day.mo.toNat - Day.mo.toNat⊢ Day.mo < Day.mompr.mo.tu.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.mo = some Day.tuleft✝:Day.mo ≤ Day.turight✝:steps + 1 = Day.tu.toNat - Day.mo.toNat⊢ Day.mo < Day.tumpr.mo.we.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.mo = some Day.weleft✝:Day.mo ≤ Day.weright✝:steps + 1 = Day.we.toNat - Day.mo.toNat⊢ Day.mo < Day.wempr.mo.th.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.mo = some Day.thleft✝:Day.mo ≤ Day.thright✝:steps + 1 = Day.th.toNat - Day.mo.toNat⊢ Day.mo < Day.thmpr.mo.fr.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.mo = some Day.frleft✝:Day.mo ≤ Day.frright✝:steps + 1 = Day.fr.toNat - Day.mo.toNat⊢ Day.mo < Day.frmpr.mo.sa.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.mo = some Day.saleft✝:Day.mo ≤ Day.saright✝:steps + 1 = Day.sa.toNat - Day.mo.toNat⊢ Day.mo < Day.sampr.mo.su.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.mo = some Day.suleft✝:Day.mo ≤ Day.suright✝:steps + 1 = Day.su.toNat - Day.mo.toNat⊢ Day.mo < Day.sumpr.tu.mo.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.tu = some Day.moleft✝:Day.tu ≤ Day.moright✝:steps + 1 = Day.mo.toNat - Day.tu.toNat⊢ Day.tu < Day.mompr.tu.tu.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.tu = some Day.tuleft✝:Day.tu ≤ Day.turight✝:steps + 1 = Day.tu.toNat - Day.tu.toNat⊢ Day.tu < Day.tumpr.tu.we.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.tu = some Day.weleft✝:Day.tu ≤ Day.weright✝:steps + 1 = Day.we.toNat - Day.tu.toNat⊢ Day.tu < Day.wempr.tu.th.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.tu = some Day.thleft✝:Day.tu ≤ Day.thright✝:steps + 1 = Day.th.toNat - Day.tu.toNat⊢ Day.tu < Day.thmpr.tu.fr.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.tu = some Day.frleft✝:Day.tu ≤ Day.frright✝:steps + 1 = Day.fr.toNat - Day.tu.toNat⊢ Day.tu < Day.frmpr.tu.sa.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.tu = some Day.saleft✝:Day.tu ≤ Day.saright✝:steps + 1 = Day.sa.toNat - Day.tu.toNat⊢ Day.tu < Day.sampr.tu.su.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.tu = some Day.suleft✝:Day.tu ≤ Day.suright✝:steps + 1 = Day.su.toNat - Day.tu.toNat⊢ Day.tu < Day.sumpr.we.mo.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.we = some Day.moleft✝:Day.we ≤ Day.moright✝:steps + 1 = Day.mo.toNat - Day.we.toNat⊢ Day.we < Day.mompr.we.tu.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.we = some Day.tuleft✝:Day.we ≤ Day.turight✝:steps + 1 = Day.tu.toNat - Day.we.toNat⊢ Day.we < Day.tumpr.we.we.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.we = some Day.weleft✝:Day.we ≤ Day.weright✝:steps + 1 = Day.we.toNat - Day.we.toNat⊢ Day.we < Day.wempr.we.th.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.we = some Day.thleft✝:Day.we ≤ Day.thright✝:steps + 1 = Day.th.toNat - Day.we.toNat⊢ Day.we < Day.thmpr.we.fr.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.we = some Day.frleft✝:Day.we ≤ Day.frright✝:steps + 1 = Day.fr.toNat - Day.we.toNat⊢ Day.we < Day.frmpr.we.sa.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.we = some Day.saleft✝:Day.we ≤ Day.saright✝:steps + 1 = Day.sa.toNat - Day.we.toNat⊢ Day.we < Day.sampr.we.su.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.we = some Day.suleft✝:Day.we ≤ Day.suright✝:steps + 1 = Day.su.toNat - Day.we.toNat⊢ Day.we < Day.sumpr.th.mo.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.th = some Day.moleft✝:Day.th ≤ Day.moright✝:steps + 1 = Day.mo.toNat - Day.th.toNat⊢ Day.th < Day.mompr.th.tu.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.th = some Day.tuleft✝:Day.th ≤ Day.turight✝:steps + 1 = Day.tu.toNat - Day.th.toNat⊢ Day.th < Day.tumpr.th.we.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.th = some Day.weleft✝:Day.th ≤ Day.weright✝:steps + 1 = Day.we.toNat - Day.th.toNat⊢ Day.th < Day.wempr.th.th.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.th = some Day.thleft✝:Day.th ≤ Day.thright✝:steps + 1 = Day.th.toNat - Day.th.toNat⊢ Day.th < Day.thmpr.th.fr.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.th = some Day.frleft✝:Day.th ≤ Day.frright✝:steps + 1 = Day.fr.toNat - Day.th.toNat⊢ Day.th < Day.frmpr.th.sa.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.th = some Day.saleft✝:Day.th ≤ Day.saright✝:steps + 1 = Day.sa.toNat - Day.th.toNat⊢ Day.th < Day.sampr.th.su.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.th = some Day.suleft✝:Day.th ≤ Day.suright✝:steps + 1 = Day.su.toNat - Day.th.toNat⊢ Day.th < Day.sumpr.fr.mo.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.fr = some Day.moleft✝:Day.fr ≤ Day.moright✝:steps + 1 = Day.mo.toNat - Day.fr.toNat⊢ Day.fr < Day.mompr.fr.tu.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.fr = some Day.tuleft✝:Day.fr ≤ Day.turight✝:steps + 1 = Day.tu.toNat - Day.fr.toNat⊢ Day.fr < Day.tumpr.fr.we.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.fr = some Day.weleft✝:Day.fr ≤ Day.weright✝:steps + 1 = Day.we.toNat - Day.fr.toNat⊢ Day.fr < Day.wempr.fr.th.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.fr = some Day.thleft✝:Day.fr ≤ Day.thright✝:steps + 1 = Day.th.toNat - Day.fr.toNat⊢ Day.fr < Day.thmpr.fr.fr.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.fr = some Day.frleft✝:Day.fr ≤ Day.frright✝:steps + 1 = Day.fr.toNat - Day.fr.toNat⊢ Day.fr < Day.frmpr.fr.sa.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.fr = some Day.saleft✝:Day.fr ≤ Day.saright✝:steps + 1 = Day.sa.toNat - Day.fr.toNat⊢ Day.fr < Day.sampr.fr.su.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.fr = some Day.suleft✝:Day.fr ≤ Day.suright✝:steps + 1 = Day.su.toNat - Day.fr.toNat⊢ Day.fr < Day.sumpr.sa.mo.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.sa = some Day.moleft✝:Day.sa ≤ Day.moright✝:steps + 1 = Day.mo.toNat - Day.sa.toNat⊢ Day.sa < Day.mompr.sa.tu.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.sa = some Day.tuleft✝:Day.sa ≤ Day.turight✝:steps + 1 = Day.tu.toNat - Day.sa.toNat⊢ Day.sa < Day.tumpr.sa.we.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.sa = some Day.weleft✝:Day.sa ≤ Day.weright✝:steps + 1 = Day.we.toNat - Day.sa.toNat⊢ Day.sa < Day.wempr.sa.th.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.sa = some Day.thleft✝:Day.sa ≤ Day.thright✝:steps + 1 = Day.th.toNat - Day.sa.toNat⊢ Day.sa < Day.thmpr.sa.fr.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.sa = some Day.frleft✝:Day.sa ≤ Day.frright✝:steps + 1 = Day.fr.toNat - Day.sa.toNat⊢ Day.sa < Day.frmpr.sa.sa.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.sa = some Day.saleft✝:Day.sa ≤ Day.saright✝:steps + 1 = Day.sa.toNat - Day.sa.toNat⊢ Day.sa < Day.sampr.sa.su.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.sa = some Day.suleft✝:Day.sa ≤ Day.suright✝:steps + 1 = Day.su.toNat - Day.sa.toNat⊢ Day.sa < Day.sumpr.su.mo.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.moleft✝:Day.su ≤ Day.moright✝:steps + 1 = Day.mo.toNat - Day.su.toNat⊢ Day.su < Day.mompr.su.tu.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.tuleft✝:Day.su ≤ Day.turight✝:steps + 1 = Day.tu.toNat - Day.su.toNat⊢ Day.su < Day.tumpr.su.we.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.weleft✝:Day.su ≤ Day.weright✝:steps + 1 = Day.we.toNat - Day.su.toNat⊢ Day.su < Day.wempr.su.th.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.thleft✝:Day.su ≤ Day.thright✝:steps + 1 = Day.th.toNat - Day.su.toNat⊢ Day.su < Day.thmpr.su.fr.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.frleft✝:Day.su ≤ Day.frright✝:steps + 1 = Day.fr.toNat - Day.su.toNat⊢ Day.su < Day.frmpr.su.sa.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.saleft✝:Day.su ≤ Day.saright✝:steps + 1 = Day.sa.toNat - Day.su.toNat⊢ Day.su < Day.sampr.su.su.introsteps:Nateq:Std.PRange.succMany? (steps + 1) Day.su = some Day.suleft✝:Day.su ≤ Day.suright✝:steps + 1 = Day.su.toNat - Day.su.toNat⊢ Day.su < Day.su
```


### Display 44


```text
d1:Dayd2:Day⊢ d1 ≤ d2 ↔ Std.PRange.UpwardEnumerable.LE d1 d2
```


### Display 45


```text
mpd1:Dayd2:Day⊢ d1 ≤ d2 → Std.PRange.UpwardEnumerable.LE d1 d2mprd1:Dayd2:Day⊢ Std.PRange.UpwardEnumerable.LE d1 d2 → d1 ≤ d2
```


### Display 46


```text
mpd1:Dayd2:Day⊢ d1 ≤ d2 → Std.PRange.UpwardEnumerable.LE d1 d2
```


### Display 47


```text
mpd1:Dayd2:Dayle:d1 ≤ d2⊢ Std.PRange.UpwardEnumerable.LE d1 d2
```


### Display 48


```text
mpd1:Dayd2:Dayle:d1 ≤ d2⊢ ∃ n, Std.PRange.succMany? n d1 = some d2
```


### Display 49


```text
mpd1:Dayd2:Dayle:d1 ≤ d2⊢ Std.PRange.succMany? (d2.toNat - d1.toNat) d1 = some d2
```


### Display 50


```text
mp.mod2:Dayle:Day.mo ≤ d2⊢ Std.PRange.succMany? (d2.toNat - Day.mo.toNat) Day.mo = some d2mp.tud2:Dayle:Day.tu ≤ d2⊢ Std.PRange.succMany? (d2.toNat - Day.tu.toNat) Day.tu = some d2mp.wed2:Dayle:Day.we ≤ d2⊢ Std.PRange.succMany? (d2.toNat - Day.we.toNat) Day.we = some d2mp.thd2:Dayle:Day.th ≤ d2⊢ Std.PRange.succMany? (d2.toNat - Day.th.toNat) Day.th = some d2mp.frd2:Dayle:Day.fr ≤ d2⊢ Std.PRange.succMany? (d2.toNat - Day.fr.toNat) Day.fr = some d2mp.sad2:Dayle:Day.sa ≤ d2⊢ Std.PRange.succMany? (d2.toNat - Day.sa.toNat) Day.sa = some d2mp.sud2:Dayle:Day.su ≤ d2⊢ Std.PRange.succMany? (d2.toNat - Day.su.toNat) Day.su = some d2
```


### Display 51


```text
mp.su.mole:Day.su ≤ Day.mo⊢ Std.PRange.succMany? (Day.mo.toNat - Day.su.toNat) Day.su = some Day.momp.su.tule:Day.su ≤ Day.tu⊢ Std.PRange.succMany? (Day.tu.toNat - Day.su.toNat) Day.su = some Day.tump.su.wele:Day.su ≤ Day.we⊢ Std.PRange.succMany? (Day.we.toNat - Day.su.toNat) Day.su = some Day.wemp.su.thle:Day.su ≤ Day.th⊢ Std.PRange.succMany? (Day.th.toNat - Day.su.toNat) Day.su = some Day.thmp.su.frle:Day.su ≤ Day.fr⊢ Std.PRange.succMany? (Day.fr.toNat - Day.su.toNat) Day.su = some Day.frmp.su.sale:Day.su ≤ Day.sa⊢ Std.PRange.succMany? (Day.sa.toNat - Day.su.toNat) Day.su = some Day.samp.su.sule:Day.su ≤ Day.su⊢ Std.PRange.succMany? (Day.su.toNat - Day.su.toNat) Day.su = some Day.su
```


### Display 52


```text
mp.mo.mole:Day.mo ≤ Day.mo⊢ Std.PRange.succMany? (Day.mo.toNat - Day.mo.toNat) Day.mo = some Day.momp.mo.tule:Day.mo ≤ Day.tu⊢ Std.PRange.succMany? (Day.tu.toNat - Day.mo.toNat) Day.mo = some Day.tump.mo.wele:Day.mo ≤ Day.we⊢ Std.PRange.succMany? (Day.we.toNat - Day.mo.toNat) Day.mo = some Day.wemp.mo.thle:Day.mo ≤ Day.th⊢ Std.PRange.succMany? (Day.th.toNat - Day.mo.toNat) Day.mo = some Day.thmp.mo.frle:Day.mo ≤ Day.fr⊢ Std.PRange.succMany? (Day.fr.toNat - Day.mo.toNat) Day.mo = some Day.frmp.mo.sale:Day.mo ≤ Day.sa⊢ Std.PRange.succMany? (Day.sa.toNat - Day.mo.toNat) Day.mo = some Day.samp.mo.sule:Day.mo ≤ Day.su⊢ Std.PRange.succMany? (Day.su.toNat - Day.mo.toNat) Day.mo = some Day.sump.tu.mole:Day.tu ≤ Day.mo⊢ Std.PRange.succMany? (Day.mo.toNat - Day.tu.toNat) Day.tu = some Day.momp.tu.tule:Day.tu ≤ Day.tu⊢ Std.PRange.succMany? (Day.tu.toNat - Day.tu.toNat) Day.tu = some Day.tump.tu.wele:Day.tu ≤ Day.we⊢ Std.PRange.succMany? (Day.we.toNat - Day.tu.toNat) Day.tu = some Day.wemp.tu.thle:Day.tu ≤ Day.th⊢ Std.PRange.succMany? (Day.th.toNat - Day.tu.toNat) Day.tu = some Day.thmp.tu.frle:Day.tu ≤ Day.fr⊢ Std.PRange.succMany? (Day.fr.toNat - Day.tu.toNat) Day.tu = some Day.frmp.tu.sale:Day.tu ≤ Day.sa⊢ Std.PRange.succMany? (Day.sa.toNat - Day.tu.toNat) Day.tu = some Day.samp.tu.sule:Day.tu ≤ Day.su⊢ Std.PRange.succMany? (Day.su.toNat - Day.tu.toNat) Day.tu = some Day.sump.we.mole:Day.we ≤ Day.mo⊢ Std.PRange.succMany? (Day.mo.toNat - Day.we.toNat) Day.we = some Day.momp.we.tule:Day.we ≤ Day.tu⊢ Std.PRange.succMany? (Day.tu.toNat - Day.we.toNat) Day.we = some Day.tump.we.wele:Day.we ≤ Day.we⊢ Std.PRange.succMany? (Day.we.toNat - Day.we.toNat) Day.we = some Day.wemp.we.thle:Day.we ≤ Day.th⊢ Std.PRange.succMany? (Day.th.toNat - Day.we.toNat) Day.we = some Day.thmp.we.frle:Day.we ≤ Day.fr⊢ Std.PRange.succMany? (Day.fr.toNat - Day.we.toNat) Day.we = some Day.frmp.we.sale:Day.we ≤ Day.sa⊢ Std.PRange.succMany? (Day.sa.toNat - Day.we.toNat) Day.we = some Day.samp.we.sule:Day.we ≤ Day.su⊢ Std.PRange.succMany? (Day.su.toNat - Day.we.toNat) Day.we = some Day.sump.th.mole:Day.th ≤ Day.mo⊢ Std.PRange.succMany? (Day.mo.toNat - Day.th.toNat) Day.th = some Day.momp.th.tule:Day.th ≤ Day.tu⊢ Std.PRange.succMany? (Day.tu.toNat - Day.th.toNat) Day.th = some Day.tump.th.wele:Day.th ≤ Day.we⊢ Std.PRange.succMany? (Day.we.toNat - Day.th.toNat) Day.th = some Day.wemp.th.thle:Day.th ≤ Day.th⊢ Std.PRange.succMany? (Day.th.toNat - Day.th.toNat) Day.th = some Day.thmp.th.frle:Day.th ≤ Day.fr⊢ Std.PRange.succMany? (Day.fr.toNat - Day.th.toNat) Day.th = some Day.frmp.th.sale:Day.th ≤ Day.sa⊢ Std.PRange.succMany? (Day.sa.toNat - Day.th.toNat) Day.th = some Day.samp.th.sule:Day.th ≤ Day.su⊢ Std.PRange.succMany? (Day.su.toNat - Day.th.toNat) Day.th = some Day.sump.fr.mole:Day.fr ≤ Day.mo⊢ Std.PRange.succMany? (Day.mo.toNat - Day.fr.toNat) Day.fr = some Day.momp.fr.tule:Day.fr ≤ Day.tu⊢ Std.PRange.succMany? (Day.tu.toNat - Day.fr.toNat) Day.fr = some Day.tump.fr.wele:Day.fr ≤ Day.we⊢ Std.PRange.succMany? (Day.we.toNat - Day.fr.toNat) Day.fr = some Day.wemp.fr.thle:Day.fr ≤ Day.th⊢ Std.PRange.succMany? (Day.th.toNat - Day.fr.toNat) Day.fr = some Day.thmp.fr.frle:Day.fr ≤ Day.fr⊢ Std.PRange.succMany? (Day.fr.toNat - Day.fr.toNat) Day.fr = some Day.frmp.fr.sale:Day.fr ≤ Day.sa⊢ Std.PRange.succMany? (Day.sa.toNat - Day.fr.toNat) Day.fr = some Day.samp.fr.sule:Day.fr ≤ Day.su⊢ Std.PRange.succMany? (Day.su.toNat - Day.fr.toNat) Day.fr = some Day.sump.sa.mole:Day.sa ≤ Day.mo⊢ Std.PRange.succMany? (Day.mo.toNat - Day.sa.toNat) Day.sa = some Day.momp.sa.tule:Day.sa ≤ Day.tu⊢ Std.PRange.succMany? (Day.tu.toNat - Day.sa.toNat) Day.sa = some Day.tump.sa.wele:Day.sa ≤ Day.we⊢ Std.PRange.succMany? (Day.we.toNat - Day.sa.toNat) Day.sa = some Day.wemp.sa.thle:Day.sa ≤ Day.th⊢ Std.PRange.succMany? (Day.th.toNat - Day.sa.toNat) Day.sa = some Day.thmp.sa.frle:Day.sa ≤ Day.fr⊢ Std.PRange.succMany? (Day.fr.toNat - Day.sa.toNat) Day.sa = some Day.frmp.sa.sale:Day.sa ≤ Day.sa⊢ Std.PRange.succMany? (Day.sa.toNat - Day.sa.toNat) Day.sa = some Day.samp.sa.sule:Day.sa ≤ Day.su⊢ Std.PRange.succMany? (Day.su.toNat - Day.sa.toNat) Day.sa = some Day.sump.su.mole:Day.su ≤ Day.mo⊢ Std.PRange.succMany? (Day.mo.toNat - Day.su.toNat) Day.su = some Day.momp.su.tule:Day.su ≤ Day.tu⊢ Std.PRange.succMany? (Day.tu.toNat - Day.su.toNat) Day.su = some Day.tump.su.wele:Day.su ≤ Day.we⊢ Std.PRange.succMany? (Day.we.toNat - Day.su.toNat) Day.su = some Day.wemp.su.thle:Day.su ≤ Day.th⊢ Std.PRange.succMany? (Day.th.toNat - Day.su.toNat) Day.su = some Day.thmp.su.frle:Day.su ≤ Day.fr⊢ Std.PRange.succMany? (Day.fr.toNat - Day.su.toNat) Day.su = some Day.frmp.su.sale:Day.su ≤ Day.sa⊢ Std.PRange.succMany? (Day.sa.toNat - Day.su.toNat) Day.su = some Day.samp.su.sule:Day.su ≤ Day.su⊢ Std.PRange.succMany? (Day.su.toNat - Day.su.toNat) Day.su = some Day.su
```


### Display 53


```text
mp.tu.mole:Day.tu ≤ Day.mo⊢ Falsemp.we.mole:Day.we ≤ Day.mo⊢ Falsemp.we.tule:Day.we ≤ Day.tu⊢ Falsemp.th.mole:Day.th ≤ Day.mo⊢ Falsemp.th.tule:Day.th ≤ Day.tu⊢ Falsemp.th.wele:Day.th ≤ Day.we⊢ Falsemp.fr.mole:Day.fr ≤ Day.mo⊢ Falsemp.fr.tule:Day.fr ≤ Day.tu⊢ Falsemp.fr.wele:Day.fr ≤ Day.we⊢ Falsemp.fr.thle:Day.fr ≤ Day.th⊢ Falsemp.sa.mole:Day.sa ≤ Day.mo⊢ Falsemp.sa.tule:Day.sa ≤ Day.tu⊢ Falsemp.sa.wele:Day.sa ≤ Day.we⊢ Falsemp.sa.thle:Day.sa ≤ Day.th⊢ Falsemp.sa.frle:Day.sa ≤ Day.fr⊢ Falsemp.su.mole:Day.su ≤ Day.mo⊢ Falsemp.su.tule:Day.su ≤ Day.tu⊢ Falsemp.su.wele:Day.su ≤ Day.we⊢ Falsemp.su.thle:Day.su ≤ Day.th⊢ Falsemp.su.frle:Day.su ≤ Day.fr⊢ Falsemp.su.sale:Day.su ≤ Day.sa⊢ False
```


### Display 54


```text
mprd1:Dayd2:Day⊢ Std.PRange.UpwardEnumerable.LE d1 d2 → d1 ≤ d2
```


### Display 55


```text
mprd1:Dayd2:Daysteps:Nateq:Std.PRange.succMany? steps d1 = some d2⊢ d1 ≤ d2
```


### Display 56


```text
mprd1:Dayd2:Daysteps:Nateq:Std.PRange.succMany? steps d1 = some d2this:if d1 ≤ d2 then steps = d2.toNat - d1.toNat else False⊢ d1 ≤ d2
```


### Display 57


```text
mpr.mod2:Daysteps:Nateq:Std.PRange.succMany? steps Day.mo = some d2this:if Day.mo ≤ d2 then steps = d2.toNat - Day.mo.toNat else False⊢ Day.mo ≤ d2mpr.tud2:Daysteps:Nateq:Std.PRange.succMany? steps Day.tu = some d2this:if Day.tu ≤ d2 then steps = d2.toNat - Day.tu.toNat else False⊢ Day.tu ≤ d2mpr.wed2:Daysteps:Nateq:Std.PRange.succMany? steps Day.we = some d2this:if Day.we ≤ d2 then steps = d2.toNat - Day.we.toNat else False⊢ Day.we ≤ d2mpr.thd2:Daysteps:Nateq:Std.PRange.succMany? steps Day.th = some d2this:if Day.th ≤ d2 then steps = d2.toNat - Day.th.toNat else False⊢ Day.th ≤ d2mpr.frd2:Daysteps:Nateq:Std.PRange.succMany? steps Day.fr = some d2this:if Day.fr ≤ d2 then steps = d2.toNat - Day.fr.toNat else False⊢ Day.fr ≤ d2mpr.sad2:Daysteps:Nateq:Std.PRange.succMany? steps Day.sa = some d2this:if Day.sa ≤ d2 then steps = d2.toNat - Day.sa.toNat else False⊢ Day.sa ≤ d2mpr.sud2:Daysteps:Nateq:Std.PRange.succMany? steps Day.su = some d2this:if Day.su ≤ d2 then steps = d2.toNat - Day.su.toNat else False⊢ Day.su ≤ d2
```


### Display 58


```text
mpr.su.mosteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.mothis:if Day.su ≤ Day.mo then steps = Day.mo.toNat - Day.su.toNat else False⊢ Day.su ≤ Day.mompr.su.tusteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.tuthis:if Day.su ≤ Day.tu then steps = Day.tu.toNat - Day.su.toNat else False⊢ Day.su ≤ Day.tumpr.su.westeps:Nateq:Std.PRange.succMany? steps Day.su = some Day.wethis:if Day.su ≤ Day.we then steps = Day.we.toNat - Day.su.toNat else False⊢ Day.su ≤ Day.wempr.su.thsteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.ththis:if Day.su ≤ Day.th then steps = Day.th.toNat - Day.su.toNat else False⊢ Day.su ≤ Day.thmpr.su.frsteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.frthis:if Day.su ≤ Day.fr then steps = Day.fr.toNat - Day.su.toNat else False⊢ Day.su ≤ Day.frmpr.su.sasteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.sathis:if Day.su ≤ Day.sa then steps = Day.sa.toNat - Day.su.toNat else False⊢ Day.su ≤ Day.sampr.su.susteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.suthis:if Day.su ≤ Day.su then steps = Day.su.toNat - Day.su.toNat else False⊢ Day.su ≤ Day.su
```


### Display 59


```text
mpr.mo.mosteps:Nateq:Std.PRange.succMany? steps Day.mo = some Day.mothis:if Day.mo ≤ Day.mo then steps = Day.mo.toNat - Day.mo.toNat else False⊢ Day.mo ≤ Day.mompr.mo.tusteps:Nateq:Std.PRange.succMany? steps Day.mo = some Day.tuthis:if Day.mo ≤ Day.tu then steps = Day.tu.toNat - Day.mo.toNat else False⊢ Day.mo ≤ Day.tumpr.mo.westeps:Nateq:Std.PRange.succMany? steps Day.mo = some Day.wethis:if Day.mo ≤ Day.we then steps = Day.we.toNat - Day.mo.toNat else False⊢ Day.mo ≤ Day.wempr.mo.thsteps:Nateq:Std.PRange.succMany? steps Day.mo = some Day.ththis:if Day.mo ≤ Day.th then steps = Day.th.toNat - Day.mo.toNat else False⊢ Day.mo ≤ Day.thmpr.mo.frsteps:Nateq:Std.PRange.succMany? steps Day.mo = some Day.frthis:if Day.mo ≤ Day.fr then steps = Day.fr.toNat - Day.mo.toNat else False⊢ Day.mo ≤ Day.frmpr.mo.sasteps:Nateq:Std.PRange.succMany? steps Day.mo = some Day.sathis:if Day.mo ≤ Day.sa then steps = Day.sa.toNat - Day.mo.toNat else False⊢ Day.mo ≤ Day.sampr.mo.susteps:Nateq:Std.PRange.succMany? steps Day.mo = some Day.suthis:if Day.mo ≤ Day.su then steps = Day.su.toNat - Day.mo.toNat else False⊢ Day.mo ≤ Day.sumpr.tu.mosteps:Nateq:Std.PRange.succMany? steps Day.tu = some Day.mothis:if Day.tu ≤ Day.mo then steps = Day.mo.toNat - Day.tu.toNat else False⊢ Day.tu ≤ Day.mompr.tu.tusteps:Nateq:Std.PRange.succMany? steps Day.tu = some Day.tuthis:if Day.tu ≤ Day.tu then steps = Day.tu.toNat - Day.tu.toNat else False⊢ Day.tu ≤ Day.tumpr.tu.westeps:Nateq:Std.PRange.succMany? steps Day.tu = some Day.wethis:if Day.tu ≤ Day.we then steps = Day.we.toNat - Day.tu.toNat else False⊢ Day.tu ≤ Day.wempr.tu.thsteps:Nateq:Std.PRange.succMany? steps Day.tu = some Day.ththis:if Day.tu ≤ Day.th then steps = Day.th.toNat - Day.tu.toNat else False⊢ Day.tu ≤ Day.thmpr.tu.frsteps:Nateq:Std.PRange.succMany? steps Day.tu = some Day.frthis:if Day.tu ≤ Day.fr then steps = Day.fr.toNat - Day.tu.toNat else False⊢ Day.tu ≤ Day.frmpr.tu.sasteps:Nateq:Std.PRange.succMany? steps Day.tu = some Day.sathis:if Day.tu ≤ Day.sa then steps = Day.sa.toNat - Day.tu.toNat else False⊢ Day.tu ≤ Day.sampr.tu.susteps:Nateq:Std.PRange.succMany? steps Day.tu = some Day.suthis:if Day.tu ≤ Day.su then steps = Day.su.toNat - Day.tu.toNat else False⊢ Day.tu ≤ Day.sumpr.we.mosteps:Nateq:Std.PRange.succMany? steps Day.we = some Day.mothis:if Day.we ≤ Day.mo then steps = Day.mo.toNat - Day.we.toNat else False⊢ Day.we ≤ Day.mompr.we.tusteps:Nateq:Std.PRange.succMany? steps Day.we = some Day.tuthis:if Day.we ≤ Day.tu then steps = Day.tu.toNat - Day.we.toNat else False⊢ Day.we ≤ Day.tumpr.we.westeps:Nateq:Std.PRange.succMany? steps Day.we = some Day.wethis:if Day.we ≤ Day.we then steps = Day.we.toNat - Day.we.toNat else False⊢ Day.we ≤ Day.wempr.we.thsteps:Nateq:Std.PRange.succMany? steps Day.we = some Day.ththis:if Day.we ≤ Day.th then steps = Day.th.toNat - Day.we.toNat else False⊢ Day.we ≤ Day.thmpr.we.frsteps:Nateq:Std.PRange.succMany? steps Day.we = some Day.frthis:if Day.we ≤ Day.fr then steps = Day.fr.toNat - Day.we.toNat else False⊢ Day.we ≤ Day.frmpr.we.sasteps:Nateq:Std.PRange.succMany? steps Day.we = some Day.sathis:if Day.we ≤ Day.sa then steps = Day.sa.toNat - Day.we.toNat else False⊢ Day.we ≤ Day.sampr.we.susteps:Nateq:Std.PRange.succMany? steps Day.we = some Day.suthis:if Day.we ≤ Day.su then steps = Day.su.toNat - Day.we.toNat else False⊢ Day.we ≤ Day.sumpr.th.mosteps:Nateq:Std.PRange.succMany? steps Day.th = some Day.mothis:if Day.th ≤ Day.mo then steps = Day.mo.toNat - Day.th.toNat else False⊢ Day.th ≤ Day.mompr.th.tusteps:Nateq:Std.PRange.succMany? steps Day.th = some Day.tuthis:if Day.th ≤ Day.tu then steps = Day.tu.toNat - Day.th.toNat else False⊢ Day.th ≤ Day.tumpr.th.westeps:Nateq:Std.PRange.succMany? steps Day.th = some Day.wethis:if Day.th ≤ Day.we then steps = Day.we.toNat - Day.th.toNat else False⊢ Day.th ≤ Day.wempr.th.thsteps:Nateq:Std.PRange.succMany? steps Day.th = some Day.ththis:if Day.th ≤ Day.th then steps = Day.th.toNat - Day.th.toNat else False⊢ Day.th ≤ Day.thmpr.th.frsteps:Nateq:Std.PRange.succMany? steps Day.th = some Day.frthis:if Day.th ≤ Day.fr then steps = Day.fr.toNat - Day.th.toNat else False⊢ Day.th ≤ Day.frmpr.th.sasteps:Nateq:Std.PRange.succMany? steps Day.th = some Day.sathis:if Day.th ≤ Day.sa then steps = Day.sa.toNat - Day.th.toNat else False⊢ Day.th ≤ Day.sampr.th.susteps:Nateq:Std.PRange.succMany? steps Day.th = some Day.suthis:if Day.th ≤ Day.su then steps = Day.su.toNat - Day.th.toNat else False⊢ Day.th ≤ Day.sumpr.fr.mosteps:Nateq:Std.PRange.succMany? steps Day.fr = some Day.mothis:if Day.fr ≤ Day.mo then steps = Day.mo.toNat - Day.fr.toNat else False⊢ Day.fr ≤ Day.mompr.fr.tusteps:Nateq:Std.PRange.succMany? steps Day.fr = some Day.tuthis:if Day.fr ≤ Day.tu then steps = Day.tu.toNat - Day.fr.toNat else False⊢ Day.fr ≤ Day.tumpr.fr.westeps:Nateq:Std.PRange.succMany? steps Day.fr = some Day.wethis:if Day.fr ≤ Day.we then steps = Day.we.toNat - Day.fr.toNat else False⊢ Day.fr ≤ Day.wempr.fr.thsteps:Nateq:Std.PRange.succMany? steps Day.fr = some Day.ththis:if Day.fr ≤ Day.th then steps = Day.th.toNat - Day.fr.toNat else False⊢ Day.fr ≤ Day.thmpr.fr.frsteps:Nateq:Std.PRange.succMany? steps Day.fr = some Day.frthis:if Day.fr ≤ Day.fr then steps = Day.fr.toNat - Day.fr.toNat else False⊢ Day.fr ≤ Day.frmpr.fr.sasteps:Nateq:Std.PRange.succMany? steps Day.fr = some Day.sathis:if Day.fr ≤ Day.sa then steps = Day.sa.toNat - Day.fr.toNat else False⊢ Day.fr ≤ Day.sampr.fr.susteps:Nateq:Std.PRange.succMany? steps Day.fr = some Day.suthis:if Day.fr ≤ Day.su then steps = Day.su.toNat - Day.fr.toNat else False⊢ Day.fr ≤ Day.sumpr.sa.mosteps:Nateq:Std.PRange.succMany? steps Day.sa = some Day.mothis:if Day.sa ≤ Day.mo then steps = Day.mo.toNat - Day.sa.toNat else False⊢ Day.sa ≤ Day.mompr.sa.tusteps:Nateq:Std.PRange.succMany? steps Day.sa = some Day.tuthis:if Day.sa ≤ Day.tu then steps = Day.tu.toNat - Day.sa.toNat else False⊢ Day.sa ≤ Day.tumpr.sa.westeps:Nateq:Std.PRange.succMany? steps Day.sa = some Day.wethis:if Day.sa ≤ Day.we then steps = Day.we.toNat - Day.sa.toNat else False⊢ Day.sa ≤ Day.wempr.sa.thsteps:Nateq:Std.PRange.succMany? steps Day.sa = some Day.ththis:if Day.sa ≤ Day.th then steps = Day.th.toNat - Day.sa.toNat else False⊢ Day.sa ≤ Day.thmpr.sa.frsteps:Nateq:Std.PRange.succMany? steps Day.sa = some Day.frthis:if Day.sa ≤ Day.fr then steps = Day.fr.toNat - Day.sa.toNat else False⊢ Day.sa ≤ Day.frmpr.sa.sasteps:Nateq:Std.PRange.succMany? steps Day.sa = some Day.sathis:if Day.sa ≤ Day.sa then steps = Day.sa.toNat - Day.sa.toNat else False⊢ Day.sa ≤ Day.sampr.sa.susteps:Nateq:Std.PRange.succMany? steps Day.sa = some Day.suthis:if Day.sa ≤ Day.su then steps = Day.su.toNat - Day.sa.toNat else False⊢ Day.sa ≤ Day.sumpr.su.mosteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.mothis:if Day.su ≤ Day.mo then steps = Day.mo.toNat - Day.su.toNat else False⊢ Day.su ≤ Day.mompr.su.tusteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.tuthis:if Day.su ≤ Day.tu then steps = Day.tu.toNat - Day.su.toNat else False⊢ Day.su ≤ Day.tumpr.su.westeps:Nateq:Std.PRange.succMany? steps Day.su = some Day.wethis:if Day.su ≤ Day.we then steps = Day.we.toNat - Day.su.toNat else False⊢ Day.su ≤ Day.wempr.su.thsteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.ththis:if Day.su ≤ Day.th then steps = Day.th.toNat - Day.su.toNat else False⊢ Day.su ≤ Day.thmpr.su.frsteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.frthis:if Day.su ≤ Day.fr then steps = Day.fr.toNat - Day.su.toNat else False⊢ Day.su ≤ Day.frmpr.su.sasteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.sathis:if Day.su ≤ Day.sa then steps = Day.sa.toNat - Day.su.toNat else False⊢ Day.su ≤ Day.sampr.su.susteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.suthis:if Day.su ≤ Day.su then steps = Day.su.toNat - Day.su.toNat else False⊢ Day.su ≤ Day.su
```


### Display 60


```text
mpr.su.susteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.suthis:Day.su ≤ Day.su ∧ steps = Day.su.toNat - Day.su.toNat⊢ Day.su ≤ Day.su
```


### Display 61


```text
mpr.mo.mosteps:Nateq:Std.PRange.succMany? steps Day.mo = some Day.mothis:Day.mo ≤ Day.mo ∧ steps = Day.mo.toNat - Day.mo.toNat⊢ Day.mo ≤ Day.mompr.mo.tusteps:Nateq:Std.PRange.succMany? steps Day.mo = some Day.tuthis:Day.mo ≤ Day.tu ∧ steps = Day.tu.toNat - Day.mo.toNat⊢ Day.mo ≤ Day.tumpr.mo.westeps:Nateq:Std.PRange.succMany? steps Day.mo = some Day.wethis:Day.mo ≤ Day.we ∧ steps = Day.we.toNat - Day.mo.toNat⊢ Day.mo ≤ Day.wempr.mo.thsteps:Nateq:Std.PRange.succMany? steps Day.mo = some Day.ththis:Day.mo ≤ Day.th ∧ steps = Day.th.toNat - Day.mo.toNat⊢ Day.mo ≤ Day.thmpr.mo.frsteps:Nateq:Std.PRange.succMany? steps Day.mo = some Day.frthis:Day.mo ≤ Day.fr ∧ steps = Day.fr.toNat - Day.mo.toNat⊢ Day.mo ≤ Day.frmpr.mo.sasteps:Nateq:Std.PRange.succMany? steps Day.mo = some Day.sathis:Day.mo ≤ Day.sa ∧ steps = Day.sa.toNat - Day.mo.toNat⊢ Day.mo ≤ Day.sampr.mo.susteps:Nateq:Std.PRange.succMany? steps Day.mo = some Day.suthis:Day.mo ≤ Day.su ∧ steps = Day.su.toNat - Day.mo.toNat⊢ Day.mo ≤ Day.sumpr.tu.mosteps:Nateq:Std.PRange.succMany? steps Day.tu = some Day.mothis:Day.tu ≤ Day.mo ∧ steps = Day.mo.toNat - Day.tu.toNat⊢ Day.tu ≤ Day.mompr.tu.tusteps:Nateq:Std.PRange.succMany? steps Day.tu = some Day.tuthis:Day.tu ≤ Day.tu ∧ steps = Day.tu.toNat - Day.tu.toNat⊢ Day.tu ≤ Day.tumpr.tu.westeps:Nateq:Std.PRange.succMany? steps Day.tu = some Day.wethis:Day.tu ≤ Day.we ∧ steps = Day.we.toNat - Day.tu.toNat⊢ Day.tu ≤ Day.wempr.tu.thsteps:Nateq:Std.PRange.succMany? steps Day.tu = some Day.ththis:Day.tu ≤ Day.th ∧ steps = Day.th.toNat - Day.tu.toNat⊢ Day.tu ≤ Day.thmpr.tu.frsteps:Nateq:Std.PRange.succMany? steps Day.tu = some Day.frthis:Day.tu ≤ Day.fr ∧ steps = Day.fr.toNat - Day.tu.toNat⊢ Day.tu ≤ Day.frmpr.tu.sasteps:Nateq:Std.PRange.succMany? steps Day.tu = some Day.sathis:Day.tu ≤ Day.sa ∧ steps = Day.sa.toNat - Day.tu.toNat⊢ Day.tu ≤ Day.sampr.tu.susteps:Nateq:Std.PRange.succMany? steps Day.tu = some Day.suthis:Day.tu ≤ Day.su ∧ steps = Day.su.toNat - Day.tu.toNat⊢ Day.tu ≤ Day.sumpr.we.mosteps:Nateq:Std.PRange.succMany? steps Day.we = some Day.mothis:Day.we ≤ Day.mo ∧ steps = Day.mo.toNat - Day.we.toNat⊢ Day.we ≤ Day.mompr.we.tusteps:Nateq:Std.PRange.succMany? steps Day.we = some Day.tuthis:Day.we ≤ Day.tu ∧ steps = Day.tu.toNat - Day.we.toNat⊢ Day.we ≤ Day.tumpr.we.westeps:Nateq:Std.PRange.succMany? steps Day.we = some Day.wethis:Day.we ≤ Day.we ∧ steps = Day.we.toNat - Day.we.toNat⊢ Day.we ≤ Day.wempr.we.thsteps:Nateq:Std.PRange.succMany? steps Day.we = some Day.ththis:Day.we ≤ Day.th ∧ steps = Day.th.toNat - Day.we.toNat⊢ Day.we ≤ Day.thmpr.we.frsteps:Nateq:Std.PRange.succMany? steps Day.we = some Day.frthis:Day.we ≤ Day.fr ∧ steps = Day.fr.toNat - Day.we.toNat⊢ Day.we ≤ Day.frmpr.we.sasteps:Nateq:Std.PRange.succMany? steps Day.we = some Day.sathis:Day.we ≤ Day.sa ∧ steps = Day.sa.toNat - Day.we.toNat⊢ Day.we ≤ Day.sampr.we.susteps:Nateq:Std.PRange.succMany? steps Day.we = some Day.suthis:Day.we ≤ Day.su ∧ steps = Day.su.toNat - Day.we.toNat⊢ Day.we ≤ Day.sumpr.th.mosteps:Nateq:Std.PRange.succMany? steps Day.th = some Day.mothis:Day.th ≤ Day.mo ∧ steps = Day.mo.toNat - Day.th.toNat⊢ Day.th ≤ Day.mompr.th.tusteps:Nateq:Std.PRange.succMany? steps Day.th = some Day.tuthis:Day.th ≤ Day.tu ∧ steps = Day.tu.toNat - Day.th.toNat⊢ Day.th ≤ Day.tumpr.th.westeps:Nateq:Std.PRange.succMany? steps Day.th = some Day.wethis:Day.th ≤ Day.we ∧ steps = Day.we.toNat - Day.th.toNat⊢ Day.th ≤ Day.wempr.th.thsteps:Nateq:Std.PRange.succMany? steps Day.th = some Day.ththis:Day.th ≤ Day.th ∧ steps = Day.th.toNat - Day.th.toNat⊢ Day.th ≤ Day.thmpr.th.frsteps:Nateq:Std.PRange.succMany? steps Day.th = some Day.frthis:Day.th ≤ Day.fr ∧ steps = Day.fr.toNat - Day.th.toNat⊢ Day.th ≤ Day.frmpr.th.sasteps:Nateq:Std.PRange.succMany? steps Day.th = some Day.sathis:Day.th ≤ Day.sa ∧ steps = Day.sa.toNat - Day.th.toNat⊢ Day.th ≤ Day.sampr.th.susteps:Nateq:Std.PRange.succMany? steps Day.th = some Day.suthis:Day.th ≤ Day.su ∧ steps = Day.su.toNat - Day.th.toNat⊢ Day.th ≤ Day.sumpr.fr.mosteps:Nateq:Std.PRange.succMany? steps Day.fr = some Day.mothis:Day.fr ≤ Day.mo ∧ steps = Day.mo.toNat - Day.fr.toNat⊢ Day.fr ≤ Day.mompr.fr.tusteps:Nateq:Std.PRange.succMany? steps Day.fr = some Day.tuthis:Day.fr ≤ Day.tu ∧ steps = Day.tu.toNat - Day.fr.toNat⊢ Day.fr ≤ Day.tumpr.fr.westeps:Nateq:Std.PRange.succMany? steps Day.fr = some Day.wethis:Day.fr ≤ Day.we ∧ steps = Day.we.toNat - Day.fr.toNat⊢ Day.fr ≤ Day.wempr.fr.thsteps:Nateq:Std.PRange.succMany? steps Day.fr = some Day.ththis:Day.fr ≤ Day.th ∧ steps = Day.th.toNat - Day.fr.toNat⊢ Day.fr ≤ Day.thmpr.fr.frsteps:Nateq:Std.PRange.succMany? steps Day.fr = some Day.frthis:Day.fr ≤ Day.fr ∧ steps = Day.fr.toNat - Day.fr.toNat⊢ Day.fr ≤ Day.frmpr.fr.sasteps:Nateq:Std.PRange.succMany? steps Day.fr = some Day.sathis:Day.fr ≤ Day.sa ∧ steps = Day.sa.toNat - Day.fr.toNat⊢ Day.fr ≤ Day.sampr.fr.susteps:Nateq:Std.PRange.succMany? steps Day.fr = some Day.suthis:Day.fr ≤ Day.su ∧ steps = Day.su.toNat - Day.fr.toNat⊢ Day.fr ≤ Day.sumpr.sa.mosteps:Nateq:Std.PRange.succMany? steps Day.sa = some Day.mothis:Day.sa ≤ Day.mo ∧ steps = Day.mo.toNat - Day.sa.toNat⊢ Day.sa ≤ Day.mompr.sa.tusteps:Nateq:Std.PRange.succMany? steps Day.sa = some Day.tuthis:Day.sa ≤ Day.tu ∧ steps = Day.tu.toNat - Day.sa.toNat⊢ Day.sa ≤ Day.tumpr.sa.westeps:Nateq:Std.PRange.succMany? steps Day.sa = some Day.wethis:Day.sa ≤ Day.we ∧ steps = Day.we.toNat - Day.sa.toNat⊢ Day.sa ≤ Day.wempr.sa.thsteps:Nateq:Std.PRange.succMany? steps Day.sa = some Day.ththis:Day.sa ≤ Day.th ∧ steps = Day.th.toNat - Day.sa.toNat⊢ Day.sa ≤ Day.thmpr.sa.frsteps:Nateq:Std.PRange.succMany? steps Day.sa = some Day.frthis:Day.sa ≤ Day.fr ∧ steps = Day.fr.toNat - Day.sa.toNat⊢ Day.sa ≤ Day.frmpr.sa.sasteps:Nateq:Std.PRange.succMany? steps Day.sa = some Day.sathis:Day.sa ≤ Day.sa ∧ steps = Day.sa.toNat - Day.sa.toNat⊢ Day.sa ≤ Day.sampr.sa.susteps:Nateq:Std.PRange.succMany? steps Day.sa = some Day.suthis:Day.sa ≤ Day.su ∧ steps = Day.su.toNat - Day.sa.toNat⊢ Day.sa ≤ Day.sumpr.su.mosteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.mothis:Day.su ≤ Day.mo ∧ steps = Day.mo.toNat - Day.su.toNat⊢ Day.su ≤ Day.mompr.su.tusteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.tuthis:Day.su ≤ Day.tu ∧ steps = Day.tu.toNat - Day.su.toNat⊢ Day.su ≤ Day.tumpr.su.westeps:Nateq:Std.PRange.succMany? steps Day.su = some Day.wethis:Day.su ≤ Day.we ∧ steps = Day.we.toNat - Day.su.toNat⊢ Day.su ≤ Day.wempr.su.thsteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.ththis:Day.su ≤ Day.th ∧ steps = Day.th.toNat - Day.su.toNat⊢ Day.su ≤ Day.thmpr.su.frsteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.frthis:Day.su ≤ Day.fr ∧ steps = Day.fr.toNat - Day.su.toNat⊢ Day.su ≤ Day.frmpr.su.sasteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.sathis:Day.su ≤ Day.sa ∧ steps = Day.sa.toNat - Day.su.toNat⊢ Day.su ≤ Day.sampr.su.susteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.suthis:Day.su ≤ Day.su ∧ steps = Day.su.toNat - Day.su.toNat⊢ Day.su ≤ Day.su
```


### Display 62


```text
mpr.su.su.introsteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.suleft✝:Day.su ≤ Day.suright✝:steps = Day.su.toNat - Day.su.toNat⊢ Day.su ≤ Day.su
```


### Display 63


```text
mpr.mo.mo.introsteps:Nateq:Std.PRange.succMany? steps Day.mo = some Day.moleft✝:Day.mo ≤ Day.moright✝:steps = Day.mo.toNat - Day.mo.toNat⊢ Day.mo ≤ Day.mompr.mo.tu.introsteps:Nateq:Std.PRange.succMany? steps Day.mo = some Day.tuleft✝:Day.mo ≤ Day.turight✝:steps = Day.tu.toNat - Day.mo.toNat⊢ Day.mo ≤ Day.tumpr.mo.we.introsteps:Nateq:Std.PRange.succMany? steps Day.mo = some Day.weleft✝:Day.mo ≤ Day.weright✝:steps = Day.we.toNat - Day.mo.toNat⊢ Day.mo ≤ Day.wempr.mo.th.introsteps:Nateq:Std.PRange.succMany? steps Day.mo = some Day.thleft✝:Day.mo ≤ Day.thright✝:steps = Day.th.toNat - Day.mo.toNat⊢ Day.mo ≤ Day.thmpr.mo.fr.introsteps:Nateq:Std.PRange.succMany? steps Day.mo = some Day.frleft✝:Day.mo ≤ Day.frright✝:steps = Day.fr.toNat - Day.mo.toNat⊢ Day.mo ≤ Day.frmpr.mo.sa.introsteps:Nateq:Std.PRange.succMany? steps Day.mo = some Day.saleft✝:Day.mo ≤ Day.saright✝:steps = Day.sa.toNat - Day.mo.toNat⊢ Day.mo ≤ Day.sampr.mo.su.introsteps:Nateq:Std.PRange.succMany? steps Day.mo = some Day.suleft✝:Day.mo ≤ Day.suright✝:steps = Day.su.toNat - Day.mo.toNat⊢ Day.mo ≤ Day.sumpr.tu.mo.introsteps:Nateq:Std.PRange.succMany? steps Day.tu = some Day.moleft✝:Day.tu ≤ Day.moright✝:steps = Day.mo.toNat - Day.tu.toNat⊢ Day.tu ≤ Day.mompr.tu.tu.introsteps:Nateq:Std.PRange.succMany? steps Day.tu = some Day.tuleft✝:Day.tu ≤ Day.turight✝:steps = Day.tu.toNat - Day.tu.toNat⊢ Day.tu ≤ Day.tumpr.tu.we.introsteps:Nateq:Std.PRange.succMany? steps Day.tu = some Day.weleft✝:Day.tu ≤ Day.weright✝:steps = Day.we.toNat - Day.tu.toNat⊢ Day.tu ≤ Day.wempr.tu.th.introsteps:Nateq:Std.PRange.succMany? steps Day.tu = some Day.thleft✝:Day.tu ≤ Day.thright✝:steps = Day.th.toNat - Day.tu.toNat⊢ Day.tu ≤ Day.thmpr.tu.fr.introsteps:Nateq:Std.PRange.succMany? steps Day.tu = some Day.frleft✝:Day.tu ≤ Day.frright✝:steps = Day.fr.toNat - Day.tu.toNat⊢ Day.tu ≤ Day.frmpr.tu.sa.introsteps:Nateq:Std.PRange.succMany? steps Day.tu = some Day.saleft✝:Day.tu ≤ Day.saright✝:steps = Day.sa.toNat - Day.tu.toNat⊢ Day.tu ≤ Day.sampr.tu.su.introsteps:Nateq:Std.PRange.succMany? steps Day.tu = some Day.suleft✝:Day.tu ≤ Day.suright✝:steps = Day.su.toNat - Day.tu.toNat⊢ Day.tu ≤ Day.sumpr.we.mo.introsteps:Nateq:Std.PRange.succMany? steps Day.we = some Day.moleft✝:Day.we ≤ Day.moright✝:steps = Day.mo.toNat - Day.we.toNat⊢ Day.we ≤ Day.mompr.we.tu.introsteps:Nateq:Std.PRange.succMany? steps Day.we = some Day.tuleft✝:Day.we ≤ Day.turight✝:steps = Day.tu.toNat - Day.we.toNat⊢ Day.we ≤ Day.tumpr.we.we.introsteps:Nateq:Std.PRange.succMany? steps Day.we = some Day.weleft✝:Day.we ≤ Day.weright✝:steps = Day.we.toNat - Day.we.toNat⊢ Day.we ≤ Day.wempr.we.th.introsteps:Nateq:Std.PRange.succMany? steps Day.we = some Day.thleft✝:Day.we ≤ Day.thright✝:steps = Day.th.toNat - Day.we.toNat⊢ Day.we ≤ Day.thmpr.we.fr.introsteps:Nateq:Std.PRange.succMany? steps Day.we = some Day.frleft✝:Day.we ≤ Day.frright✝:steps = Day.fr.toNat - Day.we.toNat⊢ Day.we ≤ Day.frmpr.we.sa.introsteps:Nateq:Std.PRange.succMany? steps Day.we = some Day.saleft✝:Day.we ≤ Day.saright✝:steps = Day.sa.toNat - Day.we.toNat⊢ Day.we ≤ Day.sampr.we.su.introsteps:Nateq:Std.PRange.succMany? steps Day.we = some Day.suleft✝:Day.we ≤ Day.suright✝:steps = Day.su.toNat - Day.we.toNat⊢ Day.we ≤ Day.sumpr.th.mo.introsteps:Nateq:Std.PRange.succMany? steps Day.th = some Day.moleft✝:Day.th ≤ Day.moright✝:steps = Day.mo.toNat - Day.th.toNat⊢ Day.th ≤ Day.mompr.th.tu.introsteps:Nateq:Std.PRange.succMany? steps Day.th = some Day.tuleft✝:Day.th ≤ Day.turight✝:steps = Day.tu.toNat - Day.th.toNat⊢ Day.th ≤ Day.tumpr.th.we.introsteps:Nateq:Std.PRange.succMany? steps Day.th = some Day.weleft✝:Day.th ≤ Day.weright✝:steps = Day.we.toNat - Day.th.toNat⊢ Day.th ≤ Day.wempr.th.th.introsteps:Nateq:Std.PRange.succMany? steps Day.th = some Day.thleft✝:Day.th ≤ Day.thright✝:steps = Day.th.toNat - Day.th.toNat⊢ Day.th ≤ Day.thmpr.th.fr.introsteps:Nateq:Std.PRange.succMany? steps Day.th = some Day.frleft✝:Day.th ≤ Day.frright✝:steps = Day.fr.toNat - Day.th.toNat⊢ Day.th ≤ Day.frmpr.th.sa.introsteps:Nateq:Std.PRange.succMany? steps Day.th = some Day.saleft✝:Day.th ≤ Day.saright✝:steps = Day.sa.toNat - Day.th.toNat⊢ Day.th ≤ Day.sampr.th.su.introsteps:Nateq:Std.PRange.succMany? steps Day.th = some Day.suleft✝:Day.th ≤ Day.suright✝:steps = Day.su.toNat - Day.th.toNat⊢ Day.th ≤ Day.sumpr.fr.mo.introsteps:Nateq:Std.PRange.succMany? steps Day.fr = some Day.moleft✝:Day.fr ≤ Day.moright✝:steps = Day.mo.toNat - Day.fr.toNat⊢ Day.fr ≤ Day.mompr.fr.tu.introsteps:Nateq:Std.PRange.succMany? steps Day.fr = some Day.tuleft✝:Day.fr ≤ Day.turight✝:steps = Day.tu.toNat - Day.fr.toNat⊢ Day.fr ≤ Day.tumpr.fr.we.introsteps:Nateq:Std.PRange.succMany? steps Day.fr = some Day.weleft✝:Day.fr ≤ Day.weright✝:steps = Day.we.toNat - Day.fr.toNat⊢ Day.fr ≤ Day.wempr.fr.th.introsteps:Nateq:Std.PRange.succMany? steps Day.fr = some Day.thleft✝:Day.fr ≤ Day.thright✝:steps = Day.th.toNat - Day.fr.toNat⊢ Day.fr ≤ Day.thmpr.fr.fr.introsteps:Nateq:Std.PRange.succMany? steps Day.fr = some Day.frleft✝:Day.fr ≤ Day.frright✝:steps = Day.fr.toNat - Day.fr.toNat⊢ Day.fr ≤ Day.frmpr.fr.sa.introsteps:Nateq:Std.PRange.succMany? steps Day.fr = some Day.saleft✝:Day.fr ≤ Day.saright✝:steps = Day.sa.toNat - Day.fr.toNat⊢ Day.fr ≤ Day.sampr.fr.su.introsteps:Nateq:Std.PRange.succMany? steps Day.fr = some Day.suleft✝:Day.fr ≤ Day.suright✝:steps = Day.su.toNat - Day.fr.toNat⊢ Day.fr ≤ Day.sumpr.sa.mo.introsteps:Nateq:Std.PRange.succMany? steps Day.sa = some Day.moleft✝:Day.sa ≤ Day.moright✝:steps = Day.mo.toNat - Day.sa.toNat⊢ Day.sa ≤ Day.mompr.sa.tu.introsteps:Nateq:Std.PRange.succMany? steps Day.sa = some Day.tuleft✝:Day.sa ≤ Day.turight✝:steps = Day.tu.toNat - Day.sa.toNat⊢ Day.sa ≤ Day.tumpr.sa.we.introsteps:Nateq:Std.PRange.succMany? steps Day.sa = some Day.weleft✝:Day.sa ≤ Day.weright✝:steps = Day.we.toNat - Day.sa.toNat⊢ Day.sa ≤ Day.wempr.sa.th.introsteps:Nateq:Std.PRange.succMany? steps Day.sa = some Day.thleft✝:Day.sa ≤ Day.thright✝:steps = Day.th.toNat - Day.sa.toNat⊢ Day.sa ≤ Day.thmpr.sa.fr.introsteps:Nateq:Std.PRange.succMany? steps Day.sa = some Day.frleft✝:Day.sa ≤ Day.frright✝:steps = Day.fr.toNat - Day.sa.toNat⊢ Day.sa ≤ Day.frmpr.sa.sa.introsteps:Nateq:Std.PRange.succMany? steps Day.sa = some Day.saleft✝:Day.sa ≤ Day.saright✝:steps = Day.sa.toNat - Day.sa.toNat⊢ Day.sa ≤ Day.sampr.sa.su.introsteps:Nateq:Std.PRange.succMany? steps Day.sa = some Day.suleft✝:Day.sa ≤ Day.suright✝:steps = Day.su.toNat - Day.sa.toNat⊢ Day.sa ≤ Day.sumpr.su.mo.introsteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.moleft✝:Day.su ≤ Day.moright✝:steps = Day.mo.toNat - Day.su.toNat⊢ Day.su ≤ Day.mompr.su.tu.introsteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.tuleft✝:Day.su ≤ Day.turight✝:steps = Day.tu.toNat - Day.su.toNat⊢ Day.su ≤ Day.tumpr.su.we.introsteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.weleft✝:Day.su ≤ Day.weright✝:steps = Day.we.toNat - Day.su.toNat⊢ Day.su ≤ Day.wempr.su.th.introsteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.thleft✝:Day.su ≤ Day.thright✝:steps = Day.th.toNat - Day.su.toNat⊢ Day.su ≤ Day.thmpr.su.fr.introsteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.frleft✝:Day.su ≤ Day.frright✝:steps = Day.fr.toNat - Day.su.toNat⊢ Day.su ≤ Day.frmpr.su.sa.introsteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.saleft✝:Day.su ≤ Day.saright✝:steps = Day.sa.toNat - Day.su.toNat⊢ Day.su ≤ Day.sampr.su.su.introsteps:Nateq:Std.PRange.succMany? steps Day.su = some Day.suleft✝:Day.su ≤ Day.suright✝:steps = Day.su.toNat - Day.su.toNat⊢ Day.su ≤ Day.su
```

