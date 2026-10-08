import Ps.CompilerIr.PublicApi
import Ps.Foundation.List

-- Logical owner: public-api. This syntactic projection reads only source Core
-- signatures. It neither normalizes types nor inspects erased/target code.
inductive PsSourceScalarType where
  | nat
  | int
  | uint8
  | uint16
  | uint32
  | uint64
  | usize
  | int8
  | int16
  | int32
  | int64
  | isize
  | float
  | float32
  | bool
  | char
  | string
  | unit

inductive PsSourceSignatureType where
  | scalar (type : PsSourceScalarType)
  | parameter (index : Nat)
  | array (element : PsSourceSignatureType)
  | function (parameters : List PsSourceSignatureType) (result : PsSourceSignatureType)

structure PsSourceSignatureParameter where
  sourceName : PsName
  binderInfo : PsBinderInfo
  index : Nat

structure PsSourceSignature where
  typeParameters : List PsSourceSignatureParameter
  type : PsSourceSignatureType

inductive PsSourceSignatureError where
  | resourcePolicy
  | resourceExhausted
  | namedTypeUnsupported
  | dependentValueTypeUnsupported
  | higherRankTypeUnsupported
  | propositionOrAmbiguousSort
  | typeFormUnsupported
  | internalStack

inductive PsSourceSignatureBinding where
  | typeParameter (index : Nat)
  | valueParameter

def psSourceSignatureRootText (name : PsName) : Option String :=
  match name with
  | PsName.str parent text =>
      match parent with
      | PsName.anonymous => Option.some text
      | _ => Option.none
  | _ => Option.none

def psSourceSignatureScalar (name : PsName) : Option PsSourceScalarType :=
  match psSourceSignatureRootText name with
  | Option.none => Option.none
  | Option.some text =>
      if psStringEq text "Nat" then Option.some PsSourceScalarType.nat
      else if psStringEq text "Int" then Option.some PsSourceScalarType.int
      else if psStringEq text "UInt8" then Option.some PsSourceScalarType.uint8
      else if psStringEq text "UInt16" then Option.some PsSourceScalarType.uint16
      else if psStringEq text "UInt32" then Option.some PsSourceScalarType.uint32
      else if psStringEq text "UInt64" then Option.some PsSourceScalarType.uint64
      else if psStringEq text "USize" then Option.some PsSourceScalarType.usize
      else if psStringEq text "Int8" then Option.some PsSourceScalarType.int8
      else if psStringEq text "Int16" then Option.some PsSourceScalarType.int16
      else if psStringEq text "Int32" then Option.some PsSourceScalarType.int32
      else if psStringEq text "Int64" then Option.some PsSourceScalarType.int64
      else if psStringEq text "ISize" then Option.some PsSourceScalarType.isize
      else if psStringEq text "Float" then Option.some PsSourceScalarType.float
      else if psStringEq text "Float32" then Option.some PsSourceScalarType.float32
      else if psStringEq text "Bool" then Option.some PsSourceScalarType.bool
      else if psStringEq text "Char" then Option.some PsSourceScalarType.char
      else if psStringEq text "String" then Option.some PsSourceScalarType.string
      else if psStringEq text "Unit" then Option.some PsSourceScalarType.unit
      else Option.none

def psSourceSignatureArrayHead (expression : PsExpr) : Bool :=
  match expression with
  | PsExpr.constE name levels =>
      match levels with
      | List.nil =>
          match psSourceSignatureRootText name with
          | Option.none => false
          | Option.some text => psStringEq text "Array"
      | List.cons _ _ => false
  | _ => false

def psSourceSignatureBindingAt
    (scope : List PsSourceSignatureBinding) : Nat -> Option PsSourceSignatureBinding :=
  match scope with
  | List.nil => fun (_index : Nat) => Option.none
  | List.cons binding rest =>
      let smaller : Nat -> Option PsSourceSignatureBinding :=
        psSourceSignatureBindingAt rest;
      fun (index : Nat) =>
        if Nat.beq index 0 then Option.some binding
        else smaller (Nat.sub index 1)

structure PsSourceSignaturePrefix where
  body : PsExpr
  parametersRev : List PsSourceSignatureParameter
  scope : List PsSourceSignatureBinding
  count : Nat

def psSourceSignaturePrefixWorker
    (maxDepth : Nat) (fuel : Nat) :
    PsSourceSignaturePrefix -> Except PsSourceSignatureError PsSourceSignaturePrefix :=
  match fuel with
  | Nat.zero =>
      fun (_state : PsSourceSignaturePrefix) =>
        Except.error PsSourceSignatureError.resourceExhausted
  | Nat.succ remaining =>
      let smaller :
          PsSourceSignaturePrefix -> Except PsSourceSignatureError PsSourceSignaturePrefix :=
        psSourceSignaturePrefixWorker maxDepth remaining;
      fun (state : PsSourceSignaturePrefix) =>
        match state.body with
        | PsExpr.forallE name type body binder =>
            match type with
            | PsExpr.sortE level =>
                if Nat.blt state.count maxDepth then
                  match level with
                  | PsLevel.succ _ =>
                      smaller
                        (PsSourceSignaturePrefix.mk
                          body
                          (List.cons
                            (PsSourceSignatureParameter.mk name binder state.count)
                            state.parametersRev)
                          (List.cons (PsSourceSignatureBinding.typeParameter state.count) state.scope)
                          (Nat.succ state.count))
                  | _ => Except.error PsSourceSignatureError.propositionOrAmbiguousSort
                else
                  Except.error PsSourceSignatureError.resourceExhausted
            | _ => Except.ok state
        | _ => Except.ok state

-- Continuations are data; native and self-hosted execution need no source-type
-- call stack. Scope markers distinguish a type binder from a dependent value.
inductive PsSourceSignatureTask where
  | project (expression : PsExpr) (scope : List PsSourceSignatureBinding) (depth : Nat)
  | arrayDone
  | functionNext
      (body : PsExpr) (scope : List PsSourceSignatureBinding) (depth : Nat)
      (parametersRev : List PsSourceSignatureType)
  | parameterDone
      (body : PsExpr) (scope : List PsSourceSignatureBinding) (depth : Nat)
      (parametersRev : List PsSourceSignatureType)
  | functionDone (parametersRev : List PsSourceSignatureType)

structure PsSourceSignatureState where
  tasks : List PsSourceSignatureTask
  values : List PsSourceSignatureType

def psSourceSignatureProjectStep
    (maxDepth : Nat) (expression : PsExpr)
    (scope : List PsSourceSignatureBinding) (depth : Nat)
    (rest : List PsSourceSignatureTask) (values : List PsSourceSignatureType) :
    Except PsSourceSignatureError PsSourceSignatureState :=
  if Nat.ble depth maxDepth then
    match expression with
    | PsExpr.constE name levels =>
        match levels with
        | List.nil =>
            match psSourceSignatureScalar name with
            | Option.none => Except.error PsSourceSignatureError.namedTypeUnsupported
            | Option.some scalar =>
                Except.ok (PsSourceSignatureState.mk rest (List.cons (PsSourceSignatureType.scalar scalar) values))
        | List.cons _ _ => Except.error PsSourceSignatureError.namedTypeUnsupported
    | PsExpr.bvar index =>
        match psSourceSignatureBindingAt scope index with
        | Option.none => Except.error PsSourceSignatureError.dependentValueTypeUnsupported
        | Option.some binding =>
            match binding with
            | PsSourceSignatureBinding.typeParameter parameter =>
                Except.ok (PsSourceSignatureState.mk rest (List.cons (PsSourceSignatureType.parameter parameter) values))
            | PsSourceSignatureBinding.valueParameter =>
                Except.error PsSourceSignatureError.dependentValueTypeUnsupported
    | PsExpr.app head element =>
        if psSourceSignatureArrayHead head then
          Except.ok
            (PsSourceSignatureState.mk
              (List.cons (PsSourceSignatureTask.project element scope (Nat.succ depth))
                (List.cons PsSourceSignatureTask.arrayDone rest))
              values)
        else Except.error PsSourceSignatureError.typeFormUnsupported
    | PsExpr.forallE _ _ _ _ =>
        Except.ok
          (PsSourceSignatureState.mk
            (List.cons (PsSourceSignatureTask.functionNext expression scope depth List.nil) rest)
            values)
    | _ => Except.error PsSourceSignatureError.typeFormUnsupported
  else Except.error PsSourceSignatureError.resourceExhausted

def psSourceSignatureFunctionStep
    (maxDepth : Nat) (body : PsExpr)
    (scope : List PsSourceSignatureBinding) (depth : Nat)
    (parametersRev : List PsSourceSignatureType)
    (rest : List PsSourceSignatureTask) (values : List PsSourceSignatureType) :
    Except PsSourceSignatureError PsSourceSignatureState :=
  match body with
  | PsExpr.forallE _ type tail _ =>
      if Nat.blt (psListLength scope) maxDepth then
        match type with
        | PsExpr.sortE _ => Except.error PsSourceSignatureError.higherRankTypeUnsupported
        | _ =>
            Except.ok
              (PsSourceSignatureState.mk
                (List.cons (PsSourceSignatureTask.project type scope (Nat.succ depth))
                  (List.cons (PsSourceSignatureTask.parameterDone tail scope depth parametersRev) rest))
                values)
      else Except.error PsSourceSignatureError.resourceExhausted
  | _ =>
      Except.ok
        (PsSourceSignatureState.mk
          (List.cons (PsSourceSignatureTask.project body scope (Nat.succ depth))
            (List.cons (PsSourceSignatureTask.functionDone parametersRev) rest))
          values)

def psSourceSignatureStep
    (maxDepth : Nat) (task : PsSourceSignatureTask)
    (rest : List PsSourceSignatureTask) (values : List PsSourceSignatureType) :
    Except PsSourceSignatureError PsSourceSignatureState :=
  match task with
  | PsSourceSignatureTask.project expression scope depth =>
      psSourceSignatureProjectStep maxDepth expression scope depth rest values
  | PsSourceSignatureTask.functionNext body scope depth parametersRev =>
      psSourceSignatureFunctionStep maxDepth body scope depth parametersRev rest values
  | PsSourceSignatureTask.arrayDone =>
      match values with
      | List.cons element tail =>
          Except.ok (PsSourceSignatureState.mk rest (List.cons (PsSourceSignatureType.array element) tail))
      | _ => Except.error PsSourceSignatureError.internalStack
  | PsSourceSignatureTask.parameterDone body scope depth parametersRev =>
      match values with
      | List.cons parameter tail =>
          Except.ok
            (PsSourceSignatureState.mk
              (List.cons
                (PsSourceSignatureTask.functionNext body
                  (List.cons PsSourceSignatureBinding.valueParameter scope)
                  depth (List.cons parameter parametersRev)) rest)
              tail)
      | _ => Except.error PsSourceSignatureError.internalStack
  | PsSourceSignatureTask.functionDone parametersRev =>
      match values with
      | List.cons result tail =>
          Except.ok
            (PsSourceSignatureState.mk rest
              (List.cons (PsSourceSignatureType.function (psListReverse parametersRev) result) tail))
      | _ => Except.error PsSourceSignatureError.internalStack

def psSourceSignatureWorker
    (maxDepth : Nat) (fuel : Nat) :
    PsSourceSignatureState -> Except PsSourceSignatureError PsSourceSignatureType :=
  match fuel with
  | Nat.zero =>
      fun (_state : PsSourceSignatureState) =>
        Except.error PsSourceSignatureError.resourceExhausted
  | Nat.succ remaining =>
      let smaller :
          PsSourceSignatureState -> Except PsSourceSignatureError PsSourceSignatureType :=
        psSourceSignatureWorker maxDepth remaining;
      fun (state : PsSourceSignatureState) =>
        match state.tasks with
        | List.nil =>
            match state.values with
            | List.nil => Except.error PsSourceSignatureError.internalStack
            | List.cons result tail =>
                match tail with
                | List.nil => Except.ok result
                | List.cons _ _ => Except.error PsSourceSignatureError.internalStack
        | List.cons task rest =>
            match psSourceSignatureStep maxDepth task rest state.values with
            | Except.error error => Except.error error
            | Except.ok next => smaller next

def psProjectSourceSignatureWithLimits
    (maxSteps maxDepth : Nat) (expression : PsExpr) :
    Except PsSourceSignatureError PsSourceSignature :=
  if Nat.beq maxSteps 0 then Except.error PsSourceSignatureError.resourcePolicy
  else if Nat.beq maxDepth 0 then Except.error PsSourceSignatureError.resourcePolicy
  else if Nat.blt 128 maxDepth then Except.error PsSourceSignatureError.resourcePolicy
  else
    match
        psSourceSignaturePrefixWorker maxDepth (Nat.succ maxDepth)
          (PsSourceSignaturePrefix.mk expression List.nil List.nil 0) with
    | Except.error error => Except.error error
    | Except.ok prefixState =>
        match
            psSourceSignatureWorker maxDepth maxSteps
              (PsSourceSignatureState.mk
                (List.cons (PsSourceSignatureTask.project prefixState.body prefixState.scope 0) List.nil)
                List.nil) with
        | Except.error error => Except.error error
        | Except.ok type =>
            Except.ok (PsSourceSignature.mk (psListReverse prefixState.parametersRev) type)

def psProjectSourceSignature (expression : PsExpr) :
    Except PsSourceSignatureError PsSourceSignature :=
  psProjectSourceSignatureWithLimits 400000 128 expression
