import Ps.InterfaceIr.CanonicalAbi
import Ps.InterfaceIr.Encode

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

def graphWorld (definitions : List PsForeignDefinition) (argument : PsForeignType) : PsForeignWorld :=
  let fn := PsForeignFunction.mk "call" [PsForeignField.mk "x" argument] none false ["component-model"]
  let iface := PsForeignInterface.mk "host" definitions [fn] [] []
  PsForeignWorld.mk "psc-foreign-interface/1" "psc" "abi" "world" [iface] ["host"] []

def sharedGraphPublicBoundary : Bool :=
  let world := graphWorld (doubling 27).reverse (.named "t27")
  match psCanonicalPlanWorld { policy with typeDepth := 29 } .memory32 world,
      psCanonicalPlanWorld { policy with typeDepth := 28 } .memory32 world with
  | .ok [plan], .error .resourceExhausted =>
      plan.indirectParameters && !plan.indirectResult &&
        codes plan.coreParameters == [0] && plan.parameterLayout.byteSize == 134217728
  | _, _ => false

def graphFailures : Bool :=
  let rejects := fun (definitions : List PsForeignDefinition) =>
    match psForeignAnalyzeDefinitions false 64 definitions with | .error _ => true | .ok _ => false
  rejects [PsForeignDefinition.mk "a" (.alias (.named "b")), PsForeignDefinition.mk "b" (.alias (.named "a"))] &&
    rejects [PsForeignDefinition.mk "a" (.alias (.named "missing"))] &&
    rejects [PsForeignDefinition.mk "file" .resource, PsForeignDefinition.mk "alias" (.alias (.borrow "file"))]

-- A zero-depth enum body still consumes one node at a named reference.
def graphDepthEdges : Bool :=
  let choice := PsForeignDefinition.mk "choice" (.enumeration ["one"])
  let defs := [choice,
    PsForeignDefinition.mk "maybe" (.alias (.option (.named "choice")))]
  match psForeignValidateWorld { policy with typeDepth := 1 } (graphWorld [choice] (.named "choice")),
      psForeignValidateWorld { policy with typeDepth := 3 } (graphWorld defs (.named "maybe")),
      psForeignValidateWorld { policy with typeDepth := 2 } (graphWorld defs (.named "maybe")) with
  | .ok _, .ok _, .error .resourceExhausted => true
  | _, _, _ => false

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

def memoryDefinitions : List PsForeignDefinition := [
  PsForeignDefinition.mk "bytes" (.alias (.list (scalar .u8))),
  PsForeignDefinition.mk "text" (.alias (scalar .string)),
  PsForeignDefinition.mk "wide" (.alias (scalar .u64)),
  PsForeignDefinition.mk "wide-list" (.alias (.list (scalar .u64))),
  PsForeignDefinition.mk "signed" (.alias (scalar .s16)),
  PsForeignDefinition.mk "letter" (.alias (scalar .char)),
  PsForeignDefinition.mk "boolean" (.alias (scalar .bool)),
  PsForeignDefinition.mk "single" (.alias (scalar .f32)),
  PsForeignDefinition.mk "mixed" (.variant [PsForeignCase.mk "narrow" (some (scalar .f32)),
    PsForeignCase.mk "wide" (some (scalar .f64)), PsForeignCase.mk "count" (some (scalar .u32)),
    PsForeignCase.mk "absent" none]),
  PsForeignDefinition.mk "bulk" (.alias (.tuple (List.replicate 17 (scalar .u8)))),
  PsForeignDefinition.mk "choice" (.enumeration ["first", "second"]),
  PsForeignDefinition.mk "maybe" (.alias (.option (scalar .u64))),
  PsForeignDefinition.mk "outcome" (.alias (.result (some (scalar .string)) (some (scalar .u32)))),
  PsForeignDefinition.mk "pair" (.alias (.tuple [scalar .u8, scalar .u64, scalar .u16])),
  PsForeignDefinition.mk "message" (.record [
    PsForeignField.mk "name" (.named "text"), PsForeignField.mk "data" (.named "bytes"),
    PsForeignField.mk "constructor" (.named "wide"), PsForeignField.mk "status" (.named "maybe")])
]

def memoryFunctions : List PsForeignFunction := [
  PsForeignFunction.mk "echo-text" [PsForeignField.mk "x" (scalar .string)] (some (scalar .string)) false ["component-model"],
  PsForeignFunction.mk "count" [] (some (scalar .u32)) false ["component-model"],
  PsForeignFunction.mk "last" ((List.range 17).map fun index =>
    PsForeignField.mk ("x" ++ toString index) (scalar .u8)) (some (scalar .u8)) false ["component-model"]
]

def memoryWorld : PsForeignWorld :=
  PsForeignWorld.mk "psc-foreign-interface/1" "psc" "codec" "world"
    [PsForeignInterface.mk "values" memoryDefinitions memoryFunctions [] []] ["values"] ["values"]

def memoryFlatJson (value : PsCanonicalFlatType) : String :=
  psJsonQuote (match value with | .i32 => "i32" | .i64 => "i64" | .f32 => "f32" | .f64 => "f64")

def memoryBoolJson (value : Bool) : String := if value then "true" else "false"

def memoryLayoutJson (value : PsCanonicalLayout) : String :=
  psJsonArray [psNatToString value.alignment, psNatToString value.byteSize, psNatToString value.flatCount,
    psJsonArray (value.flatPrefix.map memoryFlatJson), psJsonArray (value.fieldOffsets.map psNatToString),
    psNatToString value.payloadOffset, memoryBoolJson value.needsMemory, memoryBoolJson value.needsHandleTable]

def memoryFixtureLayouts (width : PsCanonicalPointerWidth) : String :=
  match psCanonicalResolve width memoryDefinitions 64 with
  | .error _ => "null"
  | .ok layouts => psJsonArray (layouts.map fun entry =>
      psJsonArray [psJsonQuote entry.1, memoryLayoutJson entry.2])

def memoryFunctionJson (value : PsCanonicalFunctionPlan) : String :=
  let direction := match value.direction with | .lift => "lift" | .lower => "lower"
  psJsonArray [psJsonQuote value.functionName, psJsonQuote direction,
    psJsonArray (value.coreParameters.map memoryFlatJson), psJsonArray (value.coreResults.map memoryFlatJson)]

def memoryFunctionPlans (width : PsCanonicalPointerWidth) : String :=
  match psCanonicalPlanWorld policy width memoryWorld with
  | .error _ => "null"
  | .ok plans => psJsonArray (plans.map memoryFunctionJson)

def memoryFixture : String :=
  match psForeignEncodeWorld 64 memoryWorld with
  | .error _ => "null"
  | .ok world => psJsonArray [world, memoryFixtureLayouts .memory32, memoryFixtureLayouts .memory64,
      memoryFunctionPlans .memory32, memoryFunctionPlans .memory64]

def runTests : IO Unit := do
  let tests := [("record alignment/offsets", scalarAndRecord), ("pointer widths", memoryWidths),
    ("variant joins/payload alignment", variants), ("tag widths", tagWidths),
    ("tag bounds", noTagOverflow), ("indirect lift/lower", indirect),
    ("direct threshold", directThreshold), ("world plans", worldPlans),
    ("policy rejection", rejectedProfiles), ("shared graph/size bound", sharedGraphAndSizeBound),
    ("shared graph public boundary/depth", sharedGraphPublicBoundary),
    ("cycles/missing/borrow aliases", graphFailures), ("exact named depth edges", graphDepthEdges),
    ("handle-table obligation", handleObligation), ("unsupported/fuel", malformedAndFuel)]
  for (name, passed) in tests do
    if !passed then throw (IO.userError ("PSC_CANONICAL_ABI_FAIL: " ++ name))
    IO.println ("PSC_CANONICAL_ABI_PASS: " ++ name)
  IO.println "PSC_CANONICAL_ABI_TESTS: PASS"


def main (arguments : List String) : IO Unit := do
  if arguments == ["--memory-fixture"] then IO.println memoryFixture else runTests
