# First PSCV0-authored compiler module — validation

## Candidate scope

The actual compiler module `Ps.Syntax.Translate` is selected from `packages/syntax/src-ps/Ps/Syntax/Translate.ps` by `pscv0-authoring.json` for the candidate bridge build. The existing public compiler and its 69 baseline Lean files are not changed. There is no old-PS fallback when the selected source is invalid.

The four translation APIs use the selected PSCV0 base do forms and one pure generic error-mapping helper. Their original signatures, error kinds and first-failure behavior are acceptance requirements. Native proofs compare BOTH generated projections against the original API definitions for every String input; generated JS additionally requires positive/negative correspondence tests. No success is claimed before those gates run.

## Observed first failure

Source `1d578cd6d96b3bd6a3a57ff90c8340a2b47c1870`, run `38110082840`, job `114383654200`: failure before expensive generation. The selected PS source parsed, but the owned native reader could not reread the original printer's `(_ : epsilon) -> PsTranslationError` inside a higher-order parameter type. Error: expected `)` at11:70, got `:`. No retained-compiler preparation or new bridge generation ran.

This is a general source-printer/reader boundary, not a reason to remove the generic helper, relax round-trip checks or change the language reference. The corrected portable PSCV0 type printer renders anonymous explicit Pi as ordinary arrows, preserving named/non-explicit binders. Both readable and lowered declaration headers use that same owner. This does not promise unrestricted dependent type parsing or full formatting.

## Shared-prefix bootstrap strategy

The corrected printer must itself be built by the retained compiler before it can consume the new source. The builder prepares the unchanged syntax prefix once, retaining the pure in-process preparation state just before Translate. It generates a surface bootstrap from predecessor-readable source, uses THAT generated code to read/print/lower Translate.ps, and resumes the same pure prefix with the selected PS-derived module. The rest of the small syntax/foundation closure is compiled again for the candidate. Nothing is deserialized into checking authority; the compiler's existing preparation API is pure.

Native source/round-trip/eight-theorem preflight runs before the expensive prefix. Actual generated projections must match native preflight exactly and then pass the same theorems again. Native outputs are not substituted for generated compiler inputs. Final Linux/Windows runs retain the original38 tests and add authoring and anonymous-arrow regressions. RC4 independently checks the emitted module correspondence and the existing do fixture theorem.

No full compiler or kernel rebuild, full C2/C3, public CLI switch, general comment formatter or new source diagnostic remapping is implied. The selected initial module has no comments; both trivia inventories are checked. General commented-module migration must remain blocked until placement is implemented.
