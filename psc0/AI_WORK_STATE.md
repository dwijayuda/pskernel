# PSC0 AI work state — first generated PSCV0 readable-source bridge qualified

## Read first: actual result (2026-10-11)

Branch: `psc0/pscv0-readable-selfhost-v1`, based on adoption checkpoint `b64a95e4537dade93462e0232b5da54d79f9cb25` of `psc0/npm-modular-packages-v1`.

The bounded capability **`declaration-except-do/1` is implemented and qualified as a generated portable source bridge**. This is not completion of PSCV0 or migration of the whole compiler to `.ps`, and does not replace the public `psc` CLI.

- Portable implementation: `1ed94be7b1d3c49f11e302464478be76fa299172`, four new `.lean` modules owned by `@proofscript/syntax`.
- Retained self-hosted PSC0 JavaScript generated the bridge's **19-module syntax/foundation closure**, without rebuilding the whole compiler or kernel.
- Generated Linux job `114349106754` and Windows job `114351167496` in [run 38098425773](https://github.com/dwijayuda/pskernel/actions/runs/38098425773) both **passed 38/38 tests**. Ten program fixtures were compiled and admitted by the unchanged selected JS kernel; success values, first-error propagation, shadowing and source round trips were checked.
- That historical run remains **failed overall**, because its RC4 job failed during reference-project setup. Never relabel it green.
- The independent RC4 replay [38108354566](https://github.com/dwijayuda/pskernel/actions/runs/38108354566), job `114378537741`, **passed** at source `4269b087b3bf2bc81baf9920ab3f23aae251cc54`. It reused exact generated artifacts, verified their source/file identities and both platform test reports, and proved the actual generated readable-do and lowered-match fixture functions equal for every pair of `Except String Nat` inputs. Lean 4.35.0-rc4 reported **no theorem axioms**. A known-false ground equation was rejected, then the positive proof passed again.
- Replay executed no downloaded JavaScript and regenerated neither compiler nor kernel. All original 38 generated-JS tests and portable implementation sources were unchanged by reference completion.

Contracts and evidence: [PSCV0_EXCEPT_DO_BRIDGE.md](docs/PSCV0_EXCEPT_DO_BRIDGE.md), [PSCV0_BRIDGE_VALIDATION.md](docs/PSCV0_BRIDGE_VALIDATION.md), [PSCV0_BRIDGE_CAPABILITIES.json](docs/PSCV0_BRIDGE_CAPABILITIES.json).

## User intent and immutable boundaries

The selected source-language reference is the user's `Lean4_ProofScript_PSCV0_Lean435rc4_Expanded_Lean_First_Unified_Language_Reference(2).md`: **230234 bytes**, SHA-256 `a419955383fd3e35d873f82c939ecf3a92dc65b162cc9d0d3cadf5b853a0f4b0`. Its semantic pin is Lean **4.35.0-rc4**, commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. The complete reference remains in the user attachment; the adoption record identifies it, rather than claiming a verbatim repository copy.

The user wants useful language additions first, readable authoritative `.ps` compiler source later, and a readable `.lean` projection. No backward-compatible old `.ps` mode is required. Historical seeds remain immutable bootstrap evidence, not the new language ceiling. Do not rename an old parser and claim full PSCV0 support.

Keep kernel implementation/metatheory work separate. Main, the original npm branch, existing public host, existing 69 compiler source files, selected compiler seed, grammar identity of that existing compiler, and kernel source/JS adapter remain unchanged. New additions under `packages/syntax/src/Ps/Syntax/Pscv0/` have their own limited evidence; they are not covered merely because older files are unchanged.

Use GitHub for repository reads/writes and cloud CI for execution. No local repo checkout/build/test, Desktop Commander, force pushes, npm publication or unrequested main merge. Fetch live HEAD before every mutation; preserve concurrent commits with expected-HEAD non-force updates. Do not trust this checkpoint's hashes as current without reading GitHub.

## Implemented portable mechanism

| Owner | Role |
| --- | --- |
| `Syntax/Pscv0/Surface.lean` | Source-level do items and declaration intent; paired printing; hygienic Except match/let lowering |
| `Syntax/Pscv0/Read.lean` | Balanced token/position reader for PS braced/newline do and selected native Lean layout |
| `Syntax/Pscv0/Commands.lean` | Declaration binder/result-type delimiter ownership; no textual grammar replacement |
| `Syntax/Pscv0/Module.lean` | Original source capture; declaration/body association; source views and separate semantic lowering |

Selected forms: declaration-body do with explicit builtin `Except E A` result; identifier/wildcard binds; immutable lets including supported typed lets; discarded/intermediate actions; terminal return/final action. All lowering goes to already supported ordinary terms and still needs real compiler/type/kernel checking.

Readability works in both directions without printing the lowered matches as the authoring representation:

```text
function step(a: Except String Nat): Except String Nat := do {
  let x ← a
  return Nat.succ(x)
}
```

```lean
def step (a : Except String Nat) : Except String Nat := do
  let x ← a
  return Nat.succ x
```

The original source is retained exactly by `psPscv0ReplayOriginal`. Canonical printing of comments without placement anchors explicitly refuses with `PSCV0-TRIVIA-PRINT-PENDING`; comments are not silently dropped. Source size/token/do-item/nesting budgets remain active. Name hygiene, first-error propagation and parameterless-value semantics are covered by tests.

Unsupported: arbitrary monads/typeclass inference, nested/expression-local do, early return, mutation, loops, try/catch/finally/throw, nullary Unit completion, untyped inferred lambdas, new projections/record updates, richer pattern compilation and general comment formatting. Existing leaf-expression limitations are not silently relaxed. No executable extensions or kernel primitives were added.

## Exact generation and evidence identities

Retained builder: npm run `38075437516`, source `2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a`, artifact `11678641329`. Builder JS SHA-256 `6cddc3c34c38f1524ef9a355c46b0eb17949c45c54fd59367ea370c1af861ab3`. TypeScript **7.0.2**; bootstrap implementation type checks under Lean **4.34.0**. The separate RC4 lane is not a kernel/runtime upgrade.

Generated bridge JS SHA-256: `1ef9268e2b84aab67e5c122bf860f85957c6b66352d71be5f76bb4354cdfa281`.
Generated bridge TS SHA-256: `5a27fda9ca051a9bd769da6d678f75b3ae3a54804ea22807c53d24006b7aca7f`.
Ten-fixture canonical admissions SHA-256, identical on Linux/Windows: `6f14a42e22bf0e0fb41fbe4af07ada5bcbc82b21776e7f6b40149176d629ddb2`.

| Evidence | Run / source | Artifact | ZIP SHA-256 |
| --- | --- | --- | --- |
| Native source, five round trips, four refusals, comment replay and native fixture equality | `38098707088` / `be0232c40e77c603da6954c505fc7ace2aa0541f` | `11686798545` | `c7aafa3625cf0c04fbadce46fcfa75b9d9a6d4c3591d184e5f9a04610ff87c8b` |
| C0-generated bridge and Linux38 tests | `38098425773` / `1ed94be7b1d3c49f11e302464478be76fa299172` | `11686899111` | `ce2fb8315b733ae64aa8515d31eb32b4a5941a941a2119ce433fac5d41037361` |
| Windows38 tests over identical bridge | same source/run | `11686158753` | `a43cf36fae1e1499e5fa68c8fc92bc7dcef94318335fe766a23d773101476fe1` |
| Independent RC4 proof + retained-input verification + false-proof refusal | `38108354566` / `4269b087b3bf2bc81baf9920ab3f23aae251cc54` | `11691260418` | `bce05b001f8b7e62dda0bc29bb71ea31f3de499157e578ec19744bad9ec4c5b2` |

The reference proof uses unchanged generated functions and the same universal equality statement. Only the initial insufficient symbolic `rfl` proof body was replaced with `cases a <;> cases b <;> rfl`. Checked reference-source SHA-256: `26252fe00865f313b64b3b18cb397544c4b390dac65a044c9d05f6049759e8a6`. Functions+statement SHA-256: `d8f2aa3ab2647569acc6bb2a2127b3d0fb4172dabf02b248c9e964b842af4e95`.

This is a theorem about **one generated two-action program for all its inputs**, not the bridge algorithm, arbitrary source programs, JS semantic preservation, kernel soundness, or the full source-language selection. The bridge's own full admission stream is retained but not independently kernel-admitted; fixture admission is the qualified kernel evidence.

## Cost-controlled continuation

Finished: first portable source/do bridge plus paired readable source views and bounded qualification. Do not repeat the entire prefix build for reference-only changes. `.github/workflows/psc0-pscv0-reference-replay.yml` replays exact artifacts and verifies all relevant source digests; a changed implementation will correctly refuse reuse. The successful replay took approximately32 seconds including toolchain setup, not another syntax-closure generation.

For changes to bridge implementation, first use the fast native source/round-trip lane, then a genuinely needed generated bridge build. Do not treat native success as self-hosted-JS conformance. For whole compiler source or grammar changes, plan an explicit compiler-only qualification instead of overwriting old self-host baselines. No full C2/C3 cycle was performed here.

Next substantive migration work should use this bridge rather than adding another test wrapper: integrate the selected source path under an honest PSCV0 capability identity, address comment/source-origin placement and the declaration/application gaps required by actual compiler authoring, and migrate one representative compiler module with original-vs-new semantics checks before a broad source-authority switch. Expected-type conveniences, result projections and record updates remain the approved next language families; do not add unrelated backends or tactics first.

Public `psc`, full compiler source-authority migration, complete PSCV0 conformance, new selected seed, independent 13-package self-hosting, new installed C2/C3 and kernel self-hosting are **not completed or claimed**. No npm publication or replacement public ZIP was made.

## Historical evidence is preserved

The previous stale work state is archived byte-for-byte at [AI_WORK_STATE_PSCV0_BRIDGE_PREQUALIFICATION.md](docs/history/AI_WORK_STATE_PSCV0_BRIDGE_PREQUALIFICATION.md), blob `fbddb7ad9c7339665afbb3a3572a9d588b42c238`. It described an older build as in-progress; this state supersedes its current-status text, not its historical evidence. The previous detailed validation ledger is preserved at [PSCV0_BRIDGE_VALIDATION_BEFORE_RC4_REPLAY.md](docs/history/PSCV0_BRIDGE_VALIDATION_BEFORE_RC4_REPLAY.md). All actual failures and corrected bootstrap restrictions remain recorded there and in the current ledger.
