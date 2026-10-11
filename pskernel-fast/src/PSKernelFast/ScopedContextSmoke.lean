import PSKernelFast.ScopedContext

namespace PSKernelFast.Core

private def require (ok : Bool) (message : String) : IO Unit :=
  if ok then pure () else throw <| IO.userError message

private def expectFailure (result : Except ScopedError α)
    (error : ScopedError) : IO Unit :=
  match result with
  | .error actual => require (actual == error) "scope failure category changed"
  | .ok _ => throw <| IO.userError "malformed binder was unexpectedly stored"

private def expectOk (result : Except ScopedError (AnyScopedFrame params)) :
    IO (AnyScopedFrame params) :=
  match result with
  | .ok frame => pure frame
  | .error _ => throw <| IO.userError "valid binder entry was declined"

/-- Scope *structure* and unchanged-parent regression, not dependent typing. -/
def scopedContextSmoke : IO Unit := do
  let u : KName := .str .anonymous "u"
  let v : KName := .str .anonymous "v"
  let outer := AnyScopedFrame.empty [u]

  require (outer.depth == 0 && (outer.rawDomainAt 0).isNone)
    "empty local context contained a binder"
  expectFailure (outer.extend (.bvar 0)) .malformedBinder
  expectFailure (outer.extend (.sort (.param v))) .malformedBinder
  expectFailure (outer.extend (.mvar u)) .malformedBinder

  let c1 ← expectOk <| outer.extend (.sort (.param u))
  require (c1.depth == 1) "scoped parent depth not incremented"
  require (c1.rawDomainAt 0 == some (.sort (.param u)))
    "stored outer binder domain lost"
  require (outer.depth == 0 && (outer.rawDomainAt 0).isNone)
    "immutable parent was changed by extension"

  let c2 ← expectOk <| c1.extend (.bvar 0)
  require (c2.depth == 2) "second binder depth not incremented"
  require (c2.rawDomainAt 0 == some (.bvar 0))
    "newest raw binder domain was not stored exactly"
  require (c2.rawDomainAt 1 == some (.sort (.param u)))
    "outer raw binder domain was lost"
  require ((c2.rawDomainAt 2).isNone)
    "nonexistent binder index was accepted"

  expectFailure (c2.extend (.bvar 2)) .malformedBinder
  expectFailure (c2.extend (.fvar u)) .malformedBinder
  let c3 ← expectOk <| c2.extend (.bvar 1)
  require (c3.depth == 3) "third binder did not increment depth"
  require (c2.depth == 2 && (c2.rawDomainAt 2).isNone)
    "failed or successful extension mutated prior scope"

  IO.println "PSKernel-Fast G4.3: proof-carrying structural binder frame PASS"
  IO.println "G4.3 limit: stored domains are raw observations, not inferred types"
end PSKernelFast.Core

def main : IO Unit := PSKernelFast.Core.scopedContextSmoke
