import Ps.BackendTs.Module
import Ps.Erasure.Basic

-- Source-owned TS target admission, after complete original-IR typing.
-- This is not an erasure-preservation proof and accepts no caller report token.
-- maxSteps bounds worklist visits, including identifier characters. Existing
-- immutable name indexes and String/Nat primitives have separate finite costs.
-- A weighted 4096 expression/type-depth domain protects the emitter's bounded
-- name scans, including its top-level eta-to-let rewrite.

def psSh1TargetPolicy : String := "psc0-sh1-ts-target/1"

structure PsSh1TargetError where
  code : String
  detail : String
  owner : String
  path : String
  visitedSteps : Nat

structure PsSh1TargetReport where
  policy : String
  accepted : Bool
  traversalComplete : Bool
  visitedSteps : Nat

inductive PsSh1TargetNameRole where
  | globalValue
  | globalType
  | globalBoth
  | localValue
  | localType
  | reference
  | property
  | quotedProperty

structure PsSh1TargetScope where
  owner : String
  path : String
  earlier : PsErasureNameIndex Bool
  locals : PsErasureNameIndex Bool
  selfName : String
  selfFunction : Bool

inductive PsSh1TargetTask where
  | noImports (imports : List PsVerifiedIrExternalImport)
  | collectStructures (items : List PsVerifiedIrStructure)
  | collectInductives (items : List PsVerifiedIrInductive)
  | collectDeclarations (items : List PsVerifiedIrDeclaration)
  | addGlobal (scope : PsSh1TargetScope) (name : String) (isType : Bool)
  | brandNames (items : List PsVerifiedIrStructure) (index : Nat)
  | tagNames (items : List PsVerifiedIrInductive) (index : Nat)
  | implementationNames (items : List PsVerifiedIrDeclaration)
  | addPrivate (scope : PsSh1TargetScope) (name : String)
  | name
      (scope : PsSh1TargetScope) (role : PsSh1TargetNameRole) (value : String)
  | nameChars
      (scope : PsSh1TargetScope) (role : PsSh1TargetNameRole)
      (value : String) (position : Nat) (first : Bool)
  | structures (items : List PsVerifiedIrStructure)
  | inductives (items : List PsVerifiedIrInductive)
  | structureFields
      (scope : PsSh1TargetScope) (items : List PsVerifiedIrStructureField) (index : Nat)
  | constructors
      (scope : PsSh1TargetScope) (items : List PsVerifiedIrConstructor) (index : Nat)
  | constructorFields
      (scope : PsSh1TargetScope) (items : List PsVerifiedIrConstructorField) (index : Nat)
  | typeParameters
      (scope : PsSh1TargetScope) (items : List PsVerifiedIrTypeParameter) (index : Nat)
  | declarations
      (earlier : PsErasureNameIndex Bool) (items : List PsVerifiedIrDeclaration)
  | parameters
      (scope : PsSh1TargetScope) (depth : Nat) (weighted : Bool)
      (items : List PsVerifiedIrParameter) (index : Nat)
      (resultType : PsVerifiedIrType) (body : PsVerifiedIrExpr)
  | runtimeType (scope : PsSh1TargetScope) (depth : Nat) (value : PsVerifiedIrType)
  | runtimeTypes
      (scope : PsSh1TargetScope) (depth : Nat) (items : List PsVerifiedIrType) (index : Nat)
  | expression (scope : PsSh1TargetScope) (depth : Nat) (value : PsVerifiedIrExpr)
  | expressions
      (scope : PsSh1TargetScope) (depth : Nat) (items : List PsVerifiedIrExpr) (index : Nat)
  | readVariable (scope : PsSh1TargetScope) (name : String)
  | expressionFields
      (scope : PsSh1TargetScope) (depth : Nat)
      (items : List (Prod String PsVerifiedIrExpr)) (index : Nat)
  | alternatives
      (scope : PsSh1TargetScope) (depth : Nat)
      (items : List (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)))
      (index : Nat)
  | matchBindings
      (scope : PsSh1TargetScope) (depth : Nat)
      (items : List PsVerifiedIrMatchBinding) (index : Nat) (body : PsVerifiedIrExpr)

structure PsSh1TargetState where
  tasks : List PsSh1TargetTask
  globals : PsErasureNameIndex Bool
  privateNames : PsErasureNameIndex Bool
  visitedSteps : Nat

def psSh1TargetEmptyNames : PsErasureNameIndex Bool :=
  PsErasureNameIndex.empty

def psSh1TargetHasName
    (entries : PsErasureNameIndex Bool) (name : String) : Bool :=
  match psErasureIndexFind Bool entries (PsName.str PsName.anonymous name) with
  | Option.none => false
  | Option.some _ => true

def psSh1TargetIsGlobalType
    (entries : PsErasureNameIndex Bool) (name : String) : Bool :=
  match psErasureIndexFind Bool entries (PsName.str PsName.anonymous name) with
  | Option.none => false
  | Option.some isType => isType

def psSh1TargetInsertName
    (entries : PsErasureNameIndex Bool) (name : String) : PsErasureNameIndex Bool :=
  psErasureIndexInsert Bool entries (PsName.str PsName.anonymous name) true

def psSh1TargetRootScope (owner : String) : PsSh1TargetScope :=
  PsSh1TargetScope.mk owner "target" psSh1TargetEmptyNames psSh1TargetEmptyNames "" false

def psSh1TargetAt (scope : PsSh1TargetScope) (part : String) : PsSh1TargetScope :=
  PsSh1TargetScope.mk scope.owner
    (String.Internal.append scope.path (String.Internal.append "." part))
    scope.earlier scope.locals scope.selfName scope.selfFunction

def psSh1TargetAtIndex
    (scope : PsSh1TargetScope) (part : String) (index : Nat) : PsSh1TargetScope :=
  psSh1TargetAt scope (String.Internal.append part (psNatToString index))

def psSh1TargetWithLocal
    (scope : PsSh1TargetScope) (name : String) : PsSh1TargetScope :=
  PsSh1TargetScope.mk scope.owner scope.path scope.earlier
    (psSh1TargetInsertName scope.locals name) scope.selfName scope.selfFunction

def psSh1TargetSchedule
    (state : PsSh1TargetState) (tasks : List PsSh1TargetTask) : PsSh1TargetState :=
  PsSh1TargetState.mk (psListAppend tasks state.tasks)
    state.globals state.privateNames state.visitedSteps

def psSh1TargetErrorAt
    (state : PsSh1TargetState) (scope : PsSh1TargetScope)
    (code detail : String) : PsSh1TargetError :=
  PsSh1TargetError.mk code detail scope.owner scope.path state.visitedSteps

def psSh1TargetStringIn (items : List String) (value : String) : Bool :=
  match items with
  | List.nil => false
  | List.cons item rest =>
      if psStringEq item value then true else psSh1TargetStringIn rest value

def psSh1TargetKeyword (value : String) : Bool :=
  psSh1TargetStringIn
    ["await", "break", "case", "catch", "class", "const", "continue",
     "debugger", "default", "delete", "do", "else", "enum", "export",
     "extends", "false", "finally", "for", "function", "if", "implements",
     "import", "in", "instanceof", "interface", "let", "new", "null",
     "package", "private", "protected", "public", "return", "static",
     "super", "switch", "this", "throw", "true", "try", "typeof", "var",
     "void", "while", "with", "yield", "arguments", "eval"] value

def psSh1TargetTypeKeyword (value : String) : Bool :=
  psSh1TargetStringIn
    ["any", "unknown", "never", "number", "bigint", "boolean", "string",
     "symbol", "object", "undefined", "intrinsic"] value

-- Actual unqualified names emitted by the enabled expression templates.
-- IIFE-local __ps_a / __ps_i / __field0 names are deliberately not reserved:
-- source expressions are their arguments, outside those local binder scopes.
def psSh1TargetExpressionGlobal (value : String) : Bool :=
  psSh1TargetStringIn ["Array", "BigInt", "Number", "String", "Error", "undefined"] value

-- Actual additional names used by the module runtime and its TS annotations.
def psSh1TargetModuleGlobal (value : String) : Bool :=
  if psSh1TargetExpressionGlobal value then true else
    psSh1TargetStringIn
      ["Symbol", "WeakMap", "Reflect", "Uint32Array", "Function", "Generator"] value

def psSh1TargetRuntimeName (value : String) : Bool :=
  psSh1TargetStringIn
    ["__ps$Request", "__ps$Computation", "__ps$implementations", "__ps$run",
     "__ps$wrap", "__ps$invoke", "__ps$Utf8View", "__ps$lastUtf8",
     "__ps$previousUtf8", "__ps$utf8Width", "__ps$utf8",
     "__ps$stringGet", "__ps$stringNext", "__ps$count", "__ps$cursor",
     "__ps$match$0"] value

def psSh1TargetRoleIsGlobal (role : PsSh1TargetNameRole) : Bool :=
  match role with
  | .globalValue => true
  | .globalType => true
  | .globalBoth => true
  | _ => false

def psSh1TargetRoleIsType (role : PsSh1TargetNameRole) : Bool :=
  match role with
  | .globalType => true
  | .globalBoth => true
  | .localType => true
  | _ => false

def psSh1TargetRoleIsBinding (role : PsSh1TargetNameRole) : Bool :=
  match role with
  | .reference => false
  | .property => false
  | .quotedProperty => false
  | _ => true

def psSh1TargetRoleUsesExpressionGlobals (role : PsSh1TargetNameRole) : Bool :=
  match role with
  | .globalValue => true
  | .globalBoth => true
  | .localValue => true
  | _ => false

def psSh1TargetAsciiBetween (low high : Nat) (value : Char) : Bool :=
  if Nat.ble low (Char.toNat value) then Nat.ble (Char.toNat value) high else false

def psSh1TargetIdentifierStart (value : Char) : Bool :=
  if psSh1TargetAsciiBetween 65 90 value then true
  else if psSh1TargetAsciiBetween 97 122 value then true
  else if Nat.beq (Char.toNat value) 95 then true
  else Nat.beq (Char.toNat value) 36

def psSh1TargetIdentifierRest (value : Char) : Bool :=
  if psSh1TargetIdentifierStart value then true
  else psSh1TargetAsciiBetween 48 57 value

def psSh1TargetTypeCapture
    (state : PsSh1TargetState) (role : PsSh1TargetNameRole) (value : String) : Bool :=
  match role with
  | .localType =>
      if psStringEq value "Array" then true
      else psSh1TargetIsGlobalType state.globals value
  | _ => false

def psSh1TargetCheckName
    (state : PsSh1TargetState) (scope : PsSh1TargetScope)
    (role : PsSh1TargetNameRole) (value : String) :
    Except PsSh1TargetError PsSh1TargetState :=
  match role with
  | .quotedProperty =>
      if psStringEq value "__proto__" then
        Except.error (psSh1TargetErrorAt state scope "target-property-name" value)
      else Except.ok state
  | .property =>
      if psStringEq value "__proto__" then
        Except.error (psSh1TargetErrorAt state scope "target-property-name" value)
      else Except.ok (psSh1TargetSchedule state
        [PsSh1TargetTask.nameChars scope role value 0 true])
  | _ =>
      if if psSh1TargetRoleIsBinding role then psSh1TargetKeyword value else false then
        Except.error (psSh1TargetErrorAt state scope "target-binding-name" value)
      else if if psSh1TargetRoleIsType role then psSh1TargetTypeKeyword value else false then
        Except.error (psSh1TargetErrorAt state scope "target-type-name" value)
      else if psSh1TargetTypeCapture state role value then
        Except.error (psSh1TargetErrorAt state scope "target-type-capture" value)
      else if if psSh1TargetRoleIsBinding role then psSh1TargetRuntimeName value else false then
        Except.error (psSh1TargetErrorAt state scope "target-runtime-name" value)
      else if if psSh1TargetRoleIsGlobal role then psSh1TargetModuleGlobal value else false then
        Except.error (psSh1TargetErrorAt state scope "target-runtime-name" value)
      else if if psSh1TargetRoleUsesExpressionGlobals role then psSh1TargetExpressionGlobal value else false then
        Except.error (psSh1TargetErrorAt state scope "target-runtime-name" value)
      else if if psSh1TargetRoleIsBinding role then psSh1TargetHasName state.privateNames value else false then
        Except.error (psSh1TargetErrorAt state scope "target-generated-name" value)
      else Except.ok (psSh1TargetSchedule state
        [PsSh1TargetTask.nameChars scope role value 0 true])

def psSh1TargetStep
    (state : PsSh1TargetState) (task : PsSh1TargetTask) :
    Except PsSh1TargetError PsSh1TargetState :=
  match task with
  | .noImports imports =>
      match imports with
      | List.nil => Except.ok state
      | List.cons _ _ =>
          Except.error (psSh1TargetErrorAt state (psSh1TargetRootScope "module")
            "target-imports-unsupported" "closed source-owned target requires no external IR imports")
  | .collectStructures items =>
      match items with
      | List.nil => Except.ok state
      | List.cons item rest =>
          let scope := psSh1TargetRootScope item.name;
          Except.ok (psSh1TargetSchedule state
            [PsSh1TargetTask.name scope PsSh1TargetNameRole.globalType item.name, PsSh1TargetTask.addGlobal scope item.name true,
             PsSh1TargetTask.collectStructures rest])
  | .collectInductives items =>
      match items with
      | List.nil => Except.ok state
      | List.cons item rest =>
          let scope := psSh1TargetRootScope item.name;
          Except.ok (psSh1TargetSchedule state
            [PsSh1TargetTask.name scope PsSh1TargetNameRole.globalBoth item.name, PsSh1TargetTask.addGlobal scope item.name true,
             PsSh1TargetTask.collectInductives rest])
  | .collectDeclarations items =>
      match items with
      | List.nil => Except.ok state
      | List.cons item rest =>
          let scope := psSh1TargetRootScope item.name;
          Except.ok (psSh1TargetSchedule state
            [PsSh1TargetTask.name scope PsSh1TargetNameRole.globalValue item.name, PsSh1TargetTask.addGlobal scope item.name false,
             PsSh1TargetTask.collectDeclarations rest])
  | .addGlobal scope name isType =>
      if psSh1TargetHasName state.globals name then
        Except.error (psSh1TargetErrorAt state scope "target-global-collision" name)
      else Except.ok (PsSh1TargetState.mk state.tasks
        (psErasureIndexInsert Bool state.globals (PsName.str PsName.anonymous name) isType)
        state.privateNames state.visitedSteps)
  | .brandNames items index =>
      match items with
      | List.nil => Except.ok state
      | List.cons item rest =>
          Except.ok (psSh1TargetSchedule state
            [PsSh1TargetTask.addPrivate (psSh1TargetRootScope item.name)
               (String.Internal.append "__ps$brand$" (psNatToString index)),
             PsSh1TargetTask.brandNames rest (Nat.succ index)])
  | .tagNames items index =>
      match items with
      | List.nil => Except.ok state
      | List.cons item rest =>
          Except.ok (psSh1TargetSchedule state
            [PsSh1TargetTask.addPrivate (psSh1TargetRootScope item.name)
               (String.Internal.append "__ps$tag$" (psNatToString index)),
             PsSh1TargetTask.tagNames rest (Nat.succ index)])
  | .implementationNames items =>
      match items with
      | List.nil => Except.ok state
      | List.cons item rest =>
          match item.parameters with
          | List.nil => Except.ok (psSh1TargetSchedule state [PsSh1TargetTask.implementationNames rest])
          | List.cons _ _ =>
              Except.ok (psSh1TargetSchedule state
                [PsSh1TargetTask.addPrivate (psSh1TargetRootScope item.name)
                   (String.Internal.append "__ps$impl$" item.name),
                 PsSh1TargetTask.implementationNames rest])
  | .addPrivate scope name =>
      if psSh1TargetHasName state.globals name then
        Except.error (psSh1TargetErrorAt state scope "target-generated-name" name)
      else if psSh1TargetHasName state.privateNames name then
        Except.error (psSh1TargetErrorAt state scope "target-generated-name" name)
      else Except.ok (PsSh1TargetState.mk state.tasks state.globals
        (psSh1TargetInsertName state.privateNames name) state.visitedSteps)
  | .name scope role value => psSh1TargetCheckName state scope role value
  | .nameChars scope role value position first =>
      if String.Internal.atEnd value (String.Pos.Raw.mk position) then
        if first then
          Except.error (psSh1TargetErrorAt state scope "target-identifier" "empty identifier")
        else Except.ok state
      else
        let char := String.Internal.get value (String.Pos.Raw.mk position);
        let valid := if first then psSh1TargetIdentifierStart char else psSh1TargetIdentifierRest char;
        if valid then
          let next := String.Pos.Raw.byteIdx (String.Internal.next value (String.Pos.Raw.mk position));
          Except.ok (psSh1TargetSchedule state
            [PsSh1TargetTask.nameChars scope role value next false])
        else Except.error (psSh1TargetErrorAt state scope "target-identifier" value)
  | .structures items =>
      match items with
      | List.nil => Except.ok state
      | List.cons item rest =>
          let scope := psSh1TargetRootScope item.name;
          Except.ok (psSh1TargetSchedule state
            [PsSh1TargetTask.typeParameters scope item.typeParameters 0,
             PsSh1TargetTask.structureFields scope item.fields 0, PsSh1TargetTask.structures rest])
  | .inductives items =>
      match items with
      | List.nil => Except.ok state
      | List.cons item rest =>
          let scope := psSh1TargetRootScope item.name;
          Except.ok (psSh1TargetSchedule state
            [PsSh1TargetTask.typeParameters scope item.typeParameters 0,
             PsSh1TargetTask.constructors scope item.constructors 0, PsSh1TargetTask.inductives rest])
  | .structureFields scope items index =>
      match items with
      | List.nil => Except.ok state
      | List.cons item rest =>
          let atField := psSh1TargetAtIndex scope "field" index;
          Except.ok (psSh1TargetSchedule state
            [PsSh1TargetTask.name atField PsSh1TargetNameRole.property item.name,
             PsSh1TargetTask.runtimeType atField 4096 item.type,
             PsSh1TargetTask.structureFields scope rest (Nat.succ index)])
  | .constructors scope items index =>
      match items with
      | List.nil => Except.ok state
      | List.cons item rest =>
          let atCtor := psSh1TargetAtIndex scope "constructor" index;
          Except.ok (psSh1TargetSchedule state
            [PsSh1TargetTask.name atCtor PsSh1TargetNameRole.quotedProperty item.name,
             PsSh1TargetTask.constructorFields atCtor item.fields 0,
             PsSh1TargetTask.constructors scope rest (Nat.succ index)])
  | .constructorFields scope items index =>
      match items with
      | List.nil => Except.ok state
      | List.cons item rest =>
          let atField := psSh1TargetAtIndex scope "field" index;
          Except.ok (psSh1TargetSchedule state
            [PsSh1TargetTask.name atField PsSh1TargetNameRole.property item.name,
             PsSh1TargetTask.runtimeType atField 4096 item.type,
             PsSh1TargetTask.constructorFields scope rest (Nat.succ index)])
  | .typeParameters scope items index =>
      match items with
      | List.nil => Except.ok state
      | List.cons item rest =>
          let atType := psSh1TargetAtIndex scope "typeParameter" index;
          Except.ok (psSh1TargetSchedule state
            [PsSh1TargetTask.name atType PsSh1TargetNameRole.localType item.name,
             PsSh1TargetTask.typeParameters scope rest (Nat.succ index)])
  | .declarations earlier items =>
      match items with
      | List.nil => Except.ok state
      | List.cons item rest =>
          let hasParameters := match item.parameters with
            | List.nil => false
            | List.cons _ _ => true;
          let scope := PsSh1TargetScope.mk item.name "body" earlier
            psSh1TargetEmptyNames item.name hasParameters;
          Except.ok (psSh1TargetSchedule state
            [PsSh1TargetTask.typeParameters scope item.typeParameters 0,
             PsSh1TargetTask.parameters scope 4096 false item.parameters 0 item.resultType item.body,
             PsSh1TargetTask.declarations (psSh1TargetInsertName earlier item.name) rest])
  | .parameters scope depth weighted items index resultType body =>
      match items with
      | List.nil =>
          Except.ok (psSh1TargetSchedule state
            [PsSh1TargetTask.runtimeType (psSh1TargetAt scope "resultType") 4096 resultType,
             PsSh1TargetTask.expression scope depth body])
      | List.cons item rest =>
          match depth with
          | Nat.zero =>
              Except.error (psSh1TargetErrorAt state scope
                "target-depth-exhausted" "weighted lambda/eta depth exceeds 4096")
          | Nat.succ remaining =>
              let nextDepth := if weighted then remaining else depth;
              let atParameter := psSh1TargetAtIndex scope "parameter" index;
              Except.ok (psSh1TargetSchedule state
                [PsSh1TargetTask.name atParameter PsSh1TargetNameRole.localValue item.name,
                 PsSh1TargetTask.runtimeType atParameter 4096 item.type,
                 PsSh1TargetTask.parameters (psSh1TargetWithLocal scope item.name) nextDepth weighted
                   rest (Nat.succ index) resultType body])
  | .runtimeType scope depth value =>
      match depth with
      | Nat.zero =>
          Except.error (psSh1TargetErrorAt state scope
            "target-depth-exhausted" "runtime type depth exceeds 4096")
      | Nat.succ remaining =>
          match value with
          | .unknown =>
              Except.error (psSh1TargetErrorAt state scope
                "target-unchecked-type" "original-IR typing is required before target admission")
          | .primitive _ => Except.ok state
          | .typeParameter name =>
              Except.ok (psSh1TargetSchedule state [PsSh1TargetTask.name scope PsSh1TargetNameRole.reference name])
          | .named name arguments =>
              Except.ok (psSh1TargetSchedule state
                [PsSh1TargetTask.name scope PsSh1TargetNameRole.reference name, PsSh1TargetTask.runtimeTypes scope remaining arguments 0])
          | .function parameters resultType =>
              Except.ok (psSh1TargetSchedule state
                [PsSh1TargetTask.runtimeTypes scope remaining parameters 0,
                 PsSh1TargetTask.runtimeType (psSh1TargetAt scope "result") remaining resultType])
  | .runtimeTypes scope depth items index =>
      match items with
      | List.nil => Except.ok state
      | List.cons item rest =>
          Except.ok (psSh1TargetSchedule state
            [PsSh1TargetTask.runtimeType (psSh1TargetAtIndex scope "type" index) depth item,
             PsSh1TargetTask.runtimeTypes scope depth rest (Nat.succ index)])
  | .expression scope depth value =>
      match depth with
      | Nat.zero =>
          Except.error (psSh1TargetErrorAt state scope
            "target-depth-exhausted" "weighted expression/eta depth exceeds 4096")
      | Nat.succ remaining =>
          match value with
          | .literal _ => Except.ok state
          | .var name =>
              Except.ok (psSh1TargetSchedule state
                [PsSh1TargetTask.name scope PsSh1TargetNameRole.reference name, PsSh1TargetTask.readVariable scope name])
          | .intrinsic _ typeArguments arguments =>
              Except.ok (psSh1TargetSchedule state
                [PsSh1TargetTask.runtimeTypes scope 4096 typeArguments 0,
                 PsSh1TargetTask.expressions scope remaining arguments 0])
          | .lambda parameters resultType body =>
              Except.ok (psSh1TargetSchedule state
                [PsSh1TargetTask.parameters (psSh1TargetAt scope "lambda") remaining true
                   parameters 0 resultType body])
          | .call fn typeArguments arguments =>
              Except.ok (psSh1TargetSchedule state
                [PsSh1TargetTask.expression (psSh1TargetAt scope "callee") remaining fn,
                 PsSh1TargetTask.runtimeTypes scope 4096 typeArguments 0,
                 PsSh1TargetTask.expressions scope remaining arguments 0])
          | .letE name type value body =>
              Except.ok (psSh1TargetSchedule state
                [PsSh1TargetTask.name (psSh1TargetAt scope "letName") PsSh1TargetNameRole.localValue name,
                 PsSh1TargetTask.runtimeType (psSh1TargetAt scope "letType") 4096 type,
                 PsSh1TargetTask.expression (psSh1TargetAt scope "initializer") remaining value,
                 PsSh1TargetTask.expression (psSh1TargetAt (psSh1TargetWithLocal scope name) "letBody")
                   remaining body])
          | .ifE condition thenBranch elseBranch =>
              Except.ok (psSh1TargetSchedule state
                [PsSh1TargetTask.expression (psSh1TargetAt scope "condition") remaining condition,
                 PsSh1TargetTask.expression (psSh1TargetAt scope "then") remaining thenBranch,
                 PsSh1TargetTask.expression (psSh1TargetAt scope "else") remaining elseBranch])
          | .record _ typeArguments fields =>
              Except.ok (psSh1TargetSchedule state
                [PsSh1TargetTask.runtimeTypes scope 4096 typeArguments 0,
                 PsSh1TargetTask.expressionFields scope remaining fields 0])
          | .projection _ typeArguments target field =>
              Except.ok (psSh1TargetSchedule state
                [PsSh1TargetTask.runtimeTypes scope 4096 typeArguments 0,
                 PsSh1TargetTask.name (psSh1TargetAt scope "field") PsSh1TargetNameRole.property field,
                 PsSh1TargetTask.expression (psSh1TargetAt scope "target") remaining target])
          | .constructor inductiveName name typeArguments fields =>
              if psSh1TargetHasName scope.locals inductiveName then
                Except.error (psSh1TargetErrorAt state scope
                  "target-value-capture" inductiveName)
              else Except.ok (psSh1TargetSchedule state
                [PsSh1TargetTask.name (psSh1TargetAt scope "constructor") PsSh1TargetNameRole.quotedProperty name,
                 PsSh1TargetTask.runtimeTypes scope 4096 typeArguments 0,
                 PsSh1TargetTask.expressionFields scope remaining fields 0])
          | .matchE _ typeArguments scrutinee alternatives =>
              Except.ok (psSh1TargetSchedule state
                [PsSh1TargetTask.runtimeTypes scope 4096 typeArguments 0,
                 PsSh1TargetTask.expression (psSh1TargetAt scope "scrutinee") remaining scrutinee,
                 PsSh1TargetTask.alternatives scope remaining alternatives 0])
  | .expressions scope depth items index =>
      match items with
      | List.nil => Except.ok state
      | List.cons item rest =>
          Except.ok (psSh1TargetSchedule state
            [PsSh1TargetTask.expression (psSh1TargetAtIndex scope "argument" index) depth item,
             PsSh1TargetTask.expressions scope depth rest (Nat.succ index)])
  | .readVariable scope name =>
      if psSh1TargetHasName scope.locals name then Except.ok state
      else if psStringEq scope.selfName name then
        if scope.selfFunction then Except.ok state
        else Except.error (psSh1TargetErrorAt state scope "target-self-value" name)
      else if psSh1TargetHasName scope.earlier name then Except.ok state
      else Except.error (psSh1TargetErrorAt state scope "target-global-order" name)
  | .expressionFields scope depth items index =>
      match items with
      | List.nil => Except.ok state
      | List.cons item rest =>
          let atField := psSh1TargetAtIndex scope "field" index;
          Except.ok (psSh1TargetSchedule state
            [PsSh1TargetTask.name atField PsSh1TargetNameRole.property item.fst,
             PsSh1TargetTask.expression atField depth item.snd,
             PsSh1TargetTask.expressionFields scope depth rest (Nat.succ index)])
  | .alternatives scope depth items index =>
      match items with
      | List.nil => Except.ok state
      | List.cons item rest =>
          let atAlternative := psSh1TargetAtIndex scope "alternative" index;
          Except.ok (psSh1TargetSchedule state
            [PsSh1TargetTask.name atAlternative PsSh1TargetNameRole.quotedProperty item.fst,
             PsSh1TargetTask.matchBindings atAlternative depth item.snd.fst 0 item.snd.snd,
             PsSh1TargetTask.alternatives scope depth rest (Nat.succ index)])
  | .matchBindings scope depth items index body =>
      match items with
      | List.nil => Except.ok (psSh1TargetSchedule state [PsSh1TargetTask.expression scope depth body])
      | List.cons item rest =>
          let atBinding := psSh1TargetAtIndex scope "binding" index;
          Except.ok (psSh1TargetSchedule state
            [PsSh1TargetTask.name atBinding PsSh1TargetNameRole.localValue item.name,
             PsSh1TargetTask.name atBinding PsSh1TargetNameRole.property item.field,
             PsSh1TargetTask.runtimeType atBinding 4096 item.type,
             PsSh1TargetTask.matchBindings (psSh1TargetWithLocal scope item.name) depth
               rest (Nat.succ index) body])

def psSh1TargetFinished (state : PsSh1TargetState) : PsSh1TargetReport :=
  PsSh1TargetReport.mk psSh1TargetPolicy true true state.visitedSteps

def psSh1TargetRun (fuel : Nat) (state : PsSh1TargetState) :
    Except PsSh1TargetError PsSh1TargetReport :=
  match fuel with
  | Nat.zero =>
      match state.tasks with
      | List.nil => Except.ok (psSh1TargetFinished state)
      | List.cons _ _ =>
          Except.error (psSh1TargetErrorAt state (psSh1TargetRootScope "module")
            "target-fuel-exhausted" "target worklist allowance exhausted")
  | Nat.succ remaining =>
      match state.tasks with
      | List.nil => Except.ok (psSh1TargetFinished state)
      | List.cons task rest =>
          let current := PsSh1TargetState.mk rest state.globals state.privateNames
            (Nat.succ state.visitedSteps);
          match psSh1TargetStep current task with
          | Except.error error => Except.error error
          | Except.ok next => psSh1TargetRun remaining next

def psSh1CheckTarget (maxSteps : Nat) (module : PsVerifiedIrModule) :
    Except PsSh1TargetError PsSh1TargetReport :=
  let tasks : List PsSh1TargetTask :=
    [PsSh1TargetTask.noImports module.imports,
     PsSh1TargetTask.collectStructures module.structures,
     PsSh1TargetTask.collectInductives module.inductives,
     PsSh1TargetTask.collectDeclarations module.declarations,
     PsSh1TargetTask.brandNames module.structures 0,
     PsSh1TargetTask.tagNames module.inductives 0,
     PsSh1TargetTask.implementationNames module.declarations,
     PsSh1TargetTask.structures module.structures,
     PsSh1TargetTask.inductives module.inductives,
     PsSh1TargetTask.declarations psSh1TargetEmptyNames module.declarations];
  psSh1TargetRun maxSteps
    (PsSh1TargetState.mk tasks psSh1TargetEmptyNames psSh1TargetEmptyNames 0)
