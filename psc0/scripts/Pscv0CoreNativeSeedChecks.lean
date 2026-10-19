import Ps.Host.StandardExport

universe u

private def coreSeedUInt8OfNat : Nat → UInt8 := UInt8.ofNat
private def coreSeedUInt8ToUInt32 : UInt8 → UInt32 := UInt8.toUInt32
private def coreSeedUInt8ToUInt64 : UInt8 → UInt64 := UInt8.toUInt64
private def coreSeedUInt32OfNat : Nat → UInt32 := UInt32.ofNat
private def coreSeedUInt32ToNat : UInt32 → Nat := UInt32.toNat
private def coreSeedUInt64OfNat : Nat → UInt64 := UInt64.ofNat
private def coreSeedUInt64ToNat : UInt64 → Nat := UInt64.toNat
private def coreSeedUInt64ToUInt8 : UInt64 → UInt8 := UInt64.toUInt8

private def coreSeedUInt32Binary : List (UInt32 → UInt32 → UInt32) :=
  [UInt32.add, UInt32.sub, UInt32.land, UInt32.lor, UInt32.xor,
   UInt32.shiftLeft, UInt32.shiftRight]
private def coreSeedUInt32Complement : UInt32 → UInt32 := UInt32.complement
private def coreSeedUInt64Binary : List (UInt64 → UInt64 → UInt64) :=
  [UInt64.mul, UInt64.xor, UInt64.shiftRight]

private def coreSeedByteArrayMk : Array UInt8 → ByteArray := ByteArray.mk
private def coreSeedByteArraySize : ByteArray → Nat := ByteArray.size
private def coreSeedByteArrayPush : ByteArray → UInt8 → ByteArray := ByteArray.push
private def coreSeedByteArrayFold {α : Type u} :
    (α → UInt8 → α) → α → ByteArray → Nat → Nat → α :=
  @ByteArray.foldl α
private def coreSeedStringUtf8 : String → ByteArray := String.toUTF8

example : UInt8.toUInt32 (UInt8.ofNat 257) = UInt32.ofNat 1 := rfl
example : UInt32.xor (UInt32.ofNat 17) (UInt32.ofNat 3) = UInt32.ofNat 18 := rfl
example : UInt32.shiftRight (UInt32.ofNat 256) (UInt32.ofNat 8) =
    UInt32.ofNat 1 := rfl
example : UInt64.toUInt8 (UInt64.ofNat 258) = UInt8.ofNat 2 := rfl

def main : IO Unit := do
  PsV7Native.checkCoreExportControls
  IO.println "PSCV0_CORE_NATIVE_SEEDS: PASS typed native byte/word APIs and closed equations"
