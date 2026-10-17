import Ps.Compiler.Pscv0
import Ps.Elab.Monotonicity
import PsKernelLean.Prelude
import Init.Internal.Order.Basic

-- These native references are never inserted into the portable environment.
-- The portable tests below construct their own proofs from the exported Core.
namespace PsV7MonotonicityOracle
open Lean.Order

private theorem constant : monotone (fun (_ : Option Nat) => some 7) :=
  monotone_const (some 7)

private theorem identity : monotone (fun (x : Option Nat) => x) :=
  monotone_id

private theorem recursiveCall : monotone (fun (f : Nat → Option Nat) => f 3) :=
  monotone_apply 3 (fun f => f) monotone_id

private theorem lambda :
    monotone (fun (f : Nat → Option Nat) => fun n => f (Nat.succ n)) :=
  monotone_of_monotone_apply _ fun n =>
    monotone_apply (Nat.succ n) (fun f => f) monotone_id

private theorem nestedProjection :
    monotone (fun (p : (Nat → Option Nat) ×' ((Nat → Option Nat) ×' (Nat → Option Nat))) =>
      p.2.2 3) :=
  monotone_apply 3 _ (PProd.monotone_snd (PProd.monotone_snd monotone_id))

private theorem pair :
    monotone (fun (p : (Nat → Option Nat) ×' (Nat → Option Nat)) =>
      PProd.mk p.2 p.1) :=
  PProd.monotone_mk (PProd.monotone_snd monotone_id) (PProd.monotone_fst monotone_id)

private theorem independentMatch (flag : Bool) :
    monotone (fun (f : Nat → Option Nat) =>
      match flag with | false => none | true => f 3) :=
  match flag with
  | false => monotone_const none
  | true => monotone_apply 3 (fun f => f) monotone_id

private theorem independentIte (p : Prop) [Decidable p] :
    monotone (fun (f : Nat → Option Nat) => if p then none else f 3) :=
  monotone_ite p (fun (_ : Nat → Option Nat) => none) (fun (f : Nat → Option Nat) => f 3)
    (monotone_const none) (monotone_apply 3 (fun f => f) monotone_id)

private theorem independentDite (p : Prop) [Decidable p] :
    monotone (fun (f : Nat → Option Nat) =>
      dite p (fun _ => none) (fun _ => f 3)) :=
  monotone_dite p (fun (_ : Nat → Option Nat) (_ : p) => none)
    (fun (f : Nat → Option Nat) (_ : ¬ p) => f 3)
    (monotone_const (fun _ => none))
    (monotone_of_monotone_apply _ fun _ => monotone_apply 3 (fun f => f) monotone_id)

-- Decreasing in the ordinary Nat sense does not imply monotonicity for a
-- different order: 1 is below 2 in the flat order with bottom 1, whereas
-- pred 1 = 0 is not below pred 2 = 1 in that order.
private theorem decreasingCounterexample :
    ¬ @monotone Nat (FlatOrder.instOrder (b := 1)) Nat
      (FlatOrder.instOrder (b := 1)) Nat.pred := by
  intro h
  have impossible : FlatOrder.rel (b := (1 : Nat)) (0 : Nat) (1 : Nat) :=
    h 1 2 FlatOrder.rel.bot
  cases impossible

end PsV7MonotonicityOracle

namespace PsV7Native

private def monoProbeName (text : String) : PsName :=
  text.splitOn "." |>.foldl psNameAppendStr .anonymous

private def monoProbeConst (text : String) (levels : List PsLevel := []) : PsExpr :=
  .constE (monoProbeName text) levels

private def monoProbeApp (text : String) (levels : List PsLevel)
    (arguments : List PsExpr) : PsExpr :=
  psExprApplyMany (monoProbeConst text levels) arguments

private def monoProbeLambda (domain body : PsExpr) : PsExpr :=
  .lam .anonymous domain body .explicit

private def monoProbeArrow (domain codomain : PsExpr) : PsExpr :=
  .forallE .anonymous domain (psExprLiftBVars 1 0 codomain) .explicit

private def monoProbeGoal (domain domainOrder codomain codomainOrder functional : PsExpr) : PsExpr :=
  monoProbeApp "Lean.Order.monotone" [.succ .zero, .succ .zero]
    [domain, domainOrder, codomain, codomainOrder, functional]

private def monoProbeGoals : List (String × PsExpr) := Id.run do
  let one := PsLevel.succ .zero
  let nat := monoProbeConst "Nat"
  let boolean := monoProbeConst "Bool"
  let option := monoProbeApp "Option" [.zero] [nat]
  let absent := monoProbeApp "Option.none" [.zero] [nat]
  let present := monoProbeApp "Option.some" [.zero] [nat, .lit (.natural 7)]
  let optionOrder := monoProbeApp "Lean.Order.instPartialOrderOption" [.zero] [nat]
  let optionCCPO := monoProbeApp "Lean.Order.instCCPOOption" [.zero] [nat]
  let functionType := monoProbeArrow nat option
  let family := monoProbeLambda nat option
  let functionCCPO := monoProbeApp "Lean.Order.instCCPOPi" [one, one]
    [nat, family, monoProbeLambda nat optionCCPO]
  let parent := fun type ccpo => monoProbeApp "Lean.Order.CCPO.toPartialOrder" [one] [type, ccpo]
  let functionOrder := parent functionType functionCCPO
  let pairType := monoProbeApp "PProd" [one, one] [functionType, functionType]
  let pairCCPO := monoProbeApp "Lean.Order.instCCPOPProd" [one, one]
    [functionType, functionType, functionCCPO, functionCCPO]
  let pairOrder := parent pairType pairCCPO
  let tripleType := monoProbeApp "PProd" [one, one] [functionType, pairType]
  let tripleCCPO := monoProbeApp "Lean.Order.instCCPOPProd" [one, one]
    [functionType, pairType, functionCCPO, pairCCPO]
  let tripleOrder := parent tripleType tripleCCPO
  let call := fun function => PsExpr.app function (.lit (.natural 3))
  let project := fun index value => PsExpr.proj (psRootName "PProd") index value
  let pointwise := monoProbeLambda functionType
    (monoProbeLambda nat (.app (.bvar 1) (monoProbeApp "Nat.succ" [] [.bvar 0])))
  let swapped := monoProbeLambda pairType
    (monoProbeApp "PProd.mk" [one, one]
      [functionType, functionType, project 1 (.bvar 0), project 0 (.bvar 0)])
  let matched := monoProbeLambda functionType
    (monoProbeApp "Bool.rec" [one]
      [monoProbeLambda boolean option, absent, call (.bvar 0), .bvar 1])
  let decisionType := monoProbeApp "Decidable" [] [.bvar 0]
  let quantifyCondition := fun target =>
    PsExpr.forallE (psRootName "p") (.sortE .zero)
      (.forallE (psRootName "decision") decisionType target .instanceImplicit) .explicit
  let conditional := monoProbeLambda functionType
    (monoProbeApp "ite" [one] [option, .bvar 2, .bvar 1, absent, call (.bvar 0)])
  let dependentConditional := monoProbeLambda functionType
    (monoProbeApp "dite" [one]
      [option, .bvar 2, .bvar 1,
        monoProbeLambda (.bvar 2) absent,
        monoProbeLambda (monoProbeApp "Not" [] [.bvar 2]) (call (.bvar 1))])
  return [
    ("constant", monoProbeGoal option optionOrder option optionOrder
      (monoProbeLambda option present)),
    ("identity", monoProbeGoal option optionOrder option optionOrder
      (monoProbeLambda option (.bvar 0))),
    ("recursiveCall", monoProbeGoal functionType functionOrder option optionOrder
      (monoProbeLambda functionType (call (.bvar 0)))),
    ("lambda", monoProbeGoal functionType functionOrder functionType functionOrder pointwise),
    ("nestedProjection", monoProbeGoal tripleType tripleOrder option optionOrder
      (monoProbeLambda tripleType (call (project 1 (project 1 (.bvar 0)))))),
    ("pair", monoProbeGoal pairType pairOrder pairType pairOrder swapped),
    ("independentMatch", .forallE (psRootName "flag") boolean
      (monoProbeGoal functionType functionOrder option optionOrder matched) .explicit),
    ("independentIte", quantifyCondition
      (monoProbeGoal functionType functionOrder option optionOrder conditional)),
    ("independentDite", quantifyCondition
      (monoProbeGoal functionType functionOrder option optionOrder dependentConditional))]

private def monoProbeDecreasingTarget : PsExpr :=
  let nat := monoProbeConst "Nat"
  let order := monoProbeApp "Lean.Order.FlatOrder.instOrder" [.succ .zero]
    [nat, .lit (.natural 1)]
  monoProbeGoal nat order nat order (monoProbeConst "Nat.pred")

private def monoProbeProofs (environment : PsEnvironment) :
    Except PsElabError (List PsDeclaration) := do
  let context := psElabContextEmpty environment
  let proofs ← monoProbeGoals.mapM fun (label, target) => do
    let proof ← (psElabMonotonicityProof context target).mapError (.atContext label)
    -- Recheck using a fresh meta context, not the proof search's assignments.
    let checked ← (psElabResolvedTerm (psElabContextEmpty environment) proof
      (some target)).mapError (.atContext (label ++ ".freshCheck"))
    if psExprHasUnresolvedMeta checked.term || !psExprFVarsInContext psLocalEmpty checked.term then
      throw (.proof (label ++ ": proof is not closed"))
    return PsDeclaration.theoremDecl
      (psNameAppendStr (psRootName "$psc0MonotonicityProbe") label) [] target checked.term
  let _ ← (psElabResolvedTerm context monoProbeDecreasingTarget
    (some (.sortE .zero))).mapError (.atContext "decreasing.target")
  match psElabMonotonicityProof context monoProbeDecreasingTarget with
  | .ok _ => throw (.proof "decreasing: accepted a nonmonotone functional")
  | .error error =>
    if psElabErrorIsResource error then throw error
  return proofs

-- The caller supplies the already-audited Standard plus Order environment.
-- Every portable proof is then replayed from an empty official kernel with
-- that actual declaration closure. Native oracle declarations are absent.
def checkPartialFixpointMonotonicity (environment : PsEnvironment) : IO Unit := do
  let proofs ← match monoProbeProofs environment with
    | .ok proofs => pure proofs
    | .error error => throw (IO.userError (psCompilerPscv0ElabError error))
  let declarations := proofs ++ environment.declarations
  let empty := (← Lean.mkEmptyEnvironment 0).toKernelEnv
  let mut checked := empty
  let mut pending := declarations.reverse
  let mut progress := true
  while progress && !pending.isEmpty do
    progress := false
    let mut deferred := []
    for declaration in pending do
      let attempt ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
        PsKernelLean.tryPreludeDeclaration declarations checked declaration
      match attempt with
      | .ok (.admitted next) =>
        checked := next
        progress := true
      | .ok .deferred => deferred := declaration :: deferred
      | .error error => throw (IO.userError error.message)
    pending := deferred.reverse
  unless pending.isEmpty do
    throw (IO.userError ("monotonicity replay retains blocked declarations: " ++
      String.intercalate ", " (pending.map (fun value => psNameToString (psDeclarationName value)))))
  for (label, _) in monoProbeGoals do
    IO.println ("PSCV0_M3_P1_MONOTONICITY_" ++ label ++ ": PASS portable proof and fresh kernel")
  IO.println "PSCV0_M3_P1_MONOTONICITY_decreasing: PASS well-typed nonmonotone refusal"
  IO.println "PSCV0_M3_P1_MONOTONICITY: PASS 9 checked proofs, 1 nonmonotone refusal"

end PsV7Native
