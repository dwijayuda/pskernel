import Ps.KernelCore.API.DagNestedTransformed

/- Private restoration only. The retained functions below construct syntax and
   metadata; they make no checking judgments. Restored references replace the
   provisional transformed namespace in a private append-only owner. The next
   phase must independently validate restored templates, constructors, recursor
   types and rules before any public environment or receipt may be returned. -/
structure PsKernelExprV2NestedRestoredEnvironment where
  environment : PsKernelEnvironment
  renames : List (Prod PsKernelName PsKernelName)

def psKernelExprV2NestedRestoreEnvironment
    (base : PsKernelEnvironment) (checked : PsKernelExprV2NestedCheckedTransformed) :
    Except String PsKernelExprV2NestedRestoredEnvironment :=
  let plan := checked.preprocessed;
  let decl := plan.header.original;
  match plan.processed.state.aux with
  | List.nil =>
      Except.ok (PsKernelExprV2NestedRestoredEnvironment.mk checked.admitted.environment List.nil)
  | List.cons _ _ =>
      match decl.types with
      | List.nil => Except.error "empty nested inductive declaration"
      | List.cons first _ =>
          let renames := psKernelSimpleNestedMakeRenames (psKernelSimpleRecName first.name)
            plan.processed.state.aux;
          match psKernelSimpleNestedAddOriginals checked.admitted.environment base decl
              plan.canonicalParams plan.processed.state.aux renames with
          | Except.error error =>
              Except.error (String.Internal.append "nested original restoration: " error)
          | Except.ok originals =>
              match psKernelSimpleNestedAddAuxRecursors checked.admitted.environment originals
                  (psKernelSimpleMutualNames decl.types) plan.canonicalParams decl.numParams
                  plan.processed.state.aux renames with
              | Except.error error =>
                  Except.error (String.Internal.append "nested auxiliary restoration: " error)
              | Except.ok environment =>
                  Except.ok (PsKernelExprV2NestedRestoredEnvironment.mk environment renames)

def psKernelExprV2NestedRestoredOriginName
    (name : PsKernelName) (renames : List (Prod PsKernelName PsKernelName)) : PsKernelName :=
  match renames with
  | List.nil => name
  | List.cons first rest =>
      if psKernelNameEq name (Prod.snd first) then Prod.fst first
      else psKernelExprV2NestedRestoredOriginName name rest

def psKernelExprV2NestedRestoreType
    (type : PsKernelExpr) (origin : Option PsKernelExprV2DeclarationRef)
    (owner : PsKernelDagGeneratedState) : Except String (Prod PsKernelDagGeneratedState Nat) :=
  match origin with
  | Option.none => psKernelDagGeneratedImport type owner
  | Option.some reference => psKernelExprV2NestedOverlay type reference.type owner

def psKernelExprV2NestedRestoreRules
    (rules : List PsKernelRecursorRule) (origins : List PsKernelExprV2RecursorRuleRef)
    (owner : PsKernelDagGeneratedState) :
    Except String (Prod PsKernelDagGeneratedState (List PsKernelExprV2RecursorRuleRef)) :=
  match rules with
  | List.nil => Except.ok (Prod.mk owner List.nil)
  | List.cons rule rest =>
      let attempted : Except String (Prod PsKernelDagGeneratedState Nat) :=
        match origins with
        | List.nil => psKernelDagGeneratedImport rule.rhs owner
        | List.cons first _ => psKernelExprV2NestedOverlay rule.rhs first.rhs owner;
      match attempted with
      | Except.error error => Except.error error
      | Except.ok imported =>
          let tail : List PsKernelExprV2RecursorRuleRef := match origins with
            | List.nil => List.nil
            | List.cons _ remaining => remaining;
          match psKernelExprV2NestedRestoreRules rest tail (Prod.fst imported) with
          | Except.error error => Except.error error
          | Except.ok result =>
              Except.ok (Prod.mk (Prod.fst result)
                (List.cons (PsKernelExprV2RecursorRuleRef.mk rule.ctor rule.nFields (Prod.snd imported))
                  (Prod.snd result)))

def psKernelExprV2NestedRestoreReference
    (info : PsKernelConstantInfo) (origin : Option PsKernelExprV2DeclarationRef)
    (owner : PsKernelDagGeneratedState) : Except String PsKernelDagGeneratedState :=
  match psKernelExprV2NestedRestoreType (psKernelConstantInfoType info) origin owner with
  | Except.error error => Except.error error
  | Except.ok imported =>
      let next := Prod.fst imported;
      let root := Prod.snd imported;
      match info with
      | PsKernelConstantInfo.inductInfo value =>
          let reference := PsKernelExprV2DeclarationRef.mk value.base.name value.base.levelParams
            root Option.none PsKernelExprV2DeclarationRefKind.inductiveDecl;
          Except.ok (PsKernelDagGeneratedState.mk next.arena next.built (List.cons reference next.declarations))
      | PsKernelConstantInfo.ctorInfo value =>
          let reference := PsKernelExprV2DeclarationRef.mk value.base.name value.base.levelParams
            root Option.none PsKernelExprV2DeclarationRefKind.constructorDecl;
          Except.ok (PsKernelDagGeneratedState.mk next.arena next.built (List.cons reference next.declarations))
      | PsKernelConstantInfo.recInfo value =>
          let origins : List PsKernelExprV2RecursorRuleRef :=
            match origin with
            | Option.none => List.nil
            | Option.some reference =>
                match reference.kind with
                | PsKernelExprV2DeclarationRefKind.recursorDecl rules => rules
                | _ => List.nil;
          match psKernelExprV2NestedRestoreRules value.rules origins next with
          | Except.error error => Except.error error
          | Except.ok rules =>
              let state := Prod.fst rules;
              let reference := PsKernelExprV2DeclarationRef.mk value.base.name value.base.levelParams
                root Option.none (PsKernelExprV2DeclarationRefKind.recursorDecl (Prod.snd rules));
              Except.ok (PsKernelDagGeneratedState.mk state.arena state.built
                (List.cons reference state.declarations))
      | _ => Except.error "PSKERNEL_V2_NESTED_RESTORED_KIND_MISMATCH"

def psKernelExprV2NestedRestorePrefix
    (constants : List PsKernelConstantInfo) (base : PsKernelEnvironment)
    (origins : List PsKernelExprV2DeclarationRef)
    (renames : List (Prod PsKernelName PsKernelName)) (owner : PsKernelDagGeneratedState) :
    Except String PsKernelDagGeneratedState :=
  match constants with
  | List.nil => Except.ok owner
  | List.cons info rest =>
      if psKernelEnvironmentContains base (psKernelConstantInfoName info) then
        psKernelExprV2NestedRestorePrefix rest base origins renames owner
      else
        let oldName := psKernelExprV2NestedRestoredOriginName (psKernelConstantInfoName info) renames;
        let origin := psKernelExprV2DeclarationRefFind origins oldName;
        match psKernelExprV2NestedRestoreReference info origin owner with
        | Except.error error => Except.error error
        | Except.ok next => psKernelExprV2NestedRestorePrefix rest base origins renames next

structure PsKernelExprV2NestedRestored where
  checked : PsKernelExprV2NestedCheckedTransformed
  environment : PsKernelEnvironment
  renames : List (Prod PsKernelName PsKernelName)
  owner : PsKernelDagGeneratedState

def psKernelExprV2NestedRestore
    (base : PsKernelEnvironment) (originalOwner : PsKernelDagGeneratedState)
    (checked : PsKernelExprV2NestedCheckedTransformed) : Except String PsKernelExprV2NestedRestored :=
  match psKernelExprV2NestedRestoreEnvironment base checked with
  | Except.error error => Except.error error
  | Except.ok restored =>
      match checked.preprocessed.processed.state.aux with
      | List.nil =>
          Except.ok (PsKernelExprV2NestedRestored.mk checked restored.environment restored.renames checked.admitted.owner)
      | List.cons _ _ =>
          let transformed := checked.admitted.owner;
          let privateOwner := PsKernelDagGeneratedState.mk transformed.arena transformed.built originalOwner.declarations;
          match psKernelExprV2NestedRestorePrefix restored.environment.constants base
              transformed.declarations restored.renames privateOwner with
          | Except.error error => Except.error error
          | Except.ok owner =>
              Except.ok (PsKernelExprV2NestedRestored.mk checked restored.environment restored.renames owner)
