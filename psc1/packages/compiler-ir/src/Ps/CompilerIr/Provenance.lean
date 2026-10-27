import Ps.CompilerIr.Model
import Ps.Foundation.List

/-! Transform provenance is diagnostic/link data, never a validation token.
Producers attach it at creation sites; emitters still validate exact IR. -/

inductive PsIrOriginKind where
  | structure
  | inductive
  | declaration

inductive PsIrOriginRule where
  | retained
  | specialization
  | worker

structure PsIrTransformOrigin where
  kind : PsIrOriginKind
  outputName : String
  inputName : String
  arguments : List PsVerifiedIrType
  rule : PsIrOriginRule

structure PsIrTracedModule where
  raw : PsVerifiedIrModule
  origins : List PsIrTransformOrigin

def psIrRetainedOrigin (kind : PsIrOriginKind) (name : String) : PsIrTransformOrigin :=
  PsIrTransformOrigin.mk kind name name [] PsIrOriginRule.retained

def psIrRetainedOrigins (module : PsVerifiedIrModule) : List PsIrTransformOrigin :=
  psListAppend
    (psListMap (fun (value : PsVerifiedIrStructure) =>
      psIrRetainedOrigin PsIrOriginKind.structure value.name) module.structures)
    (psListAppend
      (psListMap (fun (value : PsVerifiedIrInductive) =>
        psIrRetainedOrigin PsIrOriginKind.inductive value.name) module.inductives)
      (psListMap (fun (value : PsVerifiedIrDeclaration) =>
        psIrRetainedOrigin PsIrOriginKind.declaration value.name) module.declarations))
