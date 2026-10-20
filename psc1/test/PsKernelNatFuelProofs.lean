import Ps.KernelCore.API.Dag

/-!
Exact extensional equivalence of delayed recursive aliases for every supplied
fuel. The old worker equations live only in this native proof file. This proves
preservation of arithmetic results and zero-fuel behavior, not whole-kernel
soundness or a runtime allocation bound.
-/
namespace PsKernelNatFuelProofs

def beforeNatGcdWithFuel
    (fuel : Nat) :
    Nat -> Nat -> Nat :=
  match fuel with
  | Nat.zero =>
      fun
        (left : Nat)
        (_right : Nat) =>
        left
  | Nat.succ remaining =>
      let smaller :
          Nat -> Nat -> Nat :=
        beforeNatGcdWithFuel remaining;
      fun
        (left : Nat)
        (right : Nat) =>
        if Nat.beq right 0 then
          left
        else
          smaller
            right
            (Nat.mod left right)

def beforeNatHeapWordCountWithFuel
    (fuel : Nat) :
    Nat -> Nat :=
  match fuel with
  | Nat.zero =>
      fun (_value : Nat) =>
        0
  | Nat.succ remaining =>
      let smaller : Nat -> Nat :=
        beforeNatHeapWordCountWithFuel remaining;
      fun (value : Nat) =>
        if Nat.beq value 0 then
          0
        else
          Nat.succ
            (smaller
              (Nat.div
                value
                psKernelNatWordBase))

def beforeNatPowWithFuel
    (fuel : Nat) :
    Nat -> Nat -> Nat :=
  match fuel with
  | Nat.zero =>
      fun
        (_base : Nat)
        (_exponent : Nat) =>
        1
  | Nat.succ remaining =>
      let smaller :
          Nat -> Nat -> Nat :=
        beforeNatPowWithFuel remaining;
      fun
        (base : Nat)
        (exponent : Nat) =>
        if Nat.beq exponent 0 then
          1
        else
          let halfExponent :=
            Nat.div exponent 2;
          let half :=
            smaller
              base
              halfExponent;
          let squared :=
            Nat.mul half half;
          if
              Nat.beq
                (Nat.mod exponent 2)
                0 then
            squared
          else
            Nat.mul
              base
              squared

def beforeNatBitwiseWithFuel
    (fuel : Nat) :
    PsKernelNatBitwiseOp ->
    Nat ->
    Nat ->
    Nat :=
  match fuel with
  | Nat.zero =>
      fun
        (_op : PsKernelNatBitwiseOp)
        (_left : Nat)
        (_right : Nat) =>
        0
  | Nat.succ remaining =>
      let smaller :
          PsKernelNatBitwiseOp ->
          Nat ->
          Nat ->
          Nat :=
        beforeNatBitwiseWithFuel remaining;
      fun
        (op : PsKernelNatBitwiseOp)
        (left : Nat)
        (right : Nat) =>
        if Nat.beq left 0 then
          if Nat.beq right 0 then
            0
          else
            let low :=
              psKernelNatBitResult
                op
                0
                (Nat.mod right 2);
            let rest :=
              smaller
                op
                0
                (Nat.div right 2);
            Nat.add
              low
              (Nat.mul 2 rest)
        else
          let low :=
            psKernelNatBitResult
              op
              (Nat.mod left 2)
              (Nat.mod right 2);
          let rest :=
            smaller
              op
              (Nat.div left 2)
              (Nat.div right 2);
          Nat.add
            low
            (Nat.mul 2 rest)

def beforeNatShiftRightWithFuel
    (fuel : Nat) :
    Nat -> Nat -> Nat :=
  match fuel with
  | Nat.zero =>
      fun
        (value : Nat)
        (_count : Nat) =>
        value
  | Nat.succ remaining =>
      let smaller :
          Nat -> Nat -> Nat :=
        beforeNatShiftRightWithFuel remaining;
      fun
        (value : Nat)
        (count : Nat) =>
        if Nat.beq count 0 then
          value
        else if Nat.beq value 0 then
          0
        else
          smaller
            (Nat.div value 2)
            (Nat.sub count 1)

theorem NatGcdWithFuel_delayed_recursion_preserves (fuel : Nat) :
    psKernelNatGcdWithFuel fuel = beforeNatGcdWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ fuel ih =>
      funext left right
      simp only [psKernelNatGcdWithFuel, beforeNatGcdWithFuel, ih]

#print axioms NatGcdWithFuel_delayed_recursion_preserves

theorem NatHeapWordCountWithFuel_delayed_recursion_preserves (fuel : Nat) :
    psKernelNatHeapWordCountWithFuel fuel = beforeNatHeapWordCountWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ fuel ih =>
      funext value
      simp only [psKernelNatHeapWordCountWithFuel, beforeNatHeapWordCountWithFuel, ih]

#print axioms NatHeapWordCountWithFuel_delayed_recursion_preserves

theorem NatPowWithFuel_delayed_recursion_preserves (fuel : Nat) :
    psKernelNatPowWithFuel fuel = beforeNatPowWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ fuel ih =>
      funext base exponent
      simp only [psKernelNatPowWithFuel, beforeNatPowWithFuel, ih]

#print axioms NatPowWithFuel_delayed_recursion_preserves

theorem NatBitwiseWithFuel_delayed_recursion_preserves (fuel : Nat) :
    psKernelNatBitwiseWithFuel fuel = beforeNatBitwiseWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ fuel ih =>
      funext op left right
      simp only [psKernelNatBitwiseWithFuel, beforeNatBitwiseWithFuel, ih]

#print axioms NatBitwiseWithFuel_delayed_recursion_preserves

theorem NatShiftRightWithFuel_delayed_recursion_preserves (fuel : Nat) :
    psKernelNatShiftRightWithFuel fuel = beforeNatShiftRightWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ fuel ih =>
      funext value count
      simp only [psKernelNatShiftRightWithFuel, beforeNatShiftRightWithFuel, ih]

#print axioms NatShiftRightWithFuel_delayed_recursion_preserves

private def require (label : String) (ok : Bool) : IO Unit := do
  if !ok then throw (IO.userError ("PSKERNEL_LARGE_NAT_FAILED " ++ label))

private def largeNumeralRegression : IO Unit := do
  let b63 : Nat := 9223372036854775808
  let b64 : Nat := 18446744073709551616
  let b128 : Nat := 340282366920938463463374607431768211456
  for (value, words, bytes) in
      [(0,0,8),(b63,1,8),(b64-1,1,8),(b64,2,16),(b128,3,24),(b128+31,3,24)] do
    require "heap-words" (psKernelNatHeapWordCount value == words)
    require "size-bytes" (psKernelNatSizeInBytes value == bytes)
    require "exact-boundary" (match psKernelCheckNatSize bytes value with
      | .ok _ => true | _ => false)
    require "below-boundary" (match psKernelCheckNatSize (bytes-1) value with
      | .error _ => true | _ => false)
  require "gcd" (psKernelNatGcd (3*b128) (5*b128) == b128)
  require "gcd-coprime" (psKernelNatGcd (b128+1) b128 == 1)
  require "pow-zero" (psKernelNatPow 0 4294967295 == 0)
  require "pow-one" (psKernelNatPow 1 4294967295 == 1)
  require "pow-two" (psKernelNatPow 2 128 == b128)
  require "bit-and" (psKernelNatBitwise .land (b128+31) (b128+85) == b128+21)
  require "bit-or" (psKernelNatBitwise .lor (b128+31) (b128+85) == b128+95)
  require "bit-xor" (psKernelNatBitwise .xor (b128+31) (b128+85) == 74)
  require "shift" (psKernelNatShiftRight (b128+31) 128 == 1)
  require "shift-huge" (psKernelNatShiftRight (b128+31) 4294967296 == 0)
  require "zero-fuel" (psKernelNatGcdWithFuel 0 17 9 == 17 &&
    psKernelNatHeapWordCountWithFuel 0 b128 == 0 &&
    psKernelNatPowWithFuel 0 2 128 == 1 &&
    psKernelNatBitwiseWithFuel 0 .lor b128 b128 == 0 &&
    psKernelNatShiftRightWithFuel 0 b128 128 == b128)
  IO.println "PSKERNEL_LARGE_NAT_NATIVE: PASS"

#eval largeNumeralRegression

end PsKernelNatFuelProofs
