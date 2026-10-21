import Lean
import Ps.KernelCore.API.DagAdmission
import Ps.KernelCore.Research.ExprV2Validation

/-!
Local obligations for DAG admission guards. These prove exact index behavior,
flag meaning, error precedence and conditional integration. They do not prove
the complete memoized DAG traversal or the arena replay theorem globally.
The latter obligations remain separate from finite native/generated tests.
-/
namespace PsKernelExprV2AdmissionGuardProofs

private def referenceGuard (expr : PsKernelExpr) (allowed : List PsKernelName) :
    Except String Unit :=
  match psKernelCheckNoMVarNoFVar expr with
  | .error error => .error error
  | .ok _ => psKernelCheckLevelParams expr allowed

theorem id_member_exact (id : Nat) (ids : List Nat) :
    psKernelExprV2AdmissionIdMember id ids = true ↔ id ∈ ids := by
  induction ids with
  | nil => simp [psKernelExprV2AdmissionIdMember]
  | cons first rest ih =>
      simp [psKernelExprV2AdmissionIdMember, Nat.beq_eq, ih]

theorem bucket_set_same (fuel : Nat) (seen : PsKernelExprV2AdmissionSeen)
    (key : Nat) (ids : List Nat) :
    psKernelExprV2AdmissionSeenBucket fuel
      (psKernelExprV2AdmissionSeenSet fuel seen key ids) key = ids := by
  induction fuel generalizing seen key with
  | zero => rfl
  | succ remaining ih =>
      simp only [psKernelExprV2AdmissionSeenSet]
      split <;> simp_all [psKernelExprV2AdmissionSeenBucket]

theorem inserted_id_is_found (seen : PsKernelExprV2AdmissionSeen) (id : Nat) :
    psKernelExprV2AdmissionSeenContains
      (psKernelExprV2AdmissionSeenInsert seen id) id = true := by
  simp [psKernelExprV2AdmissionSeenContains, psKernelExprV2AdmissionSeenInsert,
    bucket_set_same, psKernelExprV2AdmissionIdMember]

theorem hit_requires_exact_id (seen : PsKernelExprV2AdmissionSeen) (id : Nat) :
    psKernelExprV2AdmissionSeenContains seen id = true ↔
      id ∈ psKernelExprV2AdmissionSeenBucket 16 seen id := by
  exact id_member_exact id (psKernelExprV2AdmissionSeenBucket 16 seen id)

theorem empty_owner_has_no_hits (id : Nat) :
    psKernelExprV2AdmissionSeenContains PsKernelExprV2AdmissionSeen.empty id = false := by
  rfl

theorem first_undef_kept (name : PsKernelName) (next : Option PsKernelName) :
    psKernelExprV2AdmissionFirstUndef (.some name) next = .some name := by
  rfl

theorem first_undef_from_next (next : Option PsKernelName) :
    psKernelExprV2AdmissionFirstUndef .none next = next := by
  rfl

private theorem bool_if_or (left right : Bool) :
    (if left then true else right) = (left || right) := by
  cases left <;> rfl

theorem expression_mvar_implies_full_mvar (expr : PsKernelExpr) :
    psKernelExprV2LegacyHasMVar expr = true → psKernelExprHasMVar expr = true := by
  induction expr with
  | bvar index => simp [psKernelExprV2LegacyHasMVar]
  | fvar name => simp [psKernelExprV2LegacyHasMVar]
  | mvar name => simp [psKernelExprHasMVar]
  | sort level => simp [psKernelExprV2LegacyHasMVar]
  | const name levels => simp [psKernelExprV2LegacyHasMVar]
  | app fn arg ihfn iharg =>
      simp only [psKernelExprV2LegacyHasMVar, psKernelExprHasMVar,
        bool_if_or, Bool.or_eq_true]
      intro found
      rcases found with first | second
      · exact Or.inl (ihfn first)
      · exact Or.inr (iharg second)
  | lam name type body info ihtype ihbody =>
      simp only [psKernelExprV2LegacyHasMVar, psKernelExprHasMVar,
        bool_if_or, Bool.or_eq_true]
      intro found
      rcases found with first | second
      · exact Or.inl (ihtype first)
      · exact Or.inr (ihbody second)
  | forallE name type body info ihtype ihbody =>
      simp only [psKernelExprV2LegacyHasMVar, psKernelExprHasMVar,
        bool_if_or, Bool.or_eq_true]
      intro found
      rcases found with first | second
      · exact Or.inl (ihtype first)
      · exact Or.inr (ihbody second)
  | letE name type value body nondep ihtype ihvalue ihbody =>
      simp only [psKernelExprV2LegacyHasMVar, psKernelExprHasMVar,
        bool_if_or, Bool.or_eq_true]
      intro found
      rcases found with (first | second) | third
      · exact Or.inl (ihtype first)
      · exact Or.inr (Or.inl (ihvalue second))
      · exact Or.inr (Or.inr (ihbody third))
  | lit value => simp [psKernelExprV2LegacyHasMVar]
  | mdata tag body ih =>
      simpa only [psKernelExprV2LegacyHasMVar, psKernelExprHasMVar] using ih
  | proj name index body ih =>
      simpa only [psKernelExprV2LegacyHasMVar, psKernelExprHasMVar] using ih

theorem sort_universe_mvar_precedes_param
    (level : PsKernelLevel) (allowed : List PsKernelName)
    (hasMVar : psKernelLevelHasMVar level = true) :
    psKernelExprV2AdmissionNodeLevels (.sort level) allowed =
      .error "declaration has metavariables" := by
  simp [psKernelExprV2AdmissionNodeLevels, hasMVar]

theorem constant_universe_mvar_precedes_param
    (name : PsKernelName) (levels : List PsKernelLevel) (allowed : List PsKernelName)
    (hasMVar : psKernelLevelsHaveMVar levels = true) :
    psKernelExprV2AdmissionNodeLevels (.const name levels) allowed =
      .error "declaration has metavariables" := by
  simp [psKernelExprV2AdmissionNodeLevels, hasMVar]

theorem free_variable_precedes_undefined_param (undefinedParam : Option PsKernelName) :
    psKernelExprV2AdmissionStaticFinish true undefinedParam =
      .error "declaration has free variables" := by
  rfl

theorem finish_matches_reference
    (expr : PsKernelExpr) (allowed : List PsKernelName)
    (noMVar : psKernelExprHasMVar expr = false) :
    psKernelExprV2AdmissionStaticFinish (psKernelExprHasFVar expr)
      (psKernelFindUndefExprLevelParam expr allowed) = referenceGuard expr allowed := by
  cases hf : psKernelExprHasFVar expr <;>
    cases hu : psKernelFindUndefExprLevelParam expr allowed <;>
    simp [psKernelExprV2AdmissionStaticFinish, referenceGuard,
      psKernelCheckNoMVarNoFVar, psKernelCheckLevelParams, noMVar, hf, hu]

theorem scan_zero_precedes_memo
    (arena : PsKernelExprV2PagedArena) (allowed : List PsKernelName)
    (seen : PsKernelExprV2AdmissionSeen) (root : Nat) (first : Option PsKernelName) :
    psKernelExprV2AdmissionScanWithFuel 0 arena allowed seen root first =
      .error "PSKERNEL_V2_ADMISSION_GUARD_FUEL" := by
  rfl

theorem validated_root_expression_mvar
    (arena : PsKernelExprV2PagedArena) (root : Nat) (allowed : List PsKernelName)
    (entry : PsKernelExprV2Entry)
    (lookup : psKernelExprV2PagedRequire arena root = .ok entry)
    (found : entry.hasExprMVar = true) :
    psKernelExprV2AdmissionStaticOnCanonical arena root allowed =
      .error "declaration has metavariables" := by
  simp [psKernelExprV2AdmissionStaticOnCanonical, lookup, found]

theorem canonical_guard_matches_reference_conditionally
    (arena : PsKernelExprV2PagedArena) (root : Nat) (allowed : List PsKernelName)
    (entry : PsKernelExprV2Entry) (expr : PsKernelExpr)
    (seen : PsKernelExprV2AdmissionSeen)
    (lookup : psKernelExprV2PagedRequire arena root = .ok entry)
    (noExprMVar : entry.hasExprMVar = false)
    (noMVar : psKernelExprHasMVar expr = false)
    (fvarCorresponds : entry.hasFVar = psKernelExprHasFVar expr)
    (scan : psKernelExprV2AdmissionScanWithFuel (Nat.succ entry.depth)
      arena allowed .empty root .none =
        .ok (Prod.mk seen (psKernelFindUndefExprLevelParam expr allowed))) :
    psKernelExprV2AdmissionStaticOnCanonical arena root allowed =
      referenceGuard expr allowed := by
  simp only [psKernelExprV2AdmissionStaticOnCanonical, lookup, noExprMVar]
  simp only [Bool.false_eq_true, ite_false, scan]
  rw [fvarCorresponds]
  exact finish_matches_reference expr allowed noMVar

theorem checked_boundary_preserves_validation_error
    (source : PsKernelExprV2PagedArena) (root : Nat) (allowed : List PsKernelName)
    (error : String) (invalid : psKernelExprV2PagedValidate source = .error error) :
    psKernelExprV2AdmissionStaticChecked source root allowed = .error error := by
  simp [psKernelExprV2AdmissionStaticChecked, invalid]

theorem header_existing_name_precedes_arena
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (base : PsKernelConstantBase) (root : Nat)
    (exists : psKernelEnvironmentContains context.scalar.environment base.name = true) :
    psKernelExprV2AdmissionCheckHeaderWithFuel fuel context state base root =
      .some (.error "already declared") := by
  simp [psKernelExprV2AdmissionCheckHeaderWithFuel, exists]

theorem header_duplicate_params_precedes_arena
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (base : PsKernelConstantBase) (root : Nat)
    (fresh : psKernelEnvironmentContains context.scalar.environment base.name = false)
    (duplicates : psKernelNameHasDuplicates base.levelParams = true) :
    psKernelExprV2AdmissionCheckHeaderWithFuel fuel context state base root =
      .some (.error "duplicate universe parameter") := by
  simp [psKernelExprV2AdmissionCheckHeaderWithFuel, fresh, duplicates]

end PsKernelExprV2AdmissionGuardProofs

#print axioms PsKernelExprV2AdmissionGuardProofs.id_member_exact
#print axioms PsKernelExprV2AdmissionGuardProofs.bucket_set_same
#print axioms PsKernelExprV2AdmissionGuardProofs.inserted_id_is_found
#print axioms PsKernelExprV2AdmissionGuardProofs.hit_requires_exact_id
#print axioms PsKernelExprV2AdmissionGuardProofs.empty_owner_has_no_hits
#print axioms PsKernelExprV2AdmissionGuardProofs.first_undef_kept
#print axioms PsKernelExprV2AdmissionGuardProofs.first_undef_from_next
#print axioms PsKernelExprV2AdmissionGuardProofs.expression_mvar_implies_full_mvar
#print axioms PsKernelExprV2AdmissionGuardProofs.sort_universe_mvar_precedes_param
#print axioms PsKernelExprV2AdmissionGuardProofs.constant_universe_mvar_precedes_param
#print axioms PsKernelExprV2AdmissionGuardProofs.free_variable_precedes_undefined_param
#print axioms PsKernelExprV2AdmissionGuardProofs.finish_matches_reference
#print axioms PsKernelExprV2AdmissionGuardProofs.scan_zero_precedes_memo
#print axioms PsKernelExprV2AdmissionGuardProofs.validated_root_expression_mvar
#print axioms PsKernelExprV2AdmissionGuardProofs.canonical_guard_matches_reference_conditionally
#print axioms PsKernelExprV2AdmissionGuardProofs.checked_boundary_preserves_validation_error
#print axioms PsKernelExprV2AdmissionGuardProofs.header_existing_name_precedes_arena
#print axioms PsKernelExprV2AdmissionGuardProofs.header_duplicate_params_precedes_arena
