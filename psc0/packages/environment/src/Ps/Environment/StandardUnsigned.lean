import Ps.Environment.StandardUnsignedFoundationData
import Ps.Environment.StandardNumeric
import Ps.Environment.StandardScalarArithmetic

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
  { environment with instances }

-- Intrinsic bodies and their proof closure are not emitted as support code.
-- BitVec/Fin keep their prepared record layout; UInt uses the scalar boundary.
def psStandardUnsignedRuntimeDeclarations : List PsDeclaration :=
  (psStandardUnsignedFoundationDeclarations.filter fun d =>
    ["UInt8.size", "UInt16.size", "UInt32.size", "UInt64.size",
      "BitVec", "BitVec.ofFin", "BitVec.rec", "UInt8.instOfNat",
      "UInt16.instOfNat", "UInt32.instOfNat", "UInt64.instOfNat"].contains
      (psNameToString (psDeclarationName d))) ++
  psStandardScalarArithmeticDeclarations.filter (fun d =>
    psNameToString (psDeclarationName d) == "instOfNatNat")
