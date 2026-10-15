import Ps.Environment.StandardFloatOperationsData
import Ps.Environment.StandardClass
import Ps.Environment.StandardUnsigned

/-!
Pinned Lean 4.35.0 Float/Float32 operations and decision procedures, exported
with real proof bodies and checked constructive theorem cuts. The complete
logical closure is selected; only dictionaries enter runtime support.
Apache-2.0 upstream attribution is retained in the generated data module.
-/

def psStandardFloatScalarInstances : List (String × PsDeclaration) :=
  ["Float", "Float32"].flatMap fun owner =>
    let name := psRootName owner
    let type : PsExpr := .constE name []
    let arithmetic := psStandardBinarySpecs.filterMap fun spec => do
      let methodName ← spec.natMethod
      let .str _ method := methodName | none
      if !["add", "sub", "mul", "div"].contains method then none else
        some (spec.className, psStandardBinaryInstance spec name
          (psNameAppendStr name method))
    let negative : PsDeclaration := .definitionDecl
      (psDecisionName ("PsStandard.instNeg" ++ owner)) []
      (.app (.constE (psRootName "Neg") [.zero]) type)
      (psLogicApply (.constE (psDecisionName "Neg.mk") [.zero])
        [type, .constE (psNameAppendStr name "neg") []])
    let word := if owner == "Float" then "UInt64" else "UInt32"
    arithmetic ++ [
      ("Neg", negative),
      ("BEq", psStandardBEqInstance owner type
        (.constE (psNameAppendStr name "beq") [])),
      ("Inhabited", psStandardInhabitedGround owner type
        (psOrderCall (owner ++ ".ofBits")
          [psOrderCall (word ++ ".ofNat") [.lit (.natural 0)]]))]

-- Native order and Eq dictionaries retain their original names and proofs.
-- IEEE BEq and canonical-model DecidableEq must never share a dictionary.
def psStandardFloatNativeInstances : List (String × PsDeclaration) :=
  psStandardFloatOperationsDeclarations.filterMap fun declaration =>
    let name := psNameToString (psDeclarationName declaration)
    let className :=
      if ["instLTFloat", "instLTFloat32"].contains name then some "LT"
      else if ["instLEFloat", "instLEFloat32"].contains name then some "LE"
      -- DecidableEq is a reducible Pi alias, not a class. Its result is Decidable.
      else if ["instDecidableEqFloat", "instDecidableEqFloat32"].contains name then some "Decidable"
      else if ["Float.decLt", "Float.decLe", "Float32.decLt", "Float32.decLe"].contains name then some "Decidable"
      else none
    className.map (fun className => (className, declaration))

def psStandardFloatOperationsExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardFloatOperationsDeclarations.foldl
    psEnvironmentInsert environment
  let environment := psStandardFloatOperationsReducibility.foldl (fun env (name, status) =>
    psEnvironmentSetReducibility env name status) environment
  let environment := (psStandardFloatScalarInstances.map Prod.snd).foldl
    psEnvironmentInsert environment
  (psStandardFloatNativeInstances ++ psStandardFloatScalarInstances).foldl
    (fun env (className, declaration) =>
      psStandardRegisterInstances env className [declaration]) environment

def psStandardFloatOperationsRuntimeDeclarations : List PsDeclaration :=
  psStandardFloatScalarInstances.map Prod.snd ++
    (psStandardFloatNativeInstances.filterMap fun (className, declaration) =>
      if className == "LT" || className == "LE" then some declaration else none)
