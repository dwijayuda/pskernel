import Ps.Bridge.CheckedAdmissions
import CheckedSpineReference

set_option maxRecDepth 10000
set_option maxHeartbeats 4000000

private theorem spine_reverse_acc_eq (values acc : List alpha) :
    psListReverseAcc values acc = values.reverse ++ acc := by
  induction values generalizing acc with
  | nil => rfl
  | cons head tail ih =>
      simp [psListReverseAcc, ih, List.reverse_cons, List.append_assoc]

private theorem spine_reverse_eq (values : List alpha) : psListReverse values = values.reverse := by
  simp [psListReverse, spine_reverse_acc_eq]

private theorem collect_acc_append (all left right state) :
    psCheckedNestedCollectAcc all (left ++ right) state =
      psCheckedNestedCollectAcc all right (psCheckedNestedCollectAcc all left state) := by
  induction left generalizing state with
  | nil => rfl
  | cons declaration rest ih => simp [psCheckedNestedCollectAcc, ih]

private theorem collect_acc_reverse (all declarations state) :
    psCheckedNestedCollectAcc all declarations.reverse state =
      declarations.foldr (psCheckedNestedCollectStep all) state := by
  induction declarations generalizing state with
  | nil => rfl
  | cons declaration rest ih =>
      simp [List.reverse_cons, collect_acc_append, psCheckedNestedCollectAcc, ih]

private theorem reference_collect_foldr (all declarations) :
    CheckedSpineReference.psCheckedNestedCollect all declarations =
      declarations.foldr (psCheckedNestedCollectStep all) (.ok []) := by
  induction declarations with
  | nil => rfl
  | cons declaration rest ih =>
      simp only [CheckedSpineReference.psCheckedNestedCollect, List.foldr, ih, psCheckedNestedCollectStep]

theorem checked_collect_eq (all declarations) :
    psCheckedNestedCollect all declarations =
      CheckedSpineReference.psCheckedNestedCollect all declarations := by
  rw [psCheckedNestedCollect, spine_reverse_eq, collect_acc_reverse, reference_collect_foldr]

theorem checked_find_eq (wrappers) :
    psCheckedNestedFind wrappers = CheckedSpineReference.psCheckedNestedFind wrappers := by
  induction wrappers with
  | nil => rfl
  | cons entry rest ih =>
      funext name
      simp only [psCheckedNestedFind, CheckedSpineReference.psCheckedNestedFind, ih]

private theorem normalize_acc_eq (wrappers declarations acc) :
    psCheckedNestedNormalizeAcc wrappers declarations acc =
      acc.reverse ++ CheckedSpineReference.psCheckedNestedNormalize wrappers declarations := by
  induction declarations generalizing acc with
  | nil => simp [psCheckedNestedNormalizeAcc, spine_reverse_eq, CheckedSpineReference.psCheckedNestedNormalize]
  | cons declaration rest ih =>
      cases declaration <;>
        simp only [psCheckedNestedNormalizeAcc, CheckedSpineReference.psCheckedNestedNormalize,
          checked_find_eq] <;>
        repeat first
          | split
          | simp_all only [ih, List.reverse_cons, List.reverse_nil, List.nil_append,
              List.append_assoc, List.cons_append, List.singleton_append]

theorem checked_normalize_eq (wrappers declarations) :
    psCheckedNestedNormalize wrappers declarations =
      CheckedSpineReference.psCheckedNestedNormalize wrappers declarations := by
  simpa only [psCheckedNestedNormalize, List.reverse_nil, List.nil_append] using
    normalize_acc_eq wrappers declarations []

#print axioms checked_collect_eq
#print axioms checked_find_eq
#print axioms checked_normalize_eq

private def sameCollect (all values : List PsDeclaration) : Bool :=
  match psCheckedNestedCollect all values, CheckedSpineReference.psCheckedNestedCollect all values with
  | .error (.missingConstructor a),.error (.missingConstructor b) => psNameEq a b
  | .error (.mismatchedConstructor a),.error (.mismatchedConstructor b) => psNameEq a b
  | .ok a,.ok b =>
      Nat.beq (psListLength a) (psListLength b)
  | _,_ => false

def runCheckedSpineTests : IO Unit := do
  let nameA := PsName.str .anonymous "A"
  let nameB := PsName.str .anonymous "B"
  let ctorA := PsName.str nameA "missing"
  let ctorB := PsName.str nameB "missing"
  let infoA := PsInductiveInfo.mk nameA [] (.sortE .zero) 0 0 [ctorA] false
  let infoB := PsInductiveInfo.mk nameB [] (.sortE .zero) 0 0 [ctorB] false
  let values := [PsDeclaration.inductiveDecl infoA,PsDeclaration.inductiveDecl infoB]
  if !sameCollect values values then throw (IO.userError "collector changed rightmost error")
  match psCheckedNestedCollect values values with
  | .error (.missingConstructor name) =>
      if !(psNameEq name ctorB) then throw (IO.userError "collector error priority changed")
  | _ => throw (IO.userError "missing constructor accepted")
  let sample := PsDeclaration.definitionDecl nameA [] (.sortE .zero) (.sortE .zero)
  let large := List.replicate 10000 sample
  match psCheckedNestedCollect large large with
  | .ok result => if !result.isEmpty then throw (IO.userError "unexpected wrappers")
  | _ => throw (IO.userError "ordinary declarations refused")
  if (psCheckedNestedNormalize [] large).length != 10000 then throw (IO.userError "normalize order/length")
  IO.println "PSC1_CHECKED_SPINES: all-input collector/find/normalization equalities; exact rightmost-error priority;10000 declarations"
