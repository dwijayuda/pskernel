import CodecSpineReference
import Lean

set_option maxRecDepth 10000
set_option maxHeartbeats 8000000

-- Exact equality includes refusal priority and the opaque String append tree.
-- No associativity assumption, new axiom, admission shortcut or fuel bound.
theorem codec_spine_acc_eq (value : PsExpr) (frames : List PsCodecExprFrame) :
    psEncodeCodecExprAcc value frames =
      psCodecExprResume frames (PsCodecSpineReference.psEncodeCodecExpr value) := by
  induction value generalizing frames <;>
    simp_all only [psEncodeCodecExprAcc, PsCodecSpineReference.psEncodeCodecExpr,
      psCodecExprResume]
  all_goals
    repeat' first
      | rfl
      | (split <;> simp_all only [psCodecExprResume, psCodecExprApplyFrame])

theorem codec_spine_eq (value : PsExpr) :
    psEncodeCodecExpr value = PsCodecSpineReference.psEncodeCodecExpr value := by
  simpa only [psEncodeCodecExpr, psCodecExprResume] using
    codec_spine_acc_eq value []

#print axioms codec_spine_acc_eq
#print axioms codec_spine_eq

theorem codec_admissions_loop_worker_eq (all declarations : List PsDeclaration)
    (state : PsCheckedAdmissionEncodeState) :
    psEncodeCheckedAdmissionsLoopWorker all declarations state =
      PsCodecSpineReference.psEncodeCheckedAdmissionsLoop all declarations state := by
  induction declarations generalizing state with
  | nil => rfl
  | cons declaration rest ih =>
      cases declaration <;>
        simp only [psEncodeCheckedAdmissionsLoopWorker,
          PsCodecSpineReference.psEncodeCheckedAdmissionsLoop, ih] <;> rfl

theorem codec_admissions_loop_eq (all declarations : List PsDeclaration) :
    psEncodeCheckedAdmissionsLoop all declarations =
      PsCodecSpineReference.psEncodeCheckedAdmissionsLoop all declarations := by
  funext state
  exact codec_admissions_loop_worker_eq all declarations state

theorem codec_admissions_reverse_worker_eq (values acc : List String) :
    psCheckedAdmissionReverseStringsWorker values acc =
      PsCodecSpineReference.psCheckedAdmissionReverseStringsAcc values acc := by
  induction values generalizing acc with
  | nil => rfl
  | cons head tail ih =>
      simp only [psCheckedAdmissionReverseStringsWorker,
        PsCodecSpineReference.psCheckedAdmissionReverseStringsAcc, ih]

theorem codec_admissions_reverse_eq (values : List String) :
    psCheckedAdmissionReverseStringsAcc values =
      PsCodecSpineReference.psCheckedAdmissionReverseStringsAcc values := by
  funext acc
  exact codec_admissions_reverse_worker_eq values acc

#print axioms codec_admissions_loop_eq
#print axioms codec_admissions_reverse_eq
