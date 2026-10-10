import PSCVL.Policy

/-!
P1-F selected concrete dictionary syntheses in the pinned Lean4.35.0-rc3
ambient environment. These are additional witnesses, NOT an approved graph
of PSCV Standard typeclass dependencies or runtime implementations.
-/
set_option autoImplicit false

-- Concrete candidate for normative surface Nat:+
#synth Add Nat

-- Concrete candidate for normative surface Nat:*
#synth Mul Nat

-- Concrete candidate for normative surface Nat:-
#synth Sub Nat

-- Concrete candidate for normative surface Int:+
#synth Add Int

-- Concrete candidate for normative surface Nat:==
#synth DecidableEq Nat

-- Concrete candidate for normative surface Bool:==
#synth DecidableEq Bool

-- Concrete candidate for normative surface String:++
#synth Append String

-- Typecheck concrete goal Nat:+ independently of printed selection.
example : Add Nat := inferInstance

-- Typecheck concrete goal Nat:* independently of printed selection.
example : Mul Nat := inferInstance

-- Typecheck concrete goal Nat:- independently of printed selection.
example : Sub Nat := inferInstance

-- Typecheck concrete goal Int:+ independently of printed selection.
example : Add Int := inferInstance

-- Typecheck concrete goal Nat:== independently of printed selection.
example : DecidableEq Nat := inferInstance

-- Typecheck concrete goal Bool:== independently of printed selection.
example : DecidableEq Bool := inferInstance

-- Typecheck concrete goal String:++ independently of printed selection.
example : Append String := inferInstance
