import Ps.Environment.StandardUnsignedFoundationData
import Ps.Environment.StandardNumeric
import Ps.Environment.StandardScalarArithmetic
import Ps.Environment.StandardRepr

/-
Selected scalar dictionaries follow Lean 4.35.0 Init/Prelude.lean,
Init/Data/Repr.lean and Init/Data/ToString/Basic.lean.
Copyright (c) Microsoft Corporation. Apache-2.0; see THIRD_PARTY_NOTICES.md.
Modified: checked Core dictionary builders over the admitted UInt model.
-/
def psStandardUnsignedScalarInstances : List (String × PsDeclaration) :=
  ["UInt8", "UInt16", "UInt32", "UInt64"].flatMap fun owner =>
    let type := PsExpr.constE (psRootName owner) []
    let natural := psOrderCall (owner ++ ".toNat") [.fvar 0]
    let text := psOrderCall "Nat.repr" [natural]
    let printer := psLogicLam 0 "value" type text
    let repr := psLogicLam 0 "value" type (psLogicLam 1 "prec" psOrderNat
      (psFormatCall "text" [text]))
    let atom := PsDeclaration.definitionDecl
      (psDecisionName ("PsStandard.instReprAtom" ++ owner)) []
      (psFormatClassType "ReprAtom" type)
      (.app (.constE (psDecisionName "ReprAtom.mk") [.zero]) type)
    -- Lean's general BEq fallback uses DecidableEq. Here each selected
    -- UInt has an injective bounded-Nat model with a checked toNat method.
    -- Comparing its canonical Nat representations via checked Nat.beq
    -- preserves the upstream Boolean equality without importing unrelated
    -- DecidableEq proof dependencies. All widths share this construction.
    let equality := psLogicLam 0 "left" type
      (psLogicLam 1 "right" type
        (psOrderCall "Nat.beq"
          [psOrderCall (owner ++ ".toNat") [.fvar 0],
           psOrderCall (owner ++ ".toNat") [.fvar 1]]))
    [("BEq", psStandardBEqInstance owner type equality),
     ("Inhabited", psStandardInhabitedGround owner type
       (psOrderCall (owner ++ ".ofNat") [.lit (.natural 0)])),
     ("ToString", psStandardToStringInstance owner type printer),
     ("Repr", psFormatGroundInstance "Repr" ("Repr" ++ owner) type repr),
     ("ReprAtom", atom)]

-- Reviewed native closure: 80 declarations, four former UInt axioms replaced
-- by their actual BitVec structures, no new axiom. Native instance extensions
-- are explicit; proof dependencies do not silently register new search rules.
def psStandardUnsignedExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardUnsignedFoundationDeclarations.foldl psEnvironmentInsert environment
  let environment := psStandardUnsignedFoundationReducibility.foldl (fun env (name, status) =>
    psEnvironmentSetReducibility env name status) environment
  let instances := psStandardUnsignedFoundationDeclarations.foldl (fun index d =>
    let name := psNameToString (psDeclarationName d)
    if ["UInt8.instOfNat", "UInt16.instOfNat", "UInt32.instOfNat", "UInt64.instOfNat"].contains name then
      psInstanceIndexAdd index {
        value := .constE (psDeclarationName d) []
        levelParams := []
        type := psDeclarationType d
        className := some (psRootName "OfNat") }
    else index) environment.instances
  let environment := { environment with instances }
  let environment := (psStandardUnsignedScalarInstances.map Prod.snd).foldl psEnvironmentInsert environment
  psStandardUnsignedScalarInstances.foldl (fun env (className, declaration) =>
    psStandardRegisterInstances env className [declaration]) environment

-- Intrinsic bodies and their proof closure are not emitted as support code.
-- BitVec/Fin keep their prepared record layout; UInt uses the scalar boundary.
def psStandardUnsignedRuntimeDeclarations : List PsDeclaration :=
  psStandardUnsignedScalarInstances.map Prod.snd ++ (psStandardUnsignedFoundationDeclarations.filter fun d =>
    ["UInt8.size", "UInt16.size", "UInt32.size", "UInt64.size",
      "BitVec", "BitVec.ofFin", "BitVec.rec", "UInt8.instOfNat",
      "UInt16.instOfNat", "UInt32.instOfNat", "UInt64.instOfNat"].contains
      (psNameToString (psDeclarationName d))) ++
  psStandardScalarArithmeticDeclarations.filter (fun d =>
    psNameToString (psDeclarationName d) == "instOfNatNat")
