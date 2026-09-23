import {LEAN_SEMANTICS_VERSION,PROOFSCRIPT_SPEC_VERSION} from '@proofscript/syntax';

export const PSC_VERSION='0.1.0';

export const HELP=`ProofScript compiler

Usage:
  psc init [dir] [--lib] [-y]
  psc check [entry.ps|entry.lean] [-p, --project <path>] [--verified] [--json]
  psc build [entry.ps|entry.lean] [-p, --project <path>] [--verified] [--target js|wasm] [--json]
  psc run [entry.ps|entry.lean] [-p, --project <path>] [--verified] [--json] [-- <args...>]
  psc translate <entry.ps|entry.lean> --to ps|lean [-p, --project <path>]
  psc emit-lean [entry.ps|entry.lean] [-p, --project <path>]
  psc clean [-p, --project <path>]
  psc --version
  psc --help

Commands:
  init       Create a ProofScript project and psconfig.json
  check      Parse .ps or supported .lean and type-check without outputs
  build      Compile .ps or supported .lean to JS, or verified W1 WebAssembly
  run        Build .ps or supported .lean and invoke exported main
  translate  Canonically translate supported .ps/.lean to ps or lean
  emit-lean  Print canonical Lean lowering for the supported reference slice
  clean      Remove the configured output directory

Verified compiler:
  --verified  source -> Lean-compatible elaboration -> pskernel checked core
              -> erasure -> compiler IR -> TypeScript -> JavaScript
  --target wasm branches after verified compiler IR:
              -> Wasm lowering -> typed WasmIR -> Binaryen -> .wasm/.wat
  W1 Wasm currently supports Bool/Unit first-order runtime code only.
  Nat/Int/String/structures/ADTs/generics/closures/FFI fail closed.
  No automatic fallback to the legacy software checker.
  run --verified accepts primitive main parameters directly:
  Nat, Int, Bool, String, Unit.
  Supported structure/ADT parameters use the checked JSON ABI:
  nested Nat/Int are decimal strings; ADTs use {"$ctor":"name",...fields}.

Current language track:
  ProofScript ${PROOFSCRIPT_SPEC_VERSION} with v0.6.1 compiler-ready surface baseline
  Lean semantic target: ${LEAN_SEMANTICS_VERSION}
`;
