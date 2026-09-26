import Ps.BackendRust.Compiler

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
  "def idFloat32 (x : Float32) : Float32 := x\n"

def psBackendRustScalarProofScriptSource : String :=
  "def idUInt8(x : UInt8) : UInt8 := x;\n" ++
  "def idUInt16(x : UInt16) : UInt16 := x;\n" ++
  "def idUInt32(x : UInt32) : UInt32 := x;\n" ++
  "def idUInt64(x : UInt64) : UInt64 := x;\n" ++
  "def idUSize(x : USize) : USize := x;\n" ++
  "def idInt8(x : Int8) : Int8 := x;\n" ++
  "def idInt16(x : Int16) : Int16 := x;\n" ++
  "def idInt32(x : Int32) : Int32 := x;\n" ++
  "def idInt64(x : Int64) : Int64 := x;\n" ++
  "def idISize(x : ISize) : ISize := x;\n" ++
  "def idFloat(x : Float) : Float := x;\n" ++
  "def idFloat32(x : Float32) : Float32 := x;\n"

def psBackendRustSourceContainsScalars (output : String) : Bool :=
  output.contains "pub fn idUInt8"
    && output.contains "pub fn idUInt16"
    && output.contains "pub fn idUInt32"
    && output.contains "pub fn idUInt64"
    && output.contains "pub fn idUSize"
    && output.contains "pub fn idInt8"
    && output.contains "pub fn idInt16"
    && output.contains "pub fn idInt32"
    && output.contains "pub fn idInt64"
    && output.contains "pub fn idISize"
    && output.contains "pub fn idFloat"
    && output.contains "pub fn idFloat32"

def psTestBackendRustLeanSource : Bool :=
  match
      psCompilerRustSource
        PsCompilerSourceKind.lean
        psBackendRustScalarLeanSource with
  | Except.error _ => false
  | Except.ok output => psBackendRustSourceContainsScalars output

def psTestBackendRustProofScriptSource : Bool :=
  match
      psCompilerRustSource
        PsCompilerSourceKind.proofScript
        psBackendRustScalarProofScriptSource with
  | Except.error _ => false
  | Except.ok output => psBackendRustSourceContainsScalars output

def main : IO Unit := do
  if psTestBackendRustLeanSource then
    IO.println "PSC1_BACKEND_RUST_SOURCE_PASS: Lean source -> Rust"
  else
    throw (IO.userError "PSC1_BACKEND_RUST_SOURCE_FAIL: Lean source -> Rust")
  if psTestBackendRustProofScriptSource then
    IO.println "PSC1_BACKEND_RUST_SOURCE_PASS: ProofScript source -> Rust"
  else
    throw (IO.userError "PSC1_BACKEND_RUST_SOURCE_FAIL: ProofScript source -> Rust")
