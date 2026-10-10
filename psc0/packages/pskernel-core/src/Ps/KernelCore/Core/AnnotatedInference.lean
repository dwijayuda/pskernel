import Ps.KernelCore.Core.AnnotatedExpr
import Ps.KernelCore.Core.InferenceBoundary

/-!
Carried inference and exposed-function syntax. These records do not grant
acceptance or certify supplied annotations; companion proofs must establish
their provenance and semantic validity from actual executions.
-/
namespace PsKernelSemantics

abbrev AnnotatedInferenceResult := PsKernelInferenceResultOf AnnotatedExpr

/-- Includes the carried range-sort annotation of the exposed product. -/
structure AnnotatedForallView extends PsKernelForallViewOf AnnotatedExpr where
  rangeSort : PsKernelLevel

def eraseInferenceResult (result : AnnotatedInferenceResult) :
    PsKernelInferenceResultOf PsKernelExpr :=
  psKernelInferenceResultMap AnnotatedExpr.erase result

/-- Projection matching the existing public check/infer result type. -/
def eraseInferenceType (result : AnnotatedInferenceResult) : PsKernelExpr :=
  result.type.erase

def eraseForallView (view : AnnotatedForallView) : PsKernelForallView :=
  psKernelForallViewMap AnnotatedExpr.erase view.toPsKernelForallViewOf

/-- Reconstruction retains the chosen tag verbatim. -/
def annotatedForallViewExpr (view : AnnotatedForallView) : AnnotatedExpr :=
  AnnotatedExpr.forallE view.name view.domain view.body view.binderInfo view.rangeSort

/-- A syntax view only: this does not validate the supplied annotation. -/
def annotatedForallView? (expr : AnnotatedExpr) : Option AnnotatedForallView :=
  match expr with
  | AnnotatedExpr.forallE name domain body binderInfo rangeSort =>
      Option.some {
        name := name
        domain := domain
        body := body
        binderInfo := binderInfo
        rangeSort := rangeSort
      }
  | _ => Option.none

/-- Both bodies are already closed. The caller supplies the range sort obtained
at its codomain-sort visit; no default annotation is introduced here. -/
def annotatedLambdaResult
    (name : PsKernelName) (domain body bodyType : AnnotatedExpr)
    (binderInfo : PsKernelBinderInfo) (rangeSort : PsKernelLevel) :
    AnnotatedInferenceResult :=
  {
    expr := AnnotatedExpr.lam name domain body binderInfo rangeSort
    type := AnnotatedExpr.forallE name domain bodyType binderInfo rangeSort
  }

/-- Syntax construction only. Argument typing and domain equality remain
obligations of the checking branch using this constructor. -/
def annotatedApplicationResult
    (fn arg : AnnotatedInferenceResult) (view : AnnotatedForallView) :
    AnnotatedInferenceResult :=
  {
    expr := AnnotatedExpr.app fn.expr arg.expr
    type := AnnotatedExpr.inst arg.expr view.body 0
  }

end PsKernelSemantics
