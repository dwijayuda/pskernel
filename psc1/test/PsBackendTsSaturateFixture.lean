/- Portable source fixture for the opt-in saturated-call backend.
   These functions are ordinary checked source; no optimization annotation
   or kernel-name recognition participates in their execution. -/

inductive SatIndex where
  | empty
  | bucket (entries : List Nat)
  | branch (left right : SatIndex)

def satLookupWorker
    (fuel : Nat) (index : SatIndex) (hash : Nat) : List Nat :=
  match fuel with
  | Nat.zero =>
      match index with
      | SatIndex.bucket entries => entries
      | _ => List.nil
  | Nat.succ remaining =>
      match index with
      | SatIndex.branch left right =>
          if Nat.beq (Nat.mod hash 2) 0 then
            satLookupWorker remaining left (Nat.div hash 2)
          else satLookupWorker remaining right (Nat.div hash 2)
      | _ => List.nil

def satSetWorker
    (fuel : Nat) (index : SatIndex) (hash : Nat) (entries : List Nat) : SatIndex :=
  match fuel with
  | Nat.zero => SatIndex.bucket entries
  | Nat.succ remaining =>
      let left := match index with
        | SatIndex.branch value _ => value
        | _ => SatIndex.empty;
      let right := match index with
        | SatIndex.branch _ value => value
        | _ => SatIndex.empty;
      if Nat.beq (Nat.mod hash 2) 0 then
        SatIndex.branch (satSetWorker remaining left (Nat.div hash 2) entries) right
      else SatIndex.branch left (satSetWorker remaining right (Nat.div hash 2) entries)

def satLookup (fuel : Nat) : SatIndex -> Nat -> List Nat :=
  match fuel with
  | Nat.zero => fun (index : SatIndex) (hash : Nat) => satLookupWorker 0 index hash
  | Nat.succ remaining =>
      fun (index : SatIndex) (hash : Nat) => satLookupWorker (Nat.succ remaining) index hash

def satSet (fuel : Nat) : SatIndex -> Nat -> List Nat -> SatIndex :=
  match fuel with
  | Nat.zero =>
      fun (index : SatIndex) (hash : Nat) (entries : List Nat) =>
        satSetWorker 0 index hash entries
  | Nat.succ remaining =>
      fun (index : SatIndex) (hash : Nat) (entries : List Nat) =>
        satSetWorker (Nat.succ remaining) index hash entries

def satStage (fuel : Nat) : Nat -> Nat :=
  match fuel with
  | Nat.zero => fun (state : Nat) => state
  | Nat.succ remaining =>
      fun (state : Nat) =>
        let next := satStage remaining;
        next (Nat.add state 1)

def satEffectful (fuel : Nat) (effect : Nat -> Nat) : Nat -> Nat :=
  match fuel with
  | Nat.zero =>
      let seen := effect 0;
      fun (state : Nat) => Nat.add seen state
  | Nat.succ remaining =>
      let seen := effect (Nat.succ remaining);
      fun (state : Nat) =>
        let next := satEffectful remaining effect;
        next (Nat.add state seen)

def satApplyEffect (fuel : Nat) (effect : Nat -> Nat) (state : Nat) : Nat :=
  satStage fuel (effect state)

def satShadow (satStage : Nat -> Nat -> Nat) (first second : Nat) : Nat :=
  satStage first second

def satCaptured (fuel base : Nat) : Nat -> Nat :=
  match fuel with
  | Nat.zero => fun (state : Nat) => Nat.add base state
  | Nat.succ remaining =>
      fun (state : Nat) => satStage (Nat.succ remaining) (Nat.add base state)

def satZeroDiv (fuel : Nat) (value : Nat) : Nat :=
  satStage fuel (Nat.add (Nat.div value 0) (Nat.mod value 0))


/- The interval after the first returned argument is intentionally effectful.
   A two-stage optimization must inspect this interval and decline. -/
def satBetweenStages (fuel : Nat) (effect : Nat -> Nat) : Nat -> Nat -> Nat :=
  match fuel with
  | Nat.zero =>
      fun (first : Nat) =>
        let seen := effect first;
        fun (second : Nat) => Nat.add seen second
  | Nat.succ remaining =>
      fun (first : Nat) =>
        let seen := effect first;
        fun (second : Nat) =>
          let next := satBetweenStages remaining effect;
          next seen second

def satFixedOrder
    (left right : Nat -> Nat) (fuel first second : Nat) : Nat :=
  satCaptured (left fuel) (right first) second
