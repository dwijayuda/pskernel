# PSKernel Con Leche

Experimental **alternative independent checker** for PSC0, implemented in native
Lean 4.35.0. The kernel is the real `leanprover/con-leche`, pinned at
`b47ea19d6864a1fd09db6144528f91baa5c550dd`, not a renamed copy of PSKernel Core
or PSKernel-C0. This package adds the PSC0-facing boundary and stricter input
axiom policy without changing the upstream checker or its proof.

## Scope

This initial package checks complete **lean4export 3.x NDJSON streams**. It does
NOT yet consume PSC0 canonical admissions v2 or compile `.ps` source. It is not
registered in `Ps.Host.NativeV7`, the parent Lake workspace, the npm runtime
registry, or any backend. Official Lean remains the active compiler's authority.
A successful check is not a PSC0 publication capability. The new branch is an
explicit research exception, not a change to the native M3+B roadmap.

Read [ARCHITECTURE.md](ARCHITECTURE.md) for the actual codebase analysis and
integration gates, [UPSTREAM_PIN.json](UPSTREAM_PIN.json) for immutable identity,
and [AI_WORK_STATE.md](AI_WORK_STATE.md) for qualification state.

## Build and use

```sh
cd psc0/packages/pskernel-con-leche
lake update
lake build
lake exe pskernel-con-leche --identity
lake exe pskernel-con-leche --ndjson /path/to/complete-export.ndjson
lake exe pskernel-con-leche-tests
lake build PsKernelConLecheProofs
```

The first update downloads the pinned source dependency. No downloaded checker
binary, preprocessing service, self-host bootstrap, or compiler migration is
required. The npm manifest is private metadata/build tooling; it deliberately
advertises no nonexistent JavaScript checker or distributable native binary.

`--ndjson` is the only checking entry point. `--trusted`, unknown options, missing
files and canonical-v2 inputs fail. Exit codes: **0 accepted**, **1 invalid**,
**2 positively unsupported/policy-declined**, **3 malformed/internal/resource**.
A timeout, signal, missing binary or nonzero exit must never be treated as
acceptance. `--identity` also exits zero but reports `status: identity`, not an
accept; consumers must validate the operation and status as well as the exit.

The CLI sets the upstream panic/linearity abort variables before checking. The
caller must impose a wall-clock and OS memory limit for untrusted inputs. The
initial in-memory adapter bounds input to 64 MiB and one million declaration
records; a resource refusal is not a compatibility verdict. The file is checked
before and after reading, but the byte bound is not an OS memory limit. Use a
separate process per checking request in a future host integration.

## Trust and evidence

`check` returns `CheckedInput chunks limits`, containing an environment and the
Lean equation proving that `checkInput` accepted those exact chunks and limits.
This is in-process evidence, not a serialized token. The optional proof target
proves that every wrapper accept is an upstream verified-fold accept and applies
upstream's `model_exists` theorem. Its build is a separate qualification gate;
merely writing the theorem is not qualification.

The checker uses only `.verified`; no retry, fallback, cached accept, or selection
of `.trusted` is provided. It completes both install and pending-check phases.
The entire prepared declaration stream, including the built-in prelude, is
checked. No file declaration is dropped by this adapter.

PSC0 permits only input axioms `propext` and `Quot.sound`. The policy uses exact
structured names and lets the upstream checker validate their full types.
`Classical.choice`, arbitrary axioms and even a declaration of `sorryAx` decline
(the last is intentionally stricter than upstream). Upstream's MODEL PROOF uses
`Classical.choice` in the metalogic and assumes a suitable `SetTheory V`; that is
disclosed separately and is not a new admitted input axiom.

Neither upstream consistency nor wrapper refinement establishes PSC0 source
preservation, canonical-to-export correspondence, primitive runtime correctness,
backend correctness, full Lean compatibility, or performance parity. These are
separate claims and remain open here.

## Upstream

- Source and license: https://github.com/leanprover/con-leche/tree/b47ea19d6864a1fd09db6144528f91baa5c550dd
- Checker fold: `ConLeche/Cached/Installed.lean`
- Parser/prelude: `ConLeche/Frontend/{Stream,Prelude,Prepare,ExportC}.lean`
- Model theorem: `ConLeche/MainTheorem.lean`

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Upgrades require a new exact
pin, upstream API/trust-boundary review, and fresh qualification.
