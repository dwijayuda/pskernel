import Ps.KernelCore.API.Dag
import Lean

/- Authentic indexed-Prop recursor occurrence regression. No handcrafted
   recursor metadata or unchecked environment is used. -/

private def require (label : String) (ok : Bool) : IO Unit := do
  unless ok do throw (IO.userError ("PSC1_INVALID_RECURSOR_OCCURRENCE_FAIL " ++ label))

private def accepted {α : Type} (label : String) : Except PsKernelError α → IO α
  | .ok value => pure value
  | .error _ => throw (IO.userError ("PSC1_INVALID_RECURSOR_OCCURRENCE_REJECTED " ++ label))

private def nm (text : String) := PsKernelName.str .anonymous text
private def one := PsKernelLevel.succ .zero
private def two := PsKernelLevel.succ one
private def type := PsKernelExpr.sort one
private def all (name : String) (domain body : PsKernelExpr) :=
  PsKernelExpr.forallE (nm name) domain body .default
private def lam (name : String) (domain body : PsKernelExpr) :=
  PsKernelExpr.lam (nm name) domain body .default
private def apps := psKernelApplyArgs
private def boolean := nm "OccurrenceBool"
private def ff := PsKernelName.str boolean "ff"
private def tt := PsKernelName.str boolean "tt"
private def boolType := PsKernelExpr.const boolean []
private def gate := nm "OccurrenceGate"
private def gateCtor := PsKernelName.str gate "mk"
private def gateAt (index : PsKernelExpr) := apps (.const gate []) [index]
private def boolDecl := PsKernelSimpleInductiveDecl.mk [] boolean type
  [PsKernelSimpleConstructorDecl.mk ff boolType,
   PsKernelSimpleConstructorDecl.mk tt boolType] false 0
private def gateDecl := PsKernelSimpleInductiveDecl.mk [] gate
  (all "b" boolType (.sort .zero))
  [PsKernelSimpleConstructorDecl.mk gateCtor (gateAt (.const ff []))] false 0

/- The motive returns Type, whose type is Sort 2; hence Gate.rec.{2}. -/
private def eliminated (minor index major : PsKernelExpr) :=
  apps (.const (psKernelSimpleRecName gate) [two])
    [lam "b" boolType (lam "h" (gateAt (.bvar 0)) type), minor, index, major]

private def ownerDecl (name : PsKernelName) (index : PsKernelExpr)
    (recursive erased : Bool) : PsKernelSimpleInductiveDecl :=
  let owner := PsKernelExpr.const name []
  let minor := if recursive then owner else boolType
  let residual := eliminated minor index (.bvar 0)
  let field := if erased then
      PsKernelExpr.app (lam "T" type (psKernelExprLiftLooseBVars residual 0 1)) owner
    else residual
  PsKernelSimpleInductiveDecl.mk [] name type
    [PsKernelSimpleConstructorDecl.mk (PsKernelName.str name "mk")
      (all "h" (gateAt index) (all "child" field owner))] false 0

private def officialName : PsKernelName → Lean.Name
  | .anonymous => .anonymous
  | .str parent value => .str (officialName parent) value
  | .num parent value => .num (officialName parent) value

private def officialLevel : PsKernelLevel → Option Lean.Level
  | .zero => some .zero
  | .succ value => (officialLevel value).map Lean.Level.succ
  | .max left right => do
      return .max (← officialLevel left) (← officialLevel right)
  | .imax left right => do
      return .imax (← officialLevel left) (← officialLevel right)
  | .param name => some (.param (officialName name))
  | .mvar _ => none

private def officialExpr : PsKernelExpr → Option Lean.Expr
  | .bvar index => some (.bvar index)
  | .sort level => (officialLevel level).map Lean.Expr.sort
  | .const name levels => do
      return .const (officialName name) (← levels.mapM officialLevel)
  | .app fn arg => do
      return .app (← officialExpr fn) (← officialExpr arg)
  | .lam name domain body _ => do
      return .lam (officialName name) (← officialExpr domain) (← officialExpr body) .default
  | .forallE name domain body _ => do
      return .forallE (officialName name) (← officialExpr domain) (← officialExpr body) .default
  | _ => none

private def officialDeclaration (decl : PsKernelSimpleInductiveDecl) : IO Lean.Declaration := do
  let some header := officialExpr decl.type | throw (IO.userError "official header conversion")
  let mut ctors : List Lean.Constructor := []
  for ctor in decl.ctors do
    let some body := officialExpr ctor.type | throw (IO.userError "official ctor conversion")
    ctors := ctors ++ [{ name := officialName ctor.name, type := body }]
  pure (.inductDecl (decl.levelParams.map officialName) decl.numParams
    [{ name := officialName decl.name, type := header, ctors }] decl.isUnsafe)

private def officialAdd (env : Lean.Environment) (decl : PsKernelSimpleInductiveDecl) :
    IO (Except Lean.Kernel.Exception Lean.Environment) := do
  pure (env.addDeclCore 0 0 (← officialDeclaration decl) none true)

private def officialAccept (env : Lean.Environment) (decl : PsKernelSimpleInductiveDecl) :
    IO Lean.Environment := do
  match ← officialAdd env decl with
  | .ok value => pure value
  | .error _ => throw (IO.userError "official fixture admission")

private def errorIs (expected : String) : Except PsKernelError α → Bool
  | .error (.rejectedInvalid actual) => actual == expected
  | _ => false

private def unsupported : Except PsKernelError α → Bool
  | .error (.declinedUnsupported _) => true
  | _ => false

def main : IO Unit := do
  let empty ← accepted "empty" (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let first ← accepted "Bool" (psKernelV1AdmitDeclaration empty (.ordinaryInductive boolDecl))
  let ready ← accepted "Gate" (psKernelV1AdmitDeclaration first.session (.ordinaryInductive gateDecl))
  let some (.recInfo recursor) := psKernelEnvironmentFind ready.session.environment (psKernelSimpleRecName gate)
    | throw (IO.userError "missing actual Gate recursor")
  require "actual-K-recursor" recursor.k
  Lean.initSearchPath (← Lean.findSysroot)
  let official ← Lean.importModules #[{ module := `Init }] {}
  let official ← officialAccept official boolDecl
  let official ← officialAccept official gateDecl
  let bad := ownerDecl (nm "OccurrenceBad") (.const tt []) true false
  let good := ownerDecl (nm "OccurrenceGood") (.const ff []) true false
  let nonrecursive := ownerDecl (nm "OccurrenceNonrecursive") (.const tt []) false false
  let erased := ownerDecl (nm "OccurrenceErased") (.const tt []) false true
  let unsafeBad := { bad with isUnsafe := true }
  require "official-rejects-stuck-recursive-minor"
    (match ← officialAdd official bad with | .error _ => true | _ => false)
  discard (← officialAccept official good)
  discard (← officialAccept official nonrecursive)
  discard (← officialAccept official erased)
  discard (← officialAccept official unsafeBad)
  IO.println "PSC1_INVALID_RECURSOR_OCCURRENCE_ORACLE: PASS stuck/reducible/nonrecursive/erased/unsafe controls"
  let message := "simple inductive field has an invalid recursor-headed recursive occurrence"
  require "public-invalid-exact-diagnostic"
    (errorIs message (psKernelV1AdmitDeclaration ready.session (.ordinaryInductive bad)))
  discard (← accepted "reducible-recursive-minor"
    (psKernelV1AdmitDeclaration ready.session (.ordinaryInductive good)))
  discard (← accepted "nonrecursive-stuck-minor"
    (psKernelV1AdmitDeclaration ready.session (.ordinaryInductive nonrecursive)))
  require "original-only-erased-occurrence-keeps-unsupported"
    (unsupported (psKernelV1AdmitDeclaration ready.session (.ordinaryInductive erased)))
  require "unsafe-recursive-occurrence-keeps-unsupported"
    (unsupported (psKernelV1AdmitDeclaration ready.session (.ordinaryInductive unsafeBad)))
  let zeroFuel := { ready.session with resources := { ready.session.resources with fuel := 0 } }
  require "zero-fuel-precedes-semantic-guard"
    (match psKernelV1AdmitDeclaration zeroFuel (.ordinaryInductive bad) with
     | .error (.resourceExhausted _ _) => true | _ => false)
  require "failed-admission-publishes-no-type-ctor-or-recursor"
    ([bad.name, PsKernelName.str bad.name "mk", psKernelSimpleRecName bad.name].all
      (fun name => (psKernelEnvironmentFind ready.session.environment name).isNone))
  let boxName := nm "OccurrenceBox"
  let box := PsKernelSimpleInductiveDecl.mk [] boxName
    (all "A" type type)
    [PsKernelSimpleConstructorDecl.mk (PsKernelName.str boxName "mk")
      (all "A" type (all "value" (.bvar 0) (apps (.const boxName []) [.bvar 1])))] false 1
  let boxed ← accepted "Box" (psKernelV1AdmitDeclaration ready.session (.ordinaryInductive box))
  let nestedName := nm "OccurrenceNested"
  let nestedType := PsKernelExpr.const nestedName []
  let nested := PsKernelSimpleInductiveDecl.mk [] nestedName type
    [PsKernelSimpleConstructorDecl.mk (PsKernelName.str nestedName "mk")
      (all "child" (apps (.const boxName []) [nestedType]) nestedType)] false 0
  require "genuine-nested-ordinary-keeps-unsupported"
    (unsupported (psKernelV1AdmitDeclaration boxed.session (.ordinaryInductive nested)))
  let nestedGroup := PsKernelSimpleMutualInductiveDecl.mk [] 0
    [PsKernelSimpleMutualTypeDecl.mk nested.name nested.type nested.ctors] false
  let officialBox ← officialAccept official box
  discard (← officialAccept officialBox nested)
  discard (← accepted "genuine-nested-explicit-route"
    (psKernelV1AdmitDeclaration boxed.session (.nestedInductive nestedGroup)))
  IO.println "PSC1_INVALID_RECURSOR_OCCURRENCE: PASS invalid/reducible/nonrecursive/erased/unsafe/nested/resource/publication controls"

