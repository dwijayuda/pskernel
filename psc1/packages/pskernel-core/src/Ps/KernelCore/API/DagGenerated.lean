import Ps.KernelCore.API.Kernel
import Ps.KernelCore.API.DagDeclaration

/-
Explicit transitional ownership bridge for checked generated metadata.

Complete ordinary, mutual and nested admission first constructs and validates
the final types and recursor rules in the private work environment. Only after
that admission succeeds may this bridge copy the checked metadata into the
owning batch arena. No exported recursor body, caller-provided rule or supplied
cache is accepted as authoritative metadata. A group is planned completely
before any import; missing or mismatched metadata leaves the owner unchanged.

This import is performed once per successful inductive command in a batch,
not inside WHNF. It preserves original IDs by appending smart-constructed
nodes, and appends the corresponding source expressions to the decoded table.
Ordinary/mutual header and constructor IDs still refer to their original input.
Nested restored types and renamed auxiliary recursors come from the validated
final environment. Successful Quot admission installs all four live headers;
repeated admission retains exact existing owners without appending more nodes.
Initial-session metadata is not installed here.
This deliberately remains a recursive-expression import and V1 inductive
admission fallback, not completed DAG-native admission. Repeated source
subtrees are not interned. Construction and retained-memory costs must be
included in whole-batch measurements.

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

/- Plans below are constructed only after complete checked admission. They
contain the final live metadata, not caller-supplied types or rule bodies.
A missing or inconsistent member declines the entire plan before any append.
The later import transaction either installs the complete plan or returns an
error without publishing a batch session. -/
def psKernelDagGeneratedAppendInfos
    (left : List PsKernelConstantInfo) :
    List PsKernelConstantInfo -> List PsKernelConstantInfo :=
  match left with
  | List.nil =>
      fun (right : List PsKernelConstantInfo) => right
  | List.cons first rest =>
      fun (right : List PsKernelConstantInfo) =>
        let recur := psKernelDagGeneratedAppendInfos rest;
        List.cons first (recur right)

def psKernelDagGeneratedTypeNames
    (types : List PsKernelDagInductive) : List PsKernelName :=
  match types with
  | List.nil => List.nil
  | List.cons first rest =>
      List.cons first.name (psKernelDagGeneratedTypeNames rest)

def psKernelDagGeneratedCtorNames
    (ctors : List PsKernelDagConstructor) : List PsKernelName :=
  match ctors with
  | List.nil => List.nil
  | List.cons first rest =>
      List.cons first.name (psKernelDagGeneratedCtorNames rest)

def psKernelDagGeneratedFindRecursor
    (environment : PsKernelEnvironment) (name : PsKernelName)
    (numParams : Nat) (all : List PsKernelName) :
    Option PsKernelRecursorInfo :=
  match psKernelEnvironmentFind environment name with
  | Option.none => Option.none
  | Option.some info =>
      match info with
      | PsKernelConstantInfo.recInfo recursor =>
          if psKernelNameEq recursor.base.name name then
            if Nat.beq recursor.numParams numParams then
              if psKernelNameListsEq recursor.all all then Option.some recursor
              else Option.none
            else Option.none
          else Option.none
      | _ => Option.none

def psKernelDagGeneratedPlanRecursors
    (types : List PsKernelDagInductive) :
    PsKernelEnvironment -> Nat -> List PsKernelName ->
    Option (List PsKernelConstantInfo) :=
  match types with
  | List.nil =>
      fun (_environment : PsKernelEnvironment) (_numParams : Nat)
          (_all : List PsKernelName) =>
        Option.some List.nil
  | List.cons first rest =>
      fun (environment : PsKernelEnvironment) (numParams : Nat)
          (all : List PsKernelName) =>
        match psKernelDagGeneratedFindRecursor
            environment (psKernelSimpleRecName first.name) numParams all with
        | Option.none => Option.none
        | Option.some recursor =>
            let recur := psKernelDagGeneratedPlanRecursors rest;
            match recur environment numParams all with
            | Option.none => Option.none
            | Option.some tail =>
                Option.some (List.cons (PsKernelConstantInfo.recInfo recursor) tail)

def psKernelDagGeneratedPlanMutual
    (group : PsKernelDagInductiveGroup) (environment : PsKernelEnvironment) :
    Option (List PsKernelConstantInfo) :=
  psKernelDagGeneratedPlanRecursors group.types environment group.numParams
    (psKernelDagGeneratedTypeNames group.types)

def psKernelDagGeneratedPlanNestedConstructors
    (names : List PsKernelName) :
    PsKernelEnvironment -> PsKernelName -> List PsKernelName -> Nat ->
    Option (List PsKernelConstantInfo) :=
  match names with
  | List.nil =>
      fun (_environment : PsKernelEnvironment) (_family : PsKernelName)
          (_levelParams : List PsKernelName) (_numParams : Nat) =>
        Option.some List.nil
  | List.cons name rest =>
      fun (environment : PsKernelEnvironment) (family : PsKernelName)
          (levelParams : List PsKernelName) (numParams : Nat) =>
        match psKernelEnvironmentFind environment name with
        | Option.none => Option.none
        | Option.some info =>
            match info with
            | PsKernelConstantInfo.ctorInfo ctor =>
                if psKernelNameEq ctor.base.name name then
                  if psKernelNameEq ctor.induct family then
                    if psKernelNameListsEq ctor.base.levelParams levelParams then
                      if Nat.beq ctor.numParams numParams then
                        let recur := psKernelDagGeneratedPlanNestedConstructors rest;
                        match recur environment family levelParams numParams with
                        | Option.none => Option.none
                        | Option.some tail => Option.some (List.cons info tail)
                      else Option.none
                    else Option.none
                  else Option.none
                else Option.none
            | _ => Option.none

def psKernelDagGeneratedNestedInfoMatches
    (info : PsKernelInductiveInfo) (source : PsKernelDagInductive)
    (levelParams : List PsKernelName) (numParams : Nat)
    (all : List PsKernelName) (numNested : Nat) : Bool :=
  if psKernelNameEq info.base.name source.name then
    if psKernelNameListsEq info.base.levelParams levelParams then
      if Nat.beq info.numParams numParams then
        if psKernelNameListsEq info.all all then
          if Nat.beq info.numNested numNested then
            psKernelNameListsEq info.ctors (psKernelDagGeneratedCtorNames source.ctors)
          else false
        else false
      else false
    else false
  else false

def psKernelDagGeneratedPlanNestedFamily
    (source : PsKernelDagInductive) (environment : PsKernelEnvironment)
    (levelParams : List PsKernelName) (numParams : Nat)
    (all : List PsKernelName) (numNested : Nat) :
    Option (List PsKernelConstantInfo) :=
  match psKernelEnvironmentFind environment source.name with
  | Option.none => Option.none
  | Option.some entry =>
      match entry with
      | PsKernelConstantInfo.inductInfo info =>
          if psKernelDagGeneratedNestedInfoMatches
              info source levelParams numParams all numNested then
            match psKernelDagGeneratedPlanNestedConstructors
                info.ctors environment source.name levelParams numParams with
            | Option.none => Option.none
            | Option.some ctors =>
                match psKernelDagGeneratedFindRecursor
                    environment (psKernelSimpleRecName source.name) numParams all with
                | Option.none => Option.none
                | Option.some recursor =>
                    Option.some (List.cons entry
                      (psKernelDagGeneratedAppendInfos ctors
                        (List.cons (PsKernelConstantInfo.recInfo recursor) List.nil)))
          else Option.none
      | _ => Option.none

def psKernelDagGeneratedPlanNestedFamilies
    (types : List PsKernelDagInductive) :
    PsKernelEnvironment -> List PsKernelName -> Nat -> List PsKernelName -> Nat ->
    Option (List PsKernelConstantInfo) :=
  match types with
  | List.nil =>
      fun (_environment : PsKernelEnvironment) (_levelParams : List PsKernelName)
          (_numParams : Nat) (_all : List PsKernelName) (_numNested : Nat) =>
        Option.some List.nil
  | List.cons first rest =>
      fun (environment : PsKernelEnvironment) (levelParams : List PsKernelName)
          (numParams : Nat) (all : List PsKernelName) (numNested : Nat) =>
        match psKernelDagGeneratedPlanNestedFamily
            first environment levelParams numParams all numNested with
        | Option.none => Option.none
        | Option.some members =>
            let recur := psKernelDagGeneratedPlanNestedFamilies rest;
            match recur environment levelParams numParams all numNested with
            | Option.none => Option.none
            | Option.some tail =>
                Option.some (psKernelDagGeneratedAppendInfos members tail)

/- numNested is the number produced by checked nested restoration. This is a
   metadata enumeration bound, not checker fuel. The names match
   psKernelSimpleNestedMakeRenamesWorker exactly, starting at index one. -/
def psKernelDagGeneratedPlanNestedAux
    (count : Nat) :
    PsKernelEnvironment -> PsKernelName -> Nat -> Nat -> List PsKernelName ->
    Option (List PsKernelConstantInfo) :=
  match count with
  | Nat.zero =>
      fun (_environment : PsKernelEnvironment) (_mainRec : PsKernelName)
          (_index _numParams : Nat) (_all : List PsKernelName) =>
        Option.some List.nil
  | Nat.succ remaining =>
      fun (environment : PsKernelEnvironment) (mainRec : PsKernelName)
          (index numParams : Nat) (all : List PsKernelName) =>
        let name := psKernelNameAppendIndexAfter mainRec index;
        match psKernelDagGeneratedFindRecursor environment name numParams all with
        | Option.none => Option.none
        | Option.some recursor =>
            let recur := psKernelDagGeneratedPlanNestedAux remaining;
            match recur environment mainRec (Nat.succ index) numParams all with
            | Option.none => Option.none
            | Option.some tail =>
                Option.some (List.cons (PsKernelConstantInfo.recInfo recursor) tail)

def psKernelDagGeneratedPlanNested
    (group : PsKernelDagInductiveGroup) (environment : PsKernelEnvironment) :
    Option (List PsKernelConstantInfo) :=
  match group.types with
  | List.nil => Option.some List.nil
  | List.cons first _ =>
      match psKernelEnvironmentFind environment first.name with
      | Option.none => Option.none
      | Option.some entry =>
          match entry with
          | PsKernelConstantInfo.inductInfo info =>
              let all := psKernelDagGeneratedTypeNames group.types;
              match psKernelDagGeneratedPlanNestedFamilies group.types environment
                  group.levelParams group.numParams all info.numNested with
              | Option.none => Option.none
              | Option.some families =>
                  match psKernelDagGeneratedPlanNestedAux info.numNested environment
                      (psKernelSimpleRecName first.name) 1 group.numParams all with
                  | Option.none => Option.none
                  | Option.some auxiliary =>
                      Option.some (psKernelDagGeneratedAppendInfos families auxiliary)
          | _ => Option.none

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

def psKernelDagGeneratedInstallPlan
    (plan : Option (List PsKernelConstantInfo))
    (state : PsKernelDagGeneratedState) :
    Except String PsKernelDagGeneratedState :=
  match plan with
  | Option.none => Except.ok state
  | Option.some infos => psKernelDagGeneratedInstallInfos infos state

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
   into environment. Ordinary/mutual input types retain their original IDs.
   Nested headers, constructors, main recursors and renamed auxiliary recursors
   use only the final restored metadata validated by nested admission. -/
def psKernelDagGeneratedAfterCommand
    (command : PsKernelDagCommand) (environment : PsKernelEnvironment)
    (state : PsKernelDagGeneratedState) :
    Except String PsKernelDagGeneratedState :=
  match command with
  | PsKernelDagCommand.admit request =>
      match request with
      | PsKernelDagDeclarationRequest.ordinaryInductive _ numParams value _ =>
          match psKernelDagGeneratedFindRecursor environment
              (psKernelSimpleRecName value.name) numParams (List.cons value.name List.nil) with
          | Option.none => Except.ok state
          | Option.some recursor => psKernelDagGeneratedInstallRecursor recursor state
      | PsKernelDagDeclarationRequest.mutualInductive group =>
          psKernelDagGeneratedInstallPlan
            (psKernelDagGeneratedPlanMutual group environment) state
      | PsKernelDagDeclarationRequest.nestedInductive group =>
          psKernelDagGeneratedInstallPlan
            (psKernelDagGeneratedPlanNested group environment) state
      | PsKernelDagDeclarationRequest.quot =>
          psKernelDagGeneratedInstallQuotPlan
            (psKernelDagGeneratedPlanQuot environment) state
      | _ => Except.ok state
  | _ => Except.ok state
