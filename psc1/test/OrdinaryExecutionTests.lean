import Ps.Compiler.Ordinary
import Ps.Host.LeanChecked
import Ps.CompilerIr.Validate

private def require (condition : Bool) (message : String) : IO Unit := do
  if !condition then throw (IO.userError message)

private def elaborate (kind : PsCompilerSourceKind) (source : String) : IO PsElabModuleResult :=
  match psCompilerElaborateSource kind source with
  | .error _ => throw (IO.userError ("ordinary fixture failed elaboration: " ++ source))
  | .ok result => pure result

private def prepare (kind : PsCompilerSourceKind) (source : String) :
    IO PsCompilerOrdinaryModule := do
  let input ← elaborate kind source
  let result ← match psCompilerPrepareOrdinary input with
    | .error message => throw (IO.userError message)
    | .ok result => pure result
  match psCompilerPrepareElaborated input with
  | .ok _ => throw (IO.userError "old checked path silently accepted partial")
  | .error _ => pure ()
  match ← psHostLeanCheckPrepared result.logical with
  | .error message => throw (IO.userError message)
  | .ok _ => pure ()
  pure result

private def checkRuntime (result : PsCompilerOrdinaryModule) : IO Unit := do
  let ir ← match psCompilerOrdinaryIr result with
    | .error message => throw (IO.userError message)
    | .ok value => pure value
  match psStrictValidateModule ir with
  | .error _ => throw (IO.userError "ordinary runtime failed strict IR validation")
  | .ok _ => pure ()

private def requireOrdinaryFailure (source : String) : IO Unit := do
  let input ← elaborate .lean source
  match psCompilerPrepareOrdinary input with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError ("invalid partial declaration accepted: " ++ source))

private def requireProductWitnessBudget : IO Unit := do
  let mut source := "def WitnessT0 : Type := Nat\n"
  for index in List.range 16 do
    let previous := "WitnessT" ++ toString index
    let current := "WitnessT" ++ toString (index + 1)
    source := source ++ "def " ++ current ++ " : Type := Prod " ++ previous ++ " " ++ previous ++ "\n"
  source := source ++ "partial def witnessBound (n : Nat) : WitnessT16 := witnessBound n\n"
  let elaborated <- match psCompilerElaborateSource .lean source with
    | .error _ => throw (IO.userError "PSC1_ORDINARY_BUDGET_FAIL: regression source must elaborate")
    | .ok value => pure value
  match psCompilerPrepareOrdinary elaborated with
  | .error reason =>
      if reason.startsWith "PSC1_PARTIAL_NO_CHECKED_INHABITANT:" then
        IO.println "PSC1_ORDINARY_BUDGET_PASS: compact nested Prod aliases"
      else throw (IO.userError ("PSC1_ORDINARY_BUDGET_FAIL: " ++ reason))
  | .ok _ => throw (IO.userError "PSC1_ORDINARY_BUDGET_FAIL: exponential witness accepted")

def main : IO Unit := do
  requireProductWitnessBudget
  let source := "partial def countdown (n : Nat) : Nat := if Nat.beq n 0 then 42 else countdown (Nat.sub n 1)\n"
  let first ← prepare .lean source
  checkRuntime first
  let second ← prepare .proofScript
    "partial def countdown(n : Nat) : Nat := if (Nat.beq(n, 0)) { 42 } else { countdown(Nat.sub(n, 1)) }\n"
  checkRuntime second
  require (first.partialNames.length == 1) "missing partial dependency metadata"
  let f := psRootName "countdown"
  let some logicalDeclaration := psEnvironmentFind
      (← match psAddDeclarationList psSelfHostProdPreludeEnvironment first.logical.declarations with
          | .error _ => throw (IO.userError "logical replay failed")
          | .ok value => pure value) f
    | throw (IO.userError "opaque function missing")
  require (psDeclarationValue logicalDeclaration |>.isNone) "partial value unfolded as a definition"
  match first.source.declarations, first.logical.declarations with
  | [.partialDecl _ _ _ body],
      [.opaqueDecl _ _ _ witness, .definitionDecl bodyName _ _ checkedBody] =>
      require (psNameEq bodyName (psOrdinaryBodyName f)) "wrong body owner"
      require (psExprAlphaEq body checkedBody) "runtime body not bound to admission"
      require (!psExprAlphaEq witness checkedBody) "test does not distinguish witness from executable body"
  | _, _ => throw (IO.userError "wrong ordinary expansion shape")
  let typeChoice ← prepare .lean
    "partial def chooseType (n : Nat) : Type := chooseType n\n"
  let opaqueType := PsExpr.app (.constE (psRootName "chooseType") [])
    (.lit (.natural 0))
  let forgedUnfold : PsCompilerAdmissionReadyModule := {
    declarations := typeChoice.logical.declarations ++ [
      .definitionDecl (psRootName "forbiddenUnfold") [] opaqueType (.lit (.natural 1))
    ]
  }
  -- The witness for chooseType is Nat. Accepting a Nat here would therefore
  -- expose that witness through kernel conversion. The official checker refuses.
  match ← psHostLeanCheckPrepared forgedUnfold with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "independent kernel unfolded the partial inhabitant")
  let generic ← prepare .lean
    "partial def choose {a : Type} (x : a) : a := choose x\n"
  require (generic.partialNames.length == 1) "local parameter inhabitant rejected"
  requireOrdinaryFailure "partial def value : Nat := 1\n"
  requireOrdinaryFailure "partial def impossible {a : Type} (n : Nat) : a := impossible n\n"
  let wrongLogical : PsCompilerAdmissionReadyModule := { declarations := [] }
  match psCompilerOrdinaryIr { first with logical := wrongLogical } with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "forged runtime/logical pairing accepted")
  let changed ← elaborate .lean
    "partial def countdown (n : Nat) : Nat := 9\n"
  match psCompilerOrdinaryIr { first with source := { declarations := changed.declarations } } with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "changed source body reused old admission")
  let colliding := PsElabModuleResult.mk psSelfHostProdPreludeEnvironment
    (first.source.declarations ++ [
      .definitionDecl (psOrdinaryBodyName f) []
        (.constE psNatName []) (.lit (.natural 1))
    ])
  match psCompilerPrepareOrdinary colliding with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "generated body name collision accepted")
  let forged := PsElabModuleResult.mk psSelfHostProdPreludeEnvironment
    [.axiomDecl (psRootName "invented") [] (.constE psNatName [])]
  match psCompilerPrepareOrdinary forged with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "ordinary mode accepted source axiom")
  IO.println "PSC1_ORDINARY_BOUNDARY_TESTS: passed; no runtime divergence executed in kernel"
