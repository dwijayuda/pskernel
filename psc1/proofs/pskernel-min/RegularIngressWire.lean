import RegularIngressModel

namespace Ps.MinKernel.RegularIngressWire
open Ps.MinKernel.CoreIngress
open Ps.MinKernel.RegularIngressModel

-- Mathematical decimal place values, independent of the streaming recognizer.
inductive DecimalTail : Nat → List Nat → Nat → Prop where
  | nil (value) : DecimalTail value [] value
  | digit (initial byte tail value)
      (lower : 48 ≤ byte) (upper : byte ≤ 57)
      (rest : DecimalTail (10 * initial + (byte - 48)) tail value) :
      DecimalTail initial (byte :: tail) value

inductive Decimal : Nat → List Nat → Prop where
  | zero : Decimal 0 [48]
  | positive (head tail value) (lower : 48 ≤ head) (upper : head ≤ 57)
      (nonzero : head ≠ 48) (rest : DecimalTail (head - 48) tail value) :
      Decimal value (head :: tail)

theorem digit_bounds (byte : Nat) (h : psMinRegByteDigit byte = true) :
    48 ≤ byte ∧ byte ≤ 57 := by
  unfold psMinRegByteDigit at h
  split at h
  next small => contradiction
  next lower =>
    split at h
    next large => contradiction
    next upper =>
      exact ⟨Nat.le_of_not_gt (by simpa only [Nat.blt_eq] using lower),
        Nat.le_of_not_gt (by simpa only [Nat.blt_eq] using upper)⟩

theorem timesTen_value (value : Nat) : psMinRegByteTimesTen value = 10 * value := by
  unfold psMinRegByteTimesTen
  simp only [Nat.add_eq, Nat.succ_mul, Nat.zero_mul, Nat.zero_add]
  ac_rfl

theorem readTail_value (fuel : Nat) (bytes : List Nat) (initial : Nat)
    (result : PsMinRegByteNumber) (h : psMinRegByteReadTail fuel bytes initial = some result) :
    ∃ digits, bytes = digits ++ result.rest ∧ DecimalTail initial digits result.value := by
  induction fuel generalizing bytes initial result with
  | zero =>
    cases bytes with
    | nil =>
      simp only [psMinRegByteReadTail, Option.some.injEq] at h
      subst result
      exact ⟨[], rfl, .nil initial⟩
    | cons head rest =>
      simp only [psMinRegByteReadTail] at h
      split at h
      next => contradiction
      next =>
        cases h
        exact ⟨[], rfl, .nil initial⟩
  | succ fuel ih =>
    cases bytes with
    | nil =>
      simp only [psMinRegByteReadTail, Option.some.injEq] at h
      subst result
      exact ⟨[], rfl, .nil initial⟩
    | cons head rest =>
      simp only [psMinRegByteReadTail] at h
      split at h
      next digit =>
        split at h
        next bounded =>
          obtain ⟨digits, equation, meaning⟩ := ih rest
            (Nat.add (psMinRegByteTimesTen initial) (Nat.sub head 48)) result h
          obtain ⟨lower, upper⟩ := digit_bounds head digit
          refine ⟨head :: digits, ?_, ?_⟩
          · exact congrArg (List.cons head) equation
          · apply DecimalTail.digit initial head digits result.value lower upper
            simpa only [timesTen_value, Nat.add_eq, Nat.sub_eq] using meaning
        next => contradiction
      next =>
        cases h
        exact ⟨[], rfl, .nil initial⟩

theorem readNumber_value (bytes : List Nat) (result : PsMinRegByteNumber)
    (h : psMinRegByteReadNumber bytes = some result) :
    ∃ digits, bytes = digits ++ result.rest ∧ Decimal result.value digits := by
  cases bytes with
  | nil => simp [psMinRegByteReadNumber] at h
  | cons head rest =>
    simp only [psMinRegByteReadNumber] at h
    split at h
    next zero =>
      have hz : head = 48 := by simpa only [Nat.beq_eq_true] using zero
      subst head
      cases h
      exact ⟨[48], rfl, .zero⟩
    next nonzero =>
      split at h
      next digit =>
        obtain ⟨tail, equation, meaning⟩ := readTail_value 6 rest (Nat.sub head 48) result h
        obtain ⟨lower, upper⟩ := digit_bounds head digit
        refine ⟨head :: tail, congrArg (List.cons head) equation, ?_⟩
        apply Decimal.positive head tail result.value lower upper
        · simpa only [Nat.beq_eq_true] using nonzero
        · simpa only [Nat.sub_eq] using meaning
      next => contradiction

inductive Token where
  | literal (bytes : List Nat)
  | number (value : Nat)

-- A wire derivation is a sequence of exact punctuation/text and canonical
-- decimal numerals. It has no reference to any executable parser or checker.
inductive Wire : List Token → List Nat → Prop where
  | nil : Wire [] []
  | literal (head tail tokens) (rest : Wire tokens tail) :
      Wire (.literal head :: tokens) (head ++ tail)
  | number (value digits tail tokens) (meaning : Decimal value digits) (rest : Wire tokens tail) :
      Wire (.number value :: tokens) (digits ++ tail)

theorem wire_append (left right : List Token) (a b : List Nat)
    (ha : Wire left a) (hb : Wire right b) : Wire (left ++ right) (a ++ b) := by
  induction ha with
  | nil => exact hb
  | literal head tail tokens rest ih =>
    simpa only [List.cons_append, List.append_assoc] using Wire.literal head (tail ++ b) (tokens ++ right) ih
  | number value digits tail tokens meaning rest ih =>
    simpa only [List.cons_append, List.append_assoc] using Wire.number value digits (tail ++ b) (tokens ++ right) meaning ih

def Recognizes (tokens : List Token) (parser : List Nat → Option (List Nat)) : Prop :=
  ∀ bytes rest, parser bytes = some rest → ∃ prefix, Wire tokens prefix ∧ bytes = prefix ++ rest

theorem literal_prefix (literal bytes rest : List Nat)
    (h : psMinRegByteLiteral literal bytes = some rest) : bytes = literal ++ rest := by
  induction literal generalizing bytes with
  | nil => simpa only [psMinRegByteLiteral, Option.some.injEq] using h
  | cons expected tail ih =>
    cases bytes with
    | nil => simp [psMinRegByteLiteral] at h
    | cons actual next =>
      simp only [psMinRegByteLiteral] at h
      split at h
      next same =>
        have he : expected = actual := by simpa only [Nat.beq_eq_true] using same
        subst actual
        exact congrArg (List.cons expected) (ih next h)
      next => contradiction

theorem recognizes_literal (literal : List Nat) :
    Recognizes [.literal literal] (psMinRegByteLiteral literal) := by
  intro bytes rest checked
  exact ⟨literal, by simpa only [List.append_nil] using Wire.literal literal [] [] Wire.nil,
    literal_prefix literal bytes rest checked⟩

theorem recognizes_number (value : Nat) :
    Recognizes [.number value] (psMinRegByteNumber value) := by
  intro bytes rest checked
  unfold psMinRegByteNumber at checked
  cases hn : psMinRegByteReadNumber bytes with
  | none => simp [hn] at checked
  | some result =>
    simp only [hn] at checked
    split at checked
    next same =>
      have equal : result.value = value := by simpa only [Nat.beq_eq_true] using same
      have tail : result.rest = rest := by simpa only [Option.some.injEq] using checked
      obtain ⟨digits, equation, meaning⟩ := readNumber_value bytes result hn
      rw [equal] at meaning
      refine ⟨digits, ?_, ?_⟩
      · simpa only [List.append_nil] using Wire.number value digits [] [] meaning Wire.nil
      · simpa only [tail] using equation
    next => contradiction

theorem recognizes_empty : Recognizes [] (fun bytes => some bytes) := by
  intro bytes rest checked
  exact ⟨[], Wire.nil, by simpa only [Option.some.injEq] using checked⟩

theorem recognizes_then (a b : List Token)
    (first second : List Nat → Option (List Nat))
    (ha : Recognizes a first) (hb : Recognizes b second) :
    Recognizes (a ++ b) (fun bytes => psMinRegByteThen (first bytes) second) := by
  intro bytes rest checked
  cases hf : first bytes with
  | none => simp [psMinRegByteThen, hf] at checked
  | some middle =>
    have hs : second middle = some rest := by simpa only [psMinRegByteThen, hf] using checked
    obtain ⟨left, leftWire, leftEq⟩ := ha bytes middle hf
    obtain ⟨right, rightWire, rightEq⟩ := hb middle rest hs
    refine ⟨left ++ right, wire_append a b left right leftWire rightWire, ?_⟩
    rw [leftEq, rightEq, List.append_assoc]

#print axioms digit_bounds
#print axioms timesTen_value
#print axioms readTail_value
#print axioms readNumber_value
#print axioms wire_append
#print axioms literal_prefix
#print axioms recognizes_number
#print axioms recognizes_then
end Ps.MinKernel.RegularIngressWire
