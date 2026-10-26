import Lean
import Ps.KernelCore.API.DagNestedOverlay

private def nm (s : String) := PsKernelName.str .anonymous s
private def s1 := PsKernelExpr.sort (.succ .zero)
private def empty := PsKernelDagGeneratedState.mk psKernelExprV2PagedEmpty psKernelExprV2DecodedEmpty []
private def force {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)
private def require (label : String) (condition : Bool) : IO Unit := do
  unless condition do throw (IO.userError ("overlay regression: " ++ label))
  IO.println ("PSC1_NESTED_OVERLAY_ASSERT " ++ label)
private def entrySame (a b : PsKernelExprV2Entry) : Bool :=
  psKernelExprV2NestedOverlayNodeSame a.node b.node && a.hash == b.hash &&
    a.looseRange == b.looseRange && a.hasFVar == b.hasFVar &&
    a.hasExprMVar == b.hasExprMVar && a.depth == b.depth
private def prefixStable (beforeOwner afterOwner : PsKernelDagGeneratedState) : IO Bool := do
  let mut stable := beforeOwner.arena.size ≤ afterOwner.arena.size && beforeOwner.built.size ≤ afterOwner.built.size
  for id in List.range beforeOwner.arena.size do
    let a ← force (psKernelExprV2PagedRequire beforeOwner.arena id)
    let b ← force (psKernelExprV2PagedRequire afterOwner.arena id)
    let x ← force (psKernelExprV2DecodedRequire beforeOwner.built id)
    let y ← force (psKernelExprV2DecodedRequire afterOwner.built id)
    stable := stable && entrySame a b && psKernelExprEqual x y
  pure stable
private def errorText {α : Type} : Except String α → String
  | .error error => error
  | .ok _ => "unexpected success"

def main : IO Unit := do
  let n := nm "OverlayOrigin"
  let forms : List (String × PsKernelExpr) := [
    ("bvar",.bvar 1000000000000000000),("fvar",.fvar n),("mvar",.mvar n),
    ("sort",s1),("const",.const n [.zero,.succ .zero]),
    ("app",.app s1 (.bvar 0)),("lam",.lam n s1 (.bvar 0) .default),
    ("forall",.forallE n s1 (.bvar 0) .default),
    ("let",.letE n s1 (.bvar 0) (.bvar 0) false),
    ("literal",.lit (.str "Aé€😀")),("metadata",.mdata 7 (.bvar 0)),
    ("projection",.proj n 0 (.bvar 0))]
  for (label,source) in forms do
    let before ← force (psKernelDagGeneratedImport source empty)
    let after ← force (psKernelExprV2NestedOverlay source before.snd before.fst)
    require (label ++ "-same-root") (after.snd == before.snd)
    require (label ++ "-zero-node-growth") (after.fst.arena.size == before.fst.arena.size && after.fst.built.size == before.fst.built.size)
    let decoded ← force (psKernelExprV2DecodedRequire after.fst.built after.snd)
    require (label ++ "-canonical-source-and-prefix") (psKernelExprEqual decoded source && (← prefixStable before.fst after.fst))
  let spines : List (String × PsKernelExpr × PsKernelExpr) := [
    ("app",.app s1 (.bvar 0),.app s1 (.bvar 1)),
    ("lam",.lam n s1 (.bvar 0) .default,.lam n s1 (.bvar 1) .default),
    ("forall",.forallE n s1 (.bvar 0) .default,.forallE n s1 (.bvar 1) .default),
    ("let",.letE n s1 (.bvar 0) (.bvar 0) false,.letE n s1 (.bvar 0) (.bvar 1) false),
    ("metadata",.mdata 7 (.bvar 0),.mdata 7 (.bvar 1)),
    ("projection",.proj n 0 (.bvar 0),.proj n 0 (.bvar 1))]
  for (label,source,target) in spines do
    let before ← force (psKernelDagGeneratedImport source empty)
    let after ← force (psKernelExprV2NestedOverlay target before.snd before.fst)
    require (label ++ "-only-new-leaf-and-parent") (after.fst.arena.size == before.fst.arena.size+2 && after.fst.built.size == after.fst.arena.size)
    require (label ++ "-old-ids-and-all-metadata-retained") (← prefixStable before.fst after.fst)
    let decoded ← force (psKernelExprV2DecodedRequire after.fst.built after.snd)
    require (label ++ "-changed-canonical-exact") (psKernelExprEqual decoded target)
  let payloads : List (String × PsKernelExpr × PsKernelExpr) := [
    ("binder-name",.lam n s1 (.bvar 0) .default,.lam (nm "Renamed") s1 (.bvar 0) .default),
    ("binder-info",.forallE n s1 (.bvar 0) .default,.forallE n s1 (.bvar 0) .implicit),
    ("let-nondep",.letE n s1 (.bvar 0) (.bvar 0) false,.letE n s1 (.bvar 0) (.bvar 0) true)]
  for (label,source,target) in payloads do
    let before ← force (psKernelDagGeneratedImport source empty)
    let after ← force (psKernelExprV2NestedOverlay target before.snd before.fst)
    require (label ++ "-all-children-reused") (after.fst.arena.size == before.fst.arena.size+1 && (← prefixStable before.fst after.fst))
    let decoded ← force (psKernelExprV2DecodedRequire after.fst.built after.snd)
    require (label ++ "-new-payload-exact") (psKernelExprEqual decoded target)
  let before ← force (psKernelDagGeneratedImport (.bvar 0) empty)
  let badRoot := before.fst.built.size
  require "missing-original-decoded-error-first"
    (errorText (psKernelExprV2NestedOverlay (.app s1 s1) badRoot before.fst) == errorText (psKernelExprV2DecodedRequire before.fst.built badRoot))
  let stale := { before.fst with built := psKernelExprV2DecodedEmpty }
  require "stale-decoded-continuation-rejected"
    (errorText (psKernelExprV2NestedOverlay (.bvar 0) 0 stale) == errorText (psKernelExprV2DecodedRequire stale.built 0))
  let absent := { before.fst with arena := psKernelExprV2PagedEmpty }
  require "missing-original-arena-error-preserved"
    (errorText (psKernelExprV2NestedOverlay (.bvar 0) 0 absent) == errorText (psKernelExprV2PagedRequire absent.arena 0))
  let target := PsKernelExpr.app s1 (.bvar 1)
  let after ← force (psKernelExprV2NestedOverlay target before.snd before.fst)
  let originalImport ← force (psKernelDagGeneratedImport target before.fst)
  require "changed-kind-original-generated-size-and-root"
    (after.snd == originalImport.snd && after.fst.arena.size == originalImport.fst.arena.size)
  require "changed-kind-prefix-metadata-retained" (← prefixStable before.fst after.fst)
  let decoded ← force (psKernelExprV2DecodedRequire after.fst.built after.snd)
  require "changed-kind-canonical-exact" (psKernelExprEqual decoded target)
  let header ← force (psKernelDagGeneratedImport s1 empty)
  let declaration := PsKernelExprV2DeclarationRef.mk n [] header.snd none .axiomDecl
  let owned := { header.fst with declarations := [declaration] }
  let keeps := fun (owner : PsKernelDagGeneratedState) => match owner.declarations with
    | [entry] => psKernelNameEq entry.name n && entry.type == header.snd && entry.deltaValue.isNone &&
        (match entry.kind with | .axiomDecl => true | _ => false)
    | _ => false
  let sameOwner ← force (psKernelExprV2NestedOverlay s1 header.snd owned)
  require "unchanged-owner-retains-declaration-prefix" (keeps sameOwner.fst)
  let changedOwner ← force (psKernelExprV2NestedOverlay (.mdata 7 s1) header.snd owned)
  require "changed-owner-retains-declaration-prefix" (keeps changedOwner.fst)
  IO.println "PSC1_NESTED_OVERLAY_NATIVE: PASS controls=68 unchanged=36 spines=18 payloads=6 malformed=3 changedKind=3 declarationPrefix=2 privateOnly=true publicRouteChanged=false"
