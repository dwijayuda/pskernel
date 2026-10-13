/-
Native authoring audit for selected Standard dependencies; never imported by
the portable compiler. Traversal follows Lean 4.35.0 CollectAxioms.lean's
visited-before-descending invariant, extended to recursor rule RHSs and mutual
families. This reports dependencies, not admission or equivalence.
-/
import Ps.Host.PrimitiveAudit
import Lean.Util.CollectAxioms

namespace PsV7Native

private def closureDependencies (info : Lean.ConstantInfo) : Array Lean.Name :=
  let expressions := info.type.getUsedConstants ++
    ((info.value? true).map Lean.Expr.getUsedConstants).getD #[]
  let family := match info with
    | .inductInfo v => v.all.toArray ++ v.ctors.toArray
    | .ctorInfo v => #[v.induct]
    | .recInfo v => v.all.toArray ++
        (v.rules.toArray.flatMap fun rule => #[rule.ctor] ++ rule.rhs.getUsedConstants)
    | _ => #[]
  expressions ++ family

private def closureKind : Lean.ConstantInfo → String
  | .axiomInfo _ => "axiom"
  | .defnInfo _ => "definition"
  | .thmInfo _ => "theorem"
  | .opaqueInfo _ => "opaque"
  | .quotInfo _ => "quotient-primitive"
  | .inductInfo _ => "inductive"
  | .ctorInfo _ => "constructor"
  | .recInfo _ => "recursor"

-- Worklist with a visited set handles inductive/constructor/recursor cycles
-- without imposing the compiler's elaboration resource policy on this audit.
private def closure (environment : Lean.Environment) (root : Lean.Name) :
    IO (Array Lean.ConstantInfo) := do
  let mut pending := [root]
  let mut seen : Lean.NameSet := {}
  let mut entries := #[]
  while !pending.isEmpty do
    let name := pending.head!
    pending := pending.tail!
    if !seen.contains name then
      seen := seen.insert name
      let some info := environment.checked.get.find? name
        | throw (IO.userError ("missing upstream closure declaration: " ++ toString name))
      entries := entries.push info
      pending := (closureDependencies info).toList ++ pending
  return entries.qsort (fun a b => Lean.Name.lt a.name b.name)

def standardClosureAudit : IO Lean.Json := do
  Lean.initSearchPath (← Lean.findSysroot)
  let native ← Lean.importModules #[{ module := `Init }] {}
  let roots := [`Nat.mod_lt, `BitVec.ofNat, `UInt64.ofNat, `UInt64.xor,
    `mixHash, `String.hash, `Float, `Float.ofScientific]
  let portableNames := psSelfHostProdPreludeEnvironment.declarations.foldl
    (fun (names : Lean.NameSet) d => names.insert (PsKernelLean.toLeanName (psDeclarationName d))) {}
  let reports ← roots.mapM fun root => do
    let entries ← closure native root
    let summarize := fun (info : Lean.ConstantInfo) => Lean.Json.mkObj [
      ("name", Lean.toJson (toString info.name)),
      ("kind", Lean.toJson (closureKind info)),
      ("existingPortableName", Lean.toJson (portableNames.contains info.name))]
    pure (Lean.Json.mkObj [
      ("root", Lean.toJson (toString root)),
      ("count", Lean.toJson entries.size),
      ("axioms", Lean.toJson ((entries.filter Lean.ConstantInfo.isAxiom).map (fun x => toString x.name))),
      ("entries", .arr (entries.map summarize))])
  return Lean.Json.mkObj [
    ("schema", Lean.toJson ("pscv0-standard-dependency-audit/1" : String)),
    ("leanCommit", Lean.toJson Lean.githash),
    ("limitation", Lean.toJson ("Read-only upstream closure. Existing names are collision boundaries, not compatible imports. No declarations are admitted, no proof bodies replaced by axioms, and no runtime equivalence is asserted." : String)),
    ("roots", Lean.toJson reports)]

end PsV7Native
