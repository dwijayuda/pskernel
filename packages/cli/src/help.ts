import {LEAN_SEMANTICS_VERSION,PROOFSCRIPT_SPEC_VERSION} from '@proofscript/syntax';

export const PSC_VERSION='0.1.0';

export const HELP=`ProofScript compiler

Usage:
  psc init [dir] [--lib] [-y]
  psc check [entry.ps] [-p, --project <path>] [--json]
  psc build [entry.ps] [-p, --project <path>] [--json]
  psc run [entry.ps] [-p, --project <path>] [--json] [-- <args...>]
  psc emit-lean [entry.ps] [-p, --project <path>]
  psc clean [-p, --project <path>]
  psc --version
  psc --help

Commands:
  init       Create a ProofScript project and psconfig.json
  check      Parse and type-check without writing build outputs
  build      Check, emit canonical Lean + TypeScript, then let TypeScript emit JS/.d.ts
  run        Build and invoke exported main with arguments after --
  emit-lean  Print canonical Lean lowering for the supported reference slice
  clean      Remove the configured output directory

Current language track:
  ProofScript ${PROOFSCRIPT_SPEC_VERSION} with v0.6.1 compiler-ready surface baseline
  Lean semantic target: ${LEAN_SEMANTICS_VERSION}
`;
