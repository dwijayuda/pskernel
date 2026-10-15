import Ps.KernelCore.Admission.Declaration.Admission
import Ps.KernelCore.Checker.Session

/- These are source-admitted declarations, not synthetic theorem metadata.
   The new checker fallback may succeed ONLY for fully checked proof pairs
   with exactly the same independently checked proposition type. -/

def c0PcName (s : String) : PsKernelName :=
  .str .anonymous s

def c0PcAddAxiom (env : PsKernelEnvironment)
    (name : PsKernelName) (type : PsKernelExpr) :
    IO PsKernelEnvironment := do
  match psKernelAddAxiom 4096 env
      { base := { name := name, levelParams := [], type := type }
        isUnsafe := false } 4096 psKernelLeanNatMaxSizeDefault with
  | .ok accepted => pure accepted
  | .error reason =>
      throw (IO.userError ("C0 proof-congruence axiom: " ++ reason))

def c0PcAddTheorem (env : PsKernelEnvironment)
    (name : PsKernelName) (type proof : PsKernelExpr) :
    IO PsKernelEnvironment := do
  match psKernelAddTheorem 4096 env
      { base := { name := name, levelParams := [], type := type }
        value := proof } 4096 psKernelLeanNatMaxSizeDefault with
  | .ok accepted => pure accepted
  | .error reason =>
      throw (IO.userError ("C0 proof-congruence theorem: " ++ reason))

def main : IO Unit := do
  let sort0 : PsKernelExpr := .sort .zero
  let pName := c0PcName "C0ProofCongruenceP"
  let qName := c0PcName "C0ProofCongruenceQ"
  let p : PsKernelExpr := .const pName []
  let q : PsKernelExpr := .const qName []
  let axP := c0PcName "C0ProofCongruenceAxP"
  let axP2 := c0PcName "C0ProofCongruenceAxP2"
  let axQ := c0PcName "C0ProofCongruenceAxQ"
  let leftThm := c0PcName "C0ProofCongruenceLeft"
  let rightThm := c0PcName "C0ProofCongruenceRight"
  let otherThm := c0PcName "C0ProofCongruenceOther"
  let fnName := c0PcName "C0ProofCongruenceFunction"
  let mut env := psKernelEnvironmentEmpty
  env ← c0PcAddAxiom env pName sort0
  env ← c0PcAddAxiom env qName sort0
  env ← c0PcAddAxiom env axP p
  env ← c0PcAddAxiom env axP2 p
  env ← c0PcAddAxiom env axQ q
  env ← c0PcAddTheorem env leftThm p (.const axP [])
  env ← c0PcAddTheorem env rightThm p (.const axP2 [])
  env ← c0PcAddTheorem env otherThm q (.const axQ [])
  let fType : PsKernelExpr :=
    .forallE (c0PcName "proof") p sort0 .default
  env ← c0PcAddAxiom env fnName fType
  let ctx := (psKernelMkCheckerSession env [] .safe 4096
    psKernelLeanNatMaxSizeDefault).context
  let initial := psKernelCheckerStateEmpty
  let defeq := psKernelIsDefEqWithFuel 4095
  let proofA : PsKernelExpr := .const leftThm []
  let proofB : PsKernelExpr := .const rightThm []
  let proofOther : PsKernelExpr := .const otherThm []
  let f : PsKernelExpr := .const fnName []
  let lhs : PsKernelExpr := .app f proofA
  let rhs : PsKernelExpr := .app f proofB
  let wrongProposition : PsKernelExpr := .app f proofOther
  let invalidApplication : PsKernelExpr := .app f sort0
  let candidate := psKernelDefEqCheckedProofCongruenceWithFuel
    96 4096 defeq ctx initial
  if (candidate lhs rhs).isNone then
    throw (IO.userError "C0 checked proof congruence missed valid pair")
  let lamA : PsKernelExpr :=
    .lam (c0PcName "x") sort0 lhs .default
  let lamB : PsKernelExpr :=
    .lam (c0PcName "x") sort0 rhs .default
  if (candidate lamA lamB).isNone then
    throw (IO.userError "C0 scoped proof congruence lost fresh binder")
  let piA : PsKernelExpr :=
    .forallE (c0PcName "x") sort0 lhs .default
  let piB : PsKernelExpr :=
    .forallE (c0PcName "x") sort0 rhs .default
  if (candidate piA piB).isNone then
    throw (IO.userError "C0 checked dependent Pi congruence declined")
  for negative in [wrongProposition, invalidApplication] do
    if (candidate lhs negative).isSome then
      throw (IO.userError "C0 proof congruence accepted ill-typed or different proof")
  if (psKernelDefEqCheckedProofCongruenceWithFuel
      0 4096 defeq ctx initial lhs rhs).isSome then
    throw (IO.userError "C0 proof congruence ignored structural budget")
  IO.println "C0_PROOF_CONGRUENCE checked_proof_irrel=pass scoped_binders=pass negative=pass"
