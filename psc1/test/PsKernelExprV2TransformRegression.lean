import Ps.KernelCore.SelfHost
import Ps.KernelCore.Research.ExprV2PagedImport
import Ps.KernelCore.Core.ExprV2.TransformSpine

/- Native oracle fixtures. Production transforms never use this tree decoder. -/
def transformDecode (fuel : Nat) (arena : PsKernelExprV2PagedArena)
    (root : Nat) : Except String PsKernelExpr :=
  match fuel with
  | 0 => .error "test decoder fuel"
  | n + 1 => do
      let entry <- match psKernelExprV2PagedFind arena root with
        | .none => .error "test decoder root"
        | .some e => .ok e
      match entry.node with
      | .bvar index => return .bvar index
      | .fvar name => return .fvar name
      | .mvar name => return .mvar name
      | .sort level => return .sort level
      | .const name levels => return .const name levels
      | .lit literal => return .lit literal
      | .app fn arg =>
          return .app (<- transformDecode n arena fn) (<- transformDecode n arena arg)
      | .lam name type body info =>
          return .lam name (<- transformDecode n arena type) (<- transformDecode n arena body) info
      | .forallE name type body info =>
          return .forallE name (<- transformDecode n arena type) (<- transformDecode n arena body) info
      | .letE name type value body nondep =>
          return .letE name (<- transformDecode n arena type)
            (<- transformDecode n arena value) (<- transformDecode n arena body) nondep
      | .mdata tag body => return .mdata tag (<- transformDecode n arena body)
      | .proj name index body => return .proj name index (<- transformDecode n arena body)

def transformGet {α : Type} (label : String) (result : Except String α) : IO α :=
  match result with
  | .error error => throw (IO.userError (label ++ ": " ++ error))
  | .ok result => pure result

def transformAssert (label : String) (value : Bool) : IO Unit :=
  if value then pure () else throw (IO.userError label)

def transformReject {α : Type} (label : String) (result : Except String α) : IO Unit :=
  match result with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError (label ++ ": unexpectedly accepted"))

def transformRead (result : PsKernelExprV2PagedArena × Nat) : IO PsKernelExpr :=
  transformGet "decode" (transformDecode (result.1.size + 1) result.1 result.2)

def transformCompare (label : String)
    (result : Except String (PsKernelExprV2PagedArena × Nat))
    (expected : PsKernelExpr) : IO Unit := do
  let graph <- transformGet label result
  let actual <- transformRead graph
  transformAssert label (psKernelExprEqual actual expected)
  let count <- transformGet "expanded count" (psKernelExprV2TransformCountOnCanonical graph.1 graph.2)
  transformAssert "expanded count equals legacy tree count" (Nat.beq count (psKernelExprNodeCount actual))

def transformImportValues (arena : PsKernelExprV2PagedArena)
    (values : List PsKernelExpr) : IO (PsKernelExprV2PagedArena × List Nat) := do
  let mut current := arena
  let mut ids := []
  for value in values do
    let next <- transformGet "import replacement" (psKernelExprV2PagedImportIntoChecked current value)
    current := next.1
    ids := ids ++ [next.2]
  return (current, ids)

def transformFixtures : List PsKernelExpr :=
  let x := PsKernelName.str .anonymous "x"
  let y := PsKernelName.str .anonymous "y"
  let u := PsKernelName.str .anonymous "u"
  let s := PsKernelExpr.sort (.param u)
  let a := PsKernelExpr.app (.bvar 0) (.bvar 3)
  [ .bvar 0, .bvar 4, .fvar x, .mvar y, s,
    .const x [.param u, .succ (.param u)], .app (.fvar x) a,
    .lam x s (.app (.bvar 0) (.app (.bvar 1) (.fvar y))) .implicit,
    .forallE y s (.lam x s (.app (.bvar 2) (.fvar x)) .instImplicit) .strictImplicit,
    .letE x s (.bvar 1) (.app (.bvar 0) (.app (.bvar 2) (.fvar x))) false,
    .letE y s (.fvar x) (.lam x s (.app (.bvar 3) (.fvar y)) .default) true,
    .lit (.nat 17), .lit (.str "DAG"), .mdata 41 a, .proj y 2 (.app (.fvar x) a) ]

def transformRunCases : IO Unit := do
  let x := PsKernelName.str .anonymous "x"
  let y := PsKernelName.str .anonymous "y"
  let u := PsKernelName.str .anonymous "u"
  let replacementSets : List (List PsKernelExpr) :=
    [[], [.bvar 1], [.sort .zero, .bvar 2, .fvar y]]
  let names := [x, y, x]
  let mut comparisons := 0
  for expression in transformFixtures do
    let initial <- transformGet "import fixture" (psKernelExprV2PagedImportChecked expression)
    for values in replacementSets do
      let imported <- transformImportValues initial.1 values
      for start in [0, 1] do
        for offset in [0, 1, 2] do
          transformCompare "multi-instantiation"
            (psKernelExprV2PagedInstantiateAtChecked imported.1 initial.2 start imported.2 offset)
            (psKernelExprInstantiateAt expression start values offset)
          comparisons := comparisons + 1
          for fuel in [0, 1, 2, 3] do
            transformCompare "bounded multi-instantiation"
              (psKernelExprV2TransformCheckedWithFuel fuel
                (.instantiate start imported.2) imported.1 initial.2 offset)
              (psKernelExprInstantiateAtChangedWithFuel fuel expression start values offset).1
            comparisons := comparisons + 1
      transformCompare "reverse-instantiation"
        (psKernelExprV2PagedInstantiateRevChecked imported.1 initial.2 imported.2)
        (psKernelExprInstantiateRev expression values)
      comparisons := comparisons + 1
    for offset in [0, 1, 2] do
      transformCompare "abstraction with repeated names"
        (psKernelExprV2PagedAbstractFVarsAtChecked initial.1 initial.2 names offset)
        (psKernelExprAbstractFVarsAt expression names offset)
      comparisons := comparisons + 1
      for fuel in [0, 1, 2, 3] do
        transformCompare "bounded abstraction"
          (psKernelExprV2TransformCheckedWithFuel fuel (.abstractFVars names) initial.1 initial.2 offset)
          (psKernelExprAbstractFVarsAtChangedWithFuel fuel expression names offset).1
        comparisons := comparisons + 1
    for params in [[], [u], [u, x]] do
      for values in [[], [PsKernelLevel.zero], [PsKernelLevel.succ .zero, .zero]] do
        transformCompare "universe substitution"
          (psKernelExprV2PagedInstantiateLevelParamsChecked initial.1 initial.2 params values)
          (psKernelExprInstantiateLevelParams expression params values)
        comparisons := comparisons + 1
    let unchanged <- transformGet "empty instantiation"
      (psKernelExprV2PagedInstantiateChecked initial.1 initial.2 [])
    transformAssert "empty instantiation preserves ID and arena size"
      (Nat.beq unchanged.2 initial.2 && Nat.beq unchanged.1.size initial.1.size)
    let unchangedLevels <- transformGet "empty universe substitution"
      (psKernelExprV2PagedInstantiateLevelParamsChecked initial.1 initial.2 [] [])
    transformAssert "empty universe substitution preserves ID and arena size"
      (Nat.beq unchangedLevels.2 initial.2 && Nat.beq unchangedLevels.1.size initial.1.size)
  IO.println s!"PSKERNEL_V2_TRANSFORM_ORACLE_COMPARISONS={comparisons}"

def transformRunSharing : IO Unit := do
  let x <- transformGet "bvar" (psKernelExprV2PagedMkBVar psKernelExprV2PagedEmpty 0)
  let y <- transformGet "bvar" (psKernelExprV2PagedMkBVar x.1 1)
  let shared <- transformGet "shared app" (psKernelExprV2PagedMkApp y.1 x.2 y.2)
  let wrapped <- transformGet "wrapped shared" (psKernelExprV2PagedMkMData shared.1 7 shared.2)
  let root <- transformGet "root" (psKernelExprV2PagedMkApp wrapped.1 shared.2 wrapped.2)
  let replacement <- transformGet "replacement" (psKernelExprV2PagedMkSort root.1 .zero)
  let source <- transformRead (replacement.1, root.2)
  transformCompare "same node reached with distinct positive budgets"
    (psKernelExprV2TransformCheckedWithFuel 3 (.instantiate 0 [replacement.2]) replacement.1 root.2 0)
    (psKernelExprInstantiateAtChangedWithFuel 3 source 0 [.sort .zero] 0).1
  let reversed <- transformGet "reversed root" (psKernelExprV2PagedMkApp replacement.1 wrapped.2 shared.2)
  let sourceReversed <- transformRead reversed
  transformCompare "partial result cannot poison later deeper request"
    (psKernelExprV2TransformCheckedWithFuel 3 (.instantiate 0 [replacement.2]) reversed.1 reversed.2 0)
    (psKernelExprInstantiateAtChangedWithFuel 3 sourceReversed 0 [.sort .zero] 0).1
  let mut graph := x
  for _ in [:12] do
    graph <- transformGet "shared doubling" (psKernelExprV2PagedMkApp graph.1 graph.2 graph.2)
  let value <- transformGet "shared replacement" (psKernelExprV2PagedMkSort graph.1 .zero)
  let count <- transformGet "shared expanded count" (psKernelExprV2TransformCountOnCanonical value.1 graph.2)
  transformAssert "shared count preserves occurrence multiplicity" (count == 8191)
  let result <- transformGet "shared instantiate" (psKernelExprV2PagedInstantiateChecked value.1 graph.2 [value.2])
  transformAssert "memo bounds DAG reconstruction" (Nat.ble result.1.size (value.1.size + 12))
  let closed <- transformGet "closed graph"
    (psKernelExprV2PagedAbstractFVarsChecked result.1 result.2 [PsKernelName.str .anonymous "unused"])
  transformAssert "unchanged graph retains exact ID" (closed.2 == result.2)
  let spine <- transformGet "app spine" (psKernelExprV2PagedAppSpineChecked result.1 result.2)
  transformAssert "spine argument count" (spine.2.length == 12)
  let applied <- transformGet "apply spine" (psKernelExprV2PagedApplyArgsChecked result.1 spine.1 spine.2)
  transformAssert "app spine roundtrip" (psKernelExprEqual (<- transformRead applied) (<- transformRead result))
  transformReject "zero spine fuel" (psKernelExprV2TransformAppSpineWithFuel 0 result.1 result.2 [])
  let mut large := x
  for _ in [:24] do
    large <- transformGet "large shared doubling" (psKernelExprV2PagedMkApp large.1 large.2 large.2)
  let largeValue <- transformGet "large replacement" (psKernelExprV2PagedMkSort large.1 .zero)
  let largeResult <- transformGet "large default avoids expanded-fuel closure chain"
    (psKernelExprV2PagedInstantiateChecked largeValue.1 large.2 [largeValue.2])
  transformAssert "large DAG remains linear in source nodes" (Nat.ble largeResult.1.size (largeValue.1.size + 24))
  let largeUnchanged <- transformGet "large unchanged abstraction"
    (psKernelExprV2PagedAbstractFVarsChecked largeResult.1 largeResult.2 [PsKernelName.str .anonymous "unused"])
  transformAssert "large unchanged DAG preserves ID without materialization" (largeUnchanged.2 == largeResult.2)
  IO.println "PSKERNEL_V2_TRANSFORM_SHARING_AND_BUDGETS_PASSED"

def transformRunNegatives : IO Unit := do
  let initial <- transformGet "negative fixture" (psKernelExprV2PagedMkBVar psKernelExprV2PagedEmpty 0)
  transformReject "bad root" (psKernelExprV2PagedInstantiateChecked initial.1 initial.1.size [])
  transformReject "bad replacement even on unchanged branch"
    (psKernelExprV2PagedInstantiateAtChecked initial.1 initial.2 10 [initial.1.size] 0)
  transformReject "bad replacement with zero worker fuel"
    (psKernelExprV2TransformCheckedWithFuel 0 (.instantiate 0 [initial.1.size]) initial.1 initial.2 0)
  transformReject "invalid app argument" (psKernelExprV2PagedApplyArgsChecked initial.1 initial.2 [initial.1.size])
  let entry <- match psKernelExprV2PagedFind initial.1 initial.2 with
    | .some value => pure value
    | .none => throw (IO.userError "missing negative root")
  let forgedEntry := { entry with hash := entry.hash + 1 }
  let forged : PsKernelExprV2PagedArena := { initial.1 with active := #[forgedEntry] }
  transformReject "forged metadata under zero fuel"
    (psKernelExprV2TransformCheckedWithFuel 0 (.abstractFVars []) forged 0 0)
  transformReject "forged metadata universe transform" (psKernelExprV2PagedInstantiateLevelParamsChecked forged 0 [] [])
  transformReject "forged metadata spine" (psKernelExprV2PagedAppSpineChecked forged 0)
  let cyclicEntry := { entry with node := PsKernelExprV2Node.app 0 0 }
  let cyclic : PsKernelExprV2PagedArena := { initial.1 with active := #[cyclicEntry] }
  transformReject "cycle" (psKernelExprV2PagedAbstractFVarsChecked cyclic 0 [])
  IO.println "PSKERNEL_V2_TRANSFORM_NEGATIVES_PASSED"

def main : IO Unit := do
  transformRunCases
  transformRunSharing
  transformRunNegatives
  IO.println "PSKERNEL_V2_TRANSFORM_REGRESSION_PASSED"
