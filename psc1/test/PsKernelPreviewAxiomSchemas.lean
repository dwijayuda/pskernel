import Lean

open Lean

private def text (s : String) : Json := Json.str s
private def node (tag : String) (xs : Array Json := #[]) : Json :=
  Json.arr (#[text tag] ++ xs)

private partial def nameSchema : Name → Json
  | .anonymous => node "anonymous"
  | .str p s => node "str" #[nameSchema p, text s]
  | .num p n => node "num" #[nameSchema p, text (toString n)]

private def parameterIndex (params : List Name) (n : Name) : Except String Nat :=
  let rec go : List Name → Nat → Except String Nat
    | [], _ => .error "undeclared universe parameter in standard axiom"
    | p :: ps, i => if p == n then .ok i else go ps (i + 1)
  go params 0

private partial def levelSchema (params : List Name) : Level → Except String Json
  | .zero => .ok (node "zero")
  | .succ l => do return node "succ" #[← levelSchema params l]
  | .max a b => do return node "max" #[← levelSchema params a, ← levelSchema params b]
  | .imax a b => do return node "imax" #[← levelSchema params a, ← levelSchema params b]
  | .param n => do return node "param" #[text (toString (← parameterIndex params n))]
  | .mvar _ => .error "metavariable in standard axiom"

private def binderSchema : BinderInfo → String
  | .default => "default"
  | .implicit => "implicit"
  | .strictImplicit => "strictImplicit"
  | .instImplicit => "instImplicit"

private partial def expressionSchema (params : List Name) (fixture : Bool) : Expr → Except String Json
  | .bvar n => .ok (node "bvar" #[text (toString n)])
  | .sort l => do return node "sort" #[← levelSchema params l]
  | .const n us => do return node "const" #[nameSchema n, Json.arr (← us.toArray.mapM (levelSchema params))]
  | .app f a => do return node "app" #[← expressionSchema params fixture f, ← expressionSchema params fixture a]
  | .forallE n d b bi => do
      let xs := #[← expressionSchema params fixture d, ← expressionSchema params fixture b, text (binderSchema bi)]
      return node "forallE" (xs ++ (if fixture then #[nameSchema n] else #[]))
  | _ => .error "unexpected expression constructor in pinned standard axiom"

def main : IO Unit := do
  let env ← importModules #[{ module := `Lean }] {}
  let mut schemas : Array (String × Json) := #[]
  let mut primitives : Array (String × Json) := #[]
  for n in [`propext, `Classical.choice, `Quot.sound] do
    let some info := env.find? n | throw (IO.userError "missing pinned standard axiom")
    unless (match info with | .axiomInfo _ => true | _ => false) do
      throw (IO.userError "standard axiom is not an axiom declaration")
    let schema ← match expressionSchema info.levelParams false info.type with
      | .ok v => pure v
      | .error e => throw (IO.userError e)
    schemas := schemas.push (n.toString, Json.mkObj [
      ("universeParameters", text (toString info.levelParams.length)),
      ("type", schema)])
  for n in [`Eq, `Eq.refl, `Iff, `Iff.intro, `Nonempty, `Nonempty.intro,
      `Quot, `Quot.mk, `Quot.lift, `Quot.ind] do
    let some info := env.find? n | throw (IO.userError "missing standard axiom dependency")
    let schema ← match expressionSchema info.levelParams false info.type with
      | .ok v => pure v
      | .error e => throw (IO.userError e)
    let extra ← match info with
      | .inductInfo v => pure [
          ("kind", text "inductiveType"), ("numParams", text (toString v.numParams)),
          ("numIndices", text (toString v.numIndices)), ("numNested", text (toString v.numNested)),
          ("isRec", Json.bool v.isRec), ("isReflexive", Json.bool v.isReflexive), ("isUnsafe", Json.bool v.isUnsafe),
          ("all", Json.arr (v.all.toArray.map nameSchema)), ("ctors", Json.arr (v.ctors.toArray.map nameSchema))]
      | .ctorInfo v => pure [
          ("kind", text "constructor"), ("induct", nameSchema v.induct), ("cidx", text (toString v.cidx)),
          ("numParams", text (toString v.numParams)), ("numFields", text (toString v.numFields)), ("isUnsafe", Json.bool v.isUnsafe)]
      | .quotInfo _ => pure [("kind", text "quotient")]
      | _ => throw (IO.userError "unexpected dependency kind")
    let fixtureType ← match expressionSchema info.levelParams true info.type with
      | .ok v => pure v
      | .error e => throw (IO.userError e)
    primitives := primitives.push (n.toString, Json.mkObj
      ([("universeParameters", text (toString info.levelParams.length)), ("type", schema),
        ("fixtureType", fixtureType), ("fixtureLevelParams", Json.arr (info.levelParams.toArray.map nameSchema))] ++ extra))
  IO.println (Json.mkObj [
    ("format", text "pskernel-preview-axioms-v1"),
    ("leanVersion", text "4.35.0"),
    ("leanCommit", text "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"),
    ("schemas", Json.mkObj schemas.toList), ("primitives", Json.mkObj primitives.toList)]).compress
