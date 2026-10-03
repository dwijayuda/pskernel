<a id="platforms"></a>

# ProofScript — Supported Platforms

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Upstream platform support describes the native Lean distribution at the source snapshot. It is not a promise of all ProofScript backends, npm bindings, browsers or Wasm embeddings. Target architecture, word width, runtime primitives and external capabilities belong in a separate executable profile.

**Compiler and coverage boundary.** An unsupported platform capability must reject or select an explicitly weaker named profile; no hidden substitution is permitted.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [platforms/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/platforms/index.html). Source Git blob: `f92cda3cea8b37cd640cbf9762287ee17ee7a4e4`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## Supported Platforms

<a id="The-Lean-Language-Reference--Supported-Platforms--Tier-1"></a>
### Tier 1

Tier 1 platforms are those for which Lean is built and tested by our CI infrastructure. Binary releases of Lean are available for these platforms via [`elan`](../Build-Tools-and-Distribution/Managing-Toolchains-with-Elan/index.md#elan). The Tier 1 platforms are:

- `x86-64` Linux with glibc 2.26+
- `aarch64` Linux with glibc 2.27+
- `aarch64` (Apple Silicon) macOS 10.15+
- `x86-64` Windows 11 (any version), Windows 10 (version 1903 or higher), Windows Server 2022, Windows Server 2025

<a id="The-Lean-Language-Reference--Supported-Platforms--Tier-2"></a>
### Tier 2

Tier 2 platforms are those for which Lean is cross-compiled but not tested by our CI. Binary releases are available for these platforms.

Releases may be silently broken due to the lack of automated testing. Issue reports and fixes are welcome.

The Tier 2 platforms are:

- `x86-64` macOS 10.15+
- Emscripten WebAssembly
