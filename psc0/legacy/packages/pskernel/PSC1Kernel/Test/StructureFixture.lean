namespace PSC1Kernel.Test

structure EtaPair where
  left : Nat
  right : Nat

structure EtaUnit where

def ProjDeltaA : EtaPair := { left := 1, right := 2 }
def ProjDeltaB : EtaPair := { left := 1, right := 3 }

def DeltaA : Nat := 7
abbrev DeltaB : Nat := DeltaA

end PSC1Kernel.Test
