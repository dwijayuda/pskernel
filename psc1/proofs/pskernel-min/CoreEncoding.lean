import CoreSemantics

namespace Ps.MinKernel.CoreEncoding
open Ps.MinKernel.CoreIngress

-- This grammar uses mathematical list concatenation and decimal place values.
-- It is independent of the runtime append/join/decimal encoder implementation.
def commaTail : List (List Nat) → List Nat
  | [] => []
  | first :: rest => [44] ++ (first ++ commaTail rest)

def commaBytes : List (List Nat) → List Nat
  | [] => []
  | first :: rest => first ++ commaTail rest

def objectBytes (fields : List (List Nat)) : List Nat := [123] ++ commaBytes fields ++ [125]
def arrayBytes (values : List (List Nat)) : List Nat := [91] ++ commaBytes values ++ [93]
def quoteBytes (bytes : List Nat) : List Nat := [34] ++ bytes ++ [34]

theorem append_eq (left right : List Nat) : psMinByteAppend left right = left ++ right := by
  induction left with
  | nil => rfl
  | cons head tail ih => exact congrArg (List.cons head) ih

theorem append_assoc_checked (xs ys zs : List Nat) :
    (xs ++ ys) ++ zs = xs ++ (ys ++ zs) := by
  induction xs with
  | nil => rfl
  | cons head tail ih => exact congrArg (List.cons head) ih

theorem append_nil_checked (xs : List Nat) : xs ++ [] = xs := by
  induction xs with
  | nil => rfl
  | cons head tail ih => exact congrArg (List.cons head) ih

theorem nil_append_checked (xs : List Nat) : [] ++ xs = xs := rfl

theorem join_tail_eq (values : List (List Nat)) :
    psMinByteJoinTail [44] values = commaTail values := by
  induction values with
  | nil => rfl
  | cons first rest ih =>
    change 44 :: psMinByteAppend first (psMinByteJoinTail [44] rest) =
      44 :: (first ++ commaTail rest)
    exact congrArg (List.cons 44) ((append_eq first _).trans (congrArg (fun bytes => first ++ bytes) ih))

theorem object_eq (fields : List (List Nat)) :
    psMinByteJoin [123] [44] [125] fields = objectBytes fields := by
  cases fields with
  | nil => rfl
  | cons first rest =>
    change 123 :: psMinByteAppend first (psMinByteAppend (psMinByteJoinTail [44] rest) [125]) =
      123 :: ((first ++ commaTail rest) ++ [125])
    apply congrArg (List.cons 123)
    rw [append_eq, append_eq, join_tail_eq]
    exact (append_assoc_checked first (commaTail rest) [125]).symm

theorem array_eq (values : List (List Nat)) :
    psMinByteJoin [91] [44] [93] values = arrayBytes values := by
  cases values with
  | nil => rfl
  | cons first rest =>
    change 91 :: psMinByteAppend first (psMinByteAppend (psMinByteJoinTail [44] rest) [93]) =
      91 :: ((first ++ commaTail rest) ++ [93])
    apply congrArg (List.cons 91)
    rw [append_eq, append_eq, join_tail_eq]
    exact (append_assoc_checked first (commaTail rest) [93]).symm

theorem quote_eq (bytes : List Nat) : psMinCoreQuote bytes = quoteBytes bytes := by
  simp only [psMinCoreQuote, append_eq, quoteBytes, append_assoc_checked]

def digitValue : List Nat → Nat
  | [] => 0
  | digit :: rest => digit + 10 * digitValue rest

inductive NonzeroDigits : List Nat → Prop where
  | top (digit : Nat) (positive : 0 < digit) (small : digit < 10) : NonzeroDigits [digit]
  | low (digit : Nat) (rest : List Nat) (small : digit < 10) (tail : NonzeroDigits rest) :
      NonzeroDigits (digit :: rest)

def CanonicalDigits (digits : List Nat) : Prop := digits = [0] ∨ NonzeroDigits digits

inductive DigitBytes : List Nat → List Nat → Prop where
  | nil : DigitBytes [] []
  | cons (digit rest bytes) (tail : DigitBytes rest bytes) :
      DigitBytes (digit :: rest) (bytes ++ [48 + digit])

inductive NumberWire (value : Nat) (bytes : List Nat) : Prop where
  | literal (digits : List Nat) (canonical : CanonicalDigits digits)
      (valueIdentity : digitValue digits = value) (symbols : DigitBytes digits bytes) :
      NumberWire value bytes

theorem increment_value (digits : List Nat) :
    digitValue (psMinDecimalIncrement digits) = digitValue digits + 1 := by
  induction digits with
  | nil => rfl
  | cons digit rest ih =>
    cases heq : Nat.beq digit 9 with
    | true =>
      have hd := Nat.eq_of_beq_eq_true heq
      subst digit
      simp only [psMinDecimalIncrement, heq, Bool.false_eq_true, ite_true, ite_false, digitValue, ih]
      simp [Nat.mul_add, Nat.add_assoc, Nat.add_comm, Nat.add_left_comm]
      rw [← Nat.add_assoc]
    | false =>
      simp only [psMinDecimalIncrement, heq, Bool.false_eq_true, ite_true, ite_false, digitValue]
      simp [Nat.succ_eq_add_one, Nat.add_assoc, Nat.add_comm, Nat.add_left_comm]

theorem increment_nonzero (digits : List Nat) (h : NonzeroDigits digits) :
    NonzeroDigits (psMinDecimalIncrement digits) := by
  induction h with
  | top digit positive small =>
    cases heq : Nat.beq digit 9 with
    | true =>
      have hd := Nat.eq_of_beq_eq_true heq
      subst digit
      simpa only [psMinDecimalIncrement, heq, Bool.false_eq_true, ite_true, ite_false] using
        NonzeroDigits.low 0 [1] (by decide) (NonzeroDigits.top 1 (by decide) (by decide))
    | false =>
      have ne : digit ≠ 9 := by intro equal; subst digit; contradiction
      simpa only [psMinDecimalIncrement, heq, Bool.false_eq_true, ite_true, ite_false] using
        NonzeroDigits.top (Nat.succ digit) (Nat.zero_lt_succ digit)
          (Nat.succ_lt_succ (Nat.lt_of_le_of_ne (Nat.le_of_lt_succ small) ne))
  | low digit rest small tail ih =>
    cases heq : Nat.beq digit 9 with
    | true =>
      simpa only [psMinDecimalIncrement, heq, Bool.false_eq_true, ite_true, ite_false] using
        NonzeroDigits.low 0 (psMinDecimalIncrement rest) (by decide) ih
    | false =>
      have ne : digit ≠ 9 := by intro equal; subst digit; contradiction
      simpa only [psMinDecimalIncrement, heq, Bool.false_eq_true, ite_true, ite_false] using
        NonzeroDigits.low (Nat.succ digit) rest
          (Nat.succ_lt_succ (Nat.lt_of_le_of_ne (Nat.le_of_lt_succ small) ne)) tail

theorem digits_canonical (value : Nat) : CanonicalDigits (psMinDecimalDigits value) := by
  induction value with
  | zero => exact Or.inl rfl
  | succ value ih =>
    apply Or.inr
    rcases ih with zero | nonzero
    · rw [psMinDecimalDigits, zero]
      exact NonzeroDigits.top 1 (by decide) (by decide)
    · exact increment_nonzero _ nonzero

theorem decimal_value (value : Nat) : digitValue (psMinDecimalDigits value) = value := by
  induction value with
  | zero => rfl
  | succ value ih =>
    rw [psMinDecimalDigits, increment_value, ih]

theorem decimal_symbols (digits : List Nat) : DigitBytes digits (psMinDecimalBytes digits) := by
  induction digits with
  | nil => exact .nil
  | cons digit rest ih =>
    simpa only [psMinDecimalBytes, append_eq, Nat.add_eq] using DigitBytes.cons digit rest (psMinDecimalBytes rest) ih

theorem number_wire (value : Nat) : NumberWire value (psMinCoreNumber value) :=
  ⟨psMinDecimalDigits value, digits_canonical value, decimal_value value, decimal_symbols _⟩

inductive ASCIIText : List Nat → Prop where
  | nil : ASCIIText []
  | cons (head tail) (lower : 32 ≤ head) (upper : head ≤ 126)
      (noQuote : head ≠ 34) (noEscape : head ≠ 92) (rest : ASCIIText tail) :
      ASCIIText (head :: tail)

theorem safe_text (fuel : Nat) (bytes : List Nat) (h : psMinCoreSafeText fuel bytes = true) :
    ASCIIText bytes := by
  induction fuel generalizing bytes with
  | zero =>
    cases bytes with
    | nil => exact .nil
    | cons head tail => cases h
  | succ fuel ih =>
    cases bytes with
    | nil => exact .nil
    | cons head tail =>
      simp only [psMinCoreSafeText] at h
      repeat' split at h
      all_goals try contradiction
      apply ASCIIText.cons head tail
      · have hn : ¬ head < 32 := by
          simpa only [Nat.blt_eq] using (by assumption : ¬ Nat.blt head 32 = true)
        exact Nat.le_of_not_lt hn
      · have hn : ¬ 126 < head := by
          simpa only [Nat.blt_eq] using (by assumption : ¬ Nat.blt 126 head = true)
        exact Nat.le_of_not_lt hn
      · intro equal; subst head; contradiction
      · intro equal; subst head; contradiction
      · exact ih tail h

inductive NameWire : PsMinCoreName → List Nat → Prop where
  | anonymous : NameWire .anonymous [123, 34, 107, 34, 58, 34, 97, 34, 125]
  | str (parent text parentBytes) (hp : NameWire parent parentBytes) (ht : ASCIIText text) :
      NameWire (.str parent text) (objectBytes [([34, 107, 34, 58] ++ [34, 115, 34]), ([34, 112, 34, 58] ++ parentBytes), ([34, 118, 34, 58] ++ quoteBytes text)])
  | num (parent value parentBytes numberBytes) (hp : NameWire parent parentBytes)
      (hn : NumberWire value numberBytes) :
      NameWire (.num parent value) (objectBytes [([34, 107, 34, 58] ++ [34, 110, 34]), ([34, 112, 34, 58] ++ parentBytes), ([34, 118, 34, 58] ++ quoteBytes numberBytes)])

theorem name_wire (fuel : Nat) (name : PsMinCoreName) (h : psMinCoreNameValid fuel name = true) :
    NameWire name (psMinCoreEncodeName name) := by
  induction fuel generalizing name with
  | zero => cases h
  | succ fuel ih =>
    cases name with
    | anonymous => exact .anonymous
    | str parent text =>
      simp only [psMinCoreNameValid] at h
      split at h
      next validText =>
        simpa only [psMinCoreEncodeName, object_eq, append_eq, quote_eq] using
          NameWire.str parent text (psMinCoreEncodeName parent) (ih parent h) (safe_text _ _ validText)
      next => contradiction
    | num parent value =>
      simp only [psMinCoreNameValid] at h
      split at h
      next validNumber =>
        simpa only [psMinCoreEncodeName, object_eq, append_eq, quote_eq] using
          NameWire.num parent value (psMinCoreEncodeName parent) (psMinCoreNumber value)
            (ih parent h) (number_wire value)
      next => contradiction

inductive LevelWire : Nat → List Nat → Prop where
  | zero : LevelWire 0 [123, 34, 107, 34, 58, 34, 122, 34, 125]
  | succ (level bytes) (inner : LevelWire level bytes) :
      LevelWire (Nat.succ level) (objectBytes [([34, 107, 34, 58] ++ [34, 115, 34]), ([34, 111, 34, 58] ++ bytes)])

inductive LevelsWire : List Nat → List (List Nat) → Prop where
  | nil : LevelsWire [] []
  | cons (level rest bytes chunks) (head : LevelWire level bytes) (tail : LevelsWire rest chunks) :
      LevelsWire (level :: rest) (bytes :: chunks)

theorem level_wire (level : Nat) : LevelWire level (psMinCoreEncodeLevel level) := by
  induction level with
  | zero => exact .zero
  | succ level ih =>
    simpa only [psMinCoreEncodeLevel, object_eq, append_eq] using LevelWire.succ level _ ih

theorem levels_wire (levels : List Nat) : LevelsWire levels (psMinCoreEncodeLevels levels) := by
  induction levels with
  | nil => exact .nil
  | cons level rest ih => exact .cons level rest _ _ (level_wire level) ih

inductive BinderWire : Nat → List Nat → Prop where
  | explicit : BinderWire 0 [34, 100, 101, 102, 97, 117, 108, 116, 34]
  | implicit : BinderWire 1 [34, 105, 109, 112, 108, 105, 99, 105, 116, 34]
  | strictImplicit : BinderWire 2 [34, 115, 116, 114, 105, 99, 116, 73, 109, 112, 108, 105, 99, 105, 116, 34]
  | instanceImplicit : BinderWire 3 [34, 105, 110, 115, 116, 73, 109, 112, 108, 105, 99, 105, 116, 34]

theorem binder_wire (binder : Nat) (h : Nat.blt binder 4 = true) :
    BinderWire binder (psMinCoreBinderBytes binder) := by
  have bound : binder < 4 := by simpa only [Nat.blt_eq] using h
  cases binder with
  | zero => exact .explicit
  | succ a =>
    cases a with
    | zero => exact .implicit
    | succ b =>
      cases b with
      | zero => exact .strictImplicit
      | succ c =>
        cases c with
        | zero => exact .instanceImplicit
        | succ d =>
          have lower : 4 ≤ Nat.succ (Nat.succ (Nat.succ (Nat.succ d))) :=
            Nat.succ_le_succ (Nat.succ_le_succ (Nat.succ_le_succ (Nat.succ_le_succ (Nat.zero_le d))))
          exact False.elim (Nat.not_lt_of_ge lower bound)

inductive ExprWire : PsMinCoreExpr → List Nat → Prop where
  | sort (level bytes) (h : LevelWire level bytes) :
      ExprWire (.sort level) (objectBytes [([34, 107, 34, 58] ++ [34, 115, 111, 114, 116, 34]), ([34, 108, 34, 58] ++ bytes)])
  | projection (name index value n i v) (hn : NameWire name n)
      (hi : NumberWire index i) (hv : ExprWire value v) :
      ExprWire (.projection name index value) (objectBytes [([34, 101, 34, 58] ++ v), ([34, 105, 34, 58] ++ i), ([34, 107, 34, 58] ++ [34, 112, 114, 111, 106, 34]), ([34, 110, 34, 58] ++ n)])
  | bvar (index numberBytes) (hn : NumberWire index numberBytes) :
      ExprWire (.bvar index) (objectBytes [([34, 105, 34, 58] ++ numberBytes), ([34, 107, 34, 58] ++ [34, 98, 34])])
  | natural (value numberBytes) (hn : NumberWire value numberBytes) :
      ExprWire (.natural value) (objectBytes [([34, 107, 34, 58] ++ [34, 110, 97, 116, 34]), ([34, 118, 34, 58] ++ quoteBytes numberBytes)])
  | constant (name levels nameBytes chunks) (hn : NameWire name nameBytes)
      (hl : LevelsWire levels chunks) :
      ExprWire (.constant name levels) (objectBytes [([34, 107, 34, 58] ++ [34, 99, 111, 110, 115, 116, 34]), ([34, 108, 115, 34, 58] ++ arrayBytes chunks), ([34, 110, 34, 58] ++ nameBytes)])
  | app (fn arg f a) (hf : ExprWire fn f) (ha : ExprWire arg a) :
      ExprWire (.app fn arg) (objectBytes [([34, 97, 34, 58] ++ a), ([34, 102, 34, 58] ++ f), ([34, 107, 34, 58] ++ [34, 97, 112, 112, 34])])
  | lam (name binder type body n bi t b) (hn : NameWire name n) (hbi : BinderWire binder bi)
      (ht : ExprWire type t) (hb : ExprWire body b) :
      ExprWire (.lam name binder type body) (objectBytes [([34, 98, 34, 58] ++ b), ([34, 98, 105, 34, 58] ++ bi), ([34, 107, 34, 58] ++ [34, 108, 97, 109, 34]), ([34, 110, 34, 58] ++ n), ([34, 116, 34, 58] ++ t)])
  | forallE (name binder type body n bi t b) (hn : NameWire name n) (hbi : BinderWire binder bi)
      (ht : ExprWire type t) (hb : ExprWire body b) :
      ExprWire (.forallE name binder type body) (objectBytes [([34, 98, 34, 58] ++ b), ([34, 98, 105, 34, 58] ++ bi), ([34, 107, 34, 58] ++ [34, 102, 111, 114, 97, 108, 108, 34]), ([34, 110, 34, 58] ++ n), ([34, 116, 34, 58] ++ t)])
  | letE (name type value body n t v b) (hn : NameWire name n)
      (ht : ExprWire type t) (hv : ExprWire value v) (hb : ExprWire body b) :
      ExprWire (.letE name type value body) (objectBytes [([34, 98, 34, 58] ++ b), ([34, 107, 34, 58] ++ [34, 108, 101, 116, 34]), ([34, 110, 34, 58] ++ n), ([34, 116, 34, 58] ++ t), ([34, 118, 34, 58] ++ v)])

theorem expression_wire (fuel : Nat) (expr : PsMinCoreExpr) (h : psMinCoreExprValid fuel expr = true) :
    ExprWire expr (psMinCoreEncodeExpr expr) := by
  induction fuel generalizing expr with
  | zero => cases h
  | succ fuel ih =>
    cases expr with
    | sort level =>
      simpa only [psMinCoreEncodeExpr, object_eq, append_eq] using ExprWire.sort level _ (level_wire level)
    | projection name index value =>
      simp only [psMinCoreExprValid] at h
      repeat' split at h
      all_goals try contradiction
      simpa only [psMinCoreEncodeExpr, object_eq, append_eq] using
        ExprWire.projection name index value _ _ _ (name_wire 16 name (by assumption))
          (number_wire index) (ih value h)
    | bvar index =>
      simpa only [psMinCoreEncodeExpr, object_eq, append_eq] using ExprWire.bvar index _ (number_wire index)
    | natural value =>
      simpa only [psMinCoreEncodeExpr, object_eq, append_eq, quote_eq] using ExprWire.natural value _ (number_wire value)
    | constant name levels =>
      simp only [psMinCoreExprValid] at h
      repeat' split at h
      all_goals try contradiction
      simpa only [psMinCoreEncodeExpr, object_eq, array_eq, append_eq] using
        ExprWire.constant name levels _ _ (name_wire 16 name (by assumption)) (levels_wire levels)
    | app fn arg =>
      simp only [psMinCoreExprValid] at h
      split at h
      next hf =>
        simpa only [psMinCoreEncodeExpr, object_eq, append_eq] using ExprWire.app fn arg _ _ (ih fn hf) (ih arg h)
      next => contradiction
    | lam name binder type body =>
      simp only [psMinCoreExprValid] at h
      repeat' split at h
      all_goals try contradiction
      simpa only [psMinCoreEncodeExpr, object_eq, append_eq] using
        ExprWire.lam name binder type body _ _ _ _ (name_wire 16 name (by assumption))
          (binder_wire binder (by assumption)) (ih type (by assumption)) (ih body h)
    | forallE name binder type body =>
      simp only [psMinCoreExprValid] at h
      repeat' split at h
      all_goals try contradiction
      simpa only [psMinCoreEncodeExpr, object_eq, append_eq] using
        ExprWire.forallE name binder type body _ _ _ _ (name_wire 16 name (by assumption))
          (binder_wire binder (by assumption)) (ih type (by assumption)) (ih body h)
    | letE name type value body =>
      simp only [psMinCoreExprValid] at h
      repeat' split at h
      all_goals try contradiction
      simpa only [psMinCoreEncodeExpr, object_eq, append_eq] using
        ExprWire.letE name type value body _ _ _ _ (name_wire 16 name (by assumption))
          (ih type (by assumption)) (ih value (by assumption)) (ih body h)

inductive DeclarationWire : PsMinCoreDeclaration → List Nat → Prop where
  | definition (name height type value n h t v) (hn : NameWire name n) (hh : NumberWire height h)
      (ht : ExprWire type t) (hv : ExprWire value v) :
      DeclarationWire (.mk name height type value)
        (objectBytes [([34, 100, 101, 99, 108, 97, 114, 97, 116, 105, 111, 110, 34, 58] ++ objectBytes [([34, 104, 34, 58] ++ objectBytes [([34, 104, 34, 58] ++ quoteBytes h), ([34, 107, 34, 58] ++ [34, 114, 101, 103, 117, 108, 97, 114, 34])]), ([34, 107, 34, 58] ++ [34, 100, 101, 102, 105, 110, 105, 116, 105, 111, 110, 34]), ([34, 108, 112, 34, 58] ++ [91, 93]), ([34, 110, 34, 58] ++ n), ([34, 115, 34, 58] ++ [34, 115, 97, 102, 101, 34]), ([34, 116, 34, 58] ++ t), ([34, 118, 34, 58] ++ v)]), ([34, 107, 105, 110, 100, 34, 58] ++ [34, 99, 111, 110, 115, 116, 97, 110, 116, 34])])

inductive DeclarationsWire : List PsMinCoreDeclaration → List (List Nat) → Prop where
  | nil : DeclarationsWire [] []
  | cons (decl rest bytes chunks) (head : DeclarationWire decl bytes) (tail : DeclarationsWire rest chunks) :
      DeclarationsWire (decl :: rest) (bytes :: chunks)

inductive PacketWire : List PsMinCoreDeclaration → List Nat → Prop where
  | packet (source chunks) (decls : DeclarationsWire source chunks) :
      PacketWire source (objectBytes [([34, 97, 100, 109, 105, 115, 115, 105, 111, 110, 115, 34, 58] ++ arrayBytes chunks), ([34, 102, 111, 114, 109, 97, 116, 34, 58] ++ [34, 112, 114, 111, 111, 102, 115, 99, 114, 105, 112, 116, 45, 99, 104, 101, 99, 107, 101, 100, 45, 97, 100, 109, 105, 115, 115, 105, 111, 110, 115, 34]), ([34, 118, 101, 114, 115, 105, 111, 110, 34, 58] ++ [50])])

theorem declarations_wire (fuel : Nat) (source : List PsMinCoreDeclaration)
    (h : psMinCoreDeclarationsValid fuel source = true) :
    DeclarationsWire source (psMinCoreEncodeDeclarations source) := by
  induction fuel generalizing source with
  | zero =>
    cases source with
    | nil => exact .nil
    | cons decl rest => cases h
  | succ fuel ih =>
    cases source with
    | nil => exact .nil
    | cons decl rest =>
      simp only [psMinCoreDeclarationsValid] at h
      repeat' split at h
      all_goals try contradiction
      apply DeclarationsWire.cons
      · cases decl with
        | mk name height type value =>
          simpa only [psMinCoreEncodeDeclaration, object_eq, append_eq, quote_eq] using
            DeclarationWire.definition name height type value _ _ _ _
              (name_wire 16 name (by assumption)) (number_wire height)
              (expression_wire 48 type (by assumption)) (expression_wire 48 value (by assumption))
      · exact ih rest h

theorem decode_success_has_wire_derivation (bytes : List Nat) (candidate source : List PsMinCoreDeclaration)
    (h : psMinCoreDecodeCertificate bytes candidate = some source) : PacketWire source bytes := by
  obtain ⟨_, wellformed⟩ := decode_success_is_well_formed bytes candidate source h
  rw [wellformed.exactBytes]
  simpa only [psMinCoreEncode, object_eq, array_eq, append_eq] using
    PacketWire.packet source (psMinCoreEncodeDeclarations source)
      (declarations_wire 128 source wellformed.syntaxBound)

theorem byte_admission_source_model (bytes : List Nat) (candidate : List PsMinCoreDeclaration)
    (accepted : PsMinCoreAdmission) (h : psMinCoreAdmit bytes candidate = some accepted) :
    PacketWire accepted.source bytes ∧
    Ps.MinKernel.CoreTranslation.EnvironmentImage [] accepted.source accepted.normalized ∧
    ∃ model, Ps.MinKernel.CoreSemantics.SourceHistory [] [] accepted.source accepted.types
      (Ps.MinKernel.RegularProofs.emptyModel []) model := by
  obtain ⟨wellformed, image, model, history⟩ :=
    Ps.MinKernel.CoreSemantics.canonical_source_model bytes candidate accepted h
  refine ⟨?_, image, model, history⟩
  rw [wellformed.exactBytes]
  simpa only [psMinCoreEncode, object_eq, array_eq, append_eq] using
    PacketWire.packet accepted.source (psMinCoreEncodeDeclarations accepted.source)
      (declarations_wire 128 accepted.source wellformed.syntaxBound)

theorem byte_admission_consistent (bytes : List Nat) (candidate : List PsMinCoreDeclaration)
    (accepted : PsMinCoreAdmission) (h : psMinCoreAdmit bytes candidate = some accepted) :
    ∀ declaration ∈ accepted.source,
      declaration.type ≠ Ps.MinKernel.CoreSemantics.canonicalFalseType :=
  Ps.MinKernel.CoreSemantics.canonical_no_false_declaration bytes candidate accepted h

#print axioms append_assoc_checked
#print axioms append_nil_checked
#print axioms nil_append_checked
#print axioms append_eq
#print axioms join_tail_eq
#print axioms object_eq
#print axioms array_eq
#print axioms quote_eq
#print axioms commaBytes
#print axioms objectBytes
#print axioms increment_value
#print axioms increment_nonzero
#print axioms digits_canonical
#print axioms decimal_value
#print axioms decimal_symbols
#print axioms name_wire
#print axioms number_wire
#print axioms safe_text
#print axioms name_wire
#print axioms expression_wire
#print axioms decode_success_has_wire_derivation
#print axioms byte_admission_source_model
#print axioms byte_admission_consistent
end Ps.MinKernel.CoreEncoding
