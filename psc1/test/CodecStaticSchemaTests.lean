import Ps.Bridge.CheckedAdmissions
import Lean.Data.Json

namespace PsCodecStaticReference
def psEncodeCodecName (name : PsName) : String :=
  match name with
  | .anonymous =>
      psJsonObject [
        Prod.mk "k" (psJsonQuote "a")
      ]
  | .str parent value =>
      let encodedParent : String :=
        psEncodeCodecName parent;
      psJsonObject [
        psCheckedAdmissionJsonField "k" (psJsonQuote "s"),
        psCheckedAdmissionJsonField "p" encodedParent,
        psCheckedAdmissionJsonField "v" (psJsonQuote value)
      ]
  | .num parent value =>
      let encodedParent : String :=
        psEncodeCodecName parent;
      psJsonObject [
        psCheckedAdmissionJsonField "k" (psJsonQuote "n"),
        psCheckedAdmissionJsonField "p" encodedParent,
        psCheckedAdmissionJsonField "v" (psJsonQuote (psCheckedAdmissionNatToString value))
      ]

def psEncodeCodecLevel
    (level : PsLevel) :
    Except PsCheckedAdmissionCodecError String :=
  match level with
  | .zero =>
      Except.ok
        (psJsonObject [
          psCheckedAdmissionJsonField "k" (psJsonQuote "z")
        ])
  | .succ inner =>
      match psEncodeCodecLevel inner with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "k" (psJsonQuote "s"),
              psCheckedAdmissionJsonField "o" (encoded)
            ])
  | .max left right =>
      match psEncodeCodecLevel left with
      | Except.error error => Except.error error
      | Except.ok encodedLeft =>
          match psEncodeCodecLevel right with
          | Except.error error => Except.error error
          | Except.ok encodedRight =>
              Except.ok
                (psJsonObject [
                  psCheckedAdmissionJsonField "k" (psJsonQuote "max"),
                  psCheckedAdmissionJsonField "l" (encodedLeft),
                  psCheckedAdmissionJsonField "r" (encodedRight)
                ])
  | .imax left right =>
      match psEncodeCodecLevel left with
      | Except.error error => Except.error error
      | Except.ok encodedLeft =>
          match psEncodeCodecLevel right with
          | Except.error error => Except.error error
          | Except.ok encodedRight =>
              Except.ok
                (psJsonObject [
                  psCheckedAdmissionJsonField "k" (psJsonQuote "imax"),
                  psCheckedAdmissionJsonField "l" (encodedLeft),
                  psCheckedAdmissionJsonField "r" (encodedRight)
                ])
  | .param name =>
      Except.ok
        (psJsonObject [
          psCheckedAdmissionJsonField "k" (psJsonQuote "p"),
          psCheckedAdmissionJsonField "n" (psEncodeCodecName name)
        ])
  | .mvar _ =>
      Except.error PsCheckedAdmissionCodecError.universeMetavariable

def psEncodeCodecBinderInfo (binder : PsBinderInfo) : String :=
  match binder with
  | .explicit => "default"
  | .implicit => "implicit"
  | .strictImplicit => "strictImplicit"
  | .instanceImplicit => "instImplicit"

def psEncodeCodecLevelList
    (levels : List PsLevel) :
    Except PsCheckedAdmissionCodecError (List String) :=
  match levels with
  | List.nil =>
      Except.ok List.nil
  | List.cons level rest =>
      match psEncodeCodecLevel level with
      | Except.error error =>
          Except.error error
      | Except.ok encodedHead =>
          match psEncodeCodecLevelList rest with
          | Except.error error =>
              Except.error error
          | Except.ok encodedTail =>
              Except.ok (List.cons encodedHead encodedTail)

def psEncodeCodecLevels
    (levels : List PsLevel) :
    Except PsCheckedAdmissionCodecError String :=
  match psEncodeCodecLevelList levels with
  | Except.error error => Except.error error
  | Except.ok encoded => Except.ok (psJsonArray encoded)

def psEncodeCodecExpr
    (expr : PsExpr) :
    Except PsCheckedAdmissionCodecError String :=
  match expr with
  | .bvar index =>
      Except.ok
        (psJsonObject [
          psCheckedAdmissionJsonField "i" (psCheckedAdmissionNatToString index),
          psCheckedAdmissionJsonField "k" (psJsonQuote "b")
        ])
  | .fvar _ =>
      Except.error PsCheckedAdmissionCodecError.freeVariable
  | .mvar _ =>
      Except.error PsCheckedAdmissionCodecError.expressionMetavariable
  | .sortE level =>
      match psEncodeCodecLevel level with
      | Except.error error => Except.error error
      | Except.ok encodedLevel =>
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "k" (psJsonQuote "sort"),
              psCheckedAdmissionJsonField "l" (encodedLevel)
            ])
  | .constE name levels =>
      match psEncodeCodecLevels levels with
      | Except.error error => Except.error error
      | Except.ok encodedLevels =>
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "k" (psJsonQuote "const"),
              psCheckedAdmissionJsonField "ls" (encodedLevels),
              psCheckedAdmissionJsonField "n" (psEncodeCodecName name)
            ])
  | .app fn arg =>
      match psEncodeCodecExpr arg with
      | Except.error error => Except.error error
      | Except.ok encodedArg =>
          match psEncodeCodecExpr fn with
          | Except.error error => Except.error error
          | Except.ok encodedFn =>
              Except.ok
                (psJsonObject [
                  psCheckedAdmissionJsonField "a" (encodedArg),
                  psCheckedAdmissionJsonField "f" (encodedFn),
                  psCheckedAdmissionJsonField "k" (psJsonQuote "app")
                ])
  | .lam name type body binder =>
      match psEncodeCodecExpr body with
      | Except.error error => Except.error error
      | Except.ok encodedBody =>
          match psEncodeCodecExpr type with
          | Except.error error => Except.error error
          | Except.ok encodedType =>
              Except.ok
                (psJsonObject [
                  psCheckedAdmissionJsonField "b" (encodedBody),
                  psCheckedAdmissionJsonField "bi" (psJsonQuote (psEncodeCodecBinderInfo binder)),
                  psCheckedAdmissionJsonField "k" (psJsonQuote "lam"),
                  psCheckedAdmissionJsonField "n" (psEncodeCodecName name),
                  psCheckedAdmissionJsonField "t" (encodedType)
                ])
  | .forallE name type body binder =>
      match psEncodeCodecExpr body with
      | Except.error error => Except.error error
      | Except.ok encodedBody =>
          match psEncodeCodecExpr type with
          | Except.error error => Except.error error
          | Except.ok encodedType =>
              Except.ok
                (psJsonObject [
                  psCheckedAdmissionJsonField "b" (encodedBody),
                  psCheckedAdmissionJsonField "bi" (psJsonQuote (psEncodeCodecBinderInfo binder)),
                  psCheckedAdmissionJsonField "k" (psJsonQuote "forall"),
                  psCheckedAdmissionJsonField "n" (psEncodeCodecName name),
                  psCheckedAdmissionJsonField "t" (encodedType)
                ])
  | .letE name type value body =>
      match psEncodeCodecExpr body with
      | Except.error error => Except.error error
      | Except.ok encodedBody =>
          match psEncodeCodecExpr type with
          | Except.error error => Except.error error
          | Except.ok encodedType =>
              match psEncodeCodecExpr value with
              | Except.error error => Except.error error
              | Except.ok encodedValue =>
                  Except.ok
                    (psJsonObject [
                      psCheckedAdmissionJsonField "b" (encodedBody),
                      psCheckedAdmissionJsonField "k" (psJsonQuote "let"),
                      psCheckedAdmissionJsonField "n" (psEncodeCodecName name),
                      psCheckedAdmissionJsonField "t" (encodedType),
                      psCheckedAdmissionJsonField "v" (encodedValue)
                    ])
  | .lit literal =>
      match literal with
      | .natural value =>
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "k" (psJsonQuote "nat"),
              psCheckedAdmissionJsonField "v" (psJsonQuote (psCheckedAdmissionNatToString value))
            ])
      | .string value =>
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "k" (psJsonQuote "str"),
              psCheckedAdmissionJsonField "v" (psJsonQuote value)
            ])
  | .proj typeName index value =>
      match psEncodeCodecExpr value with
      | Except.error error => Except.error error
      | Except.ok encodedValue =>
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "e" (encodedValue),
              psCheckedAdmissionJsonField "i" (psCheckedAdmissionNatToString index),
              psCheckedAdmissionJsonField "k" (psJsonQuote "proj"),
              psCheckedAdmissionJsonField "n" (psEncodeCodecName typeName)
            ])
end PsCodecStaticReference

namespace PsCodecStaticProof

theorem quote_0 : psCodecQuotedA = psJsonQuote "a" := by rfl

theorem quote_1 : psCodecQuotedS = psJsonQuote "s" := by rfl

theorem quote_2 : psCodecQuotedN = psJsonQuote "n" := by rfl

theorem quote_3 : psCodecQuotedZ = psJsonQuote "z" := by rfl

theorem quote_4 : psCodecQuotedMax = psJsonQuote "max" := by rfl

theorem quote_5 : psCodecQuotedImax = psJsonQuote "imax" := by rfl

theorem quote_6 : psCodecQuotedP = psJsonQuote "p" := by rfl

theorem quote_7 : psCodecQuotedB = psJsonQuote "b" := by rfl

theorem quote_8 : psCodecQuotedSort = psJsonQuote "sort" := by rfl

theorem quote_9 : psCodecQuotedConst = psJsonQuote "const" := by rfl

theorem quote_10 : psCodecQuotedApp = psJsonQuote "app" := by rfl

theorem quote_11 : psCodecQuotedLam = psJsonQuote "lam" := by rfl

theorem quote_12 : psCodecQuotedForall = psJsonQuote "forall" := by rfl

theorem quote_13 : psCodecQuotedLet = psJsonQuote "let" := by rfl

theorem quote_14 : psCodecQuotedNat = psJsonQuote "nat" := by rfl

theorem quote_15 : psCodecQuotedStr = psJsonQuote "str" := by rfl

theorem quote_16 : psCodecQuotedProj = psJsonQuote "proj" := by rfl

theorem quote_17 : psCodecQuotedE = psJsonQuote "e" := by rfl

theorem quote_18 : psCodecQuotedI = psJsonQuote "i" := by rfl

theorem quote_19 : psCodecQuotedK = psJsonQuote "k" := by rfl

theorem quote_20 : psCodecQuotedV = psJsonQuote "v" := by rfl

theorem quote_21 : psCodecQuotedT = psJsonQuote "t" := by rfl

theorem quote_22 : psCodecQuotedBi = psJsonQuote "bi" := by rfl

theorem quote_23 : psCodecQuotedF = psJsonQuote "f" := by rfl

theorem quote_24 : psCodecQuotedLs = psJsonQuote "ls" := by rfl

theorem quote_25 : psCodecQuotedL = psJsonQuote "l" := by rfl

theorem quote_26 : psCodecQuotedR = psJsonQuote "r" := by rfl

theorem quote_27 : psCodecQuotedO = psJsonQuote "o" := by rfl

theorem schema_0 (v0 v1 v2 v3 : String) :
    psJsonObject [Prod.mk "e" v0, Prod.mk "i" v1, Prod.mk "k" v2, Prod.mk "n" v3] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedE) (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedI) (String.Internal.append (":") (v1))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") (v2))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedN) (String.Internal.append (":") (v3))))))))) ("}")) := by rfl

theorem schema_1 (v0 v1 : String) :
    psJsonObject [Prod.mk "k" v0, Prod.mk "v" v1] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedV) (String.Internal.append (":") (v1))))) ("}")) := by rfl

theorem schema_2 (v0 v1 v2 v3 v4 : String) :
    psJsonObject [Prod.mk "b" v0, Prod.mk "k" v1, Prod.mk "n" v2, Prod.mk "t" v3, Prod.mk "v" v4] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedB) (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") (v1))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedN) (String.Internal.append (":") (v2))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedT) (String.Internal.append (":") (v3))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedV) (String.Internal.append (":") (v4))))))))))) ("}")) := by rfl

theorem schema_3 (v0 v1 v2 v3 v4 : String) :
    psJsonObject [Prod.mk "b" v0, Prod.mk "bi" v1, Prod.mk "k" v2, Prod.mk "n" v3, Prod.mk "t" v4] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedB) (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedBi) (String.Internal.append (":") (v1))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") (v2))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedN) (String.Internal.append (":") (v3))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedT) (String.Internal.append (":") (v4))))))))))) ("}")) := by rfl

theorem schema_4 (v0 v1 v2 : String) :
    psJsonObject [Prod.mk "a" v0, Prod.mk "f" v1, Prod.mk "k" v2] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedA) (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedF) (String.Internal.append (":") (v1))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") (v2))))))) ("}")) := by rfl

theorem schema_5 (v0 v1 v2 : String) :
    psJsonObject [Prod.mk "k" v0, Prod.mk "ls" v1, Prod.mk "n" v2] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedLs) (String.Internal.append (":") (v1))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedN) (String.Internal.append (":") (v2))))))) ("}")) := by rfl

theorem schema_6 (v0 v1 : String) :
    psJsonObject [Prod.mk "k" v0, Prod.mk "l" v1] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedL) (String.Internal.append (":") (v1))))) ("}")) := by rfl

theorem schema_7 (v0 v1 : String) :
    psJsonObject [Prod.mk "i" v0, Prod.mk "k" v1] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedI) (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") (v1))))) ("}")) := by rfl

theorem schema_8 (v0 v1 : String) :
    psJsonObject [Prod.mk "k" v0, Prod.mk "n" v1] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedN) (String.Internal.append (":") (v1))))) ("}")) := by rfl

theorem schema_9 (v0 v1 v2 : String) :
    psJsonObject [Prod.mk "k" v0, Prod.mk "l" v1, Prod.mk "r" v2] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedL) (String.Internal.append (":") (v1))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedR) (String.Internal.append (":") (v2))))))) ("}")) := by rfl

theorem schema_10 (v0 v1 : String) :
    psJsonObject [Prod.mk "k" v0, Prod.mk "o" v1] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedO) (String.Internal.append (":") (v1))))) ("}")) := by rfl

theorem schema_11 (v0 : String) :
    psJsonObject [Prod.mk "k" v0] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") (v0))) ("}")) := by rfl

theorem schema_12 (v0 v1 v2 : String) :
    psJsonObject [Prod.mk "k" v0, Prod.mk "p" v1, Prod.mk "v" v2] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append (psCodecQuotedK) (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append (String.Internal.append (psCodecQuotedP) (String.Internal.append (":") (v1))) (String.Internal.append (",") (String.Internal.append (psCodecQuotedV) (String.Internal.append (":") (v2))))))) ("}")) := by rfl

theorem name_eq (value : PsName) :
    PsCodecStaticReference.psEncodeCodecName value = psEncodeCodecName value := by
  induction value <;>
    simp_all only [PsCodecStaticReference.psEncodeCodecName, psEncodeCodecName, psJsonObject, psJsonMapObjectFields, psJsonField, psJsonJoin,
      psJsonConcat3, psJsonConcat2, psCheckedAdmissionJsonField, psCodecQuotedA, psCodecQuotedS, psCodecQuotedN, psCodecQuotedZ, psCodecQuotedMax, psCodecQuotedImax, psCodecQuotedP, psCodecQuotedB, psCodecQuotedSort, psCodecQuotedConst, psCodecQuotedApp, psCodecQuotedLam, psCodecQuotedForall, psCodecQuotedLet, psCodecQuotedNat, psCodecQuotedStr, psCodecQuotedProj, psCodecQuotedE, psCodecQuotedI, psCodecQuotedK, psCodecQuotedV, psCodecQuotedT, psCodecQuotedBi, psCodecQuotedF, psCodecQuotedLs, psCodecQuotedL, psCodecQuotedR, psCodecQuotedO] <;> rfl

theorem level_eq (value : PsLevel) :
    PsCodecStaticReference.psEncodeCodecLevel value = psEncodeCodecLevel value := by
  induction value <;>
    simp_all only [PsCodecStaticReference.psEncodeCodecLevel, psEncodeCodecLevel, name_eq, psJsonObject, psJsonMapObjectFields, psJsonField, psJsonJoin,
      psJsonConcat3, psJsonConcat2, psCheckedAdmissionJsonField, psCodecQuotedA, psCodecQuotedS, psCodecQuotedN, psCodecQuotedZ, psCodecQuotedMax, psCodecQuotedImax, psCodecQuotedP, psCodecQuotedB, psCodecQuotedSort, psCodecQuotedConst, psCodecQuotedApp, psCodecQuotedLam, psCodecQuotedForall, psCodecQuotedLet, psCodecQuotedNat, psCodecQuotedStr, psCodecQuotedProj, psCodecQuotedE, psCodecQuotedI, psCodecQuotedK, psCodecQuotedV, psCodecQuotedT, psCodecQuotedBi, psCodecQuotedF, psCodecQuotedLs, psCodecQuotedL, psCodecQuotedR, psCodecQuotedO] <;> rfl

theorem level_list_eq (values : List PsLevel) :
    PsCodecStaticReference.psEncodeCodecLevelList values = psEncodeCodecLevelList values := by
  induction values <;>
    simp_all only [PsCodecStaticReference.psEncodeCodecLevelList, psEncodeCodecLevelList, level_eq] <;> rfl

theorem levels_eq (values : List PsLevel) :
    PsCodecStaticReference.psEncodeCodecLevels values = psEncodeCodecLevels values := by
  simp only [PsCodecStaticReference.psEncodeCodecLevels, psEncodeCodecLevels, level_list_eq]
  all_goals rfl

theorem expr_eq (value : PsExpr) :
    PsCodecStaticReference.psEncodeCodecExpr value = psEncodeCodecExpr value := by
  induction value <;>
    simp_all only [PsCodecStaticReference.psEncodeCodecExpr, psEncodeCodecExpr,
      name_eq, level_eq, levels_eq, PsCodecStaticReference.psEncodeCodecBinderInfo,
      psEncodeCodecBinderInfo, psJsonObject, psJsonMapObjectFields, psJsonField, psJsonJoin,
      psJsonConcat3, psJsonConcat2, psCheckedAdmissionJsonField, psCodecQuotedA, psCodecQuotedS, psCodecQuotedN, psCodecQuotedZ, psCodecQuotedMax, psCodecQuotedImax, psCodecQuotedP, psCodecQuotedB, psCodecQuotedSort, psCodecQuotedConst, psCodecQuotedApp, psCodecQuotedLam, psCodecQuotedForall, psCodecQuotedLet, psCodecQuotedNat, psCodecQuotedStr, psCodecQuotedProj, psCodecQuotedE, psCodecQuotedI, psCodecQuotedK, psCodecQuotedV, psCodecQuotedT, psCodecQuotedBi, psCodecQuotedF, psCodecQuotedLs, psCodecQuotedL, psCodecQuotedR, psCodecQuotedO] <;> rfl

#print axioms name_eq
#print axioms level_eq
#print axioms expr_eq
end PsCodecStaticProof

private def require (condition : Bool) (label : String) : IO Unit := do
  if !condition then throw (IO.userError ("PSC1_CODEC_STATIC_FAIL: " ++ label))

def main : IO Unit := do
  let name := PsName.str (PsName.num PsName.anonymous 7) "λ\\\"🙂"
  let base : PsExpr := .constE name [.zero, .param name, .succ .zero]
  let values : List PsExpr := [
    .bvar 3, .sortE (.max (.succ .zero) (.param name)), base,
    .app base (.lit (.string "\\\"\\\\\\nλ🙂")),
    .lam name base (.bvar 0) .explicit, .forallE name base (.bvar 0) .implicit,
    .letE name base (.lit (.natural 42)) (.bvar 0), .proj name 0 base]
  for value in values do
    match psEncodeCodecExpr value, PsCodecStaticReference.psEncodeCodecExpr value with
    | .ok actual, .ok expected =>
        require (actual == expected) "legacy bytes"
        match Lean.Json.parse actual with
        | .error error => throw (IO.userError error)
        | .ok _ => pure ()
    | _, _ => throw (IO.userError "PSC1_CODEC_STATIC_UNEXPECTED_REFUSAL")
  match psEncodeCodecExpr (.app (.fvar 1) (.mvar 2)) with
  | .error .expressionMetavariable => pure ()
  | _ => throw (IO.userError "PSC1_CODEC_STATIC_ERROR_ORDER")
  IO.println "PSC1_CODEC_STATIC: all-name/level/list/expression exact equality proved; schema/quote reductions checked; legacy bytes, Unicode, independent JSON parse and refusal order passed"
