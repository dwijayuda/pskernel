# PSC0 PSCV P1-J — normative arithmetic family typed resolution

**Scope:** actual Lean instance-synthesis observations for all 42 §24.3
addition, subtraction, and multiplication operator/type requirements
across 14 listed standard numeric basis types, with 84 independent
typeclass elaborations. This is a scalable *family* rather than seven
handpicked hardcoded source examples.

The generator reads the exact SHA-pinned `PSCV-RC-v2` normative
reference and derives 42 source rows using a closed operator-to-class
mapping:

- `+` → `HAdd T T T` and `Add T`
- `-` → `HSub T T T` and `Sub T`
- `*` → `HMul T T T` and `Mul T`

The fixed eligible basis types are Nat, Int, Int8/16/32/64,
UInt8/16/32/64, USize, ISize, Float, and Float32.
Every generated Lean source also includes an `inferInstance` typecheck
example for each goal. Cloud qualification requires the *actual*
Lean4.35.0-rc3 imported `PSCVL.Policy` environment and rejects any
missing goal, altered generated source, malformed output, or nonzero Lean
exit status. Results bind normative source digest, goal plan and emitted
text to the named source rows and their required snapshot IDs.

**Important limit:** a successful `#synth` in the imported Lean
environment is not a proof that an instance is permitted in closed
PSCV Standard. It does not prove generic-to-concrete dependency,
priority/tie/import scope, immutable declaration source locations,
runtime implementation or compiler preservation, and does not justify
any new `std.*` snapshot-ID mapping. The prior three direct Boolean
IDs remain source-located, with the other **191** still unresolved.

Before P1 closes, the complete ordered Standard registration policy,
coercion/simp/simproc/ext/grind environment and effect/WP laws must be
approved, source-located and qualified with positive/negative tests.
[P1–P5 sound gate plan](PSCV_P1_TO_P5_SOUND_GATES.md) remains applicable.
No normal compiler, PSKernel, self-host seed, TS7 target, npm release,
or PSCV certification gate is changed.
