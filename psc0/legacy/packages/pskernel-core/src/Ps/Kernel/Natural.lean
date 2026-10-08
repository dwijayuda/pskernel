import Ps.Kernel.Data

/- Exact binary arithmetic. Multi-input operations are first-order machines so
all bit work is charged to the enclosing driver; no host floating-point numbers. -/
inductive PsKernelOrder where
  | less
  | same
  | greater

def psKernelPositiveSucc (value : PsKernelPositive) : PsKernelPositive :=
  match value with
  | PsKernelPositive.one => PsKernelPositive.bit0 PsKernelPositive.one
  | PsKernelPositive.bit0 high => PsKernelPositive.bit1 high
  | PsKernelPositive.bit1 high => PsKernelPositive.bit0 (psKernelPositiveSucc high)

def psKernelNaturalSucc (value : PsKernelNatural) : PsKernelNatural :=
  match value with
  | PsKernelNatural.zero => PsKernelNatural.positive PsKernelPositive.one
  | PsKernelNatural.positive high => PsKernelNatural.positive (psKernelPositiveSucc high)

def psKernelPositivePred (value : PsKernelPositive) : PsKernelNatural :=
  match value with
  | PsKernelPositive.one => PsKernelNatural.zero
  | PsKernelPositive.bit1 high => PsKernelNatural.positive (PsKernelPositive.bit0 high)
  | PsKernelPositive.bit0 high =>
      match psKernelPositivePred high with
      | PsKernelNatural.zero => PsKernelNatural.positive PsKernelPositive.one
      | PsKernelNatural.positive rest => PsKernelNatural.positive (PsKernelPositive.bit1 rest)

def psKernelNaturalPred (value : PsKernelNatural) : PsKernelNatural :=
  match value with
  | PsKernelNatural.zero => PsKernelNatural.zero
  | PsKernelNatural.positive high => psKernelPositivePred high

inductive PsKernelBit where
  | zero
  | one

inductive PsKernelDigit where
  | digit (low : PsKernelBit) (high : PsKernelNatural)

inductive PsKernelNumericState where
  | order (left : PsKernelNatural) (right : PsKernelNatural) (lower : PsKernelOrder)
  | add (left : PsKernelNatural) (right : PsKernelNatural) (carry : PsKernelBit) (bits : PsKernelList PsKernelBit)
  | rebuild (bits : PsKernelList PsKernelBit) (value : PsKernelNatural)

inductive PsKernelNumericStep where
  | next (state : PsKernelNumericState)
  | ordered (order : PsKernelOrder)
  | sum (value : PsKernelNatural)

def psKernelNaturalDigit (value : PsKernelNatural) : PsKernelDigit :=
  match value with
  | PsKernelNatural.zero => PsKernelDigit.digit PsKernelBit.zero PsKernelNatural.zero
  | PsKernelNatural.positive positive =>
      match positive with
      | PsKernelPositive.one => PsKernelDigit.digit PsKernelBit.one PsKernelNatural.zero
      | PsKernelPositive.bit0 high => PsKernelDigit.digit PsKernelBit.zero (PsKernelNatural.positive high)
      | PsKernelPositive.bit1 high => PsKernelDigit.digit PsKernelBit.one (PsKernelNatural.positive high)

def psKernelNaturalDoubleBit (value : PsKernelNatural) (bit : PsKernelBit) : PsKernelNatural :=
  match value with
  | PsKernelNatural.zero =>
      match bit with
      | PsKernelBit.zero => PsKernelNatural.zero
      | PsKernelBit.one => PsKernelNatural.positive PsKernelPositive.one
  | PsKernelNatural.positive high =>
      match bit with
      | PsKernelBit.zero => PsKernelNatural.positive (PsKernelPositive.bit0 high)
      | PsKernelBit.one => PsKernelNatural.positive (PsKernelPositive.bit1 high)

def psKernelNumericAddContinue
    (left right : PsKernelNatural) (carry bit : PsKernelBit)
    (bits : PsKernelList PsKernelBit) : PsKernelNumericStep :=
  PsKernelNumericStep.next (PsKernelNumericState.add left right carry (PsKernelList.cons bit bits))

def psKernelNumericAddDigits
    (left right : PsKernelNatural) (a b carry : PsKernelBit)
    (bits : PsKernelList PsKernelBit) : PsKernelNumericStep :=
  match a with
  | PsKernelBit.zero =>
      match b with
      | PsKernelBit.zero => psKernelNumericAddContinue left right PsKernelBit.zero carry bits
      | PsKernelBit.one =>
          match carry with
          | PsKernelBit.zero => psKernelNumericAddContinue left right PsKernelBit.zero PsKernelBit.one bits
          | PsKernelBit.one => psKernelNumericAddContinue left right PsKernelBit.one PsKernelBit.zero bits
  | PsKernelBit.one =>
      match b with
      | PsKernelBit.one => psKernelNumericAddContinue left right PsKernelBit.one carry bits
      | PsKernelBit.zero =>
          match carry with
          | PsKernelBit.zero => psKernelNumericAddContinue left right PsKernelBit.zero PsKernelBit.one bits
          | PsKernelBit.one => psKernelNumericAddContinue left right PsKernelBit.one PsKernelBit.zero bits

def psKernelNumericStep (state : PsKernelNumericState) : PsKernelNumericStep :=
  match state with
  | PsKernelNumericState.order left right lower =>
      match left with
      | PsKernelNatural.zero =>
          match right with
          | PsKernelNatural.zero => PsKernelNumericStep.ordered lower
          | _ => PsKernelNumericStep.ordered PsKernelOrder.less
      | PsKernelNatural.positive unusedLeft =>
          match right with
          | PsKernelNatural.zero => PsKernelNumericStep.ordered PsKernelOrder.greater
          | PsKernelNatural.positive unusedRight =>
              match psKernelNaturalDigit left with
              | PsKernelDigit.digit a leftHigh =>
                  match psKernelNaturalDigit right with
                  | PsKernelDigit.digit b rightHigh =>
                      let nextOrder : PsKernelOrder :=
                        match a with
                        | PsKernelBit.zero =>
                            match b with
                            | PsKernelBit.zero => lower
                            | PsKernelBit.one => PsKernelOrder.less
                        | PsKernelBit.one =>
                            match b with
                            | PsKernelBit.zero => PsKernelOrder.greater
                            | PsKernelBit.one => lower;
                      PsKernelNumericStep.next (PsKernelNumericState.order leftHigh rightHigh nextOrder)
  | PsKernelNumericState.add left right carry bits =>
      match psKernelNaturalDigit left with
      | PsKernelDigit.digit a leftHigh =>
          match psKernelNaturalDigit right with
          | PsKernelDigit.digit b rightHigh =>
              let allZero : PsKernelFlag :=
                match left with
                | PsKernelNatural.zero =>
                    match right with
                    | PsKernelNatural.zero =>
                        match carry with
                        | PsKernelBit.zero => PsKernelFlag.yes
                        | PsKernelBit.one => PsKernelFlag.no
                    | _ => PsKernelFlag.no
                | _ => PsKernelFlag.no;
              match allZero with
              | PsKernelFlag.yes => PsKernelNumericStep.next (PsKernelNumericState.rebuild bits PsKernelNatural.zero)
              | PsKernelFlag.no => psKernelNumericAddDigits leftHigh rightHigh a b carry bits
  | PsKernelNumericState.rebuild bits value =>
      match bits with
      | PsKernelList.nil => PsKernelNumericStep.sum value
      | PsKernelList.cons bit rest =>
          PsKernelNumericStep.next (PsKernelNumericState.rebuild rest (psKernelNaturalDoubleBit value bit))

inductive PsKernelNumericResult where
  | outOfFuel
  | ordered (order : PsKernelOrder)
  | sum (value : PsKernelNatural)

def psKernelNumericRun (fuel : PsKernelFuel) : PsKernelNumericState -> PsKernelNumericResult :=
  match fuel with
  | PsKernelFuel.stop =>
      fun (state : PsKernelNumericState) => PsKernelNumericResult.outOfFuel
  | PsKernelFuel.more remaining =>
      fun (state : PsKernelNumericState) =>
        match psKernelNumericStep state with
        | PsKernelNumericStep.ordered order => PsKernelNumericResult.ordered order
        | PsKernelNumericStep.sum value => PsKernelNumericResult.sum value
        | PsKernelNumericStep.next next =>
            let smaller : PsKernelNumericState -> PsKernelNumericResult := psKernelNumericRun remaining;
            smaller next
