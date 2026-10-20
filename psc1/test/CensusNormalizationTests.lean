import Ps.Syntax.Ast
import Ps.Erasure.Definition

private def require (label : String) (condition : Bool) : IO Unit := do
  if !condition then throw (IO.userError ("PSC1_CENSUS_NORMALIZATION_FAILED: " ++ label))
  IO.println ("PASS: " ++ label)

private def testPatternNames : IO Unit := do
  let spanA := PsSourceSpan.mk (PsSourcePos.mk 2 1 3) (PsSourcePos.mk 3 1 4)
  let spanB := PsSourceSpan.mk (PsSourcePos.mk 5 1 6) (PsSourcePos.mk 6 1 7)
  let a := PsSyntaxName.mk ["same"] spanA
  let b := PsSyntaxName.mk ["same"] spanB
  let c := PsSyntaxName.mk ["last"] spanA
  let pattern := PsSyntaxBindingPattern.pair
    (.pair (.name a) (.wildcard spanA) spanA)
    (.pair (.unit spanB) (.pair (.name b) (.name c) spanB) spanB) spanA
  let names := psSyntaxBindingPatternNames pattern
  require "nested pattern keeps ordered duplicate names and their spans"
    (names.map (fun name => (name.segments, name.span.start.byteOffset)) ==
      [(["same"], 2), (["same"], 5), (["last"], 2)])
  require "empty and singleton append"
    ((psSyntaxAppendNames [] [a]).length == 1 &&
      (psSyntaxAppendNames [a] []).length == 1)
  let qualified := psSyntaxNamespaceName ["Outer", "Inner"] a
  require "namespace qualification preserves source name and span"
    (qualified.segments == ["Outer", "Inner", "same"] &&
      qualified.span.start.byteOffset == 2 && qualified.span.stop.byteOffset == 3)

private def testScopedDeclaration : IO Unit := do
  let span := PsSourceSpan.mk (PsSourcePos.mk 10 2 1) (PsSourcePos.mk 40 3 1)
  let name := PsSyntaxName.mk ["value"] span
  let term := PsSyntaxTerm.natural "1" span
  let source := PsSyntaxDeclaration.scopedDecl ["Outer"]
    (.scopedDecl ["Inner"] (.definition name [] term term span))
  let qualified := psSyntaxDeclarationQualify ["Root"] source
  require "nested declaration scopes accumulate in order"
    (match qualified with
    | .definition resultName binders _ _ resultSpan =>
        resultName.segments == ["Root", "Outer", "Inner", "value"] &&
        binders.isEmpty && resultSpan.start.byteOffset == 10
    | _ => false)
  require "scoped declaration span is the leaf declaration span"
    ((psSyntaxDeclarationSpan source).stop.byteOffset == 40)
  require "binding pattern size preserves nested structural counts"
    (psSyntaxBindingPatternSize (.pair (.name name) (.pair (.unit span) (.wildcard span) span) span) == 5)

private def testPreludeClosure : IO Unit := do
  let rootName := PsName.str .anonymous "root"
  let aName := PsName.str .anonymous "a"
  let bName := PsName.str .anonymous "b"
  let unusedName := PsName.str .anonymous "unused"
  let metadataName := PsName.str .anonymous "metadata"
  let type := PsExpr.constE psNatName []
  let root := PsDeclaration.definitionDecl rootName [] type (.constE aName [])
  let a := PsDeclaration.definitionDecl aName [] type (.constE bName [])
  let b := PsDeclaration.definitionDecl bName [] type (.lit (.natural 7))
  let unused := PsDeclaration.definitionDecl unusedName [] type (.lit (.natural 99))
  let metadata := PsDeclaration.axiomDecl metadataName [] type
  let candidates := [b, unused, metadata, a]
  let names := fun (declarations : List PsDeclaration) => declarations.map (fun d => psNameToString (psDeclarationName d))
  require "zero fuel returns the exact incoming selection"
    (names (psErasureRuntimePreludeClosure [root] candidates 0 [unused]) == ["unused"])
  require "one step selects direct references and metadata in candidate order"
    (names (psErasureRuntimePreludeClosure [root] candidates 1 []) == ["metadata", "a"])
  require "transitive closure keeps order, metadata and excludes unused definitions"
    (names (psErasureRuntimeDeclarations candidates [root]) == ["b", "metadata", "a", "root"])
  require "fixed selection is unchanged by additional fuel"
    (names (psErasureRuntimePreludeClosure [root] candidates 3 []) ==
      names (psErasureRuntimePreludeClosure [root] candidates 20 []))
  require "empty candidate set keeps roots"
    (names (psErasureRuntimeDeclarations [] [root]) == ["root"])

def main : IO Unit := do
  testPatternNames
  testScopedDeclaration
  testPreludeClosure
  IO.println "PSC1_CENSUS_NORMALIZATION: pattern and runtime closure behavior passed"
