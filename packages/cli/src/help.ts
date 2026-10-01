import {LEAN_SEMANTICS_VERSION,PROOFSCRIPT_SPEC_VERSION} from '@proofscript/syntax';

export const PSC_VERSION='0.1.0';

export const HELP=`ProofScript compiler

Usage:
  psc init [dir] [--lib] [-y]
  psc check [entry.ps|entry.lean] [-p, --project <path>] [--json]
  psc build [entry.ps|entry.lean] [-p, --project <path>] [--json]
  psc run [entry.ps|entry.lean] [-p, --project <path>] [--json] [-- <args...>]
  psc translate <entry.ps|entry.lean> --to ps|lean [-p, --project <path>]
  psc emit-lean [entry.ps|entry.lean] [-p, --project <path>]
  psc clean [-p, --project <path>]
  psc --version
  psc --help

Commands:
  init       Create a ProofScript project and psconfig.json
  check      Parse .ps or supported .lean and check through pskernel
  build      Checked core -> verified IR -> TypeScript -> JS/.d.ts
  run        Build through the checked-core path and invoke exported main
  translate  Canonically translate supported .ps/.lean to ps or lean
  emit-lean  Print canonical Lean lowering for the supported reference slice
  clean      Remove the configured output directory

Compiler pipeline:
  source -> Lean-compatible elaboration -> pskernel checked core
         -> erasure -> verified compiler IR -> TypeScript -> JavaScript

  There is no legacy software checker or automatic fallback. The historical
  --verified flag is accepted only as a deprecated compatibility marker and
  does not select a different semantic path.

  run accepts primitive main parameters directly:
  Nat, Int, Bool, String, Unit.
  Supported structure/ADT parameters use the checked JSON ABI:
  nested Nat/Int are decimal strings; ADTs use {"$ctor":"name",...fields}.

Current language track:
  ProofScript ${PROOFSCRIPT_SPEC_VERSION} with v0.6.1 compiler-ready surface baseline
  Lean semantic target: ${LEAN_SEMANTICS_VERSION}
`;
