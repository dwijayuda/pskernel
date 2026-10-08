import Ps.Kernel.Environment

/- Intrinsic String fragment: an opaque Type with well-formed UTF-8 literals.
No public declaration can install the intrinsic marker. This deliberately does
not implement Lean String constructors, byte arrays, projections or operations.
Every input byte and comparison is charged to the enclosing transition budget. -/

def psKernelBuiltinStringName : PsKernelName :=
  PsKernelName.str PsKernelName.anonymous (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit0 PsKernelPositive.one))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 PsKernelPositive.one))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 PsKernelPositive.one))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 PsKernelPositive.one))))))) PsKernelText.empty))))))

inductive PsKernelUtf8Mode where
  | start
  | one
  | two
  | three
  | e0
  | ed
  | f0
  | f4

inductive PsKernelUtf8Range where
  | range (low high : PsKernelNatural) (next : PsKernelUtf8Mode)

def psKernelUtf8Ranges (mode : PsKernelUtf8Mode) : PsKernelList PsKernelUtf8Range :=
  match mode with
  | PsKernelUtf8Mode.start =>
      (PsKernelList.cons (PsKernelUtf8Range.range PsKernelNatural.zero (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one))))))) PsKernelUtf8Mode.start) (PsKernelList.cons (PsKernelUtf8Range.range (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 PsKernelPositive.one)))))))) (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 PsKernelPositive.one)))))))) PsKernelUtf8Mode.one) (PsKernelList.cons (PsKernelUtf8Range.range (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one)))))))) (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one)))))))) PsKernelUtf8Mode.e0) (PsKernelList.cons (PsKernelUtf8Range.range (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one)))))))) (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one)))))))) PsKernelUtf8Mode.two) (PsKernelList.cons (PsKernelUtf8Range.range (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one)))))))) (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one)))))))) PsKernelUtf8Mode.ed) (PsKernelList.cons (PsKernelUtf8Range.range (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one)))))))) (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one)))))))) PsKernelUtf8Mode.two) (PsKernelList.cons (PsKernelUtf8Range.range (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one)))))))) (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one)))))))) PsKernelUtf8Mode.f0) (PsKernelList.cons (PsKernelUtf8Range.range (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one)))))))) (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one)))))))) PsKernelUtf8Mode.three) (PsKernelList.cons (PsKernelUtf8Range.range (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one)))))))) (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one)))))))) PsKernelUtf8Mode.f4) PsKernelList.nil)))))))))
  | PsKernelUtf8Mode.one =>
      (PsKernelList.cons (PsKernelUtf8Range.range (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 PsKernelPositive.one)))))))) (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 PsKernelPositive.one)))))))) PsKernelUtf8Mode.start) PsKernelList.nil)
  | PsKernelUtf8Mode.two =>
      (PsKernelList.cons (PsKernelUtf8Range.range (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 PsKernelPositive.one)))))))) (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 PsKernelPositive.one)))))))) PsKernelUtf8Mode.one) PsKernelList.nil)
  | PsKernelUtf8Mode.three =>
      (PsKernelList.cons (PsKernelUtf8Range.range (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 PsKernelPositive.one)))))))) (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 PsKernelPositive.one)))))))) PsKernelUtf8Mode.two) PsKernelList.nil)
  | PsKernelUtf8Mode.e0 =>
      (PsKernelList.cons (PsKernelUtf8Range.range (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit0 PsKernelPositive.one)))))))) (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 PsKernelPositive.one)))))))) PsKernelUtf8Mode.one) PsKernelList.nil)
  | PsKernelUtf8Mode.ed =>
      (PsKernelList.cons (PsKernelUtf8Range.range (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 PsKernelPositive.one)))))))) (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 PsKernelPositive.one)))))))) PsKernelUtf8Mode.one) PsKernelList.nil)
  | PsKernelUtf8Mode.f0 =>
      (PsKernelList.cons (PsKernelUtf8Range.range (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 PsKernelPositive.one)))))))) (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 PsKernelPositive.one)))))))) PsKernelUtf8Mode.two) PsKernelList.nil)
  | PsKernelUtf8Mode.f4 =>
      (PsKernelList.cons (PsKernelUtf8Range.range (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 PsKernelPositive.one)))))))) (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 PsKernelPositive.one)))))))) PsKernelUtf8Mode.two) PsKernelList.nil)

inductive PsKernelUtf8State where
  | scan (mode : PsKernelUtf8Mode) (text : PsKernelText)
  | ranges (value : PsKernelNatural) (text : PsKernelText) (ranges : PsKernelList PsKernelUtf8Range)
  | lower (value : PsKernelNatural) (text : PsKernelText) (high : PsKernelNatural)
      (mode : PsKernelUtf8Mode) (ranges : PsKernelList PsKernelUtf8Range) (state : PsKernelNumericState)
  | upper (value : PsKernelNatural) (text : PsKernelText) (mode : PsKernelUtf8Mode)
      (ranges : PsKernelList PsKernelUtf8Range) (state : PsKernelNumericState)

inductive PsKernelUtf8Step where
  | next (state : PsKernelUtf8State)
  | valid
  | invalid
  | invalidState

def psKernelUtf8Start (text : PsKernelText) : PsKernelUtf8State :=
  PsKernelUtf8State.scan PsKernelUtf8Mode.start text

def psKernelUtf8Step (state : PsKernelUtf8State) : PsKernelUtf8Step :=
  match state with
  | PsKernelUtf8State.scan mode text =>
      match text with
      | PsKernelText.empty =>
          match mode with
          | PsKernelUtf8Mode.start => PsKernelUtf8Step.valid
          | _ => PsKernelUtf8Step.invalid
      | PsKernelText.byte value rest => PsKernelUtf8Step.next
          (PsKernelUtf8State.ranges value rest (psKernelUtf8Ranges mode))
  | PsKernelUtf8State.ranges value text ranges =>
      match ranges with
      | PsKernelList.nil => PsKernelUtf8Step.invalid
      | PsKernelList.cons range rest =>
          match range with
          | PsKernelUtf8Range.range low high mode => PsKernelUtf8Step.next
              (PsKernelUtf8State.lower value text high mode rest
                (PsKernelNumericState.order value low PsKernelOrder.same))
  | PsKernelUtf8State.lower value text high mode ranges current =>
      match psKernelNumericStep current with
      | PsKernelNumericStep.next next => PsKernelUtf8Step.next
          (PsKernelUtf8State.lower value text high mode ranges next)
      | PsKernelNumericStep.ordered order =>
          match order with
          | PsKernelOrder.less => PsKernelUtf8Step.next (PsKernelUtf8State.ranges value text ranges)
          | _ => PsKernelUtf8Step.next (PsKernelUtf8State.upper value text mode ranges
              (PsKernelNumericState.order value high PsKernelOrder.same))
      | _ => PsKernelUtf8Step.invalidState
  | PsKernelUtf8State.upper value text mode ranges current =>
      match psKernelNumericStep current with
      | PsKernelNumericStep.next next => PsKernelUtf8Step.next
          (PsKernelUtf8State.upper value text mode ranges next)
      | PsKernelNumericStep.ordered order =>
          match order with
          | PsKernelOrder.greater => PsKernelUtf8Step.next (PsKernelUtf8State.ranges value text ranges)
          | _ => PsKernelUtf8Step.next (PsKernelUtf8State.scan mode text)
      | _ => PsKernelUtf8Step.invalidState

inductive PsKernelTextCheckState where
  | lookup (text : PsKernelText) (state : PsKernelLookupState)
  | validate (state : PsKernelUtf8State)

inductive PsKernelTextCheckStep where
  | next (state : PsKernelTextCheckState)
  | ready
  | rejected (error : PsKernelCheckError)

def psKernelTextCheckStart (env : PsKernelList PsKernelDefinition) (text : PsKernelText) : PsKernelTextCheckState :=
  PsKernelTextCheckState.lookup text (PsKernelLookupState.search psKernelBuiltinStringName env)

def psKernelTextCheckStep (state : PsKernelTextCheckState) : PsKernelTextCheckStep :=
  match state with
  | PsKernelTextCheckState.lookup text current =>
      match psKernelLookupStep current with
      | PsKernelLookupStep.next next => PsKernelTextCheckStep.next (PsKernelTextCheckState.lookup text next)
      | PsKernelLookupStep.missing => PsKernelTextCheckStep.rejected PsKernelCheckError.unknownConstant
      | PsKernelLookupStep.invalidState => PsKernelTextCheckStep.rejected PsKernelCheckError.invalidState
      | PsKernelLookupStep.found entry =>
          match entry with
          | PsKernelDefinition.stringType unusedName => PsKernelTextCheckStep.next
              (PsKernelTextCheckState.validate (psKernelUtf8Start text))
          | _ => PsKernelTextCheckStep.rejected PsKernelCheckError.unsupported
  | PsKernelTextCheckState.validate current =>
      match psKernelUtf8Step current with
      | PsKernelUtf8Step.next next => PsKernelTextCheckStep.next (PsKernelTextCheckState.validate next)
      | PsKernelUtf8Step.valid => PsKernelTextCheckStep.ready
      | PsKernelUtf8Step.invalid => PsKernelTextCheckStep.rejected PsKernelCheckError.invalidText
      | PsKernelUtf8Step.invalidState => PsKernelTextCheckStep.rejected PsKernelCheckError.invalidState

/- This fixed intrinsic rule is part of the kernel, not an axiom ingress API.
It introduces only String : Type and never supplies a proof or a recursor. -/
inductive PsKernelStringPreludeState where
  | check (environment : PsKernelList PsKernelDefinition) (state : PsKernelLookupState)

inductive PsKernelStringPreludeStep where
  | next (state : PsKernelStringPreludeState)
  | ready (environment : PsKernelList PsKernelDefinition)
  | rejected (error : PsKernelCheckError)

def psKernelStringPreludeStart (env : PsKernelList PsKernelDefinition) : PsKernelStringPreludeState :=
  PsKernelStringPreludeState.check env (PsKernelLookupState.search psKernelBuiltinStringName env)

def psKernelStringPreludeStep (state : PsKernelStringPreludeState) : PsKernelStringPreludeStep :=
  match state with
  | PsKernelStringPreludeState.check env current =>
      match psKernelLookupStep current with
      | PsKernelLookupStep.next next => PsKernelStringPreludeStep.next (PsKernelStringPreludeState.check env next)
      | PsKernelLookupStep.missing => PsKernelStringPreludeStep.ready
          (PsKernelList.cons (PsKernelDefinition.stringType psKernelBuiltinStringName) env)
      | PsKernelLookupStep.found unused => PsKernelStringPreludeStep.rejected PsKernelCheckError.duplicateName
      | PsKernelLookupStep.invalidState => PsKernelStringPreludeStep.rejected PsKernelCheckError.invalidState
