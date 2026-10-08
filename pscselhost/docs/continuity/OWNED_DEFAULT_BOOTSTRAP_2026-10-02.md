# Owned default and joint bootstrap source closure

This implements the user's revised direction: new owned `pskernel-core` is the
default and enters bootstrap. Lean WASM and native remain explicit alternatives
outside the portable closure. Legacy core and KernelOne work are not restarted.
Authoritative, release readiness and self-hosting claims remain false until their
measured gates pass.

The original replay checkout at `fbfd10886bc290b006a9abc01d36153f2d7a89c7` and its
running immutable snapshots are protected. Development uses a separate checkout.
The protected tail-loop replay completed preparation after 7,767,022 ms; no final
emitted fixed point is claimed.

Kernel regeneration is commit `f5018259`; prelude binding split is `60e95633`.
Full prelude parity and bootstrap regressions pass. The kernel's 264-test Linux
baseline and fresh bounded differential evidence pass; complete build digests
are in `OWNED_KERNEL_REGENERATION_2026-10-02.md`.

The default runs pinned generated semantic transitions in an isolated worker,
with strict wire conversion, a shared step budget, memory and wall clock limits.
It never delegates rejected or unsupported inputs to Lean. Provider-neutral
checked handles bind emission to the frozen prepared graph. Reference and owned
generations use distinct output directories and identities.

The actual 68-module source snapshot SHA-256 is
`c7e18729ab98086ecdc4c9dffdaaf5905c1bad7dcd1db418839747b55de8150b`.
Canonical admissions SHA-256 is
`d18a18cc88f749fbc914c4ff241f20b631f3c5aa57b82c1701140097ef240fd6`.
The rebuilt native seed prepared these sources; the selected owned checker
returned `unsupported-admission:inductive`, index 0, after 46,479 ms overall.
First declaration: `_pscCheckedNestedUnit`, polymorphic in `_pscCheckedMotive`.
The seed was stopped without emission. Source, admissions, exact seed binary and
result are saved in `work/joint-owned-default-60e95633/` outside the source checkout.

Focused provider tests: 21 pass, covering invalid types, duplicate/self/forward
references, fresh environments, malformed/unsupported inputs, timeouts, exhaustion,
exact checked-module consumption and identity. Prepared-session/provider regressions:
21 pass. Real frontend/build tests: 7 pass, including an owned dependent identity
through executed JavaScript, rejection before output, and explicit Lean alternatives.

The immediate semantic dependency is universe-polymorphic inductive admission and
recursor checking/reduction. Subsequent inventory requirements include prelude
primitives and the recorded conversion gaps. Full owned bootstrap and joint release
remain blocked by these missing semantics.
