import Ps.KernelCore.API.Kernel
import Ps.KernelCore.API.DagDeclaration

/-
Explicit transitional ownership bridge for checked inductive and Quot metadata.

Complete inductive admission first constructs and validates the recursor type
and every rule in the private work environment. Only after that admission
succeeds may this bridge copy that checked generated metadata into the owning
batch arena. No exported recursor body, caller-provided rule or supplied cache
is accepted as authoritative metadata.

This import is performed once per successful ordinary, mutual or nested inductive
in a batch, not inside WHNF. Only the newly admitted final-environment prefix is
visited; the previous checked environment is the exact name boundary. It preserves original IDs by appending smart-constructed
nodes, and appends the corresponding source expressions to the decoded table.
It deliberately remains a recursive-expression import: inductive admission is
still the V1 fallback, not a completed DAG-native admission path.
Repeated source subtrees are not interned by this bridge. Its construction and
retained-memory costs must be included in whole-batch measurements.

Successful Quot admission separately plans all four checked live names and kinds
before importing any header. Repeated explicit Quot commands elide import only
when all four private owners retain the exact admitted types and no delta body.
This bounded four-name route does not traverse the previous environment tail.

The caller publishes the extended owner only after this entire step succeeds.
All state remains private to RunDag; a later batch error publishes no session.
No checker fuel, depth limit or admission check is changed here.
-/

structure PsKernelDagGeneratedState where
  arena : PsKernelExprV2PagedArena
  built : PsKernelExprV2Decoded
  declarations : List PsKernelExprV2DeclarationRef

def psKernelDagGeneratedFinish
    (source : PsKernelExpr) (state : PsKernelDagGeneratedState)
    (attempt : Except String (Prod PsKernelExprV2PagedArena Nat)) :
    Except String (Prod PsKernelDagGeneratedState Nat) :=
  match attempt with
  | Except.error error => Except.error error
  | Except.ok result =>
      let arena := Prod.fst result;
      let root := Prod.snd result;
      if Nat.beq root state.built.size then
        if Nat.beq arena.size (Nat.succ state.built.size) then
          Except.ok (Prod.mk
            (PsKernelDagGeneratedState.mk arena
              (psKernelExprV2DecodedPush state.built source) state.declarations) root)
        else Except.error "PSKERNEL_V2_GENERATED_OWNER_MISMATCH"
      else Except.error "PSKERNEL_V2_GENERATED_OWNER_MISMATCH"

/- Structural recursion over already checked kernel-generated metadata.
   There is no expanded-node fuel prepass or recursively prebuilt closure. -/
def psKernelDagGeneratedImport
    (source : PsKernelExpr) (state : PsKernelDagGeneratedState) :
    Except String (Prod PsKernelDagGeneratedState Nat) :=
  match source with
  | PsKernelExpr.bvar index =>
      psKernelDagGeneratedFinish source state (psKernelExprV2PagedMkBVar state.arena index)
  | PsKernelExpr.fvar name =>
      psKernelDagGeneratedFinish source state (psKernelExprV2PagedMkFVar state.arena name)
  | PsKernelExpr.mvar name =>
      psKernelDagGeneratedFinish source state (psKernelExprV2PagedMkMVar state.arena name)
  | PsKernelExpr.sort level =>
      psKernelDagGeneratedFinish source state (psKernelExprV2PagedMkSort state.arena level)
  | PsKernelExpr.const name levels =>
      psKernelDagGeneratedFinish source state (psKernelExprV2PagedMkConst state.arena name levels)
  | PsKernelExpr.lit value =>
      psKernelDagGeneratedFinish source state (psKernelExprV2PagedMkLit state.arena value)
  | PsKernelExpr.app fn arg =>
      match psKernelDagGeneratedImport fn state with
      | Except.error error => Except.error error
      | Except.ok first =>
          match psKernelDagGeneratedImport arg (Prod.fst first) with
          | Except.error error => Except.error error
          | Except.ok second =>
              let next := Prod.fst second;
              psKernelDagGeneratedFinish source next
                (psKernelExprV2PagedMkApp next.arena (Prod.snd first) (Prod.snd second))
  | PsKernelExpr.lam name type body binderInfo =>
      match psKernelDagGeneratedImport type state with
      | Except.error error => Except.error error
      | Except.ok first =>
          match psKernelDagGeneratedImport body (Prod.fst first) with
          | Except.error error => Except.error error
          | Except.ok second =>
              let next := Prod.fst second;
              psKernelDagGeneratedFinish source next
                (psKernelExprV2PagedMkLam next.arena name
                  (Prod.snd first) (Prod.snd second) binderInfo)
  | PsKernelExpr.forallE name type body binderInfo =>
      match psKernelDagGeneratedImport type state with
      | Except.error error => Except.error error
      | Except.ok first =>
          match psKernelDagGeneratedImport body (Prod.fst first) with
          | Except.error error => Except.error error
          | Except.ok second =>
              let next := Prod.fst second;
              psKernelDagGeneratedFinish source next
                (psKernelExprV2PagedMkForall next.arena name
                  (Prod.snd first) (Prod.snd second) binderInfo)
  | PsKernelExpr.letE name type value body nondep =>
      match psKernelDagGeneratedImport type state with
      | Except.error error => Except.error error
      | Except.ok first =>
          match psKernelDagGeneratedImport value (Prod.fst first) with
          | Except.error error => Except.error error
          | Except.ok second =>
              match psKernelDagGeneratedImport body (Prod.fst second) with
              | Except.error error => Except.error error
              | Except.ok third =>
                  let next := Prod.fst third;
                  psKernelDagGeneratedFinish source next
                    (psKernelExprV2PagedMkLet next.arena name
                      (Prod.snd first) (Prod.snd second) (Prod.snd third) nondep)
  | PsKernelExpr.mdata tag body =>
      match psKernelDagGeneratedImport body state with
      | Except.error error => Except.error error
      | Except.ok first =>
          let next := Prod.fst first;
          psKernelDagGeneratedFinish source next
            (psKernelExprV2PagedMkMData next.arena tag (Prod.snd first))
  | PsKernelExpr.proj name index body =>
      match psKernelDagGeneratedImport body state with
      | Except.error error => Except.error error
      | Except.ok first =>
          let next := Prod.fst first;
          psKernelDagGeneratedFinish source next
            (psKernelExprV2PagedMkProj next.arena name index (Prod.snd first))

def psKernelDagGeneratedImportRules
    (rules : List PsKernelRecursorRule) (state : PsKernelDagGeneratedState) :
    Except String (Prod PsKernelDagGeneratedState (List PsKernelExprV2RecursorRuleRef)) :=
  match rules with
  | List.nil => Except.ok (Prod.mk state List.nil)
  | List.cons rule rest =>
      match psKernelDagGeneratedImport rule.rhs state with
      | Except.error error => Except.error error
      | Except.ok first =>
          match psKernelDagGeneratedImportRules rest (Prod.fst first) with
          | Except.error error => Except.error error
          | Except.ok tail =>
              Except.ok (Prod.mk (Prod.fst tail)
                (List.cons
                  (PsKernelExprV2RecursorRuleRef.mk rule.ctor rule.nFields (Prod.snd first))
                  (Prod.snd tail)))

def psKernelDagGeneratedInstallRecursor
    (recursor : PsKernelRecursorInfo) (state : PsKernelDagGeneratedState) :
    Except String PsKernelDagGeneratedState :=
  match psKernelDagGeneratedImport recursor.base.type state with
  | Except.error error => Except.error error
  | Except.ok typeResult =>
      match psKernelDagGeneratedImportRules recursor.rules (Prod.fst typeResult) with
      | Except.error error => Except.error error
      | Except.ok rulesResult =>
          let next := Prod.fst rulesResult;
          let kind : PsKernelExprV2DeclarationRefKind :=
            PsKernelExprV2DeclarationRefKind.recursorDecl (Prod.snd rulesResult);
          let owner := PsKernelExprV2DeclarationRef.mk
            recursor.base.name recursor.base.levelParams (Prod.snd typeResult)
            Option.none kind;
          Except.ok (PsKernelDagGeneratedState.mk next.arena next.built
            (List.cons owner next.declarations))

/- Quot admission constructs these four constants only after validating Eq.
   Plan all four live names/kinds before importing any header. This does not
   authenticate an arbitrary environment record or accept exported metadata. -/
def psKernelDagGeneratedFindQuot
    (environment : PsKernelEnvironment) (name : PsKernelName)
    (kind : PsKernelQuotKind) : Option PsKernelConstantInfo :=
  match psKernelEnvironmentFind environment name with
  | Option.none => Option.none
  | Option.some info =>
      match info with
      | PsKernelConstantInfo.quotInfo value =>
          if psKernelNameEq value.base.name name then
            if psKernelExprV2QuotKindEq value.kind kind then Option.some info
            else Option.none
          else Option.none
      | _ => Option.none

def psKernelDagGeneratedPlanQuot
    (environment : PsKernelEnvironment) :
    Option (List PsKernelConstantInfo) :=
  if environment.quotInitialized then
    match psKernelDagGeneratedFindQuot environment psKernelQuotName
        PsKernelQuotKind.typeQ with
    | Option.none => Option.none
    | Option.some typeInfo =>
        match psKernelDagGeneratedFindQuot environment psKernelQuotMkName
            PsKernelQuotKind.ctorQ with
        | Option.none => Option.none
        | Option.some ctorInfo =>
            match psKernelDagGeneratedFindQuot environment psKernelQuotLiftName
                PsKernelQuotKind.liftQ with
            | Option.none => Option.none
            | Option.some liftInfo =>
                match psKernelDagGeneratedFindQuot environment psKernelQuotIndName
                    PsKernelQuotKind.indQ with
                | Option.none => Option.none
                | Option.some indInfo =>
                    Option.some (List.cons typeInfo (List.cons ctorInfo
                      (List.cons liftInfo (List.cons indInfo List.nil))))
  else Option.none

def psKernelDagGeneratedInstallHeader
    (base : PsKernelConstantBase) (kind : PsKernelExprV2DeclarationRefKind)
    (state : PsKernelDagGeneratedState) :
    Except String PsKernelDagGeneratedState :=
  match psKernelDagGeneratedImport base.type state with
  | Except.error error => Except.error error
  | Except.ok imported =>
      let next := Prod.fst imported;
      let owner := PsKernelExprV2DeclarationRef.mk base.name base.levelParams
        (Prod.snd imported) Option.none kind;
      Except.ok (PsKernelDagGeneratedState.mk next.arena next.built
        (List.cons owner next.declarations))

def psKernelDagGeneratedInstallInfo
    (info : PsKernelConstantInfo) (state : PsKernelDagGeneratedState) :
    Except String PsKernelDagGeneratedState :=
  match info with
  | PsKernelConstantInfo.inductInfo value =>
      psKernelDagGeneratedInstallHeader value.base
        PsKernelExprV2DeclarationRefKind.inductiveDecl state
  | PsKernelConstantInfo.ctorInfo value =>
      psKernelDagGeneratedInstallHeader value.base
        PsKernelExprV2DeclarationRefKind.constructorDecl state
  | PsKernelConstantInfo.recInfo value =>
      psKernelDagGeneratedInstallRecursor value state
  | PsKernelConstantInfo.quotInfo value =>
      psKernelDagGeneratedInstallHeader value.base
        (PsKernelExprV2DeclarationRefKind.quotDecl value.kind) state
  | _ => Except.error "PSKERNEL_V2_GENERATED_OWNER_KIND"

def psKernelDagGeneratedInstallInfos
    (infos : List PsKernelConstantInfo) :
    PsKernelDagGeneratedState -> Except String PsKernelDagGeneratedState :=
  match infos with
  | List.nil =>
      fun (state : PsKernelDagGeneratedState) => Except.ok state
  | List.cons first rest =>
      fun (state : PsKernelDagGeneratedState) =>
        match psKernelDagGeneratedInstallInfo first state with
        | Except.error error => Except.error error
        | Except.ok next =>
            let recur := psKernelDagGeneratedInstallInfos rest;
            recur next

/- Repeated successful Quot admission is idempotent. The private owner must
   match the live kind/levels, have no delta body, and retain the exact admitted
   type in its synchronized decoded table before it can skip another import.
   This is an import-elision check, never an admission or checking judgment. -/
def psKernelDagGeneratedQuotOwnerMatches
    (value : PsKernelQuotInfo) (state : PsKernelDagGeneratedState) : Bool :=
  match psKernelExprV2DeclarationRefFind state.declarations value.base.name with
  | Option.none => false
  | Option.some owner =>
      if psKernelExprV2DeclarationRefMatches owner
          (PsKernelConstantInfo.quotInfo value) then
        match owner.deltaValue with
        | Option.some _ => false
        | Option.none =>
            match psKernelExprV2DecodedRequire state.built owner.type with
            | Except.error _ => false
            | Except.ok type => psKernelExprEqual type value.base.type
      else false

def psKernelDagGeneratedQuotOwnersComplete
    (infos : List PsKernelConstantInfo) :
    PsKernelDagGeneratedState -> Bool :=
  match infos with
  | List.nil =>
      fun (_state : PsKernelDagGeneratedState) => true
  | List.cons first rest =>
      fun (state : PsKernelDagGeneratedState) =>
        match first with
        | PsKernelConstantInfo.quotInfo value =>
            if psKernelDagGeneratedQuotOwnerMatches value state then
              let recur := psKernelDagGeneratedQuotOwnersComplete rest;
              recur state
            else false
        | _ => false

def psKernelDagGeneratedInstallQuotPlan
    (plan : Option (List PsKernelConstantInfo))
    (state : PsKernelDagGeneratedState) :
    Except String PsKernelDagGeneratedState :=
  match plan with
  | Option.none => Except.ok state
  | Option.some infos =>
      if psKernelDagGeneratedQuotOwnersComplete infos state then Except.ok state
      else psKernelDagGeneratedInstallInfos infos state

/- Called only after the complete indicated command has successfully admitted
   into environment. The ordinary name is derived from its admitted request;
   the rule bodies themselves are obtained exclusively from that environment. -/
def psKernelDagGeneratedAfterCommand
    (command : PsKernelDagCommand) (environment : PsKernelEnvironment)
    (state : PsKernelDagGeneratedState) :
    Except String PsKernelDagGeneratedState :=
  match command with
  | PsKernelDagCommand.admit request =>
      match request with
      | PsKernelDagDeclarationRequest.ordinaryInductive _ numParams value _ =>
          let name := psKernelSimpleRecName value.name;
          match psKernelEnvironmentFind environment name with
          | Option.none => Except.ok state
          | Option.some info =>
              match info with
              | PsKernelConstantInfo.recInfo recursor =>
                  if psKernelNameEq recursor.base.name name then
                    if Nat.beq recursor.numParams numParams then
                      if psKernelNameListsEq recursor.all (List.cons value.name List.nil) then
                        psKernelDagGeneratedInstallRecursor recursor state
                      else Except.ok state
                    else Except.ok state
                  else Except.ok state
              | _ => Except.ok state
      | PsKernelDagDeclarationRequest.quot =>
          psKernelDagGeneratedInstallQuotPlan
            (psKernelDagGeneratedPlanQuot environment) state
      | _ => Except.ok state
  | _ => Except.ok state

/- Current-command original refs are already in state.declarations after complete
   ordinary/mutual admission. Their types are installed unchanged by that checked
   admission. Search only inputRefs: an older batch owner is never authority for
   reuse. Nested restoration supplies no inputRefs and imports final types. -/
def psKernelDagGeneratedInstallType
    (info : PsKernelConstantInfo) (base : PsKernelConstantBase)
    (kind : PsKernelExprV2DeclarationRefKind)
    (inputRefs : List PsKernelExprV2DeclarationRef)
    (state : PsKernelDagGeneratedState) :
    Except String PsKernelDagGeneratedState :=
  let existing := psKernelExprV2DeclarationRefFind inputRefs base.name;
  let reusable : Bool :=
    match existing with
    | Option.none => false
    | Option.some owner => psKernelExprV2DeclarationRefMatches owner info;
  if reusable then Except.ok state
  else
    match psKernelDagGeneratedImport base.type state with
    | Except.error error => Except.error error
    | Except.ok result =>
        let next := Prod.fst result;
        let owner := PsKernelExprV2DeclarationRef.mk
          base.name base.levelParams (Prod.snd result) Option.none kind;
        Except.ok (PsKernelDagGeneratedState.mk next.arena next.built
          (List.cons owner next.declarations))

/- The admitted final environment is the only metadata authority. In particular,
   nested auxiliary recursor names and restored types are not reconstructed from
   input name suffixes or flattening-time declarations. -/
def psKernelDagGeneratedInstallNewInfo
    (info : PsKernelConstantInfo)
    (inputRefs : List PsKernelExprV2DeclarationRef)
    (state : PsKernelDagGeneratedState) :
    Except String PsKernelDagGeneratedState :=
  match info with
  | PsKernelConstantInfo.recInfo recursor =>
      psKernelDagGeneratedInstallRecursor recursor state
  | PsKernelConstantInfo.inductInfo value =>
      psKernelDagGeneratedInstallType info value.base
        PsKernelExprV2DeclarationRefKind.inductiveDecl inputRefs state
  | PsKernelConstantInfo.ctorInfo value =>
      psKernelDagGeneratedInstallType info value.base
        PsKernelExprV2DeclarationRefKind.constructorDecl inputRefs state
  | _ => Except.error "PSKERNEL_V2_GENERATED_PREFIX_KIND"

/- Checked ordinary/mutual/nested admission prepends only fresh final names to
   the exact previous environment. Stop before touching the first old entry.
   This structural worker visits the new prefix only, using exact indexed name
   membership; it performs no environment-size prepass or old-tail traversal. -/
def psKernelDagGeneratedInstallNewPrefix
    (remaining : List PsKernelConstantInfo)
    (previous : PsKernelEnvironment)
    (inputRefs : List PsKernelExprV2DeclarationRef)
    (state : PsKernelDagGeneratedState) :
    Except String PsKernelDagGeneratedState :=
  match remaining with
  | List.nil => Except.ok state
  | List.cons info rest =>
      if psKernelEnvironmentContains previous (psKernelConstantInfoName info) then
        Except.ok state
      else
        match psKernelDagGeneratedInstallNewInfo info inputRefs state with
        | Except.error error => Except.error error
        | Except.ok next =>
            psKernelDagGeneratedInstallNewPrefix rest previous inputRefs next

/- Production-only post-success bridge. RunCommands supplies both checked
   environments and already staged current-command refs. Failure returns before
   any batch publication. The historical three-argument helper above retains
   its bounded ordinary/Quot behavior and ABI for existing internal consumers. -/
def psKernelDagGeneratedAfterCommandWithPrevious
    (command : PsKernelDagCommand)
    (previous current : PsKernelEnvironment)
    (state : PsKernelDagGeneratedState) :
    Except String PsKernelDagGeneratedState :=
  match command with
  | PsKernelDagCommand.admit request =>
      match request with
      | PsKernelDagDeclarationRequest.ordinaryInductive _ _ _ _ =>
          let inputRefs := psKernelDagDeclarationsAfterAdmission request List.nil;
          psKernelDagGeneratedInstallNewPrefix
            current.constants previous inputRefs state
      | PsKernelDagDeclarationRequest.mutualInductive _ =>
          let inputRefs := psKernelDagDeclarationsAfterAdmission request List.nil;
          psKernelDagGeneratedInstallNewPrefix
            current.constants previous inputRefs state
      | PsKernelDagDeclarationRequest.nestedInductive _ =>
          let inputRefs := psKernelDagDeclarationsAfterAdmission request List.nil;
          psKernelDagGeneratedInstallNewPrefix
            current.constants previous inputRefs state
      | PsKernelDagDeclarationRequest.quot =>
          psKernelDagGeneratedInstallQuotPlan
            (psKernelDagGeneratedPlanQuot current) state
      | _ => Except.ok state
  | _ => Except.ok state
