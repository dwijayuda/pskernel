import Ps.CompilerIr.Validate
import Ps.Foundation.List
import Ps.Foundation.Name

/-- Targets share admission and IR; target selection has no checker authority.
Native BEq/Repr adapters live in Ps.Host.BackendNativeInstances. -/
inductive PsBackendTarget where
  | js
  | ts
  | rust
  | wasmCore
  | wasmComponent
  | python
  | php

def psBackendTargets : List PsBackendTarget :=
  [PsBackendTarget.js, PsBackendTarget.ts, PsBackendTarget.rust, PsBackendTarget.wasmCore, PsBackendTarget.wasmComponent, PsBackendTarget.python, PsBackendTarget.php]

def psBackendTargetName (target : PsBackendTarget) : String :=
  match target with
  | PsBackendTarget.js => "js"
  | PsBackendTarget.ts => "ts"
  | PsBackendTarget.rust => "rust"
  | PsBackendTarget.wasmCore => "wasm-core"
  | PsBackendTarget.wasmComponent => "wasm-component"
  | PsBackendTarget.python => "python"
  | PsBackendTarget.php => "php"

def psBackendTargetEq (left right : PsBackendTarget) : Bool :=
  psStringEq (psBackendTargetName left) (psBackendTargetName right)

def psBackendTargetFromName (name : String) : Option PsBackendTarget :=
  if psStringEq name "js" then Option.some PsBackendTarget.js
  else if psStringEq name "ts" then Option.some PsBackendTarget.ts
  else if psStringEq name "rust" then Option.some PsBackendTarget.rust
  else if psStringEq name "wasm-core" then Option.some PsBackendTarget.wasmCore
  else if psStringEq name "wasm-component" then Option.some PsBackendTarget.wasmComponent
  else if psStringEq name "python" then Option.some PsBackendTarget.python
  else if psStringEq name "php" then Option.some PsBackendTarget.php
  else Option.none

def psBackendTargetExtension (target : PsBackendTarget) : String :=
  match target with
  | PsBackendTarget.js => ".js"
  | PsBackendTarget.ts => ".ts"
  | PsBackendTarget.rust => ".rs"
  | PsBackendTarget.wasmCore => ".wasm"
  | PsBackendTarget.wasmComponent => ".wasm"
  | PsBackendTarget.python => ".py"
  | PsBackendTarget.php => ".php"

def psBackendRuntimeContractVersion : String := "psc1-runtime-semantics/1"

def psBackendActivePrimitive (primitive : PsVerifiedIrPrimitiveType) : Bool :=
  match primitive with
  | PsVerifiedIrPrimitiveType.nat => true
  | PsVerifiedIrPrimitiveType.int => true
  | PsVerifiedIrPrimitiveType.bool => true
  | PsVerifiedIrPrimitiveType.char => true
  | PsVerifiedIrPrimitiveType.string => true
  | PsVerifiedIrPrimitiveType.unit => true
  | _ => false

/-- Preserve the existing target capability boundary; this is not preservation. -/
partial def psBackendPublicTypeSupported (target : PsBackendTarget)
    (type : PsVerifiedIrType) : Bool :=
  match type with
  | PsVerifiedIrType.unknown => false
  | PsVerifiedIrType.primitive scalar =>
      if psBackendTargetEq target PsBackendTarget.wasmComponent then
        match scalar with
        | PsVerifiedIrPrimitiveType.bool => true
        | _ => false
      else psBackendActivePrimitive scalar
  | PsVerifiedIrType.typeParameter _ => psBackendTargetEq target PsBackendTarget.rust
  | PsVerifiedIrType.function parameters result =>
      (psBackendTargetEq target PsBackendTarget.rust ||
        psBackendTargetEq target PsBackendTarget.wasmCore) &&
        !(psListAny (fun (parameter : PsVerifiedIrType) =>
          !psBackendPublicTypeSupported target parameter) parameters) &&
        psBackendPublicTypeSupported target result
  | PsVerifiedIrType.named _ arguments =>
      (psBackendTargetEq target PsBackendTarget.rust ||
        psBackendTargetEq target PsBackendTarget.wasmCore) &&
        !(psListAny (fun (argument : PsVerifiedIrType) =>
          !psBackendPublicTypeSupported target argument) arguments)

def psBackendNameSeen (name : String) (names : List String) : Bool :=
  match names with
  | List.nil => false
  | List.cons current rest =>
      if psStringEq name current then true else psBackendNameSeen name rest

def psBackendPublicNamesUniqueWorker (names : List String) : List String -> Bool :=
  match names with
  | List.nil => fun (seen : List String) => true
  | List.cons name rest =>
      let smaller : List String -> Bool := psBackendPublicNamesUniqueWorker rest;
      fun (seen : List String) =>
        if psBackendNameSeen name seen then false else smaller (List.cons name seen)

def psBackendPublicApiWorker (target : PsBackendTarget) (source : PsValidatedIrModule)
    (publicNames : List String) : Except String Unit :=
  match publicNames with
  | List.nil => Except.ok Unit.unit
  | List.cons name rest =>
      match psStrictFindDeclaration source.raw.declarations name with
      | Option.none =>
          Except.error (String.Internal.append "PSC1_PUBLIC_DECLARATION_MISSING: " name)
      | Option.some declaration =>
          if !psBackendTargetEq target PsBackendTarget.rust &&
              !psListIsEmpty declaration.typeParameters then
            Except.error (String.Internal.append "PSC1_PUBLIC_GENERIC_SIGNATURE_UNQUALIFIED: " name)
          else if !psBackendPublicTypeSupported target declaration.resultType ||
              psListAny (fun (parameter : PsVerifiedIrParameter) =>
                !psBackendPublicTypeSupported target parameter.type) declaration.parameters then
            Except.error (String.Internal.append "PSC1_PUBLIC_TARGET_SIGNATURE_UNQUALIFIED: "
              (String.Internal.append (psBackendTargetName target) (String.Internal.append ":" name)))
          else psBackendPublicApiWorker target source rest

def psBackendCheckPublicApi (target : PsBackendTarget)
    (source : PsValidatedIrModule) (publicNames : List String) : Except String Unit :=
  if psBackendPublicNamesUniqueWorker publicNames [] then
    psBackendPublicApiWorker target source publicNames
  else Except.error "PSC1_PUBLIC_DECLARATION_DUPLICATE"

def psBackendClosedNames (source : PsValidatedIrModule) (names : List String) : Except String Unit :=
  match names with
  | List.nil => Except.ok Unit.unit
  | List.cons name rest =>
      match psStrictFindDeclaration source.raw.declarations name with
      | Option.none => Except.error (String.Internal.append "PSC1_PUBLIC_DECLARATION_LOST: " name)
      | Option.some declaration => psBackendClosedNames source rest

/-- Every wrapper is revalidated; only the captured host session can publish. -/
def psBackendClosedPlan (source : PsValidatedIrModule)
    (publicNames : List String) : Except String PsValidatedIrModule :=
  match psStrictValidateModule source.raw with
  | Except.error _ => Except.error "PSC1_BACKEND_INPUT_IR_INVALID"
  | Except.ok input =>
      match psIrSpecializeValidatedModule input with
      | Except.error _ => Except.error "PSC1_BACKEND_SPECIALIZATION_FAILED"
      | Except.ok specialized =>
          match psStrictValidateModule specialized.raw with
          | Except.error _ => Except.error "PSC1_BACKEND_SPECIALIZED_IR_INVALID"
          | Except.ok output =>
              match psBackendClosedNames output publicNames with
              | Except.error error => Except.error error
              | Except.ok checked => Except.ok output
