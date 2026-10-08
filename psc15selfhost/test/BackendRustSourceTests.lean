import Ps.DriverRust.Compiler

def psBackendRustScalarLeanSource : String :=
  "def idUInt8 (x : UInt8) : UInt8 := x\n" ++
  "def idUInt16 (x : UInt16) : UInt16 := x\n" ++
  "def idUInt32 (x : UInt32) : UInt32 := x\n" ++
  "def idUInt64 (x : UInt64) : UInt64 := x\n" ++
  "def idUSize (x : USize) : USize := x\n" ++
  "def idInt8 (x : Int8) : Int8 := x\n" ++
  "def idInt16 (x : Int16) : Int16 := x\n" ++
  "def idInt32 (x : Int32) : Int32 := x\n" ++
  "def idInt64 (x : Int64) : Int64 := x\n" ++
  "def idISize (x : ISize) : ISize := x\n" ++
  "def idFloat (x : Float) : Float := x\n" ++
  "def idFloat32 (x : Float32) : Float32 := x"

def psBackendRustScalarProofScriptSource : String :=
  "function idUInt8(x : UInt8): UInt8 := { x }\n" ++
  "function idUInt16(x : UInt16): UInt16 := { x }\n" ++
  "function idUInt32(x : UInt32): UInt32 := { x }\n" ++
  "function idUInt64(x : UInt64): UInt64 := { x }\n" ++
  "function idUSize(x : USize): USize := { x }\n" ++
  "function idInt8(x : Int8): Int8 := { x }\n" ++
  "function idInt16(x : Int16): Int16 := { x }\n" ++
  "function idInt32(x : Int32): Int32 := { x }\n" ++
  "function idInt64(x : Int64): Int64 := { x }\n" ++
  "function idISize(x : ISize): ISize := { x }\n" ++
  "function idFloat(x : Float): Float := { x }\n" ++
  "function idFloat32(x : Float32): Float32 := { x }"

def psBackendRustScalarOutputOk (output : String) : Bool :=
  output.contains "pub fn idUInt8(x: u8) -> u8 { (x).clone() }"
    && output.contains "pub fn idUInt16(x: u16) -> u16 { (x).clone() }"
    && output.contains "pub fn idUInt32(x: u32) -> u32 { (x).clone() }"
    && output.contains "pub fn idUInt64(x: u64) -> u64 { (x).clone() }"
    && output.contains "pub fn idUSize(x: usize) -> usize { (x).clone() }"
    && output.contains "pub fn idInt8(x: i8) -> i8 { (x).clone() }"
    && output.contains "pub fn idInt16(x: i16) -> i16 { (x).clone() }"
    && output.contains "pub fn idInt32(x: i32) -> i32 { (x).clone() }"
    && output.contains "pub fn idInt64(x: i64) -> i64 { (x).clone() }"
    && output.contains "pub fn idISize(x: isize) -> isize { (x).clone() }"
    && output.contains "pub fn idFloat(x: f64) -> f64 { (x).clone() }"
    && output.contains "pub fn idFloat32(x: f32) -> f32 { (x).clone() }"

def psTestBackendRustScalarLeanSource : Bool :=
  match
      psCompilerRustSource
        PsCompilerSourceKind.lean
        psBackendRustScalarLeanSource with
  | Except.error _ => false
  | Except.ok output => psBackendRustScalarOutputOk output

def psTestBackendRustScalarProofScriptSource : Bool :=
  match
      psCompilerRustSource
        PsCompilerSourceKind.proofScript
        psBackendRustScalarProofScriptSource with
  | Except.error _ => false
  | Except.ok output => psBackendRustScalarOutputOk output

def main : IO Unit := do
  if psTestBackendRustScalarLeanSource
      && psTestBackendRustScalarProofScriptSource then
    IO.println "PSC1_BACKEND_RUST_SOURCE_TESTS: PASS"
  else
    throw (IO.userError "PSC1_BACKEND_RUST_SOURCE_TESTS: FAIL")
