import Ps.KernelCore.Core.Expr

/-!
Single native source of proof-constrained, full structural DecidableEq
instances for kernel expression syntax.

The original certified-store transport and independently certified
hash/instantiation memo all need the SAME constructor equality witnesses.
Defining them in two modules makes it impossible to combine their
interfaces in one verified checker: the Lean environment rejects duplicate
declarations.

The constructors, representation, source semantics and generated decision
procedures are unchanged. Pointer equality can be used only through Lean's
proof-producing withPtrEqDecEq, never as an unchecked equality judgment.
-/

deriving instance DecidableEq for PsKernelName
deriving instance DecidableEq for PsKernelLevel
deriving instance DecidableEq for PsKernelBinderInfo
deriving instance DecidableEq for PsKernelLiteral
deriving instance DecidableEq for PsKernelExpr
