import Ps.KernelCore.Checker.ExprV2.CheckWhnf
import Ps.KernelCore.Checker.ExprV2.String

/- Final DefEq rules over the owning DAG, in the reference order:
structure eta (both orientations), string-literal expansion (both
orientations), then unit-like equality. Callbacks retain the owning
predecessor fuel. These helpers never publish an original success pair. -/
def psKernelExprV2DefEqEtaStructFieldsWithFuel
    (fuel : Nat) :
    (PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool))) ->
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
    PsKernelName -> Nat -> List Nat -> Nat -> Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match fuel with
  | Nat.zero =>
      fun (_defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
          (_context : PsKernelExprV2CheckContext) (_state : PsKernelExprV2CheckState)
          (_induct : PsKernelName) (_term : Nat) (_args : List Nat)
          (_numParams _index : Nat) =>
        Option.some (Except.error "kernel structure eta budget exhausted")
  | Nat.succ remaining =>
      fun (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
          (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
          (induct : PsKernelName) (term : Nat) (args : List Nat)
          (numParams index : Nat) =>
        let fieldCount := Nat.sub (psKernelExprV2TransformNatLength args) numParams;
        if psKernelNatLt index fieldCount then
          match psKernelExprV2TransformNatGet args (Nat.add numParams index) with
          | Option.none => Option.some (Except.ok (Prod.mk state false))
          | Option.some arg =>
              match psKernelExprV2PagedMkProj state.whnf.arena induct index term with
              | Except.error error => Option.some (Except.error error)
              | Except.ok projection =>
                  match defeq context
                      (psKernelExprV2CheckStateWithArena state (Prod.fst projection))
                      (Prod.snd projection) arg with
                  | Option.none => Option.none
                  | Option.some attempted =>
                      match attempted with
                      | Except.error error => Option.some (Except.error error)
                      | Except.ok compared =>
                          if Prod.snd compared then
                            let recur := psKernelExprV2DefEqEtaStructFieldsWithFuel remaining;
                            recur defeq context (Prod.fst compared)
                              induct term args numParams (Nat.succ index)
                          else Option.some (Except.ok compared)
        else Option.some (Except.ok (Prod.mk state true))

def psKernelExprV2DefEqEtaStructConstructor
    (context : PsKernelExprV2CheckContext) (arena : PsKernelExprV2PagedArena)
    (root : Nat) : Except String (Option (Prod PsKernelConstructorInfo (List Nat))) :=
  match psKernelExprV2TransformAppSpineOnCanonical arena root with
  | Except.error error => Except.error error
  | Except.ok spine =>
      match psKernelExprV2PagedRequire arena (Prod.fst spine) with
      | Except.error error => Except.error error
      | Except.ok head =>
          match head.node with
          | PsKernelExprV2Node.const ctorName _ =>
              match psKernelEnvironmentFind context.scalar.environment ctorName with
              | Option.none => Except.ok Option.none
              | Option.some info =>
                  match info with
                  | PsKernelConstantInfo.ctorInfo ctor =>
                      if Nat.beq (psKernelExprV2TransformNatLength (Prod.snd spine))
                          (Nat.add ctor.numParams ctor.numFields) then
                        if psKernelEnvironmentIsNonRecStructure context.scalar.environment ctor.induct then
                          Except.ok (Option.some (Prod.mk ctor (Prod.snd spine)))
                        else Except.ok Option.none
                      else Except.ok Option.none
                  | _ => Except.ok Option.none
          | _ => Except.ok Option.none

def psKernelExprV2DefEqEtaStructCoreWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (term structureValue : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match psKernelExprV2DefEqEtaStructConstructor context state.whnf.arena structureValue with
  | Except.error error => Option.some (Except.error error)
  | Except.ok found =>
      match found with
      | Option.none => Option.some (Except.ok (Prod.mk state false))
      | Option.some view =>
          let ctor := Prod.fst view;
          match inferType context state term with
          | Option.none => Option.none
          | Option.some attemptedTerm =>
              match attemptedTerm with
              | Except.error error => Option.some (Except.error error)
              | Except.ok termType =>
                  match inferType context (Prod.fst termType) structureValue with
                  | Option.none => Option.none
                  | Option.some attemptedStructure =>
                      match attemptedStructure with
                      | Except.error error => Option.some (Except.error error)
                      | Except.ok structureType =>
                          match defeq context (Prod.fst structureType)
                              (Prod.snd termType) (Prod.snd structureType) with
                          | Option.none => Option.none
                          | Option.some attemptedTypes =>
                              match attemptedTypes with
                              | Except.error error => Option.some (Except.error error)
                              | Except.ok compared =>
                                  if Prod.snd compared then
                                    psKernelExprV2DefEqEtaStructFieldsWithFuel
                                      (Nat.succ ctor.numFields) defeq context (Prod.fst compared)
                                      ctor.induct term (Prod.snd view) ctor.numParams 0
                                  else Option.some (Except.ok compared)

def psKernelExprV2DefEqEtaStructWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match psKernelExprV2DefEqEtaStructCoreWith defeq inferType context state left right with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok first =>
          if Prod.snd first then Option.some (Except.ok first)
          else psKernelExprV2DefEqEtaStructCoreWith
            defeq inferType context (Prod.fst first) right left

def psKernelExprV2DefEqStringLitExpansionCoreWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Bool))) :=
  match psKernelExprV2PagedRequire state.whnf.arena left with
  | Except.error error => Option.some (Except.error error)
  | Except.ok leftEntry =>
      match leftEntry.node with
      | PsKernelExprV2Node.lit literal =>
          match literal with
          | PsKernelLiteral.str value =>
              match psKernelExprV2IsStringOfListAppOnCanonical state.whnf.arena right with
              | Except.error error => Option.some (Except.error error)
              | Except.ok isStringOfList =>
                  if isStringOfList then
                    match psKernelExprV2StringLitToConstructorOnCanonical state.whnf.arena value with
                    | Except.error error => Option.some (Except.error error)
                    | Except.ok builtConstructor =>
                        let afterBuild :=
                          psKernelExprV2CheckStateWithArena state (Prod.fst builtConstructor);
                        match whnf context afterBuild.whnf (Prod.snd builtConstructor) with
                        | Option.none => Option.none
                        | Option.some attemptedWhnf =>
                            match attemptedWhnf with
                            | Except.error error => Option.some (Except.error error)
                            | Except.ok expanded =>
                                match defeq context
                                    (psKernelExprV2CheckStateWithWhnf afterBuild (Prod.fst expanded))
                                    (Prod.snd expanded) right with
                                | Option.none => Option.none
                                | Option.some attemptedDefEq =>
                                    match attemptedDefEq with
                                    | Except.error error => Option.some (Except.error error)
                                    | Except.ok compared =>
                                        Option.some (Except.ok
                                          (Prod.mk (Prod.fst compared) (Option.some (Prod.snd compared))))
                  else Option.some (Except.ok (Prod.mk state Option.none))
          | PsKernelLiteral.nat _ => Option.some (Except.ok (Prod.mk state Option.none))
      | _ => Option.some (Except.ok (Prod.mk state Option.none))

def psKernelExprV2DefEqStringLitExpansionWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Bool))) :=
  match psKernelExprV2DefEqStringLitExpansionCoreWith defeq whnf context state left right with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok first =>
          match Prod.snd first with
          | Option.some _ => Option.some (Except.ok first)
          | Option.none =>
              psKernelExprV2DefEqStringLitExpansionCoreWith
                defeq whnf context (Prod.fst first) right left

def psKernelExprV2DefEqIsUnitLikeTypeOnCanonical
    (context : PsKernelExprV2CheckContext) (arena : PsKernelExprV2PagedArena)
    (root : Nat) : Except String Bool :=
  match psKernelExprV2TransformAppSpineOnCanonical arena root with
  | Except.error error => Except.error error
  | Except.ok spine =>
      match psKernelExprV2PagedRequire arena (Prod.fst spine) with
      | Except.error error => Except.error error
      | Except.ok head =>
          match head.node with
          | PsKernelExprV2Node.const inductName _ =>
              if psKernelEnvironmentIsNonRecStructure context.scalar.environment inductName then
                match psKernelEnvironmentFind context.scalar.environment inductName with
                | Option.none => Except.ok false
                | Option.some info =>
                    match info with
                    | PsKernelConstantInfo.inductInfo induct =>
                        match induct.ctors with
                        | List.nil => Except.ok false
                        | List.cons ctorName rest =>
                            match rest with
                            | List.cons _ _ => Except.ok false
                            | List.nil =>
                                match psKernelEnvironmentFind context.scalar.environment ctorName with
                                | Option.none => Except.ok false
                                | Option.some value =>
                                    match value with
                                    | PsKernelConstantInfo.ctorInfo ctor =>
                                        Except.ok (Nat.beq ctor.numFields 0)
                                    | _ => Except.ok false
                    | _ => Except.ok false
              else Except.ok false
          | _ => Except.ok false

def psKernelExprV2DefEqUnitLikeWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match inferType context state left with
  | Option.none => Option.none
  | Option.some attemptedLeft =>
      match attemptedLeft with
      | Except.error error => Option.some (Except.error error)
      | Except.ok leftType =>
          let afterLeft := Prod.fst leftType;
          match whnf context afterLeft.whnf (Prod.snd leftType) with
          | Option.none => Option.none
          | Option.some attemptedWhnf =>
              match attemptedWhnf with
              | Except.error error => Option.some (Except.error error)
              | Except.ok reduced =>
                  let next := psKernelExprV2CheckStateWithWhnf (Prod.fst leftType) (Prod.fst reduced);
                  match psKernelExprV2DefEqIsUnitLikeTypeOnCanonical
                      context next.whnf.arena (Prod.snd reduced) with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok isUnit =>
                      if isUnit then
                        match inferType context next right with
                        | Option.none => Option.none
                        | Option.some attemptedRight =>
                            match attemptedRight with
                            | Except.error error => Option.some (Except.error error)
                            | Except.ok rightType =>
                                defeq context (Prod.fst rightType)
                                  (Prod.snd reduced) (Prod.snd rightType)
                      else Option.some (Except.ok (Prod.mk next false))

def psKernelExprV2DefEqFinalRulesWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match psKernelExprV2DefEqEtaStructWith defeq inferType context state left right with
  | Option.none => Option.none
  | Option.some attemptedEta =>
      match attemptedEta with
      | Except.error error => Option.some (Except.error error)
      | Except.ok eta =>
          if Prod.snd eta then Option.some (Except.ok eta)
          else
            match psKernelExprV2DefEqStringLitExpansionWith
                defeq whnf context (Prod.fst eta) left right with
            | Option.none => Option.none
            | Option.some attemptedString =>
                match attemptedString with
                | Except.error error => Option.some (Except.error error)
                | Except.ok expanded =>
                    match Prod.snd expanded with
                    | Option.some value =>
                        Option.some (Except.ok (Prod.mk (Prod.fst expanded) value))
                    | Option.none =>
                        psKernelExprV2DefEqUnitLikeWith
                          defeq inferType whnf context (Prod.fst expanded) left right
