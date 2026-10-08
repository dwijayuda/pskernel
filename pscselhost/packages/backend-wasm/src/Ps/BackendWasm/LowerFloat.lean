import Ps.BackendWasm.Type

def psWasmLowerFloatBinary
    (type : PsVerifiedIrFloatingType)
    (operation : PsVerifiedIrFloatBinaryOp) :
    List PsWasmInstruction :=
  match type, operation with
  | .float32, .add => [.f32Add]
  | .float32, .sub => [.f32Sub]
  | .float32, .mul => [.f32Mul]
  | .float32, .div => [.f32Div]
  | .float, .add => [.f64Add]
  | .float, .sub => [.f64Sub]
  | .float, .mul => [.f64Mul]
  | .float, .div => [.f64Div]

def psWasmLowerFloatCompare
    (type : PsVerifiedIrFloatingType)
    (operation : PsVerifiedIrFloatCompareOp) :
    List PsWasmInstruction :=
  match type, operation with
  | .float32, .eq => [.f32Eq]
  | .float32, .ne => [.f32Ne]
  | .float32, .lt => [.f32Lt]
  | .float32, .le => [.f32Le]
  | .float32, .gt => [.f32Gt]
  | .float32, .ge => [.f32Ge]
  | .float, .eq => [.f64Eq]
  | .float, .ne => [.f64Ne]
  | .float, .lt => [.f64Lt]
  | .float, .le => [.f64Le]
  | .float, .gt => [.f64Gt]
  | .float, .ge => [.f64Ge]
