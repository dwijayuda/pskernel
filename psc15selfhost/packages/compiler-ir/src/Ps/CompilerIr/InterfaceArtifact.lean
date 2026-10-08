import Ps.CompilerIr.Encode

-- Runtime signatures only. Core unfolding, theorem specifications, effects,
-- capabilities and behavioral equivalence require separate interface evidence.
def psIrJsonRuntimeSignature (value : PsVerifiedIrDeclaration) : Except PsIrEncodeError String :=
  psIrJsonValues [psIrJsonText value.name, psIrJsonTypeParameters value.typeParameters,
    psIrJsonParameters value.parameters, psIrJsonType value.resultType]

-- All declared layouts/imports and declaration order are retained deliberately.
-- This conservative projection never infers visibility or drops private types.
def psIrEncodeRuntimeInterface (value : PsValidatedIrModule) : Except PsIrEncodeError String :=
  psIrJsonNode "psc-runtime-interface-json/1" [
    psIrJsonText "psc-runtime-semantics/1",
    psIrJsonText "psc-runtime-values/1",
    psIrJsonValues (psListMap psIrJsonImport value.raw.imports),
    psIrJsonValues (psListMap psIrJsonStructure value.raw.structures),
    psIrJsonValues (psListMap psIrJsonInductive value.raw.inductives),
    psIrJsonValues (psListMap psIrJsonRuntimeSignature value.raw.declarations)]
