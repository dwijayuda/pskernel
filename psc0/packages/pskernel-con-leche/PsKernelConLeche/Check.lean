import ConLeche.Frontend.Prelude
import ConLeche.Frontend.Stream
import ConLeche.Cached.Installed
import ConLeche.Kernel.NatOpPins

namespace PsKernelConLeche

/-- Bounds are adapter resources, not a claim that con-leche lacks a feature. -/
structure Limits where
  maxInputBytes : Nat := 67108864
  maxInputRecords : Nat := 1000000
  deriving Repr

inductive Phase where
  | resource | prelude | parse | policy | kernel
  deriving BEq, Repr

def Phase.label : Phase → String
  | .resource => "resource"
  | .prelude => "prelude"
  | .parse => "parse"
  | .policy => "policy"
  | .kernel => "kernel"

structure Diagnostic where
  phase : Phase
  error : ConLeche.CheckError
  position : Nat := 0
  deriving Repr

/-- 1 is invalid, 2 positively unsupported/policy-declined, 3 malformed/internal.
Timeouts and process crashes must also remain nonacceptance at the host boundary. -/
def Diagnostic.exitCode (d : Diagnostic) : UInt32 :=
  match d.error with
  | .invalid _ => 1
  | .notImplemented _ => 2
  | .internal _ => 3

def Diagnostic.status (d : Diagnostic) : String :=
  match d.error with
  | .invalid _ => "rejected"
  | .notImplemented _ => "declined"
  | .internal _ => "error"

def Diagnostic.positionUnit (d : Diagnostic) : String :=
  match d.phase with
  | .parse | .prelude => "input-line"
  | .policy | .kernel => "prepared-record-zero-based"
  | .resource => "none"

def fromUpstream (phase : Phase) (e : ConLeche.CheckError × Nat) : Diagnostic :=
  { phase, error := e.1, position := e.2 }

def inputByteCount (chunks : List ByteArray) : Nat :=
  chunks.foldl (fun n chunk => n + chunk.size) 0

/-- Structured-name equality, never dotted-string or prefix matching. The
upstream checker still checks the exact type of each permitted axiom.
This policy does not assert that upstream's METATHEOREM avoids choice. -/
def permittedInputAxiom (name : ConLeche.Name) : Bool :=
  name == .str .anonymous "propext" ||
  name == .str (.str .anonymous "Quot") "sound"

/-- Inspect the complete prepared stream, including the built-in prelude.
Do not discard sorryAx or replace unsupported declarations with axioms. -/
def auditInputAxioms (decls : Array ConLeche.Declaration) : Except Diagnostic Unit := do
  for i in [:decls.size] do
    match decls[i]! with
    | .axiomDecl cv =>
      unless permittedInputAxiom cv.name do
        throw {
          phase := .policy
          error := .notImplemented s!"PSC0 input axiom policy forbids {cv.name}"
          position := i
        }
    | _ => pure ()

structure PreparedInput where
  declarations : Array ConLeche.Declaration
  inputRecords : Nat

/-- Use the actual upstream parser/prelude preparation. No Lean elaboration,
unchecked import, name-based builtin replacement, or fresh logical assumptions. -/
def prepareChunks (chunks : List ByteArray) (limits : Limits := {}) :
    Except Diagnostic PreparedInput := do
  if inputByteCount chunks > limits.maxInputBytes then
    throw { phase := .resource, error := .internal "input byte budget exceeded" }
  let pre ← ConLeche.Frontend.builtinPreludeE.mapError (fromUpstream .prelude)
  let parsed ← (ConLeche.Frontend.parseChunks chunks).mapError (fromUpstream .parse)
  if parsed.decls.size > limits.maxInputRecords then
    throw { phase := .resource, error := .internal "input declaration-record budget exceeded" }
  let declarations := ConLeche.Frontend.preparePrelude pre parsed.decls
  auditInputAxioms declarations
  pure { declarations, inputRecords := parsed.decls.size }

/-- The whole accepting computation. In particular installation alone cannot
return success: checkDecls completes BOTH installation and all pending checks.
Every call starts a fresh complete environment; no cross-input admission cache.
Only .verified is exposed. This is deliberately the sequential pure fold;
upstream's parallel process driver is not reimplemented here. -/
def checkInput (chunks : List ByteArray) (limits : Limits := {}) :
    Except Diagnostic ConLeche.Env :=
  match prepareChunks chunks limits with
  | .error e => .error e
  | .ok prepared =>
    match ConLeche.Cached.checkDecls .verified ConLeche.natOpPinSets prepared.declarations with
    | .error e => .error (fromUpstream .kernel e)
    | .ok environment => .ok environment

/-- In-process evidence tied to the EXACT input chunks and bounds. It cannot
be constructed from a boolean or JSON receipt. This is NOT evidence of the
PSC0 source-to-export bridge, source semantics, or target-code preservation. -/
structure CheckedInput (chunks : List ByteArray) (limits : Limits) where
  environment : ConLeche.Env
  accepted : checkInput chunks limits = .ok environment

/-- Check once, retaining the equation as erased Lean evidence. -/
def check (chunks : List ByteArray) (limits : Limits := {}) :
    Except Diagnostic (CheckedInput chunks limits) :=
  match h : checkInput chunks limits with
  | .error e => .error e
  | .ok environment => .ok ⟨environment, h⟩

end PsKernelConLeche
