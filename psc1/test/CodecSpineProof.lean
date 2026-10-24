import CodecSpineReference
import Lean

set_option maxRecDepth 10000
set_option maxHeartbeats 8000000

private theorem codec_insert_finish (levels : List (Option String)) (chunk : String) :
    psTextFinish (psTextInsertApplied levels chunk) =
      String.Internal.append (psTextFinish levels) chunk := by
  induction levels generalizing chunk with
  | nil => simp [psTextInsertApplied, psTextFinish, String.Internal.append]
  | cons level rest ih =>
      cases level <;> simp [psTextInsertApplied, psTextFinish, ih, String.Internal.append, String.append_assoc]

private theorem codec_builder_append (builder : PsTextBuilder) (chunk : String) :
    psTextBuilderFinish (psTextBuilderAppend builder chunk) =
      String.Internal.append (psTextBuilderFinish builder) chunk :=
  codec_insert_finish builder.levels chunk

private theorem codec_chunks_finish (chunks : List String) (builder : PsTextBuilder) :
    psCodecExprAppendChunks chunks builder =
      String.Internal.append (psTextBuilderFinish builder)
        (chunks.foldr String.Internal.append "") := by
  induction chunks generalizing builder with
  | nil => simp [psCodecExprAppendChunks, String.Internal.append]
  | cons chunk rest ih =>
      simp [psCodecExprAppendChunks, ih, codec_builder_append, String.Internal.append, String.append_assoc]

private def codec_result (builder : PsTextBuilder)
    (value : Except PsCheckedAdmissionCodecError String)
    (suffix : Except PsCheckedAdmissionCodecError (List String)) :
    Except PsCheckedAdmissionCodecError String :=
  match value with
  | .error error => .error error
  | .ok text =>
      match suffix with
      | .error error => .error error
      | .ok chunks =>
          .ok (psTextBuilderFinish builder ++ text ++ chunks.foldr String.Internal.append "")

theorem codec_spine_acc_eq (value : PsExpr) (builder : PsTextBuilder)
    (suffix : Except PsCheckedAdmissionCodecError (List String)) :
    psEncodeCodecExprAcc value builder suffix =
      codec_result builder (PsCodecSpineReference.psEncodeCodecExpr value) suffix := by
  induction value generalizing builder suffix <;>
    simp only [psEncodeCodecExprAcc, PsCodecSpineReference.psEncodeCodecExpr]
  all_goals
    repeat' first
      | progress simp_all only [codec_result, psCodecExprFinish, psCodecExprSuffix,
          codec_chunks_finish, codec_builder_append, psTextBuilderEmpty,
          psTextBuilderFinish, psTextFinish, List.foldr,
          psJsonObject, psJsonMapObjectFields, psJsonField, psJsonJoin,
          psJsonConcat2, psJsonConcat3, psCheckedAdmissionJsonField,
          psCodecQuotedA, psCodecQuotedS, psCodecQuotedN, psCodecQuotedZ,
          psCodecQuotedMax, psCodecQuotedImax, psCodecQuotedP, psCodecQuotedB,
          psCodecQuotedSort, psCodecQuotedConst, psCodecQuotedApp, psCodecQuotedLam,
          psCodecQuotedForall, psCodecQuotedLet, psCodecQuotedNat, psCodecQuotedStr,
          psCodecQuotedProj, psCodecQuotedE, psCodecQuotedI, psCodecQuotedK,
          psCodecQuotedV, psCodecQuotedT, psCodecQuotedBi, psCodecQuotedF,
          psCodecQuotedLs, psCodecQuotedL, psCodecQuotedR, psCodecQuotedO,
          String.Internal.append, String.append_assoc, String.empty_append, String.append_empty]
      | split
      | rfl

theorem codec_spine_eq (value : PsExpr) :
    psEncodeCodecExpr value = PsCodecSpineReference.psEncodeCodecExpr value := by
  simpa [psEncodeCodecExpr, codec_result, psTextBuilderEmpty,
    psTextBuilderFinish, psTextFinish, String.Internal.append] using
    codec_spine_acc_eq value psTextBuilderEmpty (.ok [])

#print axioms codec_spine_acc_eq
#print axioms codec_spine_eq
