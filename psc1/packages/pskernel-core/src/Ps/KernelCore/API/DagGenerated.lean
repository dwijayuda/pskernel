import Ps.KernelCore.API.Kernel
import Ps.KernelCore.API.DagDeclaration

/-
Explicit transitional ownership bridge for ordinary recursors, including K.

Complete inductive admission first constructs and validates the recursor type
and every rule in the private work environment. Only after that admission
succeeds may this bridge copy that checked generated metadata into the owning
batch arena. No exported recursor body, caller-provided rule or supplied cache
is accepted as authoritative metadata.

This import is performed once per successful ordinary inductive in a batch,
not inside WHNF. It preserves original IDs by appending smart-constructed
nodes, and appends the corresponding source expressions to the decoded table.
It deliberately remains a recursive-expression import: ordinary inductive
admission is still the V1 fallback, not a completed DAG-native admission path.
Repeated source subtrees are not interned by this bridge. Its construction and
retained-memory costs must be included in whole-batch measurements.

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
      | _ => Except.ok state
  | _ => Except.ok state
