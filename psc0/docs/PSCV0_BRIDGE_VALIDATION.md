# PSCV0 source bridge — completed bounded qualification ledger

Keep native source validity, generated bridge behavior, fixture proofs and whole-compiler self-hosting distinct. **The first generated source-bridge capability is qualified; full PSCV0 and compiler-source migration are not.**

## Qualified implementation and evidence

Portable source: `1ed94be7b1d3c49f11e302464478be76fa299172`.
Reference-completion source: `4269b087b3bf2bc81baf9920ab3f23aae251cc54`.

| Lane | Source / run | Job | Actual result |
| --- | --- | --- | --- |
| Native portable source + source intent | `be0232c40e77c603da6954c505fc7ace2aa0541f` / [38098707088](https://github.com/dwijayuda/pskernel/actions/runs/38098707088) | `114349935198` | success; Lean4.34 checks4 modules,5 round trips,4 source refusals, original-comment replay and fixture equality |
| Retained self-hosted compiler generation + Linux | `1ed94be7b1d3c49f11e302464478be76fa299172` / [38098425773](https://github.com/dwijayuda/pskernel/actions/runs/38098425773) | `114349106754` | success; emits actual bridge JS,38/38 generated tests |
| Windows over identical bridge | same source/run | `114351167496` | success;38/38 generated tests |
| Pinned RC4 correspondence replay | `4269b087b3bf2bc81baf9920ab3f23aae251cc54` / [38108354566](https://github.com/dwijayuda/pskernel/actions/runs/38108354566) | `114378537741` | success; actual generated fixture proof with no axioms, false-proof refusal, positive recheck |

**Run38098425773 remains failed overall:** its original RC4 job `114351167444` failed during reference-project setup. The completed independent replay adds the missing evidence without changing the historical conclusion or regenerating a successful bridge.

## What the generated tests cover

Ten valid source fixtures retain high-level do intent, round-trip PS/readable-Lean/PS, and compare canonical admissions after lowering. They include two binds, typed immutable lets, lexical shadowing, wildcard/discard, final action, first-error propagation, identifier hygiene, ASCII bind and string literals. Twenty-one malformed/unsupported cases decline explicitly. Additional checks cover exact commented-source replay, canonical comment-print refusal, BOM/string trivia, parameterless-value semantics, wrong return/error types, input limits and actual generated-runtime behavior.

All38 tests passed on Linux/Node22.23.3 and Windows/Node26.7.0. The ten-fixture stream was accepted by the retained JS kernel, then TypeScript7.0.2 produced executable code whose success/error values were checked. Fixture admissions SHA-256 agreed across platforms: `6f14a42e22bf0e0fb41fbe4af07ada5bcbc82b21776e7f6b40149176d629ddb2`.

The bridge's whole generated admission stream is retained but **not independently kernel-admitted**. Fixture admission does not imply that broader claim.

## Independent RC4 theorem

The replay uses exact generated functions from the successful artifact, not separately handwritten equivalents. The unchanged theorem is:

```lean
theorem pscv0_do_correspondence (a b : Except String Nat) :
    referenceProgram a b = loweredProgram a b := by
  cases a <;> cases b <;> rfl

#print axioms pscv0_do_correspondence
```

Lean4.35.0-rc4 at `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364` returned:

```text
'pscv0_do_correspondence' does not depend on any axioms
```

This establishes equality of that pair of generated functions for **all** their inputs. It is not a general theorem about the translator, every supported program, JavaScript lowering or kernel soundness. The failed symbolic-rfl attempt was resolved by constructor cases; the statement and generated functions were not weakened.

A known-false equation between the successful ground call and an error constructor was rejected by the same reference checker. The original positive proof then passed again. Checked reference-source SHA-256: `26252fe00865f313b64b3b18cb397544c4b390dac65a044c9d05f6049759e8a6`. Unchanged functions+statement SHA-256: `d8f2aa3ab2647569acc6bb2a2127b3d0fb4172dabf02b248c9e964b842af4e95`.

The replay verifies the origin run/source and actual successful bridge/Windows jobs, both exact38-test summaries, all19 source-module hashes and generated TS/JS/admission identities before checking the proof. It never executes downloaded JS. It completed from03:25:55Z to03:26:27Z on2026-10-11, approximately32 seconds including toolchain setup; no prefix rebuild was needed.

## Immutable artifacts

| Artifact | ID | ZIP SHA-256 |
| --- | --- | --- |
| Native4.34 evidence | `11686798545` | `c7aafa3625cf0c04fbadce46fcfa75b9d9a6d4c3591d184e5f9a04610ff87c8b` |
| Generated bridge and Linux evidence | `11686899111` | `ce2fb8315b733ae64aa8515d31eb32b4a5941a941a2119ce433fac5d41037361` |
| Windows evidence | `11686158753` | `a43cf36fae1e1499e5fa68c8fc92bc7dcef94318335fe766a23d773101476fe1` |
| RC4 replay, raw reports, proof and negative-control records | `11691260418` | `bce05b001f8b7e62dda0bc29bb71ea31f3de499157e578ec19744bad9ec4c5b2` |

Bridge JavaScript SHA-256: `1ef9268e2b84aab67e5c122bf860f85957c6b66352d71be5f76bb4354cdfa281`.
Bridge TypeScript SHA-256: `5a27fda9ca051a9bd769da6d678f75b3ae3a54804ea22807c53d24006b7aca7f`.
Retained C0 builder SHA-256: `6cddc3c34c38f1524ef9a355c46b0eb17949c45c54fd59367ea370c1af861ab3`.

## Preserved compiler and kernel boundaries

The original69 compiler source files and the main64-module bootstrap closure remain unchanged. Four new portable modules are added under the existing syntax package; generation covers only their19-module syntax/foundation closure. The unchanged retained self-hosted JavaScript compiler generated this bridge. No native compiler or handwritten JS was substituted for that generation gate.

No full C0/C1/C2/C3 cycle, selected-seed promotion, public CLI switch, kernel rebuild or full source-authority migration occurred. No new npm package/dependency, public ZIP release or main merge was made. The one-language PSCV0 design reference remains the target; unimplemented forms explicitly decline.

## Historical failures — do not erase or misclassify

| Run / source | Actual failure | Coherent correction |
| --- | --- | --- |
| `38094720290` / `7b0b3803062d` | Invalid workflow before code execution | Runner-local prefix set at step execution |
| `38095004877` / `7092ba81c304` | Old C0 rejects expression `::` | Normalize new-source expressions to List.cons; retain supported patterns |
| `38095258615` / `a5932fb84e74` | Missing Foundation.List build prerequisite | Include actual PsFoundation prerequisite |
| `38095425532` / `1f62effe6e86` | Native reserved local names | Rename sourceModule/importPrefix |
| `38095954154` / `6eb1cb5f6e42` | Unqualified Option constructor values | Qualify new-source constructor family |
| `38096114909` / `7f41b6367f40` | Result-type token misclassified as assignment | Explicit declaration-owned type delimiter before shared term parsing |
| `38097055403` / `960692ed256f` | Structural recursive call arity | Preserve full Pi type via supported returned-function form |
| `38097650380` / `9265af40cdce` | Match-valued local lacks expected type | Explicit Bool annotation in new Module source |
| `38098565850` / `01faf55c15d1` | Symbolic rfl alone does not close fixture equality | Same statement proved by exhaustive Except cases |
| `38098425773` reference lane | Reference Lake metadata missing before theorem execution | Complete reference project; independent artifact replay rather than repeating successful generation |

The previous detailed native/prequalification ledger is archived unchanged at [history/PSCV0_BRIDGE_VALIDATION_BEFORE_RC4_REPLAY.md](history/PSCV0_BRIDGE_VALIDATION_BEFORE_RC4_REPLAY.md). Earlier native passes retain their narrower original scope.

## Remaining migration work

The first bridge is complete within its capability contract. Public integration, source-trivia placement, broader inference/projections/updates, complete source conversion and the actual authoritative `.ps` compiler migration remain later steps. A changed bridge requires new generated-source qualification; a reference-only replay verifies hashes and refuses changed code. Never update old self-host baselines merely to make a changed source tree pass.
