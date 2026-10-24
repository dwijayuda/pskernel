import Ps.BackendRust.Module
import Lean

-- Exact retained natural-literal branch, before the measured runtime change.
private def retained (value : Nat) : String :=
  psRustConcat3 "__ps_nat_lit(" (psRustQuote (psNatToString value)) ")"

private def values : List Nat := [
  0,1,255,256,65535,4294967295,4294967296,
  9223372036854775807,9223372036854775808,
  18446744073709551615,18446744073709551616,
  340282366920938463463374607431768211455,
  340282366920938463463374607431768211456,
  115792089237316195423570985008687907853269984665640564039457584007913129639935
]

def main : IO Unit := do
  let declarations := values.zipIdx |>.map (fun (value,index) =>
    {name := "literal" ++ toString index,typeParameters := [],parameters := [],
     resultType := PsVerifiedIrType.primitive .nat,
     body := PsVerifiedIrExpr.literal (.natural value)} : PsVerifiedIrDeclaration)
  let module : PsVerifiedIrModule := {imports := [],structures := [],inductives := [],declarations}
  match psStrictValidateModule module with
  | .error _ => throw (IO.userError "literal fixture strict IR refused")
  | .ok _ => pure ()
  IO.FS.createDirAll "dist/rust-nat-literal"
  for legacy in [true,false] do
    let emitted := values.map (fun value =>
      if legacy then retained value else psRustEmitLiteral (.natural value))
    if !legacy then
      for value in values do
        let actual := psRustEmitLiteral (.natural value)
        let expected := if value <= 18446744073709551615 then
            "PsNat::from(" ++ toString value ++ "u64)"
          else retained value
        if actual != expected then throw (IO.userError "literal range guard changed")
    let text := psRustRuntimePrelude ++
      "\npub fn observe() -> Vec<PsNat> { vec![" ++ String.intercalate ", " emitted ++ "] }\n"
    IO.FS.writeFile ("dist/rust-nat-literal/" ++ (if legacy then "legacy" else "current") ++ ".rs") text
  IO.FS.writeFile "dist/rust-nat-literal/expected.json"
    ((Lean.toJson (values.map toString)).compress ++ "\n")
  IO.println "PSC1_RUST_NAT_LITERAL_NATIVE: strict IR; zero/u32/i64/u64/u128/256-bit boundaries; exact large fallback"
