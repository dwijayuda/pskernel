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

def main : IO Unit := do
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
