import Ps.InterfaceIr.CanonicalAbi

def scalar (value : PsForeignScalar) : PsForeignType := .scalar value

def layout (width : PsCanonicalPointerWidth) (type : PsForeignType) : Except PsForeignError PsCanonicalLayout :=
  psCanonicalTypeWithFuel width [] [] 64 type

def codes (values : List PsCanonicalFlatType) : List Nat := values.map psCanonicalFlatCode

def scalarAndRecord : Bool :=
  match layout .memory32 (.tuple [scalar .u8, scalar .u64, scalar .u16]) with
  | .error _ => false
  | .ok value => value.alignment == 8 && value.byteSize == 24 &&
      value.fieldOffsets == [0, 8, 16] && value.flatCount == 3 && codes value.flatPrefix == [0, 1, 0]

def memoryWidths : Bool :=
  match layout .memory32 (scalar .string), layout .memory64 (scalar .string),
      layout .memory64 (.list (scalar .u8)) with
  | .ok first, .ok second, .ok third =>
      first.byteSize == 8 && first.alignment == 4 && codes first.flatPrefix == [0, 0] &&
      second.byteSize == 16 && second.alignment == 8 && codes second.flatPrefix == [1, 1] &&
      third.byteSize == 16 && third.needsMemory
  | _, _, _ => false

def variants : Bool :=
  match layout .memory32 (.result (some (scalar .f32)) (some (scalar .u32))),
      layout .memory64 (.option (scalar .u64)),
      layout .memory32 (.result (some (scalar .f64)) (some (scalar .u32))) with
  | .ok first, .ok second, .ok third =>
      first.byteSize == 8 && first.payloadOffset == 4 && codes first.flatPrefix == [0, 0] &&
      second.byteSize == 16 && second.payloadOffset == 8 && codes second.flatPrefix == [0, 1] &&
      codes third.flatPrefix == [0, 1]
  | _, _, _ => false

def tagWidths : Bool :=
  let size := fun (count : Nat) =>
    match psCanonicalDiscriminantSize count with | .ok value => value | .error _ => 0
  [1, 256, 257, 65536, 65537, 4294967295].map size == [1, 1, 2, 2, 4, 4]

def noTagOverflow : Bool :=
  match psCanonicalDiscriminantSize 0, psCanonicalDiscriminantSize 4294967296 with
  | .error _, .error _ => true
  | _, _ => false

def indirect : Bool :=
  match psCanonicalSequence (List.replicate 100 (psCanonicalScalarLayout 4 .i32)),
      layout .memory64 (scalar .string) with
  | .ok args, .ok returned =>
      let lower := psCanonicalSignature .memory64 "host" "call" .lower args returned
      let lift := psCanonicalSignature .memory64 "host" "call" .lift args returned
      args.flatCount == 100 && args.flatPrefix.length == 17 &&
        lower.indirectParameters && lower.indirectResult && codes lower.coreParameters == [1, 1] &&
        lower.coreResults.isEmpty && codes lift.coreParameters == [1] && codes lift.coreResults == [1]
  | _, _ => false

def directThreshold : Bool :=
  match psCanonicalSequence (List.replicate 16 (psCanonicalScalarLayout 4 .i32)),
      psCanonicalSequence (List.replicate 17 (psCanonicalScalarLayout 4 .i32)) with
  | .ok direct, .ok indirectArgs =>
      let result := psCanonicalScalarLayout 4 .f32
      let a := psCanonicalSignature .memory32 "i" "f" .lower direct result
      let b := psCanonicalSignature .memory32 "i" "f" .lower indirectArgs result
      !a.indirectParameters && !a.indirectResult && a.coreParameters.length == 16 &&
        codes a.coreResults == [2] && b.indirectParameters && codes b.coreParameters == [0]
  | _, _ => false

def fixtureWorld (asynchronous : Bool) : PsForeignWorld :=
  let fn := PsForeignFunction.mk "call" [PsForeignField.mk "x" (scalar .u32)]
    (some (scalar .string)) asynchronous ["component-model"]
  let iface := PsForeignInterface.mk "host" [] [fn] ["io"] ["io"]
  PsForeignWorld.mk "psc-foreign-interface/1" "psc" "abi" "world" [iface] ["host"] ["host"]

def policy : PsForeignPolicy := PsForeignPolicy.mk "component-model" ["io"] ["io"] false 64

def worldPlans : Bool :=
  match psCanonicalPlanWorld policy .memory32 (fixtureWorld false) with
  | .ok [lower, lift] => codes lower.coreParameters == [0, 0] &&
      lower.coreResults.isEmpty && codes lift.coreParameters == [0] && codes lift.coreResults == [0]
  | _ => false

def rejectedProfiles : Bool :=
  let rejects := fun (value : Except PsForeignError (List PsCanonicalFunctionPlan)) =>
    match value with | .error _ => true | .ok _ => false
  rejects (psCanonicalPlanWorld policy .memory32 (fixtureWorld true)) &&
    rejects (psCanonicalPlanWorld { policy with allowedImports := [] } .memory32 (fixtureWorld false)) &&
    rejects (psCanonicalPlanWorld { policy with target := "javascript" } .memory32 (fixtureWorld false)) &&
    rejects (psCanonicalPlanWorld { policy with allowAsync := true } .memory32 (fixtureWorld false))

-- Shared named definitions double in size without exponential planner expansion.
def doubling (count : Nat) : List PsForeignDefinition :=
  let first := PsForeignDefinition.mk "t0" (.alias (scalar .u8))
  let rest := (List.range count).map fun index =>
    let previous := "t" ++ toString index
    PsForeignDefinition.mk ("t" ++ toString (index + 1))
      (.record [PsForeignField.mk "a" (.named previous), PsForeignField.mk "b" (.named previous)])
  first :: rest

def sharedGraphAndSizeBound : Bool :=
  match psCanonicalResolve .memory64 (doubling 27).reverse 64,
      psCanonicalResolve .memory64 (doubling 28) 64 with
  | .ok layouts, .error _ =>
      match psCanonicalFindLayout layouts "t27" with
      | .some value => value.byteSize == 134217728 && value.flatCount == 134217728 &&
          value.flatPrefix.length == 17
      | .none => false
  | _, _ => false

def handleObligation : Bool :=
  let resource := PsForeignDefinition.mk "file" .resource
  match psCanonicalTypeWithFuel .memory64 [resource] [] 64 (.own "file") with
  | .ok value => value.byteSize == 4 && codes value.flatPrefix == [0] && value.needsHandleTable
  | .error _ => false

def malformedAndFuel : Bool :=
  let rejects := fun (value : Except PsForeignError PsCanonicalLayout) =>
    match value with | .error _ => true | .ok _ => false
  rejects (layout .memory32 (.tuple [])) &&
    rejects (layout .memory32 (.named "missing")) &&
    rejects (layout .memory32 (.future none)) &&
    rejects (psCanonicalTypeWithFuel .memory32 [] [] 0 (scalar .u8))

def main : IO Unit := do
  let tests := [("record alignment/offsets", scalarAndRecord), ("pointer widths", memoryWidths),
    ("variant joins/payload alignment", variants), ("tag widths", tagWidths),
    ("tag bounds", noTagOverflow), ("indirect lift/lower", indirect),
    ("direct threshold", directThreshold), ("world plans", worldPlans),
    ("policy rejection", rejectedProfiles), ("shared graph/size bound", sharedGraphAndSizeBound),
    ("handle-table obligation", handleObligation), ("unsupported/fuel", malformedAndFuel)]
  for (name, passed) in tests do
    if !passed then throw (IO.userError ("PSC_CANONICAL_ABI_FAIL: " ++ name))
    IO.println ("PSC_CANONICAL_ABI_PASS: " ++ name)
  IO.println "PSC_CANONICAL_ABI_TESTS: PASS"
