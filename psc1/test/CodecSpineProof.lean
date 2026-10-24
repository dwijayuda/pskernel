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
