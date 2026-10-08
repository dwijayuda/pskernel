# @proofscript/pscv-core — Lean 4 source package

Implementation: [src/Pscv/Core/Model.lean](src/Pscv/Core/Model.lean). Compiler implementation is Lean, not JavaScript.

P0 reuses official Lean Name/Expr/Declaration representation. CoreCandidate contains untrusted candidate declarations and source metadata; it is not CheckedCore, CertifiedSource, or permission to emit code.

Built by Lake target PscvCore with Lean 4.35.0-rc3. This development npm package ships source modules only. Platform-specific compiled native releases come later. Full PSCV source semantics and frontend are not implemented yet.
