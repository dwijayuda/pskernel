<a id="basic-classes"></a>

# ProofScript — 10.5. Basic Classes

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Classes are native type-directed interfaces, not JavaScript classes. Instances provide dictionaries and associated evidence. Inference uses the pinned priority and search behavior, so importing an instance can affect elaboration. Derived instances are generated declarations that must be checked. Boolean equality and hashing require laws when used for logical claims.

**Compiler and coverage boundary.** Braced class fields use native field-declaration layout. Instance initializers use their own native sequence grammar, including semicolons only where that grammar permits them.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Type-Classes/Basic-Classes/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Type-Classes/Basic-Classes/index.html). Source Git blob: `bda55f20ce77656129faf264a50cf5aea8265011`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Extends-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Extends-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Extends-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 10.5. Basic Classes

Many Lean type classes exist in order to allow built-in notations such as addition or array indexing to be overloaded.

<a id="The-Lean-Language-Reference--Type-Classes--Basic-Classes--Boolean-Equality-Tests"></a>
### 10.5.1. Boolean Equality Tests

The Boolean equality operator `==` is overloaded by defining instances of `BEq`. The companion class `Hashable` specifies a hashing procedure for a type. When a type has both `BEq` and `Hashable` instances, then the hashes computed should respect the `BEq` instance: two values equated by `BEq.beq` should always have the same hash.

<a id="BEq___mk"></a>

**type class**

```text
BEq.{u} (α : Type u) : Type u
```

`BEq α` is a typeclass for supplying a boolean-valued equality relation on `α`, notated as `a == b`. Unlike `DecidableEq α` (which uses `a = b`), this is `Bool` valued instead of `Prop` valued, and it also does not have any axioms like being reflexive or agreeing with `=`. It is mainly intended for programming applications. See `LawfulBEq` for a version that requires that `==` and `=` coincide.

Typically we prefer to put the "more variable" term on the left, and the "more constant" term on the right.

**Instance Constructor**

```text
BEq.mk.{u}
```

**Methods**

```text
beq : α → α → Bool
```

Boolean equality, notated as `a == b`.

Conventions for notations in identifiers:

- The recommended spelling of `==` in identifiers is `beq`.

<a id="Hashable___mk"></a>

**type class**

```text
Hashable.{u} (α : Sort u) : Sort (max 1 u)
```

Types that can be hashed into a `UInt64`.

**Instance Constructor**

```text
Hashable.mk.{u}
```

**Methods**

```text
hash : α → UInt64
```

Hashes a value into a `UInt64`.

<a id="mixHash"></a>

**opaque**

```text
mixHash (u₁ u₂ : UInt64) : UInt64
```

An opaque hash mixing operation, used to implement hashing for products.

<a id="LawfulBEq___mk"></a>

**type class**

```text
LawfulBEq.{u} (α : Type u) [BEq α] : Prop
```

A Boolean equality test coincides with propositional equality.

In other words:

- `a == b` implies `a = b`.
- `a == a` is true.

**Instance Constructor**

```text
LawfulBEq.mk.{u}
```

**Extends**

- <a id="0-ReflBEq-LawfulBEq"></a>
  `ReflBEq α`

**Methods**

```text
rfl : ∀ {a : α}, (a == a) = true
```

 Inherited from 

1. `ReflBEq α`

```text
eq_of_beq : ∀ {a b : α}, (a == b) = true → a = b
```

If `a == b` evaluates to `true`, then `a` and `b` are equal in the logic.

<a id="ReflBEq___mk"></a>

**type class**

```text
ReflBEq.{u_1} (α : Type u_1) [BEq α] : Prop
```

`ReflBEq α` says that the `BEq` implementation is reflexive.

**Instance Constructor**

```text
ReflBEq.mk.{u_1}
```

**Methods**

```text
rfl : ∀ {a : α}, (a == a) = true
```

`==` is reflexive, that is, `(a == a) = true`.

<a id="EquivBEq___mk"></a>

**type class**

```text
EquivBEq.{u_1} (α : Type u_1) [BEq α] : Prop
```

`EquivBEq` says that the `BEq` implementation is an equivalence relation.

**Instance Constructor**

```text
EquivBEq.mk.{u_1}
```

**Extends**

- <a id="0-PartialEquivBEq-EquivBEq"></a>
  `PartialEquivBEq α`
- <a id="1-ReflBEq-EquivBEq"></a>
  `ReflBEq α`

**Methods**

```text
symm : ∀ {a b : α}, (a == b) = true → (b == a) = true
```

 Inherited from 

1. `PartialEquivBEq α`
2. `ReflBEq α`

```text
trans : ∀ {a b c : α}, (a == b) = true → (b == c) = true → (a == c) = true
```

 Inherited from 

1. `PartialEquivBEq α`
2. `ReflBEq α`

```text
rfl : ∀ {a : α}, (a == a) = true
```

 Inherited from 

1. `PartialEquivBEq α`
2. `ReflBEq α`

<a id="LawfulHashable___mk"></a>

**type class**

```text
LawfulHashable.{u} (α : Type u) [BEq α] [Hashable α] : Prop
```

The `BEq α` and `Hashable α` instances on `α` are compatible. This means that `a == b` implies `hash a = hash b`.

This is automatic if the `BEq` instance is lawful.

**Instance Constructor**

```text
LawfulHashable.mk.{u}
```

**Methods**

```text
hash_eq : ∀ (a b : α), (a == b) = true → hash a = hash b
```

If `a == b`, then `hash a = hash b`.

<a id="hash_eq"></a>

**theorem**

```text
hash_eq.{u_1} {α : Type u_1} [BEq α] [Hashable α] [LawfulHashable α]
  {a b : α} : (a == b) = true → hash a = hash b
```

A lawful hash function respects its Boolean equality test.

<a id="The-Lean-Language-Reference--Type-Classes--Basic-Classes--Ordering"></a>
### 10.5.2. Ordering

There are two primary ways to order the values of a type:

- The `Ord` type class provides a three-way comparison operator, `compare`, which can indicate that one value is less than, equal to, or greater than another. It returns an `Ordering`.
- The `LT` and `LE` classes provide canonical `Prop`-valued ordering relations for a type that do not need to be decidable. These relations are used to overload the `<` and `≤` operators.

<a id="Ord___mk"></a>

**type class**

```text
Ord.{u} (α : Type u) : Type u
```

`Ord α` provides a computable total order on `α`, in terms of the `compare : α → α → Ordering` function.

Typically instances will be transitive, reflexive, and antisymmetric, but this is not enforced by the typeclass.

There is a derive handler, so appending `deriving Ord` to an inductive type or structure will attempt to create an `Ord` instance.

**Instance Constructor**

```text
Ord.mk.{u}
```

**Methods**

```text
compare : α → α → Ordering
```

Compare two elements in `α` using the comparator contained in an `[Ord α]` instance.

The `compare` method is exported, so no explicit `Ord` namespace is required to use it.

<a id="compareOn"></a>

**def**

```text
compareOn.{u_1, u_2} {β : Type u_1} {α : Sort u_2} [ord : Ord β]
  (f : α → β) (x y : α) : Ordering
```

Compares two values by comparing the results of applying a function.

In particular, `x` is compared to `y` by comparing `f x` and `f y`.

Examples:

- `compareOn (·.length) "apple" "banana" = .lt`
- `compareOn (· % 3) 5 6 = .gt`
- `compareOn (·.foldl max 0) [1, 2, 3] [3, 2, 1] = .eq`

<a id="Ord___opposite"></a>

**def**

```text
Ord.opposite.{u_1} {α : Type u_1} (ord : Ord α) : Ord α
```

Inverts the order of an `Ord` instance.

The result is an `Ord α` instance that returns `Ordering.lt` when `ord` would return `Ordering.gt` and that returns `Ordering.gt` when `ord` would return `Ordering.lt`.

<a id="Ordering___lt"></a>

**inductive type**

```text
Ordering : Type
```

The result of a comparison according to a total order.

The relationship between the compared items may be:

- `Ordering.lt`: less than
- `Ordering.eq`: equal
- `Ordering.gt`: greater than

**Constructors**

```text
Ordering.lt : Ordering
```

Less than.

```text
Ordering.eq : Ordering
```

Equal.

```text
Ordering.gt : Ordering
```

Greater than.

<a id="Ordering___swap"></a>

**def**

```text
Ordering.swap : Ordering → Ordering
```

Swaps less-than and greater-than ordering results.

Examples:

- `Ordering.lt.swap = Ordering.gt`
- `Ordering.eq.swap = Ordering.eq`
- `Ordering.gt.swap = Ordering.lt`

<a id="Ordering___then"></a>

**def**

```text
Ordering.then (a b : Ordering) : Ordering
```

If `a` and `b` are `Ordering`, then `a.then b` returns `a` unless it is `.eq`, in which case it returns `b`. Additionally, it has “short-circuiting” behavior similar to boolean `&&`: if `a` is not `.eq` then the expression for `b` is not evaluated.

This is a useful primitive for constructing lexicographic comparator functions. The `deriving Ord` syntax on a structure uses the `Ord` instance to compare each field in order, combining the results equivalently to `Ordering.then`.

Use `compareLex` to lexicographically combine two comparison functions.

Examples:

```proofscript
structure Person where
  name : String
  age : Nat

-- Sort people first by name (in ascending order), and people with the same name by age (in
-- descending order)
instance : Ord Person where
  compare a b := (compare a.name b.name).then (compare b.age a.age)
```

```text
#eval Ord.compare (⟨"Gert", 33⟩ : Person) ⟨"Dana", 50⟩
```

```proofscript
Ordering.gt
```

```text
#eval Ord.compare (⟨"Gert", 33⟩ : Person) ⟨"Gert", 50⟩
```

```proofscript
Ordering.gt
```

```text
#eval Ord.compare (⟨"Gert", 33⟩ : Person) ⟨"Gert", 20⟩
```

```proofscript
Ordering.lt
```

<a id="Ordering___isLT"></a>

**def**

```text
Ordering.isLT : Ordering → Bool
```

Checks whether the ordering is `lt`.

<a id="Ordering___isLE"></a>

**def**

```text
Ordering.isLE : Ordering → Bool
```

Checks whether the ordering is `lt` or `eq`.

<a id="Ordering___isEq"></a>

**def**

```text
Ordering.isEq : Ordering → Bool
```

Checks whether the ordering is `eq`.

<a id="Ordering___isNe"></a>

**def**

```text
Ordering.isNe : Ordering → Bool
```

Checks whether the ordering is not `eq`.

<a id="Ordering___isGE"></a>

**def**

```text
Ordering.isGE : Ordering → Bool
```

Checks whether the ordering is `gt` or `eq`.

<a id="Ordering___isGT"></a>

**def**

```text
Ordering.isGT : Ordering → Bool
```

Checks whether the ordering is `gt`.

<a id="compareOfLessAndEq"></a>

**def**

```text
compareOfLessAndEq.{u_1} {α : Type u_1} (x y : α) [LT α]
  [Decidable (x < y)] [DecidableEq α] : Ordering
```

Uses decidable less-than and equality relations to find an `Ordering`.

In particular, if `x < y` then the result is `Ordering.lt`. If `x = y` then the result is `Ordering.eq`. Otherwise, it is `Ordering.gt`.

`compareOfLessAndBEq` uses `BEq` instead of `DecidableEq`.

<a id="compareOfLessAndBEq"></a>

**def**

```text
compareOfLessAndBEq.{u_1} {α : Type u_1} (x y : α) [LT α]
  [Decidable (x < y)] [BEq α] : Ordering
```

Uses a decidable less-than relation and Boolean equality to find an `Ordering`.

In particular, if `x < y` then the result is `Ordering.lt`. If `x == y` then the result is `Ordering.eq`. Otherwise, it is `Ordering.gt`.

`compareOfLessAndEq` uses `DecidableEq` instead of `BEq`.

<a id="compareLex"></a>

**def**

```text
compareLex.{u_1, u_2} {α : Sort u_1} {β : Sort u_2}
  (cmp₁ cmp₂ : α → β → Ordering) (a : α) (b : β) : Ordering
```

Compares `a` and `b` lexicographically by `cmp₁` and `cmp₂`.

`a` and `b` are first compared by `cmp₁`. If this returns `Ordering.eq`, `a` and `b` are compared by `cmp₂` to break the tie.

To lexicographically combine two `Ordering`s, use `Ordering.then`.

<a id="term-next-next-next-next"></a>

**syntax**

**Ordering Operators**

The less-than operator is overloaded in the `LT` class:

<a id="_FLQQ_term__LT___FLQQ_"></a>

```ebnf
term ::= ...
    | term < term
```

The less-than-or-equal-to operator is overloaded in the `LE` class:

<a id="_FLQQ_term______FLQQ_-next"></a>

```ebnf
term ::= ...
    | term ≤ term
```

The greater-than and greater-than-or-equal-to operators are the reverse of the less-than and less-than-or-equal-to operators, and cannot be independently overloaded:

<a id="_FLQQ_term__GT___FLQQ_"></a>

```ebnf
term ::= ...
    | term > term
```

<a id="_FLQQ_term______FLQQ_-next-next"></a>

```ebnf
term ::= ...
    | term ≥ term
```

<a id="LT___mk"></a>

**type class**

```text
LT.{u} (α : Type u) : Type u
```

`LT α` is the typeclass which supports the notation `x < y` where `x y : α`.

**Instance Constructor**

```text
LT.mk.{u}
```

**Methods**

```text
lt : α → α → Prop
```

The less-than relation: `x < y`

Conventions for notations in identifiers:

- The recommended spelling of `<` in identifiers is `lt`.

<a id="LE___mk"></a>

**type class**

```text
LE.{u} (α : Type u) : Type u
```

`LE α` is the typeclass which supports the notation `x ≤ y` where `x y : α`.

**Instance Constructor**

```text
LE.mk.{u}
```

**Methods**

```text
le : α → α → Prop
```

The less-equal relation: `x ≤ y`

Conventions for notations in identifiers:

- The recommended spelling of `≤` in identifiers is `le`.

An `Ord` can be used to construct `BEq`, `LT`, and `LE` instances with the following helpers. They are not automatically instances because many types are better served by custom relations.

<a id="ltOfOrd"></a>

**def**

```text
ltOfOrd.{u_1} {α : Type u_1} [Ord α] : LT α
```

Constructs an `LT` instance from an `Ord` instance that asserts that the result of `compare` is `Ordering.lt`.

<a id="leOfOrd"></a>

**def**

```text
leOfOrd.{u_1} {α : Type u_1} [Ord α] : LE α
```

Constructs an `LE` instance from an `Ord` instance that asserts that the result of `compare` satisfies `Ordering.isLE`.

<a id="Ord___toBEq"></a>

**def**

```text
Ord.toBEq.{u_1} {α : Type u_1} (ord : Ord α) : BEq α
```

Constructs a `BEq` instance from an `Ord` instance.

<a id="Ord___toLE"></a>

**def**

```text
Ord.toLE.{u_1} {α : Type u_1} (ord : Ord α) : LE α
```

Constructs an `LE` instance from an `Ord` instance.

<a id="Ord___toLT"></a>

**def**

```text
Ord.toLT.{u_1} {α : Type u_1} (ord : Ord α) : LT α
```

Constructs an `LT` instance from an `Ord` instance.

<a id="Using--Ord--Instances-for--LT--and--LE--Instances"></a>
Using `Ord` Instances for `LT` and `LE` Instances 

Lean can automatically derive an `Ord` instance. In this case, the `Ord Vegetable` instance compares vegetables lexicographically:
<a id="Vegetable-_LPAR_in-Using--Ord--Instances-for--LT--and--LE--Instances_RPAR_"></a>
<a id="Vegetable___color-_LPAR_in-Using--Ord--Instances-for--LT--and--LE--Instances_RPAR_"></a>
<a id="Vegetable___size-_LPAR_in-Using--Ord--Instances-for--LT--and--LE--Instances_RPAR_"></a>


```proofscript
structure Vegetable where
  color : String
  size : Fin 5
deriving Ord
```
<a id="broccoli-_LPAR_in-Using--Ord--Instances-for--LT--and--LE--Instances_RPAR_"></a>
<a id="sweetPotato-_LPAR_in-Using--Ord--Instances-for--LT--and--LE--Instances_RPAR_"></a>


```proofscript
def broccoli : Vegetable where
  color := "green"
  size := 2

def sweetPotato : Vegetable where
  color := "orange"
  size := 3
```

Using the helpers `ltOfOrd` and `leOfOrd`, `LT Vegetable` and `LE Vegetable` instances can be defined. These instances compare the vegetables using `compare` and logically assert that the result is as expected.

```proofscript
instance : LT Vegetable := ltOfOrd
instance : LE Vegetable := leOfOrd
```

The resulting relations are decidable because equality is decidable for `Ordering`:

```proofscript
#eval broccoli < sweetPotato
```

```lean
true
```

```proofscript
#eval broccoli ≤ sweetPotato
```

```lean
true
```

```proofscript
#eval broccoli < broccoli
```

```lean
false
```

```proofscript
#eval broccoli ≤ broccoli
```

```lean
true
```

<a id="The-Lean-Language-Reference--Type-Classes--Basic-Classes--Ordering--Instance-Construction"></a>
#### 10.5.2.1. Instance Construction

<a id="Ord___lex"></a>

**def**

```text
Ord.lex.{u_1, u_2} {α : Type u_1} {β : Type u_2} :
  Ord α → Ord β → Ord (α × β)
```

Constructs the lexicographic order on products `α × β` from orders for `α` and `β`.

<a id="Ord___lex___"></a>

**def**

```text
Ord.lex'.{u_1} {α : Type u_1} (ord₁ ord₂ : Ord α) : Ord α
```

Constructs an `Ord` instance from two existing instances by combining them lexicographically.

The resulting instance compares elements first by `ord₁` and then, if this returns `Ordering.eq`, by `ord₂`.

The function `compareLex` can be used to perform this comparison without constructing an intermediate `Ord` instance. `Ordering.then` can be used to lexicographically combine the results of comparisons.

<a id="Ord___on"></a>

**def**

```text
Ord.on.{u_1, u_2} {β : Type u_1} {α : Type u_2} :
  Ord β → (f : α → β) → Ord α
```

Constructs an `Ord` instance that compares values according to the results of `f`.

In particular, `ord.on f` compares `x` and `y` by comparing `f x` and `f y` according to `ord`.

The function `compareOn` can be used to perform this comparison without constructing an intermediate `Ord` instance.

<a id="The-Lean-Language-Reference--Type-Classes--Basic-Classes--Minimum-and-Maximum-Values"></a>
### 10.5.3. Minimum and Maximum Values

The classes `Max` and `Min` provide overloaded operators for choosing the greater or lesser of two values. These should be in agreement with `Ord`, `LT`, and `LE` instances, if they exist, but there is no mechanism to enforce this.

<a id="Min___mk"></a>

**type class**

```text
Min.{u} (α : Type u) : Type u
```

An overloaded operation to find the lesser of two values of type `α`.

**Instance Constructor**

```text
Min.mk.{u}
```

**Methods**

```text
min : α → α → α
```

Returns the lesser of its two arguments.

<a id="Max___mk"></a>

**type class**

```text
Max.{u} (α : Type u) : Type u
```

An overloaded operation to find the greater of two values of type `α`.

**Instance Constructor**

```text
Max.mk.{u}
```

**Methods**

```text
max : α → α → α
```

Returns the greater of its two arguments.

Given an `LE α` instance for which `LE.le` is decidable, the helpers `minOfLe` and `maxOfLe` can be used to create suitable `Min α` and `Max α` instances. They can be used as the right-hand side of an `instance` declaration.

<a id="minOfLe"></a>

**def**

```text
minOfLe.{u_1} {α : Type u_1} [LE α] [DecidableRel LE.le] : Min α
```

Constructs a `Min` instance from a decidable `≤` operation.

<a id="maxOfLe"></a>

**def**

```text
maxOfLe.{u_1} {α : Type u_1} [LE α] [DecidableRel LE.le] : Max α
```

Constructs a `Max` instance from a decidable `≤` operation.

<a id="decidable-propositions"></a>
### 10.5.4. Decidability

A proposition is 
<a id="--tech-term-decidable"></a>
*decidable* if it can be checked algorithmically.
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
 The Law of the Excluded Middle means that every proposition is true or false, but it provides no way to check which of the two cases holds, which can often be useful. By default, only algorithmic `Decidable` instances for which code can be generated are in scope; opening the `Classical` namespace makes every proposition decidable.

<a id="Decidable___isFalse"></a>

**inductive type**

```text
Decidable (p : Prop) : Type
```

Either a proof that `p` is true or a proof that `p` is false. This is equivalent to a `Bool` paired with a proof that the `Bool` is `true` if and only if `p` is true.

`Decidable` instances are primarily used via `if`-expressions and the tactic `decide`. In conditional expressions, the `Decidable` instance for the proposition is used to select a branch. At run time, this case distinction code is identical to that which would be generated for a `Bool`-based conditional. In proofs, the tactic `decide` synthesizes an instance of `Decidable p`, attempts to reduce it to `isTrue h`, and then succeeds with the proof `h` if it can.

Because `Decidable` carries data, when writing `@[simp]` lemmas which include a `Decidable` instance on the LHS, it is best to use `{_ : Decidable p}` rather than `[Decidable p]` so that non-canonical instances can be found via unification rather than instance synthesis.

**Constructors**

```text
Decidable.isFalse {p : Prop} (h : ¬p) : Decidable p
```

Proves that `p` is decidable by supplying a proof of `¬p`

```text
Decidable.isTrue {p : Prop} (h : p) : Decidable p
```

Proves that `p` is decidable by supplying a proof of `p`

<a id="DecidablePred"></a>

**def**

```text
DecidablePred.{u} {α : Sort u} (r : α → Prop) : Sort (max 1 u)
```

A decidable predicate.

A predicate is decidable if the corresponding proposition is `Decidable` for each possible argument.

<a id="DecidableRel"></a>

**def**

```text
DecidableRel.{u, v} {α : Sort u} {β : Sort v} (r : α → β → Prop) :
  Sort (max (max 1 u) v)
```

A decidable relation.

A relation is decidable if the corresponding proposition is `Decidable` for all possible arguments.

<a id="DecidableEq"></a>

**def**

```text
DecidableEq.{u} (α : Sort u) : Sort (max 1 u)
```

Propositional equality is `Decidable` for all elements of a type.

In other words, an instance of `DecidableEq α` is a means of deciding the proposition `a = b` is for all `a b : α`.

<a id="DecidableLT"></a>

**def**

```text
DecidableLT.{u} (α : Type u) [LT α] : Type u
```

Abbreviation for `DecidableRel (· < · : α → α → Prop)`.

<a id="DecidableLE"></a>

**def**

```text
DecidableLE.{u} (α : Type u) [LE α] : Type u
```

Abbreviation for `DecidableRel (· ≤ · : α → α → Prop)`.

<a id="Decidable___decide"></a>

**def**

```text
Decidable.decide (p : Prop) [h : Decidable p] : Bool
```

Converts a decidable proposition into a `Bool`.

If `p : Prop` is decidable, then `decide p : Bool` is the Boolean value that is `true` if `p` is true and `false` if `p` is false.

<a id="Decidable___byCases"></a>

**def**

```text
Decidable.byCases.{u} {p : Prop} {q : Sort u} [dec : Decidable p]
  (h1 : p → q) (h2 : ¬p → q) : q
```

Construct a `q` if some proposition `p` is decidable, and both the truth and falsity of `p` are sufficient to construct a `q`.

This is a synonym for `dite`, the dependent if-then-else operator.

<a id="Excluded-Middle-and--Decidable"></a>
Excluded Middle and `Decidable` 

The equality of functions from `Nat` to `Nat` is not decidable:

```proofscript
example (f g : Nat → Nat) : Decidable (f = g) := inferInstance
```

```lean
failed to synthesize instance of type class
  Decidable (f = g)

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

Opening `Classical` makes every proposition decidable; however, declarations and examples that use this fact must be marked `noncomputable` to indicate that code should not be generated for them.

```proofscript
open Classical
noncomputable example (f g : Nat → Nat) : Decidable (f = g) :=
  inferInstance
```

<a id="The-Lean-Language-Reference--Type-Classes--Basic-Classes--Inhabited-Types"></a>
### 10.5.5. Inhabited Types

<a id="Inhabited___mk"></a>

**type class**

```text
Inhabited.{u} (α : Sort u) : Sort (max 1 u)
```

`Inhabited α` is a typeclass that says that `α` has a designated element, called `(default : α)`. This is sometimes referred to as a "pointed type".

This class is used by functions that need to return a value of the type when called "out of domain". For example, `Array.get! arr i : α` returns a value of type `α` when `arr : Array α`, but if `i` is not in range of the array, it reports a panic message, but this does not halt the program, so it must still return a value of type `α` (and in fact this is required for logical consistency), so in this case it returns `default`.

**Instance Constructor**

```text
Inhabited.mk.{u}
```

**Methods**

```text
default : α
```

`default` is a function that produces a "default" element of any `Inhabited` type. This element does not have any particular specified properties, but it is often an all-zeroes value.

<a id="Nonempty___intro"></a>

**inductive predicate**

```text
Nonempty.{u} (α : Sort u) : Prop
```

`Nonempty α` is a typeclass that says that `α` is not an empty type, that is, there exists an element in the type. It differs from `Inhabited α` in that `Nonempty α` is a `Prop`, which means that it does not actually carry an element of `α`, only a proof that *there exists* such an element. Given `Nonempty α`, you can construct an element of `α` *nonconstructively* using `Classical.choice`.

**Constructors**

```text
Nonempty.intro.{u} {α : Sort u} (val : α) : Nonempty α
```

If `val : α`, then `α` is nonempty.

<a id="The-Lean-Language-Reference--Type-Classes--Basic-Classes--Subsingleton-Types"></a>
### 10.5.6. Subsingleton Types

<a id="Subsingleton___intro"></a>

**type class**

```text
Subsingleton.{u} (α : Sort u) : Prop
```

A *subsingleton* is a type with at most one element. It is either empty or has a unique element.

All propositions are subsingletons because of proof irrelevance: false propositions are empty, and all proofs of a true proposition are equal to one another. Some non-propositional types are also subsingletons.

**Instance Constructor**

```text
Subsingleton.intro.{u}
```

Prove that `α` is a subsingleton by showing that any two elements are equal.

**Methods**

```text
allEq : ∀ (a b : α), a = b
```

Any two elements of a subsingleton are equal.

<a id="Subsingleton___elim"></a>

**theorem**

```text
Subsingleton.elim.{u} {α : Sort u} [h : Subsingleton α] (a b : α) :
  a = b
```

If a type is a subsingleton, then all of its elements are equal.

<a id="Subsingleton___helim"></a>

**theorem**

```text
Subsingleton.helim.{u} {α β : Sort u} [h₁ : Subsingleton α] (h₂ : α = β)
  (a : α) (b : β) : a ≍ b
```

If two types are equal and one of them is a subsingleton, then all of their elements are [heterogeneously equal](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=HEq).

<a id="The-Lean-Language-Reference--Type-Classes--Basic-Classes--Arithmetic-and-Bitwise-Operators"></a>
### 10.5.7. Arithmetic and Bitwise Operators

<a id="Zero___mk"></a>

**type class**

```text
Zero.{u} (α : Type u) : Type u
```

A type with a zero element.

**Instance Constructor**

```text
Zero.mk.{u}
```

**Methods**

```text
zero : α
```

The zero element of the type.

<a id="NeZero___mk"></a>

**type class**

```text
NeZero.{u_1} {R : Type u_1} [Zero R] (n : R) : Prop
```

A type-class version of `n ≠ 0`.

**Instance Constructor**

```text
NeZero.mk.{u_1}
```

**Methods**

```text
out : n ≠ 0
```

The proposition that `n` is not zero.

<a id="HAdd___mk"></a>

**type class**

```text
HAdd.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) :
  Type (max (max u v) w)
```

The notation typeclass for heterogeneous addition. This enables the notation `a + b : γ` where `a : α`, `b : β`.

**Instance Constructor**

```text
HAdd.mk.{u, v, w}
```

**Methods**

```text
hAdd : α → β → γ
```

`a + b` computes the sum of `a` and `b`. The meaning of this notation is type-dependent.

Conventions for notations in identifiers:

- The recommended spelling of `+` in identifiers is `add`.

<a id="Add___mk"></a>

**type class**

```text
Add.{u} (α : Type u) : Type u
```

The homogeneous version of `HAdd`: `a + b : α` where `a b : α`.

**Instance Constructor**

```text
Add.mk.{u}
```

**Methods**

```text
add : α → α → α
```

`a + b` computes the sum of `a` and `b`. See `HAdd`.

<a id="HSub___mk"></a>

**type class**

```text
HSub.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) :
  Type (max (max u v) w)
```

The notation typeclass for heterogeneous subtraction. This enables the notation `a - b : γ` where `a : α`, `b : β`.

**Instance Constructor**

```text
HSub.mk.{u, v, w}
```

**Methods**

```text
hSub : α → β → γ
```

`a - b` computes the difference of `a` and `b`. The meaning of this notation is type-dependent.

- For natural numbers, this operator saturates at 0: `a - b = 0` when `a ≤ b`.

Conventions for notations in identifiers:

- The recommended spelling of `-` in identifiers is `sub` (when used as a binary operator).

<a id="Sub___mk"></a>

**type class**

```text
Sub.{u} (α : Type u) : Type u
```

The homogeneous version of `HSub`: `a - b : α` where `a b : α`.

**Instance Constructor**

```text
Sub.mk.{u}
```

**Methods**

```text
sub : α → α → α
```

`a - b` computes the difference of `a` and `b`. See `HSub`.

<a id="HMul___mk"></a>

**type class**

```text
HMul.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) :
  Type (max (max u v) w)
```

The notation typeclass for heterogeneous multiplication. This enables the notation `a * b : γ` where `a : α`, `b : β`.

**Instance Constructor**

```text
HMul.mk.{u, v, w}
```

**Methods**

```text
hMul : α → β → γ
```

`a * b` computes the product of `a` and `b`. The meaning of this notation is type-dependent.

Conventions for notations in identifiers:

- The recommended spelling of `*` in identifiers is `mul`.

<a id="SMul___mk"></a>

**type class**

```text
SMul.{u, v} (M : Type u) (α : Type v) : Type (max u v)
```

Typeclass for types with a scalar multiplication operation, denoted `•` (`\bu`)

**Instance Constructor**

```text
SMul.mk.{u, v}
```

**Methods**

```text
smul : M → α → α
```

`m • a : α` denotes the product of `m : M` and `a : α`. The meaning of this notation is type-dependent, but it is intended to be used for left actions.

<a id="Mul___mk"></a>

**type class**

```text
Mul.{u} (α : Type u) : Type u
```

The homogeneous version of `HMul`: `a * b : α` where `a b : α`.

**Instance Constructor**

```text
Mul.mk.{u}
```

**Methods**

```text
mul : α → α → α
```

`a * b` computes the product of `a` and `b`. See `HMul`.

<a id="HDiv___mk"></a>

**type class**

```text
HDiv.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) :
  Type (max (max u v) w)
```

The notation typeclass for heterogeneous division. This enables the notation `a / b : γ` where `a : α`, `b : β`.

**Instance Constructor**

```text
HDiv.mk.{u, v, w}
```

**Methods**

```text
hDiv : α → β → γ
```

`a / b` computes the result of dividing `a` by `b`. The meaning of this notation is type-dependent.

- For most types like `Nat`, `Int`, `Rat`, `Real`, `a / 0` is defined to be `0`.
- For `Nat`, `a / b` rounds downwards.
- For `Int`, `a / b` rounds downwards if `b` is positive or upwards if `b` is negative. It is implemented as `Int.ediv`, the unique function satisfying `a % b + b * (a / b) = a` and `0 ≤ a % b < natAbs b` for `b ≠ 0`. Other rounding conventions are available using the functions `Int.fdiv` (floor rounding) and `Int.tdiv` (truncation rounding).
- For `Float`, `a / 0` follows the IEEE 754 semantics for division, usually resulting in `inf` or `nan`.

Conventions for notations in identifiers:

- The recommended spelling of `/` in identifiers is `div`.

<a id="Div___mk"></a>

**type class**

```text
Div.{u} (α : Type u) : Type u
```

The homogeneous version of `HDiv`: `a / b : α` where `a b : α`.

**Instance Constructor**

```text
Div.mk.{u}
```

**Methods**

```text
div : α → α → α
```

`a / b` computes the result of dividing `a` by `b`. See `HDiv`.

<a id="Dvd___mk"></a>

**type class**

```text
Dvd.{u_1} (α : Type u_1) : Type u_1
```

Notation typeclass for the `∣` operation (typed as `\|`), which represents divisibility.

**Instance Constructor**

```text
Dvd.mk.{u_1}
```

**Methods**

```text
dvd : α → α → Prop
```

Divisibility. `a ∣ b` (typed as `\|`) means that there is some `c` such that `b = a * c`.

Conventions for notations in identifiers:

- The recommended spelling of `∣` in identifiers is `dvd`.

<a id="HMod___mk"></a>

**type class**

```text
HMod.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) :
  Type (max (max u v) w)
```

The notation typeclass for heterogeneous modulo / remainder. This enables the notation `a % b : γ` where `a : α`, `b : β`.

**Instance Constructor**

```text
HMod.mk.{u, v, w}
```

**Methods**

```text
hMod : α → β → γ
```

`a % b` computes the remainder upon dividing `a` by `b`. The meaning of this notation is type-dependent.

- For `Nat` and `Int` it satisfies `a % b + b * (a / b) = a`, and `a % 0` is defined to be `a`.

Conventions for notations in identifiers:

- The recommended spelling of `%` in identifiers is `mod`.

<a id="Mod___mk"></a>

**type class**

```text
Mod.{u} (α : Type u) : Type u
```

The homogeneous version of `HMod`: `a % b : α` where `a b : α`.

**Instance Constructor**

```text
Mod.mk.{u}
```

**Methods**

```text
mod : α → α → α
```

`a % b` computes the remainder upon dividing `a` by `b`. See `HMod`.

<a id="HPow___mk"></a>

**type class**

```text
HPow.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) :
  Type (max (max u v) w)
```

The notation typeclass for heterogeneous exponentiation. This enables the notation `a ^ b : γ` where `a : α`, `b : β`.

**Instance Constructor**

```text
HPow.mk.{u, v, w}
```

**Methods**

```text
hPow : α → β → γ
```

`a ^ b` computes `a` to the power of `b`. The meaning of this notation is type-dependent.

Conventions for notations in identifiers:

- The recommended spelling of `^` in identifiers is `pow`.

<a id="Pow___mk"></a>

**type class**

```text
Pow.{u, v} (α : Type u) (β : Type v) : Type (max u v)
```

The homogeneous version of `HPow`: `a ^ b : α` where `a : α`, `b : β`. (The right argument is not the same as the left since we often want this even in the homogeneous case.)

Types can choose to subscribe to particular defaulting behavior by providing an instance to either `NatPow` or `HomogeneousPow`:

- `NatPow` is for types whose exponents is preferentially a `Nat`.
- `HomogeneousPow` is for types whose base and exponent are preferentially the same.

**Instance Constructor**

```text
Pow.mk.{u, v}
```

**Methods**

```text
pow : α → β → α
```

`a ^ b` computes `a` to the power of `b`. See `HPow`.

<a id="NatPow___mk"></a>

**type class**

```text
NatPow.{u} (α : Type u) : Type u
```

The homogeneous version of `Pow` where the exponent is a `Nat`. The purpose of this class is that it provides a default `Pow` instance, which can be used to specialize the exponent to `Nat` during elaboration.

For example, if `x ^ 2` should preferentially elaborate with `2 : Nat` then `x`'s type should provide an instance for this class.

**Instance Constructor**

```text
NatPow.mk.{u}
```

**Methods**

```text
pow : α → Nat → α
```

`a ^ n` computes `a` to the power of `n` where `n : Nat`. See `Pow`.

<a id="HomogeneousPow___mk"></a>

**type class**

```text
HomogeneousPow.{u} (α : Type u) : Type u
```

The completely homogeneous version of `Pow` where the exponent has the same type as the base. The purpose of this class is that it provides a default `Pow` instance, which can be used to specialize the exponent to have the same type as the base's type during elaboration. This is to say, a type should provide an instance for this class in case `x ^ y` should be elaborated with both `x` and `y` having the same type.

For example, the `Float` type provides an instance of this class, which causes expressions such as `(2.2 ^ 2.2 : Float)` to elaborate.

**Instance Constructor**

```text
HomogeneousPow.mk.{u}
```

**Methods**

```text
pow : α → α → α
```

`a ^ b` computes `a` to the power of `b` where `a` and `b` both have the same type.

<a id="HShiftLeft___mk"></a>

**type class**

```text
HShiftLeft.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) :
  Type (max (max u v) w)
```

The typeclass behind the notation `a <<< b : γ` where `a : α`, `b : β`.

**Instance Constructor**

```text
HShiftLeft.mk.{u, v, w}
```

**Methods**

```text
hShiftLeft : α → β → γ
```

`a <<< b` computes `a` shifted to the left by `b` places. The meaning of this notation is type-dependent.

- On `Nat`, this is equivalent to `a * 2 ^ b`.
- On `UInt8` and other fixed width unsigned types, this is the same but truncated to the bit width.

Conventions for notations in identifiers:

- The recommended spelling of `<<<` in identifiers is `shiftLeft`.

<a id="ShiftLeft___mk"></a>

**type class**

```text
ShiftLeft.{u} (α : Type u) : Type u
```

The homogeneous version of `HShiftLeft`: `a <<< b : α` where `a b : α`.

**Instance Constructor**

```text
ShiftLeft.mk.{u}
```

**Methods**

```text
shiftLeft : α → α → α
```

The implementation of `a <<< b : α`. See `HShiftLeft`.

<a id="HShiftRight___mk"></a>

**type class**

```text
HShiftRight.{u, v, w} (α : Type u) (β : Type v)
  (γ : outParam (Type w)) : Type (max (max u v) w)
```

The typeclass behind the notation `a >>> b : γ` where `a : α`, `b : β`.

**Instance Constructor**

```text
HShiftRight.mk.{u, v, w}
```

**Methods**

```text
hShiftRight : α → β → γ
```

`a >>> b` computes `a` shifted to the right by `b` places. The meaning of this notation is type-dependent.

- On `Nat` and fixed width unsigned types like `UInt8`, this is equivalent to `a / 2 ^ b`.

Conventions for notations in identifiers:

- The recommended spelling of `>>>` in identifiers is `shiftRight`.

<a id="ShiftRight___mk"></a>

**type class**

```text
ShiftRight.{u} (α : Type u) : Type u
```

The homogeneous version of `HShiftRight`: `a >>> b : α` where `a b : α`.

**Instance Constructor**

```text
ShiftRight.mk.{u}
```

**Methods**

```text
shiftRight : α → α → α
```

The implementation of `a >>> b : α`. See `HShiftRight`.

<a id="Neg___mk"></a>

**type class**

```text
Neg.{u} (α : Type u) : Type u
```

The notation typeclass for negation. This enables the notation `-a : α` where `a : α`.

**Instance Constructor**

```text
Neg.mk.{u}
```

**Methods**

```text
neg : α → α
```

`-a` computes the negative or opposite of `a`. The meaning of this notation is type-dependent.

Conventions for notations in identifiers:

- The recommended spelling of `-` in identifiers is `neg` (when used as a unary operator).

<a id="HAnd___mk"></a>

**type class**

```text
HAnd.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) :
  Type (max (max u v) w)
```

The typeclass behind the notation `a &&& b : γ` where `a : α`, `b : β`.

**Instance Constructor**

```text
HAnd.mk.{u, v, w}
```

**Methods**

```text
hAnd : α → β → γ
```

`a &&& b` computes the bitwise AND of `a` and `b`. The meaning of this notation is type-dependent.

Conventions for notations in identifiers:

- The recommended spelling of `&&&` in identifiers is `and`.

<a id="AndOp___mk"></a>

**type class**

```text
AndOp.{u} (α : Type u) : Type u
```

The homogeneous version of `HAnd`: `a &&& b : α` where `a b : α`. (It is called `AndOp` because `And` is taken for the propositional connective.)

**Instance Constructor**

```text
AndOp.mk.{u}
```

**Methods**

```text
and : α → α → α
```

The implementation of `a &&& b : α`. See `HAnd`.

<a id="HOr___mk"></a>

**type class**

```text
HOr.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) :
  Type (max (max u v) w)
```

The typeclass behind the notation `a ||| b : γ` where `a : α`, `b : β`.

**Instance Constructor**

```text
HOr.mk.{u, v, w}
```

**Methods**

```text
hOr : α → β → γ
```

`a ||| b` computes the bitwise OR of `a` and `b`. The meaning of this notation is type-dependent.

Conventions for notations in identifiers:

- The recommended spelling of `|||` in identifiers is `or`.

<a id="OrOp___mk"></a>

**type class**

```text
OrOp.{u} (α : Type u) : Type u
```

The homogeneous version of `HOr`: `a ||| b : α` where `a b : α`. (It is called `OrOp` because `Or` is taken for the propositional connective.)

**Instance Constructor**

```text
OrOp.mk.{u}
```

**Methods**

```text
or : α → α → α
```

The implementation of `a ||| b : α`. See `HOr`.

<a id="HXor___mk"></a>

**type class**

```text
HXor.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) :
  Type (max (max u v) w)
```

The typeclass behind the notation `a ^^^ b : γ` where `a : α`, `b : β`.

**Instance Constructor**

```text
HXor.mk.{u, v, w}
```

**Methods**

```text
hXor : α → β → γ
```

`a ^^^ b` computes the bitwise XOR of `a` and `b`. The meaning of this notation is type-dependent.

Conventions for notations in identifiers:

- The recommended spelling of `^^^` in identifiers is `xor`.

<a id="XorOp___mk"></a>

**type class**

```text
XorOp.{u} (α : Type u) : Type u
```

The homogeneous version of `HXor`: `a ^^^ b : α` where `a b : α`.

**Instance Constructor**

```text
XorOp.mk.{u}
```

**Methods**

```text
xor : α → α → α
```

The implementation of `a ^^^ b : α`. See `HXor`.

<a id="The-Lean-Language-Reference--Type-Classes--Basic-Classes--Append"></a>
### 10.5.8. Append

<a id="HAppend___mk"></a>

**type class**

```text
HAppend.{u, v, w} (α : Type u) (β : Type v) (γ : outParam (Type w)) :
  Type (max (max u v) w)
```

The notation typeclass for heterogeneous append. This enables the notation `a ++ b : γ` where `a : α`, `b : β`.

**Instance Constructor**

```text
HAppend.mk.{u, v, w}
```

**Methods**

```text
hAppend : α → β → γ
```

`a ++ b` is the result of concatenation of `a` and `b`, usually read "append". The meaning of this notation is type-dependent.

Conventions for notations in identifiers:

- The recommended spelling of `++` in identifiers is `append`.

<a id="Append___mk"></a>

**type class**

```text
Append.{u} (α : Type u) : Type u
```

The homogeneous version of `HAppend`: `a ++ b : α` where `a b : α`.

**Instance Constructor**

```text
Append.mk.{u}
```

**Methods**

```text
append : α → α → α
```

`a ++ b` is the result of concatenation of `a` and `b`. See `HAppend`.

<a id="The-Lean-Language-Reference--Type-Classes--Basic-Classes--Data-Lookups"></a>
### 10.5.9. Data Lookups

<a id="GetElem___mk"></a>

**type class**

```text
GetElem.{u, v, w} (coll : Type u) (idx : Type v)
  (elem : outParam (Type w)) (valid : outParam (coll → idx → Prop)) :
  Type (max (max u v) w)
```

The classes `GetElem` and `GetElem?` implement lookup notation, specifically `xs[i]`, `xs[i]?`, `xs[i]!`, and `xs[i]'p`.

Both classes are indexed by types `coll`, `idx`, and `elem` which are the collection, the index, and the element types. A single collection may support lookups with multiple index types. The relation `valid` determines when the index is guaranteed to be valid; lookups of valid indices are guaranteed not to fail.

For example, an instance for arrays looks like `GetElem (Array α) Nat α (fun xs i => i < xs.size)`. In other words, given an array `xs` and a natural number `i`, `xs[i]` will return an `α` when `valid xs i` holds, which is true when `i` is less than the size of the array. `Array` additionally supports indexing with `USize` instead of `Nat`. In either case, because the bounds are checked at compile time, no runtime check is required.

Given `xs[i]` with `xs : coll` and `i : idx`, Lean looks for an instance of `GetElem coll idx elem valid` and uses this to infer the type of the return value `elem` and side condition `valid` required to ensure `xs[i]` yields a valid value of type `elem`. The tactic `get_elem_tactic` is invoked to prove validity automatically. The `xs[i]'p` notation uses the proof `p` to satisfy the validity condition. If the proof `p` is long, it is often easier to place the proof in the context using `have`, because `get_elem_tactic` tries `assumption`.

The proof side-condition `valid xs i` is automatically dispatched by the `get_elem_tactic` tactic; this tactic can be extended by adding more clauses to `get_elem_tactic_extensible` using `macro_rules`.

`xs[i]?` and `xs[i]!` do not impose a proof obligation; the former returns an `Option elem`, with `none` signalling that the value isn't present, and the latter returns `elem` but panics if the value isn't there, returning `default : elem` based on the `Inhabited elem` instance. These are provided by the `GetElem?` class, for which there is a default instance generated from a `GetElem` class as long as `valid xs i` is always decidable.

Important instances include:

- `arr[i] : α` where `arr : Array α` and `i : Nat` or `i : USize`: does array indexing with no runtime bounds check and a proof side goal `i < arr.size`.
- `l[i] : α` where `l : List α` and `i : Nat`: index into a list, with proof side goal `i < l.length`.

**Instance Constructor**

```text
GetElem.mk.{u, v, w}
```

**Methods**

```text
getElem : (xs : coll) → (i : idx) → valid xs i → elem
```

The syntax `arr[i]` gets the `i`'th element of the collection `arr`. If there are proof side conditions to the application, they will be automatically inferred by the `get_elem_tactic` tactic.

Conventions for notations in identifiers:

- The recommended spelling of `xs[i]` in identifiers is `getElem`.
- The recommended spelling of `xs[i]'h` in identifiers is `getElem`.

<a id="GetElem______mk"></a>

**type class**

```text
GetElem?.{u, v, w} (coll : Type u) (idx : Type v)
  (elem : outParam (Type w)) (valid : outParam (coll → idx → Prop)) :
  Type (max (max u v) w)
```

The classes `GetElem` and `GetElem?` implement lookup notation, specifically `xs[i]`, `xs[i]?`, `xs[i]!`, and `xs[i]'p`.

Both classes are indexed by types `coll`, `idx`, and `elem` which are the collection, the index, and the element types. A single collection may support lookups with multiple index types. The relation `valid` determines when the index is guaranteed to be valid; lookups of valid indices are guaranteed not to fail.

For example, an instance for arrays looks like `GetElem (Array α) Nat α (fun xs i => i < xs.size)`. In other words, given an array `xs` and a natural number `i`, `xs[i]` will return an `α` when `valid xs i` holds, which is true when `i` is less than the size of the array. `Array` additionally supports indexing with `USize` instead of `Nat`. In either case, because the bounds are checked at compile time, no runtime check is required.

Given `xs[i]` with `xs : coll` and `i : idx`, Lean looks for an instance of `GetElem coll idx elem valid` and uses this to infer the type of the return value `elem` and side condition `valid` required to ensure `xs[i]` yields a valid value of type `elem`. The tactic `get_elem_tactic` is invoked to prove validity automatically. The `xs[i]'p` notation uses the proof `p` to satisfy the validity condition. If the proof `p` is long, it is often easier to place the proof in the context using `have`, because `get_elem_tactic` tries `assumption`.

The proof side-condition `valid xs i` is automatically dispatched by the `get_elem_tactic` tactic; this tactic can be extended by adding more clauses to `get_elem_tactic_extensible` using `macro_rules`.

`xs[i]?` and `xs[i]!` do not impose a proof obligation; the former returns an `Option elem`, with `none` signalling that the value isn't present, and the latter returns `elem` but panics if the value isn't there, returning `default : elem` based on the `Inhabited elem` instance. These are provided by the `GetElem?` class, for which there is a default instance generated from a `GetElem` class as long as `valid xs i` is always decidable.

Important instances include:

- `arr[i] : α` where `arr : Array α` and `i : Nat` or `i : USize`: does array indexing with no runtime bounds check and a proof side goal `i < arr.size`.
- `l[i] : α` where `l : List α` and `i : Nat`: index into a list, with proof side goal `i < l.length`.

**Instance Constructor**

```text
GetElem?.mk.{u, v, w}
```

**Extends**

- <a id="0-GetElem-GetElem?"></a>
  `GetElem coll idx elem valid`

**Methods**

```text
getElem : (xs : coll) → (i : idx) → valid xs i → elem
```

 Inherited from 

1. `GetElem coll idx elem valid`

```text
getElem? : coll → idx → Option elem
```

The syntax `arr[i]?` gets the `i`'th element of the collection `arr`, if it is present (and wraps it in `some`), and otherwise returns `none`.

Conventions for notations in identifiers:

- The recommended spelling of `xs[i]?` in identifiers is `getElem?`.

```text
getElem! : [Inhabited elem] → coll → idx → elem
```

The syntax `arr[i]!` gets the `i`'th element of the collection `arr`, if it is present, and otherwise panics at runtime and returns the `default` term from `Inhabited elem`.

Conventions for notations in identifiers:

- The recommended spelling of `xs[i]!` in identifiers is `getElem!`.

<a id="LawfulGetElem___mk"></a>

**type class**

```text
LawfulGetElem.{u, v, w} (cont : Type u) (idx : Type v)
  (elem : outParam (Type w)) (dom : outParam (cont → idx → Prop))
  [ge : GetElem? cont idx elem dom] : Prop
```

Lawful `GetElem?` instances (which extend `GetElem`) are those for which the potentially-failing `GetElem?.getElem?` and `GetElem?.getElem!` operators succeed when the validity predicate is satisfied, and fail when it is not.

**Instance Constructor**

```text
LawfulGetElem.mk.{u, v, w}
```

**Methods**

```text
getElem?_def : ∀ (c : cont) (i : idx) [inst : Decidable (dom c i)], c[i]? = if h : dom c i then some c[i] else none
```

`GetElem?.getElem?` succeeds when the validity predicate is satisfied and fails otherwise.

```text
getElem!_def : ∀ [inst : Inhabited elem] (c : cont) (i : idx),
  c[i]! =
    match c[i]? with
    | some e => e
    | none => default
```

`GetElem?.getElem!` succeeds and fails when `GetElem.getElem?` succeeds and fails.

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
The less-than relation: `x < y` 

Conventions for notations in identifiers:

 * The recommended spelling of `<` in identifiers is `lt`.
```


### Display 2


```text
The less-equal relation: `x ≤ y` 

Conventions for notations in identifiers:

 * The recommended spelling of `≤` in identifiers is `le`.
```


### Display 3


```text
`a > b` is an abbreviation for `b < a`. 

Conventions for notations in identifiers:

 * The recommended spelling of `>` in identifiers is `gt`.
```


### Display 4


```text
`a ≥ b` is an abbreviation for `b ≤ a`. 

Conventions for notations in identifiers:

 * The recommended spelling of `≥` in identifiers is `ge`.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
true
```


### Display 2


```text
false
```


### Display 3


```text
failed to synthesize instance of type class
  Decidable (f = g)

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

