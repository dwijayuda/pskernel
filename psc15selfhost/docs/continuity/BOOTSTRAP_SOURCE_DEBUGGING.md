# Debugging the portable compiler source gate

`npm run bootstrap:check` first builds the Lean-hosted compiler and then asks
that compiler to elaborate the portable compiler source closure. A successful
Lean build or `check:source:bootstrap` profile audit does not establish that the
second stage passes. Read the final `PSC1_PROJECT_ELAB_FAILED` diagnostic.

## Names available to the bootstrap compiler

Portable source may use only names supplied by the bootstrap prelude and its
source imports. Lean accepting a standard-library function does not make that
function available to PSC1. Prefer an explicit source implementation in the
existing subset over extending the prelude just to compile the compiler.

In particular, `List.append` is unavailable in this closure. The source stdlib
provides `listAppend`; it does not define Lean's namespaced `List.append`.
The match elaborator now uses `psElabListAppend`, an explicit structural worker
that preserves left-to-right element order and requires no new imports.

An unavailable dotted name can produce `unsupportedTerm`: the elaborator falls
back from global-name resolution to structure-field projection. Therefore this
error does not by itself prove that the surrounding syntax is unsupported.
Inspect the referenced globals as well as projections and syntax.

## Localize without changing semantics

Keep error ordering, metadata checks, context threading, and recursor argument
ordering intact. Extract one semantic phase, rerun the real source checker, and
use the named failing declaration to select the next change. Do not accumulate
unverified syntax substitutions or weaken checking.

`psElabMatchRecursorLevels` isolates universe selection and its arity rejection.
`psElabMatchBuildRecursor` isolates motive creation and argument assembly. This
split localized the old `psElabMatch: unsupportedTerm` failure to the two
unavailable append calls. The existing dual-source match regression checks the
constructor-branch order and the final scrutinee argument.

## Reusable host executable

The branch bootstrap verifier retains the Lean-built `psc1` executable for one
day, named with its exact source commit. It can run `psc1 check` on a local source
tree when the local Lean toolchain is unavailable. Record both the executable
commit and the checked source changes. This is a diagnostic convenience: CI
must still rebuild the changed source and run the regression and bootstrap
gates. A retained executable is not a self-hosted compiler or fixed-point proof.

## Trust boundary

These portability changes remain in the elaborator and host verification tools.
Phase 13 remains a non-authoritative KernelCore shadow provider. The source gate
passing would not alone establish fixed-point self-hosting, authoritative
CheckedCore admission, or Phase 13 acceptance.
