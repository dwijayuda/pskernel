import Ps.KernelCore.Core.AnnotatedExpr
import Ps.KernelCore.Core.UniverseRegime

/-!
Structural comparison of annotated syntax. Binder annotations are compared by
their uniform zero condition; ordinary sorts still use full syntactic level
equality. This operation has no inference fallback. The existing raw checker
is not yet migrated to annotated syntax.
-/
namespace PsKernelSemantics.AnnotatedExpr

def checkRegimes : AnnotatedExpr → AnnotatedExpr → Bool
  | .lam _ A b _ v, .lam _ A' b' _ v'
  | .forallE _ A b _ v, .forallE _ A' b' _ v' =>
      UniverseRegime.check v v' && (checkRegimes A A' && checkRegimes b b')
  | .app f a, .app f' a' => checkRegimes f f' && checkRegimes a a'
  | .letE _ A a b _, .letE _ A' a' b' _ =>
      checkRegimes A A' && (checkRegimes a a' && checkRegimes b b')
  | .mdata _ e, .mdata _ e' | .proj _ _ e, .proj _ _ e' => checkRegimes e e'
  | _, _ => true

/-- The raw comparison checks shape and payloads. The additional
guard checks binder annotation information. -/
def checkedExprEq (a b : AnnotatedExpr) : Bool :=
  psKernelExprEq a.erase b.erase && checkRegimes a b


end PsKernelSemantics.AnnotatedExpr
