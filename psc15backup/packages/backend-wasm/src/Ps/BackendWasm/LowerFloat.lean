import Ps.BackendWasm.Type

def psWasmLowerFloatBinary
    (type : PsVerifiedIrFloatingType)
    (operation : PsVerifiedIrFloatBinaryOp) :
    List PsWasmInstruction :=
  match type with
  | .float32 =>
      match operation with
      | .add => [PsWasmInstruction.f32Add]
      | .sub => [PsWasmInstruction.f32Sub]
      | .mul => [PsWasmInstruction.f32Mul]
      | .div => [PsWasmInstruction.f32Div]
  | .float =>
      match operation with
      | .add => [PsWasmInstruction.f64Add]
      | .sub => [PsWasmInstruction.f64Sub]
      | .mul => [PsWasmInstruction.f64Mul]
      | .div => [PsWasmInstruction.f64Div]

def psWasmLowerFloatCompare
    (type : PsVerifiedIrFloatingType)
    (operation : PsVerifiedIrFloatCompareOp) :
    List PsWasmInstruction :=
  match type with
  | .float32 =>
      match operation with
      | .eq => [PsWasmInstruction.f32Eq]
      | .ne => [PsWasmInstruction.f32Ne]
      | .lt => [PsWasmInstruction.f32Lt]
      | .le => [PsWasmInstruction.f32Le]
      | .gt => [PsWasmInstruction.f32Gt]
      | .ge => [PsWasmInstruction.f32Ge]
  | .float =>
      match operation with
      | .eq => [PsWasmInstruction.f64Eq]
      | .ne => [PsWasmInstruction.f64Ne]
      | .lt => [PsWasmInstruction.f64Lt]
      | .le => [PsWasmInstruction.f64Le]
      | .gt => [PsWasmInstruction.f64Gt]
      | .ge => [PsWasmInstruction.f64Ge]
