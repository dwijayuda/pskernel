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
    (structureName : PsName)
    (major : PsExpr) :
    Nat -> Nat -> PsExpr -> Except PsErasureError PsExpr
  | 0, _, minor => Except.ok minor
  | remaining + 1, index, minor =>
      match minor with
      | PsExpr.lam _ _ body _ =>
          let projection :=
            PsExpr.proj structureName index major;
          psErasureApplyStructureMinorFields
            structureName
            major
            remaining
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
              if !info.isStructure || info.numIndices != 0 then
                Except.ok Option.none
              else
                match psEnvironmentFindRecursor environment recursorName with
                | Option.none => Except.ok Option.none
                | Option.some recInfo =>
                    if
                        recInfo.numParams != info.numParams
                          || recInfo.numIndices != 0
                          || recInfo.numMotives != 1
                          || recInfo.numMinors != 1 then
                      Except.error PsErasureError.unsupportedRuntimeTerm
                    else
                      match info.constructors with
                      | [constructorName] =>
                          match
                              psEnvironmentFindConstructor
                                environment
                                constructorName with
                          | Option.none =>
                              Except.error
                                (PsErasureError.unknownConstant constructorName)
                          | Option.some constructorInfo =>
                              if constructorInfo.numParams != info.numParams then
                                Except.error PsErasureError.unsupportedRuntimeTerm
                              else
                                let expectedArity :=
                                  Nat.add info.numParams 3;
                                if view.args.length != expectedArity then
                                  Except.ok Option.none
                                else
                                  let motiveIndex := info.numParams;
                                  let minorIndex := Nat.add info.numParams 1;
                                  let majorIndex := Nat.sub expectedArity 1;
                                  match
                                      view.args[motiveIndex]?,
                                      view.args[minorIndex]?,
                                      view.args[majorIndex]? with
                                  | Option.some motive,
                                    Option.some minor,
                                    Option.some major =>
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
                                  | _, _, _ =>
                                      Except.error PsErasureError.unsupportedApplication
                      | _ => Except.error PsErasureError.unsupportedRuntimeTerm
  | _ => Except.ok Option.none

partial def psLowerStructureRecursorsWithFuel
    (environment : PsEnvironment) :
    Nat -> PsExpr -> Except PsErasureError PsExpr
  | 0, _ => Except.error PsErasureError.fuelExhausted
  | fuel + 1, expr =>
      match expr with
      | PsExpr.app fn arg =>
          match
              psLowerStructureRecursorsWithFuel
                environment
                fuel
                fn with
          | Except.error error => Except.error error
          | Except.ok loweredFn =>
              match
                  psLowerStructureRecursorsWithFuel
                    environment
                    fuel
                    arg with
              | Except.error error => Except.error error
              | Except.ok loweredArg =>
                  let rebuilt := PsExpr.app loweredFn loweredArg;
                  match
                      psTryLowerStructureRecursorApplication
                        environment
                        rebuilt with
                  | Except.error error => Except.error error
                  | Except.ok Option.none => Except.ok rebuilt
                  | Except.ok (Option.some lowered) => Except.ok lowered
      | PsExpr.lam name type body binder =>
          match
              psLowerStructureRecursorsWithFuel
                environment
                fuel
                type with
          | Except.error error => Except.error error
          | Except.ok loweredType =>
              match
                  psLowerStructureRecursorsWithFuel
                    environment
                    fuel
                    body with
              | Except.error error => Except.error error
              | Except.ok loweredBody =>
                  Except.ok
                    (PsExpr.lam name loweredType loweredBody binder)
      | PsExpr.forallE name type body binder =>
          match
              psLowerStructureRecursorsWithFuel
                environment
                fuel
                type with
          | Except.error error => Except.error error
          | Except.ok loweredType =>
              match
                  psLowerStructureRecursorsWithFuel
                    environment
                    fuel
                    body with
              | Except.error error => Except.error error
              | Except.ok loweredBody =>
                  Except.ok
                    (PsExpr.forallE name loweredType loweredBody binder)
      | PsExpr.letE name type value body =>
          match
              psLowerStructureRecursorsWithFuel
                environment
                fuel
                type with
          | Except.error error => Except.error error
          | Except.ok loweredType =>
              match
                  psLowerStructureRecursorsWithFuel
                    environment
                    fuel
                    value with
              | Except.error error => Except.error error
              | Except.ok loweredValue =>
                  match
                      psLowerStructureRecursorsWithFuel
                        environment
                        fuel
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
              psLowerStructureRecursorsWithFuel
                environment
                fuel
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
