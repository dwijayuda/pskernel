import Ps.Environment.StandardUnsignedOperationsData
import Ps.Environment.StandardArithmetic
import Ps.Environment.StandardClass

-- Native logical definitions and explicit search registrations are separate.
-- Reuse the existing HAdd/HSub/HMul/HDiv/HMod specifications and their output
-- parameter semantics. No scalar-specific parser/elaborator dispatch.
def psStandardUnsignedOperatorInstances : List (String × PsDeclaration) :=
  ["UInt8", "UInt16", "UInt32", "UInt64"].flatMap fun owner =>
    let name := psRootName owner
    let arithmetic := psStandardBinarySpecs.filterMap fun spec => do
      let methodName ← spec.natMethod
      let .str _ method := methodName | none
      return (spec.className, psStandardBinaryInstance spec name (psNameAppendStr name method))
    let type := PsExpr.constE name []
    let neg := PsDeclaration.definitionDecl
      (psNameAppendStr (psRootName "PsStandard") ("instNeg" ++ owner)) []
      (.app (.constE (psRootName "Neg") [.zero]) type)
      (psLogicApply (.constE (psDecisionName "Neg.mk") [.zero])
        [type, .constE (psNameAppendStr name "neg") []])
    arithmetic ++ [("Neg", neg)]

def psStandardUnsignedOperationsExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := (psStandardUnsignedOperationsDeclarations ++
    psStandardUnsignedOperatorInstances.map Prod.snd).foldl psEnvironmentInsert environment
  let environment := psStandardUnsignedOperationsReducibility.foldl (fun env (name, status) =>
    psEnvironmentSetReducibility env name status) environment
  psStandardUnsignedOperatorInstances.foldl (fun env (className, declaration) =>
    psStandardRegisterInstances env className [declaration]) environment

-- Intrinsic method bodies and their bound-proof closure are logical data.
-- Only ordinary dictionaries enter the runtime support catalogue.
def psStandardUnsignedOperationsRuntimeDeclarations : List PsDeclaration :=
  psStandardUnsignedOperatorInstances.map Prod.snd
