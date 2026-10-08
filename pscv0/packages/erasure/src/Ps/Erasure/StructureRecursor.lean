import Ps.Erasure.Structure

def psErasureStructureNameFromRecursor
    (name : PsName) : Option PsName :=
  match name with
  | PsName.str parent value =>
      if psStringEq value "rec" then
        Option.some parent
      else
        Option.none
  | _ => Option.none

def psErasureApplyStructureMinorFields
    (structureName : PsName) (major : PsExpr) (count : Nat) :
    Nat -> PsExpr -> Except PsErasureError PsExpr :=
  match count with
  | Nat.zero => fun (_index : Nat) (minor : PsExpr) => Except.ok minor
  | Nat.succ remaining =>
    let smaller : Nat -> PsExpr -> Except PsErasureError PsExpr :=
      psErasureApplyStructureMinorFields structureName major remaining;
    fun (index : Nat) (minor : PsExpr) =>
      match minor with
      | PsExpr.lam _ _ body _ =>
          let projection :=
            PsExpr.proj structureName index major;
          smaller
            (Nat.add index 1)
            (psExprInstantiate1 body projection)
      | _ => Except.error PsErasureError.binderMismatch


def psTryLowerStructureRecursorApplication
    (environment : PsEnvironment)
    (expr : PsExpr) :
    Except PsErasureError (Option PsExpr) :=
  let view := psErasureAppView expr;
  match view.head with
  | PsExpr.constE recursorName _ =>
      match psErasureStructureNameFromRecursor recursorName with
      | Option.none => Except.ok Option.none
      | Option.some structureName =>
          match psEnvironmentFindInductive environment structureName with
          | Option.none => Except.ok Option.none
          | Option.some info =>
              if if info.isStructure then psErasureNatNotEqual info.numIndices 0 else true then
                Except.ok Option.none
              else
                match psEnvironmentFindRecursor environment recursorName with
                | Option.none => Except.ok Option.none
                | Option.some recInfo =>
                    if
                        if psErasureNatNotEqual recInfo.numParams info.numParams then true
                        else if psErasureNatNotEqual recInfo.numIndices 0 then true
                        else if psErasureNatNotEqual recInfo.numMotives 1 then true
                        else psErasureNatNotEqual recInfo.numMinors 1 then
                      Except.error PsErasureError.unsupportedRuntimeTerm
                    else
                      match info.constructors with
                      | List.cons constructorName rest =>
                          match rest with
                          | List.nil =>
                              match
                                  psEnvironmentFindConstructor
                                    environment
                                    constructorName with
                              | Option.none =>
                                  Except.error
                                    (PsErasureError.unknownConstant constructorName)
                              | Option.some constructorInfo =>
                                  if psErasureNatNotEqual constructorInfo.numParams info.numParams then
                                    Except.error PsErasureError.unsupportedRuntimeTerm
                                  else
                                    let expectedArity :=
                                      Nat.add info.numParams 3;
                                    if psErasureNatNotEqual (psListLength view.args) expectedArity then
                                      Except.ok Option.none
                                    else
                                      let motiveIndex := info.numParams;
                                      let minorIndex := Nat.add info.numParams 1;
                                      let majorIndex := Nat.sub expectedArity 1;
                                      match psErasureExprListAt view.args motiveIndex with
                                      | Option.none => Except.error PsErasureError.unsupportedApplication
                                      | Option.some motive =>
                                          match psErasureExprListAt view.args minorIndex with
                                          | Option.none => Except.error PsErasureError.unsupportedApplication
                                          | Option.some minor =>
                                              match psErasureExprListAt view.args majorIndex with
                                              | Option.none => Except.error PsErasureError.unsupportedApplication
                                              | Option.some major =>
                                                  match motive with
                                                  | PsExpr.lam _ majorType _ _ =>
                                                      let liftedMinor :=
                                                        psExprLiftBVars 1 0 minor;
                                                      match
                                                          psErasureApplyStructureMinorFields
                                                            structureName
                                                            (PsExpr.bvar 0)
                                                            constructorInfo.numFields
                                                            0
                                                            liftedMinor with
                                                      | Except.error error =>
                                                          Except.error error
                                                      | Except.ok body =>
                                                          Except.ok
                                                            (Option.some
                                                              (PsExpr.letE
                                                                (psRootName "_psStructureMajor")
                                                                majorType
                                                                major
                                                                body))
                                                  | _ =>
                                                      Except.error PsErasureError.binderMismatch
                          | List.cons _ _ => Except.error PsErasureError.unsupportedRuntimeTerm
                      | _ => Except.error PsErasureError.unsupportedRuntimeTerm
  | _ => Except.ok Option.none

def psLowerStructureRecursorsWithFuel
    (environment : PsEnvironment) (fuel : Nat) : PsExpr -> Except PsErasureError PsExpr :=
  match fuel with
  | Nat.zero => fun (_expr : PsExpr) => Except.error PsErasureError.fuelExhausted
  | Nat.succ remaining =>
    let smaller : PsExpr -> Except PsErasureError PsExpr := psLowerStructureRecursorsWithFuel environment remaining;
    fun (expr : PsExpr) =>
      match expr with
      | PsExpr.app fn arg =>
          match
              smaller
                fn with
          | Except.error error => Except.error error
          | Except.ok loweredFn =>
              match
                  smaller
                    arg with
              | Except.error error => Except.error error
              | Except.ok loweredArg =>
                  let rebuilt := PsExpr.app loweredFn loweredArg;
                  match
                      psTryLowerStructureRecursorApplication
                        environment
                        rebuilt with
                  | Except.error error => Except.error error
                  | Except.ok result =>
                      match result with
                      | Option.none => Except.ok rebuilt
                      | Option.some lowered => Except.ok lowered
      | PsExpr.lam name type body binder =>
          match
              smaller
                type with
          | Except.error error => Except.error error
          | Except.ok loweredType =>
              match
                  smaller
                    body with
              | Except.error error => Except.error error
              | Except.ok loweredBody =>
                  Except.ok
                    (PsExpr.lam name loweredType loweredBody binder)
      | PsExpr.forallE name type body binder =>
          match
              smaller
                type with
          | Except.error error => Except.error error
          | Except.ok loweredType =>
              match
                  smaller
                    body with
              | Except.error error => Except.error error
              | Except.ok loweredBody =>
                  Except.ok
                    (PsExpr.forallE name loweredType loweredBody binder)
      | PsExpr.letE name type value body =>
          match
              smaller
                type with
          | Except.error error => Except.error error
          | Except.ok loweredType =>
              match
                  smaller
                    value with
              | Except.error error => Except.error error
              | Except.ok loweredValue =>
                  match
                      smaller
                        body with
                  | Except.error error => Except.error error
                  | Except.ok loweredBody =>
                      Except.ok
                        (PsExpr.letE
                          name
                          loweredType
                          loweredValue
                          loweredBody)
      | PsExpr.proj typeName index value =>
          match
              smaller
                value with
          | Except.error error => Except.error error
          | Except.ok loweredValue =>
              Except.ok
                (PsExpr.proj typeName index loweredValue)
      | _ => Except.ok expr


def psLowerStructureRecursors
    (environment : PsEnvironment)
    (expr : PsExpr) : Except PsErasureError PsExpr :=
  psLowerStructureRecursorsWithFuel environment 4096 expr
