import Ps.PSCKernel.Core.LocalContext

structure PsCKernelLocalContextNamedTest where
  name : String
  passed : Bool

def psCKernelLocalContextNameX : PsCKernelName :=
  psCKernelNameFromDotted "x"

def psCKernelLocalContextNameY : PsCKernelName :=
  psCKernelNameFromDotted "y"

def psCKernelLocalContextNameZ : PsCKernelName :=
  psCKernelNameFromDotted "z"

def psCKernelLocalContextIdX : PsCKernelFVarId :=
  { name := psCKernelLocalContextNameX }

def psCKernelLocalContextIdY : PsCKernelFVarId :=
  { name := psCKernelLocalContextNameY }

def psCKernelLocalContextIdZ : PsCKernelFVarId :=
  { name := psCKernelLocalContextNameZ }

def psCKernelLocalContextType (name : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelNameFromDotted name) []

def psCKernelLocalContextOptionExprEq
    (left : Option PsCKernelExpr)
    (right : Option PsCKernelExpr) : Bool :=
  match left, right with
  | none, none => true
  | some leftExpr, some rightExpr => psCKernelExprEqStructural leftExpr rightExpr
  | _, _ => false

def psCKernelLocalContextOptionDeclHasId
    (decl? : Option PsCKernelLocalDecl)
    (id : PsCKernelFVarId) : Bool :=
  match decl? with
  | none => false
  | some decl => psCKernelFVarIdEq (psCKernelLocalDeclFVarId decl) id

def psCKernelLocalContextIdListEq
    (left : List PsCKernelFVarId)
    (right : List PsCKernelFVarId) : Bool :=
  match left, right with
  | [], [] => true
  | leftHead :: leftTail, rightHead :: rightTail =>
      if psCKernelFVarIdEq leftHead rightHead then
        psCKernelLocalContextIdListEq leftTail rightTail
      else
        false
  | _, _ => false

def psCKernelLocalContextTestEmpty : Bool :=
  let ctx : PsCKernelLocalContext := psCKernelLocalContextEmpty
  psCKernelLocalContextIsEmpty ctx &&
    Nat.beq (psCKernelLocalContextNumIndices ctx) 0

def psCKernelLocalContextTestCDeclFields : Bool :=
  let type : PsCKernelExpr := psCKernelLocalContextType "T"
  let ctx : PsCKernelLocalContext :=
    psCKernelLocalContextMkLocalDecl
      psCKernelLocalContextEmpty
      psCKernelLocalContextIdX
      psCKernelLocalContextNameX
      type
      PsCKernelBinderInfo.implicit
      PsCKernelLocalDeclKind.default
  match psCKernelLocalContextGetAt? ctx 0 with
  | none => false
  | some decl =>
      Nat.beq (psCKernelLocalDeclIndex decl) 0 &&
        psCKernelFVarIdEq (psCKernelLocalDeclFVarId decl) psCKernelLocalContextIdX &&
        psCKernelNameEq (psCKernelLocalDeclUserName decl) psCKernelLocalContextNameX &&
        psCKernelExprEqStructural (psCKernelLocalDeclType decl) type &&
        psCKernelBinderInfoEq
          (psCKernelLocalDeclBinderInfo decl)
          PsCKernelBinderInfo.implicit

def psCKernelLocalContextTestIndicesAndOrder : Bool :=
  let type : PsCKernelExpr := psCKernelLocalContextType "T"
  let first : PsCKernelLocalContext :=
    psCKernelLocalContextMkLocalDecl
      psCKernelLocalContextEmpty
      psCKernelLocalContextIdX
      psCKernelLocalContextNameX
      type
      PsCKernelBinderInfo.default
      PsCKernelLocalDeclKind.default
  let second : PsCKernelLocalContext :=
    psCKernelLocalContextMkLocalDecl
      first
      psCKernelLocalContextIdY
      psCKernelLocalContextNameY
      type
      PsCKernelBinderInfo.default
      PsCKernelLocalDeclKind.default
  Nat.beq (psCKernelLocalContextNumIndices second) 2 &&
    psCKernelLocalContextOptionDeclHasId
      (psCKernelLocalContextGetAt? second 0)
      psCKernelLocalContextIdX &&
    psCKernelLocalContextOptionDeclHasId
      (psCKernelLocalContextGetAt? second 1)
      psCKernelLocalContextIdY

def psCKernelLocalContextTestFindContains : Bool :=
  let ctx : PsCKernelLocalContext :=
    psCKernelLocalContextMkLocalDecl
      psCKernelLocalContextEmpty
      psCKernelLocalContextIdX
      psCKernelLocalContextNameX
      (psCKernelLocalContextType "T")
      PsCKernelBinderInfo.default
      PsCKernelLocalDeclKind.default
  psCKernelLocalContextContains ctx psCKernelLocalContextIdX &&
    !psCKernelLocalContextContains ctx psCKernelLocalContextIdY &&
    psCKernelLocalContextOptionDeclHasId
      (psCKernelLocalContextFind? ctx psCKernelLocalContextIdX)
      psCKernelLocalContextIdX

def psCKernelLocalContextTestDependentLet : Bool :=
  let value : PsCKernelExpr := psCKernelLocalContextType "v"
  let ctx : PsCKernelLocalContext :=
    psCKernelLocalContextMkLetDecl
      psCKernelLocalContextEmpty
      psCKernelLocalContextIdX
      psCKernelLocalContextNameX
      (psCKernelLocalContextType "T")
      value
      false
      PsCKernelLocalDeclKind.default
  match psCKernelLocalContextFind? ctx psCKernelLocalContextIdX with
  | none => false
  | some decl =>
      psCKernelLocalDeclIsLet decl false &&
        psCKernelLocalDeclIsLet decl true &&
        psCKernelLocalContextOptionExprEq
          (psCKernelLocalDeclValue? decl false)
          (some value)

def psCKernelLocalContextTestNondepLetHidesValue : Bool :=
  let value : PsCKernelExpr := psCKernelLocalContextType "v"
  let ctx : PsCKernelLocalContext :=
    psCKernelLocalContextMkLetDecl
      psCKernelLocalContextEmpty
      psCKernelLocalContextIdX
      psCKernelLocalContextNameX
      (psCKernelLocalContextType "T")
      value
      true
      PsCKernelLocalDeclKind.default
  match psCKernelLocalContextFind? ctx psCKernelLocalContextIdX with
  | none => false
  | some decl =>
      !psCKernelLocalDeclIsLet decl false &&
        psCKernelLocalDeclIsLet decl true &&
        psCKernelLocalContextOptionExprEq
          (psCKernelLocalDeclValue? decl false)
          none &&
        psCKernelLocalContextOptionExprEq
          (psCKernelLocalDeclValue? decl true)
          (some value) &&
        psCKernelLocalDeclIsNondep decl

def psCKernelLocalContextTestLetBinderInfoDefault : Bool :=
  let ctx : PsCKernelLocalContext :=
    psCKernelLocalContextMkLetDecl
      psCKernelLocalContextEmpty
      psCKernelLocalContextIdX
      psCKernelLocalContextNameX
      (psCKernelLocalContextType "T")
      (psCKernelLocalContextType "v")
      false
      PsCKernelLocalDeclKind.default
  match psCKernelLocalContextFind? ctx psCKernelLocalContextIdX with
  | none => false
  | some decl =>
      psCKernelBinderInfoEq
        (psCKernelLocalDeclBinderInfo decl)
        PsCKernelBinderInfo.default

def psCKernelLocalContextTestKinds : Bool :=
  let ctx : PsCKernelLocalContext :=
    psCKernelLocalContextMkLocalDecl
      psCKernelLocalContextEmpty
      psCKernelLocalContextIdX
      psCKernelLocalContextNameX
      (psCKernelLocalContextType "T")
      PsCKernelBinderInfo.default
      PsCKernelLocalDeclKind.auxDecl
  match psCKernelLocalContextFind? ctx psCKernelLocalContextIdX with
  | none => false
  | some decl =>
      psCKernelLocalDeclKindEq
        (psCKernelLocalDeclKind decl)
        PsCKernelLocalDeclKind.auxDecl &&
        psCKernelLocalDeclIsImplementationDetail decl

def psCKernelLocalContextTestFVarOrder : Bool :=
  let type : PsCKernelExpr := psCKernelLocalContextType "T"
  let first : PsCKernelLocalContext :=
    psCKernelLocalContextMkLocalDecl
      psCKernelLocalContextEmpty
      psCKernelLocalContextIdX
      psCKernelLocalContextNameX
      type
      PsCKernelBinderInfo.default
      PsCKernelLocalDeclKind.default
  let second : PsCKernelLocalContext :=
    psCKernelLocalContextMkLetDecl
      first
      psCKernelLocalContextIdY
      psCKernelLocalContextNameY
      type
      (psCKernelLocalContextType "v")
      false
      PsCKernelLocalDeclKind.default
  psCKernelLocalContextIdListEq
    (psCKernelLocalContextGetFVarIds second)
    [psCKernelLocalContextIdX, psCKernelLocalContextIdY]

def psCKernelLocalContextTestUserNameLookupLatest : Bool :=
  let type : PsCKernelExpr := psCKernelLocalContextType "T"
  let first : PsCKernelLocalContext :=
    psCKernelLocalContextMkLocalDecl
      psCKernelLocalContextEmpty
      psCKernelLocalContextIdX
      psCKernelLocalContextNameZ
      type
      PsCKernelBinderInfo.default
      PsCKernelLocalDeclKind.default
  let second : PsCKernelLocalContext :=
    psCKernelLocalContextMkLocalDecl
      first
      psCKernelLocalContextIdY
      psCKernelLocalContextNameZ
      type
      PsCKernelBinderInfo.default
      PsCKernelLocalDeclKind.default
  psCKernelLocalContextOptionDeclHasId
    (psCKernelLocalContextFindFromUserName? second psCKernelLocalContextNameZ)
    psCKernelLocalContextIdY

def psCKernelLocalContextTestOutOfBounds : Bool :=
  let ctx : PsCKernelLocalContext :=
    psCKernelLocalContextMkLocalDecl
      psCKernelLocalContextEmpty
      psCKernelLocalContextIdX
      psCKernelLocalContextNameX
      (psCKernelLocalContextType "T")
      PsCKernelBinderInfo.default
      PsCKernelLocalDeclKind.default
  match psCKernelLocalContextGetAt? ctx 4 with
  | none => true
  | some _ => false

def psCKernelLocalContextTests : List PsCKernelLocalContextNamedTest := [
  { name := "empty context has zero indices", passed := psCKernelLocalContextTestEmpty },
  { name := "cdecl preserves Lean fields", passed := psCKernelLocalContextTestCDeclFields },
  { name := "declaration indices preserve insertion order", passed := psCKernelLocalContextTestIndicesAndOrder },
  { name := "find and contains use FVarId identity", passed := psCKernelLocalContextTestFindContains },
  { name := "dependent let exposes its value", passed := psCKernelLocalContextTestDependentLet },
  { name := "nondep let hides value unless explicitly allowed", passed := psCKernelLocalContextTestNondepLetHidesValue },
  { name := "let binder info is default", passed := psCKernelLocalContextTestLetBinderInfoDefault },
  { name := "declaration kind marks implementation details", passed := psCKernelLocalContextTestKinds },
  { name := "free-variable ids preserve declaration order", passed := psCKernelLocalContextTestFVarOrder },
  { name := "user-name lookup returns latest declaration", passed := psCKernelLocalContextTestUserNameLookupLatest },
  { name := "out-of-bounds lookup returns none", passed := psCKernelLocalContextTestOutOfBounds }
]

def psCKernelRunLocalContextTests
    (tests : List PsCKernelLocalContextNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_LOCAL_CONTEXT_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_LOCAL_CONTEXT_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunLocalContextTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunLocalContextTests psCKernelLocalContextTests
  if passed then
    IO.println "PSCKERNEL_LOCAL_CONTEXT_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_LOCAL_CONTEXT_TESTS: FAIL")
