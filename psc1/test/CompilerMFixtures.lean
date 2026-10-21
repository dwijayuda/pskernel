import ProofScript.Compiler.Effect

namespace Ps.Internal.CompilerMContract

def stateProgram (flag : Bool) : CompilerM Nat Nat Nat Nat := do
  let context : Nat <- compilerRead ()
  let original : Nat <- compilerGet ()
  let captured : Nat -> Nat := fun (n : Nat) => original + n
  compilerSet (original + context)
  compilerModify (fun (n : Nat) => n + 2)
  let current : Nat <- compilerGet ()
  return captured (if flag then current else context)

def earlyProgram (flag : Bool) : CompilerM Nat Nat Nat Nat := do
  let mut total : Nat := 0
  for i in [0:3] do
    let old : Nat <- compilerGet ()
    compilerSet (old + 1)
    total := total + old
    if flag && Nat.beq i 1 then
      return total
  compilerSet 99
  return total

def failureProgram (flag : Bool) : CompilerM Nat Nat Nat Nat := do
  compilerSet 50
  if flag then
    let ignored : Unit <- compilerThrow 13
    compilerSet 999
  return 7

def recoveryProgram (flag : Bool) : CompilerM Nat Nat Nat Nat :=
  compilerTryCatch (failureProgram flag)
    (fun (error : Nat) => do
      let original : Nat <- compilerGet ()
      compilerSet (original + error)
      return (error + 100))

def readerProgram (flag : Bool) : CompilerM Nat Nat Nat Nat := do
  let inside : Nat <- compilerWithReader (stateProgram flag)
    (fun (context : Nat) => context + 10)
  let outside : Nat <- compilerRead ()
  return (inside + outside)

def unitProgram (flag : Bool) : CompilerM Nat Nat Nat Nat := do
  let () : Unit := ()
  compilerSet (if flag then 4 else 6)
  let state : Nat <- compilerGet ()
  let (value, (_, extra)) : Nat × (Bool × Nat) := (state, (flag, 3))
  return (value + extra)

def callbackProgram (flag : Bool) : CompilerM Nat Nat Nat (Nat -> Nat) := do
  let original : Nat <- compilerGet ()
  let captured : Nat -> Nat := fun (value : Nat) => original + value
  compilerSet 20
  return captured

def handlerProgram (flag : Bool) : CompilerM Nat Nat Nat Nat := do
  let mut amount : Nat := 2
  try
    compilerSet 50
    amount := 10
    if flag then
      throw 7
    amount := amount + 1
  catch error =>
    let restored : Nat <- compilerGet ()
    amount := amount + restored + error
    compilerSet (amount + 1)
  return amount

def handlerEarlyProgram (flag : Bool) : CompilerM Nat Nat Nat Nat := do
  try
    compilerSet 9
    if flag then
      return 31
    throw 6
  catch error =>
    compilerSet 99
    return (error + 70)

def observe (program : CompilerM Nat Nat Nat Nat) : Nat :=
  match program.run 3 7 with
  | Result.error error => error * 100000 + 99999
  | Result.ok pair => pair.fst * 100000 + pair.snd

end Ps.Internal.CompilerMContract

def stateCase (flag : Bool) : Nat := Ps.Internal.CompilerMContract.observe (Ps.Internal.CompilerMContract.stateProgram flag)
def earlyCase (flag : Bool) : Nat := Ps.Internal.CompilerMContract.observe (Ps.Internal.CompilerMContract.earlyProgram flag)
def failureCase (flag : Bool) : Nat := Ps.Internal.CompilerMContract.observe (Ps.Internal.CompilerMContract.failureProgram flag)
def recoveryCase (flag : Bool) : Nat := Ps.Internal.CompilerMContract.observe (Ps.Internal.CompilerMContract.recoveryProgram flag)
def readerCase (flag : Bool) : Nat := Ps.Internal.CompilerMContract.observe (Ps.Internal.CompilerMContract.readerProgram flag)
def unitCase (flag : Bool) : Nat := Ps.Internal.CompilerMContract.observe (Ps.Internal.CompilerMContract.unitProgram flag)

-- Returned callbacks remain owned through product fields, arrays and options.
def callbackCase (flag : Bool) : Nat :=
  let program : CompilerM Nat Nat Nat (Nat -> Nat) := Ps.Internal.CompilerMContract.callbackProgram flag;
  match program.run 3 7 with
  | Result.error error => error
  | Result.ok pair =>
      let fallback : Option (Nat -> Nat) := Option.some pair.fst;
      let callbacks : Array (Nat -> Nat) := #[pair.fst];
      let selected : Option (Nat -> Nat) := callbacks[if flag then 0 else 1]?;
      match selected with
      | Option.some callback => callback 4 + pair.snd
      | Option.none =>
          match fallback with
          | Option.some callback => callback 2 + pair.snd
          | Option.none => 999

def handlerCase (flag : Bool) : Nat := Ps.Internal.CompilerMContract.observe (Ps.Internal.CompilerMContract.handlerProgram flag)
def handlerEarlyCase (flag : Bool) : Nat := Ps.Internal.CompilerMContract.observe (Ps.Internal.CompilerMContract.handlerEarlyProgram flag)
