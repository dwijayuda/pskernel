import BackendJsFixture
import BackendJsTailFixture
import BackendJsPropertyFixture
import Ps.BackendJs.Print
import Ps.BackendTs.Module

def psBackendJsDiffEmitJs : Except String String :=
  match psBackendJsFixtureValidated with
  | Except.error error => Except.error error
  | Except.ok validated =>
      match psJsEmitValidatedModule validated with
      | Except.error _ => Except.error "JS"
      | Except.ok output => Except.ok output

def psBackendJsDiffEmitTs : Except String String :=
  match psBackendJsFixtureValidated with
  | Except.error error => Except.error error
  | Except.ok validated =>
      match psTsEmitValidatedModule validated with
      | Except.error _ => Except.error "TS"
      | Except.ok output => Except.ok output

def main (args : List String) : IO Unit := do
  match args with
  | ["tail"] =>
      match psJsPrintModuleStackSafe psJsTailFixtureModule with
      | Except.error _ => throw (IO.userError "PSC2_BACKEND_JS_TAIL_EMIT_FAILED")
      | Except.ok output => IO.print output
  | ["js"] =>
      match psBackendJsDiffEmitJs with
      | Except.error target =>
          throw
            (IO.userError
              ("PSC2_BACKEND_JS_DIFF_EMIT_FAILED: " ++
                target))
      | Except.ok output =>
          IO.print output
  | ["ts"] =>
      match psBackendJsDiffEmitTs with
      | Except.error target =>
          throw
            (IO.userError
              ("PSC2_BACKEND_JS_DIFF_EMIT_FAILED: " ++
                target))
      | Except.ok output =>
          IO.print output
  | [target] =>
      if target == "properties-js" || target == "properties-js-stack" || target == "properties-ts" then
        match psPropertyEmit target with
        | Except.error error => throw (IO.userError error)
        | Except.ok output => IO.print output
      else throw (IO.userError "unknown fixture target")
  | _ =>
      throw
        (IO.userError
          "usage: psc1_backend_js_diff_fixture <js|ts|tail>")
