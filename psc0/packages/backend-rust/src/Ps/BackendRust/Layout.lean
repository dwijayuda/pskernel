import Ps.BackendRust.TailAlias

-- Only recursive nominal layouts need indirection. Functions and arrays
-- already have indirect representations and cannot make an infinite-size type.
def psRustLayoutNames : Nat → PsVerifiedIrType → List String
  | 0, _ => []
  | n + 1, type =>
      match type with
      | .named "Array" _ | .function _ _ => []
      | .named name args => name :: args.flatMap (psRustLayoutNames n)
      | _ => []

def psRustLayoutGraph (ir : PsVerifiedIrModule) : List (String × List String) :=
  (ir.structures.map fun s =>
    (s.name, s.fields.flatMap fun f => psRustLayoutNames 65536 f.type)) ++
  (ir.inductives.map fun i =>
    (i.name, i.constructors.flatMap fun c =>
      c.fields.flatMap fun f => psRustLayoutNames 65536 f.type))

def psRustLayoutReaches (graph : List (String × List String)) (target : String) :
    Nat → List String → List String → Except String Bool
  | 0, _, _ => throw "PSCV0-RUST: layout graph budget exhausted"
  | _ + 1, [], _ => return false
  | n + 1, name :: rest, seen => do
      if name == target then return true
      if seen.contains name then return ← psRustLayoutReaches graph target n rest seen
      let children := (graph.find? (fun p => p.1 == name)).map (·.2) |>.getD []
      psRustLayoutReaches graph target n (children ++ rest) (name :: seen)

def psRustSharedLayouts (ir : PsVerifiedIrModule) : Except String (List String) := do
  let graph := psRustLayoutGraph ir
  let mut shared := []
  for (name, children) in graph do
    if ← psRustLayoutReaches graph name 100000 children [] then
      shared := name :: shared
  return shared

structure PsRustContext where
  declarations : List PsVerifiedIrDeclaration
  shared : List String
  locals : List String := []
  tail? : Option PsVerifiedIrDeclaration := none
  aliases : List PsRustTailAlias := []

def psRustNodeName (shared : List String) (name : String) : String :=
  if shared.contains name then "__ps_node_" ++ name else name
