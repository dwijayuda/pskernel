# PSC0 AI work state — first PSCV0-authored compiler module candidate

## Current work (2026-10-11)

Branch `psc0/pscv0-readable-selfhost-v1`; starting checkpoint `82ad3c6ef1cc634a5c3d94a1bad7ad2babd2e263`.
The user authorized continuing the readable self-host migration. This slice uses the already qualified portable PSCV0 bridge to author the real `Ps.Syntax.Translate` compiler module in `.ps` and consume that source in the candidate bridge build. It does not broaden the language or replace the public compiler yet.

Implementation and validation are being committed; no new successful CI or completed source migration is claimed at this checkpoint. Read live branch HEAD and CI before continuing.

## Canonical candidate source and bootstrap boundaries

- Candidate authoring source: `packages/syntax/src-ps/Ps/Syntax/Translate.ps`, inside the existing `@proofscript/syntax` package.
- `pscv0-authoring.json` selects this module explicitly. Missing, invalid or unsupported selected PS fails; there is no fallback to the old Lean file.
- The original `packages/syntax/src/Ps/Syntax/Translate.lean`, Git blob `eafd7159b14a251fe11ffdbfb1e2482bcc773c9b`, remains immutable predecessor code. It is not a second editable candidate master. `src-ps` avoids an accidental same-path source collision in the old release packer. Promotion/moving the final source root is a later explicit operation.
- The candidate retains the four translation API signatures and behavior while replacing repeated error propagation with `do` and one generic pure error-mapping helper. Keeping predecessor leaf-translation APIs during bootstrap is not a user-facing old-PS compatibility mode; the candidate source path applies PSCV0 restrictions and never falls back.
- Existing 69 baseline compiler files, all four qualified bridge implementation modules, public npm host, selected seed/toolchain and kernel source/JS adapter remain unchanged. The generated candidate bridge is new code and must earn its own evidence; unchanged-source inheritance alone cannot qualify it.

The selected specification remains the user's PSCV0 reference, SHA-256 `a419955383fd3e35d873f82c939ecf3a92dc65b162cc9d0d3cadf5b853a0f4b0`, Lean RC4 commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. Base do forms follow its §3, lines796–823 in the attached reference. This implementation is still the bounded `declaration-except-do/1` subset, not full PSCV0.

## Integration owners

`scripts/pscv0-authoring.mjs`: IO, explicit module selection, predecessor/seed hash validation and output capture. It invokes the actual retained portable bridge for all parsing/printing/lowering; no JS implementation of language semantics.

`scripts/pscv0-build-bridge.mjs`: actually chooses the `.ps` module from the manifest, lowers it using the qualified surface seed, and feeds that result to the retained self-hosted PSC0 compiler. Only the syntax/foundation bridge closure is regenerated. It records raw PS, readable Lean, lowered Lean and consumed-source identities.

`scripts/pscv0-authoring-proof.mjs`: runs native proofs that BOTH actual generated projections equal each of the four frozen predecessor APIs for every String input. There are eight theorems per Lean version; require no theorem axioms. Run this cheap gate before expensive generation. A proof script failure must not trigger a new full build before being resolved.

`scripts/pscv0-authoring.test.mjs`: compare the genuinely generated candidate APIs against retained compiler APIs on positive/negative sources; require the new bridge to read/lower its own selected PS source and reproduce both projections. Keep all original38 generated-bridge tests unchanged.

## Evidence and generation plan

Surface seed: generated bridge source `1ed94be7b1d3c49f11e302464478be76fa299172`, run `38098425773`, artifact `11686899111`; JS SHA-256 `1ef9268e2b84aab67e5c122bf860f85957c6b66352d71be5f76bb4354cdfa281`, TS SHA-256 `5a27fda9ca051a9bd769da6d678f75b3ae3a54804ea22807c53d24006b7aca7f`. Its 38-test Linux/Windows and RC4 qualification are recorded in `docs/PSCV0_BRIDGE_CAPABILITIES.json` and the archived work state.

Retained compiler: npm run `38075437516`, source `2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a`, artifact `11678641329`; TypeScript7.0.2. Do not regenerate compiler or kernel.

The workflow first type-checks the old bridge and generates/proves candidate source projections using native Lean4.34. Only after these cheap gates pass does it build the19-module syntax/foundation candidate using the retained compiler. Linux and Windows run the unchanged38 tests plus new authoring tests. The independent RC4 lane builds only the native syntax/foundation prerequisites and checks the actual generated module projections and existing do correspondence theorem.

## Honest limitations

This first selected module has no existing source comments; the gate verifies both old/new trivia inventories and exact source replay. No comments are lost, but general comment anchoring/formatting is NOT implemented. Do not strip comments to admit another source file. The materializer explicitly refuses commented canonical output until that feature exists.

Compiler diagnostics after lowering still use generated-Lean coordinates. Full PS source-to-diagnostic remapping is pending and must be addressed before switching the public authoring path. Neither source hashes nor this native proof constitute a general compiler/backend correctness theorem.

The public compiler source root remains unchanged. Only the candidate bridge build selects the first PS module. No full C2/C3, complete compiler migration, public npm release, kernel admission of the whole bridge, kernel regeneration or main merge is claimed.

## Continuation discipline

GitHub repository reads/writes and cloud CI only. No local checkout/build/test, Desktop Commander, force push, automatic npm publication or kernel edits. Preserve concurrent history with expected-HEAD non-force updates. Use native/focused checks before expensive generation; do not loosen old tests, source identity guards or the reference to obtain a pass.

Previous complete work state: `docs/history/AI_WORK_STATE_BEFORE_FIRST_PS_MODULE.md`, original blob `25c589a1970f6f3b91bb5f6855aaecdbd0eb39c1`. Keep historical failed runs failed and separate qualified old bridge from the newly generated authoring candidate.
