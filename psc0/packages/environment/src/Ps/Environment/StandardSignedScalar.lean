import Ps.Environment.StandardSignedOperations
import Ps.Environment.StandardUnsigned
import Ps.Environment.StandardClass

/-
Pinned Lean 4.35.0 Init/Data/SInt/Basic.lean (Henrik Böving) and
Init/Prelude.lean, copyright Lean FRO, LLC, Apache-2.0.
Derived portable checked HAdd/HSub/HMul/HDiv/HMod/Neg/OfNat/BEq/Inhabited
dictionaries built entirely from the already officially checked signed
BitVec methods. No native theorem, unsafe cast, or new axiom.
See psc0/THIRD_PARTY_NOTICES.md.
-/

-- Typeclass search and scalar operations use the existing generic H*
-- architecture; the source parser never special-cases signed arithmetic.
def psStandardSignedScalarInstances : List (String × PsDeclaration) :=
  ["Int8", "Int16", "Int32", "Int64"].flatMap fun owner =>
    let name := psRootName owner
    let type := PsExpr.constE name []
    let arithmetic := psStandardBinarySpecs.filterMap fun spec => do
      let methodName ← spec.natMethod
      let .str _ method := methodName | none
      return (spec.className, psStandardBinaryInstance spec name
        (psNameAppendStr name method))
    let negative : PsDeclaration := .definitionDecl
      (psDecisionName ("PsStandard.instNeg" ++ owner)) []
      (.app (.constE (psRootName "Neg") [.zero]) type)
      (psLogicApply (.constE (psDecisionName "Neg.mk") [.zero])
        [type, .constE (psNameAppendStr name "neg") []])
    let n := PsExpr.fvar 1
    let ofNat : PsDeclaration := .definitionDecl
      (psDecisionName ("PsStandard.instOfNat" ++ owner)) []
      (psLogicPi 1 "n" psOrderNat
        (psLogicApply (.constE (psRootName "OfNat") [.zero]) [type, n]))
      (psLogicLam 1 "n" psOrderNat
        (psLogicApply (.constE (psDecisionName "OfNat.mk") [.zero])
          [type, n, psOrderCall (owner ++ ".ofNat") [n]]))
    let bytes := owner.replace "Int" "UInt"
    let bits := fun value => psOrderCall (bytes ++ ".toNat")
      [psOrderCall (owner ++ ".to" ++ bytes) [value]]
    let equal := psLogicLam 0 "left" type
      (psLogicLam 1 "right" type
        (psOrderCall "Nat.beq" [bits (.fvar 0), bits (.fvar 1)]))
    arithmetic ++ [
      ("Neg", negative),
      ("OfNat", ofNat),
      ("BEq", psStandardBEqInstance owner type equal),
      ("Inhabited", psStandardInhabitedGround owner type
        (psOrderCall (owner ++ ".ofNat") [.lit (.natural 0)]))
    ]

def psStandardSignedScalarExtend (environment : PsEnvironment) : PsEnvironment :=
  let instances := psStandardSignedScalarInstances
  let environment := instances.foldl (fun env (_, declaration) =>
    psEnvironmentInsert env declaration) environment
  instances.foldl (fun env (className, declaration) =>
    psStandardRegisterInstances env className [declaration]) environment

-- Class methods and dictionaries are checked logical programs, and must
-- enter the executable prelude to support generic calls after erasure.
def psStandardSignedScalarRuntimeDeclarations : List PsDeclaration :=
  psStandardSignedScalarInstances.map Prod.snd
