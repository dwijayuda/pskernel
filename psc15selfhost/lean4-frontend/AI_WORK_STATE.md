# Experimental PSCV → Lean 4 frontend work state

Branch: pscv/lean4-native-frontend-experiment
Base: psc2/selfhost-lean-kernel (isolated from pscv/v3-execution)
Status: M0 implementation committed; executable cloud evidence pending.

Scope delivered:
- reuse existing PSC2 .ps → .lean translation CLI rather than duplicate syntax;
- pin Lean 4.35.0-rc3 by exact githash before checks and native codegen;
- check translated modules using Lean itself;
- reject obvious unsafe/partial/axiom/proof-hole source words;
- reserve C source emission for explicit development-unverified mode;
- positive/negative source fixtures and targeted GitHub CI.

Explicitly NOT delivered:
- complete PSCV grammar, contracts, VC closure, import proof trust closure,
  specification coverage, erasure assurance, PSCV-CERT-v1, or certified codegen.

Next: consume CI results, fix adapter-only integration defects if found,
then implement normative PSCV verification lowering behind a separate
capability, without touching PSKernel or v5.1 execution lanes.
