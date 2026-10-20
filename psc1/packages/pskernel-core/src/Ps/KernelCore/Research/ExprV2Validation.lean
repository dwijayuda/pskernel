import Ps.KernelCore.Research.ExprV2Chunked

/- Native research adapter: convert, independently validate and compare
the portable immutable DAG. This module is NOT imported by the checker. -/

/- Decode in node-insertion order. Every child ID is earlier than its parent,
so each unique arena node is materialized ONCE and reused by later nodes. -/
private def psKernelExprV2ReadDecoded
    (built : Array PsKernelExpr) (id : Nat) :
    Except String PsKernelExpr :=
  match built[id]? with
  | some value => .ok value
  | none => .error "PSKERNEL_V2_FORWARD_OR_INVALID_REFERENCE"

def psKernelExprV2DecodeNode
    (built : Array PsKernelExpr)
    (node : PsKernelExprV2Node) :
    Except String PsKernelExpr := do
  match node with
  | .bvar index => return .bvar index
  | .fvar name => return .fvar name
  | .mvar name => return .mvar name
  | .sort level => return .sort level
  | .const name levels => return .const name levels
  | .lit literal => return .lit literal
  | .app fn arg =>
      return .app (← psKernelExprV2ReadDecoded built fn)
        (← psKernelExprV2ReadDecoded built arg)
  | .lam name type body binderInfo =>
      return .lam name
        (← psKernelExprV2ReadDecoded built type)
        (← psKernelExprV2ReadDecoded built body) binderInfo
  | .forallE name type body binderInfo =>
      return .forallE name
        (← psKernelExprV2ReadDecoded built type)
        (← psKernelExprV2ReadDecoded built body) binderInfo
  | .letE name type value body nondep =>
      return .letE name
        (← psKernelExprV2ReadDecoded built type)
        (← psKernelExprV2ReadDecoded built value)
        (← psKernelExprV2ReadDecoded built body) nondep
  | .mdata metadata body =>
      return .mdata metadata (← psKernelExprV2ReadDecoded built body)
  | .proj typeName index body =>
      return .proj typeName index (← psKernelExprV2ReadDecoded built body)

def psKernelExprV2Decode
    (arena : PsKernelExprV2Arena) (root : Nat) :
    Except String PsKernelExpr := do
  let mut built : Array PsKernelExpr := #[]
  for entry in arena.nodes do
    let expr ← psKernelExprV2DecodeNode built entry.node
    built := built.push expr
  psKernelExprV2ReadDecoded built root

/-
Independent reference calculations, used exclusively by validation.
The slow reference traverses the materialized tree, not V2 metadata.
-/
def psKernelExprV2LegacyLooseRange : PsKernelExpr → Nat
  | .bvar index => Nat.succ index
  | .app fn arg =>
      Nat.max (psKernelExprV2LegacyLooseRange fn)
        (psKernelExprV2LegacyLooseRange arg)
  | .lam _ type body _ =>
      Nat.max (psKernelExprV2LegacyLooseRange type)
        (Nat.sub (psKernelExprV2LegacyLooseRange body) 1)
  | .forallE _ type body _ =>
      Nat.max (psKernelExprV2LegacyLooseRange type)
        (Nat.sub (psKernelExprV2LegacyLooseRange body) 1)
  | .letE _ type value body _ =>
      Nat.max
        (Nat.max (psKernelExprV2LegacyLooseRange type)
          (psKernelExprV2LegacyLooseRange value))
        (Nat.sub (psKernelExprV2LegacyLooseRange body) 1)
  | .mdata _ body => psKernelExprV2LegacyLooseRange body
  | .proj _ _ body => psKernelExprV2LegacyLooseRange body
  | _ => 0

def psKernelExprV2LegacyDepth : PsKernelExpr → Nat
  | .app fn arg =>
      Nat.succ (Nat.max (psKernelExprV2LegacyDepth fn)
        (psKernelExprV2LegacyDepth arg))
  | .lam _ type body _ =>
      Nat.succ (Nat.max (psKernelExprV2LegacyDepth type)
        (psKernelExprV2LegacyDepth body))
  | .forallE _ type body _ =>
      Nat.succ (Nat.max (psKernelExprV2LegacyDepth type)
        (psKernelExprV2LegacyDepth body))
  | .letE _ type value body _ =>
      Nat.succ (Nat.max
        (Nat.max (psKernelExprV2LegacyDepth type)
          (psKernelExprV2LegacyDepth value))
        (psKernelExprV2LegacyDepth body))
  | .mdata _ body => Nat.succ (psKernelExprV2LegacyDepth body)
  | .proj _ _ body => Nat.succ (psKernelExprV2LegacyDepth body)
  | _ => 1

def psKernelExprV2LegacyHasMVar : PsKernelExpr → Bool
  | .mvar _ => true
  | .app fn arg =>
      psKernelExprV2LegacyHasMVar fn || psKernelExprV2LegacyHasMVar arg
  | .lam _ type body _ =>
      psKernelExprV2LegacyHasMVar type || psKernelExprV2LegacyHasMVar body
  | .forallE _ type body _ =>
      psKernelExprV2LegacyHasMVar type || psKernelExprV2LegacyHasMVar body
  | .letE _ type value body _ =>
      psKernelExprV2LegacyHasMVar type ||
        psKernelExprV2LegacyHasMVar value ||
          psKernelExprV2LegacyHasMVar body
  | .mdata _ body => psKernelExprV2LegacyHasMVar body
  | .proj _ _ body => psKernelExprV2LegacyHasMVar body
  | _ => false

/-
Validation MUST be performed before any untrusted, serialized, or externally
constructed V2 graph becomes eligible for a kernel acceleration path.
Does not trust metadata to validate metadata; recomputes from legacy structure.
-/
def psKernelExprV2Validate
    (arena : PsKernelExprV2Arena) :
    Except String Unit := do
  let mut built : Array PsKernelExpr := #[]
  for entry in arena.nodes do
    let expr ← psKernelExprV2DecodeNode built entry.node
    if entry.hash != psKernelExprHash expr then
      throw "PSKERNEL_V2_HASH_INVALID"
    if entry.looseRange != psKernelExprV2LegacyLooseRange expr then
      throw "PSKERNEL_V2_LOOSE_RANGE_INVALID"
    if entry.hasFVar != psKernelExprHasFVar expr then
      throw "PSKERNEL_V2_FVAR_FLAG_INVALID"
    if entry.hasExprMVar != psKernelExprV2LegacyHasMVar expr then
      throw "PSKERNEL_V2_MVAR_FLAG_INVALID"
    if entry.depth != psKernelExprV2LegacyDepth expr then
      throw "PSKERNEL_V2_DEPTH_INVALID"
    if (entry.looseRange > 0) != psKernelExprHasLooseBVar expr then
      throw "PSKERNEL_V2_LEGACY_LOOSE_FLAG_INVALID"
    built := built.push expr

/-
Same-arena equality: node ID equality is sufficient; a different hash is a
sufficient inequality only for validated graphs; otherwise inspect exact node
structure recursively. Names and binder-info on Lam/Pi are intentionally
ignored, precisely matching PSC1's semantic psKernelExprEq.
-/
def psKernelExprV2EqWithFuel
    (fuel : Nat) (arena : PsKernelExprV2Arena)
    (left right : Nat) : Bool :=
  match fuel with
  | 0 => false
  | Nat.succ remaining =>
      if left == right then
        match arena.nodes[left]? with
        | some _ => true
        | none => false
      else
        match arena.nodes[left]?, arena.nodes[right]? with
        | some a, some b =>
            if a.hash != b.hash then false
            else
              let eqChild := psKernelExprV2EqWithFuel remaining arena
              match a.node, b.node with
              | .bvar x, .bvar y => x == y
              | .fvar x, .fvar y => psKernelNameEq x y
              | .mvar x, .mvar y => psKernelNameEq x y
              | .sort x, .sort y => psKernelLevelEq x y
              | .const n ls, .const m rs =>
                  psKernelNameEq n m && psKernelLevelListEq ls rs
              | .lit x, .lit y => psKernelLiteralEq x y
              | .app f x, .app g y =>
                  eqChild f g && eqChild x y
              | .lam _ t v _, .lam _ u w _ =>
                  eqChild t u && eqChild v w
              | .forallE _ t v _, .forallE _ u w _ =>
                  eqChild t u && eqChild v w
              | .letE _ t v b nd, .letE _ u w c md =>
                  eqChild t u && eqChild v w && eqChild b c && nd == md
              | .mdata x b, .mdata y c =>
                  x == y && eqChild b c
              | .proj n x b, .proj m y c =>
                  psKernelNameEq n m && x == y && eqChild b c
              | _, _ => false
        | _, _ => false

def psKernelExprV2Eq
    (arena : PsKernelExprV2Arena) (left right : Nat) : Bool :=
  psKernelExprV2EqWithFuel (Nat.succ arena.nodes.size) arena left right

/-
Import old expressions only at a migration boundary; the new normal path
must use smart constructors, not repeatedly import for each checker operation.
A fuel bound makes this adapter total even on unknown source inputs.
-/
def psKernelExprV2ImportFuel
    (fuel : Nat) (arena : PsKernelExprV2Arena)
    (expr : PsKernelExpr) :
    Except String (PsKernelExprV2Arena × Nat) :=
  match fuel with
  | 0 => .error "PSKERNEL_V2_IMPORT_FUEL_EXHAUSTED"
  | Nat.succ remaining =>
      let recurse := psKernelExprV2ImportFuel remaining
      match expr with
      | .bvar index => .ok (psKernelExprV2MkBVar arena index)
      | .fvar name => .ok (psKernelExprV2MkFVar arena name)
      | .mvar name => .ok (psKernelExprV2MkMVar arena name)
      | .sort level => .ok (psKernelExprV2MkSort arena level)
      | .const name levels => .ok (psKernelExprV2MkConst arena name levels)
      | .lit literal => .ok (psKernelExprV2MkLit arena literal)
      | .app fn arg => do
          let (a, f) ← recurse arena fn
          let (b, x) ← recurse a arg
          psKernelExprV2MkApp b f x
      | .lam name type body binderInfo => do
          let (a, t) ← recurse arena type
          let (b, v) ← recurse a body
          psKernelExprV2MkLam b name t v binderInfo
      | .forallE name type body binderInfo => do
          let (a, t) ← recurse arena type
          let (b, v) ← recurse a body
          psKernelExprV2MkForall b name t v binderInfo
      | .letE name type value body nondep => do
          let (a, t) ← recurse arena type
          let (b, v) ← recurse a value
          let (c, d) ← recurse b body
          psKernelExprV2MkLet c name t v d nondep
      | .mdata metadata body => do
          let (a, b) ← recurse arena body
          psKernelExprV2MkMData a metadata b
      | .proj name index body => do
          let (a, b) ← recurse arena body
          psKernelExprV2MkProj a name index b

def psKernelExprV2Import
    (arena : PsKernelExprV2Arena) (expr : PsKernelExpr) :
    Except String (PsKernelExprV2Arena × Nat) :=
  psKernelExprV2ImportFuel
    (Nat.succ (psKernelExprNodeCount expr)) arena expr

/-
Expression V2 / M1b: linear-in-DAG-node-count metadata replay validator.

Unlike the independent but expensive legacy-oracle validator, this check
does not expand shared subexpressions. It rebuilds nodes in topological order
using only verified prior entries, and compares every cached field.

This is a research capability, NOT an admission proof. Equivalence to the old
expressions still needs independent differential/or formal evidence; no kernel
provider consumes the result of this function yet.
-/

def psKernelExprV2ReplayNode
    (already : PsKernelExprV2Arena)
    (node : PsKernelExprV2Node) :
    Except String (PsKernelExprV2Arena × Nat) :=
  match node with
  | .bvar index =>
      .ok (psKernelExprV2MkBVar already index)
  | .fvar name =>
      .ok (psKernelExprV2MkFVar already name)
  | .mvar name =>
      .ok (psKernelExprV2MkMVar already name)
  | .sort level =>
      .ok (psKernelExprV2MkSort already level)
  | .const name levels =>
      .ok (psKernelExprV2MkConst already name levels)
  | .lit literal =>
      .ok (psKernelExprV2MkLit already literal)
  | .app fn arg =>
      psKernelExprV2MkApp already fn arg
  | .lam name type body binderInfo =>
      psKernelExprV2MkLam already name type body binderInfo
  | .forallE name type body binderInfo =>
      psKernelExprV2MkForall already name type body binderInfo
  | .letE name type value body nondep =>
      psKernelExprV2MkLet already name type value body nondep
  | .mdata metadata body =>
      psKernelExprV2MkMData already metadata body
  | .proj name index body =>
      psKernelExprV2MkProj already name index body

def psKernelExprV2SameMetadata
    (expected observed : PsKernelExprV2Entry) : Bool :=
  expected.hash == observed.hash &&
  expected.looseRange == observed.looseRange &&
  expected.hasFVar == observed.hasFVar &&
  expected.hasExprMVar == observed.hasExprMVar &&
  expected.depth == observed.depth

/-
Return a freshly replayed, topologically checked arena.
Invalid child IDs, forward edges or counterfeit metadata cause Except.error.
The caller must not use unaudited original entries for trusted fast paths.
-/
def psKernelExprV2ValidateLinear
    (source : PsKernelExprV2Arena) :
    Except String PsKernelExprV2Arena := do
  let mut checked := psKernelExprV2Empty
  for sourceEntry in source.nodes do
    let (next, id) ← psKernelExprV2ReplayNode checked sourceEntry.node
    let computed ← psKernelExprV2Lookup next id
    if !psKernelExprV2SameMetadata sourceEntry computed then
      throw "PSKERNEL_V2_REPLAY_METADATA_MISMATCH"
    checked := next
  return checked


/-
Independently validate a chunked DAG from its nodes (in ID order), replaying
EVERY entry using canonical V2 smart constructors. The validator does not
trust cached hash, flags or loose range from the chunked source. Invalid
forward references, forged flags, and malformed layout all fail closed.

This is a research validation gate. The replay array is temporary and does
not appear in the eventual production checking path.
-/
def psKernelExprV2ValidateChunked
    (source : PsKernelExprV2ChunkedArena) :
    Except String Unit := do
  let mut checked := psKernelExprV2Empty
  for id in [:source.size] do
    let entry ← match psKernelExprV2ChunkedFind source id with
      | Option.none =>
          throw "PSKERNEL_V2_CHUNKED_MISSING_ENTRY"
      | Option.some value =>
          pure value
    let (next, newId) ← psKernelExprV2ReplayNode checked entry.node
    if newId != id then
      throw "PSKERNEL_V2_CHUNKED_ID_REPLAY_MISMATCH"
    let expected ← psKernelExprV2Lookup next newId
    if !psKernelExprV2SameMetadata entry expected then
      throw "PSKERNEL_V2_CHUNKED_METADATA_INVALID"
    checked := next
