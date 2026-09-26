import Ps.Core.Expr
import Ps.Core.Subst
import Ps.Core.LevelSubst
import Ps.Environment.LocalContext

structure PsMetaVarDecl where
  id : Nat
  type : PsExpr
  localContext : List PsLocalDecl

structure PsMetaAssignment where
  id : Nat
  value : PsExpr

structure PsLevelMetaAssignment where
  id : Nat
  value : PsLevel

structure PsMetaContext where
  nextId : Nat
  declarations : List PsMetaVarDecl
  assignments : List PsMetaAssignment
  levels : List PsLevelMetaAssignment


def psMetaContextEmpty : PsMetaContext :=
  {
    nextId := 0
    declarations := []
    assignments := []
    levels := []
  }


def psFindMetaDecl : Nat -> List PsMetaVarDecl -> Option PsMetaVarDecl
  | _, [] => none
  | id, declaration :: rest =>
      if id == declaration.id then
        some declaration
      else
        psFindMetaDecl id rest


def psFindMetaAssignment : Nat -> List PsMetaAssignment -> Option PsExpr
  | _, [] => none
  | id, assignment :: rest =>
      if id == assignment.id then
        some assignment.value
      else
        psFindMetaAssignment id rest


def psFindLevelMetaAssignment : Nat -> List PsLevelMetaAssignment -> Option PsLevel
  | _, [] => none
  | id, assignment :: rest =>
      if id == assignment.id then
        some assignment.value
      else
        psFindLevelMetaAssignment id rest


def psMetaLookup? (context : PsMetaContext) (id : Nat) : Option PsExpr :=
  psFindMetaAssignment id context.assignments


def psMetaLevelLookup? (context : PsMetaContext) (id : Nat) : Option PsLevel :=
  psFindLevelMetaAssignment id context.levels


def psMetaDecl? (context : PsMetaContext) (id : Nat) : Option PsMetaVarDecl :=
  psFindMetaDecl id context.declarations


def psMetaFresh (context : PsMetaContext) (type : PsExpr)
    (localContext : List PsLocalDecl) : Nat × PsMetaContext :=
  let id := context.nextId
  let declaration : PsMetaVarDecl :=
    {
      id := id
      type := type
      localContext := localContext
    }
  (
    id,
    {
      nextId := id + 1
      declarations := declaration :: context.declarations
      assignments := context.assignments
      levels := context.levels
    }
  )


def psMetaLevelFresh (context : PsMetaContext) : Nat × PsMetaContext :=
  let id := context.nextId
  (
    id,
    {
      nextId := id + 1
      declarations := context.declarations
      assignments := context.assignments
      levels := context.levels
    }
  )


def psLevelContainsMVar (id : Nat) : PsLevel -> Bool
  | .zero => false
  | .succ level => psLevelContainsMVar id level
  | .max left right =>
      if psLevelContainsMVar id left then
        true
      else
        psLevelContainsMVar id right
  | .imax left right =>
      if psLevelContainsMVar id left then
        true
      else
        psLevelContainsMVar id right
  | .param _ => false
  | .mvar otherId => id == otherId


def psLevelHasMVar : PsLevel -> Bool
  | .zero => false
  | .succ level => psLevelHasMVar level
  | .max left right =>
      if psLevelHasMVar left then
        true
      else
        psLevelHasMVar right
  | .imax left right =>
      if psLevelHasMVar left then
        true
      else
        psLevelHasMVar right
  | .param _ => false
  | .mvar _ => true


def psLevelListHasMVar : List PsLevel -> Bool
  | [] => false
  | level :: rest =>
      if psLevelHasMVar level then
        true
      else
        psLevelListHasMVar rest


def psExprContainsMVar (id : Nat) : PsExpr -> Bool
  | .bvar _ => false
  | .fvar _ => false
  | .mvar otherId => id == otherId
  | .sortE _ => false
  | .constE _ _ => false
  | .app fn arg =>
      if psExprContainsMVar id fn then
        true
      else
        psExprContainsMVar id arg
  | .lam _ type body _ =>
      if psExprContainsMVar id type then
        true
      else
        psExprContainsMVar id body
  | .forallE _ type body _ =>
      if psExprContainsMVar id type then
        true
      else
        psExprContainsMVar id body
  | .letE _ type value body =>
      if psExprContainsMVar id type then
        true
      else if psExprContainsMVar id value then
        true
      else
        psExprContainsMVar id body
  | .lit _ => false
  | .proj _ _ value => psExprContainsMVar id value


def psAssignMeta
    (context : PsMetaContext)
    (id : Nat)
    (value : PsExpr) : Option PsMetaContext :=
  match psMetaLookup? context id with
  | some _ => none
  | none =>
      match psMetaDecl? context id with
      | none => none
      | some declaration =>
          let resolved :=
            psInstantiateExprMVarsWith
              (fun metaId => psMetaLookup? context metaId)
              value
          if psExprContainsMVar id resolved then
            none
          else if psExprFVarsInContext declaration.localContext resolved then
            let assignment : PsMetaAssignment :=
              {
                id := id
                value := resolved
              }
            some
              {
                nextId := context.nextId
                declarations := context.declarations
                assignments := assignment :: context.assignments
                levels := context.levels
              }
          else
            none


def psAssignLevelMeta
    (context : PsMetaContext)
    (id : Nat)
    (value : PsLevel) : Option PsMetaContext :=
  match psMetaLevelLookup? context id with
  | some _ => none
  | none =>
      let resolved :=
        psInstantiateLevelMVarsWith
          (fun metaId => psMetaLevelLookup? context metaId)
          value
      if psLevelContainsMVar id resolved then
        none
      else
        let assignment : PsLevelMetaAssignment :=
          {
            id := id
            value := resolved
          }
        some
          {
            nextId := context.nextId
            declarations := context.declarations
            assignments := context.assignments
            levels := assignment :: context.levels
          }


def psExprHasUnresolvedMeta : PsExpr -> Bool
  | .mvar _ => true
  | .sortE level => psLevelHasMVar level
  | .constE _ levels => psLevelListHasMVar levels
  | .app fn arg =>
      if psExprHasUnresolvedMeta fn then
        true
      else
        psExprHasUnresolvedMeta arg
  | .lam _ type body _ =>
      if psExprHasUnresolvedMeta type then
        true
      else
        psExprHasUnresolvedMeta body
  | .forallE _ type body _ =>
      if psExprHasUnresolvedMeta type then
        true
      else
        psExprHasUnresolvedMeta body
  | .letE _ type value body =>
      if psExprHasUnresolvedMeta type then
        true
      else if psExprHasUnresolvedMeta value then
        true
      else
        psExprHasUnresolvedMeta body
  | .proj _ _ value => psExprHasUnresolvedMeta value
  | _ => false
