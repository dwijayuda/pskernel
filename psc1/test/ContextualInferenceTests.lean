import Ps.Compiler.Api
import Ps.CompilerIr.Validate

-- Both frontends, canonical encoding and the checked IR boundary. Independent
-- official kernel admission and target execution live in the host gate.
private def requireAccepted
    (name : String) (kind : PsCompilerSourceKind) (source : String) : IO Unit := do
  let prepared <- match psCompilerPrepareSource kind source with
    | .error _ => throw (IO.userError ("PSC1_CONTEXTUAL_INFERENCE_FAIL: " ++ name ++ " preparation"))
    | .ok value => pure value
  let ir <- match psCompilerVerifiedIrFromPrepared prepared with
    | .error _ => throw (IO.userError ("PSC1_CONTEXTUAL_INFERENCE_FAIL: " ++ name ++ " erasure"))
    | .ok value => pure value
  match psStrictValidateModule ir with
  | .error _ => throw (IO.userError ("PSC1_CONTEXTUAL_INFERENCE_FAIL: " ++ name ++ " checked IR"))
  | .ok _ => IO.println ("PSC1_CONTEXTUAL_INFERENCE_PASS: " ++ name)

private def requireRejected
    (name : String) (kind : PsCompilerSourceKind) (source : String) : IO Unit := do
  let parsed <- match psCompilerParseSource kind source with
    | .error _ => throw (IO.userError ("PSC1_CONTEXTUAL_INFERENCE_FAIL: " ++ name ++ " negative source did not parse"))
    | .ok value => pure value
  match psCompilerElaborateModule parsed with
  | .error _ => IO.println ("PSC1_CONTEXTUAL_INFERENCE_PASS: " ++ name)
  | .ok _ => throw (IO.userError ("PSC1_CONTEXTUAL_INFERENCE_FAIL: " ++ name ++ " unexpected acceptance"))

private def requireAcceptedPair (name leanSource psSource : String) : IO Unit := do
  requireAccepted (name ++ " [lean]") .lean leanSource
  requireAccepted (name ++ " [ps]") .proofScript psSource

private def requireRejectedPair (name leanSource psSource : String) : IO Unit := do
  requireRejected (name ++ " [lean]") .lean leanSource
  requireRejected (name ++ " [ps]") .proofScript psSource

private def requireTransactionalPreview : IO Unit := do
  let environment := psSelfHostProdPreludeEnvironment
  let context := psElabContextEmpty environment
  let fresh := psMetaFresh context.metaContext context.localContext
    (.sortE (.succ .zero)) .natural
  let nat := PsExpr.constE (.str .anonymous "Nat") []
  let int := PsExpr.constE (.str .anonymous "Int") []
  let bool := PsExpr.constE (.str .anonymous "Bool") []
  let product := PsExpr.constE (.str .anonymous "Prod") []
  let pairType := PsExpr.app (.app product fresh.expr) nat
  let current := PsElabTermResult.mk
    (psElabContextWithMeta context fresh.context) nat pairType
  -- The first product parameter can assign the meta before the second fails.
  let refused := psElabApplicationWithExpected current []
    (some (.app (.app product int) bool))
  match psMetaFindAssignment refused.context.metaContext context.metaContext.nextId with
  | some _ => throw (IO.userError "PSC1_CONTEXTUAL_INFERENCE_FAIL: speculative assignment escaped")
  | none => pure ()
  if refused.context.metaContext.nextId != fresh.context.nextId then
    throw (IO.userError "PSC1_CONTEXTUAL_INFERENCE_FAIL: speculative fresh identity escaped")
  let accepted := psElabApplicationWithExpected refused []
    (some (.app (.app product bool) nat))
  match psMetaFindAssignment accepted.context.metaContext context.metaContext.nextId with
  | some (.constE (.str .anonymous "Bool") []) =>
      IO.println "PSC1_CONTEXTUAL_INFERENCE_PASS: failed preview rolls back before a different successful constraint"
  | _ => throw (IO.userError "PSC1_CONTEXTUAL_INFERENCE_FAIL: rollback blocked subsequent constraint")

def main : IO Unit := do
  requireTransactionalPreview
  requireAcceptedPair "contextual and nested generic Int calls"
    "def contextualId {A : Type} (value : A) : A := value\ndef result : Int := contextualId (contextualId 7)\n"
    "def contextualId {A : Type}(value : A) : A := value\ndef result : Int := contextualId(contextualId(7))\n"
  requireAcceptedPair "contextual product element"
    "def result : Int := let pair : Prod Int Bool := Prod.mk 8 true; Prod.fst pair\n"
    "def result : Int := let pair : Prod(Int, Bool) := Prod.mk(8, true)\n Prod.fst(pair)\n"
  requireAcceptedPair "contextual Array element and empty constructor"
    "def result : Int := let values : Array Int := Array.push (Array.emptyWithCapacity 1) 9; Array.getD values 0 0\n"
    "def result : Int := let values : Array(Int) := Array.push(Array.emptyWithCapacity(1), 9)\n Array.getD(values, 0, 0)\n"
  requireAcceptedPair "annotated local and unannotated Nat local"
    "def contextualId {A : Type} (value : A) : A := value\ndef annotated : Int := let value : Int := contextualId 11; value\ndef inferred : Nat := let value := contextualId 12; value\n"
    "def contextualId {A : Type}(value : A) : A := value\ndef annotated : Int := let value : Int := contextualId(11)\n value\n def inferred : Nat := let value := contextualId(12)\n value\n"
  requireAcceptedPair "expected function type through partial application"
    "def keepLeft {A : Type} (left : A) (right : A) : A := left\ndef result : Int := let choose : Int -> Int := keepLeft 14; choose 15\n"
    "def keepLeft {A : Type}(left : A, right : A) : A := left\n def result : Int := let choose : Int -> Int := keepLeft(14)\n choose(15)\n"
  requireAcceptedPair "dependent explicit type under unresolved argument context"
    "def contextualId {A : Type} (value : A) : A := value\ndef dependent {Tag : Type} (A : Type) (tag : Tag) (value : A) : A := value\ndef result : Nat := let value := contextualId (dependent Nat true 17); value\ndef contextual : Int := dependent Int true 18\n"
    "def contextualId {A : Type}(value : A) : A := value\ndef dependent {Tag : Type}(A : Type, tag : Tag, value : A) : A := value\ndef result : Nat := let value := contextualId(dependent(Nat, true, 17))\n value\ndef contextual : Int := dependent(Int, true, 18)\n"
  requireRejectedPair "wrong generic argument"
    "def contextualId {A : Type} (value : A) : A := value\ndef result : Int := contextualId true\n"
    "def contextualId {A : Type}(value : A) : A := value\ndef result : Int := contextualId(true)\n"
  requireRejectedPair "wrong product element"
    "def result : Prod Int Nat := Prod.mk 1 true\n"
    "def result : Prod(Int, Nat) := Prod.mk(1, true)\n"
  requireRejectedPair "wrong Array element"
    "def result : Array Int := Array.push (Array.emptyWithCapacity 1) true\n"
    "def result : Array(Int) := Array.push(Array.emptyWithCapacity(1), true)\n"
  requireRejectedPair "dependent explicit type cannot be rewritten by result context"
    "def dependent (A : Type) (value : A) : A := value\ndef result : Int := dependent Nat 1\n"
    "def dependent(A : Type, value : A) : A := value\n def result : Int := dependent(Nat, 1)\n"
  requireRejectedPair "ambiguous unused empty Array"
    "def result : Nat := let values := Array.emptyWithCapacity 0; 1\n"
    "def result : Nat := let values := Array.emptyWithCapacity(0)\n 1\n"
  requireRejectedPair "rigid local type cannot become Int"
    "def contextualId {A : Type} (value : A) : A := value\ndef result {A : Type} (value : A) : Int := contextualId value\n"
    "def contextualId {A : Type}(value : A) : A := value\ndef result {A : Type} (value : A) : Int := contextualId(value)\n"
  requireAccepted "intervening implicit telescope stays sequential [lean]" .lean
    "def afterValue (count : Nat) {A : Type} (value : A) : A := value\ndef result : Int := afterValue 0 (Int.ofNat 19)\n"

  requireAcceptedPair "bare lambda uses the expected domain"
    "def result : Nat := let apply : Nat -> Nat := fun value => value + 3; apply 4\n"
    "def result : Nat := let apply : Nat -> Nat := fun value => value + 3\n apply(4)\n"
  requireAcceptedPair "mixed typed and bare lambda domains"
    "def result : Nat := let apply : Nat -> Nat -> Nat := fun (left : Nat) right => left + right; apply 4 5\n"
    "def result : Nat := let apply : Nat -> Nat -> Nat := fun (left : Nat) right => left + right\n apply(4, 5)\n"
  requireAcceptedPair "dependent bare lambda follows the expected telescope"
    "def result : (A : Type) -> A -> A := fun A value => value\n"
    "def result : (A : Type) -> A -> A := fun A value => value\n"
  requireRejectedPair "bare lambda without expected domain stays ambiguous"
    "def result : Nat := let apply := fun value => value; 1\n"
    "def result : Nat := let apply := fun value => value\n 1\n"
  requireRejectedPair "bare lambda cannot change the expected result"
    "def result : Nat -> Bool := fun value => value\n"
    "def result : Nat -> Bool := fun value => value\n"
  requireAcceptedPair "intervening implicit telescope in both grammars"
    "def afterValue (count : Nat) {A : Type} (value : A) : A := value\ndef result : Nat := afterValue 0 19\n"
    "def afterValue(count : Nat) {A : Type}(value : A) : A := value\ndef result : Nat := afterValue(0, 19)\n"
