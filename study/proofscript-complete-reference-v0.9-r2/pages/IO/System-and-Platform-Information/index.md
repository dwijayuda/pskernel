<a id="platform-info"></a>

# ProofScript — 21.6. System and Platform Information

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Native IO separates a logical description from execution in a runtime environment. Console operations, mutable references, files, processes, clocks, randomness and tasks have exact APIs and effects. A file handle is a resource with identity and lifetime, not an immutable DTO. Browser, Node and Wasm hosts require explicit adapters; the existence of a Lean API does not establish that every target can implement it.

**Compiler and coverage boundary.** Retain native Task behavior rather than renaming Promise. Resource cleanup, cancellation, process termination and foreign failures need exact declared models; no undocumented async/await keyword is introduced.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [IO/System-and-Platform-Information/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/IO/System-and-Platform-Information/index.html). Source Git blob: `21621d8a6d5fcf512e645da9482c52351ca3ab8c`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 21.6. System and Platform Information

<a id="System___Platform___numBits"></a>

**def**

```text
System.Platform.numBits : Nat
```

The word size of the current platform, which may be 64 or 32 bits.

<a id="System___Platform___target"></a>

**def**

```text
System.Platform.target : String
```

The LLVM target triple of the current platform. Empty if missing when Lean was compiled.

<a id="System___Platform___isWindows"></a>

**def**

```text
System.Platform.isWindows : Bool
```

Is the current platform Windows?

<a id="System___Platform___isOSX"></a>

**def**

```text
System.Platform.isOSX : Bool
```

Is the current platform macOS?

<a id="System___Platform___isEmscripten"></a>

**def**

```text
System.Platform.isEmscripten : Bool
```

Is the current platform [Emscripten](https://emscripten.org/)?
