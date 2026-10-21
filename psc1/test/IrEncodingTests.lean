import Ps.CompilerIr.Encode
import Ps.CompilerIr.Validate
import Lean.Data.Json

private def require (name : String) (condition : Bool) : IO Unit := do
  if !condition then throw (IO.userError ("PSC1_IR_ENCODING_FAIL: " ++ name))
  IO.println ("PSC1_IR_ENCODING_PASS: " ++ name)

private def charPrefix (needle text : List Char) : Bool :=
  match needle, text with
  | [], _ => true
  | _, [] => false
  | left :: restNeedle, right :: restText =>
      left == right && charPrefix restNeedle restText

private def charContains (needle text : List Char) : Bool :=
  if charPrefix needle text then true
  else match text with
    | [] => false
    | _ :: rest => charContains needle rest

private def containsText (text needle : String) : Bool :=
  charContains (psJsonStringToChars needle) (psJsonStringToChars text)

private def encode (source : PsVerifiedIrModule) : IO String := do
  match psIrEncodeModule source with
  | .error _ => throw (IO.userError "PSC1_IR_ENCODING_REFUSED")
  | .ok text => pure text

def main : IO Unit := do
  let huge : Nat := 9007199254740993123456789
  let source : PsVerifiedIrModule := {
    imports := [], structures := [], inductives := []
    declarations := [{
      name := "big", typeParameters := [], parameters := []
      resultType := .primitive .nat
      body := .literal (.natural huge)
    }, {
      name := "unicode", typeParameters := [], parameters := []
      resultType := .primitive .string
      body := .literal (.string "λ🙂\n\t\"\\")
    }]
  }
  let text <- encode source
  let value <- match Lean.Json.parse text with
    | .error message => throw (IO.userError message)
    | .ok value => pure value
  require "independent JSON parser accepts compact tagged IR"
    (value.compress == text)
  require "integers beyond ECMAScript precision are transported as exact decimal strings"
    (containsText text "9007199254740993123456789" &&
      containsText text "[\"natural\",\"9007199254740993123456789\"]")
  require "Unicode and escapes retain exact logical text"
    (containsText text "λ🙂\\n\\t\\\"\\\\")
  let changed : PsVerifiedIrModule := {
    source with declarations := source.declarations.reverse
  }
  let changedText <- encode changed
  require "declaration order changes graph identity" (text != changedText)
  let changedBody : PsVerifiedIrModule := {
    source with declarations := source.declarations.map (fun declaration =>
      if declaration.name == "big" then { declaration with body := .literal (.natural (huge + 1)) }
      else declaration)
  }
  let changedBodyText <- encode changedBody
  require "body changes beyond machine precision change graph identity"
    (text != changedBodyText && containsText changedBodyText "9007199254740993123456790")
  require "serialization grants no validation authority"
    (match psStrictValidateModule { source with declarations := [{
      name := "forged", typeParameters := [], parameters := []
      resultType := .primitive .nat, body := .literal (.bool true)
    }] } with | .error _ => true | .ok _ => false)
  require "serialization depth exhaustion refuses without partial bytes"
    (match psIrEncodeExprWithFuel 0 (.literal (.natural 0)) with
      | .error .fuelExhausted => true | .ok _ => false)
  let aggregate : PsVerifiedIrModule := {
    imports := []
    structures := [{
      name := "Box", typeParameters := []
      fields := [{ name := "field", type := .primitive .string }] }]
    inductives := [{
      name := "Choice", typeParameters := []
      constructors := [{ name := "take", fields := [{ name := "payload", type := .named "Box" [] }] }] }]
    declarations := [{
      name := "project", typeParameters := []
      parameters := [{ name := "value", type := .named "Choice" [] }]
      resultType := .primitive .string
      body := .matchE "Choice" [] (.var "value") [
        ("take", [{ field := "payload", name := "box", type := .named "Box" [] }],
          .projection "Box" [] (.var "box") "field")]
    }]
  }
  let aggregateText <- encode aggregate
  require "match owner bindings field labels and projections are retained"
    (containsText aggregateText "[\"matchE\",\"Choice\"" &&
      containsText aggregateText "[\"payload\",\"box\",[\"named\",\"Box\",[]]]" &&
      containsText aggregateText "[\"projection\",\"Box\",[],[\"var\",\"box\"],\"field\"]")
