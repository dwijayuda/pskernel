import Ps.BackendPhp.Portable

theorem psPhpCaptureBudgetFallback (context : PsPhp.Context)
    (parameters : List PsVerifiedIrParameter) (body : PsVerifiedIrExpr) :
    PsPhp.captureForWithFuel 0 context parameters body = PsPhp.capture context := by
  unfold PsPhp.captureForWithFuel
  split <;> rfl

private def natT : PsVerifiedIrType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat

private def parameter (name : String) : PsVerifiedIrParameter :=
  { name := name, type := natT }

private def expect (bound : List String) (body : PsVerifiedIrExpr)
    (names : List String) : IO Unit :=
  match PsPhp.freeGlobalNames 32 bound body with
  | Except.error _ => throw (IO.userError "capture analysis unexpectedly exhausted")
  | Except.ok actual =>
      unless actual == names do throw (IO.userError "lexical capture demand mismatch")

def main : IO Unit := do
  expect [] (.var "global") ["global"]
  expect ["global"] (.var "global") []
  expect [] (.lambda [parameter "global"] natT (.var "global")) []
  expect [] (.letE "global" natT (.var "global") (.var "global")) ["global"]
  expect [] (.lambda [parameter "outer"] (.function [natT] natT)
    (.lambda [parameter "inner"] natT (.var "global"))) ["global"]
  expect [] (.call (.var "next") [] [.var "input"]) ["next", "input"]
  expect [] (.matchE "Owner" [] (.var "subject")
    [("Ctor", ([{ field := "value", name := "global", type := natT }], .var "global"))]) ["subject"]
  let context : PsPhp.Context := PsPhp.Context.mk
    [("global", "$g0_global"), ("unrelated", "$g1_unrelated")] []
    [("global", "$v0_global")] ["$__ps_wrap"] true true false [] PsStringSet.empty
  let captured := PsPhp.captureFor context [] (.var "global")
  unless captured == " use ($v0_global, $__ps_wrap)" do
    throw (IO.userError "local shadowing or helper captures changed")
  let globals : PsPhp.Context := PsPhp.Context.mk context.globals [] [] context.helpers true true false [] PsStringSet.empty
  unless PsPhp.captureFor globals [] (.var "global") == " use (&$g0_global, $__ps_wrap)" do
    throw (IO.userError "needed global reference or global order lost")
  unless PsPhp.captureForWithFuel 0 globals [] (.var "global") == PsPhp.capture globals do
    throw (IO.userError "budget fallback lost a possible capture")
  let forward := PsPhp.captureFor globals [parameter "x"]
    (.lambda [parameter "y"] natT (.call (.var "global") [] [.var "y"]))
  unless forward == " use (&$g0_global, $__ps_wrap)" do
    throw (IO.userError "nested forward global demand lost")
  IO.println "PSC1_PHP_CAPTURE_ANALYSIS: complete budget fallback proof and lexical shadow/initializer/match/nested/forward/global-reference/helper cases passed"
