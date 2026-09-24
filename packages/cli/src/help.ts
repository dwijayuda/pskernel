import {LEAN_SEMANTICS_VERSION,PROOFSCRIPT_SPEC_VERSION} from '@proofscript/syntax';

export const PSC_VERSION='0.1.0';

export const HELP=`ProofScript compiler

Usage:
  psc init [dir] [--lib] [-y]
  psc check [entry.ps|entry.psx|entry.lean] [-p, --project <path>] [--verified] [--json]
  psc build [entry.ps|entry.psx|entry.lean] [-p, --project <path>] [--verified] [--json]
  psc run [entry.ps|entry.psx|entry.lean] [-p, --project <path>] [--verified] [--json] [-- <args...>]
  psc translate <entry.ps|entry.psx|entry.lean> --to ps|lean [-p, --project <path>]
  psc emit-lean [entry.ps|entry.psx|entry.lean] [-p, --project <path>]
  psc clean [-p, --project <path>]
  psc --version
  psc --help

Commands:
  init       Create a ProofScript project and psconfig.json
  check      Parse .ps/.psx or supported .lean; JSX semantic lowering is PSX2
  build      Compile the currently supported semantic subset to TS then JS/.d.ts
  run        Build the currently supported semantic subset and invoke main
  translate  Canonically translate supported .ps/.psx/.lean to ps or lean
  emit-lean  Print canonical Lean lowering for the supported reference slice
  clean      Remove the configured output directory

Verified compiler:
  --verified  source -> Lean-compatible elaboration -> pskernel checked core
              -> erasure -> compiler IR -> TypeScript -> JavaScript
  No automatic fallback to the legacy software checker.
  run --verified accepts primitive main parameters directly:
  Nat, Int, Bool, String, Unit.
  Supported structure/ADT parameters use the checked JSON ABI:
  nested Nat/Int are decimal strings; ADTs use {"$ctor":"name",...fields}.

Current language track:
  ProofScript ${PROOFSCRIPT_SPEC_VERSION} with v0.6.1 compiler-ready surface baseline
  Lean semantic target: ${LEAN_SEMANTICS_VERSION}
`;
