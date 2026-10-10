import Ps.KernelCore.Core.AnnotatedEquality

/-! Native checks of the same syntax/guards imported by the semantic model.
No semantic theorem or Con Leche module is linked by this test. -/
open PsKernelSemantics PsKernelSemantics.AnnotatedExpr

private def n (s : String) : PsKernelName := .str .anonymous s

private def require (label : String) (value : Bool) : IO Unit :=
  unless value do throw (IO.userError ("annotation syntax: " ++ label))

def main : IO Unit := do
  let p : PsKernelLevel := .param (n "u")
  let q : PsKernelLevel := .param (n "v")
  let dom : AnnotatedExpr := .sort (.succ .zero)
  let a : AnnotatedExpr := .lam (n "x") dom (.bvar 0) .default (.max p q)
  let b : AnnotatedExpr := .lam (n "y") dom (.bvar 0) .implicit (.max q p)
  require "binder display fields and symbolic regime" (checkedExprEq a b)
  require "Prop versus Type annotation" (!checkedExprEq
    (.lam (n "x") dom (.bvar 0) .default .zero)
    (.lam (n "x") dom (.bvar 0) .default (.succ .zero)))
  require "sort levels remain distinct" (!checkedExprEq (.sort (.succ .zero))
    (.sort (.succ (.succ .zero))))
  require "parameter and metavariable are distinct" (!UniverseRegime.check p (.mvar (n "u")))
  let body : AnnotatedExpr := .forallE (n "t") dom
    (.mdata 7 (.app (.bvar 1) (.bvar 0))) .default (.imax q p)
  require "substitution under binder" (checkedExprEq (inst a body 0) (inst b body 0))
  require "lifting" (checkedExprEq (liftN 3 a 0) (liftN 3 b 0))
  let af : AnnotatedExpr := .app a (.fvar (n "z"))
  let bf : AnnotatedExpr := .app b (.fvar (n "z"))
  require "closing" (checkedExprEq (close (n "z") af 0) (close (n "z") bf 0))
  require "universe instantiation" (checkedExprEq
    (instLevels [n "u", n "v"] [.zero, .succ .zero] a)
    (instLevels [n "u", n "v"] [.zero, .succ .zero] b))
  require "metadata retained" (!checkedExprEq (.mdata 1 a) (.mdata 2 b))
  require "let nondependency flag retained" (!checkedExprEq
    (.letE (n "x") dom a (.bvar 0) false)
    (.letE (n "y") dom b (.bvar 0) true))
  require "projection index retained" (!checkedExprEq
    (.proj (n "S") 0 a) (.proj (n "S") 1 b))
  require "constant universe levels retained" (!checkedExprEq
    (.const (n "c") [.succ .zero]) (.const (n "c") [.succ (.succ .zero)]))
  IO.println "PSKERNEL_ANNOTATED_SYNTAX: PASS cases=12 modelImports=0"
