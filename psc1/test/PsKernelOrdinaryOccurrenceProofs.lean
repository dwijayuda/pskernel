import Lean.Elab.Tactic.Omega
import Ps.KernelCore.API.DagOrdinaryOccurrence
import Ps.KernelCore.API.DagOrdinaryAnnotations
import Ps.KernelCore.Admission.Inductive.Common.Occurrence
import Ps.KernelCore.Research.ExprV2Validation

/-!
Universal structural correspondence for the actual ID-native ordinary header
workers. ArenaModel states node decoding, child-reference closure and sound
depth metadata. It assumes no result of either occurrence or annotation worker.

The theorems below do not prove that every successful replay-validation call
establishes ArenaModel. That whole-arena invariant remains a separate boundary
obligation. They also make no claim about constructor or recursor admission.
All proof-only models and tactics stay outside the portable executable closure.
-/
namespace PsKernelOrdinaryOccurrenceProofs

def nodeExpr (decode : Nat -> PsKernelExpr) : PsKernelExprV2Node -> PsKernelExpr
  | .bvar index => .bvar index
  | .fvar name => .fvar name
  | .mvar name => .mvar name
  | .sort level => .sort level
  | .const name levels => .const name levels
  | .app fn arg => .app (decode fn) (decode arg)
  | .lam name type body info => .lam name (decode type) (decode body) info
  | .forallE name type body info => .forallE name (decode type) (decode body) info
  | .letE name type value body nondep =>
      .letE name (decode type) (decode value) (decode body) nondep
  | .lit value => .lit value
  | .mdata tag body => .mdata tag (decode body)
  | .proj name index body => .proj name index (decode body)

def validId (arena : PsKernelExprV2PagedArena) (root : Nat) : Prop :=
  Exists (fun entry => psKernelExprV2PagedFind arena root = some entry)

def validIds (arena : PsKernelExprV2PagedArena) (ids : List Nat) : Prop :=
  forall id, id ∈ ids -> validId arena id

def childIds (node : PsKernelExprV2Node) : List Nat :=
  (psKernelExprV2TransformChildren node 0).map Prod.fst

structure ArenaModel (arena : PsKernelExprV2PagedArena)
    (decode : Nat -> PsKernelExpr) : Prop where
  shape : forall root entry, psKernelExprV2PagedFind arena root = some entry ->
    decode root = nodeExpr decode entry.node
  depth : forall root entry, psKernelExprV2PagedFind arena root = some entry ->
    psKernelExprV2LegacyDepth (decode root) <= entry.depth
  children : forall root entry, psKernelExprV2PagedFind arena root = some entry ->
    validIds arena (childIds entry.node)

theorem legacy_depth_positive (expr : PsKernelExpr) :
    0 < psKernelExprV2LegacyDepth expr := by
  cases expr <;> simp [psKernelExprV2LegacyDepth]

theorem legacy_depth_le_expanded_count (expr : PsKernelExpr) :
    psKernelExprV2LegacyDepth expr <= psKernelExprNodeCount expr := by
  induction expr <;>
    simp_all [psKernelExprV2LegacyDepth, psKernelExprNodeCount, Nat.max_le] <;> omega

theorem app_spine_with_fuel_correspondence
    (arena : PsKernelExprV2PagedArena) (decode : Nat -> PsKernelExpr)
    (model : ArenaModel arena decode) (fuel : Nat) :
    forall root args,
      validId arena root -> validIds arena args ->
      psKernelExprV2LegacyDepth (decode root) <= fuel ->
      Exists (fun head => Exists (fun values =>
        psKernelExprV2TransformAppSpineWithFuel fuel arena root args =
          Except.ok (head, values) /\
        validId arena head /\
        decode head = psKernelExprGetAppFn (decode root) /\
        values.map decode = psKernelExprGetAppArgsWorker (decode root) (args.map decode) /\
        validIds arena values)) := by
  induction fuel with
  | zero =>
      intro root args _ _ bound
      have positive := legacy_depth_positive (decode root)
      omega
  | succ remaining ih =>
      intro root args rootValid argsValid bound
      rcases rootValid with ⟨entry, lookup⟩
      have shape := model.shape root entry lookup
      have children := model.children root entry lookup
      cases node : entry.node
      case app fn arg =>
          have fnValid : validId arena fn :=
            children fn (by simp [childIds, node, psKernelExprV2TransformChildren])
          have argValid : validId arena arg :=
            children arg (by simp [childIds, node, psKernelExprV2TransformChildren])
          have nextArgsValid : validIds arena (arg :: args) := by
            intro id member
            simp only [List.mem_cons] at member
            rcases member with equal | old
            · subst id
              exact argValid
            · exact argsValid id old
          have fnBound : psKernelExprV2LegacyDepth (decode fn) <= remaining := by
            simp only [shape, node, nodeExpr, psKernelExprV2LegacyDepth,
              Nat.succ_le_succ_iff, Nat.max_le] at bound
            exact bound.1
          rcases ih fn (arg :: args) fnValid nextArgsValid fnBound with
            ⟨head, values, result, headValid, headExpr, valueExprs, valuesValid⟩
          refine ⟨head, values, ?_, headValid, ?_, ?_, valuesValid⟩
          · simpa only [psKernelExprV2TransformAppSpineWithFuel, lookup, node] using result
          · simpa only [shape, node, nodeExpr, psKernelExprGetAppFn] using headExpr
          · simpa only [shape, node, nodeExpr, psKernelExprGetAppArgsWorker,
              List.map_cons] using valueExprs
      all_goals
        refine ⟨root, args, ?_, ⟨entry, lookup⟩, ?_, ?_, argsValid⟩
        · simp only [psKernelExprV2TransformAppSpineWithFuel, lookup, node]
        · simp only [shape, node, nodeExpr, psKernelExprGetAppFn]
        · simp only [shape, node, nodeExpr, psKernelExprGetAppArgsWorker]

theorem app_spine_on_canonical_correspondence
    (arena : PsKernelExprV2PagedArena) (decode : Nat -> PsKernelExpr)
    (model : ArenaModel arena decode) (root : Nat)
    (rootValid : validId arena root) :
    Exists (fun head => Exists (fun args =>
      psKernelExprV2TransformAppSpineOnCanonical arena root = Except.ok (head, args) /\
      validId arena head /\
      decode head = psKernelExprGetAppFn (decode root) /\
      args.map decode = psKernelExprGetAppArgs (decode root) /\
      validIds arena args)) := by
  rcases rootValid with ⟨entry, lookup⟩
  have bound := model.depth root entry lookup
  have emptyValid : validIds arena [] := by
    intro id member
    cases member
  rcases app_spine_with_fuel_correspondence arena decode model (Nat.succ entry.depth)
      root [] ⟨entry, lookup⟩ emptyValid (by omega) with
    ⟨head, args, result, headValid, headExpr, argExprs, argsValid⟩
  refine ⟨head, args, ?_, headValid, headExpr, ?_, argsValid⟩
  · simpa only [psKernelExprV2TransformAppSpineOnCanonical, lookup] using result
  · simpa only [psKernelExprGetAppArgs, List.map_nil] using argExprs

theorem uniform_argument_count_correspondence
    (decode : Nat -> PsKernelExpr) (args : List Nat) :
    psKernelExprV2TransformNatLength args = psKernelExprListLength (args.map decode) := by
  induction args with
  | nil => rfl
  | cons first rest ih =>
      simpa only [psKernelExprV2TransformNatLength, List.map_cons,
        psKernelExprListLength] using congrArg Nat.succ ih

theorem uniform_arguments_correspondence
    (arena : PsKernelExprV2PagedArena) (decode : Nat -> PsKernelExpr)
    (model : ArenaModel arena decode) (args : List Nat)
    (argsValid : validIds arena args) (offset index : Nat) :
    psKernelExprV2OrdinaryUniformParamArgs args arena offset index =
      Except.ok (psKernelSimpleUniformParamArgsMatch offset (args.map decode) index) := by
  induction args generalizing index with
  | nil => rfl
  | cons first rest ih =>
      rcases argsValid first (by simp) with ⟨entry, lookup⟩
      have restValid : validIds arena rest := by
        intro id member
        exact argsValid id (by simp [member])
      have shape := model.shape first entry lookup
      cases node : entry.node <;>
        simp [psKernelExprV2OrdinaryUniformParamArgs, psKernelExprV2PagedRequire,
          lookup, node, List.map_cons, psKernelSimpleUniformParamArgsMatch,
          psKernelSimpleUniformParamArgsMatchWorker, shape, nodeExpr, ih restValid]
      all_goals split <;> simp_all

theorem declared_names_correspondence (target : PsKernelName) (values : List PsKernelName) :
    psKernelExprV2OrdinaryDeclaredNameMember target values = psKernelNameMember target values := by
  induction values with
  | nil => rfl
  | cons first rest ih =>
      simp only [psKernelExprV2OrdinaryDeclaredNameMember, psKernelNameMember, ih]

theorem uniform_occurrence_head_correspondence
    (arena : PsKernelExprV2PagedArena) (decode : Nat -> PsKernelExpr)
    (model : ArenaModel arena decode) (root : Nat)
    (rootValid : validId arena root)
    (declaredNames : List PsKernelName) (expectedLevels : List PsKernelLevel)
    (numParams offset : Nat) :
    psKernelExprV2OrdinaryUniformOccurrenceHead
        arena declaredNames expectedLevels numParams root offset =
      psKernelSimpleCheckUniformOccurrenceHead
        declaredNames expectedLevels numParams (decode root) offset := by
  rcases app_spine_on_canonical_correspondence arena decode model root rootValid with
    ⟨head, args, spine, headValid, headExpr, argExprs, argsValid⟩
  rcases headValid with ⟨entry, lookup⟩
  have shape := model.shape head entry lookup
  have count := uniform_argument_count_correspondence decode args
  have matched := uniform_arguments_correspondence arena decode model args argsValid offset 0
  simp only [psKernelExprV2OrdinaryUniformOccurrenceHead, spine,
    psKernelExprV2PagedRequire, lookup, psKernelSimpleCheckUniformOccurrenceHead]
  rw [← headExpr, ← argExprs, shape]
  cases node : entry.node <;>
    simp [nodeExpr, node, count, matched, psKernelSimpleDeclaredNameMember,
      declared_names_correspondence]

theorem uniform_occurrence_with_fuel_correspondence
    (arena : PsKernelExprV2PagedArena) (decode : Nat -> PsKernelExpr)
    (model : ArenaModel arena decode) (fuel : Nat)
    (root : Nat) (rootValid : validId arena root)
    (declaredNames : List PsKernelName) (expectedLevels : List PsKernelLevel)
    (numParams offset : Nat) :
    psKernelExprV2OrdinaryUniformOccurrenceWithFuel
        fuel arena declaredNames expectedLevels numParams root offset =
      psKernelSimpleCheckUniformOccurrenceWithFuel
        fuel declaredNames expectedLevels numParams (decode root) offset := by
  induction fuel generalizing root offset with
  | zero => rfl
  | succ remaining ih =>
      have headEqual := uniform_occurrence_head_correspondence
        arena decode model root rootValid declaredNames expectedLevels numParams offset
      simp only [psKernelExprV2OrdinaryUniformOccurrenceWithFuel,
        psKernelSimpleCheckUniformOccurrenceWithFuel, headEqual]
      cases head : psKernelSimpleCheckUniformOccurrenceHead
          declaredNames expectedLevels numParams (decode root) offset with
      | error error => rfl
      | ok stop =>
          cases stop with
          | true => rfl
          | false =>
              rcases rootValid with ⟨entry, lookup⟩
              have shape := model.shape root entry lookup
              have children := model.children root entry lookup
              simp only [Bool.false_eq_true, ite_false, psKernelExprV2PagedRequire,
                lookup, shape]
              cases node : entry.node
              case app fn arg =>
                  have fnValid := children fn
                    (by simp [childIds, node, psKernelExprV2TransformChildren])
                  have argValid := children arg
                    (by simp [childIds, node, psKernelExprV2TransformChildren])
                  simp only [nodeExpr, node, ih fn fnValid, ih arg argValid] <;> rfl
              case lam name type body info =>
                  have typeValid := children type
                    (by simp [childIds, node, psKernelExprV2TransformChildren])
                  have bodyValid := children body
                    (by simp [childIds, node, psKernelExprV2TransformChildren])
                  simp only [nodeExpr, node, ih type typeValid, ih body bodyValid] <;> rfl
              case forallE name type body info =>
                  have typeValid := children type
                    (by simp [childIds, node, psKernelExprV2TransformChildren])
                  have bodyValid := children body
                    (by simp [childIds, node, psKernelExprV2TransformChildren])
                  simp only [nodeExpr, node, ih type typeValid, ih body bodyValid] <;> rfl
              case letE name type value body nondep =>
                  have typeValid := children type
                    (by simp [childIds, node, psKernelExprV2TransformChildren])
                  have valueValid := children value
                    (by simp [childIds, node, psKernelExprV2TransformChildren])
                  have bodyValid := children body
                    (by simp [childIds, node, psKernelExprV2TransformChildren])
                  simp only [nodeExpr, node, ih type typeValid, ih value valueValid,
                    ih body bodyValid] <;> rfl
              case mdata tag body =>
                  have bodyValid := children body
                    (by simp [childIds, node, psKernelExprV2TransformChildren])
                  simp only [nodeExpr, node, ih body bodyValid]
              case proj name index body =>
                  have bodyValid := children body
                    (by simp [childIds, node, psKernelExprV2TransformChildren])
                  simp only [nodeExpr, node, ih body bodyValid]
              all_goals simp only [nodeExpr, node]

/- Sufficient structural fuel is observationally irrelevant to the reference
   worker, even when the first semantic error stops an earlier sibling. -/
theorem uniform_occurrence_structural_adequacy
    (expr : PsKernelExpr) (firstFuel secondFuel : Nat)
    (firstBound : psKernelExprV2LegacyDepth expr <= firstFuel)
    (secondBound : psKernelExprV2LegacyDepth expr <= secondFuel)
    (declaredNames : List PsKernelName) (expectedLevels : List PsKernelLevel)
    (numParams offset : Nat) :
    psKernelSimpleCheckUniformOccurrenceWithFuel
        firstFuel declaredNames expectedLevels numParams expr offset =
      psKernelSimpleCheckUniformOccurrenceWithFuel
        secondFuel declaredNames expectedLevels numParams expr offset := by
  induction expr generalizing firstFuel secondFuel offset <;>
    cases firstFuel <;> cases secondFuel <;>
    simp only [psKernelExprV2LegacyDepth, Nat.succ_le_succ_iff,
      Nat.not_succ_le_zero, Nat.max_le] at firstBound secondBound
  case app.succ.succ fn arg ihFn ihArg first second =>
    have fnEqual := ihFn first second firstBound.1 secondBound.1 offset
    have argEqual := ihArg first second firstBound.2 secondBound.2 offset
    simp only [psKernelSimpleCheckUniformOccurrenceWithFuel, fnEqual, argEqual]
  case lam.succ.succ name type body info ihType ihBody first second =>
    have typeEqual := ihType first second firstBound.1 secondBound.1 offset
    have bodyEqual := ihBody first second firstBound.2 secondBound.2 (Nat.succ offset)
    simp only [psKernelSimpleCheckUniformOccurrenceWithFuel, typeEqual, bodyEqual]
  case forallE.succ.succ name type body info ihType ihBody first second =>
    have typeEqual := ihType first second firstBound.1 secondBound.1 offset
    have bodyEqual := ihBody first second firstBound.2 secondBound.2 (Nat.succ offset)
    simp only [psKernelSimpleCheckUniformOccurrenceWithFuel, typeEqual, bodyEqual]
  case letE.succ.succ name type value body nondep ihType ihValue ihBody first second =>
    have typeEqual := ihType first second firstBound.1.1 secondBound.1.1 offset
    have valueEqual := ihValue first second firstBound.1.2 secondBound.1.2 offset
    have bodyEqual := ihBody first second firstBound.2 secondBound.2 (Nat.succ offset)
    simp only [psKernelSimpleCheckUniformOccurrenceWithFuel, typeEqual, valueEqual, bodyEqual]
  case mdata.succ.succ tag body ihBody first second =>
    have bodyEqual := ihBody first second firstBound secondBound offset
    simp only [psKernelSimpleCheckUniformOccurrenceWithFuel, bodyEqual]
  case proj.succ.succ name index body ihBody first second =>
    have bodyEqual := ihBody first second firstBound secondBound offset
    simp only [psKernelSimpleCheckUniformOccurrenceWithFuel, bodyEqual]
  all_goals
    first
    | omega
    | rfl

theorem uniform_occurrence_on_canonical_correspondence
    (arena : PsKernelExprV2PagedArena) (decode : Nat -> PsKernelExpr)
    (model : ArenaModel arena decode) (root : Nat)
    (rootValid : validId arena root)
    (declaredNames : List PsKernelName) (expectedLevels : List PsKernelLevel)
    (numParams offset : Nat) :
    psKernelExprV2OrdinaryUniformOccurrenceOnCanonical
        arena declaredNames expectedLevels numParams root offset =
      psKernelSimpleCheckUniformOccurrence
        declaredNames expectedLevels numParams (decode root) offset := by
  rcases rootValid with ⟨entry, lookup⟩
  have depthBound := model.depth root entry lookup
  have countBound := legacy_depth_le_expanded_count (decode root)
  simp only [psKernelExprV2OrdinaryUniformOccurrenceOnCanonical,
    psKernelExprV2PagedRequire, lookup, psKernelSimpleCheckUniformOccurrence]
  rw [uniform_occurrence_with_fuel_correspondence
    arena decode model _ root ⟨entry, lookup⟩]
  exact uniform_occurrence_structural_adequacy (decode root) _ _
    (by omega) (by omega) declaredNames expectedLevels numParams offset

theorem uniform_occurrences_correspondence
    (arena : PsKernelExprV2PagedArena) (decode : Nat -> PsKernelExpr)
    (model : ArenaModel arena decode) (roots : List Nat)
    (rootsValid : validIds arena roots)
    (declaredNames : List PsKernelName) (expectedLevels : List PsKernelLevel)
    (numParams : Nat) :
    psKernelExprV2OrdinaryUniformOccurrences roots arena declaredNames expectedLevels numParams =
      psKernelSimpleCheckUniformOccurrencesWorker (roots.map decode)
        declaredNames expectedLevels numParams := by
  induction roots with
  | nil => rfl
  | cons first rest ih =>
      have firstValid := rootsValid first (by simp)
      have restValid : validIds arena rest := by
        intro id member
        exact rootsValid id (by simp [member])
      simp only [psKernelExprV2OrdinaryUniformOccurrences, List.map_cons,
        psKernelSimpleCheckUniformOccurrencesWorker,
        uniform_occurrence_on_canonical_correspondence
          arena decode model first firstValid, ih restValid] <;> rfl

/- The native proof target records exactly the next V1 annotation argument.
   It is not imported by production and never replaces the actual worker. -/
def annotationTarget (expr : PsKernelExpr) : Option PsKernelExpr :=
  match psKernelExprGetAppFn expr with
  | .const name _ =>
      match psKernelExprGetAppArgs expr with
      | first :: rest =>
          match rest with
          | [] =>
              if
                  if psKernelNameEq name psKernelTypeAnnotationOutParamName then true
                  else psKernelNameEq name psKernelTypeAnnotationSemiOutParamName then
                some first
              else none
          | _ :: secondRest =>
              match secondRest with
              | [] =>
                  if
                      if psKernelNameEq name psKernelTypeAnnotationOptParamName then true
                      else psKernelNameEq name psKernelTypeAnnotationAutoParamName then
                    some first
                  else none
              | _ :: _ => none
      | [] => none
  | _ => none

theorem annotation_step (fuel : Nat) (expr : PsKernelExpr) :
    psKernelExprConsumeTypeAnnotationsWithFuel (Nat.succ fuel) expr =
      match annotationTarget expr with
      | none => expr
      | some first => psKernelExprConsumeTypeAnnotationsWithFuel fuel first := by
  cases fn : psKernelExprGetAppFn expr <;>
    simp only [psKernelExprConsumeTypeAnnotationsWithFuel, annotationTarget, fn]
  case const name levels =>
    cases args : psKernelExprGetAppArgs expr with
    | nil => rfl
    | cons first rest =>
        cases rest with
        | nil =>
            cases outParam : psKernelNameEq name psKernelTypeAnnotationOutParamName <;>
              cases semiOutParam : psKernelNameEq name psKernelTypeAnnotationSemiOutParamName <;>
              simp_all [args]
        | cons second tail =>
            cases tail with
            | nil =>
                cases optParam : psKernelNameEq name psKernelTypeAnnotationOptParamName <;>
                  cases autoParam : psKernelNameEq name psKernelTypeAnnotationAutoParamName <;>
                  simp_all [args]
            | cons third tail => rfl

theorem app_args_worker_depth
    (expr : PsKernelExpr) (acc : List PsKernelExpr) (value : PsKernelExpr)
    (member : value ∈ psKernelExprGetAppArgsWorker expr acc) :
    value ∈ acc \/
      psKernelExprV2LegacyDepth value < psKernelExprV2LegacyDepth expr := by
  induction expr generalizing acc
  case app fn arg ihFn ihArg =>
    simp only [psKernelExprGetAppArgsWorker] at member
    rcases ihFn (arg :: acc) member with previous | smaller
    · simp only [List.mem_cons] at previous
      rcases previous with equal | old
      · subst value
        right
        simp only [psKernelExprV2LegacyDepth]
        exact Nat.lt_succ_of_le (Nat.le_max_right _ _)
      · exact Or.inl old
    · right
      simp only [psKernelExprV2LegacyDepth]
      exact Nat.lt_trans smaller (Nat.lt_succ_of_le (Nat.le_max_left _ _))
  all_goals
    exact Or.inl (by simpa only [psKernelExprGetAppArgsWorker] using member)

theorem annotation_target_member
    (expr first : PsKernelExpr) (selected : annotationTarget expr = some first) :
    first ∈ psKernelExprGetAppArgs expr := by
  cases fn : psKernelExprGetAppFn expr <;>
    simp only [annotationTarget, fn] at selected
  case const name levels =>
    cases args : psKernelExprGetAppArgs expr with
    | nil => simp [args] at selected
    | cons value rest =>
        cases rest with
        | nil =>
            simp only [args] at selected
            split at selected <;> simp_all
        | cons second tail =>
            cases tail with
            | nil =>
                simp only [args] at selected
                split at selected <;> simp_all
            | cons third tail => simp [args] at selected
  all_goals contradiction

theorem annotation_target_depth
    (expr first : PsKernelExpr) (selected : annotationTarget expr = some first) :
    psKernelExprV2LegacyDepth first < psKernelExprV2LegacyDepth expr := by
  have member := annotation_target_member expr first selected
  rcases app_args_worker_depth expr [] first member with impossible | smaller
  · cases impossible
  · exact smaller

theorem annotation_structural_adequacy_at_depth (depth : Nat) :
    forall expr : PsKernelExpr, psKernelExprV2LegacyDepth expr = depth ->
      forall firstFuel secondFuel : Nat,
        psKernelExprV2LegacyDepth expr <= firstFuel ->
        psKernelExprV2LegacyDepth expr <= secondFuel ->
        psKernelExprConsumeTypeAnnotationsWithFuel firstFuel expr =
          psKernelExprConsumeTypeAnnotationsWithFuel secondFuel expr := by
  induction depth using Nat.strongRecOn with
  | ind depth ih =>
      intro expr atDepth firstFuel secondFuel firstBound secondBound
      have positive := legacy_depth_positive expr
      cases firstFuel with
      | zero => omega
      | succ first =>
          cases secondFuel with
          | zero => omega
          | succ second =>
              simp only [annotation_step]
              cases target : annotationTarget expr with
              | none => rfl
              | some next =>
                  have smaller := annotation_target_depth expr next target
                  exact ih (psKernelExprV2LegacyDepth next) (by omega)
                    next rfl first second (by omega) (by omega)

theorem annotation_structural_adequacy
    (expr : PsKernelExpr) (firstFuel secondFuel : Nat)
    (firstBound : psKernelExprV2LegacyDepth expr <= firstFuel)
    (secondBound : psKernelExprV2LegacyDepth expr <= secondFuel) :
    psKernelExprConsumeTypeAnnotationsWithFuel firstFuel expr =
      psKernelExprConsumeTypeAnnotationsWithFuel secondFuel expr := by
  exact annotation_structural_adequacy_at_depth
    (psKernelExprV2LegacyDepth expr) expr rfl firstFuel secondFuel firstBound secondBound

theorem annotations_with_fuel_correspondence
    (arena : PsKernelExprV2PagedArena) (decode : Nat -> PsKernelExpr)
    (model : ArenaModel arena decode) (fuel : Nat)
    (root : Nat) (rootValid : validId arena root) :
    Exists (fun result =>
      psKernelExprV2OrdinaryConsumeTypeAnnotationsWithFuel fuel arena root = Except.ok result /\
      validId arena result /\
      decode result = psKernelExprConsumeTypeAnnotationsWithFuel fuel (decode root)) := by
  induction fuel generalizing root with
  | zero => exact ⟨root, rfl, rootValid, rfl⟩
  | succ remaining ih =>
      rcases app_spine_on_canonical_correspondence arena decode model root rootValid with
        ⟨head, args, spine, headValid, headExpr, argExprs, argsValid⟩
      rcases headValid with ⟨entry, lookup⟩
      have shape := model.shape head entry lookup
      simp only [psKernelExprV2OrdinaryConsumeTypeAnnotationsWithFuel, spine,
        psKernelExprV2PagedRequire, lookup, psKernelExprConsumeTypeAnnotationsWithFuel]
      rw [← headExpr, ← argExprs, shape]
      cases node : entry.node
      case const name levels =>
        simp only [nodeExpr]
        cases args with
        | nil => exact ⟨root, rfl, rootValid, rfl⟩
        | cons first rest =>
            have firstValid : validId arena first := argsValid first (by simp)
            cases rest with
            | nil =>
                simp only [List.map_cons, List.map_nil]
                cases selected :
                    (if psKernelNameEq name psKernelTypeAnnotationOutParamName then true
                     else psKernelNameEq name psKernelTypeAnnotationSemiOutParamName) with
                | false => exact ⟨root, rfl, rootValid, rfl⟩
                | true => exact ih first firstValid
            | cons second tail =>
                cases tail with
                | nil =>
                    simp only [List.map_cons, List.map_nil]
                    cases selected :
                        (if psKernelNameEq name psKernelTypeAnnotationOptParamName then true
                         else psKernelNameEq name psKernelTypeAnnotationAutoParamName) with
                    | false => exact ⟨root, rfl, rootValid, rfl⟩
                    | true => exact ih first firstValid
                | cons third tail => exact ⟨root, rfl, rootValid, rfl⟩
      all_goals
        exact ⟨root, rfl, rootValid, by simp only [nodeExpr]⟩

theorem annotations_on_canonical_correspondence
    (arena : PsKernelExprV2PagedArena) (decode : Nat -> PsKernelExpr)
    (model : ArenaModel arena decode) (root : Nat)
    (rootValid : validId arena root) :
    Exists (fun result =>
      psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical arena root = Except.ok result /\
      validId arena result /\
      decode result = psKernelExprConsumeTypeAnnotations (decode root)) := by
  rcases rootValid with ⟨entry, lookup⟩
  rcases annotations_with_fuel_correspondence arena decode model
      (Nat.succ entry.depth) root ⟨entry, lookup⟩ with
    ⟨result, consumed, resultValid, resultExpr⟩
  have depthBound := model.depth root entry lookup
  have countBound := legacy_depth_le_expanded_count (decode root)
  refine ⟨result, ?_, resultValid, ?_⟩
  · simpa only [psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical,
      psKernelExprV2PagedRequire, lookup] using consumed
  · rw [resultExpr, psKernelExprConsumeTypeAnnotations]
    exact annotation_structural_adequacy (decode root) _ _ (by omega) (by omega)

end PsKernelOrdinaryOccurrenceProofs

#print axioms PsKernelOrdinaryOccurrenceProofs.app_spine_with_fuel_correspondence
#print axioms PsKernelOrdinaryOccurrenceProofs.app_spine_on_canonical_correspondence
#print axioms PsKernelOrdinaryOccurrenceProofs.uniform_argument_count_correspondence
#print axioms PsKernelOrdinaryOccurrenceProofs.uniform_arguments_correspondence
#print axioms PsKernelOrdinaryOccurrenceProofs.declared_names_correspondence
#print axioms PsKernelOrdinaryOccurrenceProofs.uniform_occurrence_head_correspondence
#print axioms PsKernelOrdinaryOccurrenceProofs.uniform_occurrence_with_fuel_correspondence
#print axioms PsKernelOrdinaryOccurrenceProofs.uniform_occurrence_structural_adequacy
#print axioms PsKernelOrdinaryOccurrenceProofs.uniform_occurrence_on_canonical_correspondence
#print axioms PsKernelOrdinaryOccurrenceProofs.uniform_occurrences_correspondence
#print axioms PsKernelOrdinaryOccurrenceProofs.legacy_depth_le_expanded_count
#print axioms PsKernelOrdinaryOccurrenceProofs.annotation_target_depth
#print axioms PsKernelOrdinaryOccurrenceProofs.annotation_structural_adequacy
#print axioms PsKernelOrdinaryOccurrenceProofs.annotations_with_fuel_correspondence
#print axioms PsKernelOrdinaryOccurrenceProofs.annotations_on_canonical_correspondence
