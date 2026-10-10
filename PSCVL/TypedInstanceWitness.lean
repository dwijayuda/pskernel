import PSCVL.Policy

/-!
P1-E: seven typeclass witnesses from the actual pinned Lean 4.35.0-rc3
imported environment. This file is NOT the closed PSCV Standard and cannot
authorize any runtime lowering, certificate, or executable publication.
-/
set_option autoImplicit false

-- Normative row Nat:+: observational imported-environment synthesis
#synth HAdd Nat Nat Nat

-- Normative row Nat:*: observational imported-environment synthesis
#synth HMul Nat Nat Nat

-- Normative row Nat:-: observational imported-environment synthesis
#synth HSub Nat Nat Nat

-- Normative row Int:+: observational imported-environment synthesis
#synth HAdd Int Int Int

-- Normative row String:++: observational imported-environment synthesis
#synth Append String

-- Normative row Nat:==: observational imported-environment synthesis
#synth BEq Nat

-- Normative row Bool:==: observational imported-environment synthesis
#synth BEq Bool

-- Independent Lean type checking of inhabitance, not PSCV source fidelity.
example : HAdd Nat Nat Nat := inferInstance

-- Independent Lean type checking of inhabitance, not PSCV source fidelity.
example : HMul Nat Nat Nat := inferInstance

-- Independent Lean type checking of inhabitance, not PSCV source fidelity.
example : HSub Nat Nat Nat := inferInstance

-- Independent Lean type checking of inhabitance, not PSCV source fidelity.
example : HAdd Int Int Int := inferInstance

-- Independent Lean type checking of inhabitance, not PSCV source fidelity.
example : Append String := inferInstance

-- Independent Lean type checking of inhabitance, not PSCV source fidelity.
example : BEq Nat := inferInstance

-- Independent Lean type checking of inhabitance, not PSCV source fidelity.
example : BEq Bool := inferInstance
