import Ps.BackendTs.Module

namespace PsKernelTsSaturatedTailRegression

def nat : PsVerifiedIrType := .primitive .nat
def param (name : String) : PsVerifiedIrParameter := ⟨name,nat⟩
def v (name : String) : PsVerifiedIrExpr := .var name
def n (value : Nat) : PsVerifiedIrExpr := .literal (.natural value)
def op (kind : PsVerifiedIrIntrinsic) (a b : PsVerifiedIrExpr) : PsVerifiedIrExpr := .intrinsic kind [] [a,b]
def call3 (name : String) (a b c : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  .call (.call (.call (v name) [] [a]) [] [b]) [] [c]
def helper : PsVerifiedIrDeclaration :=
  { name := "genericCurried",typeParameters := [],parameters := [param "hiddenFuel"],
    resultType := .function [nat] (.function [nat] nat),
    body := .ifE (op .natEq (v "hiddenFuel") (n 0))
      (.lambda [param "hiddenX"] (.function [nat] nat)
        (.lambda [param "hiddenY"] nat (op .natAdd (v "hiddenX") (v "hiddenY"))))
      (.lambda [param "hiddenX"] (.function [nat] nat)
        (.lambda [param "hiddenY"] nat
          (call3 "genericCurried" (op .natSub (v "hiddenFuel") (n 1))
            (v "hiddenY") (op .natAdd (v "hiddenX") (n 1))))) }
def forward : PsVerifiedIrDeclaration :=
  {name := "genericFlat",typeParameters := [],parameters := [param "fuel",param "x",param "y"],
   resultType := nat,body := call3 "genericCurried" (v "fuel") (v "x") (v "y")}
def none {α : Type} (x : Option α) : Bool := match x with | .none => true | .some _ => false
def some {α : Type} (x : Option α) : Bool := !none x

def controls : List (String × Bool) :=
  let emit := psTsEmitSaturatedTailLoop [] [] [helper];
  let emitted := emit forward;
  let output := match emitted with | .none => "" | .some s => s;
  [ ("saturated-exposed",some emitted),
    ("loop-emitted",output.contains "while (true)"),
    ("no-wrapper-in-recursive-worker",!output.contains "__ps$wrap"),
    ("no-generator-in-recursive-worker",!output.contains "function*"),
    ("parallel-state-update",output.contains "[fuel, x, y] = ["),
    ("callee-abi-kept",none (psTsEmitSaturatedTailLoop [] [] [helper,forward] helper)),
    ("missing-callee-declines",none (psTsEmitSaturatedTailLoop [] [] [] forward)),
    ("same-name-declines",none (emit {forward with name := "genericCurried"})),
    ("nonforwarding-argument-declines",none (emit {forward with body := call3 "genericCurried" (n 2) (v "x") (v "y")})),
    ("reordered-forwarding-declines",none (emit {forward with body := call3 "genericCurried" (v "fuel") (v "y") (v "x")})),
    ("polymorphic-wrapper-declines",none (emit {forward with typeParameters := [⟨"A"⟩]})),
    ("polymorphic-callee-declines",none (psTsEmitSaturatedTailLoop [] [] [{helper with typeParameters := [⟨"A"⟩]}] forward)),
    ("capture-declines",none (psTsEmitSaturatedTailLoop [] [] [{helper with body := .letE "x" nat (n 0) helper.body}] forward)),
    ("partial-self-declines",none (psTsSaturatedSelfWithFuel "genericCurried" "genericFlat" 3 4096 (.call (v "genericCurried") [] [n 1]))),
    ("escaping-self-declines",none (psTsSaturatedSelfWithFuel "genericCurried" "genericFlat" 3 4096 (v "genericCurried"))),
    ("shadowed-match-self-declines",none (psTsSaturatedSelfWithFuel "genericCurried" "genericFlat" 3 4096
      (.matchE "Shape" [] (v "value") [("node",[⟨"field","genericCurried",nat⟩],call3 "genericCurried" (n 1) (n 2) (n 3))]))),
    ("nested-self-argument-declines",none (psTsSaturatedSelfWithFuel "genericCurried" "genericFlat" 3 4096 (call3 "genericCurried" (n 1) (v "genericCurried") (n 0)))),
    ("bounded-spine-declines",none (psTsSaturatedSpineWithFuel 0 forward.body [])),
    ("bounded-application-declines",none (psTsSaturatedApplyWithFuel 0 helper.body [n 1])),
    ("bounded-rewrite-declines",none (psTsSaturatedSelfWithFuel "genericCurried" "genericFlat" 3 0 forward.body)),
    ("effectful-leaf-declines",none (psTsEmitSaturatedTailLoop [] [] [{helper with body := .lambda [param "hiddenX",param "hiddenY"] nat (.call (v "effect") [] [])}] forward)) ]

end PsKernelTsSaturatedTailRegression

def main : IO Unit := do
  for (name,ok) in PsKernelTsSaturatedTailRegression.controls do
    if !ok then throw (IO.userError ("SATURATED_TAIL_FAIL "++name))
    IO.println ("PSC1_SATURATED_TAIL_ASSERT "++name)
  let module := PsVerifiedIrModule.mk [] [] [] [PsKernelTsSaturatedTailRegression.helper,PsKernelTsSaturatedTailRegression.forward]
  match psTsEmitModule module with
  | .error _ => throw (IO.userError "generic fixture emission failed")
  | .ok source =>
      let out ← IO.getEnv "PSC1_SATURATED_FIXTURE"
      match out with
      | .none => throw (IO.userError "missing fixture destination")
      | .some path => IO.FS.writeFile path source
  IO.println "PSC1_SATURATED_TAIL_NATIVE: PASS controls=21"
