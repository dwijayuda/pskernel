import Ps.BackendWasm.Type

def psWasmLowerFloatBinary
    (type : PsVerifiedIrFloatingType)
    (operation : PsVerifiedIrFloatBinaryOp) :
    List PsWasmInstruction :=
  match type with
  | .float32 =>
      match operation with
      | .add => [.f32Add]
      | .sub => [.f32Sub]
      | .mul => [.f32Mul]
      | .div => [.f32Div]
  | .float =>
      match operation with
      | .add => [.f64Add]
      | .sub => [.f64Sub]
      | .mul => [.f64Mul]
      | .div => [.f64Div]

def psWasmLowerFloatCompare
    (type : PsVerifiedIrFloatingType)
    (operation : PsVerifiedIrFloatCompareOp) :
    List PsWasmInstruction :=
  match type with
  | .float32 =>
      match operation with
      | .eq => [.f32Eq]
      | .ne => [.f32Ne]
      | .lt => [.f32Lt]
      | .le => [.f32Le]
      | .gt => [.f32Gt]
      | .ge => [.f32Ge]
  | .float =>
      match operation with
      | .eq => [.f64Eq]
      | .ne => [.f64Ne]
      | .lt => [.f64Lt]
      | .le => [.f64Le]
      | .gt => [.f64Gt]
      | .ge => [.f64Ge]
