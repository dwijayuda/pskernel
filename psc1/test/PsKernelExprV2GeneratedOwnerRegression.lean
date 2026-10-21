import Ps.KernelCore.API.Dag
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

/- The bridge is tested only after real successful admission. These fixtures
   do not import an exported recursor body or fabricate environment metadata. -/
private def require (label : String) (condition : Bool) : IO Unit := do
  unless condition do throw (IO.userError ("PSC1_V2_GENERATED_OWNER_FAIL " ++ label))

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error message => throw (IO.userError message)

private def expectPublic {α : Type} (label : String) : Except PsKernelError α → IO α
  | .ok value => pure value
  | .error (.rejectedInvalid message) =>
      throw (IO.userError (label ++ ": rejectedInvalid: " ++ message))
  | .error (.declinedUnsupported message) =>
      throw (IO.userError (label ++ ": declinedUnsupported: " ++ message))
  | .error (.resourceExhausted _ message) =>
      throw (IO.userError (label ++ ": resourceExhausted: " ++ message))
  | .error (.internalError message) =>
      throw (IO.userError (label ++ ": internalError: " ++ message))

private def nm (text : String) := PsKernelName.str .anonymous text
private def one := PsKernelLevel.succ PsKernelLevel.zero
private def s1 := PsKernelExpr.sort one
private def nat := PsKernelExpr.const psKernelNatName []
private def lit (value : Nat) := PsKernelExpr.lit (.nat value)
private def cn (name : PsKernelName) := PsKernelExpr.const name []
private def apply := psKernelApplyArgs
private def all (name : String) (domain body : PsKernelExpr) :=
  PsKernelExpr.forallE (nm name) domain body .default
private def lam (name : String) (domain body : PsKernelExpr) :=
  PsKernelExpr.lam (nm name) domain body .default
private def zero := cn psKernelNatZeroName
private def succ (value : PsKernelExpr) := PsKernelExpr.app (cn psKernelNatSuccName) value
private def leftName := nm "OwnerLeft"
private def rightName := nm "OwnerRight"
private def listName := nm "OwnerList"
private def treeName := nm "OwnerTree"
private def plainName := nm "OwnerPlain"
private def ctor (parent : PsKernelName) (text : String) := PsKernelName.str parent text
private def family (name : PsKernelName) (parameter index : PsKernelExpr) :=
  apply (cn name) [parameter,index]
private def listOf (parameter : PsKernelExpr) := PsKernelExpr.app (cn listName) parameter
private def tree := cn treeName
private def trees := listOf tree
private def plain := cn plainName

private def natDecl : PsKernelSimpleInductiveDecl :=
  .mk [] psKernelNatName s1
    [.mk psKernelNatZeroName nat,.mk psKernelNatSuccName (all "n" nat nat)] false 0

private def listDecl : PsKernelSimpleInductiveDecl :=
  .mk [] listName (all "A" s1 s1)
    [.mk (ctor listName "nil") (all "A" s1 (listOf (.bvar 0))),
     .mk (ctor listName "cons") (all "A" s1 (all "head" (.bvar 0)
       (all "tail" (listOf (.bvar 1)) (listOf (.bvar 2)))))] false 1

private def mutualType (name other : PsKernelName) : PsKernelSimpleMutualTypeDecl :=
  .mk name (all "A" s1 (all "n" nat s1))
    [.mk (ctor name "base") (all "A" s1
       (all "value" (.bvar 0) (family name (.bvar 1) zero))),
     .mk (ctor name "step") (all "A" s1 (all "n" nat
       (all "other" (family other (.bvar 1) (.bvar 0))
         (family name (.bvar 2) (succ (.bvar 1))))))]

private def mutualDecl : PsKernelSimpleMutualInductiveDecl :=
  .mk [] 1 [mutualType leftName rightName,mutualType rightName leftName] false

private def treeDecl : PsKernelSimpleMutualInductiveDecl :=
  .mk [] 0 [.mk treeName s1
    [.mk (ctor treeName "leaf") (all "value" nat tree),
     .mk (ctor treeName "branch") (all "children" trees tree)]] false

private def plainDecl : PsKernelSimpleMutualInductiveDecl :=
  .mk [] 0 [.mk plainName s1
    [.mk (ctor plainName "zero") plain,
     .mk (ctor plainName "step") (all "previous" plain plain)]] false

private def badMutualDecl : PsKernelSimpleMutualInductiveDecl :=
  .mk [] 1
    [.mk leftName (all "A" s1 (all "n" nat s1))
       [.mk (ctor leftName "base") (all "A" s1
          (all "value" (.bvar 0) (family rightName (.bvar 1) zero)))],
     mutualType rightName leftName] false

private def badTreeDecl : PsKernelSimpleMutualInductiveDecl :=
  .mk [] 0 [.mk treeName s1
    [.mk (ctor treeName "leaf") (all "value" nat trees),
     .mk (ctor treeName "branch") (all "children" trees tree)]] false

private def mutualMotive (name : PsKernelName) :=
  lam "n" nat (lam "major" (family name nat (.bvar 0)) nat)
private def mutualBaseMinor := lam "value" nat (.bvar 0)
private def mutualStepMinor (other : PsKernelName) :=
  lam "n" nat (lam "other" (family other nat (.bvar 0)) (lam "ih" nat (.bvar 0)))
private def mutualRec (name : PsKernelName) (index major : PsKernelExpr) :=
  apply (.const (psKernelSimpleRecName name) [one])
    [nat,mutualMotive leftName,mutualMotive rightName,
     mutualBaseMinor,mutualStepMinor rightName,mutualBaseMinor,mutualStepMinor leftName,
     index,major]
private def mutualBase (name : PsKernelName) (value : Nat) :=
  apply (cn (ctor name "base")) [nat,lit value]
private def mutualStep (name : PsKernelName) (index major : PsKernelExpr) :=
  apply (cn (ctor name "step")) [nat,index,major]
private def treeLeaf (value : Nat) := PsKernelExpr.app (cn (ctor treeName "leaf")) (lit value)
private def treeNil := PsKernelExpr.app (cn (ctor listName "nil")) tree
private def treeCons (head tail : PsKernelExpr) :=
  apply (cn (ctor listName "cons")) [tree,head,tail]
private def treeRec (name : PsKernelName) (major : PsKernelExpr) :=
  apply (.const name [one])
    [lam "tree" tree nat,lam "trees" trees nat,
     lam "value" nat (.bvar 0),
     lam "children" trees (lam "ih" nat (.bvar 0)),
     lit 0,
     lam "head" tree (lam "tail" trees (lam "headIH" nat (lam "tailIH" nat (.bvar 1)))),
     major]
private def plainRec (major : PsKernelExpr) :=
  apply (.const (psKernelSimpleRecName plainName) [one])
    [lam "major" plain nat,lit 5,lam "previous" plain (lam "ih" nat (.bvar 0)),major]

private def fixtureTerms : List (String × PsKernelExpr × PsKernelExpr) :=
  let left7 := mutualBase leftName 7
  let right9 := mutualBase rightName 9
  let leftStep9 := mutualStep leftName zero right9
  let rightStep7 := mutualStep rightName zero left7
  let children := treeCons (treeLeaf 7) treeNil
  let mainRec := psKernelSimpleRecName treeName
  let auxRec := psKernelNameAppendIndexAfter mainRec 1
  [("mutual-left-base",mutualRec leftName zero left7,lit 7),
   ("mutual-right-base",mutualRec rightName zero right9,lit 9),
   ("mutual-left-cross",mutualRec leftName (succ zero) leftStep9,lit 9),
   ("mutual-right-cross",mutualRec rightName (succ zero) rightStep7,lit 7),
   ("mutual-left-two",mutualRec leftName (succ (succ zero))
      (mutualStep leftName (succ zero) rightStep7),lit 7),
   ("mutual-right-two",mutualRec rightName (succ (succ zero))
      (mutualStep rightName (succ zero) leftStep9),lit 9),
   ("nested-leaf",treeRec mainRec (treeLeaf 7),lit 7),
   ("nested-branch",treeRec mainRec (.app (cn (ctor treeName "branch")) children),lit 7),
   ("nested-aux-nil",treeRec auxRec treeNil,lit 0),
   ("nested-aux-cons",treeRec auxRec children,lit 7),
   ("nested-no-aux-zero",plainRec (cn (ctor plainName "zero")),lit 5),
   ("nested-no-aux-step",plainRec (.app (cn (ctor plainName "step"))
      (cn (ctor plainName "zero"))),lit 5)]

private def inferOfficialName : PsKernelName → Lean.Name
  | .anonymous => .anonymous
  | .str parent value => .str (inferOfficialName parent) value
  | .num parent value => .num (inferOfficialName parent) value

private def inferOfficialLevel : PsKernelLevel → Option Lean.Level
  | .zero => some .zero
  | .succ value => (inferOfficialLevel value).map Lean.Level.succ
  | .max left right => do
      return .max (← inferOfficialLevel left) (← inferOfficialLevel right)
  | .imax left right => do
      return .imax (← inferOfficialLevel left) (← inferOfficialLevel right)
  | .param name => some (.param (inferOfficialName name))
  | .mvar _ => none

private def inferOfficialBinder : PsKernelBinderInfo → Lean.BinderInfo
  | .default => .default
  | .implicit => .implicit
  | .strictImplicit => .strictImplicit
  | .instImplicit => .instImplicit

private def inferOfficialExpr : PsKernelExpr → Option Lean.Expr
  | .bvar index => some (.bvar index)
  | .sort level => (inferOfficialLevel level).map Lean.Expr.sort
  | .const name levels => do
      return .const (inferOfficialName name) (← levels.mapM inferOfficialLevel)
  | .app fn arg => do
      return .app (← inferOfficialExpr fn) (← inferOfficialExpr arg)
  | .lam name domain body binderInfo => do
      return .lam (inferOfficialName name) (← inferOfficialExpr domain)
        (← inferOfficialExpr body) (inferOfficialBinder binderInfo)
  | .forallE name domain body binderInfo => do
      return .forallE (inferOfficialName name) (← inferOfficialExpr domain)
        (← inferOfficialExpr body) (inferOfficialBinder binderInfo)
  | .letE name type value body nondep => do
      return .letE (inferOfficialName name) (← inferOfficialExpr type)
        (← inferOfficialExpr value) (← inferOfficialExpr body) nondep
  | .lit (.nat value) => some (.lit (.natVal value))
  | .lit (.str value) => some (.lit (.strVal value))
  | .mdata _ body => (inferOfficialExpr body).map (Lean.Expr.mdata {})
  | .proj name index body => do
      return .proj (inferOfficialName name) index (← inferOfficialExpr body)
  | _ => none

private def officialExpr (value : PsKernelExpr) : IO Lean.Expr :=
  match inferOfficialExpr value with
  | some result => pure result
  | none => throw (IO.userError "official generated-owner conversion")

private structure Prepared where
  session : PsKernelKernelSession
  arena : PsKernelExprV2PagedArena
  commands : List PsKernelDagCommand
  stages : List PsKernelKernelSession
  declarations : List PsKernelExprV2DeclarationRef

private def importType (arena : PsKernelExprV2PagedArena) (value : PsKernelSimpleMutualTypeDecl) :
    IO (PsKernelExprV2PagedArena × PsKernelDagInductive) := do
  let (a,type) ← expect (psKernelExprV2PagedImportIntoChecked arena value.type)
  let mut arena := a
  let mut ctors := []
  for value in value.ctors do
    let (a,type) ← expect (psKernelExprV2PagedImportIntoChecked arena value.type)
    arena := a
    ctors := ctors ++ [PsKernelDagConstructor.mk value.name type]
  pure (arena,PsKernelDagInductive.mk value.name type ctors)

private def importGroup (arena : PsKernelExprV2PagedArena) (value : PsKernelSimpleMutualInductiveDecl) :
    IO (PsKernelExprV2PagedArena × PsKernelDagInductiveGroup) := do
  let mut arena := arena
  let mut types := []
  for value in value.types do
    let (a,type) ← importType arena value
    arena := a
    types := types ++ [type]
  pure (arena,.mk value.levelParams value.numParams types value.isUnsafe)

private def recordAdmission (label : String) (prior : Prepared) (arena : PsKernelExprV2PagedArena)
    (request : PsKernelDagDeclarationRequest) (declaration : PsKernelDeclarationRequest) :
    IO Prepared := do
  let admitted ← expectPublic label (psKernelV1AdmitDeclaration prior.session declaration)
  pure (.mk admitted.session arena (prior.commands ++ [.admit request])
    (prior.stages ++ [admitted.session])
    (psKernelDagDeclarationsAfterAdmission request prior.declarations))

private def prepareOrdinary (label : String) (prior : Prepared) (value : PsKernelSimpleInductiveDecl) :
    IO Prepared := do
  let (arena,type) ← importType prior.arena (.mk value.name value.type value.ctors)
  recordAdmission label prior arena (.ordinaryInductive value.levelParams value.numParams type value.isUnsafe)
    (.ordinaryInductive value)

private def prepareGroup (label : String) (prior : Prepared) (value : PsKernelSimpleMutualInductiveDecl)
    (nested : Bool) : IO (Prepared × PsKernelDagInductiveGroup) := do
  let (arena,group) ← importGroup prior.arena value
  let request := if nested then PsKernelDagDeclarationRequest.nestedInductive group
    else .mutualInductive group
  let declaration := if nested then PsKernelDeclarationRequest.nestedInductive value
    else .mutualInductive value
  let prepared ← recordAdmission label prior arena request declaration
  pure (prepared,group)

private structure Families where
  empty : PsKernelKernelSession
  foundation : Prepared
  prepared : Prepared
  mutualGroup : PsKernelDagInductiveGroup
  treeGroup : PsKernelDagInductiveGroup
  plainGroup : PsKernelDagInductiveGroup

private def prepareFamilies : IO Families := do
  let empty ← expectPublic "empty" (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let first ← prepareOrdinary "Nat" (.mk empty psKernelExprV2PagedEmpty [] [] []) natDecl
  let foundation ← prepareOrdinary "OwnerList" first listDecl
  let (withMutual,mutualGroup) ← prepareGroup "mutual-parameter-index" foundation mutualDecl false
  let (nested,treeGroup) ← prepareGroup "nested-auxiliary" withMutual treeDecl true
  let (prepared,plainGroup) ← prepareGroup "nested-no-auxiliary" nested plainDecl true
  pure (.mk empty foundation prepared mutualGroup treeGroup plainGroup)

private structure Fixture where
  label : String
  expr : PsKernelExpr
  expected : PsKernelExpr
  root : Nat
  expectedRoot : Nat

private structure Inputs where
  arena : PsKernelExprV2PagedArena
  built : PsKernelExprV2Decoded
  cases : List Fixture
  natId : Nat
  sortId : Nat
  missingId : Nat
  badMutual : PsKernelDagInductiveGroup
  badTree : PsKernelDagInductiveGroup

private def prepareInputs (families : Families) : IO Inputs := do
  let mut arena := families.prepared.arena
  let mut cases := []
  for (label,expr,expected) in fixtureTerms do
    let (a,root) ← expect (psKernelExprV2PagedImportIntoChecked arena expr)
    let (a,target) ← expect (psKernelExprV2PagedImportIntoChecked a expected)
    arena := a
    cases := cases ++ [Fixture.mk label expr expected root target]
  let (a,natId) ← expect (psKernelExprV2PagedImportIntoChecked arena nat)
  let (a,sortId) ← expect (psKernelExprV2PagedImportIntoChecked a s1)
  let (a,missingId) ← expect (psKernelExprV2PagedImportIntoChecked a (cn (nm "OwnerMissingDependency")))
  let (a,badMutual) ← importGroup a badMutualDecl
  let (arena,badTree) ← importGroup a badTreeDecl
  let built ← expect (psKernelExprV2DecodeChecked arena)
  pure (.mk arena built cases natId sortId missingId badMutual badTree)

private def installedOwner (families : Families) (input : Inputs) : IO PsKernelDagGeneratedState := do
  let mut generated := PsKernelDagGeneratedState.mk input.arena input.built []
  for (command,stage) in families.prepared.commands.zip families.prepared.stages do
    let next := match command with
      | .admit request => psKernelDagDeclarationsAfterAdmission request generated.declarations
      | _ => generated.declarations
    generated ← expect (psKernelDagGeneratedAfterCommand command stage.environment
      { generated with declarations := next })
  pure generated

private def decode (arena : PsKernelExprV2PagedArena) (root : Nat) : IO PsKernelExpr := do
  let built ← expect (psKernelExprV2DecodeChecked arena)
  expect (psKernelExprV2DecodedRequire built root)

private def checkState (generated : PsKernelDagGeneratedState) : PsKernelExprV2CheckState :=
  psKernelExprV2CheckStateWithWhnf (psKernelExprV2CheckStateEmpty generated.arena)
    (psKernelExprV2WhnfStateForDeclarations generated.arena generated.declarations)

private def getInductive (session : PsKernelKernelSession) (name : PsKernelName) :
    IO PsKernelInductiveInfo :=
  match psKernelEnvironmentFind session.environment name with
  | some (.inductInfo value) => pure value
  | _ => throw (IO.userError "expected checked inductive metadata")

private def getRecursor (session : PsKernelKernelSession) (name : PsKernelName) :
    IO PsKernelRecursorInfo :=
  match psKernelEnvironmentFind session.environment name with
  | some (.recInfo value) => pure value
  | _ => throw (IO.userError "expected checked recursor metadata")

private def metadataRegression (families : Families) (input : Inputs)
    (generated : PsKernelDagGeneratedState) : IO Unit := do
  let session := families.prepared.session
  let _ ← expect (psKernelExprV2PagedValidate generated.arena)
  require "owner-size-and-private-extension"
    (generated.arena.size == generated.built.size && input.arena.size < generated.arena.size)
  require "all-25-live-owners" (generated.declarations.length == 25)
  for index in List.range input.arena.size do
    let before ← expect (psKernelExprV2DecodedRequire input.built index)
    let after ← expect (psKernelExprV2DecodedRequire generated.built index)
    require "original-source-ID-unchanged" (psKernelExprEqual before after)
  let mut recursors := 0
  let mut rules := 0
  for owner in generated.declarations do
    let some info := psKernelEnvironmentFind session.environment owner.name
      | throw (IO.userError "owner lacks checked live declaration")
    require "owner-matches-final-admitted-kind"
      (psKernelExprV2DeclarationRefMatches owner info && owner.deltaValue.isNone)
    require "owner-type-is-exact-final-admitted-type"
      (psKernelExprEqual (psKernelConstantInfoType info) (← decode generated.arena owner.type))
    match info with
    | .recInfo info =>
        recursors := recursors + 1
        require "generated-recursor-type-is-private" (input.arena.size ≤ owner.type)
        for rule in info.rules do
          let some rhs := psKernelExprV2RecursorRuleOwner generated.declarations info rule
            | throw (IO.userError "missing checked generated rule owner")
          require "rule-is-exact-final-admitted-RHS"
            (psKernelExprEqual rule.rhs (← decode generated.arena rhs))
          rules := rules + 1
    | _ => pure ()
  require "all-seven-recursors-and-fourteen-rules" (recursors == 7 && rules == 14)
  for original in families.prepared.declarations do
    let some installed := psKernelExprV2DeclarationRefFind generated.declarations original.name
      | throw (IO.userError "original declaration owner lost")
    require "ordinary-mutual-original-header-constructor-IDs-retained"
      (installed.type == original.type && original.type < input.arena.size)
  let left ← getInductive session leftName
  let right ← getInductive session rightName
  require "mutual-is-cross-recursive-parameterized-and-indexed"
    (left.isRec && right.isRec && left.numParams == 1 && right.numParams == 1 &&
      left.numIndices == 1 && right.numIndices == 1 && left.all.length == 2 && right.all.length == 2)
  let nested ← getInductive session treeName
  let ordinary ← getInductive session plainName
  require "genuine-nested-and-no-aux-routes" (nested.numNested == 1 && ordinary.numNested == 0)
  for name in [treeName,ctor treeName "leaf",ctor treeName "branch",
      plainName,ctor plainName "zero",ctor plainName "step"] do
    let some owner := psKernelExprV2DeclarationRefFind generated.declarations name
      | throw (IO.userError "missing restored declaration owner")
    require "nested-header-and-constructor-owned-from-restored-metadata"
      (input.arena.size ≤ owner.type)
  for name in [leftName,rightName] do
    let info ← getRecursor session (psKernelSimpleRecName name)
    require "both-mutual-recursor-metadata"
      (info.numParams == 1 && info.numIndices == 1 && info.numMotives == 2 &&
        info.numMinors == 4 && info.base.levelParams.length == 1 && !info.k)
  for name in [psKernelSimpleRecName treeName,
      psKernelNameAppendIndexAfter (psKernelSimpleRecName treeName) 1] do
    let info ← getRecursor session name
    require "main-and-renamed-auxiliary-recursor-metadata"
      (info.numParams == 0 && info.numIndices == 0 && info.numMotives == 2 &&
        info.numMinors == 4 && info.base.levelParams.length == 1 && !info.k)

private def unchangedPlan (label : String) (command : PsKernelDagCommand)
    (environment : PsKernelEnvironment) (before : PsKernelDagGeneratedState) : IO Unit := do
  let after ← expect (psKernelDagGeneratedAfterCommand command environment before)
  require (label ++ "-no-private-import")
    (after.arena.size == before.arena.size && after.built.size == before.built.size &&
      after.declarations.length == before.declarations.length)
  for (left,right) in before.declarations.zip after.declarations do
    require (label ++ "-no-owner-publication")
      (psKernelNameEq left.name right.name && left.type == right.type)

private def planRegression (families : Families) (input : Inputs) : IO Unit := do
  let environment := families.prepared.session.environment
  let before := PsKernelDagGeneratedState.mk input.arena input.built families.prepared.declarations
  let mutualPlan := psKernelDagGeneratedPlanMutual families.mutualGroup environment
  let nestedPlan := psKernelDagGeneratedPlanNested families.treeGroup environment
  let plainPlan := psKernelDagGeneratedPlanNested families.plainGroup environment
  require "complete-plans-before-import"
    (match mutualPlan,nestedPlan,plainPlan with
     | some first,some second,some third => first.length == 2 && second.length == 5 && third.length == 4
     | _,_,_ => false)
  let first :: second :: rest := families.mutualGroup.types
    | throw (IO.userError "two-member fixture lost")
  let missingMember := { families.mutualGroup with
    types := first :: { second with name := nm "OwnerMissingMember" } :: rest }
  let wrongParameters := { families.mutualGroup with numParams := 2 }
  let wrongLevels := { families.treeGroup with levelParams := [nm "ownerUnexpectedLevel"] }
  for (label,group) in [("missing-later-mutual-member",missingMember),
      ("mismatched-parameter-count",wrongParameters)] do
    require (label ++ "-plan-refusal") (psKernelDagGeneratedPlanMutual group environment).isNone
    unchangedPlan label (.admit (.mutualInductive group)) environment before
  require "nested-mismatched-levels-refusal"
    (psKernelDagGeneratedPlanNested wrongLevels environment).isNone
  unchangedPlan "nested-mismatched-levels" (.admit (.nestedInductive wrongLevels)) environment before
  require "no-owner-from-unadmitted-environment"
    (psKernelDagGeneratedPlanNested families.treeGroup families.foundation.session.environment).isNone
  unchangedPlan "no-owner-from-unadmitted-environment" (.admit (.nestedInductive families.treeGroup))
    families.foundation.session.environment before

private def compareExpr (label : String)
    (original : Except String (PsKernelExpr × PsKernelCheckerSession))
    (actual : Option (Except String (PsKernelExprV2CheckState × Nat))) : IO Unit := do
  match original,actual with
  | .error left,some (.error right) => require (label ++ "-exact-error") (left == right)
  | .ok left,some (.ok right) =>
      require (label ++ "-exact-expression")
        (psKernelExprEqual left.fst (← decode right.fst.whnf.arena right.snd))
  | _,none => throw (IO.userError ("unexpected owner fallback: " ++ label))
  | _,_ => throw (IO.userError ("owner result mismatch: " ++ label))

private def compareBool (label : String)
    (original : Except String (Bool × PsKernelCheckerSession))
    (actual : Option (Except String (PsKernelExprV2CheckState × Bool))) : IO Unit := do
  match original,actual with
  | .error left,some (.error right) => require (label ++ "-exact-error") (left == right)
  | .ok left,some (.ok right) => require (label ++ "-exact-boolean") (left.fst == right.snd)
  | _,none => throw (IO.userError ("unexpected owner DefEq fallback: " ++ label))
  | _,_ => throw (IO.userError ("owner DefEq result mismatch: " ++ label))

private def differentialRegression (families : Families) (input : Inputs)
    (generated : PsKernelDagGeneratedState) : IO Unit := do
  let base := psKernelKernelSessionChecker families.prepared.session [] .safe
  let mut checks := 0
  let mut reductions := 0
  let mut equalities := 0
  for fixture in input.cases do
    for fuel in [0,1,2,4,16,64] do
      for (limit,depth) in [(0,0),(1,15),(1,16)] do
        let context := { base.context with maxRecDepth := limit,recDepth := depth }
        let scalar := { base with context := context }
        let ownedContext := psKernelExprV2CheckContextEmpty context
        compareExpr (fixture.label ++ "-check")
          (psKernelSessionCheck fuel scalar fixture.expr)
          (psKernelExprV2TryCheckStateWithFuel fuel ownedContext (checkState generated) fixture.root)
        checks := checks + 1
        compareExpr (fixture.label ++ "-WHNF")
          (psKernelSessionWhnf fuel scalar fixture.expr)
          (psKernelExprV2TryWhnfCheckStateWithFuel fuel ownedContext (checkState generated) fixture.root)
        reductions := reductions + 1
        compareBool (fixture.label ++ "-DefEq")
          (psKernelSessionIsDefEq fuel scalar fixture.expr fixture.expected)
          (psKernelExprV2TryDefEqStateWithFuel fuel ownedContext (checkState generated)
            fixture.root fixture.expectedRoot)
        equalities := equalities + 1
    let context := psKernelExprV2CheckContextEmpty base.context
    let checked ← match psKernelExprV2TryCheckStateWithFuel 4096 context (checkState generated) fixture.root with
      | some result => expect result
      | none => throw (IO.userError ("missing complete owned check: " ++ fixture.label))
    require (fixture.label ++ "-owned-check-is-Nat")
      (psKernelExprEq (← decode checked.fst.whnf.arena checked.snd) nat)
    let reduced ← match psKernelExprV2TryWhnfCheckStateWithFuel 4096 context (checkState generated) fixture.root with
      | some result => expect result
      | none => throw (IO.userError ("missing complete owned WHNF: " ++ fixture.label))
    require (fixture.label ++ "-owned-WHNF-value")
      (psKernelExprEq (← decode reduced.fst.whnf.arena reduced.snd) fixture.expected)
    require (fixture.label ++ "-owned-DefEq-success")
      (match psKernelExprV2TryDefEqStateWithFuel 4096 context (checkState generated)
          fixture.root fixture.expectedRoot with
       | some (.ok result) => result.snd | _ => false)
  require "complete-resource-matrices" (checks == 216 && reductions == 216 && equalities == 216)

private def invalidReference {α : Type} : Except PsKernelError α → Bool
  | .error (.rejectedInvalid message) => message == "PSKERNEL_V2_DECODE_INVALID_REFERENCE"
  | _ => false

private def sameRejection {α β : Type} (label : String)
    (original : Except PsKernelError α) (actual : Except PsKernelError β) : IO Unit := do
  match original,actual with
  | .error (.rejectedInvalid left),.error (.rejectedInvalid right) =>
      require (label ++ "-exact-rejection") (left == right)
  | _,_ => throw (IO.userError ("expected invalid declaration rejection: " ++ label))

private def publicRegression (families : Families) (input : Inputs)
    (generated : PsKernelDagGeneratedState) : IO Unit := do
  let mut queries := []
  for fixture in input.cases do
    queries := queries ++ [.check fixture.root,.whnf fixture.root,
      .isDefEq fixture.root fixture.expectedRoot]
  let result ← expectPublic "complete-owner-batch"
    (psKernelV1RunDag families.empty [] .safe input.arena (families.prepared.commands ++ queries))
  let mut answers := result.replies.drop families.prepared.commands.length
  for fixture in input.cases do
    match answers with
    | .checked checked :: .normalized reduced :: .equal equal :: rest =>
        require (fixture.label ++ "-public-check")
          (psKernelExprEq checked.type nat && psKernelExprEqual checked.expression fixture.expr)
        require (fixture.label ++ "-public-WHNF") (psKernelExprEq reduced fixture.expected)
        require (fixture.label ++ "-public-DefEq") equal
        answers := rest
    | _ => throw (IO.userError "incomplete public owner protocol")
  require "exact-public-36-reply-protocol" (answers.isEmpty && queries.length == 36)
  let first :: _ := input.cases | throw (IO.userError "missing owner fixture")
  let definition := PsKernelDagDeclarationRequest.definitionDecl
    (.mk (.mk (nm "OwnerBatchDefinition") [] input.natId) first.root .abbrevHint .safe)
  let result ← expectPublic "real-checked-definition"
    (psKernelV1RunDag families.empty [] .safe input.arena
      (families.prepared.commands ++ [.admit definition,.check first.root,
        .isDefEq first.root first.expectedRoot]))
  require "real-definition-checked-and-compared"
    (match result.replies.reverse with | .equal true :: .checked _ :: .admitted _ :: _ => true | _ => false)
  sameRejection "invalid-mutual"
    (psKernelV1AdmitDeclaration families.foundation.session (.mutualInductive badMutualDecl))
    (psKernelV1RunDag families.empty [] .safe input.arena
      (families.foundation.commands ++ [.admit (.mutualInductive input.badMutual)]))
  sameRejection "invalid-nested"
    (psKernelV1AdmitDeclaration families.foundation.session (.nestedInductive badTreeDecl))
    (psKernelV1RunDag families.empty [] .safe input.arena
      (families.foundation.commands ++ [.admit (.nestedInductive input.badTree)]))
  sameRejection "duplicate-mutual"
    (psKernelV1AdmitDeclaration families.prepared.session (.mutualInductive mutualDecl))
    (psKernelV1RunDag families.empty [] .safe input.arena
      (families.prepared.commands ++ [.admit (.mutualInductive families.mutualGroup)]))
  for (label,type,value,typeId,valueId) in
      [("OwnerWrongType",s1,first.expr,input.sortId,first.root),
       ("OwnerMissingValue",nat,cn (nm "OwnerMissingDependency"),input.natId,input.missingId)] do
    sameRejection label
      (psKernelV1AdmitDeclaration families.prepared.session
        (.definitionDecl (.mk (.mk (nm label) [] type) value .abbrevHint .safe)))
      (psKernelV1RunDag families.empty [] .safe input.arena
        (families.prepared.commands ++ [.admit (.definitionDecl
          (.mk (.mk (nm label) [] typeId) valueId .abbrevHint .safe))]))
  let privateId := input.arena.size
  let privateHeader := PsKernelDagConstantBase.mk (nm "OwnerPrivateHeader") [] privateId
  let publicHeader := PsKernelDagConstantBase.mk (nm "OwnerPrivateBody") [] input.natId
  let privateDefinition := PsKernelDagDefinition.mk publicHeader privateId .abbrevHint .safe
  let badHeader := PsKernelDagInductive.mk (nm "OwnerPrivateFamily") privateId []
  let badCtor := PsKernelDagInductive.mk (nm "OwnerPrivateFamily") input.sortId
    [.mk (nm "OwnerPrivateCtor") privateId]
  let privateCommands : List PsKernelDagCommand :=
    [.check privateId,.whnf privateId,.isDefEq privateId input.natId,.isDefEq input.natId privateId,
     .admit (.axiomDecl privateHeader false),.admit (.definitionDecl privateDefinition),
     .admit (.theoremDecl publicHeader privateId),.admit (.opaqueDecl publicHeader privateId false),
     .admit (.mutualDefinitions [privateDefinition]),
     .admit (.ordinaryInductive [] 0 badHeader false),.admit (.ordinaryInductive [] 0 badCtor false),
     .admit (.mutualInductive (.mk [] 0 [badHeader] false)),
     .admit (.nestedInductive (.mk [] 0 [badCtor] false))]
  for command in privateCommands do
    require "public-appended-ID-remains-invalid"
      (invalidReference (psKernelV1RunDag families.empty [] .safe input.arena
        (families.prepared.commands ++ [command])))
    require "original-source-namespace-before-extended-owner"
      (invalidReference (psKernelDagRunCommandWithSource input.built
        (.mk families.prepared.session generated.declarations) [] .safe
        generated.arena generated.built command))
  require "all-thirteen-private-input-forms" (privateCommands.length == 13)
  require "earlier-unsupported-error-precedes-private-ID"
    (match psKernelV1RunDag families.empty [] .safe input.arena
        (families.prepared.commands ++ [.admit (.unsupported "OWNER_ORDER_SENTINEL"),.check privateId]) with
     | .error (.declinedUnsupported message) => message == "OWNER_ORDER_SENTINEL"
     | _ => false)
  require "private-ID-error-precedes-later-unsupported"
    (invalidReference (psKernelV1RunDag families.empty [] .safe input.arena
      (families.prepared.commands ++ [.check privateId,.admit (.unsupported "OWNER_ORDER_SENTINEL")])) )
  require "failed-batch-publishes-no-session-or-declarations"
    ((psKernelEnvironmentFind families.empty.environment leftName).isNone &&
      (psKernelEnvironmentFind families.foundation.session.environment treeName).isNone)
  let _ ← expectPublic "fresh-success-after-failed-batch"
    (psKernelV1RunDag families.empty [] .safe input.arena families.prepared.commands)
  pure ()

private def officialGroupDeclaration (group : PsKernelSimpleMutualInductiveDecl) : IO Lean.Declaration := do
  let mut types : List Lean.InductiveType := []
  for value in group.types do
    let mut ctors : List Lean.Constructor := []
    for value in value.ctors do
      ctors := ctors ++ [{ name := inferOfficialName value.name,type := ← officialExpr value.type }]
    types := types ++ [{ name := inferOfficialName value.name,type := ← officialExpr value.type,ctors := ctors }]
  pure (.inductDecl (group.levelParams.map inferOfficialName) group.numParams types group.isUnsafe)

private def officialGroup (environment : Lean.Environment) (group : PsKernelSimpleMutualInductiveDecl) :
    IO Lean.Environment := do
  let declaration ← officialGroupDeclaration group
  match environment.addDeclCore 0 0 declaration none true with
  | .ok next => pure next
  | .error _ => throw (IO.userError "official generated-owner inductive fixture failed")

private def officialRegression (families : Families) (input : Inputs) : IO Unit := do
  Lean.initSearchPath (← Lean.findSysroot)
  let initial ← Lean.importModules #[{ module := `Init }] {}
  let base ← officialGroup initial (.mk listDecl.levelParams listDecl.numParams
    [.mk listDecl.name listDecl.type listDecl.ctors] listDecl.isUnsafe)
  let withMutual ← officialGroup base mutualDecl
  let withTree ← officialGroup withMutual treeDecl
  let official ← officialGroup withTree plainDecl
  let mut positives := 4
  let mut negatives := 0
  for fixture in input.cases do
    let term ← officialExpr fixture.expr
    require (fixture.label ++ "-official-check")
      (match Lean.Kernel.check official {} term with | .ok _ => true | _ => false)
    require (fixture.label ++ "-official-DefEq")
      (match Lean.Kernel.isDefEq official {} term (← officialExpr fixture.expected) with
       | .ok true => true | _ => false)
    let label := nm ("official-" ++ fixture.label)
    let result := official.addDeclCore 0 0 (.defnDecl {
      name := inferOfficialName label
      levelParams := []
      type := ← officialExpr nat
      value := term
      hints := .abbrev
      safety := .safe
    }) none true
    require (fixture.label ++ "-official-real-definition")
      (match result with | .ok _ => true | _ => false)
    let _ ← expectPublic (fixture.label ++ "-independent-real-definition")
      (psKernelV1AdmitDeclaration families.prepared.session
        (.definitionDecl (.mk (.mk label [] nat) fixture.expr .abbrevHint .safe)))
    positives := positives + 1
  for (label,group) in [("bad-mutual",badMutualDecl),("bad-nested",badTreeDecl)] do
    let declaration ← officialGroupDeclaration group
    require (label ++ "-official-rejection")
      (match base.addDeclCore 0 0 declaration none true with | .error _ => true | _ => false)
    negatives := negatives + 1
  let duplicate ← officialGroupDeclaration mutualDecl
  require "duplicate-mutual-official-rejection"
    (match official.addDeclCore 0 0 duplicate none true with | .error _ => true | _ => false)
  negatives := negatives + 1
  let first :: _ := input.cases | throw (IO.userError "missing official fixture")
  for (label,type,value) in
      [("OwnerWrongType",s1,first.expr),("OwnerMissingValue",nat,cn (nm "OwnerMissingDependency"))] do
    let result := official.addDeclCore 0 0 (.defnDecl {
      name := inferOfficialName (nm label)
      levelParams := []
      type := ← officialExpr type
      value := ← officialExpr value
      hints := .abbrev
      safety := .safe
    }) none true
    require (label ++ "-official-rejection") (match result with | .error _ => true | _ => false)
    negatives := negatives + 1
  require "complete-official-definition-and-group-matrix" (positives == 16 && negatives == 5)

private def missingOwnerRegression (families : Families) (input : Inputs) : IO Unit := do
  let context := psKernelExprV2CheckContextEmpty
    (psKernelKernelSessionChecker families.prepared.session [] .safe).context
  let unowned := psKernelExprV2CheckStateWithWhnf (psKernelExprV2CheckStateEmpty input.arena)
    (psKernelExprV2WhnfStateForDeclarations input.arena families.prepared.declarations)
  for fixture in input.cases do
    require (fixture.label ++ "-new-owner-is-required")
      (psKernelExprV2TryCheckStateWithFuel 4096 context unowned fixture.root).isNone

private def regression : IO Unit := do
  let families ← prepareFamilies
  let input ← prepareInputs families
  require "all-twelve-real-recursor-cases" (input.cases.length == 12)
  let generated ← installedOwner families input
  metadataRegression families input generated
  planRegression families input
  missingOwnerRegression families input
  differentialRegression families input generated
  publicRegression families input generated
  officialRegression families input
  IO.println "PSC1_V2_GENERATED_OWNER_PASS owners=25 recursors=7 rules=14 cases=12 checks=216 whnf=216 defeq=216 private=13 officialPositive=16 officialNegative=5"

def main : IO Unit := regression
