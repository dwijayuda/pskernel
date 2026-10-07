import Ps.InterfaceIr.Wit
import Ps.InterfaceIr.Encode

def foreignPolicy : PsForeignPolicy :=
  PsForeignPolicy.mk "component-model" ["storage"] ["storage"] true 32

def foreignDefinitions : List PsForeignDefinition := [
  PsForeignDefinition.mk "file" PsForeignDefinitionBody.resource,
  PsForeignDefinition.mk "error" (PsForeignDefinitionBody.enumeration ["missing", "denied"]),
  PsForeignDefinition.mk "metadata" (PsForeignDefinitionBody.record [PsForeignField.mk "size" (PsForeignType.scalar PsForeignScalar.u64)]),
  PsForeignDefinition.mk "event" (PsForeignDefinitionBody.variant [PsForeignCase.mk "closed" Option.none,
    PsForeignCase.mk "opened" (Option.some (PsForeignType.named "metadata"))])
]

def foreignRead : PsForeignFunction :=
  PsForeignFunction.mk "read" [PsForeignField.mk "handle" (PsForeignType.borrow "file")]
    (Option.some (PsForeignType.result (Option.some (PsForeignType.list (PsForeignType.scalar PsForeignScalar.u8)))
      (Option.some (PsForeignType.named "error")))) false ["component-model", "javascript"]

def foreignWorld : PsForeignWorld :=
  PsForeignWorld.mk "psc-foreign-interface/1" "fixture" "storage" "client"
    [PsForeignInterface.mk "storage-api" foreignDefinitions [foreignRead] [] ["storage"]]
    ["storage-api"] []

def foreignWith (definitions : List PsForeignDefinition) (function : PsForeignFunction) : PsForeignWorld :=
  { foreignWorld with interfaces := [PsForeignInterface.mk "storage-api" definitions [function] [] ["storage"]] }

def foreignAccepts (policy : PsForeignPolicy) (world : PsForeignWorld) : Bool :=
  match psForeignValidateWorld policy world with
  | Except.ok _ => true
  | Except.error _ => false

def foreignIsExhausted : Bool :=
  match psForeignValidateWorld { foreignPolicy with typeDepth := 1 } foreignWorld with
  | Except.error PsForeignError.resourceExhausted => true
  | _ => false

def foreignEncoding : Bool :=
  match
      psForeignEncodeWorld
        foreignPolicy.typeDepth
        foreignWorld with
  | Except.error _ => false
  | Except.ok _ => true

def foreignEmission : Bool :=
  match psForeignEmitWit foreignPolicy foreignWorld with
  | Except.error _ => false
  | Except.ok source => source ==
      "package %fixture:%storage;\n\ninterface %storage-api {\n  resource %file;\n  enum %error { %missing, %denied }\n  record %metadata { %size: u64 }\n  variant %event { %closed, %opened(%metadata) }\n  %read: func(%handle: borrow<%file>) -> result<list<u8>, %error>;\n}\n\nworld %client {\n  import %storage-api;\n}\n"

def main : IO Unit := do
  let owned := { foreignRead with result := Option.some (PsForeignType.own "file") };
  let future := { foreignRead with parameters := [], asynchronous := true, result := Option.some (PsForeignType.future (Option.some (PsForeignType.stream (Option.some (PsForeignType.named "event"))))) };
  let cases : List (String × Bool) := [
    ("records variants results and resource borrowing", foreignAccepts foreignPolicy foreignWorld),
    ("owned resource result", foreignAccepts foreignPolicy (foreignWith foreignDefinitions owned)),
    ("future stream and async function", foreignAccepts foreignPolicy (foreignWith foreignDefinitions future)),
    ("canonical InterfaceIR encoding", foreignEncoding),
    ("WIT boundary output", foreignEmission),
    ("explicit exhaustion", foreignIsExhausted),
    ("import capability cannot be laundered through provider", !foreignAccepts { foreignPolicy with allowedImports := [] } foreignWorld),
    ("missing interface", !foreignAccepts foreignPolicy { foreignWorld with imports := ["missing"] }),
    ("invalid identifier injection", !foreignAccepts foreignPolicy { foreignWorld with packageName := "name; world injected {}" }),
    ("interface/world namespace conflict", !foreignAccepts foreignPolicy { foreignWorld with name := "storage-api" }),
    ("borrow cannot escape in result", !foreignAccepts foreignPolicy (foreignWith foreignDefinitions { foreignRead with result := Option.some (PsForeignType.borrow "file") })),
    ("async borrow unsupported", !foreignAccepts foreignPolicy (foreignWith foreignDefinitions { foreignRead with asynchronous := true })),
    ("nested borrow unsupported", !foreignAccepts foreignPolicy (foreignWith foreignDefinitions { foreignRead with parameters := [PsForeignField.mk "handles" (PsForeignType.list (PsForeignType.borrow "file"))] })),
    ("unknown resource", !foreignAccepts foreignPolicy (foreignWith [] owned)),
    ("target unavailable", !foreignAccepts { foreignPolicy with target := "rust" } foreignWorld),
    ("async policy disabled", !foreignAccepts { foreignPolicy with allowAsync := false } (foreignWith foreignDefinitions future)),
    ("recursive type cycle", !foreignAccepts foreignPolicy (foreignWith [PsForeignDefinition.mk "cycle" (PsForeignDefinitionBody.alias (PsForeignType.named "cycle"))] { foreignRead with parameters := [], result := Option.some (PsForeignType.named "cycle") })),
    ("duplicate enum cases", !foreignAccepts foreignPolicy (foreignWith [PsForeignDefinition.mk "bad" (PsForeignDefinitionBody.enumeration ["same", "same"])] { foreignRead with parameters := [], result := Option.none }))
  ];
  for entry in cases do
    if !entry.2 then throw (IO.userError ("PSCV_FOREIGN_INTERFACE_TESTS: FAIL " ++ entry.1));
  IO.println ("PSCV_FOREIGN_INTERFACE_TESTS: PASS (" ++ toString cases.length ++ " cases)")
