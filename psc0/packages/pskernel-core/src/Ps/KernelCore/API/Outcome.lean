import Ps.KernelCore.Checker.ResourcePolicy

/- Public operations use the PSC1-supported Except PsKernelError Value shape.
   Success has a typed payload; four typed error variants retain the reason for
   non-acceptance. No runtime type parameter or second checker is introduced. -/
inductive PsKernelOutcome where
  | accepted
  | rejectedInvalid
  | declinedUnsupported
  | resourceExhausted
  | internalError

inductive PsKernelError where
  | rejectedInvalid (message : String)
  | declinedUnsupported (message : String)
  | resourceExhausted (resource : PsKernelResourceError) (message : String)
  | internalError (message : String)

def psKernelErrorOutcome (error : PsKernelError) : PsKernelOutcome :=
  match error with
  | PsKernelError.rejectedInvalid _ => PsKernelOutcome.rejectedInvalid
  | PsKernelError.declinedUnsupported _ => PsKernelOutcome.declinedUnsupported
  | PsKernelError.resourceExhausted _ _ => PsKernelOutcome.resourceExhausted
  | PsKernelError.internalError _ => PsKernelOutcome.internalError

def psKernelDiagnosticMember
    (message : String)
    (messages : List String) : Bool :=
  match messages with
  | List.nil => false
  | List.cons head rest =>
      if psKernelStringEq message head then true
      else psKernelDiagnosticMember message rest

def psKernelKnownInvalidDiagnostic (message : String) : Bool :=
  if psKernelStringEq message "recursive argument contains the datatype under a stuck recursor" then
    true
  else psKernelDiagnosticMember message
    (List.cons "already declared" (List.cons "application type mismatch" (List.cons "declaration has free variables" (List.cons "declaration has metavariables" (List.cons "definition type mismatch" (List.cons "duplicate inductive, constructor, or recursor name" (List.cons "duplicate mutual inductive, constructor, or recursor name" (List.cons "duplicate universe parameter" (List.cons "empty mutual inductive declaration" (List.cons "empty nested inductive declaration" (List.cons "expected function type" (List.cons "expected sort" (List.cons "failed to initialize quot module, Eq has an unexpected type" (List.cons "failed to initialize quot module, environment does not have Eq type" (List.cons "failed to initialize quot module, missing Eq constructor" (List.cons "failed to initialize quot module, quotient name is already declared" (List.cons "failed to initialize quot module, unexpected number of constructors for Eq type" (List.cons "failed to initialize quot module, unexpected number of universe params at Eq type" (List.cons "failed to initialize quot module, unexpected type for Eq constructor" (List.cons "failed to initialize quot module, unexpected universe params at Eq constructor" (List.cons "failed to restore nested inductive parameters" (List.cons "ill-formed nested inductive parameter instantiation" (List.cons "incorrect number of universe levels" (List.cons "inductive declaration name is already declared" (List.cons "invalid empty mutual definition" (List.cons "invalid mutual definition, declaration is not tagged as unsafe/partial" (List.cons "invalid mutual definition, declarations must have the same safety annotation" (List.cons "invalid mutual definition, declarations must have the same universe level parameters" (List.cons "invalid mutual definition, duplicate declaration name" (List.cons "invalid occurrence of datatype being declared: it must be applied to the parameters and universe levels of the mutual declaration" (List.cons "invalid outer mutual inductive metadata" (List.cons "invalid projection index" (List.cons "invalid projection: constructor metadata missing" (List.cons "invalid projection: constructor parameter is not a forall" (List.cons "invalid projection: inductive must have exactly one constructor" (List.cons "invalid projection: inductive type is not fully applied" (List.cons "invalid projection: missing structure parameter" (List.cons "invalid projection: projected expression type is not an inductive application" (List.cons "invalid projection: proof structure depends on data field" (List.cons "invalid projection: proof structure field is not a proposition" (List.cons "invalid projection: structure name is not inductive" (List.cons "invalid projection: structure type mismatch" (List.cons "invalid reference to undefined universe level parameter" (List.cons "kernel type checker does not support metavariables" (List.cons "let value type mismatch" (List.cons "loose bound variable in type checker" (List.cons "mutual constructor has invalid return type" (List.cons "mutual constructor returns the wrong datatype" (List.cons "mutual inductive admission requires at least two datatypes" (List.cons "mutual inductive constructor field universe is too large" (List.cons "mutual inductive field has a non-positive recursive occurrence" (List.cons "mutual inductive result must be a sort" (List.cons "mutual recursor rule count mismatch" (List.cons "mutually inductive types must live in the same universe" (List.cons "nested auxiliary recursor rename collides with an existing declaration" (List.cons "nested auxiliary recursor rename missing during validation" (List.cons "nested family head is not a constant" (List.cons "nested family head is not an inductive datatype" (List.cons "nested family selection failed" (List.cons "nested outer constructor metadata is missing" (List.cons "nested outer constructor name is outside its inductive namespace" (List.cons "nested preprocessing constructor parameter mismatch" (List.cons "nested template does not contain exactly the fixed outer parameters" (List.cons "opaque value type mismatch" (List.cons "outer mutual inductive parameters are inconsistent" (List.cons "recursive argument index contains a recursive occurrence" (List.cons "recursive function argument contains a negative recursive occurrence" (List.cons "reserved prefix '_nested' occurs in nested inductive constructor" (List.cons "reserved prefix '_nested' occurs in nested inductive declaration" (List.cons "safe declaration uses partial constant" (List.cons "safe declaration uses unsafe constant" (List.cons "simple inductive constructor field universe is too large" (List.cons "simple inductive constructor has fewer parameters than the datatype" (List.cons "simple inductive constructor must return the declared datatype with matching parameters and index arity" (List.cons "simple inductive constructor parameter does not match the datatype parameter" (List.cons "simple inductive constructor return index contains a recursive occurrence" (List.cons "simple inductive declaration has fewer parameters than declared" (List.cons "simple inductive result must be a sort" (List.cons "theorem proof type mismatch" (List.cons "theorem type is not a proposition" (List.cons "unknown constant" (List.cons "unknown free variable" List.nil))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))

def psKernelKnownUnsupportedDiagnostic (message : String) : Bool :=
  psKernelDiagnosticMember message (List.cons "nested or invalid mutual inductive occurrence is not supported" (List.cons "simple inductive admission does not yet support nested recursive occurrences" List.nil))


/- Exact diagnostic adaptation preserves all legacy messages. Unknown messages,
   including provider failures, conservatively fail closed as internalError. -/
def psKernelErrorFromMessage (message : String) : PsKernelError :=
  match psKernelResourceMessage message with
  | Option.some resource => PsKernelError.resourceExhausted resource message
  | Option.none =>
      if psKernelKnownUnsupportedDiagnostic message then
        PsKernelError.declinedUnsupported message
      else if psKernelKnownInvalidDiagnostic message then
        PsKernelError.rejectedInvalid message
      else PsKernelError.internalError message
