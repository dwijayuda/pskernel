# Prepared declarations and replay validation

A performance sample of the interrupted generated compiler replay spent its
admission phase in `psStringEqFromWithFuel`. It compared two separately encoded,
multi-megabyte canonical strings character by character, repeatedly looking up
UTF-8 views by string equality. The previous compiler runs produced no completed
checked-emission or fixed-point result; their snapshots and logs remain preserved.

`PsCompilerAdmissionReadyModule` now contains only declarations. Preparation
validates that they can be encoded. Each admission request encodes those exact
declarations directly; environment reconstruction validates codec support and
uses the same declarations. There is no cached payload that can disagree with
the declarations, and no long character-by-character comparison in this path.

This representation is not a checked capability. The production JavaScript host
still freezes the whole prepared graph before invoking the selected checker,
keeps its accepted object behind a session-local WeakMap handle, re-encodes and
compares the accepted payload before emission, and emits from that same graph.
Native Lean sessions retain the same immutable value and compare the actual
accepted bytes before emission. Invalid encodings, invalid terms, changed bytes,
forged handles and kernel rejection remain covered by tests. No check is replaced
with an acceptance flag or alternate provider.

The single-field record literal initially produced `unsupportedTerm` when PSC
compiled its own preparation function. An explicit constructor fixes that source
subset issue. The failed snapshot/log is preserved separately from the successful
retry. Focused guards require the constructor, declarations-only representation,
fresh encoding and unchanged checked-host gate.

Validation executed:

- Native compiler, minimal self-host tests, product tests and replay audit build.
- Native minimal/product tests and replay behavior/parser checks pass.
- Nine native checked-seed cases pass, including codec-invalid declarations,
  codec-valid ill-typed declarations, nested recursors and exact emission.
- 30 JavaScript checked-build, prepared-session and seed-session tests pass.
- Source guards, 72-module closure, three-root minimality and 14 source-isolation
  cases pass. PSC checks the compiler API's 1,800-declaration dependency closure.
- An actual 72-module build with the explicit Lean WASM reference provider passes
  in 66,065 ms. Source closure:
  `38fec582939f5b0e02a15d6f479efbae6d5d5e90f44faa9b294ce29586f29ac3`.
  Native seed:
  `8d527c8557867f1eaadef2a5b6a4cd0ea795b807b2df7501f2a24a4dfdde1d22`.
  Admissions:
  `b995916150ae010f36af0c13d4aafaf590fb4eddcf6b512cf9c80920863faed4`.
  TypeScript:
  `bb79d8a39be9a879ba18d3ede2f567dd32f3c17fd056974a368058063bafed93`.
  JavaScript:
  `7fef852ddb121af7867809118743015f88564d9a3a5e991b55660352536e705d`.

The generated reference compiler replay of that exact snapshot has started in a
new output directory. Its fixed-point result is pending. The owned default still
rejects `PsSourcePos` because Nat/prelude and constructor-field semantics are not
implemented. The owned generated kernel is in the source closure; the current
reference provider is external. No genuine joint owned self-hosting or release
readiness is claimed by this checkpoint.
