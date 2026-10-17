/-
Int.toNat follows Lean 4 Init/Data/Int/Basic.lean.
Copyright (c) 2016 Jeremy Avigad. All rights reserved.
Authors: Jeremy Avigad, Leonardo de Moura. Apache-2.0.
See psc0/THIRD_PARTY_NOTICES.md. Modified: portable Core declaration builder.
-/
import Ps.Environment.StandardString

-- Int's logical constructors are independent of its compact backend layout.
-- Replace the old type/constructor assumptions, and check toNat with Int.rec.
-- Execution uses the typed intToNat intrinsic, audited separately from this
-- logical model (as for Array's already selected runtime representation).
def psStandardIntDeclarations : List PsDeclaration :=
  let int := PsExpr.constE psIntName []
  let nat := psOrderNat
  let u := psRootName "u"
  let motive := PsExpr.fvar 0
  let n := PsExpr.fvar 1
  let value := PsExpr.fvar 4
  let positive := PsExpr.app (.constE psIntOfNatName []) n
  let negative := PsExpr.app (.constE psIntNegSuccName []) n
  let motiveType := psLogicPi 4 "value" int (.sortE (.param u))
  let positiveMinor := psLogicPi 1 "n" nat (.app motive positive)
  let negativeMinor := psLogicPi 1 "n" nat (.app motive negative)
  let recType := psLogicPi 0 "motive" motiveType
    (psLogicPi 2 "ofNat" positiveMinor
      (psLogicPi 3 "negSucc" negativeMinor
        (psLogicPi 4 "value" int (.app motive value)))) .implicit
  let recName := psNameAppendStr psIntName "rec"
  let toNat := psLogicApply (.constE recName [.succ .zero])
    [psLogicLam 4 "_" int nat,
     psLogicLam 1 "n" nat n,
     psLogicLam 1 "_" nat (.lit (.natural 0)), value]
  [ .inductiveDecl (.mk psIntName [] psPreludeTypeType 0 0
      [psIntOfNatName, psIntNegSuccName] false),
    .constructorDecl (.mk psIntOfNatName [] (psLogicPi 1 "n" nat int)
      psIntName 0 0 1 []),
    .constructorDecl (.mk psIntNegSuccName [] (psLogicPi 1 "n" nat int)
      psIntName 1 0 1 []),
    .recursorDecl (.mk recName [u] recType [psIntName] 0 0 1 2),
    psOrderDecl "Int.toNat" (psLogicPi 4 "value" int nat)
      (psLogicLam 4 "value" int toNat) ]

def psStandardIntExtend (environment : PsEnvironment) : PsEnvironment :=
  psStandardIntDeclarations.foldl psSelfHostReplacePreludeAxiom environment
