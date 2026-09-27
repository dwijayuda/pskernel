import Ps.Bootstrap.SelfHost

def psMinimalSelfHostLeanSource : String :=
  "def answer : Nat := 42"

def psMinimalSelfHostListConstructionSource : String :=
  "def singleton : List Nat := List.cons 1 List.nil\n"

def psMinimalSelfHostListMatchSource : String :=
  "def headOrZero (xs : List Nat) : Nat :=\n" ++
  "  match xs with\n" ++
  "  | List.nil => 0\n" ++
  "  | List.cons head tail => head\n"

def psMinimalSelfHostListSource : String :=
  psMinimalSelfHostListConstructionSource ++
  psMinimalSelfHostListMatchSource

def psTestMinimalSelfHostPreparation : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostLeanSource with
  | Except.error _ => false
  | Except.ok prepared =>
      prepared.declarations.length > 0
        && prepared.canonicalAdmissions.length > 0

def psTestMinimalSelfHostVerifiedIr : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostLeanSource with
  | Except.error _ => false
  | Except.ok prepared =>
      match psCompilerVerifiedIrFromPrepared prepared with
      | Except.error _ => false
      | Except.ok _ => true

def psTestForgedAdmissionReadyRejected : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostLeanSource with
  | Except.error _ => false
  | Except.ok prepared =>
      let forged : PsCompilerAdmissionReadyModule :=
        { prepared with canonicalAdmissions := "forged" }
      match psCompilerVerifiedIrFromPrepared forged with
      | Except.error PsCompilerError.preparedAdmissionMismatch => true
      | _ => false

def psTestMinimalSelfHostTypeScript : Bool :=
  match
      psCompilerTypeScriptSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostLeanSource with
  | Except.error _ => false
  | Except.ok output => output.contains "answer"

def psTestMinimalSelfHostListConstructionPreparation : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostListConstructionSource with
  | Except.error _ => false
  | Except.ok prepared =>
      prepared.declarations.length > 0
        && prepared.canonicalAdmissions.length > 0

def psTestMinimalSelfHostListMatchPreparation : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostListMatchSource with
  | Except.error _ => false
  | Except.ok prepared =>
      prepared.declarations.length > 0
        && prepared.canonicalAdmissions.length > 0

def psTestMinimalSelfHostListPreparation : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostListSource with
  | Except.error _ => false
  | Except.ok prepared =>
      prepared.declarations.length > 0
        && prepared.canonicalAdmissions.length > 0

def psTestMinimalSelfHostListConstructionMissingRuntime : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostListConstructionSource with
  | Except.error _ => false
  | Except.ok prepared =>
      match psCompilerVerifiedIrFromPrepared prepared with
      | Except.error
          (PsCompilerError.erasure
            (PsErasureError.unknownConstant name)) =>
          psNameEq name psSelfHostListConsName
            || psNameEq name psSelfHostListNilName
      | _ => false

def psTestMinimalSelfHostListMatchMissingRuntime : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostListMatchSource with
  | Except.error _ => false
  | Except.ok prepared =>
      match psCompilerVerifiedIrFromPrepared prepared with
      | Except.error
          (PsCompilerError.erasure
            (PsErasureError.unknownConstant name)) =>
          psNameEq name psSelfHostListRecName
            || psNameEq name psSelfHostListConsName
            || psNameEq name psSelfHostListNilName
      | _ => false

def psTestMinimalSelfHostListVerifiedIr : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostListSource with
  | Except.error _ => false
  | Except.ok prepared =>
      match psCompilerVerifiedIrFromPrepared prepared with
      | Except.error _ => false
      | Except.ok _ => true

def psTestMinimalSelfHostListTypeScript : Bool :=
  match
      psCompilerTypeScriptSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostListSource with
  | Except.error _ => false
  | Except.ok _ => true

def main : IO Unit := do
  if psTestMinimalSelfHostPreparation then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: admission-ready boundary"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: admission-ready boundary")
  if psTestMinimalSelfHostVerifiedIr then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: prepared core -> VerifiedIR"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: prepared core -> VerifiedIR")
  if psTestForgedAdmissionReadyRejected then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: forged admission-ready artifact rejected"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: forged admission-ready artifact was accepted")
  if psTestMinimalSelfHostTypeScript then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: TypeScript bootstrap backend"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: TypeScript bootstrap backend")
  if psTestMinimalSelfHostListConstructionPreparation then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: foundational List construction preparation"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational List construction preparation")
  if psTestMinimalSelfHostListMatchPreparation then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: foundational List match preparation"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational List match preparation")
  if psTestMinimalSelfHostListPreparation then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: foundational List preparation"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational List preparation")
  if psTestMinimalSelfHostListVerifiedIr then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: foundational List -> VerifiedIR"
  else if psTestMinimalSelfHostListConstructionMissingRuntime then
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational List erasure missing constructor runtime")
  else if psTestMinimalSelfHostListMatchMissingRuntime then
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational List erasure missing match runtime")
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational List -> VerifiedIR")
  if psTestMinimalSelfHostListTypeScript then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: foundational List -> TypeScript"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational List -> TypeScript")
