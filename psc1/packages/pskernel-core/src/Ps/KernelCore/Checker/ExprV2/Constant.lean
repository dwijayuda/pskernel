import Ps.KernelCore.Checker.Inference.Constant
import Ps.KernelCore.Checker.ExprV2.Environment
import Ps.KernelCore.Core.ExprV2.Transform

/-
Infer a constant type from source IDs retained by successful same-batch
admission. The live environment first applies exactly the complete checker's
lookup, universe-arity and safety rules. Missing or inconsistent source
ownership requests whole-operation fallback. No legacy type is imported.
-/
def psKernelExprV2TryInferConstantType
    (context : PsKernelCheckerContext) (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef)
    (name : PsKernelName) (levels : List PsKernelLevel) (inferOnly : Bool) :
    Option (Except String (Prod PsKernelExprV2PagedArena Nat)) :=
  match psKernelCheckConstantReference context name levels inferOnly with
  | Except.error error => Option.some (Except.error error)
  | Except.ok info =>
      match psKernelExprV2DeclarationRefFind declarations name with
      | Option.none => Option.none
      | Option.some declaration =>
          if psKernelExprV2DeclarationRefMatches declaration info then
            Option.some
              (psKernelExprV2TransformOnCanonical
                (PsKernelExprV2Transform.levels declaration.levelParams levels)
                arena declaration.type 0)
          else Option.none
