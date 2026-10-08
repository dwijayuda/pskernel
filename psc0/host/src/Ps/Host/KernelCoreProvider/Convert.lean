import Ps.KernelCore.API.Kernel
import Ps.Core.Declaration
import Ps.Host.KernelCoreProvider.Error

namespace PsKernelCoreProvider

def unsupportedCore (message : String) : PsKernelCoreProviderError :=
  { kind := .unsupportedCoreForm, message := message }

def toCoreName : PsName -> PsKernelName
  | .anonymous => .anonymous
  | .str parent value => .str (toCoreName parent) value
  | .num parent value => .num (toCoreName parent) value

def toCoreLevel : PsLevel -> Except PsKernelCoreProviderError PsKernelLevel
  | .zero => .ok .zero
  | .succ level => do
      let converted ← toCoreLevel level
      pure (.succ converted)
  | .max left right => do
      let convertedLeft ← toCoreLevel left
      let convertedRight ← toCoreLevel right
      pure (.max convertedLeft convertedRight)
  | .imax left right => do
      let convertedLeft ← toCoreLevel left
      let convertedRight ← toCoreLevel right
      pure (.imax convertedLeft convertedRight)
  | .param name => .ok (.param (toCoreName name))
  | .mvar _ => .error (unsupportedCore "universe metavariable")

def toCoreLevels : List PsLevel -> Except PsKernelCoreProviderError (List PsKernelLevel)
  | [] => .ok []
  | level :: rest => do
      let converted ← toCoreLevel level
      let convertedRest ← toCoreLevels rest
      pure (converted :: convertedRest)

def toCoreBinderInfo : PsBinderInfo -> PsKernelBinderInfo
  | .explicit => .default
  | .implicit => .implicit
  | .strictImplicit => .strictImplicit
  | .instanceImplicit => .instImplicit

def toCoreLiteral : PsLiteral -> PsKernelLiteral
  | .natural value => .nat value
  | .string value => .str value

def toCoreExpr : PsExpr -> Except PsKernelCoreProviderError PsKernelExpr
  | .bvar index => .ok (.bvar index)
  | .fvar _ => .error (unsupportedCore "free variable")
  | .mvar _ => .error (unsupportedCore "expression metavariable")
  | .sortE level => do
      let converted ← toCoreLevel level
      pure (.sort converted)
  | .constE name levels => do
      let convertedLevels ← toCoreLevels levels
      pure (.const (toCoreName name) convertedLevels)
  | .app fn arg => do
      let convertedFn ← toCoreExpr fn
      let convertedArg ← toCoreExpr arg
      pure (.app convertedFn convertedArg)
  | .lam name type body binder => do
      let convertedType ← toCoreExpr type
      let convertedBody ← toCoreExpr body
      pure (.lam (toCoreName name) convertedType convertedBody (toCoreBinderInfo binder))
  | .forallE name type body binder => do
      let convertedType ← toCoreExpr type
      let convertedBody ← toCoreExpr body
      pure (.forallE (toCoreName name) convertedType convertedBody (toCoreBinderInfo binder))
  | .letE name type value body => do
      let convertedType ← toCoreExpr type
      let convertedValue ← toCoreExpr value
      let convertedBody ← toCoreExpr body
      pure (.letE (toCoreName name) convertedType convertedValue convertedBody false)
  | .lit literal => .ok (.lit (toCoreLiteral literal))
  | .proj typeName index value => do
      let convertedValue ← toCoreExpr value
      pure (.proj (toCoreName typeName) index convertedValue)

def toCoreNames (names : List PsName) : List PsKernelName :=
  names.map toCoreName

end PsKernelCoreProvider
