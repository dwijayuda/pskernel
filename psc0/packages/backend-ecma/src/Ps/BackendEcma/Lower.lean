import Ps.BackendEcma.Intrinsic
import Ps.BackendTs.Analysis

namespace PsEcma

def typeArguments (types : List PsVerifiedIrType) : Except String String := do
  if types.isEmpty then return ""
  return "<" ++ String.intercalate ", " (← types.mapM irType) ++ ">"

-- One lowering for both dialects; no generated expression is parsed or stripped.
def lower (brands tags : List (String × String)) : Nat → PsVerifiedIrExpr → Except String Expr
  | 0, _ => .error "PSCV0-ECMA: lowering budget"
  | fuel + 1, value => do
    let visit := lower brands tags fuel
    match value with
    | .unreachable _ => return invoke [] "never" [fail "unreachable match branch"] []
    | .literal value =>
        return .atom (← (psTsEmitLiteral value).mapError (fun _ => "PSCV0-ECMA: unsupported literal"))
    | .var name => return id name
    | .intrinsic op types args => intrinsic op types (← args.mapM visit)
    | .lambda parameters result body =>
        return call "__ps$wrap" [.functionE true "" (← irParameters parameters)
          ("__ps$Computation<" ++ (← irType result) ++ ">") [ret (← visit body)]]
    | .call fn types args =>
        return unary "yield* " (call "__ps$invoke"
          (.generic (← visit fn) (← typeArguments types) :: (← args.mapM visit)))
    | .letE name type value body =>
        -- A binder shadows only its body. A function parameter avoids JS's
        -- temporal dead zone when the initializer mentions an outer namesake.
        if psTsExprUsesNameWithFuel 4096 value name then
          return delegate [ret (← visit body)] [{ name, type := ← irType type }] [← visit value]
        return delegate [.binding false name (← irType type) (some (← visit value)), ret (← visit body)]
    | .ifE c a b => return .conditional (← visit c) (← visit a) (← visit b)
    | .record name _ fields =>
        let some brand := psTsLookup brands name | throw ("PSCV0-ECMA: unknown structure " ++ name)
        return .object ((("[" ++ brand ++ "]", .cast (id "true") "const")) ::
          (← fields.mapM fun (key,value) => do return (key, ← visit value)))
    | .projection _ _ value field => return .member (← visit value) field
    | .constructor name constructor types fields =>
        let some _ := psTsLookup tags name | throw ("PSCV0-ECMA: unknown inductive " ++ name)
        let constructor := Expr.index (id name) (str constructor)
        if types.isEmpty && fields.isEmpty then return constructor
        return .call constructor (← typeArguments types) (← fields.mapM fun f => visit f.snd)
    | .matchE name _ value alternatives =>
        let some tag := psTsLookup tags name | throw ("PSCV0-ECMA: unknown match family " ++ name)
        if alternatives.isEmpty then
          return delegate [.expression (unary "void " (← visit value)), fail "unreachable empty ProofScript match"]
            [] [] "__ps$Computation<never>"
        let temp := psTsFreshMatchTemp (.matchE name [] value alternatives)
        let cases ← alternatives.mapM fun (constructor, bindings, body) => do
          let bindings ← bindings.mapM fun b => do
            return Stmt.binding false b.name (← irType b.type) (some (.member (id temp) b.field))
          return (str constructor, bindings ++ [ret (← visit body)])
        return delegate [const temp (← visit value), .switchE (.index (id temp) (id tag)) cases,
          fail "invalid ProofScript constructor tag"]

def countCases (tag self : String)
    (base step : String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr) : Option (List Stmt) := do
  if !psTsCountLiteral 0 base.snd.snd then none else do
    let localName ← psTsCountStepArgument self step.snd.snd
    let fieldName ← psTsCountField localName step.snd.fst
    return [
      letE "__ps$count" (id "0n"),
      .whileE (id "true") [
        .switchE (.index (id "__ps$cursor") (id tag)) [
          (str base.fst, [ret (id "__ps$count")]),
          (str step.fst, [set (id "__ps$cursor") (field (id "__ps$cursor") fieldName),
            inc "__ps$count" (id "1n"), .continueE])],
        fail "invalid ProofScript constructor tag"]]

def countLoop (tags : List (String × String)) (d : PsVerifiedIrDeclaration) : Option Stmt := do
  let .primitive .nat := d.resultType | none
  let [p] := d.parameters | none
  let .matchE name _ (.var value) [first,second] := d.body | none
  if value != p.name then none else do
    let tag ← psTsLookup tags name
    let cases ← countCases tag d.name first second <|> countCases tag d.name second first
    let type ← (irType p.type).toOption
    return .functionD true false d.name (psTsGenericNames d.typeParameters)
      [{ name := p.name, type }] "bigint" (letE "__ps$cursor" (id p.name) :: cases)

def tailBody (brands tags : List (String × String)) (d : PsVerifiedIrDeclaration) :
    Nat → List PsTsTailAlias → PsVerifiedIrExpr → Option (List Stmt)
  | 0, _, _ => none
  | fuel + 1, aliases, value => do
    let pureExpr := fun e =>
      if psTsTailPureWithFuel aliases 4096 e then (lower brands tags 4096 e).toOption else none
    let visit := tailBody brands tags d fuel
    match value with
    | .call fn [] args =>
      let args ← psTsTailCallArguments d.name aliases fn args
      if args.length != d.parameters.length then none else do
        let values ← args.mapM pureExpr
        return [set (.array (d.parameters.map fun p => id p.name)) (.array values), .continueE]
    | .letE name type value body =>
      if psTsExprUsesNameWithFuel 4096 value name ||
          !psTsTailBindingSafe d aliases name then none else do
        match psTsTailAliasValue d.name name value with
        | some alias =>
          if alias.captured.all (psTsTailPureWithFuel aliases 4096) then
            visit (alias :: aliases) body
          else none
        | none =>
          let value ← pureExpr value
          let body ← visit aliases body
          let type ← (irType type).toOption
          return [.block (.binding false name type (some value) :: body)]
    | .ifE c a b => return [.ifE (← pureExpr c) (← visit aliases a) (← visit aliases b)]
    | .matchE name _ value alternatives =>
      let tag ← psTsLookup tags name
      let target ← pureExpr value
      let _ ← if alternatives.isEmpty then none else some ()
      let temp := psTsFreshMatchTemp d.body
      let _ ← if psTsTailBindingSafe d aliases temp then some () else none
      let cases ← alternatives.mapM fun (constructor, bindings, body) => do
        if !bindings.all (fun b => psTsTailBindingSafe d aliases b.name) then none else do
          let bindings ← bindings.mapM fun b => do
            let type ← (irType b.type).toOption
            return Stmt.binding false b.name type (some (.member (id temp) b.field))
          return (str constructor, bindings ++ (← visit aliases body))
      -- Each match owns a lexical block. A nested match's temporary must not
      -- enter the scope of the outer branch field initializers (JS TDZ).
      return [.block [const temp target, .switchE (.index (id temp) (id tag)) cases,
        fail "invalid ProofScript constructor tag"]]
    | _ => return [ret (← pureExpr value)]

-- Continue belongs to the current tail loop only. Do not inspect expression
-- functions: their control flow has its own lexical/function boundary.
def tailHasContinue : Nat → Stmt → Bool
  | 0, _ => true
  | fuel + 1, statement =>
    match statement with
    | .continueE => true
    | .block statements => statements.any (tailHasContinue fuel)
    | .ifE _ yes no => yes.any (tailHasContinue fuel) || no.any (tailHasContinue fuel)
    | .switchE _ cases => cases.any (fun c => c.snd.any (tailHasContinue fuel))
    | _ => false

def declaration (brands tags : List (String × String)) (d : PsVerifiedIrDeclaration) :
    Except String (List Stmt) := do
  if let some loop := countLoop tags d then return [loop]
  let parameters ← irParameters d.parameters
  let result ← irType d.resultType
  let body := psTsInlineEtaApplication d.body
  if d.typeParameters.isEmpty && !parameters.isEmpty then
    if let some tail := tailBody brands tags d 4096 [] body then
      let statements := if tail.any (tailHasContinue 4096) then [.whileE (id "true") tail]
        else match tail with | [.block body] => body | _ => tail
      return [.functionD true false d.name "" parameters result statements]
  let body ← lower brands tags 4096 body
  let computation := "__ps$Computation<" ++ result ++ ">"
  if parameters.isEmpty then
    if !d.typeParameters.isEmpty then throw ("PSCV0-ECMA: generic value " ++ d.name)
    -- Export is applied to this binding by the module printer.
    return [.binding false d.name result (some (call "__ps$run" [
      .call (.functionE true "" [] computation [ret body]) "" []]))]
  let types := psTsGenericNames d.typeParameters
  let implementation := "__ps$impl$" ++ d.name
  return [
    .functionD true false d.name types parameters result [
      ret (call "__ps$run" [.call (id implementation) types (parameters.map fun p => id p.name)])],
    .functionD false true implementation types parameters computation [ret body],
    .expression (method (id "__ps$implementations") "set" [id d.name, id implementation])]
end PsEcma
