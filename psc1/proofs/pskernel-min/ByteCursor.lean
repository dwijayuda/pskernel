import Ps.MinKernel.Profile.ByteCursor

namespace Ps.MinKernel.ByteCursor

-- Independent mathematical read event. Physical bytes/callback purity are an
-- explicit host representation obligation, not granted by this predicate.
def Read (byteAt : Nat → Nat) (size offset byte : Nat) : Prop :=
  offset < size ∧ byteAt offset = byte ∧ byte ≤ 255

-- Chronological reference traversal. Every position before size is read once;
-- the terminal event fixes exact EOF. The relation calls no cursor worker.
inductive Span (byteAt : Nat → Nat) (size : Nat) : Nat → List Nat → Prop where
  | done : Span byteAt size size []
  | step {offset byte : Nat} {rest : List Nat}
      (read : Read byteAt size offset byte)
      (tail : Span byteAt size (Nat.succ offset) rest) :
      Span byteAt size offset (byte :: rest)

def digest (initial : Nat) : List Nat → Nat
  | [] => initial
  | byte :: rest => digest (Nat.mod (Nat.add (Nat.mul initial 257) byte) 65521) rest

theorem read_sound (h : psMinByteCursorRead size byteAt offset = .ok byte) :
    Read byteAt size offset byte := by
  unfold psMinByteCursorRead at h
  split at h
  next before =>
    split at h
    next bounded =>
      cases h
      exact ⟨by simpa only [Nat.blt_eq] using before, rfl,
        by simpa only [Nat.ble_eq] using bounded⟩
    next => cases h
  next => cases h

theorem read_complete (h : Read byteAt size offset byte) :
    psMinByteCursorRead size byteAt offset = .ok byte := by
  obtain ⟨before, value, bounded⟩ := h
  have before' : Nat.blt offset size = true := by simpa only [Nat.blt_eq] using before
  have bounded' : Nat.ble byte 255 = true := by simpa only [Nat.ble_eq] using bounded
  simp only [psMinByteCursorRead, before', ite_true, value, bounded']

theorem read_iff :
    psMinByteCursorRead size byteAt offset = .ok byte ↔
      Read byteAt size offset byte :=
  ⟨read_sound, read_complete⟩

theorem read_eof (size : Nat) (byteAt : Nat → Nat) :
    psMinByteCursorRead size byteAt size = .error .endOfInput := by
  have noBefore : ¬ Nat.blt size size = true := by
    simpa only [Nat.blt_eq] using Nat.lt_irrefl size
  simp only [psMinByteCursorRead, ite_eq_right noBefore]

theorem read_range (before : offset < size) (large : 255 < byteAt offset) :
    psMinByteCursorRead size byteAt offset = .error .byteRange := by
  have before' : Nat.blt offset size = true := by simpa only [Nat.blt_eq] using before
  have large' : ¬ Nat.ble (byteAt offset) 255 = true := by
    simpa only [Nat.ble_eq] using Nat.not_le_of_gt large
  simp only [psMinByteCursorRead, before', ite_true, ite_eq_right large']

theorem walk_span (span : Span byteAt size offset bytes) (initial : Nat) :
    psMinByteCursorWalk bytes.length size byteAt
      (PsMinByteCursorState.mk offset initial) =
      .ok (PsMinByteCursorState.mk size (digest initial bytes)) := by
  induction span generalizing initial with
  | done =>
      have eq : Nat.beq size size = true := by simp only [Nat.beq_eq]
      simp only [List.length_nil, psMinByteCursorWalk, eq, ite_true, digest]
  | @step offset byte rest read tail ih =>
      have ready := read_complete read
      simpa only [List.length_cons, psMinByteCursorWalk, ready,
        psMinByteDigestStep, digest] using
          ih (psMinByteDigestStep initial byte)

theorem span_valid (span : Span byteAt size offset bytes) :
    ∀ byte ∈ bytes, byte ≤ 255 := by
  induction span with
  | done => intro byte member; cases member
  | step read tail ih =>
      intro byte member
      cases member with
      | head => exact read.2.2
      | tail _ member => exact ih byte member

theorem span_length (span : Span byteAt size offset bytes) :
    offset + bytes.length = size := by
  induction span with
  | done => exact Nat.add_zero size
  | @step offset byte rest read tail ih =>
      simpa only [List.length_cons, Nat.add_succ, Nat.succ_add] using ih

theorem digest_empty (initial : Nat) : digest initial [] = initial := rfl

theorem digest_cons (initial byte : Nat) (rest : List Nat) :
    digest initial (byte :: rest) = digest ((initial * 257 + byte) % 65521) rest := rfl

theorem walk_reflect (remaining size : Nat) (byteAt : Nat → Nat)
    (start finish : PsMinByteCursorState)
    (success : psMinByteCursorWalk remaining size byteAt start = .ok finish) :
    ∃ bytes, bytes.length = remaining ∧ Span byteAt size start.offset bytes ∧
      finish = PsMinByteCursorState.mk size (digest start.digest bytes) := by
  induction remaining generalizing start finish with
  | zero =>
      change (if Nat.beq start.offset size then Except.ok start
        else Except.error PsMinByteCursorError.incomplete) = .ok finish at success
      split at success
      next atEnd =>
        have atEnd' : start.offset = size := by simpa only [Nat.beq_eq] using atEnd
        cases success
        cases start with
        | mk offset initial =>
          change offset = size at atEnd'
          subst offset
          exact ⟨[], rfl, .done, rfl⟩
      next => cases success
  | succ remaining ih =>
      change (match psMinByteCursorRead size byteAt start.offset with
        | .error error => Except.error error
        | .ok byte => psMinByteCursorWalk remaining size byteAt
            (PsMinByteCursorState.mk (Nat.succ start.offset)
              (psMinByteDigestStep start.digest byte))) = .ok finish at success
      cases read : psMinByteCursorRead size byteAt start.offset with
      | error error => simp only [read] at success
      | ok byte =>
        simp only [read] at success
        obtain ⟨bytes, count, span, result⟩ := ih _ _ success
        refine ⟨byte :: bytes, ?_, .step (read_sound read) span, ?_⟩
        · simp only [List.length_cons, count]
        · simpa only [digest, psMinByteDigestStep] using result

theorem walk_iff :
    psMinByteCursorWalk remaining size byteAt start = .ok finish ↔
      ∃ bytes, bytes.length = remaining ∧ Span byteAt size start.offset bytes ∧
        finish = PsMinByteCursorState.mk size (digest start.digest bytes) := by
  constructor
  · exact walk_reflect remaining size byteAt start finish
  · rintro ⟨bytes, count, span, result⟩
    rw [← count, result]
    exact walk_span span start.digest

theorem digest_bounded (bytes : List Nat) (initial : Nat) (bounded : initial < 65521) :
    digest initial bytes < 65521 := by
  induction bytes generalizing initial with
  | nil => exact bounded
  | cons byte rest ih =>
    exact ih _ (Nat.mod_lt _ (by decide))

end Ps.MinKernel.ByteCursor
