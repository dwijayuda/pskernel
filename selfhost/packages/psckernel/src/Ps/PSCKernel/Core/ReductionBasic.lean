import Ps.PSCKernel.Core.Environment
import Ps.PSCKernel.Core.LocalContext
import Ps.PSCKernel.Core.ExprLevelInstantiation
import Ps.PSCKernel.Core.ExprInstantiation

def psCKernelExprUnfoldDefinitionBasic?
    (env : PsCKernelEnvironment)
    (expr : PsCKernelExpr) : Option PsCKernelExpr :=
  match expr with
  | PsCKernelExpr.constE name levels =>
      match psCKernelEnvironmentFind? env name with
      | some info =>
          match info with
          | PsCKernelConstantInfo.defnInfo value =>
              if Nat.beq levels.length value.base.levelParams.length then
                some
                  (psCKernelInstantiateExprLevels
                    value.value
                    value.base.levelParams
                    levels)
              else
                none
          | _ => none
      | none => none
  | _ => none

def psCKernelExprReduceProjectionCoreBasic?
    (env : PsCKernelEnvironment)
    (typeName : PsCKernelName)
    (index : Nat)
    (major : PsCKernelExpr) : Option PsCKernelExpr :=
  match psCKernelExprGetAppFn major with
  | PsCKernelExpr.constE ctorName _ =>
      match psCKernelEnvironmentFind? env ctorName with
      | some info =>
          match info with
          | PsCKernelConstantInfo.ctorInfo value =>
              if psCKernelNameEq value.induct typeName then
                if Nat.blt index value.numFields then
                  psCKernelExprListGet?
                    (psCKernelExprGetAppArgs major)
                    (Nat.add value.numParams index)
                else
                  none
              else
                none
          | _ => none
      | none => none
  | _ => none

def psCKernelExprListTake
    (values : List PsCKernelExpr)
    (count : Nat) : List PsCKernelExpr :=
  match values, count with
  | _, 0 => []
  | [], _ => []
  | value :: rest, Nat.succ remaining =>
      value :: psCKernelExprListTake rest remaining

def psCKernelExprListDrop
    (values : List PsCKernelExpr)
    (count : Nat) : List PsCKernelExpr :=
  match values, count with
  | values, 0 => values
  | [], _ => []
  | _ :: rest, Nat.succ remaining =>
      psCKernelExprListDrop rest remaining

def psCKernelFindRecursorRule?
    (rules : List PsCKernelRecursorRule)
    (ctorName : PsCKernelName) : Option PsCKernelRecursorRule :=
  match rules with
  | [] => none
  | rule :: rest =>
      if psCKernelNameEq rule.ctor ctorName then
        some rule
      else
        psCKernelFindRecursorRule? rest ctorName

def psCKernelNatZeroName : PsCKernelName :=
  psCKernelNameFromDotted "Nat.zero"

def psCKernelNatSuccName : PsCKernelName :=
  psCKernelNameFromDotted "Nat.succ"

def psCKernelNatAddName : PsCKernelName :=
  psCKernelNameFromDotted "Nat.add"

def psCKernelNatSubName : PsCKernelName :=
  psCKernelNameFromDotted "Nat.sub"

def psCKernelNatMulName : PsCKernelName :=
  psCKernelNameFromDotted "Nat.mul"

def psCKernelNatPowName : PsCKernelName :=
  psCKernelNameFromDotted "Nat.pow"

def psCKernelNatGcdName : PsCKernelName :=
  psCKernelNameFromDotted "Nat.gcd"

def psCKernelNatModName : PsCKernelName :=
  psCKernelNameFromDotted "Nat.mod"

def psCKernelNatDivName : PsCKernelName :=
  psCKernelNameFromDotted "Nat.div"

def psCKernelNatLandName : PsCKernelName :=
  psCKernelNameFromDotted "Nat.land"

def psCKernelNatLorName : PsCKernelName :=
  psCKernelNameFromDotted "Nat.lor"

def psCKernelNatXorName : PsCKernelName :=
  psCKernelNameFromDotted "Nat.xor"

def psCKernelNatShiftLeftName : PsCKernelName :=
  psCKernelNameFromDotted "Nat.shiftLeft"

def psCKernelNatShiftRightName : PsCKernelName :=
  psCKernelNameFromDotted "Nat.shiftRight"

def psCKernelNatBeqName : PsCKernelName :=
  psCKernelNameFromDotted "Nat.beq"

def psCKernelNatBleName : PsCKernelName :=
  psCKernelNameFromDotted "Nat.ble"

def psCKernelBoolFalseName : PsCKernelName :=
  psCKernelNameFromDotted "Bool.false"

def psCKernelBoolTrueName : PsCKernelName :=
  psCKernelNameFromDotted "Bool.true"

def psCKernelQuotMkName : PsCKernelName :=
  psCKernelNameFromDotted "Quot.mk"

def psCKernelQuotLiftName : PsCKernelName :=
  psCKernelNameFromDotted "Quot.lift"

def psCKernelQuotIndName : PsCKernelName :=
  psCKernelNameFromDotted "Quot.ind"

def psCKernelNatLiteralToConstructor (value : Nat) : PsCKernelExpr :=
  match value with
  | 0 => PsCKernelExpr.constE psCKernelNatZeroName []
  | Nat.succ predecessor =>
      PsCKernelExpr.app
        (PsCKernelExpr.constE psCKernelNatSuccName [])
        (PsCKernelExpr.lit (PsCKernelLiteral.natVal predecessor))

def psCKernelNatValue? (expr : PsCKernelExpr) : Option Nat :=
  match expr with
  | PsCKernelExpr.lit (PsCKernelLiteral.natVal value) => some value
  | PsCKernelExpr.constE name levels =>
      if Nat.beq levels.length 0 then
        if psCKernelNameEq name psCKernelNatZeroName then
          some 0
        else
          none
      else
        none
  | _ => none

def psCKernelNatLiteralExpr (value : Nat) : PsCKernelExpr :=
  PsCKernelExpr.lit (PsCKernelLiteral.natVal value)

def psCKernelBoolExpr (value : Bool) : PsCKernelExpr :=
  if value then
    PsCKernelExpr.constE psCKernelBoolTrueName []
  else
    PsCKernelExpr.constE psCKernelBoolFalseName []

def psCKernelNatPrimitiveBinary?
    (name : PsCKernelName)
    (left : Nat)
    (right : Nat) : Option PsCKernelExpr :=
  if psCKernelNameEq name psCKernelNatAddName then
    some (psCKernelNatLiteralExpr (Nat.add left right))
  else if psCKernelNameEq name psCKernelNatSubName then
    some (psCKernelNatLiteralExpr (Nat.sub left right))
  else if psCKernelNameEq name psCKernelNatMulName then
    some (psCKernelNatLiteralExpr (Nat.mul left right))
  else if psCKernelNameEq name psCKernelNatPowName then
    some (psCKernelNatLiteralExpr (Nat.pow left right))
  else if psCKernelNameEq name psCKernelNatGcdName then
    some (psCKernelNatLiteralExpr (Nat.gcd left right))
  else if psCKernelNameEq name psCKernelNatModName then
    some (psCKernelNatLiteralExpr (Nat.mod left right))
  else if psCKernelNameEq name psCKernelNatDivName then
    some (psCKernelNatLiteralExpr (Nat.div left right))
  else if psCKernelNameEq name psCKernelNatLandName then
    some (psCKernelNatLiteralExpr (Nat.land left right))
  else if psCKernelNameEq name psCKernelNatLorName then
    some (psCKernelNatLiteralExpr (Nat.lor left right))
  else if psCKernelNameEq name psCKernelNatXorName then
    some (psCKernelNatLiteralExpr (Nat.xor left right))
  else if psCKernelNameEq name psCKernelNatShiftLeftName then
    some (psCKernelNatLiteralExpr (Nat.shiftLeft left right))
  else if psCKernelNameEq name psCKernelNatShiftRightName then
    some (psCKernelNatLiteralExpr (Nat.shiftRight left right))
  else if psCKernelNameEq name psCKernelNatBeqName then
    some (psCKernelBoolExpr (Nat.beq left right))
  else if psCKernelNameEq name psCKernelNatBleName then
    some (psCKernelBoolExpr (Nat.ble left right))
  else
    none

partial def psCKernelExprWhnfBasic
    (env : PsCKernelEnvironment)
    (lctx : PsCKernelLocalContext)
    (expr : PsCKernelExpr) : PsCKernelExpr :=
  match expr with
  | PsCKernelExpr.fvar fvarId =>
      match psCKernelLocalContextFind? lctx fvarId with
      | none => expr
      | some decl =>
          match psCKernelLocalDeclValue? decl false with
          | none => expr
          | some value => psCKernelExprWhnfBasic env lctx value
  | PsCKernelExpr.constE _ _ =>
      match psCKernelExprUnfoldDefinitionBasic? env expr with
      | none => expr
      | some value => psCKernelExprWhnfBasic env lctx value
  | PsCKernelExpr.app fn arg =>
      let appHead := psCKernelExprGetAppFn expr
      let appArgs := psCKernelExprGetAppArgs expr
      let natPrimitiveReduced : Option PsCKernelExpr :=
        match appHead with
        | PsCKernelExpr.constE primitiveName primitiveLevels =>
            if Nat.beq primitiveLevels.length 0 then
              if psCKernelNameEq primitiveName psCKernelNatSuccName then
                if Nat.beq appArgs.length 1 then
                  match psCKernelExprListGet? appArgs 0 with
                  | none => none
                  | some operand =>
                      match psCKernelNatValue?
                          (psCKernelExprWhnfBasic env lctx operand) with
                      | none => none
                      | some value =>
                          some (psCKernelNatLiteralExpr (Nat.succ value))
                else
                  none
              else if Nat.beq appArgs.length 2 then
                match psCKernelExprListGet? appArgs 0,
                    psCKernelExprListGet? appArgs 1 with
                | some leftExpr, some rightExpr =>
                    let reducedLeft := psCKernelExprWhnfBasic env lctx leftExpr
                    let reducedRight := psCKernelExprWhnfBasic env lctx rightExpr
                    match psCKernelNatValue? reducedLeft,
                        psCKernelNatValue? reducedRight with
                    | some leftValue, some rightValue =>
                        psCKernelNatPrimitiveBinary?
                          primitiveName
                          leftValue
                          rightValue
                    | _, _ => none
                | _, _ => none
              else
                none
            else
              none
        | _ => none
      let quotientReduced : Option PsCKernelExpr :=
        if env.quotInitialized then
          match appHead with
          | PsCKernelExpr.constE quotientName _ =>
              if psCKernelNameEq quotientName psCKernelQuotLiftName then
                if Nat.ble 6 appArgs.length then
                  match psCKernelExprListGet? appArgs 5 with
                  | none => none
                  | some major =>
                      let reducedMajor := psCKernelExprWhnfBasic env lctx major
                      match psCKernelExprGetAppFn reducedMajor with
                      | PsCKernelExpr.constE ctorName _ =>
                          let ctorArgs := psCKernelExprGetAppArgs reducedMajor
                          if psCKernelNameEq ctorName psCKernelQuotMkName then
                            if Nat.beq ctorArgs.length 3 then
                              match psCKernelExprListGet? appArgs 3,
                                  psCKernelExprListGet? ctorArgs 2 with
                              | some fnValue, some payload =>
                                  some
                                    (psCKernelExprMkAppN
                                      fnValue
                                      (payload :: psCKernelExprListDrop appArgs 6))
                              | _, _ => none
                            else
                              none
                          else
                            none
                      | _ => none
                else
                  none
              else if psCKernelNameEq quotientName psCKernelQuotIndName then
                if Nat.ble 5 appArgs.length then
                  match psCKernelExprListGet? appArgs 4 with
                  | none => none
                  | some major =>
                      let reducedMajor := psCKernelExprWhnfBasic env lctx major
                      match psCKernelExprGetAppFn reducedMajor with
                      | PsCKernelExpr.constE ctorName _ =>
                          let ctorArgs := psCKernelExprGetAppArgs reducedMajor
                          if psCKernelNameEq ctorName psCKernelQuotMkName then
                            if Nat.beq ctorArgs.length 3 then
                              match psCKernelExprListGet? appArgs 3,
                                  psCKernelExprListGet? ctorArgs 2 with
                              | some proof, some payload =>
                                  some
                                    (psCKernelExprMkAppN
                                      proof
                                      (payload :: psCKernelExprListDrop appArgs 5))
                              | _, _ => none
                            else
                              none
                          else
                            none
                      | _ => none
                else
                  none
              else
                none
          | _ => none
        else
          none
      let recursorReduced : Option PsCKernelExpr :=
        match appHead with
        | PsCKernelExpr.constE recursorName recursorLevels =>
            match psCKernelEnvironmentFind? env recursorName with
            | some (PsCKernelConstantInfo.recInfo recursor) =>
                let majorIndex :=
                  Nat.add recursor.numParams
                    (Nat.add recursor.numMotives
                      (Nat.add recursor.numMinors recursor.numIndices))
                match psCKernelExprListGet? appArgs majorIndex with
                | none => none
                | some major =>
                    let reducedMajor := psCKernelExprWhnfBasic env lctx major
                    let ruleMajor :=
                      match reducedMajor with
                      | PsCKernelExpr.lit (PsCKernelLiteral.natVal value) =>
                          psCKernelNatLiteralToConstructor value
                      | _ => reducedMajor
                    match psCKernelExprGetAppFn ruleMajor with
                    | PsCKernelExpr.constE ctorName _ =>
                        match psCKernelFindRecursorRule? recursor.rules ctorName with
                        | none => none
                        | some rule =>
                            let majorArgs := psCKernelExprGetAppArgs ruleMajor
                            if Nat.ble rule.nfields majorArgs.length then
                              if Nat.beq
                                  recursorLevels.length
                                  recursor.base.levelParams.length then
                                let rhs :=
                                  psCKernelInstantiateExprLevels
                                    rule.rhs
                                    recursor.base.levelParams
                                    recursorLevels
                                let firstIndex :=
                                  Nat.add recursor.numParams
                                    (Nat.add recursor.numMotives recursor.numMinors)
                                let prefixArgs :=
                                  psCKernelExprListTake appArgs firstIndex
                                let withPrefix := psCKernelExprMkAppN rhs prefixArgs
                                let ctorParameterCount :=
                                  Nat.sub majorArgs.length rule.nfields
                                let fieldArgs :=
                                  psCKernelExprListDrop majorArgs ctorParameterCount
                                let withFields :=
                                  psCKernelExprMkAppN withPrefix fieldArgs
                                let trailingArgs :=
                                  psCKernelExprListDrop appArgs (Nat.add majorIndex 1)
                                some (psCKernelExprMkAppN withFields trailingArgs)
                              else
                                none
                            else
                              none
                    | _ => none
            | _ => none
        | _ => none
      match natPrimitiveReduced with
      | some reduced => psCKernelExprWhnfBasic env lctx reduced
      | none =>
          match quotientReduced with
          | some reduced => psCKernelExprWhnfBasic env lctx reduced
          | none =>
              match recursorReduced with
              | some reduced => psCKernelExprWhnfBasic env lctx reduced
              | none =>
                  let reducedFn : PsCKernelExpr := psCKernelExprWhnfBasic env lctx fn
                  match reducedFn with
                  | PsCKernelExpr.lam _ _ body _ =>
                      psCKernelExprWhnfBasic
                        env
                        lctx
                        (psCKernelExprInstantiate1 body arg)
                  | _ =>
                      if psCKernelExprEqStructural reducedFn fn then
                        expr
                      else
                        PsCKernelExpr.app reducedFn arg
  | PsCKernelExpr.letE _ _ value body _ =>
      psCKernelExprWhnfBasic
        env
        lctx
        (psCKernelExprInstantiate1 body value)
  | PsCKernelExpr.proj typeName index value =>
      let reducedValue : PsCKernelExpr := psCKernelExprWhnfBasic env lctx value
      match psCKernelExprReduceProjectionCoreBasic? env typeName index reducedValue with
      | some field => psCKernelExprWhnfBasic env lctx field
      | none =>
          if psCKernelExprEqStructural reducedValue value then
            expr
          else
            PsCKernelExpr.proj typeName index reducedValue
  | _ => expr
