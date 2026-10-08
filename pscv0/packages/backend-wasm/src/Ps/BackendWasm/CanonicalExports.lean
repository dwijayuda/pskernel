import Ps.BackendWasm.Lower
import Ps.BackendWasm.Binary
import Ps.BackendWasm.ValidateIr
import Ps.InterfaceIr.CanonicalAbi
import Ps.InterfaceIr.Encode

-- An explicit export selection is adapter policy, never source authority.
structure PsWasmCanonicalExport where
  sourceName : String
  foreignName : String

structure PsWasmCanonicalSelection where
  packageNamespace : String
  packageName : String
  worldName : String
  interfaceName : String
  exports : List PsWasmCanonicalExport

structure PsWasmCanonicalArtifacts where
  binary : List UInt8
  interfaceJson : String
  bindingJson : String
  target : PsWasmModule

inductive PsWasmCanonicalError where
  | source (error : PsVerifiedIrValidationError)
  | importsUnsupported
  | selectionLimit
  | missingDeclaration (name : String)
  | unsupportedDeclaration (name : String)
  | foreign (error : PsForeignError)
  | lower (error : PsWasmLowerError)
  | target (error : PsWasmIrValidationError)
  | signature (name : String)
  | binary (error : PsWasmEncodeError)
  | interfaceEncoding (error : PsForeignEncodeError)

def psWasmCanonicalScalar (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrPrimitiveType) : Option PsForeignScalar :=
  match type with
  | PsVerifiedIrPrimitiveType.uint8 => Option.some PsForeignScalar.u8
  | PsVerifiedIrPrimitiveType.uint16 => Option.some PsForeignScalar.u16
  | PsVerifiedIrPrimitiveType.uint32 => Option.some PsForeignScalar.u32
  | PsVerifiedIrPrimitiveType.uint64 => Option.some PsForeignScalar.u64
  | PsVerifiedIrPrimitiveType.int8 => Option.some PsForeignScalar.s8
  | PsVerifiedIrPrimitiveType.int16 => Option.some PsForeignScalar.s16
  | PsVerifiedIrPrimitiveType.int32 => Option.some PsForeignScalar.s32
  | PsVerifiedIrPrimitiveType.int64 => Option.some PsForeignScalar.s64
  | PsVerifiedIrPrimitiveType.usize =>
      match profile.wordSize with
      | PsWasmWordSize.wasm32 => Option.some PsForeignScalar.u32
      | PsWasmWordSize.wasm64 => Option.some PsForeignScalar.u64
  | PsVerifiedIrPrimitiveType.isize =>
      match profile.wordSize with
      | PsWasmWordSize.wasm32 => Option.some PsForeignScalar.s32
      | PsWasmWordSize.wasm64 => Option.some PsForeignScalar.s64
  | PsVerifiedIrPrimitiveType.float => Option.some PsForeignScalar.f64
  | PsVerifiedIrPrimitiveType.float32 => Option.some PsForeignScalar.f32
  | PsVerifiedIrPrimitiveType.bool => Option.some PsForeignScalar.bool
  | PsVerifiedIrPrimitiveType.char => Option.some PsForeignScalar.char
  | _ => Option.none

def psWasmCanonicalType (profile : PsWasmTargetProfile) (name : String)
    (type : PsVerifiedIrType) : Except PsWasmCanonicalError PsForeignType :=
  match type with
  | PsVerifiedIrType.primitive primitive =>
      match psWasmCanonicalScalar profile primitive with
      | Option.none => Except.error (PsWasmCanonicalError.unsupportedDeclaration name)
      | Option.some scalar => Except.ok (PsForeignType.scalar scalar)
  | _ => Except.error (PsWasmCanonicalError.unsupportedDeclaration name)

def psWasmCanonicalResult (profile : PsWasmTargetProfile) (name : String)
    (type : PsVerifiedIrType) : Except PsWasmCanonicalError (Option PsForeignType) :=
  match type with
  | PsVerifiedIrType.primitive primitive =>
      match primitive with
      | PsVerifiedIrPrimitiveType.unit => Except.ok Option.none
      | _ =>
          match psWasmCanonicalType profile name type with
          | Except.error error => Except.error error
          | Except.ok scalar => Except.ok (Option.some scalar)
  | _ => Except.error (PsWasmCanonicalError.unsupportedDeclaration name)

-- Source parameter names need not be WIT names. Positional labels are stable
-- and do not alter either argument order or the internal declaration.
def psWasmCanonicalParameters (profile : PsWasmTargetProfile) (name : String)
    (parameters : List PsVerifiedIrParameter) :
    Nat -> Except PsWasmCanonicalError (List PsForeignField) :=
  match parameters with
  | List.nil => fun (_index : Nat) => Except.ok List.nil
  | List.cons parameter rest =>
      let smaller : Nat -> Except PsWasmCanonicalError (List PsForeignField) :=
        psWasmCanonicalParameters profile name rest;
      fun (index : Nat) =>
        match psWasmCanonicalType profile name parameter.type with
        | Except.error error => Except.error error
        | Except.ok type =>
            match smaller (Nat.succ index) with
            | Except.error error => Except.error error
            | Except.ok fields =>
                let label : String := String.Internal.append "arg" (psNatToString index);
                Except.ok (List.cons (PsForeignField.mk label type) fields)

def psWasmCanonicalFindDeclaration (declarations : List PsVerifiedIrDeclaration)
    (name : String) : Option PsVerifiedIrDeclaration :=
  match declarations with
  | List.nil => Option.none
  | List.cons declaration rest =>
      if psStringEq declaration.name name then Option.some declaration
      else psWasmCanonicalFindDeclaration rest name

def psWasmCanonicalFunction (profile : PsWasmTargetProfile)
    (declarations : List PsVerifiedIrDeclaration) (selection : PsWasmCanonicalExport) :
    Except PsWasmCanonicalError PsForeignFunction :=
  match psWasmCanonicalFindDeclaration declarations selection.sourceName with
  | Option.none => Except.error (PsWasmCanonicalError.missingDeclaration selection.sourceName)
  | Option.some declaration =>
      if psListIsEmpty declaration.typeParameters then
        if Nat.ble (psListLength declaration.parameters) 16 then
          match psWasmCanonicalParameters profile declaration.name declaration.parameters 0 with
          | Except.error error => Except.error error
          | Except.ok parameters =>
              match psWasmCanonicalResult profile declaration.name declaration.resultType with
              | Except.error error => Except.error error
              | Except.ok result =>
                  Except.ok (PsForeignFunction.mk selection.foreignName parameters result false ["component-model"])
        else Except.error (PsWasmCanonicalError.unsupportedDeclaration declaration.name)
      else Except.error (PsWasmCanonicalError.unsupportedDeclaration declaration.name)

def psWasmCanonicalPolicy : PsForeignPolicy :=
  PsForeignPolicy.mk "component-model" List.nil List.nil false 8

def psWasmCanonicalWorld (profile : PsWasmTargetProfile)
    (selection : PsWasmCanonicalSelection) (source : PsSpecializedIrModule) :
    Except PsWasmCanonicalError PsForeignWorld :=
  match psStrictValidateModule source.raw with
  | Except.error error => Except.error (PsWasmCanonicalError.source error)
  | Except.ok _ =>
      if psListIsEmpty source.raw.imports then
        if psListIsEmpty selection.exports then Except.error PsWasmCanonicalError.selectionLimit
        else if Nat.ble (psListLength selection.exports) 1024 then
          match psListMapExcept (psWasmCanonicalFunction profile source.raw.declarations) selection.exports with
          | Except.error error => Except.error error
          | Except.ok functions =>
              let interface : PsForeignInterface :=
                PsForeignInterface.mk selection.interfaceName List.nil functions List.nil List.nil;
              let world : PsForeignWorld :=
                PsForeignWorld.mk "psc-foreign-interface/1" selection.packageNamespace selection.packageName
                  selection.worldName [interface] List.nil [selection.interfaceName];
              match psForeignValidateWorld psWasmCanonicalPolicy world with
              | Except.error error => Except.error (PsWasmCanonicalError.foreign error)
              | Except.ok _ => Except.ok world
        else Except.error PsWasmCanonicalError.selectionLimit
      else Except.error PsWasmCanonicalError.importsUnsupported

def psWasmCanonicalCoreType (type : PsCanonicalFlatType) : PsWasmValueType :=
  match type with
  | PsCanonicalFlatType.i32 => PsWasmValueType.i32
  | PsCanonicalFlatType.i64 => PsWasmValueType.i64
  | PsCanonicalFlatType.f32 => PsWasmValueType.f32
  | PsCanonicalFlatType.f64 => PsWasmValueType.f64

def psWasmCanonicalExportPair (selection : PsWasmCanonicalExport) : Prod String String :=
  Prod.mk selection.foreignName selection.sourceName

def psWasmCanonicalFindExport (exports : List (Prod String String))
    (name : String) : Option String :=
  match exports with
  | List.nil => Option.none
  | List.cons entry rest =>
      if psStringEq (Prod.fst entry) name then Option.some (Prod.snd entry)
      else psWasmCanonicalFindExport rest name

-- Check the actual target function reached by each export against the
-- independent Canonical ABI planner, not just our primitive mapping.
def psWasmCanonicalCheckSignature (module : PsWasmModule)
    (plan : PsCanonicalFunctionPlan) : Except PsWasmCanonicalError Unit :=
  match psWasmCanonicalFindExport module.exports plan.functionName with
  | Option.none => Except.error (PsWasmCanonicalError.signature plan.functionName)
  | Option.some name =>
      match psWasmIrFindFunction module.functions name with
      | Option.none => Except.error (PsWasmCanonicalError.signature plan.functionName)
      | Option.some function =>
          if psWasmIrValueTypeListsEq function.parameters (psListMap psWasmCanonicalCoreType plan.coreParameters) then
            if psWasmIrValueTypeListsEq function.results (psListMap psWasmCanonicalCoreType plan.coreResults) then
              Except.ok Unit.unit
            else Except.error (PsWasmCanonicalError.signature plan.functionName)
          else Except.error (PsWasmCanonicalError.signature plan.functionName)

def psWasmCanonicalBindingEntry (selection : PsWasmCanonicalExport) : String :=
  psJsonObject [
    Prod.mk "coreExport" (psJsonQuote selection.foreignName),
    Prod.mk "functionName" (psJsonQuote selection.foreignName),
    Prod.mk "sourceName" (psJsonQuote selection.sourceName)]

def psWasmCanonicalBindingJson (profile : PsWasmTargetProfile)
    (selection : PsWasmCanonicalSelection) : String :=
  let wordBits : Nat :=
    match profile.wordSize with
    | PsWasmWordSize.wasm32 => 32
    | PsWasmWordSize.wasm64 => 64;
  psJsonObject [
    Prod.mk "bindings" (psJsonArray (psListMap psWasmCanonicalBindingEntry selection.exports)),
    Prod.mk "contract" (psJsonQuote "psc-wasm-canonical-scalar-exports/1"),
    Prod.mk "interfaceName" (psJsonQuote selection.interfaceName),
    Prod.mk "runtimeSemantics" (psJsonQuote "psc-runtime-semantics/1"),
    Prod.mk "wordBits" (psNatToString wordBits)]

def psWasmCanonicalEncode (profile : PsWasmTargetProfile)
    (selection : PsWasmCanonicalSelection) (world : PsForeignWorld) (module : PsWasmModule) :
    Except PsWasmCanonicalError PsWasmCanonicalArtifacts :=
  match psWasmEncodeModule module with
  | Except.error error => Except.error (PsWasmCanonicalError.binary error)
  | Except.ok binary =>
      match psForeignEncodeWorld 8 world with
      | Except.error error => Except.error (PsWasmCanonicalError.interfaceEncoding error)
      | Except.ok interfaceJson =>
          Except.ok (PsWasmCanonicalArtifacts.mk binary interfaceJson (psWasmCanonicalBindingJson profile selection) module)

-- This path consumes and revalidates post-specialization IR. It exports only
-- the selected scalar surface, retaining internal GC/runtime helpers privately.
-- Unit parameters, GC values and >16 arguments require conversion wrappers and
-- fail closed here. Unit results already lower to no core result.
-- Returned artifacts remain ordinary data: checked source authority and the
-- source/target evidence graph are separate production-host obligations.
def psWasmCompileCanonicalExports (profile : PsWasmTargetProfile)
    (selection : PsWasmCanonicalSelection) (source : PsSpecializedIrModule) :
    Except PsWasmCanonicalError PsWasmCanonicalArtifacts :=
  match psWasmCanonicalWorld profile selection source with
  | Except.error error => Except.error error
  | Except.ok world =>
      match psCanonicalPlanWorld psWasmCanonicalPolicy PsCanonicalPointerWidth.memory32 world with
      | Except.error error => Except.error (PsWasmCanonicalError.foreign error)
      | Except.ok plans =>
          match psWasmLowerSpecializedValidatedModule profile source with
          | Except.error error => Except.error (PsWasmCanonicalError.lower error)
          | Except.ok lowered =>
              let module : PsWasmModule :=
                PsWasmModule.mk lowered.structures lowered.arrays lowered.functionTypes lowered.functions
                  lowered.functionRefs (psListMap psWasmCanonicalExportPair selection.exports);
              match psWasmIrValidateModule module with
              | Except.error error => Except.error (PsWasmCanonicalError.target error)
              | Except.ok _ =>
                  match psListMapExcept (psWasmCanonicalCheckSignature module) plans with
                  | Except.error error => Except.error error
                  | Except.ok _ => psWasmCanonicalEncode profile selection world module
