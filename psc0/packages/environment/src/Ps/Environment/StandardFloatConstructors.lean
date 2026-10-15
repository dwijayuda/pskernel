import Ps.Environment.StandardFloatConstructorsData
import Ps.Environment.StandardFloatCanonical

/-!
F1 logical constructors with actual pinned Format.Valid proof evidence.
Only the 21-declaration constructor closure is selected here. The independent
30-root mask/representation audit is deliberately not part of this environment.
No Float runtime intrinsic, arithmetic, literal or foreign ABI is enabled.
-/

def psStandardFloatConstructorsPublicDeclarations : List PsDeclaration :=
  [("Float", "UInt64", "fromBits64"), ("Float32", "UInt32", "fromBits32")].map
    fun (owner, word, constructor) =>
      let domain := PsExpr.constE (psRootName word) []
      let result := PsExpr.constE (psRootName owner) []
      .definitionDecl (psDecisionName (owner ++ ".ofBits")) []
        (psLogicPi 0 "bits" domain result)
        (psLogicLam 0 "bits" domain
          (.app (.constE (psDecisionName ("PsV7Native.FloatCanonical." ++ constructor)) [])
            (.fvar 0)))

def psStandardFloatConstructorsExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardFloatConstructorsDeclarations.foldl
    psEnvironmentInsert environment
  let environment := psStandardFloatConstructorsReducibility.foldl (fun env (name, status) =>
    psEnvironmentSetReducibility env name status) environment
  psStandardFloatConstructorsPublicDeclarations.foldl psEnvironmentInsert environment
