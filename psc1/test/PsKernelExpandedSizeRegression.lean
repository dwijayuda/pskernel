import Ps.KernelCore.Core.ExprV2.ExpandedSize
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)
private def require (label : String) (ok : Bool) : IO Unit := do
  unless ok do throw (IO.userError ("PSC1_EXPANDED_SIZE_FAIL " ++ label))
  IO.println ("PSC1_EXPANDED_SIZE_ASSERT " ++ label)
private def nm (s : String) := PsKernelName.str .anonymous s

private def smallMatrix : IO Unit := do
  let atom := PsKernelExpr.const (nm "atom") []
  let sort := PsKernelExpr.sort .zero
  let terms := [PsKernelExpr.bvar 0,.fvar (nm "x"),.mvar (nm "m"),sort,atom,
    .app atom atom,.lam (nm "x") sort (.bvar 0) .default,
    .forallE (nm "x") sort (.bvar 0) .implicit,
    .letE (nm "x") sort sort (.bvar 0) false,
    .lit (.nat 123),.lit (.str "Aé€😀"),.mdata 13 atom,.proj (nm "Struct") 1 atom,
    .app (.mdata 1 atom) (.app atom atom),
    .letE (nm "x") (.app atom atom) (.mdata 2 atom) (.app (.bvar 0) atom) true,
    .forallE (nm "x") atom (.lam (nm "y") atom (.app (.bvar 0) (.bvar 1)) .strictImplicit) .default,
    .const (nm "levels") [.param (nm "u"),.max .zero (.succ .zero)],
    .sort (.max (.param (nm "u")) (.succ (.param (nm "v"))))]
  for (term,index) in terms.zipIdx do
    let (arena,root) ← expect (psKernelExprV2PagedImportIntoChecked psKernelExprV2PagedEmpty term)
    let actual ← expect (psKernelExprV2ExpandedSizeOnCanonical arena root)
    require ("all-shapes-exact-count-" ++ toString index) (actual == psKernelExprNodeCount term)

private def sharingMatrix : IO Unit := do
  for depth in [0,1,5,20,100] do
    let (initial,leaf) ← expect (psKernelExprV2PagedMkSort psKernelExprV2PagedEmpty .zero)
    let mut arena := initial
    let mut root := leaf
    for _ in [:depth] do
      let (next,id) ← expect (psKernelExprV2PagedMkApp arena root root)
      arena := next
      root := id
    let entry ← expect (psKernelExprV2PagedRequire arena root)
    let result ← expect (psKernelExprV2ExpandedSizeWithFuel (Nat.succ entry.depth) arena root [])
    let actual ← expect (psKernelExprV2ExpandedSizeOnCanonical arena root)
    -- The depth100 DAG has101nodes but its expanded tree has2^101-1 nodes.
    -- Never construct or recursively count that expanded reference tree.
    let expected := 2^(depth+1)-1
    require ("shared-diamond-" ++ toString depth)
      (actual == expected && result.snd == expected && result.fst.length == depth+1 && arena.size == depth+1)

def main : IO Unit := do
  smallMatrix
  sharingMatrix
  let fake := [PsKernelExprV2SizeMemo.mk 0 777]
  require "zero-budget-precedes-even-a-memo-hit"
    (match psKernelExprV2ExpandedSizeWithFuel 0 psKernelExprV2PagedEmpty 0 fake with
     | .error error => error == "PSKERNEL_V2_EXPANDED_SIZE_FUEL"
     | _ => false)
  require "public-canonical-entry-never-accepts-private-memo"
    (match psKernelExprV2ExpandedSizeWithFuel 1 psKernelExprV2PagedEmpty 0 fake,
        psKernelExprV2ExpandedSizeOnCanonical psKernelExprV2PagedEmpty 0 with
     | .ok pair,.error _ => pair.snd == 777 && pair.fst.length == 1
     | _,_ => false)
  require "missing-root-is-hard-error"
    (match psKernelExprV2ExpandedSizeOnCanonical psKernelExprV2PagedEmpty 10 with
     | .error _ => true
     | _ => false)
  IO.println "PSC1_EXPANDED_SIZE_NATIVE: PASS assertions=26 shapes=18 sharing=5 boundaries=3"
