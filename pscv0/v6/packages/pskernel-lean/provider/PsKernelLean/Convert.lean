import Lean.Environment
import Ps.Core.Declaration
import PsKernelLean.Error

namespace PsKernelLean

def unsupportedCore (message : String) : PsKernelLeanError :=
  { kind := .unsupportedCoreForm, message := message }

def toLeanName : PsName -> Lean.Name
  | .anonymous => .anonymous
  | .str parent value => .str (toLeanName parent) value
  | .num parent value => .num (toLeanName parent) value

def toLeanLevel : PsLevel -> Except PsKernelLeanError Lean.Level
  | .zero => .ok .zero
  | .succ level => do
      let converted ← toLeanLevel level
      pure (.succ converted)
  | .max left right => do
      let convertedLeft ← toLeanLevel left
      let convertedRight ← toLeanLevel right
      pure (.max convertedLeft convertedRight)
  | .imax left right => do
      let convertedLeft ← toLeanLevel left
      let convertedRight ← toLeanLevel right
      pure (.imax convertedLeft convertedRight)
  | .param name => .ok (.param (toLeanName name))
  | .mvar _ => .error (unsupportedCore "universe metavariable")

def toLeanLevels : List PsLevel -> Except PsKernelLeanError (List Lean.Level)
  | [] => .ok []
  | level :: rest => do
      let converted ← toLeanLevel level
      let convertedRest ← toLeanLevels rest
      pure (converted :: convertedRest)

def toLeanBinderInfo : PsBinderInfo -> Lean.BinderInfo
  | .explicit => .default
  | .implicit => .implicit
  | .strictImplicit => .strictImplicit
  | .instanceImplicit => .instImplicit

def toLeanLiteral : PsLiteral -> Lean.Literal
  | .natural value => .natVal value
  | .string value => .strVal value

partial def toLeanExpr : PsExpr -> Except PsKernelLeanError Lean.Expr
  | .bvar index => .ok (.bvar index)
  | .fvar _ => .error (unsupportedCore "free variable")
  | .mvar _ => .error (unsupportedCore "expression metavariable")
  | .sortE level => do
      let converted ← toLeanLevel level
      pure (.sort converted)
  | .constE name levels => do
      let convertedLevels ← toLeanLevels levels
      pure (.const (toLeanName name) convertedLevels)
  | .app fn arg => do
      let convertedFn ← toLeanExpr fn
      let convertedArg ← toLeanExpr arg
      pure (.app convertedFn convertedArg)
  | .lam name type body binder => do
      let convertedType ← toLeanExpr type
      let convertedBody ← toLeanExpr body
      pure (.lam (toLeanName name) convertedType convertedBody (toLeanBinderInfo binder))
  | .forallE name type body binder => do
      let convertedType ← toLeanExpr type
      let convertedBody ← toLeanExpr body
      pure (.forallE (toLeanName name) convertedType convertedBody (toLeanBinderInfo binder))
  | .letE name type value body => do
      let convertedType ← toLeanExpr type
      let convertedValue ← toLeanExpr value
      let convertedBody ← toLeanExpr body
      pure (.letE (toLeanName name) convertedType convertedValue convertedBody false)
  | .lit literal => .ok (.lit (toLeanLiteral literal))
  | .proj typeName index value => do
      let convertedValue ← toLeanExpr value
      pure (.proj (toLeanName typeName) index convertedValue)

def toLeanNames (names : List PsName) : List Lean.Name :=
  names.map toLeanName

end PsKernelLean
