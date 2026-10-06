def etaConditional (choose : Bool) (offset : Nat) : Nat -> Nat :=
  if choose then
    fun (value : Nat) => Nat.add offset value
  else
    fun (value : Nat) => Nat.sub value offset

def etaCapture (__ps_eta_0 : Nat) : Nat -> Nat :=
  let captured : Nat := __ps_eta_0;
  fun (__ps_eta_1 : Nat) => Nat.add captured __ps_eta_1

def etaShadow (offset : Nat) : Nat -> Nat :=
  let saved : Nat := offset;
  fun (offset : Nat) => Nat.add saved offset

def etaForward (callback : Nat -> Nat) : Nat -> Nat := callback
def etaIdentity (value : Nat) : Nat := value

def etaMatch (fuel : Nat) : Nat -> Nat :=
  match fuel with
  | Nat.zero => fun (value : Nat) => value
  | Nat.succ rest =>
      let bias : Nat := Nat.add rest 1;
      fun (value : Nat) => Nat.add bias value

def etaCount (fuel : Nat) : Nat -> Nat :=
  match fuel with
  | Nat.zero => fun (total : Nat) => total
  | Nat.succ remaining =>
      let smaller : Nat -> Nat := etaCount remaining;
      fun (total : Nat) => smaller (Nat.succ total)

def etaRuntimeCheck : Bool := Nat.beq (etaCount 1000 40) 1040

def etaCaptureCheck : Bool := Nat.beq (etaCapture 2 40) 42
def etaShadowCheck : Bool := Nat.beq (etaShadow 2 40) 42
def etaMatchZeroCheck : Bool := Nat.beq (etaMatch 0 40) 40
def etaMatchSuccessorCheck : Bool := Nat.beq (etaMatch 2 40) 42
def etaConditionalTrueCheck : Bool := Nat.beq (etaConditional Bool.true 2 40) 42
def etaConditionalFalseCheck : Bool := Nat.beq (etaConditional Bool.false 2 40) 38
def etaForwardCheck : Bool := Nat.beq (etaForward etaIdentity 42) 42
