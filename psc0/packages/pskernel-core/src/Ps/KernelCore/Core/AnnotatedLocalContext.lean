import Ps.KernelCore.Core.LocalContext
import Ps.KernelCore.Core.AnnotatedExpr

/-!
Annotated and raw contexts use exactly the same storage, lookup and extension
operations. Erasure preserves all non-expression fields. The selected readings
still need provenance and semantic validity from the checker.
-/
namespace PsKernelSemantics

abbrev AnnotatedLocalDecl := PsKernelLocalDeclOf AnnotatedExpr
abbrev AnnotatedLocalContext := PsKernelLocalContextOf AnnotatedExpr

def annotatedLocalContextEmpty : AnnotatedLocalContext :=
  psKernelLocalContextEmptyOf AnnotatedExpr

def eraseLocalDecl (decl : AnnotatedLocalDecl) : PsKernelLocalDecl :=
  psKernelLocalDeclMap AnnotatedExpr.erase decl

def eraseLocalContext (context : AnnotatedLocalContext) : PsKernelLocalContext :=
  psKernelLocalContextMap AnnotatedExpr.erase context

end PsKernelSemantics
