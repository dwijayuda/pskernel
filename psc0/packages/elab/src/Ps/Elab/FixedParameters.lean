import Ps.Foundation.List

/-!
Fixed-parameter correspondence for an already owned recursive component.
Adapted from Lean4.35.0 Lean/Elab/PreDefinition/FixedParams.lean,
eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Copyright (c) 2025 Lean FRO, LLC. Author: Joachim Breitner. Apache-2.0.
The caller supplies typed, reducible, proof-relevance-preserving observations.
This pure finite graph is not termination evidence or permission to rewrite.
-/

-- An absent parameter entry is known varying. Otherwise the inner list maps
-- each caller to at most one original parameter position. Unknown edges stay
-- distinct from varying parameters.
abbrev PsFixedParameterGraph := List (List (Option (List (Option Nat))))

structure PsFixedParameterCall where
  caller : Nat
  callee : Nat
  -- One entry per callee header slot; none means no matching caller parameter.
  arguments : List (Option Nat)

structure PsFixedParameterPlan where
  count : Nat
  permutations : List (List (Option Nat))
  deriving BEq

def psFixedParameterAt (graph : PsFixedParameterGraph) (owner slot : Nat) :
    Option (List (Option Nat)) :=
  ((graph[owner]?).bind fun entries => entries[slot]?).join

def psFixedParameterModify (graph : PsFixedParameterGraph) (owner slot : Nat)
    (change : Option (List (Option Nat)) → Option (List (Option Nat))) :
    PsFixedParameterGraph :=
  graph.zipIdx.map fun (entries, currentOwner) =>
    if currentOwner != owner then entries else
      entries.zipIdx.map fun (entry, currentSlot) =>
        if currentSlot == slot then change entry else entry

def psFixedParameterVary (graph : PsFixedParameterGraph) (owner slot : Nat) :
    PsFixedParameterGraph :=
  psFixedParameterModify graph owner slot (fun _ => none)

def psFixedParameterEdge (graph : PsFixedParameterGraph)
    (callee slot caller parameter : Nat) : PsFixedParameterGraph :=
  psFixedParameterModify graph callee slot fun
    | none => none
    | some incoming =>
      match incoming[caller]? with
      | none => none -- malformed external observations are rejected before entry
      | some (some prior) => if prior == parameter then some incoming else none
      | some none => some (incoming.zipIdx.map fun (entry, index) =>
          if index == caller then some parameter else entry)

def psFixedParameterStep (reverseDependencies : List (List (List Nat)))
    (graph : PsFixedParameterGraph) : PsFixedParameterGraph := Id.run do
  let mut next := graph
  for (entries, callee) in graph.zipIdx do
    for (entry, slot) in entries.zipIdx do
      match entry with
      | none =>
        let dependentSlots := ((reverseDependencies[callee]?).bind
          fun dependencies => dependencies[slot]?).getD []
        for dependent in dependentSlots do
          next := psFixedParameterVary next callee dependent
      | some incoming =>
        for (source, caller) in incoming.zipIdx do
          match source with
          | none => pure ()
          | some parameter =>
            match psFixedParameterAt graph caller parameter with
            | none => next := psFixedParameterVary next callee slot
            | some ancestors =>
              for (ancestor, owner) in ancestors.zipIdx do
                if let some ancestor := ancestor then
                  next := psFixedParameterEdge next callee slot owner ancestor
  return next

-- Each strict step adds an unknown correspondence or marks a slot varying.
-- A varying slot never regains an entry. The derived finite bound counts
-- every possible correspondence and every one-way varying transition.
def psFixedParameterClose (fuel : Nat) (reverseDependencies : List (List (List Nat)))
    (graph : PsFixedParameterGraph) : Except String PsFixedParameterGraph := do
  match fuel with
  | 0 => throw "PSCV0-FIXED-PARAMETERS: finite correspondence closure did not converge"
  | fuel + 1 =>
    let next := psFixedParameterStep reverseDependencies graph
    if next == graph then return graph
    psFixedParameterClose fuel reverseDependencies next

def psFixedParameterAnalyze (reverseDependencies : List (List (List Nat)))
    (calls : List PsFixedParameterCall) : Except String PsFixedParameterGraph := do
  if reverseDependencies.isEmpty then
    throw "PSCV0-FIXED-PARAMETERS: empty component"
  let arities := reverseDependencies.map List.length
  for (dependencies, owner) in reverseDependencies.zipIdx do
    let arity := (arities[owner]?).getD 0
    for dependents in dependencies do
      if dependents.any (fun slot => slot >= arity) then
        throw "PSCV0-FIXED-PARAMETERS: invalid type dependency"
  let mut graph : PsFixedParameterGraph := reverseDependencies.zipIdx.map
    fun (dependencies, owner) =>
      dependencies.zipIdx.map fun (_, slot) => some (
        reverseDependencies.zipIdx.map fun (_, caller) =>
          if caller == owner then some slot else none)
  for call in calls do
    let some callerArity := arities[call.caller]?
      | throw "PSCV0-FIXED-PARAMETERS: unknown caller"
    let some calleeArity := arities[call.callee]?
      | throw "PSCV0-FIXED-PARAMETERS: unknown callee"
    if call.arguments.length != calleeArity ||
        call.arguments.any (fun argument => argument.any (fun slot => slot >= callerArity)) then
      throw "PSCV0-FIXED-PARAMETERS: observation changed an original header"
    for (argument, slot) in call.arguments.zipIdx do
      graph := match argument with
        | none => psFixedParameterVary graph call.callee slot
        | some parameter => psFixedParameterEdge graph call.callee slot call.caller parameter
  let slots := arities.foldl Nat.add 0
  psFixedParameterClose (slots * (reverseDependencies.length + 1) + 1)
    reverseDependencies graph

def psFixedParameterPermutation (graph : PsFixedParameterGraph) :
    Except String PsFixedParameterPlan := do
  let first :: _ := graph | throw "PSCV0-FIXED-PARAMETERS: empty component"
  let mut firstMap : List (Option Nat) := []
  let mut count := 0
  for entry in first do
    match entry with
    | none => firstMap := firstMap ++ [none]
    | some _ =>
      firstMap := firstMap ++ [some count]
      count := count + 1
  let permutations ← graph.mapM fun entries =>
    entries.mapM fun entry => do
      match entry with
      | none => return none
      | some incoming =>
        if incoming.length != graph.length || incoming.any Option.isNone then
          throw "PSCV0-FIXED-PARAMETERS: fixed correspondence is not a complete component"
        let some (some position) := incoming[0]?
          | throw "PSCV0-FIXED-PARAMETERS: fixed correspondence lost its first member"
        let some (some index) := firstMap[position]?
          | throw "PSCV0-FIXED-PARAMETERS: fixed correspondence targets a varying slot"
        return some index
  for permutation in permutations do
    let fixed := permutation.filterMap id
    if fixed.length != count || fixed.eraseDups.length != count then
      throw "PSCV0-FIXED-PARAMETERS: fixed slots are not one-to-one across members"
  return { count, permutations }
