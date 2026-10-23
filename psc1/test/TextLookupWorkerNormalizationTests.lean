import Ps.Foundation.Text
import Ps.BackendTs.Expr

namespace PsTextLookupReference
def psTextInsert
    (levels : List (Option String)) :
    String -> List (Option String) :=
  match levels with
  | List.nil =>
      fun (chunk : String) =>
        List.cons (Option.some chunk) List.nil
  | List.cons level rest =>
      let smaller : String -> List (Option String) :=
        psTextInsert rest;
      fun (chunk : String) =>
        match level with
        | Option.none =>
            List.cons (Option.some chunk) rest
        | Option.some older =>
            List.cons Option.none
              (smaller (String.Internal.append older chunk))

def psTextBuilderAppend
    (builder : PsTextBuilder)
    (chunk : String) : PsTextBuilder :=
  PsTextBuilder.mk (psTextInsert builder.levels chunk)

def psTextJoinWorker
    (separator : String)
    (values : List String) :
    Bool -> PsTextBuilder -> String :=
  match values with
  | List.nil =>
      fun (_first : Bool) (builder : PsTextBuilder) =>
        psTextBuilderFinish builder
  | List.cons value rest =>
      let smaller : Bool -> PsTextBuilder -> String :=
        psTextJoinWorker separator rest;
      fun (first : Bool) (builder : PsTextBuilder) =>
        let separated : PsTextBuilder :=
          if first then builder else psTextBuilderAppend builder separator;
        smaller false (psTextBuilderAppend separated value)

def psTextJoin
    (separator : String)
    (values : List String) : String :=
  psTextJoinWorker separator values true psTextBuilderEmpty

def psTsLookup (entries : List (String × String)) : String -> Option String :=
  match entries with
  | List.nil => fun (_name : String) => Option.none
  | List.cons entry rest =>
      let smaller : String -> Option String := psTsLookup rest;
      fun (name : String) =>
        match entry with
        | Prod.mk key value => if psStringEq key name then Option.some value else smaller name
def psTsExprUsesNameWithFuel (fuel : Nat) : PsVerifiedIrExpr -> String -> Bool :=
  match fuel with
  | Nat.zero => fun (_expr : PsVerifiedIrExpr) (_name : String) => true
  | Nat.succ remaining =>
      fun (expr : PsVerifiedIrExpr) (name : String) =>
        let smaller : PsVerifiedIrExpr -> String -> Bool := psTsExprUsesNameWithFuel remaining;
        let uses : PsVerifiedIrExpr -> Bool := fun (value : PsVerifiedIrExpr) => smaller value name;
        let parameterUses : PsVerifiedIrParameter -> Bool :=
          fun (parameter : PsVerifiedIrParameter) => psStringEq parameter.name name;
        let bindingUses : PsVerifiedIrMatchBinding -> Bool :=
          fun (binding : PsVerifiedIrMatchBinding) => psStringEq binding.name name;
        let fieldUses : (String × PsVerifiedIrExpr) -> Bool :=
          fun (field : String × PsVerifiedIrExpr) =>
            match field with
            | Prod.mk _ value => smaller value name;
        let alternativeUses : (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr) -> Bool :=
          fun (alternative : String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr) =>
            match alternative with
            | Prod.mk _ detail =>
                match detail with
                | Prod.mk bindings body =>
                    if psListAny bindingUses bindings then true else smaller body name;
        match expr with
        | .literal _ => false
        | .var value => psStringEq value name
        | .intrinsic _ _ arguments => psListAny uses arguments
        | .lambda parameters _ body =>
            if psListAny parameterUses parameters then true else smaller body name
        | .call fn _ arguments => if smaller fn name then true else psListAny uses arguments
        | .letE localName _ value body =>
            if psStringEq localName name then true
            else if smaller value name then true else smaller body name
        | .ifE condition thenBranch elseBranch =>
            if smaller condition name then true
            else if smaller thenBranch name then true else smaller elseBranch name
        | .record _ _ fields => psListAny fieldUses fields
        | .projection _ _ target _ => smaller target name
        | .constructor _ _ _ fields => psListAny fieldUses fields
        | .matchE _ _ scrutinee alternatives =>
            if smaller scrutinee name then true else psListAny alternativeUses alternatives
end PsTextLookupReference

theorem text_insert_applied_eq (levels : List (Option String)) (chunk : String) :
    psTextInsertApplied levels chunk = PsTextLookupReference.psTextInsert levels chunk := by
  induction levels generalizing chunk with
  | nil => rfl
  | cons level rest ih =>
      cases level with
      | none => rfl
      | some older =>
          change List.cons Option.none (psTextInsertApplied rest (String.Internal.append older chunk)) =
            List.cons Option.none (PsTextLookupReference.psTextInsert rest (String.Internal.append older chunk))
          rw [ih]

theorem text_insert_public_eq (levels : List (Option String)) :
    psTextInsert levels = PsTextLookupReference.psTextInsert levels := by
  funext chunk
  exact text_insert_applied_eq levels chunk

theorem text_builder_append_eq (builder : PsTextBuilder) (chunk : String) :
    psTextBuilderAppend builder chunk = PsTextLookupReference.psTextBuilderAppend builder chunk := by
  change PsTextBuilder.mk (psTextInsertApplied builder.levels chunk) =
    PsTextBuilder.mk (PsTextLookupReference.psTextInsert builder.levels chunk)
  rw [text_insert_applied_eq]

theorem text_join_applied_eq (separator : String) (values : List String)
    (first : Bool) (builder : PsTextBuilder) :
    psTextJoinApplied separator values first builder =
      PsTextLookupReference.psTextJoinWorker separator values first builder := by
  induction values generalizing first builder with
  | nil => rfl
  | cons value rest ih =>
      change psTextJoinApplied separator rest false
          (psTextBuilderAppend (if first then builder else psTextBuilderAppend builder separator) value) =
        PsTextLookupReference.psTextJoinWorker separator rest false
          (PsTextLookupReference.psTextBuilderAppend
            (if first then builder else PsTextLookupReference.psTextBuilderAppend builder separator) value)
      simp only [text_builder_append_eq]
      exact ih false _

theorem text_join_worker_eq (separator : String) (values : List String) :
    psTextJoinWorker separator values =
      PsTextLookupReference.psTextJoinWorker separator values := by
  funext first builder
  exact text_join_applied_eq separator values first builder

theorem text_join_public_eq (separator : String) (values : List String) :
    psTextJoin separator values = PsTextLookupReference.psTextJoin separator values :=
  text_join_applied_eq separator values true psTextBuilderEmpty

theorem ts_lookup_applied_eq (entries : List (String × String)) (name : String) :
    psTsLookupApplied entries name = PsTextLookupReference.psTsLookup entries name := by
  induction entries with
  | nil => rfl
  | cons entry rest ih =>
      rcases entry with ⟨key, value⟩
      change (if psStringEq key name then Option.some value else psTsLookupApplied rest name) =
        (if psStringEq key name then Option.some value else PsTextLookupReference.psTsLookup rest name)
      rw [ih]

theorem ts_lookup_public_eq (entries : List (String × String)) :
    psTsLookup entries = PsTextLookupReference.psTsLookup entries := by
  funext name
  exact ts_lookup_applied_eq entries name

#print axioms text_insert_applied_eq
#print axioms text_join_applied_eq
#print axioms ts_lookup_public_eq


theorem ts_name_visitor_worker_eq (fuel : Nat) (expr : PsVerifiedIrExpr) (name : String) :
    psTsExprUsesNameWithFuelWorker fuel expr name =
      PsTextLookupReference.psTsExprUsesNameWithFuel fuel expr name := by
  induction fuel generalizing expr name with
  | zero => rfl
  | succ remaining ih =>
      cases expr <;>
        simp only [psTsExprUsesNameWithFuelWorker,
          PsTextLookupReference.psTsExprUsesNameWithFuel, ih] <;> rfl

theorem ts_name_visitor_public_eq (fuel : Nat) :
    psTsExprUsesNameWithFuel fuel =
      PsTextLookupReference.psTsExprUsesNameWithFuel fuel := by
  funext expr name
  exact ts_name_visitor_worker_eq fuel expr name

#print axioms ts_name_visitor_worker_eq

def main : IO Unit := do
  for separator in ["", ",", "λ🙂"] do
    for values in [[], [""], ["a"], ["a","b","λ🙂"], ["","\\","\"","\n"]] do
      unless psStringEq (psTextJoin separator values)
          (PsTextLookupReference.psTextJoin separator values) do
        throw (IO.userError "join byte order or separator changed")
  for levels in [[], [none], [some "old"], [some "old",some "older"], [none,some "older"]] do
    for chunk in ["","x","λ🙂","\\\"\n"] do
      unless psTextInsert levels chunk == PsTextLookupReference.psTextInsert levels chunk do
        throw (IO.userError "text carrying changed")
  let suffix := List.replicate 100001 (some "old")
  match psTextInsert (none :: suffix) "head" with
  | some head :: rest =>
      unless psStringEq head "head" && rest.length == 100001 do
        throw (IO.userError "empty first level did not preserve suffix")
  | _ => throw (IO.userError "insert empty first level")
  let entries := [("same","first"),("same","later"),("λ🙂","unicode")]
  for name in ["same","λ🙂","missing",""] do
    unless psTsLookup entries name == PsTextLookupReference.psTsLookup entries name do
      throw (IO.userError "lookup first-binding behavior changed")
  unless psTsLookup (("head","value") :: List.replicate 100001 ("tail","later")) "head" == some "value" do
    throw (IO.userError "first lookup changed")
  let type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
  let value := PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 7)
  let expressions : List PsVerifiedIrExpr :=
    [value, .var "variable", .intrinsic .natAdd [] [.var "left",.var "right"],
     .lambda [PsVerifiedIrParameter.mk "binder" type] type (.var "body"),
     .call (.var "callee") [] [.var "argument"],
     .letE "local" type (.var "value") (.var "body"),
     .ifE (.var "condition") (.var "yes") (.var "no"),
     .record "Record" [] [("field",.var "fieldValue")],
     .projection "Record" [] (.var "target") "field",
     .constructor "Option" "some" [type] [("value",.var "contained")],
     .matchE "List" [type] (.var "scrutinee")
       [("cons",[PsVerifiedIrMatchBinding.mk "head" "bound" type],.var "branch")]]
  for fuel in [0,1,2,4,64] do
    for expr in expressions do
      for name in ["variable","binder","body","bound","condition","callee","missing","λ🙂"] do
        unless psTsExprUsesNameWithFuel fuel expr name ==
            PsTextLookupReference.psTsExprUsesNameWithFuel fuel expr name do
          throw (IO.userError "name visitor binder, fuel or short-circuit behavior changed")
  unless psTsExprUsesNameWithFuel 0 value "absent" do
    throw (IO.userError "name visitor must remain conservative at zero fuel")
  if psTsExprUsesNameWithFuel 100001 value "absent" then
    throw (IO.userError "literal name visitor changed")
  IO.println "PSC1_TEXT_LOOKUP_WORKERS: all-input insert/join/lookup/name-visitor and public helper equalities; Unicode/escaping/separators/first-duplicates;100001-entry first-slot exits"
