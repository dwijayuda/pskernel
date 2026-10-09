import Ps.Foundation.List
import Ps.Foundation.Name
import Ps.CompilerIr.Model

structure PsIrCheckIssue where
  code : String
  detail : String

structure PsIrCheckSignature where
  parameters : List PsVerifiedIrType
  resultType : PsVerifiedIrType

def psIrCheckIssue (code detail : String) : PsIrCheckIssue :=
  PsIrCheckIssue.mk code detail

def psIrCheckPrimitiveName (type : PsVerifiedIrPrimitiveType) : String :=
  match type with
  | .nat => "nat"
  | .int => "int"
  | .uint8 => "uint8"
  | .uint16 => "uint16"
  | .uint32 => "uint32"
  | .uint64 => "uint64"
  | .usize => "usize"
  | .int8 => "int8"
  | .int16 => "int16"
  | .int32 => "int32"
  | .int64 => "int64"
  | .isize => "isize"
  | .float => "float"
  | .float32 => "float32"
  | .bool => "bool"
  | .char => "char"
  | .string => "string"
  | .unit => "unit"

-- Optional scalar capabilities are outside the current active runtime contract.
def psIrCheckPrimitive (type : PsVerifiedIrPrimitiveType) :
    Except PsIrCheckIssue Unit :=
  match type with
  | .nat => Except.ok Unit.unit
  | .int => Except.ok Unit.unit
  | .bool => Except.ok Unit.unit
  | .char => Except.ok Unit.unit
  | .string => Except.ok Unit.unit
  | .unit => Except.ok Unit.unit
  | _ =>
      Except.error
        (psIrCheckIssue "scalar-capability-unqualified"
          (psIrCheckPrimitiveName type))

def psIrCheckContainsName (names : List String) (name : String) : Bool :=
  match names with
  | List.nil => false
  | List.cons candidate rest =>
      if psStringEq candidate name then true
      else psIrCheckContainsName rest name

-- Type work includes list cells as well as nested type nodes.
inductive PsIrCheckTypeTask where
  | type (value : PsVerifiedIrType)
  | types (values : List PsVerifiedIrType)
  | namedArguments
      (name : String)
      (remaining : Nat)
      (values : List PsVerifiedIrType)

def psIrCheckTypeWorker
    (namedArity : String -> Option Nat)
    (typeScope : List String)
    (fuel : Nat)
    (pending : List PsIrCheckTypeTask) : Except PsIrCheckIssue Unit :=
  match fuel with
  | Nat.zero =>
      match pending with
      | List.nil => Except.ok Unit.unit
      | List.cons _ _ =>
          Except.error (psIrCheckIssue "type-resource-limit" "wellformedness")
  | Nat.succ remaining =>
      match pending with
      | List.nil => Except.ok Unit.unit
      | List.cons task rest =>
          match task with
          | .type value =>
              match value with
              | .unknown =>
                  Except.error (psIrCheckIssue "unknown-type" "annotation")
              | .typeParameter name =>
                  if psIrCheckContainsName typeScope name then
                    psIrCheckTypeWorker namedArity typeScope remaining rest
                  else
                    Except.error
                      (psIrCheckIssue "unbound-type-parameter" name)
              | .primitive primitive =>
                  match psIrCheckPrimitive primitive with
                  | Except.error issue => Except.error issue
                  | Except.ok _ =>
                      psIrCheckTypeWorker namedArity typeScope remaining rest
              | .function parameters result =>
                  psIrCheckTypeWorker namedArity typeScope remaining
                    (List.cons (PsIrCheckTypeTask.types parameters)
                      (List.cons (PsIrCheckTypeTask.type result) rest))
              | .named name arguments =>
                  match namedArity name with
                  | Option.none =>
                      Except.error (psIrCheckIssue "unknown-named-type" name)
                  | Option.some arity =>
                      psIrCheckTypeWorker namedArity typeScope remaining
                        (List.cons
                          (PsIrCheckTypeTask.namedArguments name arity arguments)
                          rest)
          | .types values =>
              match values with
              | List.nil =>
                  psIrCheckTypeWorker namedArity typeScope remaining rest
              | List.cons value tail =>
                  psIrCheckTypeWorker namedArity typeScope remaining
                    (List.cons (PsIrCheckTypeTask.type value)
                      (List.cons (PsIrCheckTypeTask.types tail) rest))
          | .namedArguments name expected values =>
              match values with
              | List.nil =>
                  match expected with
                  | Nat.zero =>
                      psIrCheckTypeWorker namedArity typeScope remaining rest
                  | Nat.succ _ =>
                      Except.error (psIrCheckIssue "named-type-arity" name)
              | List.cons value tail =>
                  match expected with
                  | Nat.zero =>
                      Except.error (psIrCheckIssue "named-type-arity" name)
                  | Nat.succ next =>
                      psIrCheckTypeWorker namedArity typeScope remaining
                        (List.cons (PsIrCheckTypeTask.type value)
                          (List.cons
                            (PsIrCheckTypeTask.namedArguments name next tail)
                            rest))

def psIrCheckType
    (fuel : Nat)
    (namedArity : String -> Option Nat)
    (typeScope : List String)
    (type : PsVerifiedIrType) : Except PsIrCheckIssue Unit :=
  psIrCheckTypeWorker namedArity typeScope fuel
    (List.cons (PsIrCheckTypeTask.type type) List.nil)

inductive PsIrCheckEqualityTask where
  | types (left right : PsVerifiedIrType)
  | lists (left right : List PsVerifiedIrType)

def psIrCheckTypeIsUnknown (type : PsVerifiedIrType) : Bool :=
  match type with
  | .unknown => true
  | _ => false

def psIrCheckTypeEqualWorker
    (fuel : Nat)
    (pending : List PsIrCheckEqualityTask) : Except PsIrCheckIssue Bool :=
  match fuel with
  | Nat.zero =>
      match pending with
      | List.nil => Except.ok true
      | List.cons _ _ =>
          Except.error (psIrCheckIssue "type-resource-limit" "equality")
  | Nat.succ remaining =>
      match pending with
      | List.nil => Except.ok true
      | List.cons task rest =>
          match task with
          | .types left right =>
              if psIrCheckTypeIsUnknown left then
                Except.error (psIrCheckIssue "unknown-type" "equality-left")
              else if psIrCheckTypeIsUnknown right then
                Except.error (psIrCheckIssue "unknown-type" "equality-right")
              else
                match left with
                | .unknown =>
                    Except.error (psIrCheckIssue "unknown-type" "equality")
                | .typeParameter name =>
                    match right with
                    | .typeParameter other =>
                        if psStringEq name other then
                          psIrCheckTypeEqualWorker remaining rest
                        else Except.ok false
                    | _ => Except.ok false
                | .primitive primitive =>
                    match psIrCheckPrimitive primitive with
                    | Except.error issue => Except.error issue
                    | Except.ok _ =>
                        match right with
                        | .primitive other =>
                            match psIrCheckPrimitive other with
                            | Except.error issue => Except.error issue
                            | Except.ok _ =>
                                if psStringEq
                                    (psIrCheckPrimitiveName primitive)
                                    (psIrCheckPrimitiveName other) then
                                  psIrCheckTypeEqualWorker remaining rest
                                else Except.ok false
                        | _ => Except.ok false
                | .function parameters result =>
                    match right with
                    | .function otherParameters otherResult =>
                        psIrCheckTypeEqualWorker remaining
                          (List.cons
                            (PsIrCheckEqualityTask.lists
                              parameters otherParameters)
                            (List.cons
                              (PsIrCheckEqualityTask.types result otherResult)
                              rest))
                    | _ => Except.ok false
                | .named name arguments =>
                    match right with
                    | .named other otherArguments =>
                        if psStringEq name other then
                          psIrCheckTypeEqualWorker remaining
                            (List.cons
                              (PsIrCheckEqualityTask.lists
                                arguments otherArguments)
                              rest)
                        else Except.ok false
                    | _ => Except.ok false
          | .lists left right =>
              match left with
              | List.nil =>
                  match right with
                  | List.nil => psIrCheckTypeEqualWorker remaining rest
                  | List.cons _ _ => Except.ok false
              | List.cons value tail =>
                  match right with
                  | List.nil => Except.ok false
                  | List.cons other others =>
                      psIrCheckTypeEqualWorker remaining
                        (List.cons (PsIrCheckEqualityTask.types value other)
                          (List.cons
                            (PsIrCheckEqualityTask.lists tail others)
                            rest))

def psIrCheckTypeEqual
    (fuel : Nat)
    (left right : PsVerifiedIrType) : Except PsIrCheckIssue Bool :=
  psIrCheckTypeEqualWorker fuel
    (List.cons (PsIrCheckEqualityTask.types left right) List.nil)

def psIrCheckLookupSubstitution
    (substitutions : List (String × PsVerifiedIrType))
    (name : String) : Option PsVerifiedIrType :=
  match substitutions with
  | List.nil => Option.none
  | List.cons entry rest =>
      match entry with
      | Prod.mk key value =>
          if psStringEq key name then Option.some value
          else psIrCheckLookupSubstitution rest name

inductive PsIrCheckSubstitutionTask where
  | type (value : PsVerifiedIrType)
  | types (values : List PsVerifiedIrType)
  | function
  | named (name : String)
  | cons

inductive PsIrCheckSubstitutionValue where
  | type (value : PsVerifiedIrType)
  | types (values : List PsVerifiedIrType)

def psIrCheckSubstitutionInvariant : PsIrCheckIssue :=
  psIrCheckIssue "type-work-invariant" "substitution"

def psIrCheckSubstituteFinish
    (values : List PsIrCheckSubstitutionValue) :
    Except PsIrCheckIssue PsVerifiedIrType :=
  match values with
  | List.nil => Except.error psIrCheckSubstitutionInvariant
  | List.cons value rest =>
      match rest with
      | List.cons _ _ => Except.error psIrCheckSubstitutionInvariant
      | List.nil =>
          match value with
          | .type type => Except.ok type
          | .types _ => Except.error psIrCheckSubstitutionInvariant

def psIrCheckSubstituteWorker
    (substitutions : List (String × PsVerifiedIrType))
    (fuel : Nat)
    (pending : List PsIrCheckSubstitutionTask)
    (values : List PsIrCheckSubstitutionValue) :
    Except PsIrCheckIssue PsVerifiedIrType :=
  match fuel with
  | Nat.zero =>
      match pending with
      | List.nil => psIrCheckSubstituteFinish values
      | List.cons _ _ =>
          Except.error (psIrCheckIssue "type-resource-limit" "substitution")
  | Nat.succ remaining =>
      match pending with
      | List.nil => psIrCheckSubstituteFinish values
      | List.cons task rest =>
          match task with
          | .type value =>
              match value with
              | .unknown =>
                  Except.error (psIrCheckIssue "unknown-type" "substitution")
              | .typeParameter name =>
                  match psIrCheckLookupSubstitution substitutions name with
                  | Option.none =>
                      Except.error
                        (psIrCheckIssue "type-substitution-unbound" name)
                  | Option.some replacement =>
                      psIrCheckSubstituteWorker substitutions remaining rest
                        (List.cons
                          (PsIrCheckSubstitutionValue.type replacement)
                          values)
              | .primitive primitive =>
                  match psIrCheckPrimitive primitive with
                  | Except.error issue => Except.error issue
                  | Except.ok _ =>
                      psIrCheckSubstituteWorker substitutions remaining rest
                        (List.cons (PsIrCheckSubstitutionValue.type value) values)
              | .function parameters result =>
                  psIrCheckSubstituteWorker substitutions remaining
                    (List.cons (PsIrCheckSubstitutionTask.types parameters)
                      (List.cons (PsIrCheckSubstitutionTask.type result)
                        (List.cons PsIrCheckSubstitutionTask.function rest)))
                    values
              | .named name arguments =>
                  psIrCheckSubstituteWorker substitutions remaining
                    (List.cons (PsIrCheckSubstitutionTask.types arguments)
                      (List.cons (PsIrCheckSubstitutionTask.named name) rest))
                    values
          | .types types =>
              match types with
              | List.nil =>
                  psIrCheckSubstituteWorker substitutions remaining rest
                    (List.cons (PsIrCheckSubstitutionValue.types List.nil) values)
              | List.cons value tail =>
                  psIrCheckSubstituteWorker substitutions remaining
                    (List.cons (PsIrCheckSubstitutionTask.type value)
                      (List.cons (PsIrCheckSubstitutionTask.types tail)
                        (List.cons PsIrCheckSubstitutionTask.cons rest)))
                    values
          | .function =>
              match values with
              | List.nil => Except.error psIrCheckSubstitutionInvariant
              | List.cons result afterResult =>
                  match result with
                  | .types _ => Except.error psIrCheckSubstitutionInvariant
                  | .type resultType =>
                      match afterResult with
                      | List.nil => Except.error psIrCheckSubstitutionInvariant
                      | List.cons parameters tail =>
                          match parameters with
                          | .type _ =>
                              Except.error psIrCheckSubstitutionInvariant
                          | .types parameterTypes =>
                              psIrCheckSubstituteWorker substitutions remaining rest
                                (List.cons
                                  (PsIrCheckSubstitutionValue.type
                                    (PsVerifiedIrType.function
                                      parameterTypes resultType))
                                  tail)
          | .named name =>
              match values with
              | List.nil => Except.error psIrCheckSubstitutionInvariant
              | List.cons arguments tail =>
                  match arguments with
                  | .type _ => Except.error psIrCheckSubstitutionInvariant
                  | .types argumentTypes =>
                      psIrCheckSubstituteWorker substitutions remaining rest
                        (List.cons
                          (PsIrCheckSubstitutionValue.type
                            (PsVerifiedIrType.named name argumentTypes))
                          tail)
          | .cons =>
              match values with
              | List.nil => Except.error psIrCheckSubstitutionInvariant
              | List.cons tailValue afterTail =>
                  match tailValue with
                  | .type _ => Except.error psIrCheckSubstitutionInvariant
                  | .types tailTypes =>
                      match afterTail with
                      | List.nil => Except.error psIrCheckSubstitutionInvariant
                      | List.cons headValue tail =>
                          match headValue with
                          | .types _ =>
                              Except.error psIrCheckSubstitutionInvariant
                          | .type headType =>
                              psIrCheckSubstituteWorker substitutions remaining rest
                                (List.cons
                                  (PsIrCheckSubstitutionValue.types
                                    (List.cons headType tailTypes))
                                  tail)

-- The caller validates the source scheme and the replacement types in their own scopes.
-- A selected replacement is returned directly and is never substituted again.
def psIrCheckSubstitute
    (fuel : Nat)
    (substitutions : List (String × PsVerifiedIrType))
    (type : PsVerifiedIrType) : Except PsIrCheckIssue PsVerifiedIrType :=
  psIrCheckSubstituteWorker substitutions fuel
    (List.cons (PsIrCheckSubstitutionTask.type type) List.nil)
    List.nil

def psIrCheckLiteralType
    (literal : PsVerifiedIrLiteral) :
    Except PsIrCheckIssue PsVerifiedIrType :=
  match literal with
  | .natural _ =>
      Except.ok (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
  | .integer _ =>
      Except.ok (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int)
  | .machineInteger _ _ =>
      Except.error
        (psIrCheckIssue "scalar-capability-unqualified" "machine-integer-literal")
  | .string _ =>
      Except.ok (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.string)
  | .bool _ =>
      Except.ok (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool)
  | .unit =>
      Except.ok (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.unit)

def psIrCheckSignatureNoTypes
    (typeArguments : List PsVerifiedIrType)
    (parameters : List PsVerifiedIrType)
    (resultType : PsVerifiedIrType) :
    Except PsIrCheckIssue PsIrCheckSignature :=
  match typeArguments with
  | List.nil => Except.ok (PsIrCheckSignature.mk parameters resultType)
  | List.cons _ _ =>
      Except.error
        (psIrCheckIssue "intrinsic-type-arity" "expected-zero")

def psIrCheckSignatureOneType
    (typeArguments : List PsVerifiedIrType)
    (build : PsVerifiedIrType -> PsIrCheckSignature) :
    Except PsIrCheckIssue PsIrCheckSignature :=
  match typeArguments with
  | List.nil =>
      Except.error (psIrCheckIssue "intrinsic-type-arity" "expected-one")
  | List.cons argument rest =>
      match rest with
      | List.nil => Except.ok (build argument)
      | List.cons _ _ =>
          Except.error (psIrCheckIssue "intrinsic-type-arity" "expected-one")

def psIrCheckSignatureTwoTypes
    (typeArguments : List PsVerifiedIrType)
    (build : PsVerifiedIrType -> PsVerifiedIrType -> PsIrCheckSignature) :
    Except PsIrCheckIssue PsIrCheckSignature :=
  match typeArguments with
  | List.nil =>
      Except.error (psIrCheckIssue "intrinsic-type-arity" "expected-two")
  | List.cons first rest =>
      match rest with
      | List.nil =>
          Except.error (psIrCheckIssue "intrinsic-type-arity" "expected-two")
      | List.cons second tail =>
          match tail with
          | List.nil => Except.ok (build first second)
          | List.cons _ _ =>
              Except.error
                (psIrCheckIssue "intrinsic-type-arity" "expected-two")

def psIrCheckArrayType (element : PsVerifiedIrType) : PsVerifiedIrType :=
  PsVerifiedIrType.named "Array" [element]

-- The caller validates type arguments in the current scope before this operation.
-- Function parameter grouping is part of each intrinsic signature.
def psIrCheckIntrinsicSignature
    (operation : PsVerifiedIrIntrinsic)
    (typeArguments : List PsVerifiedIrType) :
    Except PsIrCheckIssue PsIrCheckSignature :=
  let nat := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat;
  let int := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int;
  let bool := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool;
  let char := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.char;
  let string := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.string;
  match operation with
  | .machineIntBinary _ _ =>
      Except.error
        (psIrCheckIssue "scalar-capability-unqualified" "machine-integer-operation")
  | .machineIntCompare _ _ =>
      Except.error
        (psIrCheckIssue "scalar-capability-unqualified" "machine-integer-operation")
  | .floatBinary _ _ =>
      Except.error (psIrCheckIssue "scalar-capability-unqualified" "floating-operation")
  | .floatCompare _ _ =>
      Except.error (psIrCheckIssue "scalar-capability-unqualified" "floating-operation")
  | .natAdd => psIrCheckSignatureNoTypes typeArguments [nat, nat] nat
  | .natSub => psIrCheckSignatureNoTypes typeArguments [nat, nat] nat
  | .natMul => psIrCheckSignatureNoTypes typeArguments [nat, nat] nat
  | .natDiv => psIrCheckSignatureNoTypes typeArguments [nat, nat] nat
  | .natMod => psIrCheckSignatureNoTypes typeArguments [nat, nat] nat
  | .natEq => psIrCheckSignatureNoTypes typeArguments [nat, nat] bool
  | .natNe => psIrCheckSignatureNoTypes typeArguments [nat, nat] bool
  | .natLe => psIrCheckSignatureNoTypes typeArguments [nat, nat] bool
  | .natLt => psIrCheckSignatureNoTypes typeArguments [nat, nat] bool
  | .intOfNat => psIrCheckSignatureNoTypes typeArguments [nat] int
  | .intRepr => psIrCheckSignatureNoTypes typeArguments [int] string
  | .intNegSucc => psIrCheckSignatureNoTypes typeArguments [nat] int
  | .intNeg => psIrCheckSignatureNoTypes typeArguments [int] int
  | .intAdd => psIrCheckSignatureNoTypes typeArguments [int, int] int
  | .intSub => psIrCheckSignatureNoTypes typeArguments [int, int] int
  | .intMul => psIrCheckSignatureNoTypes typeArguments [int, int] int
  | .intEq => psIrCheckSignatureNoTypes typeArguments [int, int] bool
  | .intLe => psIrCheckSignatureNoTypes typeArguments [int, int] bool
  | .intLt => psIrCheckSignatureNoTypes typeArguments [int, int] bool
  | .boolNot => psIrCheckSignatureNoTypes typeArguments [bool] bool
  | .boolAnd => psIrCheckSignatureNoTypes typeArguments [bool, bool] bool
  | .boolOr => psIrCheckSignatureNoTypes typeArguments [bool, bool] bool
  | .boolEq => psIrCheckSignatureNoTypes typeArguments [bool, bool] bool
  | .boolNe => psIrCheckSignatureNoTypes typeArguments [bool, bool] bool
  | .charOfNat => psIrCheckSignatureNoTypes typeArguments [nat] char
  | .charToNat => psIrCheckSignatureNoTypes typeArguments [char] nat
  | .stringPush => psIrCheckSignatureNoTypes typeArguments [string, char] string
  | .stringSingleton => psIrCheckSignatureNoTypes typeArguments [char] string
  | .stringLength => psIrCheckSignatureNoTypes typeArguments [string] nat
  | .stringAppend => psIrCheckSignatureNoTypes typeArguments [string, string] string
  | .stringUtf8ByteSize => psIrCheckSignatureNoTypes typeArguments [string] nat
  | .stringNext => psIrCheckSignatureNoTypes typeArguments [string, nat] nat
  | .stringGet => psIrCheckSignatureNoTypes typeArguments [string, nat] char
  | .stringAtEnd => psIrCheckSignatureNoTypes typeArguments [string, nat] bool
  | .stringExtract => psIrCheckSignatureNoTypes typeArguments [string, nat, nat] string
  | .stringEq => psIrCheckSignatureNoTypes typeArguments [string, string] bool
  | .arrayEmptyWithCapacity =>
      psIrCheckSignatureOneType typeArguments
        (fun (element : PsVerifiedIrType) =>
          PsIrCheckSignature.mk [nat] (psIrCheckArrayType element))
  | .arraySize =>
      psIrCheckSignatureOneType typeArguments
        (fun (element : PsVerifiedIrType) =>
          PsIrCheckSignature.mk [psIrCheckArrayType element] nat)
  | .arrayPush =>
      psIrCheckSignatureOneType typeArguments
        (fun (element : PsVerifiedIrType) =>
          PsIrCheckSignature.mk [psIrCheckArrayType element, element]
            (psIrCheckArrayType element))
  | .arrayGet =>
      psIrCheckSignatureOneType typeArguments
        (fun (element : PsVerifiedIrType) =>
          PsIrCheckSignature.mk [psIrCheckArrayType element, nat] element)
  | .arrayGetD =>
      psIrCheckSignatureOneType typeArguments
        (fun (element : PsVerifiedIrType) =>
          PsIrCheckSignature.mk [psIrCheckArrayType element, nat, element] element)
  | .arraySet =>
      psIrCheckSignatureOneType typeArguments
        (fun (element : PsVerifiedIrType) =>
          PsIrCheckSignature.mk [psIrCheckArrayType element, nat, element]
            (psIrCheckArrayType element))
  | .arraySetIfInBounds =>
      psIrCheckSignatureOneType typeArguments
        (fun (element : PsVerifiedIrType) =>
          PsIrCheckSignature.mk [psIrCheckArrayType element, nat, element]
            (psIrCheckArrayType element))
  | .arrayMap =>
      psIrCheckSignatureTwoTypes typeArguments
        (fun (element result : PsVerifiedIrType) =>
          PsIrCheckSignature.mk
            [PsVerifiedIrType.function [element] result, psIrCheckArrayType element]
            (psIrCheckArrayType result))
  | .arrayFoldl =>
      psIrCheckSignatureTwoTypes typeArguments
        (fun (element accumulator : PsVerifiedIrType) =>
          PsIrCheckSignature.mk
            [PsVerifiedIrType.function [accumulator, element] accumulator,
              accumulator, psIrCheckArrayType element, nat, nat]
            accumulator)
