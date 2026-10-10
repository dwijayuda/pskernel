import Ps.KernelCore.Core.AnnotatedEquality
import Ps.KernelCore.Core.AnnotatedSpines

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
  require "simultaneous replacements are not rewritten" (checkedExprEq
    (instManyAt (.bvar 0) 0 [.bvar 0, .fvar (n "x")] 0) (.bvar 0))
  require "simultaneous order" (checkedExprEq
    (instManyAt (.app (.bvar 0) (.bvar 1)) 0 [.fvar (n "x"), .fvar (n "y")] 0)
    (.app (.fvar (n "x")) (.fvar (n "y"))))
  let openBody : AnnotatedExpr := .lam (n "z") (.bvar 1)
    (.app (.bvar 1) (.app (.bvar 2) (.bvar 0))) .default p
  let expected : AnnotatedExpr := .lam (n "z") (.fvar (n "y"))
    (.app (.bvar 1) (.app (.fvar (n "y")) (.bvar 0))) .default p
  require "open replacement lifted under binder" (checkedExprEq
    (instManyAt openBody 0 [.bvar 0, .fvar (n "y")] 0) expected)
  require "indices above substitution descend" (checkedExprEq
    (instManyAt (.bvar 4) 0 [a, b] 0) (.bvar 2))
  require "nonzero start and depth" (checkedExprEq
    (instManyAt (.app (.bvar 1) (.app (.bvar 3) (.bvar 5))) 1 [.bvar 0] 2)
    (.app (.bvar 1) (.app (.bvar 2) (.bvar 4))))
  require "reverse binder order" (checkedExprEq
    (instantiateRev (.app (.bvar 1) (.bvar 0)) [.fvar (n "x"), .fvar (n "y")])
    (.app (.fvar (n "x")) (.fvar (n "y"))))
  require "argument order retained" (checkedExprEq
    (applyArgs (.fvar (n "f")) [a, b])
    (.app (.app (.fvar (n "f")) a) b))
  let spine : AnnotatedExpr := .lam (n "x") dom
    (.lam (n "y") dom (.bvar 1) .default q) .default p
  let bounded : AnnotatedExpr × Nat := consumeLambdas 1 spine 2 0
  require "lambda-spine fuel bound" (bounded.2 == 1 && checkedExprEq bounded.1
    (.lam (n "y") dom (.bvar 1) .default q))
  let exhausted : AnnotatedExpr × Nat := consumeLambdas 5 spine 1 0
  require "lambda-spine argument bound" (exhausted.2 == 1 && checkedExprEq exhausted.1
    (.lam (n "y") dom (.bvar 1) .default q))
  IO.println "PSKERNEL_ANNOTATED_SYNTAX: PASS cases=21 modelImports=0"
