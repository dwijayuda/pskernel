import Ps.KernelCore.API.DagGenerated

/-
Transitional ownership for a session supplied to a fresh checked DAG batch.

A session constructed through checked admission already authorizes its live
environment. Direct construction with arbitrary metadata remains the explicitly
trusted integration boundary documented by API.Session. This bridge does not
validate arbitrary environments or turn receipts into admission certificates.

The history list enumerates names only. Every imported type, transparent value
and recursor rule comes from the exact live indexed lookup used by V1. A missing
lookup installs nothing. Checked history names are unique. In particular,
a history record with a different body cannot override the indexed declaration.

All imports append to the new batch's canonical arena and decoded work table.
No old IDs, semantic caches or externally supplied declaration refs are reused.
The caller retains the original decoded table as the external input namespace.
Theorems and opaque declarations publish only their types; only definitions
publish delta values. Quot ownership remains a separate unsupported slice.

This is one eager, private metadata import per nonempty batch. It consumes no
checker fuel and changes no recursive callback or admission policy. Recursive
expression import and its complete-batch construction cost remain explicit
migration limitations, including for sessions with large unused declarations.
-/

def psKernelDagInitialInstallDefinition
    (value : PsKernelDefinitionInfo) (state : PsKernelDagGeneratedState) :
    Except String PsKernelDagGeneratedState :=
  match psKernelDagGeneratedImport value.base.type state with
  | Except.error error => Except.error error
  | Except.ok typeResult =>
      match psKernelDagGeneratedImport value.value (Prod.fst typeResult) with
      | Except.error error => Except.error error
      | Except.ok bodyResult =>
          let next := Prod.fst bodyResult;
          let owner := PsKernelExprV2DeclarationRef.mk
            value.base.name value.base.levelParams (Prod.snd typeResult)
            (Option.some (Prod.snd bodyResult))
            PsKernelExprV2DeclarationRefKind.definitionDecl;
          Except.ok (PsKernelDagGeneratedState.mk next.arena next.built
            (List.cons owner next.declarations))

def psKernelDagInitialInstallInfo
    (info : PsKernelConstantInfo) (state : PsKernelDagGeneratedState) :
    Except String PsKernelDagGeneratedState :=
  match info with
  | PsKernelConstantInfo.axiomInfo value =>
      psKernelDagGeneratedInstallType info value.base
        PsKernelExprV2DeclarationRefKind.axiomDecl List.nil state
  | PsKernelConstantInfo.defnInfo value =>
      psKernelDagInitialInstallDefinition value state
  | PsKernelConstantInfo.thmInfo value =>
      psKernelDagGeneratedInstallType info value.base
        PsKernelExprV2DeclarationRefKind.theoremDecl List.nil state
  | PsKernelConstantInfo.opaqueInfo value =>
      psKernelDagGeneratedInstallType info value.base
        PsKernelExprV2DeclarationRefKind.opaqueDecl List.nil state
  | PsKernelConstantInfo.inductInfo _ =>
      psKernelDagGeneratedInstallNewInfo info List.nil state
  | PsKernelConstantInfo.ctorInfo _ =>
      psKernelDagGeneratedInstallNewInfo info List.nil state
  | PsKernelConstantInfo.recInfo _ =>
      psKernelDagGeneratedInstallNewInfo info List.nil state
  | PsKernelConstantInfo.quotInfo _ => Except.ok state

/- All recursive calls supply the complete argument list. A duplicate name in
   a trusted low-level history imports the same live record again; it never
   selects the historical type or value. Checked sessions have unique names.
   There is no growing linear seen-set or recursively prebuilt closure chain. -/
def psKernelDagInitialInstallEntries
    (remaining : List PsKernelConstantInfo)
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState) :
    Except String PsKernelDagGeneratedState :=
  match remaining with
  | List.nil => Except.ok state
  | List.cons historical rest =>
      let name := psKernelConstantInfoName historical;
      match psKernelEnvironmentFind environment name with
      | Option.none =>
          psKernelDagInitialInstallEntries rest environment state
      | Option.some live =>
          match psKernelDagInitialInstallInfo live state with
          | Except.error error => Except.error error
          | Except.ok next =>
              psKernelDagInitialInstallEntries rest environment next

def psKernelDagInitialInstall
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState) :
    Except String PsKernelDagGeneratedState :=
  psKernelDagInitialInstallEntries environment.constants environment state
