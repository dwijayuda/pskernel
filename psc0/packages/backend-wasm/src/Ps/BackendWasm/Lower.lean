import Ps.BackendWasm.LowerState

namespace PsWasm

-- Every language expression produces one value, including erased Unit slots.
-- Only explicit ABI adapters may omit those slots or flatten a value.
def lowerExpr (ir : PsVerifiedIrModule) :
    Nat → List Binding → Option PsVerifiedIrType → PsVerifiedIrExpr → LowerM Compiled
  | 0, _, _, _ => throw "PSCV0-WASM-RESOURCE: expression traversal budget exhausted"
  | fuel + 1, bindings, expected, expr => do
    let lower := lowerExpr ir fuel bindings
    let lowerFields := fun (formal : List (String × PsVerifiedIrType))
        (fields : List (String × PsVerifiedIrExpr)) => do
      let mut code : List PsWasmInstruction := []
      let mut saved : List (String × Nat) := []
      for (name, value) in fields do
        let (type, _) ← fieldIndex formal name
        let compiled ← lower none value
        let index ← allocateLocal name (← representation type)
        code := code ++ (← converted compiled type) ++ [.localSet index]
        saved := (name, index) :: saved
      let ordered ← formal.mapM fun (name, _) => do
        let some (_, index) := saved.find? (fun p => p.1 == name)
          | throw ("PSCV0-WASM-LAYOUT: missing field " ++ name)
        return PsWasmInstruction.localGet index
      return code ++ ordered
    match expr with
    | .unreachable type => return { code := [.unreachable], type }
    | .literal value => return ← literalCode value
    | .var name =>
      if let some b := bindings.find? (fun b => b.name == name) then
        return { code := [.localGet b.index], type := b.type }
      let d ← requireDeclaration ir name
      if d.parameters.isEmpty then
        return { code := [.call name], type := d.resultType }
      -- First-class declaration references use exactly the closure convention
      -- used by lambdas; direct applications bypass this adapter.
      lowerExpr ir fuel bindings expected (.lambda d.parameters d.resultType
        (.call (.var name) (d.typeParameters.map fun p => .typeParameter p.name)
          (d.parameters.map fun p => .var p.name)))
    | .letE name type value body =>
      let code ← converted (← lower (some type) value) type
      let binding ← allocateBinding name type
      let body ← lowerExpr ir fuel (binding :: bindings) expected body
      return { body with code := code ++ [.localSet binding.index] ++ body.code }
    | .ifE condition yes no =>
      let condition ← lower (some (.primitive .bool)) condition
      let yes ← lower expected yes
      let type := expected.getD yes.type
      let no ← lower (some type) no
      return {
        type
        code := condition.code ++ [.ifStart (some (← representation type))] ++
          (← converted yes type) ++ [.else_] ++ (← converted no type) ++ [.end_] }
    | .intrinsic op types args =>
      let actual ← (psIrCheckIntrinsicSignature op types).mapError
        (fun e => "PSCV0-WASM-INTRINSIC: " ++ e.detail)
      let plan ← intrinsicPlan op types
      if args.length != plan.parameters.length then throw "PSCV0-WASM-INTRINSIC: arity"
      let parts ← ((args.zip actual.parameters).zip plan.parameters).mapM fun ((arg, type), formal) => do
        converted (← lower (some type) arg) formal
      return {
        type := actual.resultType
        code := parts.flatten ++ plan.instructions ++ (← convert plan.result actual.resultType) }
    | .call fn typeArguments args =>
      let mut constantFunction : Option Compiled := none
      if let .var name := fn then
        if !(bindings.any (fun b => b.name == name)) then
          let d ← requireDeclaration ir name
          if !d.parameters.isEmpty then
            let concrete ← d.parameters.mapM (fun p => substitute d.typeParameters typeArguments p.type)
            if args.length != concrete.length then throw "PSCV0-WASM-CALL: declaration arity"
            let parts ← ((args.zip concrete).zip d.parameters).mapM fun ((arg, type), formal) => do
              converted (← lower (some type) arg) formal.type
            let type ← substitute d.typeParameters typeArguments d.resultType
            return { type, code := parts.flatten ++ [.call name] ++ (← convert d.resultType type) }
          constantFunction := some {
            code := [.call name]
            type := ← substitute d.typeParameters typeArguments d.resultType }
      let function ← match constantFunction with
        | some value => pure value
        | none => do
          if !typeArguments.isEmpty then throw "PSCV0-WASM-CALL: polymorphic closure application is not in the checked IR"
          lower none fn
      let .function parameters result := function.type
        | throw "PSCV0-WASM-CALL: expected function value"
      let index ← allocateLocal "callee" closureType
      let mut code := function.code ++ [.localSet index, .localGet index]
      if args.length != parameters.length then throw "PSCV0-WASM-CALL: closure arity"
      for (arg, type) in args.zip parameters do
        let value ← lower (some type) arg
        code := code ++ (← converted value type) ++ (← box type)
      let state ← get
      set { state with arities := parameters.length :: state.arities }
      return {
        type := result
        code := code ++ [.localGet index, .structGet closureName 0,
          .refCastFunction (closureCodeName parameters.length), .callRef (closureCodeName parameters.length)] ++
          (← unbox result) }
    | .lambda parameters result body =>
      let captureNames := psCodegenCollectCapturesWorker (bindings.map (·.name)).eraseDups
        fuel (parameters.map (·.name)) body []
      let captures := captureNames.filterMap fun n => bindings.find? (fun b => b.name == n)
      let outer ← get
      let name := "__ps_closure_" ++ outer.owner ++ "_" ++ toString outer.next
      set { outer with locals := [], names := [], next := outer.next + 1,
        arities := parameters.length :: outer.arities }
      let self ← allocateLocal "closure" closureType
      let arguments ← parameters.mapM fun p => allocateLocal (p.name ++ "_boxed") valueType
      let mut initial : List PsWasmInstruction := []
      let mut inner : List Binding := []
      for (p, index) in parameters.zip arguments do
        let b ← allocateBinding p.name p.type
        initial := initial ++ [.localGet index] ++ (← unbox p.type) ++ [.localSet b.index]
        inner := b :: inner
      for (capture, index) in captures.zipIdx do
        let b ← allocateBinding capture.name capture.type
        initial := initial ++ [.localGet self, .structGet closureName 1,
          .i32Const (Int.ofNat index), .arrayGet valuesName] ++
          (← unbox capture.type) ++ [.localSet b.index]
        inner := inner ++ [b]
      let compiled ← lowerExpr ir fuel inner (some result) body
      let innerState ← get
      let function : PsWasmFunction := {
        name, typeName := some (closureCodeName parameters.length)
        parameters := closureType :: List.replicate parameters.length valueType
        results := [valueType]
        locals := innerState.locals.drop (parameters.length + 1)
        body := psWasmTailCalls (initial ++ (← converted compiled result) ++ (← box result)) }
      set { innerState with locals := outer.locals, names := outer.names,
        lifted := innerState.lifted ++ [{ function, names := innerState.names }] }
      let captureCode ← captures.mapM fun b => do
        return [.localGet b.index] ++ (← box b.type)
      return {
        type := .function (parameters.map (·.type)) result
        code := [.refFunc name] ++ captureCode.flatten ++
          [.arrayNewFixed valuesName captures.length, .structNew closureName] }
    | .record name types fields =>
      let s ← requireStructure ir name
      return {
        type := .named name types
        code := (← lowerFields (s.fields.map fun f => (f.name, f.type)) fields) ++ [.structNew name] }
    | .constructor name constructor types fields =>
      let i ← requireInductive ir name
      let (ctor, tag) ← requireConstructor i constructor
      let fields ← lowerFields (ctor.fields.map fun f => (f.name, f.type)) fields
      -- A tag is required even for structurally identical constructor types.
      return {
        type := .named name types
        code := [.i32Const (Int.ofNat tag)] ++ fields ++ [.structNew (constructorTypeName ctor.name)] }
    | .projection name types target field =>
      let s ← requireStructure ir name
      let (formal, index) ← fieldIndex (s.fields.map fun f => (f.name, f.type)) field
      let type ← substitute s.typeParameters types formal
      let target ← lower (some (.named name types)) target
      return { type, code := target.code ++ [.structGet name index] ++ (← convert formal type) }
    | .matchE name types target alternatives =>
      let i ← requireInductive ir name
      let target ← lower (some (.named name types)) target
      let index ← allocateLocal "scrutinee" (.refT name)
      let mut branches : List (Nat × Compiled) := []
      for (ctorName, fields, body) in alternatives do
        let (ctor, tag) ← requireConstructor i ctorName
        let mut inner := bindings
        let mut code : List PsWasmInstruction := []
        for field in fields do
          let (formal, position) ← fieldIndex (ctor.fields.map fun f => (f.name, f.type)) field.field
          let binding ← allocateBinding field.name field.type
          code := code ++ [.localGet index, .refCast (constructorTypeName ctor.name),
            .structGet (constructorTypeName ctor.name) (position + 1)] ++
              (← convert formal field.type) ++ [.localSet binding.index]
          inner := binding :: inner
        let body ← lowerExpr ir fuel inner expected body
        branches := branches ++ [(tag, { body with code := code ++ body.code })]
      let type ← match expected with
        | some t => pure t
        | none => match branches.head? with
          | some (_, b) => pure b.type
          | none => throw "PSCV0-WASM-MATCH: empty elimination requires its checked expected type"
      let branches ← branches.mapM fun (tag, body) => do
        return (tag, ← converted body type)
      let result ← representation type
      let tree := branches.foldr (fun (tag, body) rest =>
        [.localGet index, .structGet name 0, .i32Const (Int.ofNat tag), .i32Eq,
         .ifStart (some result)] ++ body ++ [.else_] ++ rest ++ [.end_]) [.unreachable]
      return { type, code := target.code ++ [.localSet index] ++ tree }

def lowerDeclaration (ir : PsVerifiedIrModule) (d : PsVerifiedIrDeclaration) :
    Except String (List RuntimeDefinition × List Nat) := do
  let action : LowerM RuntimeDefinition := do
    let bindings ← d.parameters.mapM fun p => allocateBinding p.name p.type
    let body ← lowerExpr ir 65536 bindings.reverse (some d.resultType) d.body
    let state ← get
    return {
      function := {
        name := d.name, typeName := none
        parameters := ← d.parameters.mapM (fun p => representation p.type)
        results := [← representation d.resultType]
        locals := state.locals.drop d.parameters.length
        body := psWasmTailCalls (← converted body d.resultType) }
      names := state.names }
  let (definition, state) ← action.run { owner := d.name }
  return (definition :: state.lifted, state.arities)

def lowerModule (ir : PsVerifiedIrModule) :
    Except String (PsWasmModule × List (String × List String)) := do
  if !ir.imports.isEmpty then throw "PSCV0-WASM-CAPABILITY: external imports are not admitted"
  let definitions ← ir.declarations.mapM (lowerDeclaration ir)
  let runtime ← runtimeDefinitions
  let functions := definitions.flatMap (·.1) ++ runtime
  let arities := ((definitions.flatMap (·.2)) ++ [1, 2]).eraseDups
  let core : PsWasmModule := {
    psWasmModuleEmpty with
    structures := valueStructures ++ (← dataLayouts ir)
    arrays := valueArrays
    functionTypes := arities.map closureCodeType
    functions := functions.map (·.function)
    functionRefs := (functions.flatMap fun f => f.function.body.filterMap fun instruction =>
      match instruction with | .refFunc name => some name | _ => none).eraseDups
    exports := ir.declarations.map fun d => (d.name, d.name) }
  return (core, functions.map fun f => (f.function.name, f.names))

end PsWasm
