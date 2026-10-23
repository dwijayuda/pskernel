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

theorem quote_0 : psJsonQuote "a" = "\"a\"" := by decide

theorem quote_1 : psJsonQuote "s" = "\"s\"" := by decide

theorem quote_2 : psJsonQuote "n" = "\"n\"" := by decide

theorem quote_3 : psJsonQuote "z" = "\"z\"" := by decide

theorem quote_4 : psJsonQuote "max" = "\"max\"" := by decide

theorem quote_5 : psJsonQuote "imax" = "\"imax\"" := by decide

theorem quote_6 : psJsonQuote "p" = "\"p\"" := by decide

theorem quote_7 : psJsonQuote "b" = "\"b\"" := by decide

theorem quote_8 : psJsonQuote "sort" = "\"sort\"" := by decide

theorem quote_9 : psJsonQuote "const" = "\"const\"" := by decide

theorem quote_10 : psJsonQuote "app" = "\"app\"" := by decide

theorem quote_11 : psJsonQuote "lam" = "\"lam\"" := by decide

theorem quote_12 : psJsonQuote "forall" = "\"forall\"" := by decide

theorem quote_13 : psJsonQuote "let" = "\"let\"" := by decide

theorem quote_14 : psJsonQuote "nat" = "\"nat\"" := by decide

theorem quote_15 : psJsonQuote "str" = "\"str\"" := by decide

theorem quote_16 : psJsonQuote "proj" = "\"proj\"" := by decide

theorem quote_17 : psJsonQuote "e" = "\"e\"" := by decide

theorem quote_18 : psJsonQuote "i" = "\"i\"" := by decide

theorem quote_19 : psJsonQuote "k" = "\"k\"" := by decide

theorem quote_20 : psJsonQuote "v" = "\"v\"" := by decide

theorem quote_21 : psJsonQuote "t" = "\"t\"" := by decide

theorem quote_22 : psJsonQuote "bi" = "\"bi\"" := by decide

theorem quote_23 : psJsonQuote "f" = "\"f\"" := by decide

theorem quote_24 : psJsonQuote "ls" = "\"ls\"" := by decide

theorem quote_25 : psJsonQuote "l" = "\"l\"" := by decide

theorem quote_26 : psJsonQuote "r" = "\"r\"" := by decide

theorem quote_27 : psJsonQuote "o" = "\"o\"" := by decide

theorem schema_0 (v0 v1 v2 v3 : String) :
    psJsonObject [Prod.mk "e" v0, Prod.mk "i" v1, Prod.mk "k" v2, Prod.mk "n" v3] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append ("\"e\"") (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append (String.Internal.append ("\"i\"") (String.Internal.append (":") (v1))) (String.Internal.append (",") (String.Internal.append (String.Internal.append ("\"k\"") (String.Internal.append (":") (v2))) (String.Internal.append (",") (String.Internal.append ("\"n\"") (String.Internal.append (":") (v3))))))))) ("}")) := by
  simp only [psJsonObject, psJsonMapObjectFields, psJsonField, psJsonJoin,
    psJsonConcat3, psJsonConcat2, quote_0, quote_1, quote_2, quote_3, quote_4, quote_5, quote_6, quote_7, quote_8, quote_9, quote_10, quote_11, quote_12, quote_13, quote_14, quote_15, quote_16, quote_17, quote_18, quote_19, quote_20, quote_21, quote_22, quote_23, quote_24, quote_25, quote_26, quote_27]
  <;> rfl

theorem schema_1 (v0 v1 : String) :
    psJsonObject [Prod.mk "k" v0, Prod.mk "v" v1] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append ("\"k\"") (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append ("\"v\"") (String.Internal.append (":") (v1))))) ("}")) := by
  simp only [psJsonObject, psJsonMapObjectFields, psJsonField, psJsonJoin,
    psJsonConcat3, psJsonConcat2, quote_0, quote_1, quote_2, quote_3, quote_4, quote_5, quote_6, quote_7, quote_8, quote_9, quote_10, quote_11, quote_12, quote_13, quote_14, quote_15, quote_16, quote_17, quote_18, quote_19, quote_20, quote_21, quote_22, quote_23, quote_24, quote_25, quote_26, quote_27]
  <;> rfl

theorem schema_2 (v0 v1 v2 v3 v4 : String) :
    psJsonObject [Prod.mk "b" v0, Prod.mk "k" v1, Prod.mk "n" v2, Prod.mk "t" v3, Prod.mk "v" v4] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append ("\"b\"") (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append (String.Internal.append ("\"k\"") (String.Internal.append (":") (v1))) (String.Internal.append (",") (String.Internal.append (String.Internal.append ("\"n\"") (String.Internal.append (":") (v2))) (String.Internal.append (",") (String.Internal.append (String.Internal.append ("\"t\"") (String.Internal.append (":") (v3))) (String.Internal.append (",") (String.Internal.append ("\"v\"") (String.Internal.append (":") (v4))))))))))) ("}")) := by
  simp only [psJsonObject, psJsonMapObjectFields, psJsonField, psJsonJoin,
    psJsonConcat3, psJsonConcat2, quote_0, quote_1, quote_2, quote_3, quote_4, quote_5, quote_6, quote_7, quote_8, quote_9, quote_10, quote_11, quote_12, quote_13, quote_14, quote_15, quote_16, quote_17, quote_18, quote_19, quote_20, quote_21, quote_22, quote_23, quote_24, quote_25, quote_26, quote_27]
  <;> rfl

theorem schema_3 (v0 v1 v2 v3 v4 : String) :
    psJsonObject [Prod.mk "b" v0, Prod.mk "bi" v1, Prod.mk "k" v2, Prod.mk "n" v3, Prod.mk "t" v4] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append ("\"b\"") (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append (String.Internal.append ("\"bi\"") (String.Internal.append (":") (v1))) (String.Internal.append (",") (String.Internal.append (String.Internal.append ("\"k\"") (String.Internal.append (":") (v2))) (String.Internal.append (",") (String.Internal.append (String.Internal.append ("\"n\"") (String.Internal.append (":") (v3))) (String.Internal.append (",") (String.Internal.append ("\"t\"") (String.Internal.append (":") (v4))))))))))) ("}")) := by
  simp only [psJsonObject, psJsonMapObjectFields, psJsonField, psJsonJoin,
    psJsonConcat3, psJsonConcat2, quote_0, quote_1, quote_2, quote_3, quote_4, quote_5, quote_6, quote_7, quote_8, quote_9, quote_10, quote_11, quote_12, quote_13, quote_14, quote_15, quote_16, quote_17, quote_18, quote_19, quote_20, quote_21, quote_22, quote_23, quote_24, quote_25, quote_26, quote_27]
  <;> rfl

theorem schema_4 (v0 v1 v2 : String) :
    psJsonObject [Prod.mk "a" v0, Prod.mk "f" v1, Prod.mk "k" v2] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append ("\"a\"") (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append (String.Internal.append ("\"f\"") (String.Internal.append (":") (v1))) (String.Internal.append (",") (String.Internal.append ("\"k\"") (String.Internal.append (":") (v2))))))) ("}")) := by
  simp only [psJsonObject, psJsonMapObjectFields, psJsonField, psJsonJoin,
    psJsonConcat3, psJsonConcat2, quote_0, quote_1, quote_2, quote_3, quote_4, quote_5, quote_6, quote_7, quote_8, quote_9, quote_10, quote_11, quote_12, quote_13, quote_14, quote_15, quote_16, quote_17, quote_18, quote_19, quote_20, quote_21, quote_22, quote_23, quote_24, quote_25, quote_26, quote_27]
  <;> rfl

theorem schema_5 (v0 v1 v2 : String) :
    psJsonObject [Prod.mk "k" v0, Prod.mk "ls" v1, Prod.mk "n" v2] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append ("\"k\"") (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append (String.Internal.append ("\"ls\"") (String.Internal.append (":") (v1))) (String.Internal.append (",") (String.Internal.append ("\"n\"") (String.Internal.append (":") (v2))))))) ("}")) := by
  simp only [psJsonObject, psJsonMapObjectFields, psJsonField, psJsonJoin,
    psJsonConcat3, psJsonConcat2, quote_0, quote_1, quote_2, quote_3, quote_4, quote_5, quote_6, quote_7, quote_8, quote_9, quote_10, quote_11, quote_12, quote_13, quote_14, quote_15, quote_16, quote_17, quote_18, quote_19, quote_20, quote_21, quote_22, quote_23, quote_24, quote_25, quote_26, quote_27]
  <;> rfl

theorem schema_6 (v0 v1 : String) :
    psJsonObject [Prod.mk "k" v0, Prod.mk "l" v1] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append ("\"k\"") (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append ("\"l\"") (String.Internal.append (":") (v1))))) ("}")) := by
  simp only [psJsonObject, psJsonMapObjectFields, psJsonField, psJsonJoin,
    psJsonConcat3, psJsonConcat2, quote_0, quote_1, quote_2, quote_3, quote_4, quote_5, quote_6, quote_7, quote_8, quote_9, quote_10, quote_11, quote_12, quote_13, quote_14, quote_15, quote_16, quote_17, quote_18, quote_19, quote_20, quote_21, quote_22, quote_23, quote_24, quote_25, quote_26, quote_27]
  <;> rfl

theorem schema_7 (v0 v1 : String) :
    psJsonObject [Prod.mk "i" v0, Prod.mk "k" v1] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append ("\"i\"") (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append ("\"k\"") (String.Internal.append (":") (v1))))) ("}")) := by
  simp only [psJsonObject, psJsonMapObjectFields, psJsonField, psJsonJoin,
    psJsonConcat3, psJsonConcat2, quote_0, quote_1, quote_2, quote_3, quote_4, quote_5, quote_6, quote_7, quote_8, quote_9, quote_10, quote_11, quote_12, quote_13, quote_14, quote_15, quote_16, quote_17, quote_18, quote_19, quote_20, quote_21, quote_22, quote_23, quote_24, quote_25, quote_26, quote_27]
  <;> rfl

theorem schema_8 (v0 v1 : String) :
    psJsonObject [Prod.mk "k" v0, Prod.mk "n" v1] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append ("\"k\"") (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append ("\"n\"") (String.Internal.append (":") (v1))))) ("}")) := by
  simp only [psJsonObject, psJsonMapObjectFields, psJsonField, psJsonJoin,
    psJsonConcat3, psJsonConcat2, quote_0, quote_1, quote_2, quote_3, quote_4, quote_5, quote_6, quote_7, quote_8, quote_9, quote_10, quote_11, quote_12, quote_13, quote_14, quote_15, quote_16, quote_17, quote_18, quote_19, quote_20, quote_21, quote_22, quote_23, quote_24, quote_25, quote_26, quote_27]
  <;> rfl

theorem schema_9 (v0 v1 v2 : String) :
    psJsonObject [Prod.mk "k" v0, Prod.mk "l" v1, Prod.mk "r" v2] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append ("\"k\"") (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append (String.Internal.append ("\"l\"") (String.Internal.append (":") (v1))) (String.Internal.append (",") (String.Internal.append ("\"r\"") (String.Internal.append (":") (v2))))))) ("}")) := by
  simp only [psJsonObject, psJsonMapObjectFields, psJsonField, psJsonJoin,
    psJsonConcat3, psJsonConcat2, quote_0, quote_1, quote_2, quote_3, quote_4, quote_5, quote_6, quote_7, quote_8, quote_9, quote_10, quote_11, quote_12, quote_13, quote_14, quote_15, quote_16, quote_17, quote_18, quote_19, quote_20, quote_21, quote_22, quote_23, quote_24, quote_25, quote_26, quote_27]
  <;> rfl

theorem schema_10 (v0 v1 : String) :
    psJsonObject [Prod.mk "k" v0, Prod.mk "o" v1] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append ("\"k\"") (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append ("\"o\"") (String.Internal.append (":") (v1))))) ("}")) := by
  simp only [psJsonObject, psJsonMapObjectFields, psJsonField, psJsonJoin,
    psJsonConcat3, psJsonConcat2, quote_0, quote_1, quote_2, quote_3, quote_4, quote_5, quote_6, quote_7, quote_8, quote_9, quote_10, quote_11, quote_12, quote_13, quote_14, quote_15, quote_16, quote_17, quote_18, quote_19, quote_20, quote_21, quote_22, quote_23, quote_24, quote_25, quote_26, quote_27]
  <;> rfl

theorem schema_11 (v0 : String) :
    psJsonObject [Prod.mk "k" v0] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append ("\"k\"") (String.Internal.append (":") (v0))) ("}")) := by
  simp only [psJsonObject, psJsonMapObjectFields, psJsonField, psJsonJoin,
    psJsonConcat3, psJsonConcat2, quote_0, quote_1, quote_2, quote_3, quote_4, quote_5, quote_6, quote_7, quote_8, quote_9, quote_10, quote_11, quote_12, quote_13, quote_14, quote_15, quote_16, quote_17, quote_18, quote_19, quote_20, quote_21, quote_22, quote_23, quote_24, quote_25, quote_26, quote_27]
  <;> rfl

theorem schema_12 (v0 v1 v2 : String) :
    psJsonObject [Prod.mk "k" v0, Prod.mk "p" v1, Prod.mk "v" v2] =
      String.Internal.append ("{") (String.Internal.append (String.Internal.append (String.Internal.append ("\"k\"") (String.Internal.append (":") (v0))) (String.Internal.append (",") (String.Internal.append (String.Internal.append ("\"p\"") (String.Internal.append (":") (v1))) (String.Internal.append (",") (String.Internal.append ("\"v\"") (String.Internal.append (":") (v2))))))) ("}")) := by
  simp only [psJsonObject, psJsonMapObjectFields, psJsonField, psJsonJoin,
    psJsonConcat3, psJsonConcat2, quote_0, quote_1, quote_2, quote_3, quote_4, quote_5, quote_6, quote_7, quote_8, quote_9, quote_10, quote_11, quote_12, quote_13, quote_14, quote_15, quote_16, quote_17, quote_18, quote_19, quote_20, quote_21, quote_22, quote_23, quote_24, quote_25, quote_26, quote_27]
  <;> rfl

theorem name_eq (value : PsName) :
    PsCodecStaticReference.psEncodeCodecName value = psEncodeCodecName value := by
  induction value <;>
    simp_all only [PsCodecStaticReference.psEncodeCodecName, psEncodeCodecName, psJsonObject, psJsonMapObjectFields, psJsonField, psJsonJoin,
      psJsonConcat3, psJsonConcat2, psCheckedAdmissionJsonField, quote_0, quote_1, quote_2, quote_3, quote_4, quote_5, quote_6, quote_7, quote_8, quote_9, quote_10, quote_11, quote_12, quote_13, quote_14, quote_15, quote_16, quote_17, quote_18, quote_19, quote_20, quote_21, quote_22, quote_23, quote_24, quote_25, quote_26, quote_27] <;> rfl

theorem level_eq (value : PsLevel) :
    PsCodecStaticReference.psEncodeCodecLevel value = psEncodeCodecLevel value := by
  induction value <;>
    simp_all only [PsCodecStaticReference.psEncodeCodecLevel, psEncodeCodecLevel, name_eq, psJsonObject, psJsonMapObjectFields, psJsonField, psJsonJoin,
      psJsonConcat3, psJsonConcat2, psCheckedAdmissionJsonField, quote_0, quote_1, quote_2, quote_3, quote_4, quote_5, quote_6, quote_7, quote_8, quote_9, quote_10, quote_11, quote_12, quote_13, quote_14, quote_15, quote_16, quote_17, quote_18, quote_19, quote_20, quote_21, quote_22, quote_23, quote_24, quote_25, quote_26, quote_27] <;> rfl

theorem level_list_eq (values : List PsLevel) :
    PsCodecStaticReference.psEncodeCodecLevelList values = psEncodeCodecLevelList values := by
  induction values <;>
    simp_all only [PsCodecStaticReference.psEncodeCodecLevelList, psEncodeCodecLevelList, level_eq] <;> rfl

theorem levels_eq (values : List PsLevel) :
    PsCodecStaticReference.psEncodeCodecLevels values = psEncodeCodecLevels values := by
  simp only [PsCodecStaticReference.psEncodeCodecLevels, psEncodeCodecLevels, level_list_eq]
  <;> rfl

theorem expr_eq (value : PsExpr) :
    PsCodecStaticReference.psEncodeCodecExpr value = psEncodeCodecExpr value := by
  induction value <;>
    simp_all only [PsCodecStaticReference.psEncodeCodecExpr, psEncodeCodecExpr,
      name_eq, level_eq, levels_eq, PsCodecStaticReference.psEncodeCodecBinderInfo,
      psEncodeCodecBinderInfo, psJsonObject, psJsonMapObjectFields, psJsonField, psJsonJoin,
      psJsonConcat3, psJsonConcat2, psCheckedAdmissionJsonField, quote_0, quote_1, quote_2, quote_3, quote_4, quote_5, quote_6, quote_7, quote_8, quote_9, quote_10, quote_11, quote_12, quote_13, quote_14, quote_15, quote_16, quote_17, quote_18, quote_19, quote_20, quote_21, quote_22, quote_23, quote_24, quote_25, quote_26, quote_27] <;> rfl

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
