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
  IO.println "PSC1_TEXT_LOOKUP_WORKERS: all-input insert/join/lookup and public helper equalities; Unicode/escaping/separators/first-duplicates;100001-entry first-slot exits"
