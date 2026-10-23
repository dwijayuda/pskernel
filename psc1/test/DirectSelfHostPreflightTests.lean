import Ps.BackendJs.Print
import WasmBinaryCarrierTests
import Ps.BackendWasm.CompilerService

namespace PsJsNameVisitorReference
def psJsExprUsesNameWithFuel
    (fuel : Nat) :
    PsJsIrExpr -> String -> Bool :=
  match fuel with
  | Nat.zero =>
      fun (_expr : PsJsIrExpr) (_name : String) => true
  | Nat.succ remaining =>
      fun (expr : PsJsIrExpr) (name : String) =>
        let smaller : PsJsIrExpr -> String -> Bool :=
          psJsExprUsesNameWithFuel remaining;
        let uses : PsJsIrExpr -> Bool :=
          fun (value : PsJsIrExpr) =>
            smaller value name;
        let nameUses : String -> Bool :=
          fun (value : String) =>
            psStringEq value name;
        let fieldUses :
            (String × PsJsIrExpr) -> Bool :=
          fun (field : String × PsJsIrExpr) =>
            uses (Prod.snd field);
        let bindingUses :
            PsJsIrMatchBinding -> Bool :=
          fun (binding : PsJsIrMatchBinding) =>
            psStringEq binding.name name;
        let alternativeUses :
            (String ×
              List PsJsIrMatchBinding ×
              PsJsIrExpr) -> Bool :=
          fun
            (alternative :
              String ×
                List PsJsIrMatchBinding ×
                PsJsIrExpr) =>
            let detail := Prod.snd alternative;
            if psListAny bindingUses (Prod.fst detail) then
              true
            else
              uses (Prod.snd detail);
        match expr with
        | PsJsIrExpr.literal _ => false
        | PsJsIrExpr.var value =>
            psStringEq value name
        | PsJsIrExpr.unary _ value =>
            uses value
        | PsJsIrExpr.binary _ left right =>
            if uses left then true else uses right
        | PsJsIrExpr.runtime _ arguments =>
            psListAny uses arguments
        | PsJsIrExpr.lambda parameters body =>
            if psListAny nameUses parameters then
              true
            else
              uses body
        | PsJsIrExpr.call fn arguments =>
            if uses fn then true else psListAny uses arguments
        | PsJsIrExpr.letE localName value body =>
            if psStringEq localName name then
              true
            else if uses value then
              true
            else
              uses body
        | PsJsIrExpr.ifE condition thenBranch elseBranch =>
            if uses condition then
              true
            else if uses thenBranch then
              true
            else
              uses elseBranch
        | PsJsIrExpr.record fields =>
            psListAny fieldUses fields
        | PsJsIrExpr.projection target _ =>
            uses target
        | PsJsIrExpr.constructor _ fields =>
            psListAny fieldUses fields
        | PsJsIrExpr.matchE scrutinee alternatives =>
            if uses scrutinee then
              true
            else
              psListAny alternativeUses alternatives
end PsJsNameVisitorReference

namespace PsJsRuntimeReference
def psJsRuntimeUnary
    (operation : PsJsIrRuntimeOp)
    (value : String) :
    Except PsJsEmitError String :=
  match operation with
  | PsJsIrRuntimeOp.uint8OfNat =>
      Except.ok
        (psJsJoin
          ""
          ["Number(BigInt.asUintN(8, ", value, "))"])
  | PsJsIrRuntimeOp.intNegSucc =>
      Except.ok
        (psJsJoin "" ["(-(", value, " + 1n))"])
  | PsJsIrRuntimeOp.intRepr =>
      Except.ok
        (psJsJoin "" ["(", value, ").toString()"])
  | PsJsIrRuntimeOp.charOfNat =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_n) => ((__ps_n < 0xd800n || (__ps_n > 0xdfffn && __ps_n < 0x110000n)) ",
            "? String.fromCodePoint(Number(__ps_n)) : \"\\0\"))(",
            value,
            ")"
          ])
  | PsJsIrRuntimeOp.charToNat =>
      Except.ok
        (psJsJoin
          ""
          ["((__ps_c) => BigInt(__ps_c.codePointAt(0) ?? 0))(", value, ")"])
  | PsJsIrRuntimeOp.stringLength =>
      Except.ok
        (psJsJoin
          ""
          ["((__ps_s) => BigInt(Array.from(__ps_s).length))(", value, ")"])
  | PsJsIrRuntimeOp.stringUtf8ByteSize =>
      Except.ok (psJsJoin "" ["__ps$utf8(", value, ").size"])
  | PsJsIrRuntimeOp.arrayEmptyWithCapacity =>
      Except.ok
        (psJsJoin
          ""
          ["(() => { void (", value, "); return []; })()"])
  | PsJsIrRuntimeOp.arraySize =>
      Except.ok
        (psJsJoin
          ""
          ["BigInt((", value, ").length)"])
  | _ =>
      Except.error PsJsEmitError.malformedIr

def psJsRuntimeBinary
    (operation : PsJsIrRuntimeOp)
    (left right : String) :
    Except PsJsEmitError String :=
  match operation with
  | PsJsIrRuntimeOp.natSub =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_a, __ps_b) => (__ps_a >= __ps_b ? __ps_a - __ps_b : 0n))(",
            left,
            ", ",
            right,
            ")"
          ])
  | PsJsIrRuntimeOp.natDiv =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_a, __ps_b) => (__ps_b === 0n ? 0n : __ps_a / __ps_b))(",
            left,
            ", ",
            right,
            ")"
          ])
  | PsJsIrRuntimeOp.natMod =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_a, __ps_b) => (__ps_b === 0n ? __ps_a : __ps_a % __ps_b))(",
            left,
            ", ",
            right,
            ")"
          ])
  | PsJsIrRuntimeOp.stringNext =>
      Except.ok (psJsJoin ""
        ["((__ps_s, __ps_p) => __ps_p + (__ps$utf8(__ps_s).entries.get(__ps_p)?.[1] ?? 1n))(",
         left, ", ", right, ")"])
  | PsJsIrRuntimeOp.stringGet =>
      Except.ok (psJsJoin ""
        ["((__ps_s, __ps_p) => __ps$utf8(__ps_s).entries.get(__ps_p)?.[0] ?? \"A\")(",
         left, ", ", right, ")"])
  | PsJsIrRuntimeOp.stringAtEnd =>
      Except.ok (psJsJoin ""
        ["((__ps_s, __ps_p) => __ps_p >= __ps$utf8(__ps_s).size)(",
         left, ", ", right, ")"])
  | PsJsIrRuntimeOp.arrayPush =>
      Except.ok
        (psJsJoin
          ""
          ["[...(", left, "), ", right, "]"])
  | PsJsIrRuntimeOp.arrayGet =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_a, __ps_i) => __ps_a[Number(__ps_i)])(",
            left,
            ", ",
            right,
            ")"
          ])
  | PsJsIrRuntimeOp.arrayMap =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_f, __ps_a) => __ps_a.map((__ps_x) => __ps_f(__ps_x)))(",
            left,
            ", ",
            right,
            ")"
          ])
  | _ =>
      Except.error PsJsEmitError.malformedIr

def psJsRuntimeTernary
    (operation : PsJsIrRuntimeOp)
    (first second third : String) :
    Except PsJsEmitError String :=
  match operation with
  | PsJsIrRuntimeOp.stringExtract =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_s, __ps_b, __ps_e) => { if (__ps_b >= __ps_e) return \"\"; ",
            "let __ps_i = 0n; let __ps_started = false; let __ps_out = \"\"; ",
            "for (const __ps_c of __ps_s) { ",
            "const __ps_cp = __ps_c.codePointAt(0) ?? 0; ",
            "const __ps_w = BigInt(__ps_cp <= 0x7f ? 1 : __ps_cp <= 0x7ff ? 2 : __ps_cp <= 0xffff ? 3 : 4); ",
            "if (!__ps_started) { if (__ps_i === __ps_b) __ps_started = true; ",
            "else { __ps_i += __ps_w; continue; } } ",
            "if (__ps_i === __ps_e) return __ps_out; ",
            "__ps_out += __ps_c; __ps_i += __ps_w; } return __ps_out; })(",
            first,
            ", ",
            second,
            ", ",
            third,
            ")"
          ])
  | PsJsIrRuntimeOp.arrayGetD =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_a, __ps_i, __ps_fallback) => (__ps_i < BigInt(__ps_a.length) ? ",
            "__ps_a[Number(__ps_i)] : __ps_fallback))(",
            first,
            ", ",
            second,
            ", ",
            third,
            ")"
          ])
  | PsJsIrRuntimeOp.arraySet =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_a, __ps_i, __ps_v) => { const __ps_out = [...__ps_a]; ",
            "__ps_out[Number(__ps_i)] = __ps_v; return __ps_out; })(",
            first,
            ", ",
            second,
            ", ",
            third,
            ")"
          ])
  | PsJsIrRuntimeOp.arraySetIfInBounds =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_a, __ps_i, __ps_v) => { if (__ps_i >= BigInt(__ps_a.length)) return __ps_a; ",
            "const __ps_out = [...__ps_a]; __ps_out[Number(__ps_i)] = __ps_v; ",
            "return __ps_out; })(",
            first,
            ", ",
            second,
            ", ",
            third,
            ")"
          ])
  | _ =>
      Except.error PsJsEmitError.malformedIr

def psJsStringRuntimeSupport : String :=
  "let __ps$utf8Cache;\nfunction __ps$utf8(source) { if (__ps$utf8Cache?.source === source) return __ps$utf8Cache; const entries = new Map(); let size = 0n; for (const char of source) { const cp = char.codePointAt(0) ?? 0; const width = BigInt(cp <= 0x7f ? 1 : cp <= 0x7ff ? 2 : cp <= 0xffff ? 3 : 4); entries.set(size, [char, width]); size += width; } return (__ps$utf8Cache = { source, entries, size }); }\n"
end PsJsRuntimeReference

theorem js_name_visitor_worker_eq (fuel : Nat) (expr : PsJsIrExpr) (name : String) :
    psJsExprUsesNameWithFuelWorker fuel expr name =
      PsJsNameVisitorReference.psJsExprUsesNameWithFuel fuel expr name := by
  induction fuel generalizing expr name with
  | zero => rfl
  | succ remaining ih =>
      cases expr <;>
        simp only [psJsExprUsesNameWithFuelWorker,
          PsJsNameVisitorReference.psJsExprUsesNameWithFuel, ih] <;> rfl

theorem js_name_visitor_public_eq (fuel : Nat) :
    psJsExprUsesNameWithFuel fuel = PsJsNameVisitorReference.psJsExprUsesNameWithFuel fuel := by
  funext expr name
  exact js_name_visitor_worker_eq fuel expr name

#print axioms js_name_visitor_worker_eq

private def requireText (value : Except PsJsEmitError String) : IO String :=
  match value with
  | .ok value => pure value
  | .error _ => throw (IO.userError "runtime expression refused")

private def emitRuntime (legacy : Bool) : IO String := do
  let size ← requireText ((if legacy then PsJsRuntimeReference.psJsRuntimeUnary else psJsRuntimeUnary) .stringUtf8ByteSize "s")
  let get ← requireText ((if legacy then PsJsRuntimeReference.psJsRuntimeBinary else psJsRuntimeBinary) .stringGet "s" "p")
  let next ← requireText ((if legacy then PsJsRuntimeReference.psJsRuntimeBinary else psJsRuntimeBinary) .stringNext "s" "p")
  let ending ← requireText ((if legacy then PsJsRuntimeReference.psJsRuntimeBinary else psJsRuntimeBinary) .stringAtEnd "s" "p")
  let extract ← requireText ((if legacy then PsJsRuntimeReference.psJsRuntimeTernary else psJsRuntimeTernary) .stringExtract "s" "a" "b")
  let state := if legacy then
      "clear:()=>{__ps$utf8Cache=undefined},retained:()=>__ps$utf8Cache?1:0"
    else "clear:()=>{__ps$lastUtf8=undefined;__ps$previousUtf8=undefined},retained:()=>[__ps$lastUtf8,__ps$previousUtf8].filter(Boolean).length"
  pure (psJsJoin "\n" [
    (if legacy then PsJsRuntimeReference.psJsStringRuntimeSupport else psJsStringRuntimeSupport),
    "export const api = {get:(s,p)=>" ++ get ++ ",next:(s,p)=>" ++ next ++
      ",size:s=>" ++ size ++ ",ending:(s,p)=>" ++ ending ++ ",extract:(s,a,b)=>" ++ extract ++ "," ++ state ++ "};"])

private def fixtureModule : PsVerifiedIrModule :=
  let nat := PsVerifiedIrType.primitive .nat;
  let int := PsVerifiedIrType.primitive .int;
  let str := PsVerifiedIrType.primitive .string;
  let bool := PsVerifiedIrType.primitive .bool;
  .mk [] [] [] [
    .mk "answer" [] [] nat (.literal (.natural 42)),
    .mk "huge" [] [] int (.literal (.integer (-9007199254740993123456789))),
    .mk "text" [] [] str (.literal (.string "λ🙂")),
    .mk "echo" [] [.mk "value" str] str (.var "value"),
    .mk "increment" [] [.mk "value" nat] nat (.intrinsic .natAdd [] [.var "value",.literal (.natural 1)]),
    .mk "negate" [] [.mk "value" int] int (.intrinsic .intNeg [] [.var "value"]),
    .mk "invert" [] [.mk "value" bool] bool (.intrinsic .boolNot [] [.var "value"])
  ]

def main : IO Unit := do
  let expressions : List PsJsIrExpr := [
    .literal (.natural 4),.var "x",.unary .boolNot (.var "x"),
    .binary .bigintAdd (.var "left") (.var "right"),.runtime .stringGet [.var "s",.var "p"],
    .lambda ["binder"] (.var "body"),.call (.var "callee") [.var "argument"],
    .letE "local" (.var "value") (.var "body"),.ifE (.var "condition") (.var "yes") (.var "no"),
    .record [("field",.var "fieldValue")],.projection (.var "target") "field",
    .constructor "C" [("field",.var "inside")],
    .matchE (.var "scrutinee") [("C",[.mk "field" "bound"],.var "branch")]]
  for fuel in [0,1,2,4,64] do
    for expression in expressions do
      for name in ["x","left","s","binder","local","bound","branch","missing"] do
        if psJsExprUsesNameWithFuel fuel expression name !=
            PsJsNameVisitorReference.psJsExprUsesNameWithFuel fuel expression name then
          throw (IO.userError "name visitor exact behavior changed")
  if !psJsExprUsesNameWithFuel 0 (.literal (.natural 0)) "absent" then
    throw (IO.userError "fuel-zero must remain conservative")
  if psJsExprUsesNameWithFuel 100001 (.literal (.natural 0)) "absent" then
    throw (IO.userError "literal visitor changed")
  IO.FS.createDirAll "dist/direct-selfhost-preflight"
  IO.FS.writeFile "dist/direct-selfhost-preflight/runtime-current.mjs" (← emitRuntime false)
  IO.FS.writeFile "dist/direct-selfhost-preflight/runtime-legacy.mjs" (← emitRuntime true)
  let module := fixtureModule
  match psWasmLowerSpecializedModule (PsWasmTargetProfile.mk PsWasmWordSize.wasm32) module with
  | .error _ => throw (IO.userError "binary carrier fixture lowering refused")
  | .ok lowered => testWasmBinaryCarrier (psWasmServiceTransport lowered (psListMap (fun d => d.name) module.declarations))
  match psStrictValidateModule module with
  | .error _ => throw (IO.userError "Wasm transport fixture strict IR refused")
  | .ok validated =>
      let names := psListMap (fun (declaration : PsVerifiedIrDeclaration) => declaration.name) module.declarations
      match Ps.Internal.WasmCompilerService.emit validated names with
      | .error _ => throw (IO.userError "Wasm transport fixture emission refused")
      | .ok emitted => IO.FS.writeFile "dist/direct-selfhost-preflight/fixture.wasm.hex" emitted.fst
  match psIrEncodeModule module with
  | .error _ => throw (IO.userError "Wasm transport fixture IR encoding refused")
  | .ok encoded => IO.FS.writeFile "dist/direct-selfhost-preflight/fixture-ir.json" encoded
  IO.println "PSC1_DIRECT_SELFHOST_NATIVE: all-input name visitor equality; conservative fuel/hygiene; retained original runtime emitted; strict IR and owned Wasm binary fixture"
