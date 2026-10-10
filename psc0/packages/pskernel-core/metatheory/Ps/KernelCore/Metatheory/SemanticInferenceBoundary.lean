import Ps.KernelCore.Core.AnnotatedInference
import Ps.KernelCore.Metatheory.SemanticErasure

/-!
Exact erasure of carried inference data and function views. These equations
connect the annotated representation to the existing raw operations without
claiming that callers have checked the annotations or typing premises.
-/
namespace PsKernelSemantics
open AnnotatedExpr

theorem eraseInferenceResult_expr (result : AnnotatedInferenceResult) :
    (eraseInferenceResult result).expr = result.expr.erase := rfl

theorem eraseInferenceResult_type (result : AnnotatedInferenceResult) :
    (eraseInferenceResult result).type = eraseInferenceType result := rfl

theorem eraseForallView_domain (view : AnnotatedForallView) :
    (eraseForallView view).domain = view.domain.erase := rfl

theorem eraseForallView_body (view : AnnotatedForallView) :
    (eraseForallView view).body = view.body.erase := rfl

theorem erase_annotatedForallViewExpr (view : AnnotatedForallView) :
    (annotatedForallViewExpr view).erase =
      .forallE view.name (eraseForallView view).domain
        (eraseForallView view).body view.binderInfo := rfl

theorem annotatedForallView_roundtrip (view : AnnotatedForallView) :
    annotatedForallView? (annotatedForallViewExpr view) = some view := by
  cases view with
  | mk base range =>
      cases base
      rfl

theorem annotatedForallView_source (expr : AnnotatedExpr) (view : AnnotatedForallView)
    (found : annotatedForallView? expr = some view) :
    annotatedForallViewExpr view = expr := by
  cases expr <;> simp only [annotatedForallView?, Option.some.injEq, reduceCtorEq] at found
  cases found
  rfl

theorem erase_annotatedLambdaResult
    (name : PsKernelName) (domain body bodyType : AnnotatedExpr)
    (binderInfo : PsKernelBinderInfo) (rangeSort : PsKernelLevel) :
    eraseInferenceResult (annotatedLambdaResult name domain body bodyType binderInfo rangeSort) =
      { expr := .lam name domain.erase body.erase binderInfo,
        type := .forallE name domain.erase bodyType.erase binderInfo } := rfl

theorem erase_annotatedApplicationResult_expr
    (fn arg : AnnotatedInferenceResult) (view : AnnotatedForallView) :
    (annotatedApplicationResult fn arg view).expr.erase =
      .app fn.expr.erase arg.expr.erase := rfl

theorem erase_annotatedApplicationResult_type
    (fn arg : AnnotatedInferenceResult) (view : AnnotatedForallView) :
    eraseInferenceType (annotatedApplicationResult fn arg view) =
      psKernelExprInstantiate1 (eraseForallView view).body arg.expr.erase := by
  exact erase_instantiate1 view.body arg.expr

end PsKernelSemantics
