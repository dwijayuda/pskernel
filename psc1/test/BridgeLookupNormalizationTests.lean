import Ps.Bridge.CheckedAdmissions

namespace PsBridgeLookupReference
def psBridgeFindConstructor
    (declarations : List PsDeclaration) :
    PsName -> Option PsConstructorInfo :=
  match declarations with
  | List.nil =>
      fun (_name : PsName) => Option.none
  | List.cons declaration rest =>
      let smaller : PsName -> Option PsConstructorInfo :=
        psBridgeFindConstructor rest;
      fun (name : PsName) =>
        match declaration with
        | .constructorDecl info =>
            if psNameEq info.name name then
              Option.some info
            else
              smaller name
        | _ =>
            smaller name


def psBridgeFindRegularHeightInBucket
    (entries : List (PsName × Nat)) :
    PsName -> Nat :=
  match entries with
  | List.nil =>
      fun (_name : PsName) => 0
  | List.cons entry rest =>
      let smaller : PsName -> Nat :=
        psBridgeFindRegularHeightInBucket rest;
      fun (name : PsName) =>
        if psNameEq (Prod.fst entry) name then
          Prod.snd entry
        else
          smaller name


def psBridgeHeightBucket (fuel : Nat) : PsBridgeHeightIndex -> Nat -> List (PsName × Nat) :=
  match fuel with
  | Nat.zero => fun (index : PsBridgeHeightIndex) (_hash : Nat) =>
      match index with
      | PsBridgeHeightIndex.bucket entries => entries
      | _ => List.nil
  | Nat.succ remaining =>
      fun (index : PsBridgeHeightIndex) (hash : Nat) =>
        let smaller : PsBridgeHeightIndex -> Nat -> List (PsName × Nat) := psBridgeHeightBucket remaining;
        match index with
        | PsBridgeHeightIndex.branch left right =>
            if Nat.beq (Nat.mod hash 2) 0 then smaller left (Nat.div hash 2)
            else smaller right (Nat.div hash 2)
        | _ => List.nil

end PsBridgeLookupReference

private theorem constructor_worker_eq (declarations : List PsDeclaration) :
    psBridgeFindConstructorWorker declarations =
      PsBridgeLookupReference.psBridgeFindConstructor declarations := by
  induction declarations with
  | nil => rfl
  | cons declaration rest ih =>
      funext name
      cases declaration <;>
        simp only [psBridgeFindConstructorWorker,
          PsBridgeLookupReference.psBridgeFindConstructor, ih]

theorem psBridgeConstructorLookup_all_inputs
    (declarations : List PsDeclaration) (name : PsName) :
    psBridgeFindConstructor declarations name =
      PsBridgeLookupReference.psBridgeFindConstructor declarations name := by
  simpa only [psBridgeFindConstructor] using congrFun (constructor_worker_eq declarations) name

private theorem height_worker_eq (entries : List (PsName × Nat)) :
    psBridgeFindRegularHeightInBucketWorker entries =
      PsBridgeLookupReference.psBridgeFindRegularHeightInBucket entries := by
  induction entries with
  | nil => rfl
  | cons entry rest ih =>
      funext name
      simp only [psBridgeFindRegularHeightInBucketWorker,
        PsBridgeLookupReference.psBridgeFindRegularHeightInBucket, ih]

theorem psBridgeHeightLookup_all_inputs
    (entries : List (PsName × Nat)) (name : PsName) :
    psBridgeFindRegularHeightInBucket entries name =
      PsBridgeLookupReference.psBridgeFindRegularHeightInBucket entries name := by
  simpa only [psBridgeFindRegularHeightInBucket] using congrFun (height_worker_eq entries) name

private theorem bucket_worker_eq (fuel : Nat) :
    psBridgeHeightBucketWorker fuel = PsBridgeLookupReference.psBridgeHeightBucket fuel := by
  induction fuel with
  | zero =>
      funext index hash
      cases index <;> rfl
  | succ remaining ih =>
      funext index hash
      cases index <;>
        simp only [psBridgeHeightBucketWorker,
          PsBridgeLookupReference.psBridgeHeightBucket, ih]

theorem psBridgeHeightBucket_all_inputs
    (fuel : Nat) (index : PsBridgeHeightIndex) (hash : Nat) :
    psBridgeHeightBucket fuel index hash =
      PsBridgeLookupReference.psBridgeHeightBucket fuel index hash := by
  simpa only [psBridgeHeightBucket] using congrFun (congrFun (bucket_worker_eq fuel) index) hash

#print axioms psBridgeConstructorLookup_all_inputs
#print axioms psBridgeHeightLookup_all_inputs
#print axioms psBridgeHeightBucket_all_inputs

def main : IO Unit := do
  let anonymous := PsName.anonymous
  let missing := PsName.str anonymous "missing"
  let entries : List (PsName × Nat) := List.replicate 100001 (Prod.mk anonymous 7)
  unless psBridgeFindRegularHeightInBucket entries missing == 0 do
    throw (IO.userError "deep miss changed")
  unless psBridgeFindRegularHeightInBucket [Prod.mk anonymous 7, Prod.mk anonymous 9] anonymous == 7 do
    throw (IO.userError "first duplicate changed")
  for fuel in [:9] do
    for hash in [:129] do
      let index := PsBridgeHeightIndex.branch (PsBridgeHeightIndex.bucket entries) PsBridgeHeightIndex.empty
      unless (psBridgeHeightBucket fuel index hash).length ==
          (PsBridgeLookupReference.psBridgeHeightBucket fuel index hash).length do
        throw (IO.userError "fuel/index/hash lookup changed")
  IO.println "PSC1_BRIDGE_LOOKUP_NORMALIZATION: all-list/name/fuel/index/hash equalities proved; first duplicate and 100001-entry miss passed"
