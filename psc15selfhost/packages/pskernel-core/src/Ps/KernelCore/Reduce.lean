import Ps.KernelCore.Subst
import Ps.KernelCore.Environment
import Ps.KernelCore.LocalContext
import Ps.KernelCore.Primitive
import Ps.KernelCore.Quot

def psKernelCoreLevelSubstFromLists
    (params : PsKernelCoreList PsKernelCoreName) :
    PsKernelCoreList PsKernelCoreLevel -> PsKernelCoreOption PsKernelCoreLevelSubst :=
  match params with
  | PsKernelCoreList.nil =>
      fun (values : PsKernelCoreList PsKernelCoreLevel) =>
        match values with
        | PsKernelCoreList.nil =>
            PsKernelCoreOption.some PsKernelCoreLevelSubst.nil
        | PsKernelCoreList.cons _ _ => PsKernelCoreOption.none
  | PsKernelCoreList.cons param rest =>
      let buildRest :
          PsKernelCoreList PsKernelCoreLevel ->
          PsKernelCoreOption PsKernelCoreLevelSubst :=
        psKernelCoreLevelSubstFromLists rest;
      fun (values : PsKernelCoreList PsKernelCoreLevel) =>
        match values with
        | PsKernelCoreList.nil => PsKernelCoreOption.none
        | PsKernelCoreList.cons value valueRest =>
            match buildRest valueRest with
            | PsKernelCoreOption.none => PsKernelCoreOption.none
            | PsKernelCoreOption.some tail =>
                PsKernelCoreOption.some
                  (PsKernelCoreLevelSubst.cons param value tail)

def psKernelCoreLevelListInstantiateParams
    (items : PsKernelCoreList PsKernelCoreLevel)
    (subst : PsKernelCoreLevelSubst) : PsKernelCoreList PsKernelCoreLevel :=
  match items with
  | PsKernelCoreList.nil => PsKernelCoreList.nil
  | PsKernelCoreList.cons head rest =>
      PsKernelCoreList.cons
        (psKernelCoreLevelInstantiateParams head subst)
        (psKernelCoreLevelListInstantiateParams rest subst)

def psKernelCoreExprInstantiateLevelSubst
    (expr : PsKernelCoreExpr)
    (subst : PsKernelCoreLevelSubst) : PsKernelCoreExpr :=
  match expr with
  | PsKernelCoreExpr.bvar index => PsKernelCoreExpr.bvar index
  | PsKernelCoreExpr.fvar name => PsKernelCoreExpr.fvar name
  | PsKernelCoreExpr.mvar name => PsKernelCoreExpr.mvar name
  | PsKernelCoreExpr.sort level =>
      PsKernelCoreExpr.sort (psKernelCoreLevelInstantiateParams level subst)
  | PsKernelCoreExpr.const name levels =>
      PsKernelCoreExpr.const name
        (psKernelCoreLevelListInstantiateParams levels subst)
  | PsKernelCoreExpr.app fn arg =>
      PsKernelCoreExpr.app
        (psKernelCoreExprInstantiateLevelSubst fn subst)
        (psKernelCoreExprInstantiateLevelSubst arg subst)
  | PsKernelCoreExpr.lam name type body binderInfo =>
      PsKernelCoreExpr.lam
        name
        (psKernelCoreExprInstantiateLevelSubst type subst)
        (psKernelCoreExprInstantiateLevelSubst body subst)
        binderInfo
  | PsKernelCoreExpr.forallE name type body binderInfo =>
      PsKernelCoreExpr.forallE
        name
        (psKernelCoreExprInstantiateLevelSubst type subst)
        (psKernelCoreExprInstantiateLevelSubst body subst)
        binderInfo
  | PsKernelCoreExpr.letE name type value body nondep =>
      PsKernelCoreExpr.letE
        name
        (psKernelCoreExprInstantiateLevelSubst type subst)
        (psKernelCoreExprInstantiateLevelSubst value subst)
        (psKernelCoreExprInstantiateLevelSubst body subst)
        nondep
  | PsKernelCoreExpr.lit value => PsKernelCoreExpr.lit value
  | PsKernelCoreExpr.mdata metadata body =>
      PsKernelCoreExpr.mdata metadata
        (psKernelCoreExprInstantiateLevelSubst body subst)
  | PsKernelCoreExpr.proj typeName index body =>
      PsKernelCoreExpr.proj typeName index
        (psKernelCoreExprInstantiateLevelSubst body subst)

def psKernelCoreExprInstantiateLevelParams
    (expr : PsKernelCoreExpr)
    (params : PsKernelCoreList PsKernelCoreName)
    (values : PsKernelCoreList PsKernelCoreLevel) :
    PsKernelCoreOption PsKernelCoreExpr :=
  match psKernelCoreLevelSubstFromLists params values with
  | PsKernelCoreOption.none => PsKernelCoreOption.none
  | PsKernelCoreOption.some subst =>
      PsKernelCoreOption.some
        (psKernelCoreExprInstantiateLevelSubst expr subst)

def psKernelCoreIsNatBinaryPrimitiveName
    (name : PsKernelCoreName) : Bool :=
  if psKernelCoreNameEq name psKernelCorePrimitiveNatAddName then
    true
  else if psKernelCoreNameEq name psKernelCorePrimitiveNatSubName then
    true
  else if psKernelCoreNameEq name psKernelCorePrimitiveNatMulName then
    true
  else if psKernelCoreNameEq name psKernelCorePrimitiveNatPowName then
    true
  else if psKernelCoreNameEq name psKernelCorePrimitiveNatGcdName then
    true
  else if psKernelCoreNameEq name psKernelCorePrimitiveNatModName then
    true
  else if psKernelCoreNameEq name psKernelCorePrimitiveNatDivName then
    true
  else if psKernelCoreNameEq name psKernelCorePrimitiveNatBeqName then
    true
  else
    psKernelCoreNameEq name psKernelCorePrimitiveNatBleName

structure PsKernelCoreAppView where
  fn : PsKernelCoreExpr
  args : PsKernelCoreList PsKernelCoreExpr

def psKernelCoreCollectAppView
    (expr : PsKernelCoreExpr) :
    PsKernelCoreList PsKernelCoreExpr -> PsKernelCoreAppView :=
  match expr with
  | PsKernelCoreExpr.app fn arg =>
      let collectFn :
          PsKernelCoreList PsKernelCoreExpr -> PsKernelCoreAppView :=
        psKernelCoreCollectAppView fn;
      fun (args : PsKernelCoreList PsKernelCoreExpr) =>
        collectFn (PsKernelCoreList.cons arg args)
  | _ =>
      fun (args : PsKernelCoreList PsKernelCoreExpr) =>
        PsKernelCoreAppView.mk expr args

def psKernelCoreAppViewOf (expr : PsKernelCoreExpr) : PsKernelCoreAppView :=
  psKernelCoreCollectAppView expr PsKernelCoreList.nil

def psKernelCoreExprListSize
    (items : PsKernelCoreList PsKernelCoreExpr) : Nat :=
  match items with
  | PsKernelCoreList.nil => Nat.zero
  | PsKernelCoreList.cons _ rest =>
      Nat.succ (psKernelCoreExprListSize rest)

def psKernelCoreExprListGet?
    (items : PsKernelCoreList PsKernelCoreExpr) :
    Nat -> PsKernelCoreOption PsKernelCoreExpr :=
  match items with
  | PsKernelCoreList.nil =>
      fun (_index : Nat) => PsKernelCoreOption.none
  | PsKernelCoreList.cons head rest =>
      let getRest : Nat -> PsKernelCoreOption PsKernelCoreExpr :=
        psKernelCoreExprListGet? rest;
      fun (index : Nat) =>
        match index with
        | Nat.zero => PsKernelCoreOption.some head
        | Nat.succ previous => getRest previous

def psKernelCoreReduceLevelListSize
    (items : PsKernelCoreList PsKernelCoreLevel) : Nat :=
  match items with
  | PsKernelCoreList.nil => 0
  | PsKernelCoreList.cons _ rest =>
      Nat.succ (psKernelCoreReduceLevelListSize rest)

def psKernelCoreReduceNameListSize
    (items : PsKernelCoreList PsKernelCoreName) : Nat :=
  match items with
  | PsKernelCoreList.nil => 0
  | PsKernelCoreList.cons _ rest =>
      Nat.succ (psKernelCoreReduceNameListSize rest)

def psKernelCoreReduceExprListTake
    (count : Nat) :
    PsKernelCoreList PsKernelCoreExpr -> PsKernelCoreList PsKernelCoreExpr :=
  match count with
  | Nat.zero =>
      fun (_items : PsKernelCoreList PsKernelCoreExpr) => PsKernelCoreList.nil
  | Nat.succ remaining =>
      let takeRemaining := psKernelCoreReduceExprListTake remaining;
      fun (items : PsKernelCoreList PsKernelCoreExpr) =>
        match items with
        | PsKernelCoreList.nil => PsKernelCoreList.nil
        | PsKernelCoreList.cons head rest =>
            PsKernelCoreList.cons head (takeRemaining rest)

def psKernelCoreReduceExprListDrop
    (count : Nat) :
    PsKernelCoreList PsKernelCoreExpr -> PsKernelCoreList PsKernelCoreExpr :=
  match count with
  | Nat.zero =>
      fun (items : PsKernelCoreList PsKernelCoreExpr) => items
  | Nat.succ remaining =>
      let dropRemaining := psKernelCoreReduceExprListDrop remaining;
      fun (items : PsKernelCoreList PsKernelCoreExpr) =>
        match items with
        | PsKernelCoreList.nil => PsKernelCoreList.nil
        | PsKernelCoreList.cons _ rest => dropRemaining rest

def psKernelCoreExprApplyList
    (args : PsKernelCoreList PsKernelCoreExpr) : PsKernelCoreExpr -> PsKernelCoreExpr :=
  match args with
  | PsKernelCoreList.nil =>
      fun (fn : PsKernelCoreExpr) => fn
  | PsKernelCoreList.cons arg rest =>
      let applyRest := psKernelCoreExprApplyList rest;
      fun (fn : PsKernelCoreExpr) =>
        applyRest (PsKernelCoreExpr.app fn arg)

def psKernelCoreReduceRecursorMajorIndex
    (info : PsKernelCoreRecursorInfo) : Nat :=
  Nat.add
    (Nat.add
      (Nat.add info.numParams info.numMotives)
      info.numMinors)
    info.numIndices

def psKernelCoreReduceFindRecursorRule?
    (rules : PsKernelCoreList PsKernelCoreRecursorRule) :
    PsKernelCoreName -> PsKernelCoreOption PsKernelCoreRecursorRule :=
  match rules with
  | PsKernelCoreList.nil =>
      fun (_ctor : PsKernelCoreName) => PsKernelCoreOption.none
  | PsKernelCoreList.cons rule rest =>
      let findRest := psKernelCoreReduceFindRecursorRule? rest;
      fun (ctor : PsKernelCoreName) =>
        if psKernelCoreNameEq rule.ctor ctor then
          PsKernelCoreOption.some rule
        else
          findRest ctor

def psKernelCoreReduceRecursorTarget?
    (info : PsKernelCoreRecursorInfo) : PsKernelCoreOption PsKernelCoreName :=
  match info.all with
  | PsKernelCoreList.nil => PsKernelCoreOption.none
  | PsKernelCoreList.cons target rest =>
      match rest with
      | PsKernelCoreList.nil => PsKernelCoreOption.some target
      | PsKernelCoreList.cons _ _ => PsKernelCoreOption.none

def psKernelCoreReduceRecursorPrefixInfo?
    (env : PsKernelCoreEnvironment)
    (expr : PsKernelCoreExpr) : PsKernelCoreOption PsKernelCoreRecursorInfo :=
  let view := psKernelCoreAppViewOf expr;
  match view.fn with
  | PsKernelCoreExpr.const name levels =>
      match psKernelCoreEnvironmentFind? env name with
      | PsKernelCoreOption.some (PsKernelCoreConstantInfo.recInfo info) =>
          if info.k then
            PsKernelCoreOption.none
          else if Nat.beq
              (psKernelCoreExprListSize view.args)
              (psKernelCoreReduceRecursorMajorIndex info) then
            if Nat.beq
                (psKernelCoreReduceLevelListSize levels)
                (psKernelCoreReduceNameListSize info.base.levelParams) then
              PsKernelCoreOption.some info
            else
              PsKernelCoreOption.none
          else
            PsKernelCoreOption.none
      | _ => PsKernelCoreOption.none
  | _ => PsKernelCoreOption.none

def psKernelCoreReduceRecursorMajor?
    (env : PsKernelCoreEnvironment)
    (prefixExpr : PsKernelCoreExpr)
    (major : PsKernelCoreExpr) : PsKernelCoreOption PsKernelCoreExpr :=
  match psKernelCoreReduceRecursorPrefixInfo? env prefixExpr with
  | PsKernelCoreOption.none => PsKernelCoreOption.none
  | PsKernelCoreOption.some info =>
      let prefixView := psKernelCoreAppViewOf prefixExpr;
      let majorView := psKernelCoreAppViewOf major;
      match majorView.fn with
      | PsKernelCoreExpr.const ctorName _ =>
          match psKernelCoreReduceFindRecursorRule? info.rules ctorName with
          | PsKernelCoreOption.none => PsKernelCoreOption.none
          | PsKernelCoreOption.some rule =>
              match psKernelCoreReduceRecursorTarget? info with
              | PsKernelCoreOption.none => PsKernelCoreOption.none
              | PsKernelCoreOption.some target =>
                  match psKernelCoreEnvironmentFind? env ctorName with
                  | PsKernelCoreOption.some
                      (PsKernelCoreConstantInfo.ctorInfo ctor) =>
                      if psKernelCoreNameEq ctor.induct target then
                        let majorCount := psKernelCoreExprListSize majorView.args;
                        if Nat.ble rule.nFields majorCount then
                          match prefixView.fn with
                          | PsKernelCoreExpr.const _ recLevels =>
                              match psKernelCoreExprInstantiateLevelParams
                                  rule.rhs info.base.levelParams recLevels with
                              | PsKernelCoreOption.none => PsKernelCoreOption.none
                              | PsKernelCoreOption.some rhs0 =>
                                  let fixedCount :=
                                    Nat.add
                                      (Nat.add info.numParams info.numMotives)
                                      info.numMinors;
                                  let fixedArgs :=
                                    psKernelCoreReduceExprListTake fixedCount prefixView.args;
                                  let fieldStart := Nat.sub majorCount rule.nFields;
                                  let fields :=
                                    psKernelCoreReduceExprListTake rule.nFields
                                      (psKernelCoreReduceExprListDrop fieldStart majorView.args);
                                  let rhs1 := psKernelCoreExprApplyList fixedArgs rhs0;
                                  PsKernelCoreOption.some
                                    (psKernelCoreExprApplyList fields rhs1)
                          | _ => PsKernelCoreOption.none
                        else
                          PsKernelCoreOption.none
                      else
                        PsKernelCoreOption.none
                  | _ => PsKernelCoreOption.none
      | _ => PsKernelCoreOption.none

def psKernelCoreQuotFunctionFromPrefix?
    (env : PsKernelCoreEnvironment)
    (expr : PsKernelCoreExpr) : PsKernelCoreOption PsKernelCoreExpr :=
  if env.quotInitialized then
    let view := psKernelCoreAppViewOf expr;
    match view.fn with
    | PsKernelCoreExpr.const name _ =>
        if psKernelCoreNameEq name psKernelCoreQuotLiftName then
          if Nat.beq (psKernelCoreExprListSize view.args) 5 then
            psKernelCoreExprListGet? view.args 3
          else
            PsKernelCoreOption.none
        else if psKernelCoreNameEq name psKernelCoreQuotIndName then
          if Nat.beq (psKernelCoreExprListSize view.args) 4 then
            psKernelCoreExprListGet? view.args 3
          else
            PsKernelCoreOption.none
        else
          PsKernelCoreOption.none
    | _ => PsKernelCoreOption.none
  else
    PsKernelCoreOption.none

def psKernelCoreQuotRepresentative?
    (expr : PsKernelCoreExpr) : PsKernelCoreOption PsKernelCoreExpr :=
  let view := psKernelCoreAppViewOf expr;
  match view.fn with
  | PsKernelCoreExpr.const name _ =>
      if psKernelCoreNameEq name psKernelCoreQuotMkName then
        if Nat.beq (psKernelCoreExprListSize view.args) 3 then
          psKernelCoreExprListGet? view.args 2
        else
          PsKernelCoreOption.none
      else
        PsKernelCoreOption.none
  | _ => PsKernelCoreOption.none

def psKernelCoreWhnfWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig) :
    PsKernelCoreEnvironment ->
    PsKernelCoreLocalContext ->
    PsKernelCoreExpr ->
    PsKernelCoreResult String PsKernelCoreExpr :=
  match budget with
  | Nat.zero =>
      fun (_env : PsKernelCoreEnvironment)
          (_lctx : PsKernelCoreLocalContext)
          (_expr : PsKernelCoreExpr) =>
        PsKernelCoreResult.error "reduction budget exhausted"
  | Nat.succ remaining =>
      let smaller :
          PsKernelCoreEnvironment ->
          PsKernelCoreLocalContext ->
          PsKernelCoreExpr ->
          PsKernelCoreResult String PsKernelCoreExpr :=
        psKernelCoreWhnfWithResources remaining resources;
      fun (env : PsKernelCoreEnvironment)
          (lctx : PsKernelCoreLocalContext)
          (expr : PsKernelCoreExpr) =>
        match expr with
        | PsKernelCoreExpr.mdata _ body =>
            smaller env lctx body
        | PsKernelCoreExpr.fvar name =>
            match psKernelCoreLocalContextFind? lctx name with
            | PsKernelCoreOption.none => PsKernelCoreResult.ok expr
            | PsKernelCoreOption.some decl =>
                match psKernelCoreLocalDeclValue? decl with
                | PsKernelCoreOption.none => PsKernelCoreResult.ok expr
                | PsKernelCoreOption.some value => smaller env lctx value
        | PsKernelCoreExpr.letE _ _ value body _ =>
            smaller env lctx (psKernelCoreExprInstantiate1 body value)
        | PsKernelCoreExpr.app fn arg =>
            match smaller env lctx fn with
            | PsKernelCoreResult.error message =>
                PsKernelCoreResult.error message
            | PsKernelCoreResult.ok reducedFn =>
                let ordinary : Unit -> PsKernelCoreResult String PsKernelCoreExpr :=
                  fun (_unused : Unit) =>
                    match reducedFn with
                    | PsKernelCoreExpr.lam _ _ body _ =>
                        smaller env lctx
                          (psKernelCoreExprInstantiate1 body arg)
                    | PsKernelCoreExpr.const operation levels =>
                        match levels with
                        | PsKernelCoreList.nil =>
                            if psKernelCoreNameEq
                                operation psKernelCorePrimitiveNatSuccName then
                              match smaller env lctx arg with
                              | PsKernelCoreResult.error message =>
                                  PsKernelCoreResult.error message
                              | PsKernelCoreResult.ok reducedArg =>
                                  match psKernelCoreNatLiteralValue? reducedArg with
                                  | PsKernelCoreOption.none =>
                                      PsKernelCoreResult.ok
                                        (PsKernelCoreExpr.app reducedFn reducedArg)
                                  | PsKernelCoreOption.some value =>
                                      match psKernelCoreReduceNatUnary
                                          resources operation value with
                                      | PsKernelCoreResult.error message =>
                                          PsKernelCoreResult.error message
                                      | PsKernelCoreResult.ok primitiveResult =>
                                          match primitiveResult with
                                          | PsKernelCoreOption.none =>
                                              PsKernelCoreResult.ok
                                                (PsKernelCoreExpr.app reducedFn reducedArg)
                                          | PsKernelCoreOption.some result =>
                                              PsKernelCoreResult.ok result
                            else
                              PsKernelCoreResult.ok
                                (PsKernelCoreExpr.app reducedFn arg)
                        | PsKernelCoreList.cons _ _ =>
                            PsKernelCoreResult.ok
                              (PsKernelCoreExpr.app reducedFn arg)
                    | PsKernelCoreExpr.app binaryFn leftArg =>
                        match binaryFn with
                        | PsKernelCoreExpr.const operation levels =>
                            match levels with
                            | PsKernelCoreList.nil =>
                                if psKernelCoreIsNatBinaryPrimitiveName operation then
                                  match smaller env lctx leftArg with
                                  | PsKernelCoreResult.error message =>
                                      PsKernelCoreResult.error message
                                  | PsKernelCoreResult.ok reducedLeft =>
                                      match smaller env lctx arg with
                                      | PsKernelCoreResult.error message =>
                                          PsKernelCoreResult.error message
                                      | PsKernelCoreResult.ok reducedRight =>
                                          match psKernelCoreNatLiteralValue? reducedLeft with
                                          | PsKernelCoreOption.none =>
                                              PsKernelCoreResult.ok
                                                (PsKernelCoreExpr.app
                                                  (PsKernelCoreExpr.app
                                                    binaryFn reducedLeft)
                                                  reducedRight)
                                          | PsKernelCoreOption.some leftValue =>
                                              match psKernelCoreNatLiteralValue? reducedRight with
                                              | PsKernelCoreOption.none =>
                                                  PsKernelCoreResult.ok
                                                    (PsKernelCoreExpr.app
                                                      (PsKernelCoreExpr.app
                                                        binaryFn reducedLeft)
                                                      reducedRight)
                                              | PsKernelCoreOption.some rightValue =>
                                                  match psKernelCoreReduceNatBinary
                                                      resources operation leftValue rightValue with
                                                  | PsKernelCoreResult.error message =>
                                                      PsKernelCoreResult.error message
                                                  | PsKernelCoreResult.ok primitiveResult =>
                                                      match primitiveResult with
                                                      | PsKernelCoreOption.none =>
                                                          PsKernelCoreResult.ok
                                                            (PsKernelCoreExpr.app
                                                              (PsKernelCoreExpr.app
                                                                binaryFn reducedLeft)
                                                              reducedRight)
                                                      | PsKernelCoreOption.some result =>
                                                          PsKernelCoreResult.ok result
                                else
                                  PsKernelCoreResult.ok
                                    (PsKernelCoreExpr.app reducedFn arg)
                            | PsKernelCoreList.cons _ _ =>
                                PsKernelCoreResult.ok
                                  (PsKernelCoreExpr.app reducedFn arg)
                        | _ =>
                            PsKernelCoreResult.ok
                              (PsKernelCoreExpr.app reducedFn arg)
                    | _ =>
                        PsKernelCoreResult.ok
                          (PsKernelCoreExpr.app reducedFn arg);
                match psKernelCoreQuotFunctionFromPrefix? env reducedFn with
                | PsKernelCoreOption.some quotientFn =>
                    match smaller env lctx arg with
                    | PsKernelCoreResult.error message =>
                        PsKernelCoreResult.error message
                    | PsKernelCoreResult.ok reducedMajor =>
                        match psKernelCoreQuotRepresentative? reducedMajor with
                        | PsKernelCoreOption.none => ordinary Unit.unit
                        | PsKernelCoreOption.some representative =>
                            smaller env lctx
                              (PsKernelCoreExpr.app quotientFn representative)
                | PsKernelCoreOption.none =>
                    match psKernelCoreReduceRecursorPrefixInfo? env reducedFn with
                    | PsKernelCoreOption.none => ordinary Unit.unit
                    | PsKernelCoreOption.some _ =>
                        match smaller env lctx arg with
                        | PsKernelCoreResult.error message =>
                            PsKernelCoreResult.error message
                        | PsKernelCoreResult.ok reducedMajor =>
                            match psKernelCoreReduceRecursorMajor?
                                env reducedFn reducedMajor with
                            | PsKernelCoreOption.none => ordinary Unit.unit
                            | PsKernelCoreOption.some reduced =>
                                smaller env lctx reduced
        | PsKernelCoreExpr.const name levels =>
            match psKernelCoreEnvironmentFind? env name with
            | PsKernelCoreOption.none => PsKernelCoreResult.ok expr
            | PsKernelCoreOption.some info =>
                match psKernelCoreConstantInfoDeltaValue? info with
                | PsKernelCoreOption.none => PsKernelCoreResult.ok expr
                | PsKernelCoreOption.some value =>
                    match psKernelCoreExprInstantiateLevelParams
                        value
                        (psKernelCoreConstantInfoLevelParams info)
                        levels with
                    | PsKernelCoreOption.none => PsKernelCoreResult.ok expr
                    | PsKernelCoreOption.some unfolded =>
                        smaller env lctx unfolded
        | _ => PsKernelCoreResult.ok expr

def psKernelCoreWhnf
    (budget : Nat) :
    PsKernelCoreEnvironment ->
    PsKernelCoreLocalContext ->
    PsKernelCoreExpr ->
    PsKernelCoreResult String PsKernelCoreExpr :=
  psKernelCoreWhnfWithResources budget psKernelCoreResourceConfigDefault