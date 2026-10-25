import Ps.KernelCore.API.DagDeclaration
import Ps.KernelCore.Admission.Quot.Admission

/- Match only the fixed Eq bootstrap patterns. Recursion follows the bounded
   expected pattern; input types are read by ID without expanded-tree traversal.
   Binder names/info are erased exactly as psKernelExprEq. Metadata is not erased.
   Missing owner/child declines. This is an internal canonical-owner worker. -/
def psKernelDagQuotMatchShape
    (expected : PsKernelExpr) :
    PsKernelExprV2PagedArena -> Nat -> Option Bool :=
  match expected with
  | PsKernelExpr.bvar index =>
      fun (arena : PsKernelExprV2PagedArena) (root : Nat) =>
        match psKernelExprV2PagedFind arena root with
        | Option.none => Option.none
        | Option.some entry =>
            match entry.node with
            | PsKernelExprV2Node.bvar actual => Option.some (Nat.beq actual index)
            | _ => Option.some false
  | PsKernelExpr.sort level =>
      fun (arena : PsKernelExprV2PagedArena) (root : Nat) =>
        match psKernelExprV2PagedFind arena root with
        | Option.none => Option.none
        | Option.some entry =>
            match entry.node with
            | PsKernelExprV2Node.sort actual => Option.some (psKernelLevelEq actual level)
            | _ => Option.some false
  | PsKernelExpr.const name levels =>
      fun (arena : PsKernelExprV2PagedArena) (root : Nat) =>
        match psKernelExprV2PagedFind arena root with
        | Option.none => Option.none
        | Option.some entry =>
            match entry.node with
            | PsKernelExprV2Node.const actual actualLevels => Option.some (if psKernelNameEq actual name then psKernelLevelListEq actualLevels levels else false)
            | _ => Option.some false
  | PsKernelExpr.app fn arg =>
      fun (arena : PsKernelExprV2PagedArena) (root : Nat) =>
        match psKernelExprV2PagedFind arena root with
        | Option.none => Option.none
        | Option.some entry =>
            match entry.node with
            | PsKernelExprV2Node.app actualFn actualArg =>
                match psKernelDagQuotMatchShape fn arena actualFn with
                | Option.none => Option.none
                | Option.some equal =>
                    if equal then psKernelDagQuotMatchShape arg arena actualArg
                    else Option.some false
            | _ => Option.some false
  | PsKernelExpr.forallE _ domain body _ =>
      fun (arena : PsKernelExprV2PagedArena) (root : Nat) =>
        match psKernelExprV2PagedFind arena root with
        | Option.none => Option.none
        | Option.some entry =>
            match entry.node with
            | PsKernelExprV2Node.forallE _ actualDomain actualBody _ =>
                match psKernelDagQuotMatchShape domain arena actualDomain with
                | Option.none => Option.none
                | Option.some equal =>
                    if equal then psKernelDagQuotMatchShape body arena actualBody
                    else Option.some false
            | _ => Option.some false
  | _ =>
      fun (_arena : PsKernelExprV2PagedArena) (_root : Nat) => Option.some false

/- Only private references derived in this immutable batch/session are used.
   Live environment kind and universe arity remain authoritative. -/
def psKernelDagQuotMatchInfo
    (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef)
    (info : PsKernelConstantInfo) (expected : PsKernelExpr) : Option Bool :=
  match psKernelExprV2DeclarationRefFind declarations (psKernelConstantInfoName info) with
  | Option.none => Option.none
  | Option.some owner =>
      if psKernelExprV2DeclarationRefMatches owner info then
        psKernelDagQuotMatchShape expected arena owner.type
      else Option.none

def psKernelDagCheckEqForQuot
    (environment : PsKernelEnvironment) (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef) :
    Option (Except String Unit) :=
  match psKernelEnvironmentFind environment psKernelEqName with
  | Option.none => Option.some (Except.error
      "failed to initialize quot module, environment does not have Eq type")
  | Option.some eqValue =>
      match eqValue with
      | PsKernelConstantInfo.inductInfo eqInfo =>
          match eqInfo.base.levelParams with
          | List.cons universeName List.nil =>
              match eqInfo.ctors with
              | List.cons reflName List.nil =>
                  match psKernelDagQuotMatchInfo arena declarations eqValue
                      (psKernelExpectedEqType universeName) with
                  | Option.none => Option.none
                  | Option.some equal =>
                      if equal then
                        match psKernelEnvironmentFind environment reflName with
                        | Option.none => Option.some (Except.error
                            "failed to initialize quot module, missing Eq constructor")
                        | Option.some reflInfo =>
                            match psKernelConstantInfoLevelParams reflInfo with
                            | List.cons reflUniverse List.nil =>
                                match psKernelDagQuotMatchInfo arena declarations reflInfo
                                    (psKernelExpectedEqReflType reflUniverse) with
                                | Option.none => Option.none
                                | Option.some reflEqual =>
                                    if reflEqual then Option.some (Except.ok Unit.unit)
                                    else Option.some (Except.error
                                      "failed to initialize quot module, unexpected type for Eq constructor")
                            | _ => Option.some (Except.error
                                "failed to initialize quot module, unexpected universe params at Eq constructor")
                      else Option.some (Except.error
                        "failed to initialize quot module, Eq has an unexpected type")
              | _ => Option.some (Except.error
                  "failed to initialize quot module, unexpected number of constructors for Eq type")
          | _ => Option.some (Except.error
              "failed to initialize quot module, unexpected number of universe params at Eq type")
      | _ => Option.some (Except.error
          "failed to initialize quot module, environment does not have Eq type")

def psKernelDagTryAdmitQuot
    (environment : PsKernelEnvironment) (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef) :
    Option (Except String PsKernelEnvironment) :=
  if environment.quotInitialized then Option.some (Except.ok environment)
  else
    match psKernelDagCheckEqForQuot environment arena declarations with
    | Option.none => Option.none
    | Option.some attempted =>
        match attempted with
        | Except.error error => Option.some (Except.error error)
        | Except.ok _ => Option.some (psKernelInstallCheckedQuot environment)
