import Ps.Erasure.Basic

def psPrimitiveNatFindOutputSourceName
    (target : String) :
    List (PsName × String) -> Option PsName
  | [] => none
  | entry :: rest =>
      if entry.2 == target then
        some entry.1
      else
        psPrimitiveNatFindOutputSourceName target rest

def psPrimitiveNatFindRuntimeId
    (target : String) :
    List (Nat × String) -> Option Nat
  | [] => none
  | entry :: rest =>
      if entry.2 == target then
        some entry.1
      else
        psPrimitiveNatFindRuntimeId target rest

def psPrimitiveNatFindStringIndex
    (target : String) :
    List String -> Nat -> Option Nat
  | [], _ => none
  | value :: rest, index =>
      if value == target then
        some index
      else
        psPrimitiveNatFindStringIndex target rest (index + 1)

def psPrimitiveNatApply : PsExpr -> List PsExpr -> PsExpr
  | head, [] => head
  | head, argument :: rest =>
      psPrimitiveNatApply (PsExpr.app head argument) rest

def psPrimitiveNatBuildRecursiveArguments
    (runtimeLocals : List (Nat × String))
    (replacementIndex : Nat)
    (replacement : PsExpr) :
    List String -> Nat -> Option (List PsExpr)
  | [], _ => some []
  | parameter :: rest, index =>
      let current : Option PsExpr :=
        if index == replacementIndex then
          some replacement
        else
          match psPrimitiveNatFindRuntimeId parameter runtimeLocals with
          | none => none
          | some id => some (PsExpr.fvar id)
      match current with
      | none => none
      | some value =>
          match
              psPrimitiveNatBuildRecursiveArguments
                runtimeLocals
                replacementIndex
                replacement
                rest
                (index + 1) with
          | none => none
          | some values => some (value :: values)

def psPrimitiveNatRecursiveCall
    (scope : PsErasureScope)
    (replacementIndex : Nat)
    (replacement : PsExpr) : Option PsExpr :=
  match scope.currentDefinition with
  | none => none
  | some current =>
      match
          psPrimitiveNatFindOutputSourceName
            current.name
            scope.declarationNames with
      | none => none
      | some sourceName =>
          match
              psPrimitiveNatBuildRecursiveArguments
                scope.runtimeLocals
                replacementIndex
                replacement
                current.runtimeParameters
                0 with
          | none => none
          | some arguments =>
              some
                (psPrimitiveNatApply
                  (PsExpr.constE sourceName [])
                  arguments)

def psPrimitiveNatZero : PsExpr :=
  PsExpr.lit (PsLiteral.natural 0)

def psPrimitiveNatOne : PsExpr :=
  PsExpr.lit (PsLiteral.natural 1)

def psPrimitiveNatAddOne (value : PsExpr) : PsExpr :=
  psPrimitiveNatApply
    (PsExpr.constE psNatAddName [])
    [value, psPrimitiveNatOne]

def psPrimitiveNatSubOne (value : PsExpr) : PsExpr :=
  psPrimitiveNatApply
    (PsExpr.constE psNatSubName [])
    [value, psPrimitiveNatOne]

def psPrimitiveNatIsZero (value : PsExpr) : PsExpr :=
  psPrimitiveNatApply
    (PsExpr.constE psNatBeqName [])
    [value, psPrimitiveNatZero]

def psPrimitiveNatBoolCondition (condition : PsExpr) : PsExpr :=
  psPrimitiveNatApply
    (PsExpr.constE psEqName [])
    [
      PsExpr.constE psBoolName [],
      condition,
      PsExpr.constE psBoolTrueName []
    ]

def psPrimitiveNatIte
    (condition thenBranch elseBranch : PsExpr) : PsExpr :=
  psPrimitiveNatApply
    (PsExpr.constE psIteName [])
    [
      PsExpr.constE psNatName [],
      psPrimitiveNatBoolCondition condition,
      PsExpr.constE psUnitUnitName [],
      thenBranch,
      elseBranch
    ]

def psTryLowerPrimitiveNatApplication
    (scope : PsErasureScope)
    (expr : PsExpr) : Except PsErasureError (Option PsExpr) :=
  let view := psErasureAppView expr
  match view.head with
  | PsExpr.constE name _ =>
      if psNameEq name psNatSuccName then
        match view.args with
        | [value] =>
            Except.ok (some (psPrimitiveNatAddOne value))
        | _ => Except.ok none
      else if psNameEq name psNatRecName then
        match view.args with
        | [_, zeroMinor, successorMinor, major] =>
            match major with
            | PsExpr.fvar majorId =>
                match
                    psErasureLookupNat
                      scope.runtimeLocals
                      majorId,
                    scope.currentDefinition with
                | some majorName, some current =>
                    match
                        psPrimitiveNatFindStringIndex
                          majorName
                          current.runtimeParameters
                          0 with
                    | none => Except.ok none
                    | some parameterIndex =>
                        let predecessor :=
                          psPrimitiveNatSubOne major
                        match
                            psPrimitiveNatRecursiveCall
                              scope
                              parameterIndex
                              predecessor with
                        | none => Except.ok none
                        | some recursiveCall =>
                            match successorMinor with
                            | PsExpr.lam _ _ predecessorBody _ =>
                                let withPredecessor :=
                                  psExprInstantiate1
                                    predecessorBody
                                    predecessor
                                match withPredecessor with
                                | PsExpr.lam _ _ hypothesisBody _ =>
                                    let successorBody :=
                                      psExprInstantiate1
                                        hypothesisBody
                                        recursiveCall
                                    Except.ok
                                      (some
                                        (psPrimitiveNatIte
                                          (psPrimitiveNatIsZero major)
                                          zeroMinor
                                          successorBody))
                                | _ =>
                                    Except.error
                                      PsErasureError.binderMismatch
                            | _ =>
                                Except.error PsErasureError.binderMismatch
                | _, _ => Except.ok none
            | _ => Except.ok none
        | _ => Except.ok none
      else
        Except.ok none
  | _ => Except.ok none

partial def psLowerPrimitiveNatWithFuel
    (scope : PsErasureScope) :
    Nat -> PsExpr -> Except PsErasureError PsExpr
  | 0, _ => Except.error PsErasureError.fuelExhausted
  | fuel + 1, expr =>
      match expr with
      | PsExpr.app fn argument =>
          match psLowerPrimitiveNatWithFuel scope fuel fn with
          | Except.error error => Except.error error
          | Except.ok loweredFn =>
              match
                  psLowerPrimitiveNatWithFuel
                    scope
                    fuel
                    argument with
              | Except.error error => Except.error error
              | Except.ok loweredArgument =>
                  let rebuilt := PsExpr.app loweredFn loweredArgument
                  match
                      psTryLowerPrimitiveNatApplication
                        scope
                        rebuilt with
                  | Except.error error => Except.error error
                  | Except.ok none => Except.ok rebuilt
                  | Except.ok (some lowered) =>
                      psLowerPrimitiveNatWithFuel scope fuel lowered
      | PsExpr.lam name type body binder =>
          match psLowerPrimitiveNatWithFuel scope fuel type with
          | Except.error error => Except.error error
          | Except.ok loweredType =>
              match psLowerPrimitiveNatWithFuel scope fuel body with
              | Except.error error => Except.error error
              | Except.ok loweredBody =>
                  Except.ok
                    (PsExpr.lam name loweredType loweredBody binder)
      | PsExpr.forallE name type body binder =>
          match psLowerPrimitiveNatWithFuel scope fuel type with
          | Except.error error => Except.error error
          | Except.ok loweredType =>
              match psLowerPrimitiveNatWithFuel scope fuel body with
              | Except.error error => Except.error error
              | Except.ok loweredBody =>
                  Except.ok
                    (PsExpr.forallE name loweredType loweredBody binder)
      | PsExpr.letE name type value body =>
          match psLowerPrimitiveNatWithFuel scope fuel type with
          | Except.error error => Except.error error
          | Except.ok loweredType =>
              match psLowerPrimitiveNatWithFuel scope fuel value with
              | Except.error error => Except.error error
              | Except.ok loweredValue =>
                  match psLowerPrimitiveNatWithFuel scope fuel body with
                  | Except.error error => Except.error error
                  | Except.ok loweredBody =>
                      Except.ok
                        (PsExpr.letE
                          name
                          loweredType
                          loweredValue
                          loweredBody)
      | PsExpr.proj typeName index target =>
          match psLowerPrimitiveNatWithFuel scope fuel target with
          | Except.error error => Except.error error
          | Except.ok loweredTarget =>
              Except.ok (PsExpr.proj typeName index loweredTarget)
      | _ => Except.ok expr

def psLowerPrimitiveNat
    (scope : PsErasureScope)
    (expr : PsExpr) : Except PsErasureError PsExpr :=
  psLowerPrimitiveNatWithFuel scope 4096 expr
