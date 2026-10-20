import Init.Data.Nat.Basic
import Lean.Elab.Tactic.Omega
import Ps.KernelCore.Core.ExprV2.Node
import Ps.KernelCore.Research.ExprV2Validation

/-!
Conditional local metadata preservation for actual production entry builders.
Arbitrary child entries must correspond to the recursive expression oracle.
These are not whole-arena, substitution, DefEq, admission or soundness proofs.
Native proof material is outside the portable executable source closure.
-/
namespace PsKernelExprV2MetadataProofs

structure Corresponds
    (entry : PsKernelExprV2Entry) (expr : PsKernelExpr) : Prop where
  hash : entry.hash = psKernelExprHash expr
  looseRange : entry.looseRange = psKernelExprV2LegacyLooseRange expr
  hasFVar : entry.hasFVar = psKernelExprHasFVar expr
  hasExprMVar : entry.hasExprMVar = psKernelExprV2LegacyHasMVar expr
  depth : entry.depth = psKernelExprV2LegacyDepth expr

theorem natMax_eq (left right : Nat) :
    psKernelExprV2NatMax left right = Nat.max left right := by
  simp only [psKernelExprV2NatMax, Nat.ble_eq, Nat.max_def]

theorem boolOr_eq (left right : Bool) :
    psKernelExprV2BoolOr left right = (left || right) := by
  cases left <;> rfl

theorem boolOr_three (first second third : Bool) :
    psKernelExprV2BoolOr (psKernelExprV2BoolOr first second) third =
      (if first then true else if second then true else third) := by
  cases first <;> rfl

theorem app_preserves
    (fn arg : Nat)
    (f a : PsKernelExprV2Entry) (fe ae : PsKernelExpr)
    (hf : Corresponds f fe) (ha : Corresponds a ae) :
    Corresponds (psKernelExprV2AppEntry fn arg f a)
      (PsKernelExpr.app fe ae) := by
  constructor
  · simp only [psKernelExprV2AppEntry, psKernelExprHash, hf.hash, ha.hash]
  · simp only [psKernelExprV2AppEntry, psKernelExprV2LegacyLooseRange, hf.looseRange, ha.looseRange, natMax_eq]
  · simp only [psKernelExprV2AppEntry, psKernelExprHasFVar, hf.hasFVar, ha.hasFVar, psKernelExprV2BoolOr]
  · simp only [psKernelExprV2AppEntry, psKernelExprV2LegacyHasMVar, hf.hasExprMVar, ha.hasExprMVar, boolOr_eq]
  · simp only [psKernelExprV2AppEntry, psKernelExprV2LegacyDepth, hf.depth, ha.depth, natMax_eq]

theorem lam_preserves
    (name : PsKernelName) (type body : Nat) (info : PsKernelBinderInfo)
    (t b : PsKernelExprV2Entry) (te be : PsKernelExpr)
    (ht : Corresponds t te) (hb : Corresponds b be) :
    Corresponds (psKernelExprV2LamEntry name type body info t b)
      (PsKernelExpr.lam name te be info) := by
  constructor
  · simp only [psKernelExprV2LamEntry, psKernelExprHash, ht.hash, hb.hash]
  · simp only [psKernelExprV2LamEntry, psKernelExprV2LegacyLooseRange, ht.looseRange, hb.looseRange, natMax_eq]
  · simp only [psKernelExprV2LamEntry, psKernelExprHasFVar, ht.hasFVar, hb.hasFVar, psKernelExprV2BoolOr]
  · simp only [psKernelExprV2LamEntry, psKernelExprV2LegacyHasMVar, ht.hasExprMVar, hb.hasExprMVar, boolOr_eq]
  · simp only [psKernelExprV2LamEntry, psKernelExprV2LegacyDepth, ht.depth, hb.depth, natMax_eq]

theorem forall_preserves
    (name : PsKernelName) (type body : Nat) (info : PsKernelBinderInfo)
    (t b : PsKernelExprV2Entry) (te be : PsKernelExpr)
    (ht : Corresponds t te) (hb : Corresponds b be) :
    Corresponds (psKernelExprV2ForallEntry name type body info t b)
      (PsKernelExpr.forallE name te be info) := by
  constructor
  · simp only [psKernelExprV2ForallEntry, psKernelExprHash, ht.hash, hb.hash]
  · simp only [psKernelExprV2ForallEntry, psKernelExprV2LegacyLooseRange, ht.looseRange, hb.looseRange, natMax_eq]
  · simp only [psKernelExprV2ForallEntry, psKernelExprHasFVar, ht.hasFVar, hb.hasFVar, psKernelExprV2BoolOr]
  · simp only [psKernelExprV2ForallEntry, psKernelExprV2LegacyHasMVar, ht.hasExprMVar, hb.hasExprMVar, boolOr_eq]
  · simp only [psKernelExprV2ForallEntry, psKernelExprV2LegacyDepth, ht.depth, hb.depth, natMax_eq]

theorem let_preserves
    (name : PsKernelName) (type value body : Nat) (nondep : Bool)
    (t v b : PsKernelExprV2Entry) (te ve be : PsKernelExpr)
    (ht : Corresponds t te) (hv : Corresponds v ve) (hb : Corresponds b be) :
    Corresponds (psKernelExprV2LetEntry name type value body nondep t v b)
      (PsKernelExpr.letE name te ve be nondep) := by
  constructor
  · simp only [psKernelExprV2LetEntry, psKernelExprHash, ht.hash, hv.hash, hb.hash]
  · simp only [psKernelExprV2LetEntry, psKernelExprV2LegacyLooseRange, ht.looseRange, hv.looseRange, hb.looseRange, natMax_eq]
  · simp only [psKernelExprV2LetEntry, psKernelExprHasFVar, ht.hasFVar, hv.hasFVar, hb.hasFVar, boolOr_three]
  · simp only [psKernelExprV2LetEntry, psKernelExprV2LegacyHasMVar, ht.hasExprMVar, hv.hasExprMVar, hb.hasExprMVar, boolOr_eq, Bool.or_assoc]
  · simp only [psKernelExprV2LetEntry, psKernelExprV2LegacyDepth, ht.depth, hv.depth, hb.depth, natMax_eq]

theorem mdata_preserves
    (metadata body : Nat) (b : PsKernelExprV2Entry) (be : PsKernelExpr)
    (hb : Corresponds b be) :
    Corresponds (psKernelExprV2MDataEntry metadata body b)
      (PsKernelExpr.mdata metadata be) := by
  constructor
  · simp only [psKernelExprV2MDataEntry, psKernelExprHash, hb.hash]
  · simp only [psKernelExprV2MDataEntry, psKernelExprV2LegacyLooseRange, hb.looseRange]
  · simp only [psKernelExprV2MDataEntry, psKernelExprHasFVar, hb.hasFVar]
  · simp only [psKernelExprV2MDataEntry, psKernelExprV2LegacyHasMVar, hb.hasExprMVar]
  · simp only [psKernelExprV2MDataEntry, psKernelExprV2LegacyDepth, hb.depth]

theorem proj_preserves
    (name : PsKernelName) (index body : Nat)
    (b : PsKernelExprV2Entry) (be : PsKernelExpr) (hb : Corresponds b be) :
    Corresponds (psKernelExprV2ProjEntry name index body b)
      (PsKernelExpr.proj name index be) := by
  constructor
  · simp only [psKernelExprV2ProjEntry, psKernelExprHash, hb.hash]
  · simp only [psKernelExprV2ProjEntry, psKernelExprV2LegacyLooseRange, hb.looseRange]
  · simp only [psKernelExprV2ProjEntry, psKernelExprHasFVar, hb.hasFVar]
  · simp only [psKernelExprV2ProjEntry, psKernelExprV2LegacyHasMVar, hb.hasExprMVar]
  · simp only [psKernelExprV2ProjEntry, psKernelExprV2LegacyDepth, hb.depth]

theorem legacy_depth_le_count (expr : PsKernelExpr) :
    psKernelExprV2LegacyDepth expr ≤ psKernelExprNodeCount expr := by
  induction expr <;>
    simp_all [psKernelExprV2LegacyDepth, psKernelExprNodeCount] <;> omega

theorem legacy_default_budget_caps_to_depth (expr : PsKernelExpr) :
    (if Nat.ble (Nat.succ (psKernelExprNodeCount expr)) (psKernelExprV2LegacyDepth expr)
      then Nat.succ (psKernelExprNodeCount expr) else psKernelExprV2LegacyDepth expr) =
    psKernelExprV2LegacyDepth expr := by
  have bound := legacy_depth_le_count expr
  have beyond : ¬ Nat.succ (psKernelExprNodeCount expr) ≤ psKernelExprV2LegacyDepth expr := by omega
  simp only [Nat.ble_eq, beyond, if_false]

end PsKernelExprV2MetadataProofs

#print axioms PsKernelExprV2MetadataProofs.app_preserves
#print axioms PsKernelExprV2MetadataProofs.lam_preserves
#print axioms PsKernelExprV2MetadataProofs.forall_preserves
#print axioms PsKernelExprV2MetadataProofs.let_preserves
#print axioms PsKernelExprV2MetadataProofs.mdata_preserves
#print axioms PsKernelExprV2MetadataProofs.proj_preserves

#print axioms PsKernelExprV2MetadataProofs.legacy_depth_le_count
#print axioms PsKernelExprV2MetadataProofs.legacy_default_budget_caps_to_depth
