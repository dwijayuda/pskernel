import Ps.BackendRust.Module
import Ps.BackendRust.Coverage

def psBackendRustIdentityModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := []
    declarations := [
      {
        name := "idNat"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body := PsVerifiedIrExpr.var "x"
      }
    ]
  }

def psTestBackendRustIdentity : Bool :=
  match psRustEmitModule psBackendRustIdentityModule with
  | Except.error _ => false
  | Except.ok output =>
      output.contains "#![forbid(unsafe_code)]"
        && output.contains "pub fn idNat(x: PsNat) -> PsNat { x }"

def psBackendRustIntrinsicModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := []
    declarations := [
      {
        name := "plusOne"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natAdd
            [
              PsVerifiedIrExpr.var "x",
              PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 1)
            ]
      }
    ]
  }

def psTestBackendRustIntrinsic : Bool :=
  match psRustEmitModule psBackendRustIntrinsicModule with
  | Except.error _ => false
  | Except.ok output =>
      output.contains "__ps_nat_add(&(x), &(__ps_nat_lit(\"1\")))"

def psBackendRustAdtModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := [
      {
        name := "Pair"
        typeParameters := []
        fields := [
          {
            name := "left"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          },
          {
            name := "right"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
      }
    ]
    inductives := [
      {
        name := "Maybe"
        typeParameters := [{ name := "A" }]
        constructors := [
          {
            name := "none"
            fields := []
          },
          {
            name := "some"
            fields := [
              {
                name := "value"
                type := PsVerifiedIrType.typeParameter "A"
              }
            ]
          }
        ]
      }
    ]
    declarations := [
      {
        name := "leftOfPair"
        typeParameters := []
        parameters := [
          {
            name := "pair"
            type := PsVerifiedIrType.named "Pair" []
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.projection
            "Pair"
            (PsVerifiedIrExpr.var "pair")
            "left"
      },
      {
        name := "wrapNat"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType :=
          PsVerifiedIrType.named
            "Maybe"
            [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
        body :=
          PsVerifiedIrExpr.constructor
            "Maybe"
            "some"
            [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
            [
              ("value", PsVerifiedIrExpr.var "x")
            ]
      }
    ]
  }

def psTestBackendRustAdt : Bool :=
  match psRustEmitModule psBackendRustAdtModule with
  | Except.error _ => false
  | Except.ok output =>
      output.contains "pub struct Pair { pub left: PsNat, pub right: PsNat }"
        && output.contains "pub enum Maybe<A: Clone> { none {}, some { value: A } }"
        && output.contains "Maybe::some { value: x }"
        && output.contains "pub fn leftOfPair(pair: Pair) -> PsNat { (pair).left }"

def psBackendRustStringModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := []
    declarations := [
      {
        name := "pushBang"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.string
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.string
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.stringPush
            [
              PsVerifiedIrExpr.var "value",
              PsVerifiedIrExpr.intrinsic
                PsVerifiedIrIntrinsic.charOfNat
                [
                  PsVerifiedIrExpr.literal
                    (PsVerifiedIrLiteral.natural 33)
                ]
            ]
      },
      {
        name := "utf8Size"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.string
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.stringUtf8ByteSize
            [PsVerifiedIrExpr.var "value"]
      }
    ]
  }

def psTestBackendRustStringIntrinsics : Bool :=
  match psRustEmitModule psBackendRustStringModule with
  | Except.error _ => false
  | Except.ok output =>
      output.contains "__ps_string_push(&(value), __ps_char_of_nat(&(__ps_nat_lit(\"33\"))))"
        && output.contains "__ps_string_utf8_byte_size(&(value))"

def psBackendRustArrayModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := []
    declarations := [
      {
        name := "arraySizeDemo"
        typeParameters := []
        parameters := [
          {
            name := "xs"
            type :=
              PsVerifiedIrType.named
                "Array"
                [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.arraySize
            [PsVerifiedIrExpr.var "xs"]
      },
      {
        name := "arrayIdOnly"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body := PsVerifiedIrExpr.var "x"
      },
      {
        name := "arrayMapDemo"
        typeParameters := []
        parameters := [
          {
            name := "xs"
            type :=
              PsVerifiedIrType.named
                "Array"
                [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
          }
        ]
        resultType :=
          PsVerifiedIrType.named
            "Array"
            [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.arrayMap
            [
              PsVerifiedIrExpr.var "arrayIdOnly",
              PsVerifiedIrExpr.var "xs"
            ]
      }
    ]
  }

def psTestBackendRustArrayIntrinsics : Bool :=
  match psRustEmitModule psBackendRustArrayModule with
  | Except.error _ => false
  | Except.ok output =>
      output.contains "pub fn arraySizeDemo(xs: Vec<PsNat>) -> PsNat"
        && output.contains "__ps_array_size(&(xs))"
        && output.contains "__ps_array_map(arrayIdOnly, &(xs))"

def psBackendRustValueModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := []
    declarations := [
      {
        name := "one"
        typeParameters := []
        parameters := []
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body := PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 1)
      },
      {
        name := "addGlobalOne"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natAdd
            [
              PsVerifiedIrExpr.var "x",
              PsVerifiedIrExpr.var "one"
            ]
      },
      {
        name := "shadowOne"
        typeParameters := []
        parameters := [
          {
            name := "one"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body := PsVerifiedIrExpr.var "one"
      }
    ]
  }

def psTestBackendRustValues : Bool :=
  match psRustEmitModule psBackendRustValueModule with
  | Except.error _ => false
  | Except.ok output =>
      output.contains
          "pub fn one() -> PsNat { __ps_nat_lit(\"1\") }"
        && output.contains
          "__ps_nat_add(&(x), &((one)()))"
        && output.contains
          "pub fn shadowOne(one: PsNat) -> PsNat { one }"

def psTestBackendRustScalarTypes : Bool :=
  psRustEmitPrimitiveType PsVerifiedIrPrimitiveType.uint8 == "u8"
    && psRustEmitPrimitiveType PsVerifiedIrPrimitiveType.uint16 == "u16"
    && psRustEmitPrimitiveType PsVerifiedIrPrimitiveType.uint32 == "u32"
    && psRustEmitPrimitiveType PsVerifiedIrPrimitiveType.uint64 == "u64"
    && psRustEmitPrimitiveType PsVerifiedIrPrimitiveType.usize == "usize"
    && psRustEmitPrimitiveType PsVerifiedIrPrimitiveType.int8 == "i8"
    && psRustEmitPrimitiveType PsVerifiedIrPrimitiveType.int16 == "i16"
    && psRustEmitPrimitiveType PsVerifiedIrPrimitiveType.int32 == "i32"
    && psRustEmitPrimitiveType PsVerifiedIrPrimitiveType.int64 == "i64"
    && psRustEmitPrimitiveType PsVerifiedIrPrimitiveType.isize == "isize"
    && psRustEmitPrimitiveType PsVerifiedIrPrimitiveType.float == "f64"
    && psRustEmitPrimitiveType PsVerifiedIrPrimitiveType.float32 == "f32"

def psTestBackendRustIdentifiers : Bool :=
  psStringEq (psRustIdentifier "type") "r#type"
    && psStringEq (psRustIdentifier "fn") "r#fn"
    && psStringEq (psRustIdentifier "self") "__ps_kw_self"
    && psStringEq (psRustIdentifier "Self") "__ps_kw_Self"
    && psStringEq
      (psRustIdentifier "value$1")
      "__psr_value_u36_1"
    && psStringEq
      (psRustIdentifier "9value")
      "__psr_9value"
    && psStringEq
      (psRustIdentifier "__psr_value")
      "__psr___psr_value"

def psBackendRustUnsupportedImportModule : PsVerifiedIrModule :=
  {
    imports := [
      {
        localName := "hostValue"
        source := "host"
        importedName := "value"
        type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
      }
    ]
    structures := []
    inductives := []
    declarations := []
  }

def psBackendRustUnknownTypeModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := []
    declarations := [
      {
        name := "unknownValue"
        typeParameters := []
        parameters := []
        resultType := PsVerifiedIrType.unknown
        body := PsVerifiedIrExpr.literal PsVerifiedIrLiteral.unit
      }
    ]
  }

def psTestBackendRustCoverageSupported : Bool :=
  let coverage :=
    psRustCoverageModule psBackendRustIdentityModule;
  Nat.beq
    (psRustCoverageLength coverage.unsupported)
    0

def psTestBackendRustCoverageExternalImport : Bool :=
  let coverage :=
    psRustCoverageModule psBackendRustUnsupportedImportModule;
  psRustCoverageContains
    coverage.unsupported
    "module:externalImport"

def psTestBackendRustCoverageUnknownType : Bool :=
  let coverage :=
    psRustCoverageModule psBackendRustUnknownTypeModule;
  psRustCoverageContains
    coverage.unsupported
    "type:unknown"

structure PsBackendRustNamedTest where
  name : String
  passed : Bool

def psBackendRustTests : List PsBackendRustNamedTest := [
  { name := "identity module", passed := psTestBackendRustIdentity },
  { name := "Nat intrinsic", passed := psTestBackendRustIntrinsic },
  { name := "structure and inductive", passed := psTestBackendRustAdt },
  { name := "Char and String intrinsics", passed := psTestBackendRustStringIntrinsics },
  { name := "Array intrinsics", passed := psTestBackendRustArrayIntrinsics },
  { name := "top-level values and shadowing", passed := psTestBackendRustValues },
  { name := "frozen PSC1 scalar mappings", passed := psTestBackendRustScalarTypes },
  { name := "Rust identifier escaping", passed := psTestBackendRustIdentifiers },
  { name := "coverage accepts supported IR", passed := psTestBackendRustCoverageSupported },
  { name := "coverage rejects external imports", passed := psTestBackendRustCoverageExternalImport },
  { name := "coverage rejects unknown runtime types", passed := psTestBackendRustCoverageUnknownType }
]

def psRunBackendRustTests : List PsBackendRustNamedTest -> IO Bool
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSC1_BACKEND_RUST_PASS: " ++ test.name)
      else
        IO.println ("PSC1_BACKEND_RUST_FAIL: " ++ test.name)
      let restPassed ← psRunBackendRustTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psRunBackendRustTests psBackendRustTests
  if passed then
    IO.println "PSC1_BACKEND_RUST_TESTS: PASS"
  else
    throw (IO.userError "PSC1_BACKEND_RUST_TESTS: FAIL")
