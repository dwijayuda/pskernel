import PSC1Kernel.NativeMap

open PSC1Kernel
open PSC1Kernel.NativeMap

def assertNativeMap (label : String) (ok : Bool) : IO Unit :=
  if ok then pure ()
  else throw <| IO.userError ("native map smoke failed: " ++ label)

def nativeSmokeName (text : String) : IO Name := do
  match nativeMapName text with
  | .ok name => pure name
  | .error err => throw <| IO.userError err

def runNativeProviderSmoke
    (provider : NativeEvaluator)
    (n b missing : Name) : IO Unit := do
  let natOk :=
    match provider.evalNat n with
    | .ok (some 42) => true
    | _ => false
  assertNativeMap "Nat lookup" natOk

  let boolOk :=
    match provider.evalBool b with
    | .ok (some false) => true
    | _ => false
  assertNativeMap "Bool lookup" boolOk

  let missingOk :=
    match provider.evalNat missing with
    | .ok none => true
    | _ => false
  assertNativeMap "missing lookup" missingOk

  let wrongKindFails :=
    match provider.evalBool n with
    | .error _ => true
    | _ => false
  assertNativeMap "kind mismatch" wrongKindFails

  -- Exercise the provider through the actual kernel WHNF/native path.
  let ctx : CheckerContext := {
    CheckerContext.empty Environment.empty with
    nativeEvaluator := some provider
  }
  let natMarker : Expr :=
    .app (.const kernelReduceNatName []) (.const n [])
  let natReduced ←
    match whnf ctx natMarker with
    | .ok value => pure value
    | .error err => throw <| IO.userError ("native Nat WHNF failed: " ++ err)
  assertNativeMap "Nat WHNF through map"
    (Expr.eq natReduced (.lit (.nat 42)))

  let boolMarker : Expr :=
    .app (.const kernelReduceBoolName []) (.const b [])
  let boolReduced ←
    match whnf ctx boolMarker with
    | .ok value => pure value
    | .error err => throw <| IO.userError ("native Bool WHNF failed: " ++ err)
  assertNativeMap "Bool WHNF through map"
    (Expr.eq boolReduced (.const kernelBoolFalseName []))

  let missingMarker : Expr :=
    .app (.const kernelReduceNatName []) (.const missing [])
  let missingReduced ←
    match whnf ctx missingMarker with
    | .ok value => pure value
    | .error err => throw <| IO.userError ("missing native WHNF failed: " ++ err)
  assertNativeMap "missing native result stays opaque"
    (Expr.eq missingReduced missingMarker)

def main (args : List String) : IO Unit := do
  match args with
  | [] => do
      let entries ←
        match parseNativeMap
          "nat\tNativeMapSmoke.n\t42\nbool\tNativeMapSmoke.b\tfalse\n" with
        | .ok value => pure value
        | .error err => throw <| IO.userError err
      runNativeProviderSmoke
        (nativeMapEvaluator entries)
        (← nativeSmokeName "NativeMapSmoke.n")
        (← nativeSmokeName "NativeMapSmoke.b")
        (← nativeSmokeName "NativeMapSmoke.missing")
  | [path] => do
      let provider ← loadNativeMap path
      runNativeProviderSmoke
        provider
        (← nativeSmokeName "PSC1NativeMapFixture.n")
        (← nativeSmokeName "PSC1NativeMapFixture.b")
        (← nativeSmokeName "PSC1NativeMapFixture.missing")
  | _ =>
      throw <| IO.userError "usage: NativeMapSmoke [native-map.tsv]"

  let duplicateRejects :=
    match parseNativeMap
      "nat\tNativeMapSmoke.n\t1\nnat\tNativeMapSmoke.n\t2\n" with
    | .error _ => true
    | .ok _ => false
  assertNativeMap "duplicate rejection" duplicateRejects

  IO.println "PSC1 native replay map smoke: PASS"
