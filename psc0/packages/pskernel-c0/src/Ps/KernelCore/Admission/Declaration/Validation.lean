import Ps.KernelCore.Checker.Session
import Ps.KernelCore.Runtime.Acceleration.CachePolicy

/-
Core declaration validation shared by all admission operations.

This module checks universe-parameter discipline, rejects metavariables/free
variables, validates declaration headers as sorts, and checks definition bodies
against their declared types. It does not mutate the global environment.
-/


def psKernelSafetyEq
    (left : PsKernelDefinitionSafety)
    (right : PsKernelDefinitionSafety) : Bool :=
  match left with
  | PsKernelDefinitionSafety.unsafeDef =>
      match right with
      | PsKernelDefinitionSafety.unsafeDef => true
      | _ => false
  | PsKernelDefinitionSafety.safe =>
      match right with
      | PsKernelDefinitionSafety.safe => true
      | _ => false
  | PsKernelDefinitionSafety.partialDef =>
      match right with
      | PsKernelDefinitionSafety.partialDef => true
      | _ => false

def psKernelNameListsEq
    (left : List PsKernelName) :
    List PsKernelName -> Bool :=
  match left with
  | List.nil =>
      fun (right : List PsKernelName) =>
        match right with
        | List.nil => true
        | List.cons _ _ => false
  | List.cons leftHead leftTail =>
      let smaller :=
        psKernelNameListsEq leftTail;
      fun (right : List PsKernelName) =>
        match right with
        | List.nil =>
            false
        | List.cons rightHead rightTail =>
            if psKernelNameEq leftHead rightHead then
              smaller rightTail
            else
              false

def psKernelFindUndefExprLevelParam
    (expr : PsKernelExpr)
    (allowed : List PsKernelName) :
    Option PsKernelName :=
  match expr with
  | PsKernelExpr.sort level =>
      psKernelFindUndefLevelParam
        level
        allowed
  | PsKernelExpr.const _ levels =>
      psKernelFindUndefInLevels
        levels
        allowed
  | PsKernelExpr.app fn arg =>
      match
          psKernelFindUndefExprLevelParam
            fn
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          psKernelFindUndefExprLevelParam
            arg
            allowed
  | PsKernelExpr.lam _ type body _ =>
      match
          psKernelFindUndefExprLevelParam
            type
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          psKernelFindUndefExprLevelParam
            body
            allowed
  | PsKernelExpr.forallE _ type body _ =>
      match
          psKernelFindUndefExprLevelParam
            type
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          psKernelFindUndefExprLevelParam
            body
            allowed
  | PsKernelExpr.letE _ type value body _ =>
      match
          psKernelFindUndefExprLevelParam
            type
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          match
              psKernelFindUndefExprLevelParam
                value
                allowed with
          | Option.some name =>
              Option.some name
          | Option.none =>
              psKernelFindUndefExprLevelParam
                body
                allowed
  | PsKernelExpr.mdata _ body =>
      psKernelFindUndefExprLevelParam
        body
        allowed
  | PsKernelExpr.proj _ _ body =>
      psKernelFindUndefExprLevelParam
        body
        allowed
  | _ =>
      Option.none

def psKernelLevelHasMVar
    (level : PsKernelLevel) : Bool :=
  match level with
  | PsKernelLevel.mvar _ =>
      true
  | PsKernelLevel.succ inner =>
      psKernelLevelHasMVar inner
  | PsKernelLevel.max left right =>
      if psKernelLevelHasMVar left then
        true
      else
        psKernelLevelHasMVar right
  | PsKernelLevel.imax left right =>
      if psKernelLevelHasMVar left then
        true
      else
        psKernelLevelHasMVar right
  | _ =>
      false

def psKernelLevelsHaveMVar
    (levels : List PsKernelLevel) : Bool :=
  match levels with
  | List.nil =>
      false
  | List.cons head tail =>
      if psKernelLevelHasMVar head then
        true
      else
        psKernelLevelsHaveMVar tail

def psKernelExprHasMVar
    (expr : PsKernelExpr) : Bool :=
  match expr with
  | PsKernelExpr.mvar _ =>
      true
  | PsKernelExpr.sort level =>
      psKernelLevelHasMVar level
  | PsKernelExpr.const _ levels =>
      psKernelLevelsHaveMVar levels
  | PsKernelExpr.app fn arg =>
      if psKernelExprHasMVar fn then
        true
      else
        psKernelExprHasMVar arg
  | PsKernelExpr.lam _ type body _ =>
      if psKernelExprHasMVar type then
        true
      else
        psKernelExprHasMVar body
  | PsKernelExpr.forallE _ type body _ =>
      if psKernelExprHasMVar type then
        true
      else
        psKernelExprHasMVar body
  | PsKernelExpr.letE _ type value body _ =>
      if psKernelExprHasMVar type then
        true
      else if psKernelExprHasMVar value then
        true
      else
        psKernelExprHasMVar body
  | PsKernelExpr.mdata _ body =>
      psKernelExprHasMVar body
  | PsKernelExpr.proj _ _ body =>
      psKernelExprHasMVar body
  | _ =>
      false

/-!
Proof-bearing, per-query DAG-aware metavariable membership. The exact source
algorithm above remains independently available; only the native compiler
gets a proved equal implementation. Ordinary metadata leaves and linear
syntax pay no memo allocation. Every hash collision is checked by equality.
-/

structure PsKernelC0ExactMVar (expr : PsKernelExpr) where
  value : Bool
  source : value = psKernelExprHasMVar expr

structure PsKernelC0MVarMemoEntry where
  expr : PsKernelExpr
  certified : PsKernelC0ExactMVar expr

abbrev PsKernelC0MVarMemo :=
  PsKernelC0HashTrie PsKernelC0MVarMemoEntry

private def psKernelC0MVarMemoFind (expr : PsKernelExpr) :
    List PsKernelC0MVarMemoEntry →
      Option (PsKernelC0ExactMVar expr)
  | [] => none
  | entry :: rest =>
      match withPtrEqDecEq expr entry.expr (fun _ => inferInstance) with
      | .isTrue equal =>
          some (by
            cases equal
            exact entry.certified)
      | .isFalse _ =>
          psKernelC0MVarMemoFind expr rest

private def psKernelC0MVarMemoLookup
    (expr : PsKernelExpr) (memo : PsKernelC0MVarMemo) :
    Option (PsKernelC0ExactMVar expr) :=
  psKernelC0MVarMemoFind expr
    (psKernelC0TrieBucket psKernelC0IndexDepth memo
      (psKernelC0MemoShapeHash 4 expr))

private def psKernelC0MVarMemoStore
    {expr : PsKernelExpr}
    (memo : PsKernelC0MVarMemo)
    (checked : PsKernelC0ExactMVar expr) :
    PsKernelC0ExactMVar expr × PsKernelC0MVarMemo :=
  let hash := psKernelC0MemoShapeHash 4 expr
  let bucket := psKernelC0TrieBucket psKernelC0IndexDepth memo hash
  (checked, psKernelC0TrieSet psKernelC0IndexDepth memo hash
    ({ expr := expr, certified := checked } :: bucket))

/-- One memo per query, never transported across checker or expression states. -/
def psKernelC0MVarMemoGo :
    (expr : PsKernelExpr) → PsKernelC0MVarMemo →
      PsKernelC0ExactMVar expr × PsKernelC0MVarMemo
  | expr, memo =>
      match psKernelC0MVarMemoLookup expr memo with
      | some checked => (checked, memo)
      | none =>
          match expr with
          | .app fn arg =>
              let (f, m1) := psKernelC0MVarMemoGo fn memo
              -- The source predicate short-circuits on the function side.
              -- Do not traverse a potentially enormous argument DAG when
              -- the left child already certifies the presence of an MVar.
              if h : f.value = true then
                let checked : PsKernelC0ExactMVar (.app fn arg) :=
                  ⟨true, by
                    change true =
                      (if psKernelExprHasMVar fn then true
                       else psKernelExprHasMVar arg)
                    rw [← f.source]
                    simp [h]⟩
                psKernelC0MVarMemoStore m1 checked
              else
                let (a, m2) := psKernelC0MVarMemoGo arg m1
                let checked : PsKernelC0ExactMVar (.app fn arg) :=
                  ⟨a.value, by
                    change a.value =
                      (if psKernelExprHasMVar fn then true
                       else psKernelExprHasMVar arg)
                    rw [← f.source, ← a.source]
                    simp [h]⟩
                psKernelC0MVarMemoStore m2 checked
          | .lam name ty body info =>
              let (t, m1) := psKernelC0MVarMemoGo ty memo
              if ht : t.value = true then
                let checked : PsKernelC0ExactMVar (.lam name ty body info) :=
                  ⟨true, by
                    change true =
                      (if psKernelExprHasMVar ty then true
                       else psKernelExprHasMVar body)
                    rw [← t.source]
                    simp [ht]⟩
                psKernelC0MVarMemoStore m1 checked
              else
                let (b, m2) := psKernelC0MVarMemoGo body m1
                let checked : PsKernelC0ExactMVar (.lam name ty body info) :=
                  ⟨b.value, by
                    change b.value =
                      (if psKernelExprHasMVar ty then true
                       else psKernelExprHasMVar body)
                    rw [← t.source, ← b.source]
                    simp [ht]⟩
                psKernelC0MVarMemoStore m2 checked
          | .forallE name ty body info =>
              let (t, m1) := psKernelC0MVarMemoGo ty memo
              if ht : t.value = true then
                let checked : PsKernelC0ExactMVar (.forallE name ty body info) :=
                  ⟨true, by
                    change true =
                      (if psKernelExprHasMVar ty then true
                       else psKernelExprHasMVar body)
                    rw [← t.source]
                    simp [ht]⟩
                psKernelC0MVarMemoStore m1 checked
              else
                let (b, m2) := psKernelC0MVarMemoGo body m1
                let checked : PsKernelC0ExactMVar (.forallE name ty body info) :=
                  ⟨b.value, by
                    change b.value =
                      (if psKernelExprHasMVar ty then true
                       else psKernelExprHasMVar body)
                    rw [← t.source, ← b.source]
                    simp [ht]⟩
                psKernelC0MVarMemoStore m2 checked
          | .letE name ty val body nondep =>
              let (t, m1) := psKernelC0MVarMemoGo ty memo
              if ht : t.value = true then
                let checked : PsKernelC0ExactMVar
                    (.letE name ty val body nondep) :=
                  ⟨true, by
                    change true =
                      (if psKernelExprHasMVar ty then true
                       else if psKernelExprHasMVar val then true
                       else psKernelExprHasMVar body)
                    rw [← t.source]
                    simp [ht]⟩
                psKernelC0MVarMemoStore m1 checked
              else
                let (v, m2) := psKernelC0MVarMemoGo val m1
                if hv : v.value = true then
                  let checked : PsKernelC0ExactMVar
                      (.letE name ty val body nondep) :=
                    ⟨true, by
                      change true =
                        (if psKernelExprHasMVar ty then true
                         else if psKernelExprHasMVar val then true
                         else psKernelExprHasMVar body)
                      rw [← t.source, ← v.source]
                      simp [ht, hv]⟩
                  psKernelC0MVarMemoStore m2 checked
                else
                  let (b, m3) := psKernelC0MVarMemoGo body m2
                  let checked : PsKernelC0ExactMVar
                      (.letE name ty val body nondep) :=
                    ⟨b.value, by
                      change b.value =
                        (if psKernelExprHasMVar ty then true
                         else if psKernelExprHasMVar val then true
                         else psKernelExprHasMVar body)
                      rw [← t.source, ← v.source, ← b.source]
                      simp [ht, hv]⟩
                  psKernelC0MVarMemoStore m3 checked
          | .mdata md body =>
              let (b, m1) := psKernelC0MVarMemoGo body memo
              let checked : PsKernelC0ExactMVar (.mdata md body) :=
                ⟨b.value, by
                  change b.value = psKernelExprHasMVar body
                  exact b.source⟩
              psKernelC0MVarMemoStore m1 checked
          | .proj name i body =>
              let (b, m1) := psKernelC0MVarMemoGo body memo
              let checked : PsKernelC0ExactMVar (.proj name i body) :=
                ⟨b.value, by
                  change b.value = psKernelExprHasMVar body
                  exact b.source⟩
              psKernelC0MVarMemoStore m1 checked
          | .mvar name =>
              psKernelC0MVarMemoStore memo
                (⟨true, rfl⟩ : PsKernelC0ExactMVar (.mvar name))
          | .bvar index =>
              psKernelC0MVarMemoStore memo
                (⟨false, rfl⟩ : PsKernelC0ExactMVar (.bvar index))
          | .fvar name =>
              psKernelC0MVarMemoStore memo
                (⟨false, rfl⟩ : PsKernelC0ExactMVar (.fvar name))
          | .sort level =>
              psKernelC0MVarMemoStore memo
                (⟨psKernelLevelHasMVar level, rfl⟩ :
                  PsKernelC0ExactMVar (.sort level))
          | .const name levels =>
              psKernelC0MVarMemoStore memo
                (⟨psKernelLevelsHaveMVar levels, rfl⟩ :
                  PsKernelC0ExactMVar (.const name levels))
          | .lit literal =>
              psKernelC0MVarMemoStore memo
                (⟨false, rfl⟩ : PsKernelC0ExactMVar (.lit literal))


/-- Shared-DAG metavariable check, certified equal to the original
source-level checking predicate (including universe metavariables). -/
def psKernelC0MemoizedHasMVar (expr : PsKernelExpr) : Bool :=
  (psKernelC0MVarMemoGo expr .empty).1.value

theorem psKernelC0MemoizedHasMVar_source (expr : PsKernelExpr) :
    psKernelC0MemoizedHasMVar expr = psKernelExprHasMVar expr :=
  (psKernelC0MVarMemoGo expr .empty).1.source

/-- Reuse FVar's PURE shape heuristics: neither searches for an FVar nor
introduces any shared source context. The source predicate remains the fast
path for a shallow linear expression; the memo is per-call and immutable. -/
def psKernelC0AdaptiveHasMVar (expr : PsKernelExpr) : Bool :=
  if psKernelC0FVarMemoComplexApp 8 expr ||
      psKernelC0FVarMemoBinderPrefix 12 expr then
    psKernelC0MemoizedHasMVar expr
  else psKernelExprHasMVar expr

theorem psKernelC0AdaptiveHasMVar_source (expr : PsKernelExpr) :
    psKernelC0AdaptiveHasMVar expr = psKernelExprHasMVar expr := by
  unfold psKernelC0AdaptiveHasMVar
  split
  · exact psKernelC0MemoizedHasMVar_source expr
  · rfl

/-- Compiler-only source-equivalent native optimization. No new logical
admission premise, no unsound cross-environment cache and no fuel changes. -/
@[csimp] theorem psKernelExprHasMVar_csimp :
    @psKernelExprHasMVar = @psKernelC0AdaptiveHasMVar := by
  funext expr
  exact (psKernelC0AdaptiveHasMVar_source expr).symm

def psKernelCheckNoMVarNoFVar
    (expr : PsKernelExpr) :
    Except String Unit :=
  -- Directly consume the certified source-equal result. In particular,
  -- do not depend on when the native compiler applies @[csimp] inside
  -- the module that also defines the original recursive predicate.
  if psKernelC0AdaptiveHasMVar expr then
    Except.error
      "declaration has metavariables"
  else if psKernelExprHasFVar expr then
    Except.error
      "declaration has free variables"
  else
    Except.ok ()

/-- All-input exact old declaration-screening result, including error
    precedence and message. This does NOT authorize an unchecked term. -/
theorem psKernelC0CheckNoMVarNoFVar_source (expr : PsKernelExpr) :
    psKernelCheckNoMVarNoFVar expr =
      (if psKernelExprHasMVar expr then
        (Except.error "declaration has metavariables" : Except String Unit)
       else if psKernelExprHasFVar expr then
        Except.error "declaration has free variables"
       else Except.ok ()) := by
  simp only [psKernelCheckNoMVarNoFVar,
    psKernelC0AdaptiveHasMVar_source]

def psKernelCheckLevelParams
    (expr : PsKernelExpr)
    (allowed : List PsKernelName) :
    Except String Unit :=
  match
      psKernelFindUndefExprLevelParam
        expr
        allowed with
  | Option.some _ =>
      Except.error
        "invalid reference to undefined universe level parameter"
  | Option.none =>
      Except.ok ()

def psKernelCheckConstantBaseWithSession
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (base : PsKernelConstantBase) :
    Except String PsKernelCheckerSession :=
  if
      psKernelEnvironmentContains
        session.context.environment
        base.name then
    Except.error "already declared"
  else if
      psKernelNameHasDuplicates
        base.levelParams then
    Except.error
      "duplicate universe parameter"
  else
    match psKernelCheckNoMVarNoFVar base.type with
    | Except.error error =>
        Except.error error
    | Except.ok _ =>
        match
            psKernelCheckLevelParams
              base.type
              base.levelParams with
        | Except.error error =>
            Except.error error
        | Except.ok _ =>
            match
                psKernelSessionCheck
                  fuel
                  session
                  base.type with
            | Except.error error =>
                Except.error error
            | Except.ok typeType =>
                match
                    psKernelSessionEnsureSort
                      fuel
                      (Prod.snd typeType)
                      (Prod.fst typeType) with
                | Except.error error =>
                    Except.error error
                | Except.ok result =>
                    Except.ok
                      (Prod.snd result)

def psKernelCheckDefinitionBodyWithSession
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (value : PsKernelDefinitionInfo) :
    Except String PsKernelCheckerSession :=
  match psKernelCheckNoMVarNoFVar value.value with
  | Except.error error =>
      Except.error error
  | Except.ok _ =>
      match
          psKernelCheckLevelParams
            value.value
            value.base.levelParams with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          match
              psKernelSessionCheck
                fuel
                session
                value.value with
          | Except.error error =>
              Except.error error
          | Except.ok valueType =>
              match
                  psKernelSessionIsDefEq
                    fuel
                    (Prod.snd valueType)
                    (Prod.fst valueType)
                    value.base.type with
              | Except.error error =>
                  Except.error error
              | Except.ok equal =>
                  if Prod.fst equal then
                    Except.ok
                      (Prod.snd equal)
                  else
                    Except.error
                      "definition type mismatch"
