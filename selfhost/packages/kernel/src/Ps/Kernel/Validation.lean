import Ps.Kernel.Environment

inductive PsKernelStructuralError where
  | duplicateConstant
  | duplicateLevelParameter
  | invalidType
  | invalidValue
  | unsupportedConstantKind

def psKernelNameMember (target : PsName) : List PsName -> Bool
  | [] => false
  | name :: rest =>
      if psNameEq target name then
        true
      else
        psKernelNameMember target rest

def psKernelNamesUnique : List PsName -> Bool
  | [] => true
  | name :: rest =>
      !psKernelNameMember name rest && psKernelNamesUnique rest

def psKernelLevelWellFormed
    (allowed : List PsName) : PsLevel -> Bool
  | .zero => true
  | .succ level => psKernelLevelWellFormed allowed level
  | .max left right =>
      psKernelLevelWellFormed allowed left
        && psKernelLevelWellFormed allowed right
  | .imax left right =>
      psKernelLevelWellFormed allowed left
        && psKernelLevelWellFormed allowed right
  | .param name => psKernelNameMember name allowed
  | .mvar _ => false

def psKernelLevelsWellFormed
    (allowed : List PsName) : List PsLevel -> Bool
  | [] => true
  | level :: rest =>
      psKernelLevelWellFormed allowed level
        && psKernelLevelsWellFormed allowed rest

def psKernelExprClosedAt
    (allowedLevels : List PsName)
    (depth : Nat) : PsExpr -> Bool
  | .bvar index => index < depth
  | .fvar _ => false
  | .mvar _ => false
  | .sortE level =>
      psKernelLevelWellFormed allowedLevels level
  | .constE _ levels =>
      psKernelLevelsWellFormed allowedLevels levels
  | .app fn arg =>
      psKernelExprClosedAt allowedLevels depth fn
        && psKernelExprClosedAt allowedLevels depth arg
  | .lam _ type body _ =>
      psKernelExprClosedAt allowedLevels depth type
        && psKernelExprClosedAt allowedLevels (depth + 1) body
  | .forallE _ type body _ =>
      psKernelExprClosedAt allowedLevels depth type
        && psKernelExprClosedAt allowedLevels (depth + 1) body
  | .letE _ type value body =>
      psKernelExprClosedAt allowedLevels depth type
        && psKernelExprClosedAt allowedLevels depth value
        && psKernelExprClosedAt allowedLevels (depth + 1) body
  | .lit _ => true
  | .proj _ _ value =>
      psKernelExprClosedAt allowedLevels depth value

def psKernelExprClosed
    (allowedLevels : List PsName)
    (expr : PsExpr) : Bool :=
  psKernelExprClosedAt allowedLevels 0 expr

def psKernelCheckHeader
    (environment : PsKernelEnvironment)
    (base : PsKernelBaseInfo) : Except PsKernelStructuralError Unit :=
  if psKernelEnvironmentContains environment base.name then
    Except.error PsKernelStructuralError.duplicateConstant
  else if !psKernelNamesUnique base.levelParams then
    Except.error PsKernelStructuralError.duplicateLevelParameter
  else if !psKernelExprClosed base.levelParams base.type then
    Except.error PsKernelStructuralError.invalidType
  else
    Except.ok ()

def psKernelCheckValue
    (base : PsKernelBaseInfo)
    (value : PsExpr) : Except PsKernelStructuralError Unit :=
  if psKernelExprClosed base.levelParams value then
    Except.ok ()
  else
    Except.error PsKernelStructuralError.invalidValue

def psKernelStructuralCheckOrdinary
    (environment : PsKernelEnvironment)
    (info : PsKernelConstantInfo) : Except PsKernelStructuralError Unit :=
  match info with
  | .axiomInfo axiomInfo =>
      psKernelCheckHeader environment axiomInfo.base
  | .definitionInfo definitionInfo =>
      match psKernelCheckHeader environment definitionInfo.base with
      | Except.error error => Except.error error
      | Except.ok _ =>
          psKernelCheckValue definitionInfo.base definitionInfo.value
  | .theoremInfo theoremInfo =>
      match psKernelCheckHeader environment theoremInfo.base with
      | Except.error error => Except.error error
      | Except.ok _ =>
          psKernelCheckValue theoremInfo.base theoremInfo.value
  | .opaqueInfo opaqueInfo =>
      match psKernelCheckHeader environment opaqueInfo.base with
      | Except.error error => Except.error error
      | Except.ok _ =>
          psKernelCheckValue opaqueInfo.base opaqueInfo.value
  | .inductiveInfo _ =>
      Except.error PsKernelStructuralError.unsupportedConstantKind
  | .constructorInfo _ =>
      Except.error PsKernelStructuralError.unsupportedConstantKind
  | .recursorInfo _ =>
      Except.error PsKernelStructuralError.unsupportedConstantKind
  | .quotInfo _ =>
      Except.error PsKernelStructuralError.unsupportedConstantKind

def psKernelStructuralInsertOrdinary
    (environment : PsKernelEnvironment)
    (info : PsKernelConstantInfo) :
    Except PsKernelStructuralError PsKernelEnvironment :=
  match psKernelStructuralCheckOrdinary environment info with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match psKernelEnvironmentAddRaw environment info with
      | none =>
          Except.error PsKernelStructuralError.duplicateConstant
      | some next =>
          Except.ok next
